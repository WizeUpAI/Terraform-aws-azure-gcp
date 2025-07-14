
output "app_url" {
  value = aws_apprunner_service.fastapi.service_url
}
