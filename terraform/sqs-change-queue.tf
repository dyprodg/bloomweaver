# SQS Change Queue for embedding
resource "aws_sqs_queue" "change_queue_dlq" {
  name                      = "${var.project}-change-queue-dlq"
  delay_seconds             = 0
  max_message_size          = 262144  # 256 KB
  message_retention_seconds = 1209600 # 14 days
  receive_wait_time_seconds = 20

  # Enable server-side encryption
  sqs_managed_sse_enabled = true

  # Set tags
  tags = {
    Name        = "${var.project}-change-queue-dlq"
    Environment = var.environment
  }
}

# Main Change Queue for embedding worker
resource "aws_sqs_queue" "change_queue" {
  name                       = "${var.project}-change-queue"
  delay_seconds              = 0
  max_message_size           = 262144 # 256 KB
  message_retention_seconds  = 345600 # 4 days
  receive_wait_time_seconds  = 20
  visibility_timeout_seconds = 300 # 5 minutes

  # Enable server-side encryption
  sqs_managed_sse_enabled = true

  # Configure dead-letter queue
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.change_queue_dlq.arn
    maxReceiveCount     = 5
  })

  # Set tags
  tags = {
    Name        = "${var.project}-change-queue"
    Environment = var.environment
  }
}

# IAM Policy Document for SQS Queue
data "aws_iam_policy_document" "change_queue_policy" {
  statement {
    sid    = "AllowLambdaSendMessage"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage", "sqs:SendMessageBatch"]
    resources = [aws_sqs_queue.change_queue.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_lambda_function.webhook_lambda.arn]
    }
  }

  statement {
    sid    = "AllowEC2ReceiveMessage"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.embedding_worker_role.arn]
    }
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility"
    ]
    resources = [aws_sqs_queue.change_queue.arn]
  }
}

# Attach policy to SQS queue
resource "aws_sqs_queue_policy" "change_queue_policy" {
  queue_url = aws_sqs_queue.change_queue.url
  policy    = data.aws_iam_policy_document.change_queue_policy.json
}

# Output the queue URL and ARN
output "change_queue_url" {
  value = aws_sqs_queue.change_queue.url
}

output "change_queue_arn" {
  value = aws_sqs_queue.change_queue.arn
}
