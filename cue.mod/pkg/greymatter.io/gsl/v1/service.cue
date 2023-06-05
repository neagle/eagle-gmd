package v1

#Service: service = {
	#NewContext: {
		globals: #GlobalContext
		SpireContext: {
			globals
			service_name: service.name
		}
	}
	context: #NewContext

	zone_key:                  #DEFAULT_ZONE
	name:                      string
	namespace:                 string | *context.globals.namespace
	mesh_id:                   string | *context.globals.mesh.name
	service_id:                name
	api_endpoint?:             string
	api_spec_endpoint?:        string
	description?:              string
	enable_instance_metrics:   bool | *true
	enable_historical_metrics: bool | *true
	business_impact:           string | *"low"
	version?:                  string
	owner?:                    string
	owner_url?:                string
	capability?:               string
	runtime?:                  string
	documentation?:            string
	prometheus_job:            string | *"\(namespace)-\(name)"
	external_links?: [...{title: string, url: string}]

	display_name?: string
	edge?:         #EdgeConfig

	// 1.x control-api expects connection upgrades
	// at the proxy level. We enable this field 
	// in the service so it can be applied on the 
	// Proxy object.
	upgrades?: string

	health_options: {
		tls?:   #UpstreamTLSSchema
		spire?: #SpireUpstream
	}

	ingress?: [ingressName=string]: {
		ip: *"0.0.0.0" | _
	} & (#HTTPListener | #TCPListener )

	egress?: [egressName=string]: {
		ip: *"127.0.0.1" | _
	} & (#HTTPListener | #TCPListener)

	// Every service must have a ingress listener named itself
	ingress: "\(service.name)": self = (#HTTPListener | #TCPListener) & {
		port: *context.globals.sidecar.default_ingress_port | _
		metrics_options: {
			metrics_port: context.globals.sidecar.metrics_port
			if self.protocol == "http_auto" {
				metrics_receiver: {
					redis_connection_string: "redis://127.0.0.1:\(context.globals.sidecar.healthcheck_port)"
					push_interval_seconds:   10
				}
			}
		}

		_defaultfilters: [
			if self.protocol == "tcp" {
				#TCPMetricsFilter & {#options: {metrics_options}}
			},
			if self.protocol == "http_auto" {
				#AuditFilter & {
					#options: {
						if self.audit_options != _|_ {
							self.audit_options
						}
						topic: *service.name | _
					}
				}
			},
			if self.protocol == "http_auto" {
				#MetricsFilter & {#options: {metrics_options}}
			},
		]
	}

	// Default greymatter healthchecking action that all data-plane proxies receive.
	// This is required for the greymatter HC system to function properly.
	egress: "health-checks": #TCPListener & {
		port: context.globals.sidecar.healthcheck_port
		upstream: {
			namespace: *"" | _
			name:      *"greymatter-datastore" | _
			if health_options.tls != _|_ {
				{health_options.tls, ...}
			}
			if health_options.spire != _|_ {
				health_options.spire
			}
		}
	}

	// Dangling clusters that get attached to a 
	// proxy node that aren't associated with any route match.
	// This can be particularly useful when creating outbound
	// connections used by internal filter logic.
	// ext_authz is a good example of this as the filter
	// takes a cluster parameter that should be registered on the proxy
	// but not exposed by a route.
	raw_upstreams: [Upstream=string]: {
		#UpstreamSchema
		name: Upstream
	}
}

// EdgeConfig is used in the service definition
// to link services to their application edge node.
#EdgeConfig: {
	edge_ingress: *edge_name | string
	edge_name:    string
	routes:       #Routes
}
