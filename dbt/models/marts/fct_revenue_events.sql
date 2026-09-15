select
    md5('application:' || transaction_id) as revenue_event_key,
    'application' as source_system,
    transaction_id as source_record_id,
    customer_id,
    transaction_ts as occurred_at,
    transaction_type as event_type,
    signed_amount_usd,
    ingested_at as source_updated_at
from {{ ref('int_application_transactions_resolved') }}
where is_accepted

union all

select
    md5('manual_adjustment:' || source_row_id) as revenue_event_key,
    'manual_adjustment' as source_system,
    source_row_id as source_record_id,
    customer_id,
    occurred_at,
    adjustment_type as event_type,
    signed_amount_usd,
    updated_at as source_updated_at
from {{ ref('int_manual_adjustments_resolved') }}
where is_accepted
