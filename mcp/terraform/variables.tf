# terraform/variables.tf

variable "aws_region" {
  description = "The AWS region to deploy the resources to."
  type        = string
  default     = "ca-central-1"
}

variable "aws_profile" {
  description = "The AWS profile to deploy the resources to."
  type        = string
  default     = "main"
}


variable "project_name" {
  description = "The name of the project."
  type        = string
  default     = "mcp-registry"
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "The CIDR blocks for the public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "The CIDR blocks for the private subnets."
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "db_username" {
  description = "The username for the database."
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "The password for the database."
  type        = string
  sensitive   = true
}
