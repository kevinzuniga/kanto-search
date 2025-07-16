terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.3.0"
  
  # Configure a backend to store the Terraform state remotely (comment out if not needed)
  # backend "s3" {
  #   bucket         = "terraform-state-kanto"
  #   key            = "kanto-search/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-lock-kanto"
  # }
}

provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      Project     = "kanto-search"
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }
}
