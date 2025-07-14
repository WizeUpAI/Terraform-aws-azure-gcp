# ----------------------
# Providers Configuration
# ----------------------
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# ----------------------
# AWS Resources
# ----------------------
resource "aws_instance" "ec2_instance" {
  ami           = var.aws_ami
  instance_type = "t2.micro"
  tags = {
    Name = "Multicloud-AWS-EC2"
  }
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.aws_s3_bucket_name
}

resource "aws_db_instance" "rds_instance" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  name                 = "awsdb"
  username             = "admin"
  password             = var.aws_rds_password
  skip_final_snapshot  = true
}

resource "aws_lambda_function" "lambda" {
  filename         = var.aws_lambda_zip
  function_name    = "lambda-function"
  role             = var.aws_lambda_role_arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.10"
  source_code_hash = filebase64sha256(var.aws_lambda_zip)
}

resource "aws_sagemaker_notebook_instance" "notebook" {
  name          = "sagemaker-notebook"
  instance_type = "ml.t2.medium"
  role_arn      = var.aws_sagemaker_role_arn
}

resource "aws_redshift_cluster" "redshift" {
  cluster_identifier = "redshift-cluster"
  node_type          = "dc2.large"
  master_username    = "admin"
  master_password    = var.aws_redshift_password
  cluster_type       = "single-node"
}