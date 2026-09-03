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
  source = "git::https://github.com/ygminds73/terraform-module-vpc.git"

  cidr_block = var.vpc_cidr
  vpc_name   = "${local.name_prefix}-vpc"
  tags       = local.common_tags
}

# ── Subnets (4 subnets via for_each) ─────────────────────────────────
module "subnets" {
  source = "git::https://github.com/ygminds73/terraform-module-subnet.git"

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
  source = "git::https://github.com/ygminds73/terraform-module-ec2.git"

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

# ── S3 Bucket ─────────────────────────────────────────────────────────
module "s3_bucket" {
  source = "git::https://github.com/ygminds73/terraform-module-s3.git"

  bucket_name = "${local.name_prefix}-${var.bucket_suffix}"
  environment = var.environment
  tags        = merge(local.common_tags, { Purpose = "storage" })
}
