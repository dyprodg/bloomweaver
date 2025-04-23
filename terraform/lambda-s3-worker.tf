# IAM Role for S3 Worker Lambda
resource "aws_iam_role" "s3_worker_lambda_role" {
  name = "${var.project}-s3-worker-lambda-role"

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
resource "aws_iam_role_policy_attachment" "s3_worker_lambda_logs" {
  role       = aws_iam_role.s3_worker_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy for SQS access
resource "aws_iam_policy" "s3_worker_lambda_sqs_policy" {
  name        = "${var.project}-s3-worker-lambda-sqs-policy"
  description = "Allow S3 worker lambda to access SQS queue"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Effect   = "Allow"
        Resource = [aws_sqs_queue.s3_queue.arn]
      }
    ]
  })

  depends_on = [aws_sqs_queue.s3_queue]
}

# Policy for S3 access (vectors bucket)
resource "aws_iam_policy" "s3_worker_lambda_s3_policy" {
  name        = "${var.project}-s3-worker-lambda-s3-policy"
  description = "Allow S3 worker lambda to access vectors bucket"

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
          aws_s3_bucket.vectors_bucket.arn,
          "${aws_s3_bucket.vectors_bucket.arn}/*"
        ]
      }
    ]
  })

  depends_on = [aws_s3_bucket.vectors_bucket]
}

# Attach policies to role
resource "aws_iam_role_policy_attachment" "s3_worker_lambda_sqs" {
  role       = aws_iam_role.s3_worker_lambda_role.name
  policy_arn = aws_iam_policy.s3_worker_lambda_sqs_policy.arn
}

resource "aws_iam_role_policy_attachment" "s3_worker_lambda_s3" {
  role       = aws_iam_role.s3_worker_lambda_role.name
  policy_arn = aws_iam_policy.s3_worker_lambda_s3_policy.arn
}

# Create Lambda function
resource "aws_lambda_function" "s3_worker_lambda" {
  function_name = "${var.project}-s3-worker-lambda"
  description   = "Lambda for saving/deleting documents to/from S3"
  role          = aws_iam_role.s3_worker_lambda_role.arn
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  filename      = "${path.module}/../lambdas/s3-worker/main.zip"
  timeout       = 60
  memory_size   = var.lambda_memory_size_small

  environment {
    variables = {
      VECTORS_BUCKET = aws_s3_bucket.vectors_bucket.bucket
    }
  }

  # Enable tracing with X-Ray
  tracing_config {
    mode = "Active"
  }

  # Tags
  tags = {
    Name        = "${var.project}-s3-worker-lambda"
    Environment = var.environment
  }

  depends_on = [
    aws_iam_role_policy_attachment.s3_worker_lambda_logs,
    aws_iam_role_policy_attachment.s3_worker_lambda_sqs,
    aws_iam_role_policy_attachment.s3_worker_lambda_s3,
    aws_s3_bucket.vectors_bucket
  ]
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "s3_worker_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.s3_worker_lambda.function_name}"
  retention_in_days = 14
}

# Event Source Mapping (SQS trigger)
resource "aws_lambda_event_source_mapping" "s3_queue_trigger" {
  event_source_arn = aws_sqs_queue.s3_queue.arn
  function_name    = aws_lambda_function.s3_worker_lambda.function_name
  batch_size       = 10
  enabled          = true
}

# Outputs
output "s3_worker_lambda_arn" {
  value = aws_lambda_function.s3_worker_lambda.arn
}

output "s3_worker_lambda_name" {
  value = aws_lambda_function.s3_worker_lambda.function_name
}
