select
    -- blank/whitespace-only keys collapse to null here, so "missing key" is one clean check downstream
    nullif(trim(source_row_id), '') as source_row_id,
    trim(spreadsheet_row) as spreadsheet_row,
    {{ safe_to_timestamptz('occurred_at') }} as occurred_at,
    trim(customer_id) as customer_id,
    lower(trim(adjustment_type)) as adjustment_type,
    {{ safe_to_numeric('amount') }} as amount,
    upper(trim(currency)) as currency,
    reason,
    lower(trim(approval_status)) as approval_status,
    {{ safe_to_timestamptz('updated_at') }} as updated_at,
    _source_file,
    _source_line_number
from {{ source('raw', 'manual_adjustments') }}
