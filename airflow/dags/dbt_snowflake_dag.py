from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator as DummyOperator
from airflow.operators.python import BranchPythonOperator
from airflow.sensors.external_task import ExternalTaskSensor
from airflow.models import Variable

# Default arguments for the DAG
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
    'start_date': datetime(2023, 1, 1),
}

# Define the DAG
dag = DAG(
    'dbt_snowflake_models',
    default_args=default_args,
    description='Run DBT models on Snowflake',
    schedule_interval='0 7 * * *',  # 7 AM daily
    catchup=False,
    max_active_runs=1,
    tags=['dbt', 'snowflake'],
)

# S3 path where DBT project is stored
DBT_PROJECT_PATH = "{{ var.value.dbt_project_path }}"

# Environment variables for DBT
env_vars = {
    "SNOWFLAKE_ACCOUNT": "{{ var.value.snowflake_account }}",
    "SNOWFLAKE_USER": "{{ var.value.snowflake_user }}",
    "SNOWFLAKE_PASSWORD": "{{ var.value.snowflake_password }}",
    "SNOWFLAKE_ROLE": "{{ var.value.snowflake_role }}",
    "SNOWFLAKE_DATABASE": "{{ var.value.snowflake_database }}",
    "SNOWFLAKE_WAREHOUSE": "{{ var.value.snowflake_warehouse }}",
    "SNOWFLAKE_SCHEMA": "{{ var.value.snowflake_schema }}",
}

# Define tasks
start = DummyOperator(
    task_id='start',
    dag=dag,
)

# Task to fetch dbt project from S3
fetch_dbt_project = BashOperator(
    task_id='fetch_dbt_project',
    bash_command=f'aws s3 cp {DBT_PROJECT_PATH} /tmp/dbt_project --recursive',
    dag=dag,
)

# Task to install dbt dependencies
install_dbt_deps = BashOperator(
    task_id='install_dbt_deps',
    bash_command='cd /tmp/dbt_project && dbt deps',
    env=env_vars,
    dag=dag,
)

# Task to run dbt debug (to check connection)
dbt_debug = BashOperator(
    task_id='dbt_debug',
    bash_command='cd /tmp/dbt_project && dbt debug',
    env=env_vars,
    dag=dag,
)

# Task to run the first dbt model (customer_sample)
run_model_customer_sample = BashOperator(
    task_id='run_model_customer_sample',
    bash_command='cd /tmp/dbt_project && dbt run --select customer_sample',
    env=env_vars,
    dag=dag,
)

# Task to run the second dbt model (customer_single)
run_model_customer_single = BashOperator(
    task_id='run_model_customer_single',
    bash_command='cd /tmp/dbt_project && dbt run --select customer_single',
    env=env_vars,
    dag=dag,
)

# Task to generate documentation
generate_docs = BashOperator(
    task_id='generate_docs',
    bash_command='cd /tmp/dbt_project && dbt docs generate',
    env=env_vars,
    dag=dag,
)

# Task to upload artifacts back to S3
upload_artifacts = BashOperator(
    task_id='upload_artifacts',
    bash_command=f'cd /tmp/dbt_project && aws s3 cp target/ {DBT_PROJECT_PATH}/target/ --recursive',
    dag=dag,
)

end = DummyOperator(
    task_id='end',
    dag=dag,
)

# Define task dependencies
start >> fetch_dbt_project >> install_dbt_deps >> dbt_debug
dbt_debug >> run_model_customer_sample >> run_model_customer_single >> generate_docs
generate_docs >> upload_artifacts >> end