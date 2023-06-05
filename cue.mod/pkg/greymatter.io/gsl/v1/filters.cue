package v1

import (
	"regexp"
	"list"
	http "greymatter.io/gsl/v1/api/filters/http"
	network "greymatter.io/gsl/v1/api/filters/network"

	// envoy http filter imports
	envoy_rbac "envoyproxy.io/extensions/filters/http/rbac/v3"
	envoy_ratelimit "envoyproxy.io/extensions/filters/network/ratelimit/v3"
	envoy_jwt_authn "envoyproxy.io/extensions/filters/http/jwt_authn/v3"
	envoy_fault "envoyproxy.io/extensions/filters/http/fault/v3"
	envoy_ext_authz "envoyproxy.io/extensions/filters/http/ext_authz/v3"
	envoy_http_lua "envoyproxy.io/extensions/filters/http/lua/v3"
	envoy_buffer "envoyproxy.io/extensions/filters/http/buffer/v3"
	envoy_csrf "envoyproxy.io/extensions/filters/http/csrf/v3"
	envoy_grpc_json_transcoder "envoyproxy.io/extensions/filters/http/grpc_json_transcoder/v3"
	envoy_health_check "envoyproxy.io/extensions/filters/http/health_check/v3"
	envoy_ip_tagging "envoyproxy.io/extensions/filters/http/ip_tagging/v3"
	envoy_header_to_metadata "envoyproxy.io/extensions/filters/http/header_to_metadata/v3"
	envoy_cors "envoyproxy.io/extensions/filters/http/cors/v3"
	envoy_grpc_http_bridge "envoyproxy.io/extensions/filters/http/grpc_http1_bridge/v3"
	envoy_grpc_http_reverse_bridge "envoyproxy.io/extensions/filters/http/grpc_http1_reverse_bridge/v3"
	envoy_grpc_web "envoyproxy.io/extensions/filters/http/grpc_web/v3"
	envoy_grpc_stats "envoyproxy.io/extensions/filters/http/grpc_stats/v3"
	envoy_dynamic_forward_proxy "envoyproxy.io/extensions/filters/http/dynamic_forward_proxy/v3"
	envoy_original_src "envoyproxy.io/extensions/filters/http/original_src/v3"
	envoy_compressor "envoyproxy.io/extensions/filters/http/compressor/v3"
	envoy_on_demand "envoyproxy.io/extensions/filters/http/on_demand/v3"
	envoy_adaptive_concurrency "envoyproxy.io/extensions/filters/http/adaptive_concurrency/v3"
	envoy_tap "envoyproxy.io/extensions/filters/http/tap/v3"
	envoy_aws_lambda "envoyproxy.io/extensions/filters/http/aws_lambda/v3"
	envoy_aws_request_signing "envoyproxy.io/extensions/filters/http/aws_request_signing/v3"
	envoy_gzip "envoyproxy.io/extensions/filters/http/gzip/v3"
	envoy_local_rate_limit "envoyproxy.io/extensions/filters/http/local_ratelimit/v3"
	envoy_http_cache "envoyproxy.io/extensions/filters/http/cache/v3"

	// envoy network filter imports
	envoy_tcp_rbac "envoyproxy.io/extensions/filters/network/rbac/v3"
	envoy_tcp_proxy "envoyproxy.io/extensions/filters/network/tcp_proxy/v3"
	envoy_redis_proxy "envoyproxy.io/extensions/filters/network/redis_proxy/v3"
	envoy_mongo_proxy "envoyproxy.io/extensions/filters/network/mongo_proxy/v3"
	envoy_tcp_rate_limit "envoyproxy.io/extensions/filters/network/ratelimit/v3"
	envoy_echo "envoyproxy.io/extensions/filters/network/echo/v3"
	envoy_sni_cluster "envoyproxy.io/extensions/filters/network/sni_cluster/v3"
	envoy_dubbo_proxy "envoyproxy.io/extensions/filters/network/dubbo_proxy/v3"
	envoy_thrift_proxy "envoyproxy.io/extensions/filters/network/thrift_proxy/v3"
	envoy_direct_response "envoyproxy.io/extensions/filters/network/direct_response/v3"
	envoy_zookeeper_proxy "envoyproxy.io/extensions/filters/network/zookeeper_proxy/v3"
	envoy_ext_authz_tcp "envoyproxy.io/extensions/filters/network/ext_authz/v3"
	envoy_tcp_local_rate_limit "envoyproxy.io/extensions/filters/network/local_ratelimit/v3"

	envoy "envoyproxy.io/config/core/v3"
)

