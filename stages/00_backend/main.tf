module "s3_bucket" {
  source            = "../../modules/s3-bucket"
  bucket            = "dbiz-tf-state-bucket"
  block_public_acls = true
  force_destroy     = false
  tags = {
    Terraform   = "true"
    Environment = "Production"
  }
  versioning = {
    status     = true
    mfa_delete = false
  }
}