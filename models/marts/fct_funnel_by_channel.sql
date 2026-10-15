-- Purchase funnel by channel and device: how many sessions reach each step, and where they drop.
with sessions as (

    select * from {{ ref('fct_sessions') }}

),

counts as (

    select
        channel_group,
        device_category,
        count(*)                            as sessions,
        countif(reached_view_item)          as view_item_sessions,
        countif(reached_add_to_cart)        as add_to_cart_sessions,
        countif(reached_begin_checkout)     as begin_checkout_sessions,
        countif(reached_add_payment_info)   as add_payment_info_sessions,
        countif(reached_purchase)           as purchase_sessions
    from sessions
    group by 1, 2

)

select
    *,
    round(safe_divide(view_item_sessions, sessions), 4)                   as view_item_rate,
    round(safe_divide(add_to_cart_sessions, view_item_sessions), 4)       as view_to_cart_rate,
    round(safe_divide(begin_checkout_sessions, add_to_cart_sessions), 4)  as cart_to_checkout_rate,
    round(safe_divide(purchase_sessions, begin_checkout_sessions), 4)     as checkout_to_purchase_rate,
    round(safe_divide(purchase_sessions, sessions), 4)                    as overall_conversion_rate
from counts