// helper - returns all the labels in `from` that are found in `into`
_#extractSubset: {
	from: {...}
	into: {}

	output: {
		for k, v in from {
			if (into & {"\(k)": v}) != _|_ {
				"\(k)": v
			}
		}
	}
}

//TCP Filters
#TCPFilters: {
	"envoy_direct_response"?: envoy_direct_response.#Config
	"envoy_dubbo_proxy"?:     envoy_dubbo_proxy.#DubboProxy
	"envoy_echo"?:            envoy_echo.#Echo
	"envoy_ext_authz"?:       envoy_ext_authz_tcp.#ExtAuthz
	"gm_jwtsecurity"?:        network.#JwtSecurityTcpConfig
	"gm_logger"?:             network.#TcpLoggerConfig
	"gm_metrics"?:            network.#TcpMetricsConfig
	"envoy_mongo_proxy"?:     envoy_mongo_proxy.#MongoProxy
	"gm_audit"?:              network.#ObservablesTCPConfig
	"envoy_rate_limit"?:      envoy_tcp_rate_limit.#RateLimit
	"envoy_local_ratelimit"?: envoy_tcp_local_rate_limit.#LocalRateLimit
	"envoy_rbac"?:            envoy_tcp_rbac.#RBAC
	"envoy_redis_proxy"?:     envoy_redis_proxy.#RedisProxy
	"envoy_sni_cluster"?:     envoy_sni_cluster.#SniCluster
	"envoy_tcp_proxy":        envoy_tcp_proxy.#TcpProxy
	"envoy_thrift_proxy"?:    envoy_thrift_proxy.#ThriftProxy
	"envoy_zookeeper_proxy"?: envoy_zookeeper_proxy.#ZooKeeperProxy
}

#DirectResponseFilter: {
	#options:        envoy_direct_response.#Config
	direct_response: #options
}
#DubboProxyFilter: {
	#options:    envoy_dubbo_proxy.#DubboProxy
	dubbo_proxy: #options
}
#EchoFilter: {
	#options: envoy_echo.#Echo
	echo:     #options
}
#TCPMetricsFilter: {
	#options: network.#TcpMetricsConfig
	metrics: {
		#options
		metrics_ring_buffer_size:                   *4096 | _
		prometheus_system_metrics_interval_seconds: *15 | _
		metrics_key_depth:                          *"1" | _

		//hard defaults
		metrics_host:                "0.0.0.0"
		metrics_dashboard_uri_path:  "/metrics"
		metrics_prometheus_uri_path: "/prometheus"
		metrics_key_function:        "depth"
	}
}
#MongoProxyFilter: {
	#options: envoy_mongo_proxy.#MongoProxy
	mongo:    #options
}
#RedisProxyFilter: {
	#options: envoy_redis_proxy.#RedisProxy
	redis:    #options
}
#SNIClusterFilter: {
	#options:    envoy_sni_cluster.#SniCluster
	sni_cluster: #options
}
#ExtAuthZTCPFilter: {
	#options:       envoy_ext_authz_tcp.#ExtAuthz
	external_authz: #options
}
#JWTSecurityTCPFilter: {
	#options:    network.#JwtSecurityTcpConfig
	jwtsecurity: #options
}
#LoggerConfigTCPFilter: {
	#options: network.#TcpLoggerConfig
	logger:   #options
}
#AuditTCPFilter: {
	#options: network.#ObservablesTCPConfig
	audit:    #options
}
#RBACTCPFilter: {
	#options: envoy_tcp_rbac.#RBAC
	rbac:     #options
}
#RateLimitTCPFilter: {
	#options:   envoy_tcp_rate_limit.#RateLimit
	rate_limit: #options
}

