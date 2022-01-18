terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  #S3 bucket for state file
  backend "s3" {
    bucket = "terraform-state-bucket-s3"
    key    = "state-cmdbuild-using-userdata"
    region = "us-east-1"
  }

}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
