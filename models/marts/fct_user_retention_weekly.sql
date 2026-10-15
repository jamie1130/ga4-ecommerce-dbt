-- Weekly retention by acquisition cohort: of users first seen in week W, how many come back in week W+n.
with sessions as (

    select user_pseudo_id, date_trunc(session_date, week(monday)) as activity_week
    from {{ ref('fct_sessions') }}

),

first_seen as (

    select user_pseudo_id, min(activity_week) as cohort_week
    from sessions
    group by 1

),

activity as (

    select distinct
        f.cohort_week,
        date_diff(s.activity_week, f.cohort_week, week) as weeks_since_first,
        s.user_pseudo_id
    from sessions s
    join first_seen f using (user_pseudo_id)

),

cohort_size as (

    select cohort_week, count(*) as cohort_users
    from first_seen
    group by 1

)

select
    a.cohort_week,
    a.weeks_since_first,
    c.cohort_users,
    count(distinct a.user_pseudo_id)                                       as active_users,
    round(safe_divide(count(distinct a.user_pseudo_id), c.cohort_users), 4) as retention_rate
from activity a
join cohort_size c using (cohort_week)
group by 1, 2, 3
