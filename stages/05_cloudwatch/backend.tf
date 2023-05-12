data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "value"
    key    = ""
    region = ""
  }
}