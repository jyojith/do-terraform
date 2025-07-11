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

ingressRoute:
  dashboard:
    enabled: true

service:
  spec:
    type: LoadBalancer

additionalArguments:
  - "--entrypoints.web.address=:8000"
  - "--entrypoints.websecure.address=:8443"
  - "--certificatesresolvers.do.acme.dnschallenge=true"
  - "--certificatesresolvers.do.acme.dnschallenge.provider=digitalocean"
  - "--certificatesresolvers.do.acme.email=jyojith@unisphere.wiki"
  - "--certificatesresolvers.do.acme.storage=/data/acme.json"
  - "--certificatesresolvers.do.acme.dnschallenge.delaybeforecheck=0"
  - "--api.insecure=true"
  - "--accesslog=true"
  - "--log.level=INFO"

envFrom:
  - secretRef:
      name: do-dns-secret

persistence:
  enabled: true
  existingClaim: ${pvc_name}
  accessMode: ReadWriteOnce
  size: 1Gi
  storageClass: ${storage_class_name}

extraObjects:
  - apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: whoami
      namespace: traefik
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: whoami
      template:
        metadata:
          labels:
            app: whoami
        spec:
          containers:
            - name: whoami
              image: traefik/whoami
              ports:
                - containerPort: 80
  - apiVersion: v1
    kind: Service
    metadata:
      name: whoami
      namespace: traefik
    spec:
      selector:
        app: whoami
      ports:
        - port: 80
  - apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
      name: whoami
      namespace: traefik
    spec:
      entryPoints:
        - websecure
      routes:
        - match: Host(`whoami.${domain_name}`)
          kind: Rule
          services:
            - name: whoami
              port: 80
      tls:
        certResolver: do
