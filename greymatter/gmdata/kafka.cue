package gmdata

import (
	gsl "greymatter.io/gsl/v1"

	"gmdata.module/greymatter:globals"
)

Kafka: gsl.#Service & {
	// A context provides global information from globals.cue
	// to your service definitions.
	context: Kafka.#NewContext & globals

	// name must follow the pattern namespace/name
	name:                      "kafka"
	display_name:              "gmdata Kafka"
	version:                   "v1.0.0"
	description:               "EDIT ME"
	api_endpoint:              "http://\(context.globals.edge_host)/services/\(context.globals.namespace)/\(name)/"
	api_spec_endpoint:         "http://\(context.globals.edge_host)/services/\(context.globals.namespace)/\(name)/"
	enable_historical_metrics: false
	enable_instance_metrics:   false
	business_impact:           "low"
	owner:                     "gmdata"
	capability:                ""

	// Kafka -> ingress to your container
	ingress: {
		(name): {
			gsl.#TCPListener

			upstream: {
				gsl.#Upstream
				name: "local"
				instances: [
					{
						host: "127.0.0.1"
						port: 9092
					},
				]
			}
		}
	}

	// Looking to make your tcp service accessible from the edge?
	// You must open a new listener on the edge whose upstream name
	// refers to this service's name.
}

exports: "kafka": Kafka