#LocalRateLimitTCPFilter: {
	#options:         envoy_tcp_local_rate_limit.#LocalRateLimit
	local_rate_limit: #options
}

#TCPProxyFilter: {
	// special filter
	envoy_tcp_proxy.#TcpProxy
}
#ThriftProxyFilter: {
	#options: envoy_thrift_proxy.#ThriftProxy
	thrift:   #options
}
#ZookeeperProxyFilter: {
	#options:  envoy_zookeeper_proxy.#ZooKeeperProxy
	zookeeper: #options
}

// HTTP FILTERS
#HTTPFilters: {
	"envoy_adaptive_concurrency"?:      envoy_adaptive_concurrency.#AdaptiveConcurrency
	"envoy_aws_lambda"?:                envoy_aws_lambda.#Config
	"envoy_aws_request_signing"?:       envoy_aws_request_signing.#AwsRequestSigning
	"envoy_buffer"?:                    envoy_buffer.#Buffer
	"envoy_cache"?:                     envoy_http_cache.#CacheConfig
	"envoy_compressor"?:                envoy_compressor.#Compressor
	"envoy_cors"?:                      envoy_cors.#Cors
	"envoy_csrf"?:                      envoy_csrf.#CsrfPolicy
	"envoy_dynamic_forward_proxy"?:     envoy_dynamic_forward_proxy.#FilterConfig
	"envoy_ext_authz"?:                 envoy_ext_authz.#ExtAuthz
	"envoy_fault"?:                     envoy_fault.#HTTPFault
	"envoy_grpc_http1_bridge"?:         envoy_grpc_http_bridge.#Config
	"envoy_grpc_http1_reverse_bridge"?: envoy_grpc_http_reverse_bridge.#FilterConfig
	"envoy_grpc_json_transcoder"?:      envoy_grpc_json_transcoder.#GrpcJsonTranscoder
	"envoy_grpc_stats"?:                envoy_grpc_stats.#FilterConfig
	"envoy_grpc_web"?:                  envoy_grpc_web.#GrpcWeb
	"envoy_gzip"?:                      envoy_gzip.#Gzip
	"envoy_header_to_metadata"?:        envoy_header_to_metadata.#Config
	"envoy_health_check"?:              envoy_health_check.#HealthCheck
	"envoy_ip_tagging"?:                envoy_ip_tagging.#IPTagging
	"envoy_jwt_authn"?:                 envoy_jwt_authn.#JwtAuthentication
	"envoy_lua"?:                       envoy_http_lua.#Lua
	"envoy_on_demand"?:                 envoy_on_demand.#OnDemand
	"envoy_original_src"?:              envoy_original_src.#OriginalSrc
	"envoy_rate_limit"?:                envoy_ratelimit.#RateLimit
	"envoy_local_ratelimit"?:           envoy_local_rate_limit.#LocalRateLimit
	"envoy_rbac"?:                      envoy_rbac.#RBAC
	"envoy_tap"?:                       envoy_tap.#Tap
	"gm_ensure-variables"?:             http.#EnsureVariablesConfig
	"gm_impersonation"?:                http.#ImpersonationConfig
	"gm_inheaders"?:                    http.#InheadersConfig
	"gm_jwtsecurity"?:                  http.#GmJwtSecurityConfig
	"gm_list-auth"?:                    http.#ListAuthConfig
	"gm_metrics"?:                      http.#MetricsConfig
	"gm_oauth"?:                        http.#OauthConfig
	"gm_obfuscate"?:                    http.#ObfuscateConfig
	"gm_observables"?:                  http.#ObservablesConfig
	"gm_oidc-authentication"?:          http.#AuthenticationConfig
	"gm_oidc-validation"?:              http.#ValidationConfig
	"gm_policy"?:                       http.#PolicyConfig
}

