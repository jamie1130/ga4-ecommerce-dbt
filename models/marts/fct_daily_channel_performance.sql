-- Daily KPIs by channel and device: the table a marketing dashboard reads from.
with sessions as (

    select * from {{ ref('fct_sessions') }}

)

select
    session_date,
    channel_group,
    device_category,

    count(*)                                                    as sessions,
    count(distinct user_pseudo_id)                              as users,
    countif(is_new_user_session)                                as new_user_sessions,
    countif(is_engaged)                                         as engaged_sessions,
    countif(reached_purchase)                                   as converting_sessions,
    sum(transactions)                                           as transactions,
    round(sum(revenue_usd), 2)                                  as revenue_usd,

    -- rates (null-safe)
    round(safe_divide(countif(is_engaged), count(*)), 4)        as engagement_rate,
    round(safe_divide(countif(reached_purchase), count(*)), 4)  as session_conversion_rate,
    round(safe_divide(sum(revenue_usd), sum(transactions)), 2)  as average_order_value_usd,
    round(safe_divide(sum(revenue_usd), count(*)), 2)           as revenue_per_session_usd

from sessions
group by 1, 2, 3
