select source_file, source_line_number, source_system, source_record_id, reason_code, severity, detected_at, context
from {{ ref('int_application_transactions_issues') }}

union all

select source_file, source_line_number, source_system, source_record_id, reason_code, severity, detected_at, context
from {{ ref('int_manual_adjustments_issues') }}

union all

select
    source_file,
    source_line_number,
    case
        when source_file = 'application_transactions.csv' then 'application'
        when source_file = 'manual_adjustments.csv' then 'manual_adjustment'
    end as source_system,
    source_file || ':' || source_line_number as source_record_id,
    'field_count_mismatch' as reason_code,
    'error' as severity,
    detected_at,
    jsonb_build_object(
        'expected_field_count', expected_field_count,
        'actual_field_count', actual_field_count,
        'raw_fields', raw_fields
    ) as context
from {{ source('raw', 'quarantined_records') }}
where source_file in ('application_transactions.csv', 'manual_adjustments.csv')
