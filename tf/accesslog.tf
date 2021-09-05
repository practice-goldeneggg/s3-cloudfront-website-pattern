locals {
  s3_bucket_accesslog = "${var.project}-accesslog"
}

#----------
#
# アクセスログ用バケット
#
#----------
resource "aws_s3_bucket" "access_log" {
  bucket = local.s3_bucket_accesslog

  acl = "log-delivery-write"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name = "${var.project}-accesslog-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "access_log" {
  bucket = aws_s3_bucket.access_log.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
