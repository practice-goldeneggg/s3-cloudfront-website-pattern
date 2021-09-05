locals {
  s3_bucket_website           = "${var.project}-website"
  distribution_origin_website = "WebSiteOrigin"
}

#----------
#
# webサイトホスティング関連
#
#----------
resource "aws_s3_bucket" "website" {
  bucket        = local.s3_bucket_website
  force_destroy = true

  acl = "public-read"

  # バケット直アクセス時に作用する設定なので、CloudFront経由のアクセスしか想定していない場合は設定自体の意味は無くなる
  website {
    index_document = "index.html"
    error_document = "50x.html"
  }

  cors_rule {
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    allowed_headers = ["*"]
    max_age_seconds = 3600
  }

  logging {
    target_bucket = aws_s3_bucket.access_log.id
    target_prefix = "website-s3/"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name = "${var.project}-website-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFront"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          # "s3:ListBucket"  # ListBucketは許可すべきではない、というプラクティスに準拠
        ]
        Resource = [
          "${aws_s3_bucket.website.arn}/*",
          # "${aws_s3_bucket.website.arn}"  # ListBucketは許可すべきではない、というプラクティスに準拠
        ]
        Condition = {
          StringEquals = {
            "aws:UserAgent" = "Amazon CloudFront"
          }
        }
      },
      # Note: CloudFront以外（AWSコンソールで操作するIAMユーザー等も含めて）拒否してOKなら下記設定を有効化する
      # {
      #   Sid       = "DenyNotCloudFront"
      #   Effect    = "Deny"
      #   Principal = "*"
      #   Action    = "s3:*"
      #   Resource = [
      #     "${aws_s3_bucket.website.arn}/*",
      #     # "${aws_s3_bucket.website.arn}"
      #   ]
      #   Condition = {
      #     StringNotEquals = {
      #       "aws:UserAgent" = "Amazon CloudFront"
      #     }
      #   }
      # }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.website
  ]
}

resource "aws_cloudfront_distribution" "website" {
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
    origin_id   = local.distribution_origin_website
    domain_name = aws_s3_bucket.website.website_endpoint  # サブフォルダのindexアクセスを機能させる為 website_endpoint を指定

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = local.distribution_origin_website
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
    prefix          = "website-cloudfront/"
  }

  tags = {
    Name = "${var.project}-website-cloudfront"
  }
}
