-- Item-level purchase revenue should match session-level revenue within 0.5%.
-- A bigger gap would mean purchases are not joining back to products (e.g. missing item IDs).
-- First run: item $362,110 vs session $362,165 (0.02% apart).
with items as (
    select sum(item_revenue_usd) as revenue from {{ ref('fct_item_performance') }}
),
sessions as (
    select sum(revenue_usd) as revenue from {{ ref('fct_sessions') }}
)
select items.revenue as item_revenue, sessions.revenue as session_revenue
from items cross join sessions
where abs(items.revenue - sessions.revenue) > 0.005 * sessions.revenue
