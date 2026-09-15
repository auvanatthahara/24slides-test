with winners as (
    select *
    from {{ ref('int_application_transactions_ranked') }}
    where rn = 1
),

flagged as (
    select
        w.transaction_id,
        w.customer_id,
        w.transaction_ts,
        w.transaction_type,
        w.status,
        w.amount,
        w.currency,
        w.ingested_at,
        w._source_file,
        w._source_line_number,
        c.customer_id is null as is_orphan_customer,
        coalesce(c.is_test_account, false) as is_test_account,
        w.status != 'succeeded' as is_failed_status,
        w.transaction_ts is null as is_invalid_timestamp,
        w.amount is null as is_invalid_amount,
        fx.usd_per_unit is null as is_unsupported_currency,
        w.transaction_ts is not null
            and (
                w.transaction_ts < '{{ var("reporting_window_start") }}'
                or w.transaction_ts >= '{{ var("reporting_window_end") }}'
            ) as is_outside_window,
        fx.usd_per_unit
    from winners w
    left join {{ ref('stg_customers') }} c on c.customer_id = w.customer_id
    left join {{ ref('stg_fx_rates') }} fx
        on fx.currency = w.currency
        and fx.month_start = date_trunc('month', w.transaction_ts)::date
)

select
    transaction_id,
    customer_id,
    transaction_ts,
    transaction_type,
    status,
    amount,
    currency,
    ingested_at,
    _source_file,
    _source_line_number,
    is_orphan_customer,
    is_test_account,
    is_failed_status,
    is_invalid_timestamp,
    is_invalid_amount,
    is_unsupported_currency,
    is_outside_window,
    not (
        is_orphan_customer or is_test_account or is_failed_status
        or is_invalid_timestamp or is_invalid_amount or is_unsupported_currency
        or is_outside_window
    ) as is_accepted,
    case
        when transaction_type in ('subscription_renewal', 'token_purchase') then amount
        when transaction_type in ('refund', 'chargeback') then -amount
        else null
    end * usd_per_unit as signed_amount_usd
from flagged