_#lookupFilters: {
	adaptive_concurrency:      "envoy_adaptive_concurrency"
	audit:                     "gm_observables"
	aws_lambda:                "envoy_aws_lambda"
	aws_request_signing:       "envoy_aws_request_signing"
	buffer:                    "envoy_buffer"
	cache:                     "envoy_cache"
	compressor:                "envoy_compressor"
	cors:                      "envoy_cors"
	csrf:                      "envoy_csrf"
	direct_response:           "envoy_direct_response"
	dubbo_proxy:               "envoy_dubbo_proxy"
	dynamic_forward_proxy:     "envoy_dynamic_forward_proxy"
	echo:                      "envoy_echo"
	ensure_variables:          "gm_ensure-variables"
	external_authz:            "envoy_ext_authz"
	fault:                     "envoy_fault"
	grpc_http1_bridge:         "envoy_grpc_http1_bridge"
	grpc_http1_reverse_bridge: "envoy_grpc_http1_reverse_bridge"
	grpc_json_transcoder:      "envoy_grpc_json_transcoder"
	grpc_stats:                "envoy_grpc_stats"
	grpc_web:                  "envoy_grpc_web"
	gzip:                      "envoy_gzip"
	header_to_metadata:        "envoy_header_to_metadata"
	health_checks:             "envoy_health_check"
	impersonation:             "gm_impersonation"
	inheaders:                 "gm_inheaders"
	ip_tagging:                "envoy_ip_tagging"
	jwt_authn:                 "envoy_jwt_authn"
	jwtsecurity:               "gm_jwtsecurity"
	list_auth:                 "gm_list-auth"
	logger:                    "gm_logger"
	lua:                       "envoy_lua"
	metrics:                   "gm_metrics"
	mongo_proxy:               "envoy_mongo_proxy"
	oauth:                     "gm_oauth"
	obfuscate:                 "gm_obfuscate"
	oidc_authn:                "gm_oidc-authentication"
	oidc_validate:             "gm_oidc-validation"
	on_demand:                 "envoy_on_demand"
	original_src:              "envoy_original_src"
	policy:                    "gm_policy"
	rate_limit:                "envoy_rate_limit"
	local_rate_limit:          "envoy_local_ratelimit"
	rbac:                      "envoy_rbac"
	redis_proxy:               "envoy_redis_proxy"
	sni_cluster:               "envoy_sni_cluster"
	tap:                       "envoy_tap"
	tcp_proxy:                 "envoy_tcp_proxy"
	thrift_proxy:              "envoy_thrift_proxy"
	zookeeper_proxy:           "envoy_zookeeper_proxy"
}

_#lookupFilterSecrets: {
	metrics_secrets:    "gm_metrics"
	oidc_authn_secrets: "gm_oidc-authentication"
}

#CacheFilter: {
	#options: envoy_http_cache.#CacheConfig & {
		typed_config: {
			type_url: "type.googleapis.com/envoy.extensions.http.cache.simple_http_cache.v3.SimpleHttpCacheConfig"
		}
	}
	cache: #options
}

#LocalRateLimitFilter: {
	#options:         envoy_local_rate_limit.#LocalRateLimit
	local_rate_limit: #options
}

#JwtSecurityFilter: {
	#options:    http.#GmJwtSecurityConfig
	jwtsecurity: #options
}

#JwtAuthenticationFilter: {
	#options: {
		envoy_jwt_authn.#JwtAuthentication
	}
	jwt_authn: {
		#options
	}
}

