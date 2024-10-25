module "storage_sg_3scale_management_rules" {
  source = "git@github.com:3scale-ops/tf-aws-sg-rules.git?ref=tags/0.3.0"
  sg_id  = aws_security_group.worker.id
}

resource "aws_security_group" "worker" {
  provider    = aws.consumer
  name        = format("%s-worker-sg", local.name)
  description = "worker security group"
  vpc_id      = var.vpc_id

  # lifecycle {
  #   ignore_changes = [
  #     # Ignore changes ingress rules, as they will be modified
  #     # by openshift controllers
  #     ingress,
  #   ]
  # }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    protocol    = "-1"
    self        = "false"
    to_port     = "0"
  }
}
