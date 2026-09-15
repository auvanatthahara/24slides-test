with duplicates as (
    select
        _source_file as source_file,
        _source_line_number as source_line_number,
        'application' as source_system,
        transaction_id as source_record_id,
        'duplicate_delivery' as reason_code,
        'warning' as severity,
        now() as detected_at,
        jsonb_build_object('ingested_at', ingested_at, 'rank', rn) as context
    from {{ ref('int_application_transactions_ranked') }}
    where rn > 1
),

failed_status as (
    select _source_file as source_file, _source_line_number as source_line_number,
        'application' as source_system, transaction_id as source_record_id,
        'failed_transaction' as reason_code, 'warning' as severity, now() as detected_at,
        jsonb_build_object('status', status) as context
    from {{ ref('int_application_transactions_resolved') }}
    where is_failed_status
),

orphan_customer as (
    select _source_file as source_file, _source_line_number as source_line_number,
        'application' as source_system, transaction_id as source_record_id,
        'orphan_customer' as reason_code, 'error' as severity, now() as detected_at,
        jsonb_build_object('customer_id', customer_id) as context
    from {{ ref('int_application_transactions_resolved') }}
    where is_orphan_customer
),

test_account as (
    select _source_file as source_file, _source_line_number as source_line_number,
        'application' as source_system, transaction_id as source_record_id,
        'test_account' as reason_code, 'warning' as severity, now() as detected_at,
        jsonb_build_object('customer_id', customer_id) as context
    from {{ ref('int_application_transactions_resolved') }}
    where is_test_account
),

unsupported_currency as (
    select _source_file as source_file, _source_line_number as source_line_number,
        'application' as source_system, transaction_id as source_record_id,
        'unsupported_currency' as reason_code, 'error' as severity, now() as detected_at,
        jsonb_build_object('currency', currency) as context
    from {{ ref('int_application_transactions_resolved') }}
    where is_unsupported_currency
),

invalid_timestamp as (
    select _source_file as source_file, _source_line_number as source_line_number,
        'application' as source_system, transaction_id as source_record_id,
        'invalid_timestamp' as reason_code, 'error' as severity, now() as detected_at,
        '{}'::jsonb as context
    from {{ ref('int_application_transactions_resolved') }}
    where is_invalid_timestamp
),

invalid_amount as (
    select _source_file as source_file, _source_line_number as source_line_number,
        'application' as source_system, transaction_id as source_record_id,
        'invalid_numeric_amount' as reason_code, 'error' as severity, now() as detected_at,
        '{}'::jsonb as context
    from {{ ref('int_application_transactions_resolved') }}
    where is_invalid_amount
),

outside_window as (
    select _source_file as source_file, _source_line_number as source_line_number,
        'application' as source_system, transaction_id as source_record_id,
        'outside_reporting_window' as reason_code, 'warning' as severity, now() as detected_at,
        jsonb_build_object('transaction_ts', transaction_ts) as context
    from {{ ref('int_application_transactions_resolved') }}
    where is_outside_window
)

select * from duplicates
union all select * from failed_status
union all select * from orphan_customer
union all select * from test_account
union all select * from unsupported_currency
union all select * from invalid_timestamp
union all select * from invalid_amount
union all select * from outside_window
