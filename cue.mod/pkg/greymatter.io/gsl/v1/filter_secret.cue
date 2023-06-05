package v1

#FilterSecret: {
	filter: string
	path:   string
	type:   string
	(#KubernetesSecret | #PlaintextSecret)
}

#KubernetesSecret: {
	filter:    string
	path:      string
	type:      "kubernetes"
	namespace: string
	name:      string
	key:       string
}

#PlaintextSecret: {
	filter: string
	path:   string
	type:   "plaintext"
	secret: string
}
