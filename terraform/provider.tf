terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.49.0"
    }
  }
  required_version = "1.3.7"
  backend "s3" {
    bucket  = "terraform-tfstate-yam"
    region  = "ap-northeast-1"
    key     = "terraform.tfstate"
    encrypt = true
  }
}
provider "aws" {
  region = "ap-northeast-1"
}

provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}