terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "medibook"
  default_tags {
    tags = {
      Project   = "MediBook"
      Activity  = "Aurora-vs-RDS"
      ManagedBy = "Terraform"
    }
  }
}
