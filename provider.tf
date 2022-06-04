provider "aws" {
  region  = "ap-south-1"
  profile = "default"
}

terraform {
  required_providers {
    aws = {
      version = "~> 4.13.0"
      source = "hashicorp/aws"
    }
  }
  required_version = "~> 1.1.7"
}