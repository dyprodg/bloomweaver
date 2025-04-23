# IAM Role for Update Lambda
resource "aws_iam_role" "update_lambda_role" {
  name = "${var.project}-update-lambda-role"

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
resource "aws_iam_role_policy_attachment" "update_lambda_logs" {
  role       = aws_iam_role.update_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy for SQS access (update queue and s3 queue)
resource "aws_iam_policy" "update_lambda_sqs_policy" {
  name        = "${var.project}-update-lambda-sqs-policy"
  description = "Allow update lambda to access SQS queues"

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
        Resource = [aws_sqs_queue.update_queue.arn]
      },
      {
        Action = [
          "sqs:SendMessage",
          "sqs:SendMessageBatch"
        ]
        Effect   = "Allow"
        Resource = [aws_sqs_queue.update_queue.arn]
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = [aws_lambda_function.webhook_lambda.arn]
          }
        }
      }
    ]
  })

  depends_on = [
    aws_sqs_queue.update_queue,
    aws_lambda_function.webhook_lambda
  ]
}

# Attach policy to Lambda role
resource "aws_iam_role_policy_attachment" "update_lambda_sqs" {
  role       = aws_iam_role.update_lambda_role.name
  policy_arn = aws_iam_policy.update_lambda_sqs_policy.arn
}

# Policy for Pinecone access - in production you might use SecretsManager instead
resource "aws_iam_policy" "update_lambda_pinecone_policy" {
  name        = "${var.project}-update-lambda-pinecone-policy"
  description = "Allow update lambda to access Pinecone (via proxy permissions)"

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

# Attach Pinecone policy to Lambda role
resource "aws_iam_role_policy_attachment" "update_lambda_pinecone" {
  role       = aws_iam_role.update_lambda_role.name
  policy_arn = aws_iam_policy.update_lambda_pinecone_policy.arn
}

# Create Lambda function
resource "aws_lambda_function" "update_lambda" {
  function_name = "${var.project}-update-lambda"
  description   = "Lambda for updating documents in Pinecone"
  role          = aws_iam_role.update_lambda_role.arn
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  filename      = "${path.module}/../lambdas/update/main.zip"
  timeout       = 60
  memory_size   = var.lambda_memory_size_small

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
    Name        = "${var.project}-update-lambda"
    Environment = var.environment
  }

  depends_on = [
    aws_iam_role_policy_attachment.update_lambda_logs,
    aws_iam_role_policy_attachment.update_lambda_sqs,
    aws_iam_role_policy_attachment.update_lambda_pinecone
  ]
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "update_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.update_lambda.function_name}"
  retention_in_days = 14
}

# Event Source Mapping (SQS trigger)
resource "aws_lambda_event_source_mapping" "update_queue_trigger" {
  event_source_arn = aws_sqs_queue.update_queue.arn
  function_name    = aws_lambda_function.update_lambda.function_name
}

# Outputs
output "update_lambda_arn" {
  value = aws_lambda_function.update_lambda.arn
}

output "update_lambda_name" {
  value = aws_lambda_function.update_lambda.function_name
}
