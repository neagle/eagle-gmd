package gmdata

import (
	gsl "greymatter.io/gsl/v1"

	"gmdata.module/greymatter:globals"
)

Zk: gsl.#Service & {
	// A context provides global information from globals.cue
	// to your service definitions.
	context: Zk.#NewContext & globals

	// name must follow the pattern namespace/name
	name:                      "zk"
	display_name:              "gmdata Zookeeper"
	version:                   "v1.0.0"
	description:               "help coordinate kafka connections"
	api_endpoint:              "http://\(context.globals.edge_host)/services/\(context.globals.namespace)/\(name)/"
	api_spec_endpoint:         "http://\(context.globals.edge_host)/services/\(context.globals.namespace)/\(name)/"
	enable_historical_metrics: true
	enable_instance_metrics:   true
	business_impact:           "low"
	owner:                     "gmdata"
	capability:                ""

	// Zk -> ingress to your container
	ingress: {
		(name): {
			gsl.#TCPListener
			gsl.#SpireListener & {
				#context: context.SpireContext
				#subjects: ["gmdata-gmdata","gmdata-kafka"]
			}
			upstream: {
				gsl.#Upstream
				name: "local"
				instances: [
					{
						host: "127.0.0.1"
						port: 2181
					},
				]
			}
		}
	}

	// Looking to make your tcp service accessible from the edge?
	// You must open a new listener on the edge whose upstream name
	// refers to this service's name.
}

exports: "zk": Zk
