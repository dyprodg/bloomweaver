# DynamoDB Table for Document Status Tracking
resource "aws_dynamodb_table" "document_status" {
  name         = "${var.project}-document-status"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "doc_id"

  attribute {
    name = "doc_id"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name        = "${var.project}-document-status"
    Environment = var.environment
  }
}

# Output the DynamoDB table name
output "document_status_table_name" {
  value = aws_dynamodb_table.document_status.name
}

# Output the DynamoDB table ARN
output "document_status_table_arn" {
  value = aws_dynamodb_table.document_status.arn
} 
