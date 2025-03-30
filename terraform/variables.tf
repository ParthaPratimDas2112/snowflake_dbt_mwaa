variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_bucket_name" {
  description = "S3 bucket name for the project"
  type        = string
  default     = "dbt-snowflake-mwaa-project"
}

variable "mwaa_environment_name" {
  description = "Name of the MWAA environment"
  type        = string
  default     = "dbt-snowflake-mwaa"
}

# Snowflake variables
variable "snowflake_account" {
  description = "Snowflake account identifier"
  type        = string
  default     = ""
}

variable "snowflake_user" {
  description = "Snowflake username"
  type        = string
  default     = ""
}

variable "snowflake_password" {
  description = "Snowflake password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "snowflake_role" {
  description = "Snowflake role to use"
  type        = string
  default     = "ACCOUNTADMIN"
}

variable "snowflake_database" {
  description = "Snowflake database to use"
  type        = string
  default     = "DEMO_DB"
}

variable "snowflake_warehouse" {
  description = "Snowflake warehouse to use"
  type        = string
  default     = "COMPUTE_WH"
}

variable "snowflake_schema" {
  description = "Snowflake schema to use"
  type        = string
  default     = "PUBLIC"
}