data "terraform_remote_state" "loadbalancer" {
    backend = "s3"
    config = {
      bucket = "dbiz-tf-state-bucket"
      key = "loadbalancer.tfstate"
      region = var.region
    }
}