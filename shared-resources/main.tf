provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.13.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.vpc_azs
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_nat_gateway = var.vpc_enable_nat_gateway

  tags = var.vpc_tags
}

resource "aws_security_group" "server_lb" {
  name   = "${var.name}-server-lb"
  vpc_id = module.vpc.vpc_id

  # Nomad HTTP
  ingress {
    from_port   = 4646
    to_port     = 4646
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }

  # Nomad RPC
  ingress {
    from_port   = 4647
    to_port     = 4647
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "primary" {
  name   = var.name
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }

  # Nomad - HTTP
  ingress {
    from_port       = 4646
    to_port         = 4646
    protocol        = "tcp"
    cidr_blocks     = [var.whitelist_ip]
    security_groups = [aws_security_group.server_lb.id]
  }

  # Nomad - RPC
  ingress {
    from_port       = 4647
    to_port         = 4647
    protocol        = "tcp"
    cidr_blocks     = [var.whitelist_ip]
  }

  # Nomad - Serf
  ingress {
    from_port       = 4648
    to_port         = 4648
    protocol        = "tcp"
    cidr_blocks     = [var.whitelist_ip]
  }

  // ingress {
  //   from_port = 0
  //   to_port   = 0
  //   protocol  = "-1"
  //   self      = true
  // }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "clients_ingress_sg" {
  name   = "nomad-clients-ingress"
  vpc_id = module.vpc.vpc_id

  # Nginx external
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "client_sg" {
  name   = "nomad-clients"
  vpc_id = module.vpc.vpc_id

  # Nginx access to demo webapp
  // ingress {
  //   from_port       = 8080
  //   to_port         = 8080
  //   protocol        = "tcp"
  //   security_groups = [aws_security_group.clients_ingress_sg.id]
  // }

  # Nginx access to demo webapp
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  // ingress {
  //   from_port       = 5432
  //   to_port         = 5432
  //   protocol        = "tcp"
  //   cidr_blocks     = ["0.0.0.0/0"]
  // }

  // ingress {
  //   from_port       = 3000
  //   to_port         = 3000
  //   protocol        = "tcp"
  //   cidr_blocks     = ["0.0.0.0/0"]
  // }
  
  // ingress {
  //   from_port       = 8080
  //   to_port         = 8080
  //   protocol        = "tcp"
  //   cidr_blocks     = ["0.0.0.0/0"]
  // }

  // ingress {
  //   from_port       = 9090
  //   to_port         = 9090
  //   protocol        = "tcp"
  //   cidr_blocks     = ["0.0.0.0/0"]
  // }

  // ingress {
  //   from_port       = 8081
  //   to_port         = 8081
  //   protocol        = "tcp"
  //   cidr_blocks     = ["0.0.0.0/0"]
  // }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "instance_profile" {
  name_prefix = var.name
  role        = aws_iam_role.instance_role.name
}

resource "aws_iam_role" "instance_role" {
  name_prefix        = var.name
  assume_role_policy = data.aws_iam_policy_document.instance_role.json
}

data "aws_iam_policy_document" "instance_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "auto_discover_cluster" {
  name   = "auto-discover-cluster"
  role   = aws_iam_role.instance_role.id
  policy = data.aws_iam_policy_document.auto_discover_cluster.json
}

data "aws_iam_policy_document" "auto_discover_cluster" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "autoscaling:DescribeAutoScalingGroups",
    ]

    resources = ["*"]
  }
}