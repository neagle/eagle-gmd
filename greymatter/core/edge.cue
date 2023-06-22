// Edge configuration for enterprise mesh-segmentation. This is a dedicated
// edge proxy that provides north/south network traffic to services in this
// repository in the mesh. This edge would be separate from the default
// greymatter edge that is deployed via enterprise-level configuration in
// the gitops-core git repository.
package gmdata

import (
	gsl "greymatter.io/gsl/v1"

	"gmdata.module/greymatter:globals"
)

Edge: gsl.#Edge & {
	// A context provides global information from globals.cue
	// to your service definitions.
	context: Edge.#NewContext & globals

	name:            "edge"
	display_name:    "Eagle GMD Edge"
	version:         "v1.8.1"
	description:     "Edge ingress for gmdata namespace"
	business_impact: "high"
	owner:           "Nate Eagle"
	capability:      ""

        ingress: {
                (name): {
                        gsl.#HTTPListener
                        gsl.#MTLSListener & {
                                ssl_config: {
                                        cert_key_pairs: [
                                                {
                                                        certificate_path: "/etc/proxy/tls/edge/server.crt"
                                                        key_path:         "/etc/proxy/tls/edge/server.key"
                                                },
                                        ]
                                        trust_file: "/etc/proxy/tls/edge/ca.crt"
                                }
                        }
                        filters: [
                                gsl.#InheadersFilter,
                        ]

                        port: 10809
                }

        }

}

exports: "edge-gmdata": Edge
