# Main S3 Queue for persisting Vector data to S3
resource "aws_sqs_queue" "s3_queue" {
  name                       = "${var.project}-s3-queue"
  delay_seconds              = 0
  max_message_size           = 262144 # 256 KB
  message_retention_seconds  = 345600 # 4 days
  receive_wait_time_seconds  = 20
  visibility_timeout_seconds = 180 # 3 minutes

  # Enable server-side encryption
  sqs_managed_sse_enabled = true

  # Configure dead-letter queue
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.s3_queue_dlq.arn
    maxReceiveCount     = 5
  })

  # Set tags
  tags = {
    Name        = "${var.project}-s3-queue"
    Environment = var.environment
  }

  depends_on = [aws_sqs_queue.s3_queue_dlq]
}

# IAM Policy Document for S3 Queue - allowing Lambdas to send messages
data "aws_iam_policy_document" "s3_queue_policy" {
  statement {
    sid    = "AllowLambdaSendMessage"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage", "sqs:SendMessageBatch"]
    resources = [aws_sqs_queue.s3_queue.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        aws_lambda_function.delete_lambda.arn
        # Will need to add create and update lambdas when they are created
      ]
    }
  }
}

# Attach policy to SQS queue
resource "aws_sqs_queue_policy" "s3_queue_policy" {
  queue_url = aws_sqs_queue.s3_queue.url
  policy    = data.aws_iam_policy_document.s3_queue_policy.json
}

# Output the queue URL and ARN
output "s3_queue_url" {
  value = aws_sqs_queue.s3_queue.url
}

output "s3_queue_arn" {
  value = aws_sqs_queue.s3_queue.arn
}
