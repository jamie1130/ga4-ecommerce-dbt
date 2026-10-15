-- Total revenue in the sessions mart should match purchase revenue in the raw events
-- (within $1 for rounding). Any returned row means revenue was lost or double counted.
with mart as (
    select round(sum(revenue_usd), 2) as revenue from {{ ref('fct_sessions') }}
),
raw as (
    select round(sum(purchase_revenue_usd), 2) as revenue
    from {{ ref('stg_ga4__events') }}
    where event_name = 'purchase' and session_key is not null
)
select mart.revenue as mart_revenue, raw.revenue as raw_revenue
from mart cross join raw
where abs(coalesce(mart.revenue, 0) - coalesce(raw.revenue, 0)) > 1
