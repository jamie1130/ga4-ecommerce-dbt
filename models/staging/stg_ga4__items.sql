-- One row per item per ecommerce event (view_item, add_to_cart, begin_checkout, purchase, ...).
with source as (

    select
        user_pseudo_id,
        event_timestamp,
        event_name,
        event_date,
        event_params,
        ecommerce,
        items
    from {{ source('ga4', 'events') }}
    where _table_suffix between '{{ var("start_date") }}' and '{{ var("end_date") }}'
      and array_length(items) > 0

)

select
    concat(user_pseudo_id, '-',
           cast({{ get_event_param('ga_session_id', 'int') }} as string)) as session_key,
    user_pseudo_id,
    parse_date('%Y%m%d', event_date)        as event_date,
    timestamp_micros(event_timestamp)       as event_ts,
    event_name,
    ecommerce.transaction_id                as transaction_id,
    item.item_id,
    item.item_name,
    item.item_category,
    item.price_in_usd,
    item.quantity,
    item.item_revenue_in_usd as item_revenue_usd
from source,
    unnest(items) as item
