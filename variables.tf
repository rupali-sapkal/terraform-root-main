variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (dev, uat, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "Environment must be one of: dev, uat, prod."
  }
}

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
  default     = "myapp"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    cidr      = string
    az        = string
    is_public = bool
  }))
}

variable "ec2_instances" {
  description = "Map of EC2 instances to create"
  type = map(object({
    ami_id        = string
    instance_type = string
    subnet_key    = string
  }))
}

variable "bucket_suffix" {
  description = "Unique suffix for the S3 bucket name"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources via map meta-argument"
  type        = map(string)
  default     = {}
}
