{#
  Simplified version of GA4's default channel grouping, based on source / medium.
  The public sample is obfuscated: many values appear as '<Other>' or '(data deleted)',
  which land in their own bucket instead of being forced into a channel.
#}
{% macro channel_group(source, medium) -%}
  case
    when {{ source }} is null and {{ medium }} is null then 'Unassigned'
    when {{ source }} in ('<Other>', '(data deleted)') or {{ medium }} in ('<Other>', '(data deleted)') then 'Obfuscated'
    when {{ source }} = '(direct)' and {{ medium }} in ('(none)', '(not set)') then 'Direct'
    when {{ medium }} = 'organic' then 'Organic Search'
    when regexp_contains({{ medium }}, r'^(cpc|ppc|paidsearch)$') then 'Paid Search'
    when regexp_contains({{ medium }}, r'^(display|cpm|banner)$') then 'Display'
    when regexp_contains({{ medium }}, r'(social|social-network|sm)') then 'Social'
    when {{ medium }} = 'email' then 'Email'
    when {{ medium }} = 'affiliate' then 'Affiliates'
    when {{ medium }} = 'referral' then 'Referral'
    else 'Other'
  end
{%- endmacro %}
