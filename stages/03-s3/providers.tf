provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "dbiz-tf-state-bucket"
    key    = "s3.tfstate"
    region = "us-east-1"
  }
}