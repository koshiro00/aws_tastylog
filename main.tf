# ----------------------
# Terraform 基本設定
# ----------------------
terraform {
  required_version = ">=1.12.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.0"
    }
  }
  backend "s3" {
    bucket  = "tastylog-tfstate-bucket-yukioka"
    key     = "tasylog-dev.tfstate" # S3のオブジェクト名（変数を使用するとうまくいかないので直記入）
    region  = "ap-northeast-1"
    profile = "terraform"
  }
}

# ----------------------
# AWS プロバイダ
# ----------------------
provider "aws" {
  profile = "terraform"
  region  = "ap-northeast-1"
}
provider "aws" {
  alias   = "virginia"
  profile = "terraform"
  region  = "us-east-1"
}

# ----------------------
# Variables（変数）
# ----------------------
variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "domain" {
  type = string
}