# [Route 53 DNS]
#        ↓
# [ALB HTTP:80 / HTTPS:443]
#       ↓
# [Cognito Login (via ALB Listener Rules)]
#        ↓
# [FastAPI on ECS Fargate]

variable "aws_region" {}
variable "docker_image" {}
variable "domain_name" {}
variable "route53_zone_id" {}
variable "cognito_domain_prefix" {}
variable "acm_certificate_arn" {}


provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "alb" {
  name               = "fastapi-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.subnet[*].id
}

resource "aws_lb_target_group" "fastapi_tg" {
  name     = "fastapi-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"
  health_check {
    path = "/health"
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type = "authenticate-cognito"
    authenticate_cognito {
      user_pool_arn       = aws_cognito_user_pool.pool.arn
      user_pool_client_id = aws_cognito_user_pool_client.client.id
      user_pool_domain    = aws_cognito_user_pool_domain.domain.domain
    }

    order = 1
  }

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fastapi_tg.arn
  }
}

# ECS Cluster, Task Definition, Service
resource "aws_ecs_cluster" "fastapi_cluster" {
  name = "fastapi-cluster"
}

resource "aws_ecs_task_definition" "fastapi_task" {
  family                   = "fastapi-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "fastapi"
      image     = var.docker_image
      essential = true
      portMappings = [{
        containerPort = 80
        hostPort      = 80
      }]
    }
  ])
}

resource "aws_ecs_service" "fastapi_service" {
  name            = "fastapi-service"
  cluster         = aws_ecs_cluster.fastapi_cluster.id
  task_definition = aws_ecs_task_definition.fastapi_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  network_configuration {
    subnets         = aws_subnet.subnet[*].id
    assign_public_ip = true
    security_groups = [aws_security_group.alb_sg.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.fastapi_tg.arn
    container_name   = "fastapi"
    container_port   = 80
  }
}

# IAM role for ECS Task execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Cognito for Auth
resource "aws_cognito_user_pool" "pool" {
  name = "fastapi-users"
}

resource "aws_cognito_user_pool_client" "client" {
  name         = "fastapi-client"
  user_pool_id = aws_cognito_user_pool.pool.id
  generate_secret = false
}

resource "aws_cognito_user_pool_domain" "domain" {
  domain       = var.cognito_domain_prefix
  user_pool_id = aws_cognito_user_pool.pool.id
}

# Route 53 DNS
resource "aws_route53_record" "dns" {
  zone_id = var.route53_zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

#Prérequis
#Certificat ACM validé pour api.yourdomain.com
#Domaine dans Route 53 avec un Hosted Zone
#Image Docker de FastAPI déjà pushée sur DockerHub ou ECR

#  Rôles des services AWS dans l’architecture exposant FastAPI avec Terraform
#  Service AWS	                Rôle dans l’architecture FastAPI exposée
#  aws_vpc	                    Création du réseau virtuel privé (Virtual Private Cloud) pour isoler l’infra
#  aws_subnet	Sous-réseaux    publics/privés dans le VPC pour héberger les ressources
#  aws_internet_gateway	    Passerelle internet pour accès externe au VPC
#  aws_security_group	        Groupe de sécurité (firewall) contrôlant l’accès réseau (ports, IPs)
#  aws_ecs_cluster	            Cluster ECS (Elastic Container Service) pour déployer les containers FastAPI
#  aws_ecs_task_definition	    Description du container Docker, ressources CPU/mémoire, image Docker
#  aws_ecs_service	            Service ECS qui maintient et scale les tâches (containers)
#  aws_lb                      (Application Load Balancer)	Load balancer HTTP/HTTPS pour distribuer le trafic vers les containers ECS
#  aws_lb_target_group	        Groupe de cibles pour le load balancer, correspond aux containers FastAPI
#  aws_lb_listener	            Listener du Load Balancer qui écoute le port 80/443 et redirige vers le target group
#  aws_route53_zone	        Zone DNS publique pour gérer les noms de domaine (ex: example.com)
#  aws_route53_record	        Enregistrement DNS (A ou CNAME) qui pointe vers le Load Balancer
#  aws_iam_role	            Rôles IAM pour donner les permissions nécessaires aux services ECS, ALB
#  aws_acm_certificate	        Certificat SSL/TLS pour HTTPS, utilisé par le Load Balancer
#  aws_cognito_user_pool	    (Optionnel) Service d’authentification des utilisateurs (OAuth2, OpenID)
#  aws_lb_listener_rule	    (Optionnel) Règles du listener pour intégrer l’authentification Cognito ou WAF


#  En résumé :
#  Réseau & Sécurité : VPC + Subnets + Security Groups + Internet Gateway
#  Conteneur & Orchestration : ECS Cluster + Task Definition + Service
#  Exposition externe : ALB (Application Load Balancer) + Listener + Target Group
#  Nom de domaine : Route53 Zone + Record
#  Sécurité HTTPS : ACM Certificate pour TLS
#  Authentification : AWS Cognito (ou WAF + règles ALB) pour sécuriser l’API