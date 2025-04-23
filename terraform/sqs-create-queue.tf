# SQS Create Queue
resource "aws_sqs_queue" "create_queue" {
  name                      = "${var.project}-create-queue"
  delay_seconds             = 0
  max_message_size          = 262144 # 256 KB
  message_retention_seconds = 345600 # 4 days
  receive_wait_time_seconds = 20

  # Enable server-side encryption
  sqs_managed_sse_enabled = true

  # Set tags
  tags = {
    Name        = "${var.project}-create-queue"
    Environment = var.environment
  }
}

# IAM Policy Document for Create Queue
data "aws_iam_policy_document" "create_queue_policy" {
  statement {
    sid    = "AllowEC2SendMessage"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.embedding_worker_role.arn]
    }
    actions   = ["sqs:SendMessage", "sqs:SendMessageBatch"]
    resources = [aws_sqs_queue.create_queue.arn]
  }
}

# Attach policy to SQS queue
resource "aws_sqs_queue_policy" "create_queue_policy" {
  queue_url = aws_sqs_queue.create_queue.url
  policy    = data.aws_iam_policy_document.create_queue_policy.json
}

# Output the queue URL and ARN
output "create_queue_url" {
  value = aws_sqs_queue.create_queue.url
}

output "create_queue_arn" {
  value = aws_sqs_queue.create_queue.arn
}
