### modules/kubernetes/cert_manager/templates/wildcard_cert.yaml.tpl

apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-cert
  namespace: traefik
spec:
  secretName: ${secret_name}
  issuerRef:
    name: ${issuer_name}
    kind: ClusterIssuer
  commonName: "*.${domain_name}"
  dnsNames:
    - "*.${domain_name}"
    - "${domain_name}"
