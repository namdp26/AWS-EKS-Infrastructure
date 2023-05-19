module "s3_bucket" {
  source            = "../../modules/s3-bucket"
  bucket            = "dbiz-tf-state-bucket"
  restrict_public_buckets = true
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