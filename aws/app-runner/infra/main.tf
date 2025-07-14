# [ Route 53 DNS ]
#        ⬇
# [ CloudFront (optionnel HTTPS cache) ]
#        ⬇
# [ App Runner Public URL ]

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

# Security Cognito
resource "aws_cognito_user_pool" "fastapi_users" {
  name = "fastapi-user-pool"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }

  auto_verified_attributes = ["email"]
}

resource "aws_cognito_user_pool_client" "fastapi_client" {
  name         = "fastapi-client"
  user_pool_id = aws_cognito_user_pool.fastapi_users.id
  generate_secret = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows = ["code", "implicit"]
  allowed_oauth_scopes = ["email", "openid", "profile"]
  callback_urls = ["https://api.example.com/docs"]
  logout_urls   = ["https://api.example.com/logout"]
  supported_identity_providers = ["COGNITO"]
}

resource "aws_cognito_user_pool_domain" "domain" {
  domain       = "fastapi-app-runner-auth"
  user_pool_id = aws_cognito_user_pool.fastapi_users.id
}

# Load Balancer and DNS

resource "aws_route53_zone" "main" {
  name = "example.com"
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "api.example.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.example.com"
  type    = "CNAME"
  ttl     = 300
  records = [aws_apprunner_service.fastapi.service_url]
}
