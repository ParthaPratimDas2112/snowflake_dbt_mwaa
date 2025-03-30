{{ config(
    materialized='table'
) }}

-- Model 1: Sample customer data
select * from SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER limit 10