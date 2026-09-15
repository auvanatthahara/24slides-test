select
    period_start,
    owner_type,
    owner_id,
    team_id,
    metric_name,
    metric_unit,
    metric_value,
    logic_version,
    source_record_id
from {{ ref('int_capacity_records_resolved') }}
