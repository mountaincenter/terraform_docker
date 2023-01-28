#===================
# s3
#===================

resource "aws_s3_bucket" "web" {
  bucket        = var.bucket_name
  force_destroy = true
}