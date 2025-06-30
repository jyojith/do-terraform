resource "kubernetes_secret_v1" "do_token" {
  metadata {
    name      = "do-dns-secret"
    namespace = "traefik"
  }

  string_data = {
    DO_AUTH_TOKEN = var.do_token
  }

  type = "Opaque"
}

resource "helm_release" "traefik" {
  name             = "traefik"
  namespace        = "traefik"
  repository       = "https://helm.traefik.io/traefik"
  chart            = "traefik"
  version          = "25.0.0"
  create_namespace = true
  timeout          = 300

  values = [
    yamlencode({
      deployment = {
        kind = "Deployment"
      }

      ports = {
        web = {
          port         = 80
          expose       = true
          exposedPort  = 80
          protocol     = "TCP"
        }
        websecure = {
          port         = 443
          expose       = true
          exposedPort  = 443
          protocol     = "TCP"
        }
      }

      ingressRoute = {
        dashboard = {
          enabled = true
        }
      }

      service = {
        spec = {
          type = "LoadBalancer"
        }
      }

      additionalArguments = [
        "--certificatesresolvers.do.acme.dnschallenge=true",
        "--certificatesresolvers.do.acme.dnschallenge.provider=digitalocean",
        "--certificatesresolvers.do.acme.email=jyojith@unisphere.wiki",
        "--certificatesresolvers.do.acme.storage=/data/acme.json",
        "--certificatesresolvers.do.acme.dnschallenge.delaybeforecheck=0",
        "--entrypoints.web.address=:80",
        "--entrypoints.websecure.address=:443"
      ]

      envFrom = [
        {
          secretRef = {
            name = "do-dns-secret"
          }
        }
      ]

      persistence = {
        enabled      = true
        name         = "traefik-acme"
        accessMode   = "ReadWriteOnce"
        size         = "1Gi"
        storageClass = null
      }

      volumes = [
        {
          name = "acme"
          persistentVolumeClaim = {
            claimName = "traefik-acme"
          }
        }
      ]
    })
  ]
}
