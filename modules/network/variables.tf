# Default tags
variable "default_tags" {
  default     = {}
  type        = map(any)
  description = "Default tags to be applied to all AWS resources"
}

# Name prefix
variable "prefix" {
  type        = string
}

# Provision public subnets in custom VPC
variable "public_cidr_blocks" {
  type        = list(string)
  description = "Public Subnet CIDRs"
}

# Provision public subnets in custom VPC
variable "private_cidr_blocks" {
  type        = list(string)
  description = "Private Subnet CIDRs"
}

# VPC CIDR range
variable "vpc_cidr" {
  type        = string
  description = "VPC to host static web site"
}

variable "zones" {
  description = "deploying in multiple zones"
  default     = ["us-east-1b", "us-east-1c", "us-east-1d"]
}

# current environment 
variable "env" {
  default     = "dev"
  type        = string
  description = "Deployment Environment"
}