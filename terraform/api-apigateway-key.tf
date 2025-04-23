# Simple API Gateway with API Key authentication
resource "aws_api_gateway_rest_api" "bloomweaver_api" {
  name        = "${var.project}-api"
  description = "Webhook API for Bloomweaver"
}

# Create webhook resource
resource "aws_api_gateway_resource" "webhook" {
  rest_api_id = aws_api_gateway_rest_api.bloomweaver_api.id
  parent_id   = aws_api_gateway_rest_api.bloomweaver_api.root_resource_id
  path_part   = "webhook"
}

# POST method
resource "aws_api_gateway_method" "webhook_post" {
  rest_api_id      = aws_api_gateway_rest_api.bloomweaver_api.id
  resource_id      = aws_api_gateway_resource.webhook.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

# Lambda integration for POST
resource "aws_api_gateway_integration" "webhook_post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.bloomweaver_api.id
  resource_id             = aws_api_gateway_resource.webhook.id
  http_method             = aws_api_gateway_method.webhook_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.webhook_lambda.invoke_arn
}

# PUT method (for updates)
resource "aws_api_gateway_method" "webhook_put" {
  rest_api_id      = aws_api_gateway_rest_api.bloomweaver_api.id
  resource_id      = aws_api_gateway_resource.webhook.id
  http_method      = "PUT"
  authorization    = "NONE"
  api_key_required = true
}

# Lambda integration for PUT
resource "aws_api_gateway_integration" "webhook_put_integration" {
  rest_api_id             = aws_api_gateway_rest_api.bloomweaver_api.id
  resource_id             = aws_api_gateway_resource.webhook.id
  http_method             = aws_api_gateway_method.webhook_put.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.webhook_lambda.invoke_arn
}

# DELETE method
resource "aws_api_gateway_method" "webhook_delete" {
  rest_api_id      = aws_api_gateway_rest_api.bloomweaver_api.id
  resource_id      = aws_api_gateway_resource.webhook.id
  http_method      = "DELETE"
  authorization    = "NONE"
  api_key_required = true
}

# Lambda integration for DELETE
resource "aws_api_gateway_integration" "webhook_delete_integration" {
  rest_api_id             = aws_api_gateway_rest_api.bloomweaver_api.id
  resource_id             = aws_api_gateway_resource.webhook.id
  http_method             = aws_api_gateway_method.webhook_delete.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.webhook_lambda.invoke_arn
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.webhook_post_integration,
    aws_api_gateway_integration.webhook_put_integration,
    aws_api_gateway_integration.webhook_delete_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.bloomweaver_api.id

  lifecycle {
    create_before_destroy = true
  }
}

# Create API Gateway stage
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.bloomweaver_api.id
  stage_name    = var.environment
}

# Create API usage plan
resource "aws_api_gateway_usage_plan" "bloomweaver_usage_plan" {
  name        = "${var.project}-usage-plan"
  description = "Usage plan for Bloomweaver API"

  api_stages {
    api_id = aws_api_gateway_rest_api.bloomweaver_api.id
    stage  = aws_api_gateway_stage.prod.stage_name
  }

  throttle_settings {
    burst_limit = 50
    rate_limit  = 20
  }
}

# Create API key
resource "aws_api_gateway_api_key" "bloomweaver_api_key" {
  name = "${var.project}-api-key"
}

# Associate API key with usage plan
resource "aws_api_gateway_usage_plan_key" "bloomweaver_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.bloomweaver_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.bloomweaver_usage_plan.id
}

# Lambda permissions for API Gateway
resource "aws_lambda_permission" "api_gateway_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.webhook_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.bloomweaver_api.execution_arn}/*/*"
}

# Output the API Gateway URL
output "api_gateway_url" {
  value = "${aws_api_gateway_stage.prod.invoke_url}/webhook"
}

# Output the API key
output "api_key" {
  value     = aws_api_gateway_api_key.bloomweaver_api_key.value
  sensitive = true
}