#OIDCPipelineFilter: {
	#options: {
		http.#EnsureVariablesConfig
		#OIDCAuthenticationFilter.#options

		//custom configuation
		provider_cluster: string
		domain:           *regexp.FindSubmatch(#"^https?://(([\w\d]+\.)+[\w]+)/?"#, #options.serviceUrl)[1] | ""

		idToken: http.#AuthenticationConfig_TokenStorage & {
			location: *"cookie" | _
			key:      *"authz_token" | _
			cookieOptions: {
				domain:   *#options.domain | _
				secure:   *true | _
				httpOnly: *false | _
				path:     *"/" | _
			}

		}

		accessToken: http.#AuthenticationConfig_TokenStorage & {
			location: *"cookie" | _
			key:      *"access_token" | _
			cookieOptions: {
				domain:   *#options.domain | _
				secure:   *true | _
				httpOnly: *false | _
				path:     *"/" | _
			}
		}
		callbackPath:     *"/oauth" | _
		additionalScopes: *["openid"] | _

		//jwt authn exposed configuration
		jwt: j = {
			envoy_jwt_authn.#JwtAuthentication

			remote_jwks: *{
				http_uri: {
					cluster: *#options.provider_cluster | _
					uri:     _provider_host + "/protocol/openid-connect/certs"
					timeout: *"1s" | _
				}
			} | envoy_jwt_authn.#RemoteJwks
			local_jwks?: envoy.#DataSource
			providers: provider: {
				forward:             *true | _
				from_headers:        *[{name: "access_token"}] | _
				payload_in_metadata: *"claims" | _
				issuer:              *_provider_host | _
				audiences:           *[#options.clientId] | _
				if j.local_jwks != _|_ {
					local_jwks: j.local_jwks
				}
				if j.local_jwks == _|_ {
					remote_jwks: j.remote_jwks
				}
			}
			rules: *[
				{
					match: {prefix: "/"}
					requires: {provider_name: "provider"}
				},
			] | _
		}

		//ensure variables
		rules: *[
			{
				copyTo: [
					{
						key:      "access_token"
						location: "header"
					},
				]
				key:      "access_token"
				location: "cookie"
			},
		] | _
		// validation exposed configuration
		enforce: *true | _
		userInfo: {
			location: *"header" | _
			// USER_DN header is currently required for observables
			// application to show user audit data.
			key:    "USER_DN"
			claims: *["name"] | _
		}
	}

	// intermediate values
	_provider_host: "\(#options.provider_host)/\(#options.authRealms)/\(#options.realm)"

	oidc_authn: http.#AuthenticationConfig & {
		// copies all the fields found in  both #authenticationConfig and #options
		(_#extractSubset & {
			from: #options
			into: http.#AuthenticationConfig
		}).output
		#options.tls
		provider: *_provider_host | _
	}

	oidc_validate: http.#ValidationConfig & {
		TLSConfig: {
			useTLS: true
			for k, v in #options.tls {
				"\(k)": *v | _
			}
		}
		userInfo: #options.userInfo
		enforce:  #options.enforce
		provider: *_provider_host | _
		accessToken: {
			key:      "access_token"
			location: *"cookie" | _
		}
	}

	ensure_variables: http.#EnsureVariablesConfig & {
		if #options.rules != _|_ {
			rules: #options.rules
		}

	}

	jwt_authn: envoy_jwt_authn.#JwtAuthentication & {
		for label, v in #options.jwt if !list.Contains(["local_jwks", "remote_jwks"], label) {
			(label): v
		}
	}

	// this makes me sad
	lua: envoy_http_lua.#Lua & {
		// Use Lua pattern matching to get the user's name from encoded JSON object.
		inline_code: """
				function envoy_on_request(handle)
					local user_dn = handle:headers():get('USER_DN')
					parsed_user_dn = string.match(user_dn, '%%7B%%22name%%22:%%22(.*)%%22%%7D')
					parsed_user_dn = string.gsub(parsed_user_dn, '%%20', ' ')
					handle:headers():replace('USER_DN', parsed_user_dn)
				end
			"""
	}

	_#OIDCAuthenticationSecrets
}

