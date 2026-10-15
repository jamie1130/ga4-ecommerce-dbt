-- One row per session: traffic source, engagement, and how far the session got in the purchase funnel.
with events as (

    select * from {{ ref('stg_ga4__events') }}
    where session_key is not null

),

sessions as (

    select
        session_key,
        any_value(user_pseudo_id)                                           as user_pseudo_id,
        min(event_ts)                                                       as session_start_ts,
        min(event_date)                                                     as session_date,  -- property-timezone date, matches GA4 UI
        min(session_number)                                                 as session_number,

        -- first source/medium seen in the session; fall back to the user's first-touch source
        coalesce(
            array_agg(event_source ignore nulls order by event_ts limit 1)[safe_offset(0)],
            any_value(first_touch_source))                                  as source,
        coalesce(
            array_agg(event_medium ignore nulls order by event_ts limit 1)[safe_offset(0)],
            any_value(first_touch_medium))                                  as medium,
        array_agg(event_campaign ignore nulls order by event_ts limit 1)[safe_offset(0)] as campaign,

        array_agg(device_category ignore nulls order by event_ts limit 1)[safe_offset(0)] as device_category,
        array_agg(country ignore nulls order by event_ts limit 1)[safe_offset(0)]         as country,

        -- engagement
        coalesce(max(session_engaged_flag), 0) = 1                          as is_engaged,
        countif(event_name = 'page_view')                                   as pageviews,
        round(coalesce(sum(engagement_time_msec), 0) / 1000, 1)             as engagement_time_sec,

        -- funnel steps reached
        logical_or(event_name = 'view_item')                                as reached_view_item,
        logical_or(event_name = 'add_to_cart')                              as reached_add_to_cart,
        logical_or(event_name = 'begin_checkout')                           as reached_begin_checkout,
        logical_or(event_name = 'add_payment_info')                         as reached_add_payment_info,
        logical_or(event_name = 'purchase')                                 as reached_purchase,

        -- outcomes
        count(distinct if(event_name = 'purchase', transaction_id, null))   as transactions,
        coalesce(sum(if(event_name = 'purchase', purchase_revenue_usd, 0)), 0) as revenue_usd

    from events
    group by session_key

)

select * from sessions
