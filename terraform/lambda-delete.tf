# IAM Role for Delete Lambda
resource "aws_iam_role" "delete_lambda_role" {
  name = "${var.project}-delete-lambda-role"

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
resource "aws_iam_role_policy_attachment" "delete_lambda_logs" {
  role       = aws_iam_role.delete_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy for SQS access (delete queue and S3 queue)
resource "aws_iam_policy" "delete_lambda_sqs_policy" {
  name        = "${var.project}-delete-lambda-sqs-policy"
  description = "Allow delete lambda to access SQS queues"

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
        Resource = [aws_sqs_queue.delete_queue.arn]
      },
      {
        Action = [
          "sqs:SendMessage",
          "sqs:SendMessageBatch"
        ]
        Effect   = "Allow"
        Resource = [aws_sqs_queue.s3_queue.arn]
      }
    ]
  })

  depends_on = [
    aws_sqs_queue.delete_queue,
    aws_sqs_queue.s3_queue
  ]
}

# Policy for Pinecone access - in production you might use SecretsManager instead
resource "aws_iam_policy" "delete_lambda_pinecone_policy" {
  name        = "${var.project}-delete-lambda-pinecone-policy"
  description = "Allow delete lambda to access Pinecone (via proxy permissions)"

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

# Attach policies to role
resource "aws_iam_role_policy_attachment" "delete_lambda_sqs" {
  role       = aws_iam_role.delete_lambda_role.name
  policy_arn = aws_iam_policy.delete_lambda_sqs_policy.arn
}

resource "aws_iam_role_policy_attachment" "delete_lambda_pinecone" {
  role       = aws_iam_role.delete_lambda_role.name
  policy_arn = aws_iam_policy.delete_lambda_pinecone_policy.arn
}

# Delete Lambda function
resource "aws_lambda_function" "delete_lambda" {
  function_name = "${var.project}-delete-lambda"
  description   = "Lambda for deleting documents from Pinecone"
  role          = aws_iam_role.delete_lambda_role.arn
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  filename      = "${path.module}/../lambdas/delete/main.zip"
  timeout       = 60
  memory_size   = var.lambda_memory_size_small

  environment {
    variables = {
      PINECONE_API_KEY_SECRET = "${var.project}/pinecone/api-key" # Name of secret in Secrets Manager
      PINECONE_ENVIRONMENT    = "gcp-starter"                     # Pinecone environment
      PINECONE_INDEX          = "${var.project}-index"            # Pinecone index name
      S3_QUEUE_URL            = aws_sqs_queue.s3_queue.url
    }
  }

  # Enable tracing with X-Ray
  tracing_config {
    mode = "Active"
  }

  # Tags
  tags = {
    Name        = "${var.project}-delete-lambda"
    Environment = var.environment
  }

  depends_on = [
    aws_iam_role_policy_attachment.delete_lambda_logs,
    aws_iam_role_policy_attachment.delete_lambda_sqs,
    aws_iam_role_policy_attachment.delete_lambda_pinecone
  ]
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "delete_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.delete_lambda.function_name}"
  retention_in_days = 14
}

# Event Source Mapping (SQS trigger)
resource "aws_lambda_event_source_mapping" "delete_queue_trigger" {
  event_source_arn = aws_sqs_queue.delete_queue.arn
  function_name    = aws_lambda_function.delete_lambda.function_name
}

# Outputs
output "delete_lambda_arn" {
  value = aws_lambda_function.delete_lambda.arn
}

output "delete_lambda_name" {
  value = aws_lambda_function.delete_lambda.function_name
}
