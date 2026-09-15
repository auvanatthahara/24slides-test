select
    trim(record_id) as record_id,
    {{ safe_to_date('period_start') }} as period_start,
    trim(team_id) as team_id,
    nullif(trim(designer_id), '') as designer_id,
    {{ safe_to_numeric('capacity_points') }} as capacity_points,
    {{ safe_to_numeric('slides_completed') }} as slides_completed,
    lower(trim(logic_version)) as logic_version,
    {{ safe_to_timestamptz('updated_at') }} as updated_at,
    _source_file,
    _source_line_number
from {{ source('raw', 'capacity_records') }}
