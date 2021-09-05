locals {
  s3_bucket_notwebsite           = "${var.project}-notwebsite"
  distribution_origin_notwebsite = "NotWebSiteOrigin"
}

#----------
#
# 非・webサイトホスティング関連
#
#----------
resource "aws_s3_bucket" "notwebsite" {
  bucket        = local.s3_bucket_notwebsite
  force_destroy = true

  acl = "private"

  cors_rule {
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    allowed_headers = ["*"]
    max_age_seconds = 3600
  }

  logging {
    target_bucket = aws_s3_bucket.access_log.id
    target_prefix = "notwebsite-s3/"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name = "${var.project}-notwebsite-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "notwebsite" {
  bucket = aws_s3_bucket.notwebsite.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "notwebsite" {
  bucket = aws_s3_bucket.notwebsite.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          "AWS" = "${aws_cloudfront_origin_access_identity.notwebsite.iam_arn}"
        }
        Action = [
          "s3:GetObject",
          # "s3:ListBucket"  # ListBucketは許可すべきではない、というプラクティスに準拠
        ]
        Resource = [
          "${aws_s3_bucket.notwebsite.arn}/*",
          # "${aws_s3_bucket.notwebsite.arn}"  # ListBucketは許可すべきではない、というプラクティスに準拠
        ]
      },
      {
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "${aws_s3_bucket.notwebsite.arn}/*",
          "${aws_s3_bucket.notwebsite.arn}",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.notwebsite,
  ]
}

resource "aws_cloudfront_origin_access_identity" "notwebsite" {
  comment = "OAI for notwebsite"
}

resource "aws_cloudfront_distribution" "notwebsite" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  origin {
    origin_id   = local.distribution_origin_notwebsite
    domain_name = aws_s3_bucket.notwebsite.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.notwebsite.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    target_origin_id       = local.distribution_origin_notwebsite
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    forwarded_values {
      query_string = false
      headers      = ["Access-Control-Request-Headers", "Access-Control-Request-Method", "Origin"]
      cookies {
        forward = "none"
      }
    }

    min_ttl     = var.distribution_min_ttl
    default_ttl = var.distribution_default_ttl
    max_ttl     = var.distribution_max_ttl
  }

  custom_error_response {
    error_code         = 403
    response_code      = 403
    response_page_path = "/403.html"
  }

  logging_config {
    bucket          = aws_s3_bucket.access_log.bucket_domain_name
    include_cookies = true
    prefix          = "notwebsite-cloudfront/"
  }

  tags = {
    Name = "${var.project}-notwebsite-cloudfront"
  }
}
