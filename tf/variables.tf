variable "project" {
  type    = string
  default = "website-s3-cloudfront-20210905"
}

variable "distribution_min_ttl" {
  type    = number
  default = 0
}

variable "distribution_default_ttl" {
  type    = number
  default = 3600
}

variable "distribution_max_ttl" {
  type    = number
  default = 86400
}
