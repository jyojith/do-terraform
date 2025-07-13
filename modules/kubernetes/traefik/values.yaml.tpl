deployment:
  kind: Deployment

podSecurityContext:
  fsGroup: 65532

ports:
  web:
    port: 8000
    expose: true
    exposedPort: 80
    protocol: TCP
  websecure:
    port: 8443
    expose: true
    exposedPort: 443
    protocol: TCP
  traefik:
    port: 9000
    expose: true
    exposedPort: 9000
    protocol: TCP

ingressRoute:
  dashboard:
    enabled: true

service:
  spec:
    type: LoadBalancer

additionalArguments:
  - "--entrypoints.web.address=:8000"
  - "--entrypoints.websecure.address=:8443"
  - "--providers.kubernetesingress=true"
  - "--providers.kubernetescrd=true"
  - "--api.dashboard=true"
  - "--api.insecure=false"
  - "--accesslog=true"
  - "--log.level=DEBUG"

tlsStore:
  default:
    defaultCertificate:
      secretName: ${tls_secret_name}

extraObjects:
  # Dashboard IngressRoute
  - apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
      name: traefik-dashboard
      namespace: traefik
    spec:
      entryPoints:
        - traefik
        - websecure
      routes:
        - match: Host(`traefik.${domain_name}`)
          kind: Rule
          services:
            - name: api@internal
              kind: TraefikService
      tls: {}
