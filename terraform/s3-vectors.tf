# S3 Bucket for vector embeddings
resource "aws_s3_bucket" "vectors_bucket" {
  bucket = "${var.project}-vectors"

  tags = {
    Name        = "${var.project}-vectors"
    Environment = var.environment
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "vectors_bucket_block_public" {
  bucket = aws_s3_bucket.vectors_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for recovery
resource "aws_s3_bucket_versioning" "vectors_bucket_versioning" {
  bucket = aws_s3_bucket.vectors_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "vectors_bucket_encryption" {
  bucket = aws_s3_bucket.vectors_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Set lifecycle policy
resource "aws_s3_bucket_lifecycle_configuration" "vectors_bucket_lifecycle" {
  bucket = aws_s3_bucket.vectors_bucket.id

  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }

    # Keep old versions for 30 days
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Output the bucket ARN and name
output "vectors_bucket_arn" {
  value = aws_s3_bucket.vectors_bucket.arn
}

output "vectors_bucket_name" {
  value = aws_s3_bucket.vectors_bucket.bucket
}
