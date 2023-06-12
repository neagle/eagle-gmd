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
	api_endpoint:              "http://\(context.globals.edge_host)/services/\(context.globals.namespace)/\(name)/"
	api_spec_endpoint:         "http://\(context.globals.edge_host)/services/\(context.globals.namespace)/\(name)/"
	enable_historical_metrics: false
	enable_instance_metrics:   false
	business_impact:           "high"
	owner:                     "gmdata"
	capability:                ""

	// Jwt -> ingress to your container
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
									port: 50000
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
}

exports: "jwt": Jwt
