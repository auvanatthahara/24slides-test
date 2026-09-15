with ranked as (
    select
        c.*,
        row_number() over (
            partition by record_id
            order by updated_at desc nulls last, _source_line_number desc
        ) as rn
    from {{ ref('stg_capacity_records') }} c
),

winners as (
    select * from ranked where rn = 1
)

select
    w.period_start,
    lv.owner_type,
    case
        when lv.owner_type = 'team' then w.team_id
        when lv.owner_type = 'designer' then w.designer_id
    end as owner_id,
    w.team_id,
    lv.metric_name,
    lv.metric_unit,
    case
        when lv.metric_unit = 'points' then w.capacity_points
        when lv.metric_unit = 'slides' then w.slides_completed
    end as metric_value,
    w.logic_version,
    w.record_id as source_record_id
from winners w
left join {{ ref('seed_capacity_logic_versions') }} lv on lv.logic_version = w.logic_version
