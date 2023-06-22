package gmdata

import (
	gsl "greymatter.io/gsl/v1"

	"gmdata.module/greymatter:globals"
)

Jwt: gsl.#Service & {
	// A context provides global information from globals.cue
	// to your service definitions.
	context: Jwt.#NewContext & globals

	// name must follow the pattern namespace/name
	// per daniel, above comment is a lie, namespace gets added for you
	name:                      "jwt-security"
	display_name:              "gmdata JWT"
	version:                   "v1.0.0"
	description:               "JWT security service for gmdata"
	api_endpoint:              "/services/\(context.globals.namespace)/\(name)/"
	api_spec_endpoint:         "/services/\(context.globals.namespace)/\(name)/"
	enable_historical_metrics: true
	enable_instance_metrics:   true
	business_impact:           "high"
	owner:                     "gmdata"
	capability:                ""

	// Jwt -> ingress to your container
	ingress: {
		(name): {
			gsl.#HTTPListener
			gsl.#SpireListener & {
				#context: context.SpireContext
				#subjects: ["gmdata-gmdata"]
			}
			routes: {
				"/": {
					upstreams: {
						"local": {
							instances: [
								{
									host: "127.0.0.1"
									port: 8080
								},
							]
						}
					}
				}
			}
		}
	}

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

exports: "jwt": Jwt
