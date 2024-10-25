#
# OIDC Provider
#
resource "aws_iam_openid_connect_provider" "oidc" {
  url            = format("https://%s", local.oidc_url)
  client_id_list = ["openshift"]
  # This value is hardcoded.
  # See https://github.com/openshift/hypershift/blob/de47efa63ec6798a15a1bc8c1ef53d9481839c2c/cmd/infra/aws/iam.go#L528C16-L528C56
  thumbprint_list = ["a9d53002e97e00e043244f3d170d6f4c414104fd"]
}

#
# Worker nodes
#
resource "aws_iam_role" "worker" {
  provider             = aws.consumer
  name                 = format("%s-worker-role", local.name)
  max_session_duration = "3600"
  path                 = "/"
  assume_role_policy   = <<POLICY
{
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Sid": ""
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}

resource "aws_iam_role_policy" "worker" {
  provider = aws.consumer
  name     = format("%s-worker-policy", local.name)
  role     = aws_iam_role.worker.name
  policy   = <<POLICY
{
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeRegions"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}

resource "aws_iam_instance_profile" "worker" {
  provider = aws.consumer
  name     = format("%s-worker", local.name)
  path     = "/"
  role     = aws_iam_role.worker.name
}

#
# AWS EBS CSI Driver controller
#
resource "aws_iam_role" "aws_ebs_csi_driver_controller" {
  provider             = aws.consumer
  name                 = format("%s-aws-ebs-csi-driver-controller", local.name)
  max_session_duration = "3600"
  path                 = "/"
  assume_role_policy   = <<POLICY
{
  "Statement": [
    {
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${local.oidc_url}:sub": "system:serviceaccount:openshift-cluster-csi-drivers:aws-ebs-csi-driver-controller-sa"
        }
      },
      "Effect": "Allow",
      "Principal": {
        "Federated": "${local.oidc_principal}"
      }
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}

resource "aws_iam_role_policy" "aws_ebs_csi_driver_controller" {
  provider = aws.consumer
  name     = format("%s-aws-ebs-csi-driver-controller", local.name)
  role     = aws_iam_role.aws_ebs_csi_driver_controller.name
  policy   = <<POLICY
{
  "Statement": [
    {
      "Action": [
        "ec2:AttachVolume",
        "ec2:CreateSnapshot",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:DeleteSnapshot",
        "ec2:DeleteTags",
        "ec2:DeleteVolume",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DescribeVolumesModifications",
        "ec2:DetachVolume",
        "ec2:ModifyVolume"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:GenerateDataKeyWithoutPlainText",
        "kms:DescribeKey"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "kms:RevokeGrant",
        "kms:CreateGrant",
        "kms:ListGrants"
      ],
      "Condition": {
        "Bool": {
          "kms:GrantIsForAWSResource": true
        }
      },
      "Effect": "Allow",
      "Resource": "*"
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}

#
# Cloud Controller
#
resource "aws_iam_role" "cloud_controller" {
  provider             = aws.consumer
  name                 = format("%s-cloud-controller", local.name)
  max_session_duration = "3600"
  path                 = "/"
  assume_role_policy   = <<POLICY
{
  "Statement": [
    {
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${local.oidc_url}:sub": "system:serviceaccount:kube-system:kube-controller-manager"
        }
      },
      "Effect": "Allow",
      "Principal": {
        "Federated": "${local.oidc_principal}"
      }
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}

resource "aws_iam_role_policy" "cloud_controller" {
  provider = aws.consumer
  name     = format("%s-cloud-controller", local.name)
  role     = aws_iam_role.cloud_controller.name
  policy   = <<POLICY
{
  "Statement": [
    {
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInstances",
        "ec2:DescribeImages",
        "ec2:DescribeRegions",
        "ec2:DescribeRouteTables",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVolumes",
        "ec2:CreateSecurityGroup",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:ModifyInstanceAttribute",
        "ec2:ModifyVolume",
        "ec2:AttachVolume",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CreateRoute",
        "ec2:DeleteRoute",
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteVolume",
        "ec2:DetachVolume",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:DescribeVpcs",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:AttachLoadBalancerToSubnets",
        "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:CreateLoadBalancerPolicy",
        "elasticloadbalancing:CreateLoadBalancerListeners",
        "elasticloadbalancing:ConfigureHealthCheck",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DeleteLoadBalancerListeners",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeLoadBalancerAttributes",
        "elasticloadbalancing:DetachLoadBalancerFromSubnets",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeLoadBalancerPolicies",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
        "iam:CreateServiceLinkedRole",
        "kms:DescribeKey"
      ],
      "Effect": "Allow",
      "Resource": [
        "*"
      ]
    }
  ],
  "Version": "2012-10-17"
}
POLICY

}

#
# Cloud Network Config Controller
#
resource "aws_iam_role" "cloud_network_config_controller" {
  provider             = aws.consumer
  name                 = format("%s-cloud-network-config-controller", local.name)
  max_session_duration = "3600"
  path                 = "/"
  assume_role_policy   = <<POLICY
{
  "Statement": [
    {
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${local.oidc_url}:sub": "system:serviceaccount:openshift-cloud-network-config-controller:cloud-network-config-controller"
        }
      },
      "Effect": "Allow",
      "Principal": {
        "Federated": "${local.oidc_principal}"
      }
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}

resource "aws_iam_role_policy" "cloud_network_config_controller" {
  provider = aws.consumer
  name     = format("%s-cloud-network-config-controller", local.name)
  role     = aws_iam_role.cloud_network_config_controller.name
  policy   = <<POLICY
{
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeInstanceTypes",
        "ec2:UnassignPrivateIpAddresses",
        "ec2:AssignPrivateIpAddresses",
        "ec2:UnassignIpv6Addresses",
        "ec2:AssignIpv6Addresses",
        "ec2:DescribeSubnets",
        "ec2:DescribeNetworkInterfaces"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}

#
# Control Plane Operator
#
resource "aws_iam_role" "control_plane_operator" {
  provider             = aws.consumer
  name                 = format("%s-control-plane-operator", local.name)
  max_session_duration = "3600"
  path                 = "/"
  assume_role_policy   = <<POLICY
{
  "Statement": [
    {
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${local.oidc_url}:sub": "system:serviceaccount:kube-system:control-plane-operator"
        }
      },
      "Effect": "Allow",
      "Principal": {
        "Federated": "${local.oidc_principal}"
      }
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}

resource "aws_iam_role_policy" "control_plane_operator" {
  provider = aws.consumer
  name     = format("%s-control-plane-operator", local.name)
  role     = aws_iam_role.control_plane_operator.name
  policy   = <<POLICY
{
  "Statement": [
    {
      "Action": [
        "ec2:CreateVpcEndpoint",
        "ec2:DescribeVpcEndpoints",
        "ec2:ModifyVpcEndpoint",
        "ec2:DeleteVpcEndpoints",
        "ec2:CreateTags",
        "route53:ListHostedZones",
        "ec2:CreateSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:DeleteSecurityGroup",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets"
      ],
      "Effect": "Allow",
      "Resource": "${aws_route53_zone.internal.arn}"
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}

#
# Node Pool
#
resource "aws_iam_role" "node_pool" {
  provider             = aws.consumer
  name                 = format("%s-node-pool", local.name)
  max_session_duration = "3600"
  path                 = "/"
  assume_role_policy   = <<POLICY
{
  "Statement": [
    {
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${local.oidc_url}:sub": "system:serviceaccount:kube-system:capa-controller-manager"
        }
      },
      "Effect": "Allow",
      "Principal": {
        "Federated": "${local.oidc_principal}"
      }
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}

resource "aws_iam_role_policy" "node_pool" {
  provider = aws.consumer
  name     = format("%s-node-pool", local.name)
  role     = aws_iam_role.node_pool.name
  policy   = <<POLICY
{
  "Statement": [
    {
      "Action": [
        "ec2:AssociateRouteTable",
        "ec2:AttachInternetGateway",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CreateInternetGateway",
        "ec2:CreateNatGateway",
        "ec2:CreateRoute",
        "ec2:CreateRouteTable",
        "ec2:CreateSecurityGroup",
        "ec2:CreateSubnet",
        "ec2:CreateTags",
        "ec2:DeleteInternetGateway",
        "ec2:DeleteNatGateway",
        "ec2:DeleteRouteTable",
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteSubnet",
        "ec2:DeleteTags",
        "ec2:DescribeAccountAttributes",
        "ec2:DescribeAddresses",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeImages",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeInternetGateways",
        "ec2:DescribeNatGateways",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeNetworkInterfaceAttribute",
        "ec2:DescribeRouteTables",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcs",
        "ec2:DescribeVpcAttribute",
        "ec2:DescribeVolumes",
        "ec2:DetachInternetGateway",
        "ec2:DisassociateRouteTable",
        "ec2:DisassociateAddress",
        "ec2:ModifyInstanceAttribute",
        "ec2:ModifyNetworkInterfaceAttribute",
        "ec2:ModifySubnetAttribute",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "tag:GetResources",
        "ec2:CreateLaunchTemplate",
        "ec2:CreateLaunchTemplateVersion",
        "ec2:DescribeLaunchTemplates",
        "ec2:DescribeLaunchTemplateVersions",
        "ec2:DeleteLaunchTemplate",
        "ec2:DeleteLaunchTemplateVersions"
      ],
      "Effect": "Allow",
      "Resource": [
        "*"
      ]
    },
    {
      "Action": [
        "iam:CreateServiceLinkedRole"
      ],
      "Condition": {
        "StringLike": {
          "iam:AWSServiceName": "elasticloadbalancing.amazonaws.com"
        }
      },
      "Effect": "Allow",
      "Resource": [
        "arn:*:iam::*:role/aws-service-role/elasticloadbalancing.amazonaws.com/AWSServiceRoleForElasticLoadBalancing"
      ]
    },
    {
      "Action": [
        "iam:PassRole"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:*:iam::*:role/*-worker-role"
      ]
    },
    {
      "Action": [
        "kms:Decrypt",
        "kms:ReEncrypt",
        "kms:GenerateDataKeyWithoutPlainText",
        "kms:DescribeKey"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "kms:CreateGrant"
      ],
      "Condition": {
        "Bool": {
          "kms:GrantIsForAWSResource": true
        }
      },
      "Effect": "Allow",
      "Resource": "*"
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}

#
# Openshift Image Registry
#
resource "aws_iam_role" "openshift_image_registry" {
  provider             = aws.consumer
  name                 = format("%s-openshift-image-registry", local.name)
  max_session_duration = "3600"
  path                 = "/"
  assume_role_policy   = <<POLICY
{
  "Statement": [
    {
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${local.oidc_url}:sub": [
            "system:serviceaccount:openshift-image-registry:cluster-image-registry-operator",
            "system:serviceaccount:openshift-image-registry:registry"
          ]
        }
      },
      "Effect": "Allow",
      "Principal": {
        "Federated": "${local.oidc_principal}"
      }
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}

resource "aws_iam_role_policy" "openshift_image_registry" {
  provider = aws.consumer
  name     = format("%s-openshift-image-registry", local.name)
  role     = aws_iam_role.openshift_image_registry.name
  policy   = <<POLICY
{
  "Statement": [
    {
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:PutBucketTagging",
        "s3:GetBucketTagging",
        "s3:PutBucketPublicAccessBlock",
        "s3:GetBucketPublicAccessBlock",
        "s3:PutEncryptionConfiguration",
        "s3:GetEncryptionConfiguration",
        "s3:PutLifecycleConfiguration",
        "s3:GetLifecycleConfiguration",
        "s3:GetBucketLocation",
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucketMultipartUploads",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}

#
# Openshift Ingress
#
resource "aws_iam_role" "openshift_ingress" {
  provider             = aws.consumer
  name                 = format("%s-openshift-ingress", local.name)
  max_session_duration = "3600"
  path                 = "/"
  assume_role_policy   = <<POLICY
{
  "Statement": [
    {
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${local.oidc_url}:sub": "system:serviceaccount:openshift-ingress-operator:ingress-operator"
        }
      },
      "Effect": "Allow",
      "Principal": {
        "Federated": "${local.oidc_principal}"
      }
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}

resource "aws_iam_role_policy" "openshift_ingress" {
  provider = aws.consumer
  name     = format("%s-openshift-ingress", local.name)
  role     = aws_iam_role.openshift_ingress.name
  policy   = <<POLICY
{
  "Statement": [
    {
      "Action": [
        "elasticloadbalancing:DescribeLoadBalancers",
        "tag:GetResources",
        "route53:ListHostedZones"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Effect": "Allow",
      "Resource": [
        "${data.aws_route53_zone.consumer.arn}",
        "${aws_route53_zone.private.arn}"
      ]
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}
