# SQS Update Queue
resource "aws_sqs_queue" "update_queue" {
  name                      = "${var.project}-update-queue"
  delay_seconds             = 0
  max_message_size          = 262144 # 256 KB
  message_retention_seconds = 345600 # 4 days
  receive_wait_time_seconds = 20

  # Enable server-side encryption
  sqs_managed_sse_enabled = true

  # Set tags
  tags = {
    Name        = "${var.project}-update-queue"
    Environment = var.environment
  }
}

# IAM Policy Document for Update Queue
data "aws_iam_policy_document" "update_queue_policy" {
  statement {
    sid    = "AllowLambdaSendMessage"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage", "sqs:SendMessageBatch"]
    resources = [aws_sqs_queue.update_queue.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_lambda_function.webhook_lambda.arn]
    }
  }
}

# Attach policy to SQS queue
resource "aws_sqs_queue_policy" "update_queue_policy" {
  queue_url = aws_sqs_queue.update_queue.url
  policy    = data.aws_iam_policy_document.update_queue_policy.json
}

# Output the queue URL and ARN
output "update_queue_url" {
  value = aws_sqs_queue.update_queue.url
}

output "update_queue_arn" {
  value = aws_sqs_queue.update_queue.arn
}
