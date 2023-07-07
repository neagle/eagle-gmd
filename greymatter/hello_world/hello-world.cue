package gmdata

import (
	gsl "greymatter.io/gsl/v1"

	"gmdata.module/greymatter:globals"
)

Hello_World: gsl.#Service & {
	// A context provides global information from globals.cue
	// to your service definitions.
	context: Hello_World.#NewContext & globals

	// name must follow the pattern namespace/name
	name:                      "hello-world"
	display_name:              "Eagle GMD Hello World"
	version:                   "v1.0.0"
	description:               "The simplest service around."
	api_endpoint:              "http://\(context.globals.edge_host)/services/\(context.globals.namespace)/\(name)/"
	api_spec_endpoint:         "http://\(context.globals.edge_host)/services/\(context.globals.namespace)/\(name)/"
	enable_historical_metrics: false
	enable_instance_metrics:   false
	business_impact:           "low"
	owner:                     "Nate Eagle"
	capability:                "Helloing the world"

	// Hello-World -> ingress to your container
	ingress: {
		(name): {
			gsl.#TCPListener
			gsl.#SpireListener & {
				#context: context.SpireContext
				#subjects: ["gmdata-gmdata","gmdata-edge"]
			}	
			upstream: {
				gsl.#Upstream
				name: "local"
				instances: [
					{
						host: "127.0.0.1"
						port: 80
					},
				]
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

exports: "hello-world": Hello_World
