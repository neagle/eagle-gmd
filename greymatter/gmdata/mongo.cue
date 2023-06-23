package gmdata

import (
	gsl "greymatter.io/gsl/v1"

	"gmdata.module/greymatter:globals"
)

Mongo: gsl.#Service & {
	// A context provides global information from globals.cue
	// to your service definitions.
	context: Mongo.#NewContext & globals

	// name must follow the pattern namespace/name
	name:                      "mongo"
	display_name:              "gmdata Mongo"
	version:                   "v1.0.0"
	description:               "gm-data's persistent mongodb data"
	api_endpoint:              "http://\(context.globals.edge_host)/services/\(context.globals.namespace)/\(name)/"
	api_spec_endpoint:         "http://\(context.globals.edge_host)/services/\(context.globals.namespace)/\(name)/"
	enable_historical_metrics: true
	enable_instance_metrics:   true
	business_impact:           "low"
	owner:                     "gmdata"
	capability:                ""

	// Mongo -> ingress to your container
	ingress: {
		(name): {
			gsl.#TCPListener
			gsl.#SpireListener & {
				#context: context.SpireContext
				#subjects: ["gmdata-gmdata"]
			}
			upstream: {
				gsl.#Upstream
				name: "local"
				instances: [
					{
						host: "127.0.0.1"
						port: 27017
					},
				]
			}
		}
	}

	// Looking to make your tcp service accessible from the edge?
	// You must open a new listener on the edge whose upstream name
	// refers to this service's name.
}

exports: "mongo": Mongo
