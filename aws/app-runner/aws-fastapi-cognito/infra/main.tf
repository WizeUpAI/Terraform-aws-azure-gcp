
provider "aws" {
  region = "us-east-1"
}

resource "aws_ecr_repository" "fastapi" {
  name = "fastapi"
}

resource "aws_apprunner_service" "fastapi" {
  service_name = "fastapi-service"

  source_configuration {
    image_repository {
      image_identifier      = "ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/fastapi:latest"
      image_repository_type = "ECR"
      image_configuration {
        port = "80"
      }
    }
    auto_deployments_enabled = true
  }

  instance_configuration {
    cpu    = "1024"
    memory = "2048"
  }
}

resource "aws_cognito_user_pool" "users" {
  name = "fastapi-users"
}

resource "aws_cognito_user_pool_client" "client" {
  name         = "fastapi-client"
  user_pool_id = aws_cognito_user_pool.users.id
  generate_secret = false
  callback_urls   = ["https://example.com"]
}