_#OIDCAuthenticationSecrets: {
	// Hooks for secret injection
	#secrets: {
		client_secret?: #FilterSecret & {
			filter: _#lookupFilters["oidc_authn"]
			path:   "clientSecret"
		}
	}

	oidc_authn_secrets: #secrets
}
#OIDCAuthenticationFilter: {
	#options: {
		//custom
		provider_host:  string
		_provider_host: "\(provider_host)/\(authRealms)/\(realm)"
		r = realm:      string
		keycloak: {
			pre17: *false | bool
		}
		tls: {
			useTLS:             *true | bool
			certPath?:          string
			keyPath?:           string
			caPath?:            string
			insecureSkipVerify: *false | bool
		}

		if keycloak.pre17 {
			authRealms:      "auth/realms"
			authAdminRealms: "auth/admin/realms"
		}

		// required
		additionalScopes: [...string]
		clientId:        string
		authRealms:      *"realms" | string
		authAdminRealms: *"admin/realms" | string
		callbackPath?:   string
		serviceUrl:      string

		tokenRefresh: http.#AuthenticationConfig_TokenRefreshConfig & {
			enabled:  *true | _
			endpoint: *_provider_host | _
			realm:    *r | _
			useTLS:   *true | _
			// make optional in case token refresh tls certs are different
			for k, v in tls {
				"\(k)": *v | _
			}
			timeoutMs: t
		}
		t = timeoutMs: *1000 | _

		// escape hatch
		http.#AuthenticationConfig
	}

	oidc_authn: http.#AuthenticationConfig & {
		#options.tls
		provider: "\(#options.provider_host)/\(#options.authRealms)/\(#options.realm)"
		(_#extractSubset & {from: #options, into: http.#AuthenticationConfig}).output
	}

	_#OIDCAuthenticationSecrets
}

#OIDCValidationFilter: {
	#options: {
		provider: string
		enforce:  *true | bool
		TLSConfig: {
			useTLS:             *true | _
			insecureSkipVerify: *false | _
		}
	}
	oidc_validate: http.#ValidationConfig & {
		#options
	}
}

// // envoy http extension filters
#LuaFilter: {
	#options: envoy_http_lua.#Lua
	lua:      #options
}
#RBACFilter: {
	#options: envoy_rbac.#RBAC
	rbac:     #options
}
#RateLimitFilter: {
	#options:   envoy_ratelimit.#RateLimit
	rate_limit: #options
}
#FaultInjectionFilter: {
	#options: envoy_fault.#HTTPFault
	fault:    #options
}
#InheadersFilter: {
	#options:  http.#InheadersConfig
	inheaders: #options
}
#ImpersonationFilter: {
	#options:      http.#ImpersonationConfig
	impersonation: #options
}
#EnsureVariablesFilter: {
	#options:         http.#EnsureVariablesConfig
	ensure_variables: #options
}
#ListAuthFilter: {
	#options:  http.#ListAuthConfig
	list_auth: #options
}
#ObfuscateFilter: {
	#options:  http.#ObfuscateConfig
	obfuscate: #options
}
#PolicyFilter: {
	#options: http.#PolicyConfig
	policy:   #options
}
#OAuthFilter: {
	#options: http.#OauthConfig
	oauth:    #options
}

#AuditFilter: {
	#options: http.#ObservablesConfig
	audit:    #options
}
#CSRFFilter: {
	#options: envoy_csrf.#CsrfPolicy
	csrf:     #options
}
#GRPCJSONTranscoderFilter: {
	#options:             envoy_grpc_json_transcoder.#GrpcJsonTranscoder
	grpc_json_transcoder: #options
}
#HealthCheckFilter: {
	#options:      envoy_health_check.#HealthCheck
	health_checks: #options
}
#IPTaggingFilter: {
	#options:   envoy_ip_tagging.#IPTagging
	ip_tagging: #options
}
#HeaderToMetadataFilter: {
	#options:           envoy_header_to_metadata.#Config
	header_to_metadata: #options
}
#CorsFilter: {
	#options: envoy_cors.#Cors
	cors:     #options
}
#GRPCHTTP1BridgeFilter: {
	#options:          envoy_grpc_http_bridge.#Config
	grpc_http1_bridge: #options
}
#GRPCWebFilter: {
	#options: envoy_grpc_web.#GrpcWeb
	grpc_web: #options
}
#GRPCStatsFilter: {
	#options:   envoy_grpc_stats.#FilterConfig
	grpc_stats: #options
}
#DynamicForwardProxyFilter: {
	#options:              envoy_dynamic_forward_proxy.#FilterConfig
	dynamic_forward_proxy: #options
}
#OriginalSourceFilter: {
	#options:     envoy_original_src.#OriginalSrc
	original_src: #options
}
#GRPCHTTP1ReverseBridgeFilter: {
	#options:                  envoy_grpc_http_reverse_bridge.#Config
	grpc_http1_reverse_bridge: #options
}
#CompressorFilter: {
	#options:   envoy_compressor.#Compresor
	compressor: #options
}
#OnDemandFilter: {
	#options:  envoy_on_demand.#OnDemand
	on_demand: #options
}
#AdaptiveConcurrencyFilter: {
	#options:             envoy_adaptive_concurrency.#AdaptiveConcurrency
	adaptive_concurrency: #options
}
#TapFilter: {
	#options: envoy_tap.#Tap
	tap:      #options
}
#AWSLambdaFilter: {
	#options:   envoy_aws_lambda.#Config
	aws_lambda: #options
}
#AWSRequestSigningFilter: {
	#options:            envoy_aws_request_signing.#AwsRequestSigning
	aws_request_signing: #options
}
#GZIPFilter: {
	#options: envoy_gzip.#Gzip
	gzip:     #options
}
#BufferFilter: {
	#options: envoy_buffer.#Buffer
	buffer:   #options
}

