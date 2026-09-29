provider "aws" {
  region = var.aws_region
}

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



# ── VPC ──────────────────────────────────────────────────────────────

module "vpc" {
  source = "git::https://github.com/rupali-sapkal/terraform-module-vpc-main.git"

  cidr_block = var.vpc_cidr
  vpc_name   = "${local.name_prefix}-vpc"
  tags       = local.common_tags
}

# ── Subnets (4 subnets via for_each) ─────────────────────────────────
module "subnets" {
  source = "git::https://github.com/rupali-sapkal/terraform-module-subnet-main.git"

  for_each          = var.subnets
  subnet_name       = "${local.name_prefix}-${each.key}"
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  vpc_id            = module.vpc.vpc_id
  is_public         = each.value.is_public
  tags              = merge(local.common_tags, { SubnetType = each.value.is_public ? "public" : "private" })
}

# ── EC2 Instances (2 instances via for_each) ─────────────────────────
module "ec2_instances" {
  source = "git::https://github.com/rupali-sapkal/terraform-module-ec2-main.git"

  for_each      = var.ec2_instances
  instance_name = "${local.name_prefix}-${each.key}"
  ami_id        = each.value.ami_id
  instance_type = each.value.instance_type
  subnet_id     = module.subnets[each.value.subnet_key].subnet_id
  vpc_id        = module.vpc.vpc_id
  vpc_cidr      = var.vpc_cidr
  environment   = var.environment
  tags          = merge(local.common_tags, { Role = "web-server" })
}


# ─────────────────────────────────────────────
# ELB MODULE
# ─────────────────────────────────────────────

module "elb" {
  source = "git::https://github.com/rupali-sapkal/terraform-module-elb.git"

  name = "${local.name_prefix}-elb"

  # VPC public subnets
  subnets = module.vpc.public_subnets

  # ELB Security Group
  security_groups = [
    aws_security_group.alb_sg.id
  ]

  # Internet-facing ELB
  internal = false

  # ELB listener
  listener = [
    {
      instance_port     = 8080
      instance_protocol = "HTTP"
      lb_port           = 80
      lb_protocol       = "HTTP"
    }
  ]

  # Jenkins health check
  health_check = {
    target              = "HTTP:8080/login"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
  }

  # Jenkins EC2 instance
  number_of_instances = 1

  instances = [
    aws_instance.jenkins.id
  ]

  tags = local.common_tags

  depends_on = [
    module.vpc,
    aws_security_group.alb_sg
  ]
}


# ─────────────────────────────────────────────
# ELB DNS OUTPUT
# ─────────────────────────────────────────────

output "elb_dns_name" {
  description = "ELB DNS name"
  value       = module.elb.elb_dns_name
}
# ── S3 Bucket ─────────────────────────────────────────────────────────
module "s3_bucket" {
  source = "git::https://github.com/rupali-sapkal/terraform-module-s3-main.git"

  bucket_name = "${local.name_prefix}-${var.bucket_suffix}"
  environment = var.environment
  tags        = merge(local.common_tags, { Purpose = "storage" })
}
