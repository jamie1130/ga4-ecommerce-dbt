{#
  Pull one value out of the GA4 event_params array.
  value_type: 'string' | 'int' | 'double' | 'any'
  'any' returns a STRING built from whichever typed field is populated,
  because GA4 stores the same key as string in some events and int in others.
#}
{% macro get_event_param(key, value_type='string') -%}
  {%- if value_type == 'string' -%}
    (select ep.value.string_value from unnest(event_params) as ep where ep.key = '{{ key }}')
  {%- elif value_type == 'int' -%}
    (select coalesce(ep.value.int_value, safe_cast(ep.value.string_value as int64))
       from unnest(event_params) as ep where ep.key = '{{ key }}')
  {%- elif value_type == 'double' -%}
    (select coalesce(ep.value.double_value, ep.value.float_value, cast(ep.value.int_value as float64))
       from unnest(event_params) as ep where ep.key = '{{ key }}')
  {%- else -%}
    (select coalesce(ep.value.string_value, cast(ep.value.int_value as string),
                     cast(ep.value.double_value as string), cast(ep.value.float_value as string))
       from unnest(event_params) as ep where ep.key = '{{ key }}')
  {%- endif -%}
{%- endmacro %}
