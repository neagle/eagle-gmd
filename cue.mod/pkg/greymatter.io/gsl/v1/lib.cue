package v1

import (
	"list"
	"strings"
	envoy_tcp_proxy "envoyproxy.io/extensions/filters/network/tcp_proxy/v3"
)

#DefaultRBAC: {
	rules: {
		action: "ALLOW"
		policies: {
			all: {
				permissions: [
					{
						any: true
					},
				]
				principals: [
					{
						any: true
					},
				]
			}
		}
	}
}

#GRPCUpstream: {
	http2_protocol_options: {
		allow_connect: *true | _
	}
}

#GRPCListener: #GRPCUpstream

// DEPRECATED: please use #GRPCUpstream
#DefaultGRPCUpstream: #GRPCUpstream

#HTTP2Upstream: {
	http2_protocol_options: {}
}

#HTTP2Listener: #HTTP2Upstream

#DefaultContext: #GlobalContext & {
	mesh: {
		name:                    *"greymatter-mesh" | _
		datastore_upstream_name: *"datastore" | _
		operator_namespace:      *"gm-operator" | _
	}

	sidecar: {
		// port for ingress traffic, matching the operator 
		default_ingress_port: *10908 | _
		// port of the healtcheck service
		healthcheck_port: *10910 | _
		// port the sidecar serves metrics requests from
		metrics_port: *8082 | _
	}

	spire: {
		trust_domain: *"greymatter.io" | _
	}

	edge_host: *"" | _
}

#SpireCommon: {
	#context: {
		#GlobalContext
		service_name: string
	}
	#subjects: [...string]

	secret: {
		ecdh_curves:            *["X25519:P-256:P-521:P-384"] | [...string]
		secret_validation_name: *"spiffe://\(#context.spire.trust_domain)" | _
		// // self 
		secret_name: *"spiffe://\(#context.spire.trust_domain)/\(#context.mesh.operator_namespace).\(#context.mesh.name).\(#context.namespace)-\(#context.service_name)" | _
		// other 
		subject_names: *[ for s in #subjects {"spiffe://\(#context.spire.trust_domain)/\(#context.mesh.operator_namespace).\(#context.mesh.name).\(s)"}] | _
		set_current_client_cert_details: URI: *true | _
		forward_client_cert_details: *"APPEND_FORWARD" | _
	}
}

#SpireListener: {
	#SpireCommon
	force_https: true
	...
}

#SpireUpstream: {
	#SpireCommon
	require_tls: true
	...
}

#TLSUpstream: #UpstreamTLSSchema & {
	require_tls: true
	ssl_config: {
		protocols: *["TLS_AUTO"] | _
	}
}

#MTLSUpstream: #UpstreamTLSSchema & {
	#TLSUpstream
	ssl_config: {
		trust_file:     *"/etc/proxy/tls/sidecar/ca.crt" | _
		cert_key_pairs: *[{
			certificate_path: *"/etc/proxy/tls/sidecar/server.crt" | _
			key_path:         *"/etc/proxy/tls/sidecar/server.key" | _
		}] | _
	}
}

#TLSListener: #ListenerTLSSchema & {
	force_https: true
	ssl_config:  #ListenerSSLConfig & {
		protocols:      *["TLS_AUTO"] | _
		cert_key_pairs: *[
				{
				certificate_path: *"/etc/proxy/tls/sidecar/server.crt" | _
				key_path:         *"/etc/proxy/tls/sidecar/server.key" | _
			},
		] | _
	}
}

#MTLSListener: #ListenerTLSSchema & {
	#TLSListener
	ssl_config: {
		trust_file:           *"/etc/proxy/tls/sidecar/ca.crt" | _
		require_client_certs: *true | _
	}
}

#ShadowTraffic: {
	behavior: "shadow"
	weight:   int
}

#SplitTraffic: {
	behavior: "split"
	weight:   int
}

