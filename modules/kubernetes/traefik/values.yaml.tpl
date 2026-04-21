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
    enabled: false

service:
  spec:
    type: LoadBalancer

# ACME / Let's Encrypt storage (lego)
persistence:
  enabled: true
  path: /data
  size: 128Mi

certResolvers:
  letsencrypt:
    email: ${email}
    storage: /data/acme.json
    caServer: https://acme-staging-v02.api.letsencrypt.org/directory
    dnsChallenge:
      provider: digitalocean
      delayBeforeCheck: 30

env:
  - name: POD_NAME
    valueFrom:
      fieldRef:
        fieldPath: metadata.name
  - name: POD_NAMESPACE
    valueFrom:
      fieldRef:
        fieldPath: metadata.namespace
  - name: DO_AUTH_TOKEN
    valueFrom:
      secretKeyRef:
        name: traefik-do-dns
        key: access-token
  # Some lego/CLI docs use this name; same token as above (V2 personal access only).
  - name: DO_API_TOKEN
    valueFrom:
      secretKeyRef:
        name: traefik-do-dns
        key: access-token

additionalArguments:
  - "--entrypoints.web.address=:8000"
  - "--entrypoints.websecure.address=:8443"
  - "--entrypoints.traefik.address=:9000"
  - "--ping=true"
  # Manual routing: expose ping on web + websecure (DO LB often health-checks :443; built-in ping is single entrypoint only)
  - "--ping.manualrouting=true"
  - "--api.dashboard=true"
  - "--api.insecure=false"
  - "--accesslog=true"
  - "--log.level=DEBUG"
  - "--providers.kubernetesingress=true"
  - "--providers.kubernetescrd=true"
  - "--entrypoints.traefik.http.tls=true"

extraObjects:
  - apiVersion: traefik.io/v1alpha1
    kind: IngressRoute
    metadata:
      name: traefik-ping-web
      namespace: traefik
    spec:
      entryPoints:
        - web
      routes:
        - match: PathPrefix(`/ping`)
          kind: Rule
          priority: 2147483647
          services:
            - name: ping@internal
              kind: TraefikService
  - apiVersion: traefik.io/v1alpha1
    kind: IngressRoute
    metadata:
      name: traefik-ping-websecure
      namespace: traefik
    spec:
      entryPoints:
        - websecure
      routes:
        - match: PathPrefix(`/ping`)
          kind: Rule
          priority: 2147483647
          services:
            - name: ping@internal
              kind: TraefikService
      # Required for HTTPS entrypoint; default cert is fine for LB probes
      tls: {}
  - apiVersion: traefik.io/v1alpha1
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
      tls:
        certResolver: letsencrypt
        domains:
          - main: '*.${domain_name}'
            sans:
              - '${domain_name}'
