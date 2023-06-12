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
	description:               "Data... to the MAX!"
	api_endpoint:              "http://\(context.globals.edge_host)/services/\(context.globals.namespace)/\(name)/"
	api_spec_endpoint:         "http://\(context.globals.edge_host)/services/\(context.globals.namespace)/\(name)/"
	enable_historical_metrics: false
	enable_instance_metrics:   false
	business_impact:           "high"
	owner:                     "greymatter"
	capability:                "data"

        ingress: {
                (name): {
                        gsl.#HTTPListener

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
			}
		}
	}
}

exports: "gmdata": Gmdata
