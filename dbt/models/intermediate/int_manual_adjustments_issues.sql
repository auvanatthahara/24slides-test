with missing_key as (
    select
        _source_file as source_file,
        _source_line_number as source_line_number,
        'manual_adjustment' as source_system,
        _source_file || ':' || _source_line_number as source_record_id,
        'missing_stable_key' as reason_code,
        'error' as severity,
        now() as detected_at,
        jsonb_build_object('spreadsheet_row', spreadsheet_row) as context
    from {{ ref('stg_manual_adjustments') }}
    where source_row_id is null
),

duplicates as (
    -- any non-winner that isn't part of a genuine conflict: older versions,
    -- and the losing copy of a byte-identical tie at the top timestamp
    select
        _source_file as source_file,
        _source_line_number as source_line_number,
        'manual_adjustment' as source_system,
        source_row_id as source_record_id,
        'duplicate_delivery' as reason_code,
        'warning' as severity,
        now() as detected_at,
        jsonb_build_object('updated_at', updated_at, 'max_updated_at', max_updated_at) as context
    from {{ ref('int_manual_adjustments_ranked') }}
    where rn != 1
        and not (top_version_count > 1 and top_min_signature != top_max_signature)
),

ambiguous as (
    select
        _source_file as source_file,
        _source_line_number as source_line_number,
        'manual_adjustment' as source_system,
        source_row_id as source_record_id,
        'ambiguous_source_version' as reason_code,
        'error' as severity,
        now() as detected_at,
        jsonb_build_object(
            'updated_at', updated_at,
            'conflicting_line_numbers', top_version_line_numbers,
            'decision_needed', 'Finance must confirm the authoritative version for this key'
        ) as context
    from {{ ref('int_manual_adjustments_ranked') }}
    where is_top_version
        and top_version_count > 1
        and top_min_signature != top_max_signature
),

unapproved as (
    select _source_file as source_file, _source_line_number as source_line_number,
        'manual_adjustment' as source_system, source_row_id as source_record_id,
        'unapproved_adjustment' as reason_code, 'warning' as severity, now() as detected_at,
        jsonb_build_object('approval_status', approval_status) as context
    from {{ ref('int_manual_adjustments_resolved') }}
    where is_unapproved
),

orphan_customer as (
    select _source_file as source_file, _source_line_number as source_line_number,
        'manual_adjustment' as source_system, source_row_id as source_record_id,
        'orphan_customer' as reason_code, 'error' as severity, now() as detected_at,
        jsonb_build_object('customer_id', customer_id) as context
    from {{ ref('int_manual_adjustments_resolved') }}
    where is_orphan_customer
),

test_account as (
    select _source_file as source_file, _source_line_number as source_line_number,
        'manual_adjustment' as source_system, source_row_id as source_record_id,
        'test_account' as reason_code, 'warning' as severity, now() as detected_at,
        jsonb_build_object('customer_id', customer_id) as context
    from {{ ref('int_manual_adjustments_resolved') }}
    where is_test_account
),

unsupported_currency as (
    select _source_file as source_file, _source_line_number as source_line_number,
        'manual_adjustment' as source_system, source_row_id as source_record_id,
        'unsupported_currency' as reason_code, 'error' as severity, now() as detected_at,
        jsonb_build_object('currency', currency) as context
    from {{ ref('int_manual_adjustments_resolved') }}
    where is_unsupported_currency
),

invalid_timestamp as (
    select _source_file as source_file, _source_line_number as source_line_number,
        'manual_adjustment' as source_system, source_row_id as source_record_id,
        'invalid_timestamp' as reason_code, 'error' as severity, now() as detected_at,
        '{}'::jsonb as context
    from {{ ref('int_manual_adjustments_resolved') }}
    where is_invalid_timestamp
),

invalid_amount as (
    select _source_file as source_file, _source_line_number as source_line_number,
        'manual_adjustment' as source_system, source_row_id as source_record_id,
        'invalid_numeric_amount' as reason_code, 'error' as severity, now() as detected_at,
        '{}'::jsonb as context
    from {{ ref('int_manual_adjustments_resolved') }}
    where is_invalid_amount
),

outside_window as (
    select _source_file as source_file, _source_line_number as source_line_number,
        'manual_adjustment' as source_system, source_row_id as source_record_id,
        'outside_reporting_window' as reason_code, 'warning' as severity, now() as detected_at,
        jsonb_build_object('occurred_at', occurred_at) as context
    from {{ ref('int_manual_adjustments_resolved') }}
    where is_outside_window
)

select * from missing_key
union all select * from duplicates
union all select * from ambiguous
union all select * from unapproved
union all select * from orphan_customer
union all select * from test_account
union all select * from unsupported_currency
union all select * from invalid_timestamp
union all select * from invalid_amount
union all select * from outside_window
