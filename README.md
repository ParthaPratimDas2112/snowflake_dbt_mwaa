# DBT + Snowflake + MWAA Project

This project demonstrates how to set up a data pipeline using DBT (Data Build Tool) with Snowflake as the data warehouse and Amazon MWAA (Managed Workflows for Apache Airflow) for orchestration. The entire project is stored and executed from S3.

## Project Overview

The project contains two simple DBT models:
1. `customer_sample.sql` - Pulls 10 customer records from Snowflake's sample data
2. `customer_single.sql` - References the first model and selects a single customer record

These models are scheduled and executed daily using an Airflow DAG running on MWAA.

## Project Structure

```
dbt-snowflake-mwaa-project/
├── dbt_project/ - DBT configuration and models
├── airflow/ - Airflow DAGs and requirements
├── terraform/ - Infrastructure as code for AWS resources
├── scripts/ - Deployment and setup scripts
└── README.md - This file
```

## Setup Instructions

### Prerequisites

- AWS CLI installed and configured
- Terraform installed (>= 1.0.0)
- Snowflake account with appropriate permissions
- Basic knowledge of DBT, Airflow, and Snowflake

### Snowflake Setup

1. Connect to your Snowflake account
2. Run the setup script in `scripts/setup_snowflake.sql` to create the necessary database, schema, warehouse, and permissions

### Deploy Infrastructure

1. Update the Terraform variables in `terraform/variables.tf` or create a `terraform.tfvars` file with your specific values
2. Initialize and apply the Terraform configuration:

```bash
cd terraform
terraform init
terraform apply
```

3. Note the S3 bucket name and other outputs from the Terraform apply

### Deploy Project to S3

1. Make the deployment script executable:

```bash
chmod +x scripts/deploy_to_s3.sh
```

2. Run the script with your S3 bucket name:

```bash
./scripts/deploy_to_s3.sh YOUR_BUCKET_NAME
```

### Configure MWAA Variables

1. Access the MWAA environment console in AWS
2. Add the following Airflow variables:
   - `dbt_project_path`: s3://YOUR_BUCKET_NAME/dbt_project
   - `snowflake_account`: YOUR_SNOWFLAKE_ACCOUNT
   - `snowflake_user`: YOUR_SNOWFLAKE_USER
   - `snowflake_password`: YOUR_SNOWFLAKE_PASSWORD
   - `snowflake_role`: ACCOUNTADMIN (or appropriate role)
   - `snowflake_database`: DEMO_DB
   - `snowflake_warehouse`: COMPUTE_WH
   - `snowflake_schema`: PUBLIC

## Running the Pipeline

Once everything is set up, the Airflow DAG will run automatically based on the schedule (daily at 7 AM by default).

To trigger a manual run:
1. Access the MWAA Airflow UI
2. Navigate to the DAGs page
3. Find the `dbt_snowflake_models` DAG
4. Click the "Trigger DAG" button

## Monitoring

You can monitor DAG execution in the Airflow UI. Additionally, the DBT artifacts (logs, compiled SQL, documentation) are uploaded back to S3 after each run.

## Customization

- To modify the DBT models, update the SQL files in the `dbt_project/models` directory
- To change the schedule, edit the `schedule_interval` parameter in the Airflow DAG
- To add more Snowflake tables or views, create additional SQL files in the models directory

## Troubleshooting

- Check the Airflow logs in CloudWatch for any execution errors
- For DBT-specific issues, look at the logs in S3 after a run attempt
- Ensure your Snowflake credentials and permissions are correct

## Security Considerations

- Snowflake credentials are stored as Airflow variables. Consider using AWS Secrets Manager for production environments
- S3 bucket access is restricted to the MWAA environment
- All infrastructure is deployed with secure defaults