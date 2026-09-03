output "environment" {
  description = "Current environment"
  value       = var.environment
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "subnet_ids" {
  description = "All subnet IDs"
  value       = { for k, v in module.subnets : k => v.subnet_id }
}

output "ec2_instance_ids" {
  description = "All EC2 instance IDs"
  value       = { for k, v in module.ec2_instances : k => v.instance_id }
}

output "ec2_public_ips" {
  description = "Public IPs of EC2 instances"
  value       = { for k, v in module.ec2_instances : k => v.public_ip }
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = module.s3_bucket.bucket_name
}
