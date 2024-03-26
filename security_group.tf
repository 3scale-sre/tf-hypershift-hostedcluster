resource "aws_security_group" "worker" {
  name        = format("%s-worker-sg", local.name)
  description = "worker security group"
  vpc_id      = var.vpc_id
  tags = {
    Name                                           = format("%s-worker-sg", local.name)
    format("kubernetes.io/cluster/%s", local.name) = "owned"
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes ingress rules, as they will be modified
      # by openshift controllers
      ingress,
    ]
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    protocol    = "-1"
    self        = "false"
    to_port     = "0"
  }

  ingress {
    cidr_blocks = local.cidr_blocks
    from_port   = "-1"
    protocol    = "icmp"
    self        = "false"
    to_port     = "-1"
  }

  ingress {
    cidr_blocks = local.cidr_blocks
    from_port   = "22"
    protocol    = "tcp"
    self        = "false"
    to_port     = "22"
  }

  ingress {
    cidr_blocks = local.cidr_blocks
    from_port   = "443"
    protocol    = "tcp"
    self        = "false"
    to_port     = "443"
  }

  ingress {
    cidr_blocks = local.cidr_blocks
    from_port   = "443"
    protocol    = "udp"
    self        = "false"
    to_port     = "443"
  }

  ingress {
    cidr_blocks = local.cidr_blocks
    from_port   = "6443"
    protocol    = "tcp"
    self        = "false"
    to_port     = "6443"
  }

  ingress {
    cidr_blocks = local.cidr_blocks
    from_port   = "6443"
    protocol    = "udp"
    self        = "false"
    to_port     = "6443"
  }

  ingress {
    from_port = "10250"
    protocol  = "tcp"
    self      = "true"
    to_port   = "10250"
  }

  ingress {
    from_port = "30000"
    protocol  = "tcp"
    self      = "true"
    to_port   = "32767"
  }

  ingress {
    from_port = "30000"
    protocol  = "udp"
    self      = "true"
    to_port   = "32767"
  }

  ingress {
    from_port = "4500"
    protocol  = "udp"
    self      = "true"
    to_port   = "4500"
  }

  ingress {
    from_port = "4789"
    protocol  = "udp"
    self      = "true"
    to_port   = "4789"
  }

  ingress {
    from_port = "500"
    protocol  = "udp"
    self      = "true"
    to_port   = "500"
  }

  ingress {
    from_port = "6081"
    protocol  = "udp"
    self      = "true"
    to_port   = "6081"
  }

  ingress {
    from_port = "9000"
    protocol  = "tcp"
    self      = "true"
    to_port   = "9999"
  }

  ingress {
    from_port = "9000"
    protocol  = "udp"
    self      = "true"
    to_port   = "9999"
  }
}
