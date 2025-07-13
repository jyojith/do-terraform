### modules/kubernetes/cert_manager/templates/cluster_issuer.yaml.tpl

apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: ${email}
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
      - dns01:
          digitalocean:
            tokenSecretRef:
              name: ${secret_name}
              key: access-token
