select
    trim(transaction_id) as transaction_id,
    trim(customer_id) as customer_id,
    {{ safe_to_timestamptz('transaction_ts') }} as transaction_ts,
    lower(trim(transaction_type)) as transaction_type,
    lower(trim(status)) as status,
    {{ safe_to_numeric('amount') }} as amount,
    upper(trim(currency)) as currency,
    trim(provider_reference) as provider_reference,
    {{ safe_to_timestamptz('ingested_at') }} as ingested_at,
    _source_file,
    _source_line_number
from {{ source('raw', 'application_transactions') }}
