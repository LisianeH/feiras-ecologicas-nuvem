variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix for resource naming"
  type        = string
  default     = "feiras-ecologicas"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "db_name" {
  description = "MySQL database name"
  type        = string
  default     = "feiras"
}

variable "db_username" {
  description = "MySQL username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "MySQL user password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "frontend_instance_type" {
  description = "EC2 instance type for frontend"
  type        = string
  default     = "t3.micro"
}

variable "backend_instance_type" {
  description = "EC2 instance type for backend"
  type        = string
  default     = "t3.micro"
}

variable "allowed_ssh_cidr_blocks" {
  description = "CIDR blocks allowed to access SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "key_name" {
  description = "Optional EC2 key pair name for SSH access"
  type        = string
  default     = ""
}
