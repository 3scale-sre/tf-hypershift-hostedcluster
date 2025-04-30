variable "project" {
  type = string
}
variable "environment" {
  type = string
}
variable "cluster" {
  type = string
}
variable "namespace" {
  type = string
}
variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}
variable "oidc_bucket_name" {
  type = string
}
variable "provider_domain" {
  type    = string
  default = ""
}

variable "consumer_domain" {
  type = string
}

variable "release_image" {
  type = string
}
variable "worker_instance_type" {
  type    = string
  default = "t3a.2xlarge"
}
variable "worker_autoscaling" {
  type = object({
    min     = number
    max     = number
    enabled = bool
  })
  default = {
    min     = 0
    max     = 0
    enabled = false
  }
}

variable "worker_replicas" {
  type    = number
  default = 1
}
variable "worker_arch" {
  type    = string
  default = "amd64"
}
variable "pull_secret" {
  type      = string
  sensitive = true
}
variable "ssh_key" {
  type      = string
  sensitive = true
}
variable "fips_enabled" {
  type    = bool
  default = false
}
variable "github_oauth_enabled" {
  type    = bool
  default = true
}
variable "github_oauth_authorized_teams" {
  type    = list(string)
  default = ["3scale/operations"]
}
variable "oauth_endpoint_certificate_secret" {
  type    = string
  default = ""
}

variable "deploy_vault_app_role" {
  type    = bool
  default = false
}

variable "managedclusterset" {
  type    = string
  default = "hypershift"
}
variable "managedcluster_extra_labels" {
  type    = list(string)
  default = []
}

variable "tolerations" {
  type = list(object({
    key      = string
    operator = string
    value    = string
    effect   = string
  }))
  default = []
}
variable "node_selector" {
  type = list(object({
    key   = string
    value = string
  }))
  default = []
}
