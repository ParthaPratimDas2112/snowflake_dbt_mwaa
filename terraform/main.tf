provider "aws" {
  region = var.aws_region
}

# Create S3 bucket for the project
resource "aws_s3_bucket" "dbt_project_bucket" {
  bucket = var.project_bucket_name
  force_destroy = true
  
  tags = {
    Name        = "DBT Project Bucket"
    Environment = var.environment
    Project     = "DBT Snowflake MWAA"
  }
}

# Block public access to S3 bucket
resource "aws_s3_bucket_public_access_block" "dbt_project_bucket_public_access_block" {
  bucket = aws_s3_bucket.dbt_project_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "dbt_project_folder" {
  bucket = aws_s3_bucket.dbt_project_bucket.id
  key    = "dbt_project/"
  content_type = "application/x-directory"
  content = ""
}

resource "aws_s3_object" "airflow_folder" {
  bucket = aws_s3_bucket.dbt_project_bucket.id
  key    = "airflow/"
  content_type = "application/x-directory"
  content = ""
}

resource "aws_s3_object" "dags_folder" {
  bucket = aws_s3_bucket.dbt_project_bucket.id
  key    = "airflow/dags/"
  content_type = "application/x-directory"
  content = ""
}

# Update this block in main.tf
resource "aws_mwaa_environment" "mwaa_environment" {

  depends_on = [aws_s3_object.requirements_file]

  name = var.mwaa_environment_name
  source_bucket_arn = aws_s3_bucket.dbt_project_bucket.arn
  dag_s3_path = "airflow/dags"
  requirements_s3_path = "airflow/requirements.txt"
  
  execution_role_arn = aws_iam_role.mwaa_execution_role.arn
  
  network_configuration {
    security_group_ids = [aws_security_group.mwaa_sg.id]
    subnet_ids         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  }
  
  airflow_configuration_options = {
    "core.load_examples" = "False"
    "scheduler.min_file_process_interval" = "30"
    "webserver.dag_default_view" = "graph"
  }
  
  environment_class = "mw1.micro"
  
  logging_configuration {
    dag_processing_logs {
      enabled   = true
      log_level = "INFO"
    }
    
    scheduler_logs {
      enabled   = true
      log_level = "INFO"
    }
    
    webserver_logs {
      enabled   = true
      log_level = "INFO"
    }
    
    worker_logs {
      enabled   = true
      log_level = "INFO"
    }
  }
  
  tags = {
    Environment = var.environment
    Project     = "DBT Snowflake MWAA"
  }
}

# Create IAM role for MWAA execution
resource "aws_iam_role" "mwaa_execution_role" {
  name = "mwaa-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "airflow-env.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "airflow.amazonaws.com"
        }
      },
    ]
  })
}

# Create IAM policy for MWAA
resource "aws_iam_policy" "mwaa_execution_policy" {
  name = "mwaa-execution-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject*",
          "s3:GetBucket*",
          "s3:List*",
          "s3:PutObject*",
          "s3:DeleteObject*"
        ]
        Resource = [
          aws_s3_bucket.dbt_project_bucket.arn,
          "${aws_s3_bucket.dbt_project_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:GetLogRecord",
          "logs:GetLogGroupFields",
          "logs:GetQueryResults"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:airflow-${var.mwaa_environment_name}-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups"
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = ["arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:airflow/mwaa/*"]
      }
    ]
  })
}

# Get current account ID
data "aws_caller_identity" "current" {}

# Create SSM Parameter for Snowflake credentials
resource "aws_ssm_parameter" "snowflake_account" {
  name      = "/airflow/connections/snowflake/account"
  type      = "String"
  value     = var.snowflake_account
  overwrite = true
}

resource "aws_ssm_parameter" "snowflake_user" {
  name      = "/airflow/connections/snowflake/user"
  type      = "String"
  value     = var.snowflake_user
  overwrite = true
}

resource "aws_ssm_parameter" "snowflake_password" {
  name      = "/airflow/connections/snowflake/password"
  type      = "SecureString"
  value     = var.snowflake_password
  overwrite = true
}

resource "aws_ssm_parameter" "snowflake_role" {
  name      = "/airflow/connections/snowflake/role"
  type      = "String"
  value     = var.snowflake_role
  overwrite = true
}

resource "aws_ssm_parameter" "snowflake_database" {
  name      = "/airflow/connections/snowflake/database"
  type      = "String"
  value     = var.snowflake_database
  overwrite = true
}

resource "aws_ssm_parameter" "snowflake_warehouse" {
  name      = "/airflow/connections/snowflake/warehouse"
  type      = "String"
  value     = var.snowflake_warehouse
  overwrite = true
}

resource "aws_ssm_parameter" "snowflake_schema" {
  name      = "/airflow/connections/snowflake/schema"
  type      = "String"
  value     = var.snowflake_schema
  overwrite = true
}

resource "aws_s3_object" "requirements_file" {
  bucket = aws_s3_bucket.dbt_project_bucket.id
  key    = "airflow/requirements.txt"
  content = <<-EOT
apache-airflow==2.7.1
apache-airflow-providers-amazon==8.3.0
dbt-snowflake==1.6.1
boto3==1.28.45
cryptography==41.0.4
EOT
}