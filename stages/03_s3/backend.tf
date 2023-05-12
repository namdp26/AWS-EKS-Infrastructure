data "terraform_remote_state" "s3" {
  backend = "s3"
  config = {
    bucket = "dbiz-tf-state-bucket"
    key    = "s3.tfstate"
    region = var.region
  }
}