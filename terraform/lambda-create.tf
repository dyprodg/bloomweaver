# IAM Role for Create Lambda
resource "aws_iam_role" "create_lambda_role" {
  name = "${var.project}-create-lambda-role"

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
resource "aws_iam_role_policy_attachment" "create_lambda_logs" {
  role       = aws_iam_role.create_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy for SQS access (create queue and s3 queue)
resource "aws_iam_policy" "create_lambda_sqs_policy" {
  name        = "${var.project}-create-lambda-sqs-policy"
  description = "Allow create lambda to access SQS queues"

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
        Resource = [aws_sqs_queue.create_queue.arn]
      },
      {
        Action = [
          "sqs:SendMessage",
          "sqs:SendMessageBatch"
        ]
        Effect   = "Allow"
        Resource = [aws_sqs_queue.create_queue.arn]
        Condition {
          Test     = "ArnEquals"
          Variable = "aws:SourceArn"
          Values   = [aws_lambda_function.webhook_lambda.arn]
        }
      }
    ]
  })

  depends_on = [
    aws_sqs_queue.create_queue,
    aws_lambda_function.webhook_lambda
  ]
}

# Attach policy to Lambda role
resource "aws_iam_role_policy_attachment" "create_lambda_sqs" {
  role       = aws_iam_role.create_lambda_role.name
  policy_arn = aws_iam_policy.create_lambda_sqs_policy.arn
}

# Policy for Pinecone access - in production you might use SecretsManager instead
resource "aws_iam_policy" "create_lambda_pinecone_policy" {
  name        = "${var.project}-create-lambda-pinecone-policy"
  description = "Allow create lambda to access Pinecone (via proxy permissions)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = ["arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${var.project}/pinecone-*"]
      }
    ]
  })
}

# Create Lambda function
resource "aws_lambda_function" "create_lambda" {
  function_name = "${var.project}-create-lambda"
  description   = "Lambda for creating documents in Pinecone"
  role          = aws_iam_role.create_lambda_role.arn
  handler       = "main"
  runtime       = "go1.x"
  filename      = "${path.module}/../lambdas/create/main.zip"
  timeout       = 60
  memory_size   = 128

  environment {
    variables = {
      PINECONE_API_KEY_SECRET = "${var.project}/pinecone/api-key"
      PINECONE_ENVIRONMENT    = "gcp-starter"
      PINECONE_INDEX          = "${var.project}-index"
      S3_QUEUE_URL            = aws_sqs_queue.s3_queue.url
    }
  }

  # Enable tracing with X-Ray
  tracing_config {
    mode = "Active"
  }

  # Tags
  tags = {
    Name        = "${var.project}-create-lambda"
    Environment = var.environment
  }

  depends_on = [
    aws_iam_role_policy_attachment.create_lambda_logs,
    aws_iam_role_policy_attachment.create_lambda_sqs,
    aws_iam_role_policy_attachment.create_lambda_pinecone
  ]
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "create_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.create_lambda.function_name}"
  retention_in_days = 14
}

# Event Source Mapping (SQS trigger)
resource "aws_lambda_event_source_mapping" "create_queue_trigger" {
  event_source_arn = aws_sqs_queue.create_queue.arn
  function_name    = aws_lambda_function.create_lambda.function_name
}

# Outputs
output "create_lambda_arn" {
  value = aws_lambda_function.create_lambda.arn
}

output "create_lambda_name" {
  value = aws_lambda_function.create_lambda.function_name
}
