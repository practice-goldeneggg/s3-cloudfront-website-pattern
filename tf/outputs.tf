output "accesslog_bucket" {
  value = aws_s3_bucket.access_log
}

output "website_bucket" {
  value = aws_s3_bucket.website
}

output "website_distribution" {
  value = aws_cloudfront_distribution.website
}

output "notwebsite_bucket" {
  value = aws_s3_bucket.notwebsite
}

output "notwebsite_distribution" {
  value = aws_cloudfront_distribution.notwebsite
}
