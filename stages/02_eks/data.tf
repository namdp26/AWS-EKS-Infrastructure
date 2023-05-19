data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "dbiz-tf-state-bucket"
    key    = "eks.tfstate"
    region = var.region
  }
}