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
  type = string
}

variable "consumer_domain" {
  type = string
}

variable "release_image" {
  type = string
}
variable "workers_instance_type" {
  type    = string
  default = "t3a.2xlarge"
}
variable "workers_number" {
  type    = number
  default = 1
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
variable "managedclusterset" {
  type    = string
  default = "hypershift"
}
variable "managedcluster_extra_labels" {
  type    = list(string)
  default = []
}
