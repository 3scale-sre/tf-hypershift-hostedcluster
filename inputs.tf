locals {
  name               = join("-", [var.environment, var.project, var.cluster])
  oidc_url           = format("%s.s3.%s.amazonaws.com/%s", var.oidc_bucket_name, data.aws_region.current.name, local.name)
  oidc_principal     = format("arn:aws:iam::%s:oidc-provider/%s", data.aws_caller_identity.current.account_id, local.oidc_url)
  cidr_blocks        = [for item in data.aws_vpc.selected.cidr_block_associations : item["cidr_block"]]
  availability_zones = [for item in data.aws_subnet.selected : item["availability_zone"]]
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnet" "selected" {
  count = length(var.subnet_ids)
  id    = var.subnet_ids[count.index]
}

data "aws_route53_zone" "consumer" {
  name = var.consumer_domain
}

data "aws_route53_zone" "provider" {
  name = var.provider_domain
}
