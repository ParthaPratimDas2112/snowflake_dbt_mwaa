{{ config(
    materialized='table'
) }}

-- Model 2: Single customer record
select * from {{ ref('customer_sample') }} limit 1