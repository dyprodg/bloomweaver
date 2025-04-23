# IAM Role for Webhook Lambda
resource "aws_iam_role" "webhook_lambda_role" {
  name = "${var.project}-webhook-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach CloudWatch Logs policy to Lambda role
resource "aws_iam_role_policy_attachment" "webhook_lambda_logs" {
  role       = aws_iam_role.webhook_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy to allow Lambda to send messages to SQS
resource "aws_iam_policy" "webhook_lambda_sqs_policy" {
  name        = "${var.project}-webhook-lambda-sqs-policy"
  description = "Allow webhook lambda to send messages to SQS queues"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:SendMessage",
          "sqs:SendMessageBatch",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes"
        ]
        Effect = "Allow"
        Resource = [
          aws_sqs_queue.change_queue.arn,
          aws_sqs_queue.delete_queue.arn
        ]
      }
    ]
  })

  depends_on = [
    aws_sqs_queue.change_queue,
    aws_sqs_queue.delete_queue
  ]
}

# Policy to allow Lambda to use the S3 transfer bucket
resource "aws_iam_policy" "webhook_lambda_s3_policy" {
  name        = "${var.project}-webhook-lambda-s3-policy"
  description = "Allow webhook lambda to write to S3 transfer bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.transfer_bucket.arn,
          "${aws_s3_bucket.transfer_bucket.arn}/*"
        ]
      }
    ]
  })

  depends_on = [
    aws_s3_bucket.transfer_bucket
  ]
}

# Attach SQS policy to Lambda role
resource "aws_iam_role_policy_attachment" "webhook_lambda_sqs" {
  role       = aws_iam_role.webhook_lambda_role.name
  policy_arn = aws_iam_policy.webhook_lambda_sqs_policy.arn
}

# Attach S3 policy to Lambda role
resource "aws_iam_role_policy_attachment" "webhook_lambda_s3" {
  role       = aws_iam_role.webhook_lambda_role.name
  policy_arn = aws_iam_policy.webhook_lambda_s3_policy.arn
}

# Webhook Lambda Function
resource "aws_lambda_function" "webhook_lambda" {
  function_name = "${var.project}-webhook-lambda"
  description   = "Lambda for processing webhook requests (CREATE/UPDATE/DELETE)"
  role          = aws_iam_role.webhook_lambda_role.arn
  handler       = "main"
  runtime       = "go1.x"
  filename      = "${path.module}/../lambdas/webhook/main.zip" # Assumes the compiled Go code is zipped and placed here
  timeout       = 30
  memory_size   = 128

  environment {
    variables = {
      CHANGE_QUEUE_URL = aws_sqs_queue.change_queue.url
      DELETE_QUEUE_URL = aws_sqs_queue.delete_queue.url
      TRANSFER_BUCKET  = aws_s3_bucket.transfer_bucket.bucket
      MAX_SQS_SIZE     = "262144" # 256KB in bytes
    }
  }

  # Enable tracing with X-Ray
  tracing_config {
    mode = "Active"
  }

  # Tags
  tags = {
    Name        = "${var.project}-webhook-lambda"
    Environment = var.environment
  }

  depends_on = [
    aws_iam_role_policy_attachment.webhook_lambda_logs,
    aws_iam_role_policy_attachment.webhook_lambda_sqs,
    aws_iam_role_policy_attachment.webhook_lambda_s3,
    aws_sqs_queue.change_queue,
    aws_sqs_queue.delete_queue,
    aws_s3_bucket.transfer_bucket
  ]
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "webhook_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.webhook_lambda.function_name}"
  retention_in_days = 14
}

# Outputs
output "webhook_lambda_arn" {
  value = aws_lambda_function.webhook_lambda.arn
}

output "webhook_lambda_name" {
  value = aws_lambda_function.webhook_lambda.function_name
}
