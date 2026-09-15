select
    {{ safe_to_date('month_start') }} as month_start,
    upper(trim(currency)) as currency,
    {{ safe_to_numeric('usd_per_unit') }} as usd_per_unit,
    _source_file,
    _source_line_number
from {{ source('raw', 'fx_rates') }}
