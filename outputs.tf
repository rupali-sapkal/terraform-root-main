# ─────────────────────────────────────────────
# ENVIRONMENT
# ─────────────────────────────────────────────

output "environment" {
  description = "Current environment"
  value       = var.environment
}


# ─────────────────────────────────────────────
# VPC
# ─────────────────────────────────────────────

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}


# ─────────────────────────────────────────────
# SUBNETS
# ─────────────────────────────────────────────

output "subnet_ids" {
  description = "All subnet IDs"

  value = {
    for k, v in module.subnets :
    k => v.subnet_id
  }
}


# ─────────────────────────────────────────────
# EC2 INSTANCE IDs
# ─────────────────────────────────────────────

output "ec2_instance_ids" {
  description = "All EC2 instance IDs"

  value = {
    for k, v in module.ec2_instances :
    k => v.instance_id
  }
}


# ─────────────────────────────────────────────
# EC2 PUBLIC IPs
# ─────────────────────────────────────────────

output "ec2_public_ips" {
  description = "Public IPs of EC2 instances"

  value = {
    for k, v in module.ec2_instances :
    k => v.public_ip
  }
}


# ─────────────────────────────────────────────
# S3 BUCKET
# ─────────────────────────────────────────────

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = module.s3_bucket.bucket_name
}


# ─────────────────────────────────────────────
# APPLICATION LOAD BALANCER
# ─────────────────────────────────────────────

output "elb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.elb.elb_dns_name
}