// This allows for "drop in object" functionality inside upstreams. Fields are still eventually
// typed checked
#Upstream: {
	...
}

#TCPListener: self = {
	#ListenerSchema

	_#filterOrder: {
		// Authentication always comes first so we can 
		// block/deny/allow as necessary.
		"ext_authz": *1 | int

		// Rate limiting also receives a high priority
		// since it can prevent DOS attacks.
		"rate_limit": *2 | int

		"metrics": *3 | int

		// TCP proxy and protocol filters should 
		// always be last as they signal the proxy 
		// what kind of connection its handling.
		"tcp_proxy": *10 | int

		// The greymatter proxy requires redis to be 
		// last in the network filter chain.
		"redis_proxy": *11 | int
	}

	tcp_options: envoy_tcp_proxy.#TcpProxy & {
		cluster:     *((*(upstream.namespace + "-") | "") + upstream.name) | _
		stat_prefix: *cluster | _
	}
	metrics_options: #TCPMetricsFilter.#options

	filter_order?: [...string]
	filters: [...]
	_defaultfilters: [...]
	_allfilters: filters + _defaultfilters + [{tcp_proxy: tcp_options}]
	_unique: {
		for filter in _allfilters for name, v in filter if _#lookupFilters[name] != _|_ {
			"\(name)": v
		}
	}

	network_filters: #TCPFilters & {
		for name, v in _unique {
			"\(_#lookupFilters[name])": v
		}
	}

	active_network_filters: [ for f in (list.Sort(
		[ for name, v in _unique {name}],
		{x: string, y: string, less: (*_#filterOrder[x] | 5) < (*_#filterOrder[y] | 5)},
		) | *filter_order) {strings.Replace("\(_#lookupFilters[f])", "_", ".", 1)}]

	filter_secrets: {}
	filter_secrets: {
		for filter in _allfilters for name, v in filter if _#lookupFilterSecrets[name] != _|_ {
			(name): v
		}
	}

	upstream: #UpstreamSchema
	routes: {
		{"/": {
			upstreams: {"\(self.upstream.name)": self.upstream}
		}} & #Routes
	}
	protocol: "tcp"
}

#HTTPListener: {
	#ListenerSchema
	_#filterOrder: {
		"oidc_authn":       *1 | int
		"ensure_variables": *2 | int
		"oidc_validate":    *3 | int
		"lua":              *3 | int
		"fault":            *3 | int
		"inheaders":        *3 | int
		"impersonation":    *3 | int

		// the greymatter audits pipeline needs info populated by auth
		"audit": *4 | int

		// authz requests should be logged by audits
		"jwtsecurity":    *5 | int
		"external_authz": *5 | int
		"jwt_authn":      *5 | int
		"rbac":           *5 | int

		// Metrics must be last except for extreme and specific cases
		"metrics": *10 | int
	}

	metrics_options?: #MetricsFilter.#options
	audit_options?:   #AuditFilter.#options

	filters: [...]
	_defaultfilters: [...]
	_allfilters: filters + _defaultfilters
	filter_order?: [...string]

	_unique: {
		for filter in _allfilters for name, v in filter if _#lookupFilters[name] != _|_ {
			(name): v
		}
	}

	http_filters: #HTTPFilters & {
		for name, v in _unique {
			"\(_#lookupFilters[name])": v
		}

	}

	filter_secrets: {}
	filter_secrets: {
		for filter in _allfilters for name, v in filter if _#lookupFilterSecrets[name] != _|_ {
			(name): v
		}
	}

	active_http_filters: [ for f in (list.Sort(
		[ for name, v in _unique {name}],
		{x: string, y: string, less: (*_#filterOrder[x] | 5) < (*_#filterOrder[y] | 5)},
		) | *filter_order) {strings.Replace("\(_#lookupFilters[f])", "_", ".", 1)}]

	protocol: "http_auto"
	routes:   #Routes
}
