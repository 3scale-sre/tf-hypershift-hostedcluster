resource "aws_route53_zone" "internal" {
  provider      = aws.consumer
  force_destroy = true
  name          = "${local.name}.hypershift.local"

  vpc {
    vpc_id     = var.vpc_id
    vpc_region = data.aws_region.current.name
  }
}

resource "aws_route53_zone" "private" {
  provider      = aws.consumer
  force_destroy = true
  name          = "${local.name}.${data.aws_route53_zone.consumer.name}"

  vpc {
    vpc_id     = var.vpc_id
    vpc_region = data.aws_region.current.name
  }
}
