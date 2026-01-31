terraform {
  required_version = ">= 1.3.0"

  backend "s3" {
    bucket       = "my-terraform-state-bucket"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }



  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
