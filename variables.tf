variable "aws_access_key_id" {
  type = string
  default = ""
}
variable "aws_secret_access_key" {
  type = string
  default = ""
}

variable "aws_account_id" {
  type = string
  default = "191805346255"
}

variable "region" {
  type = string
  description = "aws-deployment-region"
  default = "us-east-1"
}

variable "sso_profile" {
  default = "CharlesIC"
}

variable "assume_role" {
  default = "tf-pave-apply"
}


variable "environment" {
  type = string
  default = "dev"
}