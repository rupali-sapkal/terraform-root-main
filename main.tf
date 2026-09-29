# ─────────────────────────────────────────────
# AWS PROVIDER
# ─────────────────────────────────────────────

provider "aws" {
  region = var.aws_region
}


# ─────────────────────────────────────────────
# LOCALS
# ─────────────────────────────────────────────

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    },
    var.tags
  )
}


# ─────────────────────────────────────────────
# VPC
# ─────────────────────────────────────────────

module "vpc" {
  source = "git::https://github.com/rupali-sapkal/terraform-module-vpc-main.git"

  cidr_block = var.vpc_cidr
  vpc_name   = "${local.name_prefix}-vpc"
  tags       = local.common_tags
}


# ─────────────────────────────────────────────
# SUBNETS
# ─────────────────────────────────────────────

module "subnets" {
  source = "git::https://github.com/rupali-sapkal/terraform-module-subnet-main.git"

  for_each = var.subnets

  subnet_name       = "${local.name_prefix}-${each.key}"
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  vpc_id            = module.vpc.vpc_id
  is_public         = each.value.is_public

  tags = merge(
    local.common_tags,
    {
      SubnetType = each.value.is_public ? "public" : "private"
    }
  )
}


# ─────────────────────────────────────────────
# EC2 INSTANCES
# ─────────────────────────────────────────────

module "ec2_instances" {
  source = "git::https://github.com/rupali-sapkal/terraform-module-ec2-main.git"

  for_each = var.ec2_instances

  instance_name = "${local.name_prefix}-${each.key}"
  ami_id        = each.value.ami_id
  instance_type = each.value.instance_type

  subnet_id = module.subnets[each.value.subnet_key].subnet_id

  vpc_id      = module.vpc.vpc_id
  vpc_cidr    = var.vpc_cidr
  environment = var.environment

  tags = merge(
    local.common_tags,
    {
      Role = "web-server"
    }
  )
}


# ─────────────────────────────────────────────
# ALB SECURITY GROUP
# ─────────────────────────────────────────────

resource "aws_security_group" "alb_sg" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-alb-sg"
    }
  )

  depends_on = [
    module.vpc
  ]
}


# ─────────────────────────────────────────────
# APPLICATION LOAD BALANCER
# ─────────────────────────────────────────────

module "elb" {
  source = "git::https://github.com/rupali-sapkal/terraform-module-elb.git"

  name = "${local.name_prefix}-jenkins"

  # VPC
  vpc_id = module.vpc.vpc_id

  # Public subnets for ALB
  subnets = [
    for key, subnet in module.subnets :
    subnet.subnet_id
    if var.subnets[key].is_public
  ]

  # ALB security group
  security_groups = [
    aws_security_group.alb_sg.id
  ]

  # EC2 instances to attach to target group
  instance_ids = {
    for key, instance in module.ec2_instances :
    key => instance.instance_id
  }

  tags = local.common_tags

  depends_on = [
    module.vpc,
    module.subnets,
    module.ec2_instances,
    aws_security_group.alb_sg
  ]
}


# ─────────────────────────────────────────────
# ELB DNS OUTPUT
# ─────────────────────────────────────────────

output "elb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.elb.elb_dns_name
}


# ─────────────────────────────────────────────
# S3 BUCKET
# ─────────────────────────────────────────────

module "s3_bucket" {
  source = "git::https://github.com/rupali-sapkal/terraform-module-s3-main.git"

  bucket_name = "${local.name_prefix}-${var.bucket_suffix}"
  environment = var.environment

  tags = merge(
    local.common_tags,
    {
      Purpose = "storage"
    }
  )
}
