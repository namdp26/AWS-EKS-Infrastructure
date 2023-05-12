module "s3_bucket" {
  source            = "../../modules/s3-bucket"
  bucket            = "dbiz-backup-bucket"
  block_public_acls = true
  force_destroy     = false
  tags = {
    Name        = "dbiz-backup-bucket"
    Environment = "production"
  }
}