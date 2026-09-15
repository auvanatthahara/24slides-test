-- fails (returns rows) if any month is outside the $0.01 reconciliation tolerance
select month_start, variance_usd
from {{ ref('mart_monthly_revenue') }}
where abs(variance_usd) > {{ var('reconciliation_tolerance_usd') }}
