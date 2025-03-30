output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.dbt_project_bucket.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.dbt_project_bucket.arn
}

output "mwaa_environment_name" {
  description = "Name of the MWAA environment"
  value       = aws_mwaa_environment.mwaa_environment.name
}

output "mwaa_webserver_url" {
  description = "The webserver URL of the MWAA environment"
  value       = aws_mwaa_environment.mwaa_environment.webserver_url
}

output "mwaa_execution_role_arn" {
  description = "The execution role ARN of the MWAA environment"
  value       = aws_iam_role.mwaa_execution_role.arn
}

output "project_structure" {
  description = "S3 path structure for the project"
  value = {
    dbt_project_path = "${aws_s3_bucket.dbt_project_bucket.id}/dbt_project"
    airflow_dags_path = "${aws_s3_bucket.dbt_project_bucket.id}/airflow/dags"
  }
}