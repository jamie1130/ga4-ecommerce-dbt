-- Product-level performance: which items get viewed, carted and bought.
with items as (

    select * from {{ ref('stg_ga4__items') }}

),

agg as (

    select
        item_id,
        any_value(item_name)                                                as item_name,
        any_value(item_category)                                            as item_category,
        countif(event_name = 'view_item')                                   as item_views,
        countif(event_name = 'add_to_cart')                                 as add_to_carts,
        sum(if(event_name = 'purchase', coalesce(quantity, 0), 0))          as units_sold,
        count(distinct if(event_name = 'purchase', transaction_id, null))   as orders,
        round(sum(if(event_name = 'purchase', coalesce(item_revenue_usd, 0), 0)), 2) as item_revenue_usd
    from items
    group by item_id

)

select
    *,
    round(safe_divide(add_to_carts, item_views), 4)  as view_to_cart_rate,
    round(safe_divide(orders, add_to_carts), 4)      as cart_to_order_rate,
    round(safe_divide(item_revenue_usd, units_sold), 2) as avg_selling_price_usd
from agg
