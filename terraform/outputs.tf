output "evidence_bucket" {
  value = aws_s3_bucket.evidence.bucket
}

output "evidence_kms_key_arn" {
  value = aws_kms_key.evidence.arn
}
