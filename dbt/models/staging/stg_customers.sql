select
    trim(customer_id) as customer_id,
    customer_name,
    upper(trim(country_code)) as country_code,
    upper(trim(billing_currency)) as billing_currency,
    {{ safe_to_date('signup_date') }} as signup_date,
    case
        when lower(trim(is_test_account)) in ('true', 't', '1', 'yes') then true
        when lower(trim(is_test_account)) in ('false', 'f', '0', 'no') then false
        else null
    end as is_test_account,
    lower(trim(account_status)) as account_status,
    _source_file,
    _source_line_number
from {{ source('raw', 'customers') }}
