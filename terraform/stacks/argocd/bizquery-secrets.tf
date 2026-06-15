# App secrets for the bizquery app — provisioned here because the argocd stack already holds the
# cluster kubeconfig and runs before Argo CD reconciles the app, so the Secret exists before pods
# start. Argo CD never tracks this Secret (it's not in git), so `prune` won't touch it. Mirrors the
# traefik module's do_dns secret pattern.
#
# Terraform owns the app namespace (same as the traefik ns), so namespace.yaml was dropped from the
# app kustomization. Argo CD's CreateNamespace=true is a harmless no-op once the ns exists.
# Hardcoded "bizquery" to match the bizquery manifests' metadata.namespace and the ApplicationSet
# element — that's where the pods run. (env.hcl's app_namespace="bizquery-dev" is the app-of-apps
# layer's namespace, NOT the pod namespace, so it must NOT be used here.)
resource "kubernetes_namespace_v1" "app" {
  metadata {
    name = "bizquery"
  }
}

# Generated once and kept in Terraform state (keep state private, like do_token). Rotate by tainting.
# URL-safe (no specials) so the DB password drops cleanly into BQP_DATABASE_URL.
resource "random_password" "db" {
  length  = 24
  special = false
}

resource "random_password" "session" {
  length  = 48
  special = false
}

resource "random_password" "bootstrap" {
  length  = 32
  special = false
}

resource "random_password" "admin" {
  length  = 16
  special = false
}

resource "kubernetes_secret_v1" "bizquery" {
  metadata {
    name      = "bizquery-secrets"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }

  # raw values — the Kubernetes provider base64-encodes them for the API
  data = {
    POSTGRES_PASSWORD = random_password.db.result
    BQP_DATABASE_URL  = "postgresql+psycopg://bqp:${random_password.db.result}@bizquery-postgres:5432/bqp"
    # DigitalOcean Gradient AI model access key — same key drives chat + embeddings
    BQP_CHAT_API_KEY      = trimspace(var.do_model_access_key)
    OPENAI_API_KEY        = trimspace(var.do_model_access_key)
    BQP_SESSION_SECRET    = random_password.session.result
    BQP_BOOTSTRAP_API_KEY = random_password.bootstrap.result
    BQP_ADMIN_PASSWORD    = random_password.admin.result
  }

  type = "Opaque"
}

# Image pull secret so the cluster can pull the private GHCR image (the app's imagePullSecrets:
# ghcr-pull references this by name). var.ghcr_pat is a GitHub PAT with read:packages.
resource "kubernetes_secret_v1" "ghcr_pull" {
  metadata {
    name      = "ghcr-pull"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }
  type = "kubernetes.io/dockerconfigjson"
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "ghcr.io" = {
          username = var.ghcr_username
          password = var.ghcr_pat
          auth     = base64encode("${var.ghcr_username}:${var.ghcr_pat}")
        }
      }
    })
  }
}

# Retrieve with: terragrunt --terragrunt-working-dir environments/dev/argocd output -raw <name>
output "bizquery_admin_password" {
  value     = random_password.admin.result
  sensitive = true
}

output "bizquery_bootstrap_api_key" {
  value     = random_password.bootstrap.result
  sensitive = true
}
