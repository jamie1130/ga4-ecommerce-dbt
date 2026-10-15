-- By definition every user is active in their own cohort week.
select *
from {{ ref('fct_user_retention_weekly') }}
where weeks_since_first = 0 and retention_rate != 1
