// Edge configuration for enterprise mesh-segmentation. This is a dedicated
// edge proxy that provides north/south network traffic to services in this
// repository in the mesh. This edge would be separate from the default
// greymatter edge that is deployed via enterprise-level configuration in
// the gitops-core git repository.
package eagle_gmd

import (
	gsl "greymatter.io/gsl/v1"

	"eagle_gmd.module/greymatter:globals"
)

Edge: gsl.#Edge & {
	// A context provides global information from globals.cue
	// to your service definitions.
	context: Edge.#NewContext & globals

	name:              "edge"
	display_name:      "Eagle Gmd Edge"
	version:           "v1.8.1"
	description:       "Edge ingress for eagle-gmd"
	business_impact:   "high"
	owner:             "Eagle Gmd"
	capability:        ""
	
	ingress: {
		// Edge -> HTTP ingress to your container
		(name): {
			gsl.#HTTPListener
			
			port: 10809
				
		}
	}
}

exports: "edge-eagle-gmd": Edge
