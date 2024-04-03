resource "random_bytes" "etcd_encryption_key" {
  length = 32
}

data "template_file" "helm_values" {
  template = yamlencode({
    "name" : local.name
    "namespace" : var.namespace
    "providerDomain" : var.provider_domain
    "publicDomain" : var.consumer_domain
    "publicZoneID" : data.aws_route53_zone.consumer.id
    "privateZoneID" : aws_route53_zone.private.id
    "oidcURL" : local.oidc_url
    "vpcID" : var.vpc_id
    "vpcCidrBlocks" : local.cidr_blocks
    "subnetID" : var.subnet_ids[0]
    "zone" : local.availability_zones[0]
    "region" : data.aws_region.current.name
    "roles" : {
      "controlPlaneOperator" : aws_iam_role.control_plane_operator.arn
      "imageRegistry" : aws_iam_role.openshift_image_registry.arn
      "ingress" : aws_iam_role.openshift_ingress.arn
      "cloudController" : aws_iam_role.cloud_controller.arn
      "network" : aws_iam_role.cloud_network_config_controller.arn
      "nodePool" : aws_iam_role.node_pool.arn
      "storage" : aws_iam_role.aws_ebs_csi_driver_controller.arn
    }
    "pullSecret" : "hypershift-pull-secret"
    "fipsEnabled" : var.fips_enabled
    "oauthEndpointCertificateSecretName" : var.oauth_endpoint_certificate_secret
    "sshKey" : "hypershift-ssh-key"
    "releaseImage" : var.release_image
    "workers" : {
      "profile" : aws_iam_instance_profile.worker.name
      "instanceType" : var.workers_instance_type
      "securityGroup" : aws_security_group.worker.id
      "number" : var.workers_number
    }
    "vault" : {
      "roleID" : vault_approle_auth_backend_role.this.role_id
      "secretID" : vault_approle_auth_backend_role_secret_id.this.secret_id
    }
    "github" : {
      "clientID" : jsondecode(module.github_oauth_idp.value)["clientID"]
      "clientSecret" : jsondecode(module.github_oauth_idp.value)["clientSecret"]
      "teams" : ["3scale/operations"]
    }
    "managedClusterSet" : var.managedclusterset
    "managedClusterExtraLabels" : var.managedcluster_extra_labels
  })
}

resource "helm_release" "hosted_cluster" {
  name  = local.name
  chart = "./${path.module}/hosted-cluster"

  values = [data.template_file.helm_values.rendered]

  # this is to avoid the key being shown in the terraform output
  set {
    name  = "etcdEncryptionKey"
    value = random_bytes.etcd_encryption_key.base64

  }

  timeout = 900

  depends_on = [
    aws_iam_openid_connect_provider.oidc,
    aws_iam_instance_profile.worker,
    aws_iam_role.aws_ebs_csi_driver_controller,
    aws_iam_role.cloud_controller,
    aws_iam_role.cloud_network_config_controller,
    aws_iam_role.control_plane_operator,
    aws_iam_role.node_pool,
    aws_iam_role.openshift_image_registry,
    aws_iam_role.openshift_ingress,
    aws_security_group.worker,
    aws_route53_zone.private,
    aws_route53_zone.internal,
    random_bytes.etcd_encryption_key,
    null_resource.cleanup
  ]
}

module "awscli_provisioner" {
  source  = "doximity/cli-provisioner/aws"
  version = "1.0.0"
}

resource "null_resource" "cleanup" {
  # these `triggers` act as a "cache" of these dependent values, so that at destroy-time
  # they still exist and refer to the same thing they used to refer to when those resources
  # existed (in case they are also being destroyed, or replaced, which is likely given this
  # usage pattern)
  triggers = {
    script       = module.awscli_provisioner.script
    cluster_name = local.name
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<COMMAND
      ${self.triggers.script}
      ${path.module}/cleanup-orphan-aws-resources.sh ${self.triggers.cluster_name}
    COMMAND
  }
}
