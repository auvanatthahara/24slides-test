with months as (
    select generate_series(
        '{{ var("reporting_window_start") }}'::date,
        ('{{ var("reporting_window_end") }}'::date - interval '1 month')::date,
        interval '1 month'
    )::date as month_start
),

app_agg as (
    select
        date_trunc('month', occurred_at)::date as month_start,
        sum(signed_amount_usd) as application_net_revenue_usd,
        count(*) as application_record_count
    from {{ ref('fct_revenue_events') }}
    where source_system = 'application'
    group by 1
),

manual_agg as (
    select
        date_trunc('month', occurred_at)::date as month_start,
        sum(signed_amount_usd) as manual_net_revenue_usd,
        count(*) as manual_record_count
    from {{ ref('fct_revenue_events') }}
    where source_system = 'manual_adjustment'
    group by 1
),

finance as (
    select month_start, expected_net_revenue_usd as finance_control_total_usd
    from {{ ref('stg_finance_control_totals') }}
)

select
    m.month_start,
    coalesce(a.application_net_revenue_usd, 0) as application_net_revenue_usd,
    coalesce(mn.manual_net_revenue_usd, 0) as manual_net_revenue_usd,
    coalesce(a.application_net_revenue_usd, 0) + coalesce(mn.manual_net_revenue_usd, 0) as net_revenue_usd,
    f.finance_control_total_usd,
    (coalesce(a.application_net_revenue_usd, 0) + coalesce(mn.manual_net_revenue_usd, 0)) - f.finance_control_total_usd as variance_usd,
    coalesce(a.application_record_count, 0) as application_record_count,
    coalesce(mn.manual_record_count, 0) as manual_record_count
from months m
left join app_agg a on a.month_start = m.month_start
left join manual_agg mn on mn.month_start = m.month_start
left join finance f on f.month_start = m.month_start
order by m.month_start
