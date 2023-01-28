variable "bucket_name" {}
variable "aws_region" {}
variable "domain_name" {}

locals {
  fqdn = {
    web_name = "web.${var.domain_name}"
  }
  bucket = {
    name = local.fqdn.web_name
  }
}