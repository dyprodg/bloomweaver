# S3 Queue Dead Letter Queue
resource "aws_sqs_queue" "s3_queue_dlq" {
  name                      = "${var.project}-s3-queue-dlq"
  delay_seconds             = 0
  max_message_size          = 262144  # 256 KB
  message_retention_seconds = 1209600 # 14 days
  receive_wait_time_seconds = 20

  # Enable server-side encryption
  sqs_managed_sse_enabled = true

  # Set tags
  tags = {
    Name        = "${var.project}-s3-queue-dlq"
    Environment = var.environment
  }
}

# IAM Policy Document for S3 DLQ - allowing Lambdas to send messages
data "aws_iam_policy_document" "s3_queue_dlq_send_policy" {
  statement {
    sid    = "AllowLambdaSendMessage"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage", "sqs:SendMessageBatch"]
    resources = [aws_sqs_queue.s3_queue_dlq.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        aws_lambda_function.delete_lambda.arn
        # Add other lambda ARNs as needed
      ]
    }
  }
}

# Attach send policy to SQS DLQ
resource "aws_sqs_queue_policy" "s3_queue_dlq_send_policy" {
  queue_url = aws_sqs_queue.s3_queue_dlq.url
  policy    = data.aws_iam_policy_document.s3_queue_dlq_send_policy.json
}

# Attach receive policy to SQS DLQ
resource "aws_sqs_queue_policy" "s3_queue_dlq_receive_policy" {
  queue_url = aws_sqs_queue.s3_queue_dlq.url
  policy    = data.aws_iam_policy_document.s3_queue_dlq_receive_policy.json
}

# Output the DLQ ARN for reference
output "s3_queue_dlq_arn" {
  value = aws_sqs_queue.s3_queue_dlq.arn
}
