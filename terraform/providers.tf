terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.1.0"
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project
      ManagedBy   = "terraform"
    }
  }
}

provider "aws" {
  region = var.region
  alias  = "eu-central-1"
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Output the account ID for reference
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
