#!/usr/bin/env bash
# Install Terraform from releases.hashicorp.com (replaces hashicorp/setup-terraform action).
set -euo pipefail

VERSION="${TF_VERSION:?set TF_VERSION}"
TMP_ZIP="/tmp/terraform_${VERSION}_linux_amd64.zip"

curl -fsSL -o "${TMP_ZIP}" \
  "https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_linux_amd64.zip"

if ! command -v unzip >/dev/null 2>&1; then
  sudo apt-get update -qq
  sudo apt-get install -y -qq unzip
fi

unzip -o -q "${TMP_ZIP}" -d /tmp/terraform-extract
sudo mv /tmp/terraform-extract/terraform /usr/local/bin/terraform
chmod +x /usr/local/bin/terraform
terraform version
