variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "project" {
  type    = string
  default = "bloomweaver"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where resources will be created"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the Auto Scaling Group"
}

variable "ec2_ami" {
  type        = string
  description = "AMI ID for the EC2 instance"
  default     = "ami-0d8d11821a1c1678b"
}

variable "ec2_instance_type" {
  type        = string
  description = "Instance type for the EC2 instance"
  default     = "t3.micro"
}

variable "ec2_volume_size" {
  type        = number
  description = "Volume size for the EC2 instance"
  default     = 8
}

variable "ec2_volume_type" {
  type        = string
  description = "Volume type for the EC2 instance"
  default     = "gp3"
}

variable "lambda_runtime" {
  type        = string
  description = "Runtime for the Lambda function"
  default     = "go1.x"
}

variable "lambda_memory_size_small" {
  type        = number
  description = "Memory size for the small embedding worker Lambda function"
  default     = 128
}

variable "lambda_memory_size_medium" {
  type        = number
  description = "Memory size for the medium embedding worker Lambda function"
  default     = 256
}

variable "lambda_memory_size_large" {
  type        = number
  description = "Memory size for the large embedding worker Lambda function"
  default     = 512
}


variable "lambda_handler" {
  type        = string
  description = "Handler for the Lambda function"
  default     = "main"
}

