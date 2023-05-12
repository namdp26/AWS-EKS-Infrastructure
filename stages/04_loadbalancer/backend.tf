data "terraform_remote_state" "loadbalancer" {
  backend = "s3"
  config = {
    bucket = "dbiz-tf-state-bucket"
    key    = "lb.tfstate"
    region = var.region
  }
}