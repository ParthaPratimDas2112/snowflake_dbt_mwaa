{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}

{% macro log_run_start_event() %}
  {% if execute %}
    {{ log("Run started at " ~ modules.datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'), info=True) }}
  {% endif %}
{% endmacro %}