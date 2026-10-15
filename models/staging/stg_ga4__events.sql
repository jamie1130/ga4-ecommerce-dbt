-- One row per GA4 event, with the parameters we use pulled out of the nested event_params array.
with source as (

    select *
    from {{ source('ga4', 'events') }}
    where _table_suffix between '{{ var("start_date") }}' and '{{ var("end_date") }}'

),

renamed as (

    select
        -- keys
        to_hex(md5(concat(
            user_pseudo_id, '|', cast(event_timestamp as string), '|', event_name, '|',
            coalesce({{ get_event_param('page_location') }}, ''), '|',
            cast(coalesce(event_bundle_sequence_id, 0) as string)
        )))                                                         as event_key,
        user_pseudo_id,
        {{ get_event_param('ga_session_id', 'int') }}               as ga_session_id,
        concat(user_pseudo_id, '-',
               cast({{ get_event_param('ga_session_id', 'int') }} as string)) as session_key,

        -- time
        parse_date('%Y%m%d', event_date)                            as event_date,
        timestamp_micros(event_timestamp)                           as event_ts,

        -- event
        event_name,
        {{ get_event_param('ga_session_number', 'int') }}           as session_number,
        {{ get_event_param('page_location') }}                      as page_location,
        {{ get_event_param('page_title') }}                         as page_title,
        {{ get_event_param('engagement_time_msec', 'int') }}        as engagement_time_msec,
        {{ get_event_param('session_engaged', 'int') }}             as session_engaged_flag,

        -- traffic: event-scoped source/medium first, user first-touch as fallback
        {{ get_event_param('source') }}                             as event_source,
        {{ get_event_param('medium') }}                             as event_medium,
        {{ get_event_param('campaign') }}                           as event_campaign,
        traffic_source.source                                       as first_touch_source,
        traffic_source.medium                                       as first_touch_medium,

        -- context
        device.category                                             as device_category,
        geo.country                                                 as country,

        -- ecommerce
        ecommerce.transaction_id                                    as transaction_id,
        ecommerce.purchase_revenue_in_usd                           as purchase_revenue_usd,
        ecommerce.total_item_quantity                               as total_item_quantity

    from source

)

select * from renamed
