output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.api.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.api.arn
}

output "invoke_arn" {
  description = "Invoke ARN for API Gateway integration"
  value       = aws_lambda_function.api.invoke_arn
}

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_api.api.api_endpoint
}

output "api_id" {
  description = "API Gateway API ID"
  value       = aws_apigatewayv2_api.api.id
}

output "custom_domain_url" {
  description = "Custom domain URL (empty if no custom domain)"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : ""
}

output "log_group_name" {
  description = "CloudWatch Log Group name"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "role_arn" {
  description = "ARN of the Lambda execution role (for attaching additional policies)"
  value       = aws_iam_role.lambda.arn
}
