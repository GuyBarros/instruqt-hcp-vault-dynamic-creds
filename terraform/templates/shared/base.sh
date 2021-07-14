#!/bin/bash
set -x

echo "==> Base"

echo "==> libc6 issue workaround"
echo 'libc6 libraries/restart-without-asking boolean true' | sudo debconf-set-selections

function install_from_url {
  cd /tmp && {
    curl -sfLo "$${1}.zip" "$${2}"
    unzip -qq "$${1}.zip"
    sudo mv "$${1}" "/usr/local/bin/$${1}"
    sudo chmod +x "/usr/local/bin/$${1}"
    rm -rf "$${1}.zip"
  }
}


echo "--> Adding helper for IP retrieval"
sudo tee /etc/profile.d/ips.sh > /dev/null <<EOF
function private_ip {
  curl -s http://169.254.169.254/latest/meta-data/local-ipv4
}

function public_ip {
  curl -s http://169.254.169.254/latest/meta-data/public-ipv4
}
EOF
source /etc/profile.d/ips.sh

echo "--> Updating apt-cache"
ssh-apt update

echo "--> Adding Vault repo"
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
 sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

echo "--> updated version of Nodejs"
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -

echo "--> Installing common dependencies"
apt-get install -y \
  build-essential \
  nodejs \
  curl \
  emacs \
  git \
  jq \
  tmux \
  unzip \
  vim \
  wget \
  tree \
  nfs-kernel-server \
  nfs-common \
  python3-pip \
  ruby-full \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg-agent \
  software-properties-common \
  openjdk-14-jdk-headless \
  prometheus-node-exporter \
  golang-go \
  alien \
  vault-enterprise \
  terraform \
  &>/dev/null

echo "--> making a path to save vault config files"
sudo mkdir -p /etc/vault.d/

echo "--> saving the database info"
sudo mkdir -p /etc/vault.d/
sudo tee /etc/vault.d/terraform.tfvars > /dev/null <<EOF
  hcp_vault_address = "${hcp_vault_addr}"
  hcp_vault_token = "${hcp_vault_admin_token}" #NOTE: THIS IS HORRIBLE PRATCISE, DONT DO IT! (its good only for workshops)
  db_hostname = "${db_hostname}"
  db_port = ${db_port}
  db_name = "${db_name}"
  db_username = "${db_username}"
  db_password = "${db_password}"

EOF

sudo tee /etc/vault.d/variables.tf > /dev/null <<EOF
 variable "hcp_vault_address" {
  description = "private URL for HCP Vault"
}
 variable "hcp_vault_namespace" {
  description = "the HCP Vault namespace we will use for mounting the database secret engine"
  default = "admin"
}

 variable "hcp_vault_token" {
  description = "Admin token for HCP Vault that will be used for configuration"
}
  variable "db_hostname" {
  description = "the hostname of the Database we will configure in Vault"
}

variable "db_port" {
  description = "the port of the Database we will configure in Vault"
}

variable "db_name" {
  description = "the Name of the Database we will configure in Vault"
}

variable "db_username" {
  description = "the admin username of the Database we will configure in Vault"
}

variable "db_password" {
  description = "the password for admin username of the Database we will configure in Vault(this will be rotated after config)"
}

EOF

sudo tee /etc/vault.d/main.tf > /dev/null <<EOF
provider "vault" {
  # It is strongly recommended to configure this provider through the
  # environment variables described above, so that each user can have
  # separate credentials set in the environment.
  #
  # This will default to using $VAULT_ADDR
  # But can be set explicitly
   address = var.hcp_vault_address
   namespace =  var.hcp_vault_namespace
   token = var.hcp_vault_token
}

# create the "mysql" namespace in the default admin namespace
resource "vault_namespace" "mysql" {
  path = "admin/mysql"
}

# configure an aliased provider, scope to the new namespace.
provider vault {
  alias     = "mysql"
  namespace = vault_namespace.mysql.path
  address = var.hcp_vault_address
  token = var.hcp_vault_token
}

# create a policy in the "mysql" namespace
resource "vault_policy" "mysql" {
  provider = vault.mysql

  depends_on = [vault_namespace.mysql]
  name       = "vault_mysql_policy"
  policy     = data.vault_policy_document.list_secrets.hcl
}

data "vault_policy_document" "list_secrets" {
  rule {
    path         = "secret/*"
    capabilities = ["list"]
    description  = "allow List on secrets under everyone/"
  }
}


EOF
