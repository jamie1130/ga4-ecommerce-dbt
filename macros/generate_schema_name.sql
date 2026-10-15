{# Use clean schema names (ga4_dbt_staging, ga4_dbt_marts) instead of dbt's default concatenation quirks. #}
{% macro generate_schema_name(custom_schema_name, node) -%}
  {%- if custom_schema_name is none -%}{{ target.schema }}{%- else -%}{{ target.schema }}_{{ custom_schema_name | trim }}{%- endif -%}
{%- endmacro %}
