# S3 Bucket for temporary document transfer
resource "aws_s3_bucket" "transfer_bucket" {
  bucket = "${var.project}-transfer-bucket"

  tags = {
    Name        = "${var.project}-transfer-bucket"
    Environment = var.environment
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "transfer_bucket_block_public" {
  bucket = aws_s3_bucket.transfer_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for recovery
resource "aws_s3_bucket_versioning" "transfer_bucket_versioning" {
  bucket = aws_s3_bucket.transfer_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "transfer_bucket_encryption" {
  bucket = aws_s3_bucket.transfer_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Set lifecycle policy to delete objects after 7 days
resource "aws_s3_bucket_lifecycle_configuration" "transfer_bucket_lifecycle" {
  bucket = aws_s3_bucket.transfer_bucket.id

  rule {
    id     = "auto-delete"
    status = "Enabled"

    expiration {
      days = 7
    }

    # Also clean up expired object versions and incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }
  }
}

# Output the bucket ARN and name
output "transfer_bucket_arn" {
  value = aws_s3_bucket.transfer_bucket.arn
}

output "transfer_bucket_name" {
  value = aws_s3_bucket.transfer_bucket.bucket
}