#MetricsFilter: {
	#options: {
		http.#MetricsConfig
		impersonate_proxy?: [...{name: string, namespace: string}]
		if impersonate_proxy != _|_ {
			shadow_clusters: [ for p in impersonate_proxy {"\(p.namespace)-\(p.name)"}]
		}

		metrics_port:                               int32
		metrics_receiver:                           http.#MetricsConfig_MetricsReceiver
		metrics_ring_buffer_size:                   *4096 | _
		prometheus_system_metrics_interval_seconds: *15 | _
		metrics_key_depth:                          *"1" | _
	}

	#secrets: {
		aws_access_key_id?: #FilterSecret & {
			filter: _#lookupFilters["metrics"]
			path:   "aws_access_key_id"
		}

		aws_secret_access_key?: #FilterSecret & {
			filter: _#lookupFilters["metrics"]
			path:   "aws_secret_access_key"
		}

		aws_session_token?: #FilterSecret & {
			filter: _#lookupFilters["metrics"]
			path:   "aws_session_token"
		}

		nats_connection_string?: #FilterSecret & {
			filter: _#lookupFilters["metrics"]
			path:   "metrics_receiver.nats_connection_string"
		}

		redis_connection_string?: #FilterSecret & {
			filter: _#lookupFilters["metrics"]
			path:   "metrics_receiver.redis_connection_string"
		}
	}

	metrics: http.#MetricsConfig & {
		for k, v in #options if k != "impersonate_proxy" {
			(k): v
		}

		//hard defaults
		metrics_host:                "0.0.0.0"
		metrics_dashboard_uri_path:  "/metrics"
		metrics_prometheus_uri_path: "/prometheus"
		metrics_key_function:        "depth"
	}

	metrics_secrets: #secrets
}

#ExternalAuthzFilter: {
	#options:       envoy_ext_authz.#ExtAuthz
	external_authz: #options
}

#OPAFilter: {
	#options: {
		{
			discovered_host: {
				// Note: TLS should be configured on the cluster linking OPA with the service
				service_name: string
				namespace:    string
				authority?:   string // envoy defaults this to the cluster_name
			}
		} | {
			static_host: {
				target_uri:  string
				stat_prefix: string
				envoy.#GrpcService_GoogleGrpc
			}
		}

		failure_mode_allow: *false | _
		//escape hatch
		envoy_ext_authz.#ExtAuthz
	}

	external_authz: envoy_ext_authz.#ExtAuthz & {
		transport_api_version: "V3"
		// skip custom fields, only copy fields found in #ExtAuthz
		for k, v in #options if !list.Contains(["discovered_host", "static_host", "request_timeout"], k) {
			(k): v
		}

		grpc_service: {
			if #options.discovered_host != _|_ {
				envoy_grpc: this = {
					if #options.discovered_host.namespace == "" {
						cluster_name: #options.discovered_host.service_name
					}

					if #options.discovered_host.namespace != "" {
						cluster_name: "\(#options.discovered_host.namespace)-\(#options.discovered_host.service_name)"
					}
					authority: *#options.discovered_host.authority | this.cluster_name
				}
			}
			if #options.static_host != _|_ {
				google_grpc: {
					#options.static_host
				}
			}
		}
	}

}
