select
    {{ safe_to_date('month_start') }} as month_start,
    {{ safe_to_numeric('application_net_revenue_usd') }} as application_net_revenue_usd,
    {{ safe_to_numeric('manual_net_revenue_usd') }} as manual_net_revenue_usd,
    {{ safe_to_numeric('expected_net_revenue_usd') }} as expected_net_revenue_usd,
    {{ safe_to_numeric('expected_application_record_count') }}::int as expected_application_record_count,
    {{ safe_to_numeric('expected_manual_record_count') }}::int as expected_manual_record_count,
    _source_file,
    _source_line_number
from {{ source('raw', 'finance_control_totals') }}
