with winners as (
    -- rn=1, and not part of a genuinely conflicting (ambiguous) top-version tie
    select *
    from {{ ref('int_manual_adjustments_ranked') }}
    where rn = 1
        and not (top_version_count > 1 and top_min_signature != top_max_signature)
),

flagged as (
    select
        w.source_row_id,
        w.spreadsheet_row,
        w.occurred_at,
        w.customer_id,
        w.adjustment_type,
        w.amount,
        w.currency,
        w.reason,
        w.approval_status,
        w.updated_at,
        w._source_file,
        w._source_line_number,
        c.customer_id is null as is_orphan_customer,
        coalesce(c.is_test_account, false) as is_test_account,
        w.approval_status != 'approved' as is_unapproved,
        w.occurred_at is null as is_invalid_timestamp,
        w.amount is null as is_invalid_amount,
        fx.usd_per_unit is null as is_unsupported_currency,
        w.occurred_at is not null
            and (
                w.occurred_at < '{{ var("reporting_window_start") }}'
                or w.occurred_at >= '{{ var("reporting_window_end") }}'
            ) as is_outside_window,
        fx.usd_per_unit
    from winners w
    left join {{ ref('stg_customers') }} c on c.customer_id = w.customer_id
    left join {{ ref('stg_fx_rates') }} fx
        on fx.currency = w.currency
        and fx.month_start = date_trunc('month', w.occurred_at)::date
)

select
    source_row_id,
    spreadsheet_row,
    occurred_at,
    customer_id,
    adjustment_type,
    amount,
    currency,
    reason,
    approval_status,
    updated_at,
    _source_file,
    _source_line_number,
    is_orphan_customer,
    is_test_account,
    is_unapproved,
    is_invalid_timestamp,
    is_invalid_amount,
    is_unsupported_currency,
    is_outside_window,
    not (
        is_orphan_customer or is_test_account or is_unapproved
        or is_invalid_timestamp or is_invalid_amount or is_unsupported_currency
        or is_outside_window
    ) as is_accepted,
    case
        when adjustment_type = 'revenue_addition' then amount
        when adjustment_type = 'refund' then -amount
        else null
    end * usd_per_unit as signed_amount_usd
from flagged
