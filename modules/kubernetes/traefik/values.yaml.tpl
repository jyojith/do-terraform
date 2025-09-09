deployment:
  kind: Deployment

podSecurityContext:
  fsGroup: 65532

providers:
  kubernetesCRD:
    allowCrossNamespace: true
    namespaces: []
  kubernetesIngress:
    allowExternalNameServices: true
    namespaces: []

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
  - "--entrypoints.traefik.address=:9000"
  - "--api.dashboard=true"
  - "--api.insecure=false"
  - "--accesslog=true"
  - "--log.level=DEBUG"
  - "--providers.kubernetesingress=true"
  - "--providers.kubernetescrd=true"
  - "--entrypoints.traefik.http.tls=true"

tlsStore:
  default:
    defaultCertificate:
      secretName: ${tls_secret_name}

extraObjects:
  - apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
      name: traefik-dashboard
      namespace: traefik
      labels:
        traefik.enable: "true"
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
