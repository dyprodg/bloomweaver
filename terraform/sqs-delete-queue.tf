# Vector Delete Queue
resource "aws_sqs_queue" "delete_queue" {
  name                       = "${var.project}-delete-queue"
  delay_seconds              = 0
  max_message_size           = 262144 # 256 KB
  message_retention_seconds  = 345600 # 4 days
  receive_wait_time_seconds  = 20
  visibility_timeout_seconds = 180 # 3 minutes

  # Enable server-side encryption
  sqs_managed_sse_enabled = true

  # Configure dead-letter queue
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.delete_queue_dlq.arn
    maxReceiveCount     = 5
  })

  # Set tags
  tags = {
    Name        = "${var.project}-delete-queue"
    Environment = var.environment
  }

  depends_on = [aws_sqs_queue.delete_queue_dlq]
}

# IAM Policy Document for SQS Queue
data "aws_iam_policy_document" "delete_queue_policy" {
  statement {
    sid    = "AllowLambdaSendMessage"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage", "sqs:SendMessageBatch"]
    resources = [aws_sqs_queue.delete_queue.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_lambda_function.webhook_lambda.arn]
    }
  }
}

# Attach policy to SQS queue
resource "aws_sqs_queue_policy" "delete_queue_policy" {
  queue_url = aws_sqs_queue.delete_queue.url
  policy    = data.aws_iam_policy_document.delete_queue_policy.json
}

# Output the queue URL and ARN
output "delete_queue_url" {
  value = aws_sqs_queue.delete_queue.url
}

output "delete_queue_arn" {
  value = aws_sqs_queue.delete_queue.arn
}
