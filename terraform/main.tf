######################################################################
# cgep-pipeline-demo — compliant baseline.
#
# This Terraform exists to demonstrate the GRC gate (lab 04_03) on a
# repo whose default state passes all three policies cleanly:
#   - SC-28 (encryption at rest with a customer KMS CMK)
#   - AC-3  (public access block, all four flags true)
#   - CM-6  (required tags via provider default_tags)
######################################################################

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project         = "cgep-pipeline-demo"
      Environment     = "demo"
      ManagedBy       = "terraform"
      ComplianceScope = "nist-800-53"
    }
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  bucket_name = "${var.name_prefix}-evidence-${random_id.suffix.hex}"
}

######################################################################
# KMS key used to encrypt the evidence bucket. Customer-managed CMK
# satisfies SC-28; required tags come from provider default_tags.
######################################################################
resource "aws_kms_key" "evidence" {
  description             = "CMK for cgep-pipeline-demo evidence bucket"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "evidence" {
  name          = "alias/${var.name_prefix}-evidence"
  target_key_id = aws_kms_key.evidence.id
}

######################################################################
# Evidence bucket. Compliant baseline:
#   - SSE-KMS with the CMK above (SC-28)
#   - Versioning enabled
#   - Public access block, all four flags true (AC-3)
######################################################################
resource "aws_s3_bucket" "evidence" {
  bucket        = local.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "evidence" {
  bucket = aws_s3_bucket.evidence.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.evidence.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "evidence" {
  bucket = aws_s3_bucket.evidence.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "evidence" {
  bucket = aws_s3_bucket.evidence.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "evidence" {
  bucket = aws_s3_bucket.evidence.id

  rule {
    id     = "expire-noncurrent"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}