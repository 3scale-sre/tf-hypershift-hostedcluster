# tf-hypershift-hostedcluster

The module will create a Hypershift HostedCluster in the Hub cluster using the credentials provided in the helm provider (see example below). The module expects an already set up VPC to be provided and will only create the required IAM resources, security groups and hosted zones.
The module will also configure the following:

* A Github oauth applications as Openshift's identity provider
* A Vault approle that grants the cluster access to a specific Vault path so the user can install external-secrets-operator with the provided credentials.

## Example usage

In `settings.tf` configure the required providers:

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "helm" {
  debug = true
  kubernetes {
    host                   = "<server>"
    cluster_ca_certificate = "<certificate-authority-data>"
    client_certificate     = "<client-certificate-data>"
    client_key             = "<client-key-data>"
  }
  experiments {
    manifest = true
  }
}

provider "vault" {
  address = "https://example.com"
}
```

Then onvoke the module in `main.tf` like this:

```hcl
module "hostedcluster" {
  source                = "git@github.com:3scale-ops/tf-hypershift-hostedcluster?ref=tags/0.1.0"
  environment           = "dev"
  project               = "example"
  cluster               = "cluster"
  namespace             = "clusters"
  vpc_id                = "vpc-xxxx"
  subnet_ids            = ["subnet-xxxx"]
  oidc_bucket_name      = "my-bucket"
  consumer_domain       = "consumer.example.com"
  provider_domain       = "provider.example.com"
  release_image         = "quay.io/openshift-release-dev/ocp-release:4.14.10-multi-x86_64"
  workers_instance_type = "t3a.2xlarge"
  workers_number        = 1
  pull_secret           = "hypershift-pull-secret"
  ssh_key               = "hypershift-ssh-key"
  managedclusterset     = "hypershift"
  managedcluster_extra_labels = [
    "environment=dev",
  ]
}
```
