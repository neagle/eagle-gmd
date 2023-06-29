package gmdata

import (
	gsl "greymatter.io/gsl/v1"

	"gmdata.module/greymatter:globals"
)

Gmdata: gsl.#Service & {
	// A context provides global information from globals.cue
	// to your service definitions.
	context: Gmdata.#NewContext & globals

	// name must follow the pattern namespace/name
	name:                      "gmdata"
	display_name:              "gmdata"
	version:                   "v1.0.0"
	description:               "greymatter data service"
	api_endpoint:              "https://\(context.globals.edge_host)/services/\(context.globals.namespace)/\(name)/static/ui"
	api_spec_endpoint:         "https://\(context.globals.edge_host)/services/\(context.globals.namespace)/\(name)/"
	enable_historical_metrics: true
	enable_instance_metrics:   true
	business_impact:           "high"
	owner:                     "greymatter"
	capability:                "data"
	health_options: {
		spire: gsl.#SpireUpstream & {
			#context: context.SpireContext
			#subjects: ["gmdata-edge"]
		}
	}
	ingress: {
		(name): {
			gsl.#HTTPListener
			gsl.#SpireListener & {
				#context: context.SpireContext
				#subjects: ["gmdata-edge"]
			}
			routes: {
				"/": {
					upstreams: {
						"local": {
							instances: [
								{
									host: "127.0.0.1"
									port: 8181
								},
							]
						}
					}
				}
			}
		}
	}

	egress: {
		"egress-to-mongo": {
			gsl.#TCPListener
			port: 27017
			upstream: {
				namespace: context.globals.namespace
				name:      "mongo"
				gsl.#SpireUpstream & {
					#context: context.SpireContext
					#subjects: ["gmdata-mongo"]
				}
			}
		}
		"egress-to-kafka": {
			gsl.#TCPListener
			port: 9092
			upstream: {
				namespace: context.globals.namespace
				name:      "kafka"
				gsl.#SpireUpstream & {
					#context: context.SpireContext
					#subjects: ["gmdata-kafka"]
				}
			}
		}
		"egress-to-zk": {
			gsl.#TCPListener
			port: 2181
			upstream: {
				namespace: context.globals.namespace
				name:      "zk"
				gsl.#SpireUpstream & {
					#context: context.SpireContext
					#subjects: ["gmdata-zk"]
				}
			}
		}
		"egress-to-services": {
			gsl.#HTTPListener
			port: 10811
			routes: {
				"/jwt": {
					prefix_rewrite: "/"
					upstreams: {
						"jwt-security": {
							namespace: context.globals.namespace
							gsl.#Upstream
							gsl.#SpireUpstream & {
								#context: context.SpireContext
								#subjects: ["gmdata-jwt-security"]
							}
						}
					}
				}
			}
		}
	}

	// Looking to make your tcp service accessible from the edge?
	// You must open a new listener on the edge whose upstream name
	// refers to this service's name.
	edge: {
		edge_name: "edge"
		routes: "/services/\(context.globals.namespace)/\(name)": {
			prefix_rewrite: "/"
			upstreams: (name): {
				gsl.#Upstream
				namespace: context.globals.namespace
				gsl.#SpireUpstream & {
					#context: context.SpireContext
					#subjects: ["gmdata-edge"]
				}
			}
		}
	}
}

exports: "gmdata": Gmdata
