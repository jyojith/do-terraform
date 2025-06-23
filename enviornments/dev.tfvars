# environments/dev.tfvars
name        = "k8s-dev"
region      = "fra1"
node_count  = 1
node_size   = "s-2vcpu-4gb"
k8s_version = "1.29.1-do.0"

argocd_reserved_ip = "192.0.2.10"
tkong_reserved_ip  = "192.0.2.11"

domain_name = "bizquery.dev"
