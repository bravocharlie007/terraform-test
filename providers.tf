terraform {
#  cloud {
#    organization = "EC2-DEPLOYER-DEV"
#    workspaces {
#      name = "terraform-test"
#    }
#  }
  required_version = "1.4.0"
  required_providers {
    aws = {
#      source = "hashicorps/aws"
      version = "4.0.0"
    }
  }
}

provider "aws" {
#  profile = var.sso_profile
  region = var.region
#  access_key = var.aws_access_key_id
#  secret_key = var.aws_secret_access_key

#  endpoints {
#    sts = "https://sts.${var.aws_account_id}.amazonaws.com"
#  }
#  assume_role {
#    role_arn = "arn:aws:iam::${var.aws_account_id}:role/${var.assume_role}"
#  }
}

