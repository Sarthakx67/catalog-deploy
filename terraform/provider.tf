terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
provider "aws"{
    # Configurations options
    # We can give Access key and Secret Key here,But We woll not dur to Security Credentials
    region = "ap-south-1"
}