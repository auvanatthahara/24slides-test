-- fails (returns a row) unless there are exactly 6 months, Jan through Jun 2026
select count(*) as row_count
from {{ ref('mart_monthly_revenue') }}
having count(*) != 6
