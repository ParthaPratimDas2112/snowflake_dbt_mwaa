#!/bin/bash
set -e

# This script deploys the DBT project and Airflow DAGs to S3
# Prerequisites: AWS CLI must be configured with appropriate permissions

# Variables
BUCKET_NAME=${1:-"dbt-snowflake-mwaa-project"}
PROJECT_DIR=$(pwd)

echo "Deploying to S3 bucket: $BUCKET_NAME"

# Check if bucket exists
if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
  echo "Bucket $BUCKET_NAME does not exist. Creating it..."
  aws s3 mb "s3://$BUCKET_NAME"
  
  # Block public access
  aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
else
  echo "Bucket $BUCKET_NAME already exists."
fi

# Deploy DBT project
echo "Deploying DBT project to S3..."
aws s3 cp "$PROJECT_DIR/dbt_project" "s3://$BUCKET_NAME/dbt_project" --recursive

# Deploy Airflow DAGs
echo "Deploying Airflow DAGs to S3..."
aws s3 cp "$PROJECT_DIR/airflow/dags" "s3://$BUCKET_NAME/airflow/dags" --recursive

# Deploy Airflow requirements
echo "Deploying Airflow requirements.txt to S3..."
aws s3 cp "$PROJECT_DIR/airflow/requirements.txt" "s3://$BUCKET_NAME/airflow/requirements.txt"

echo "Deployment completed successfully!"
echo "Project is available at: s3://$BUCKET_NAME/"