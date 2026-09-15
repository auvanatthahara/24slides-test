{{ config(materialized='ephemeral') }}

with keyed as (
    -- rows with no usable stable key are handled separately as missing_stable_key
    select *
    from {{ ref('stg_manual_adjustments') }}
    where source_row_id is not null
),

with_max as (
    select
        k.*,
        max(updated_at) over (partition by source_row_id) as max_updated_at
    from keyed k
),

signed as (
    select
        w.*,
        -- one string per row so tied top versions can be compared for equality in one shot
        concat_ws('|', w.adjustment_type, w.amount, w.currency, w.customer_id, w.occurred_at, w.approval_status) as version_signature
    from with_max w
)

select
    s.*,
    (s.updated_at = s.max_updated_at) as is_top_version,
    count(*) filter (where s.updated_at = s.max_updated_at) over (partition by s.source_row_id) as top_version_count,
    min(s.version_signature) filter (where s.updated_at = s.max_updated_at) over (partition by s.source_row_id) as top_min_signature,
    max(s.version_signature) filter (where s.updated_at = s.max_updated_at) over (partition by s.source_row_id) as top_max_signature,
    array_agg(s._source_line_number) filter (where s.updated_at = s.max_updated_at)
        over (
            partition by s.source_row_id
            order by s._source_line_number
            rows between unbounded preceding and unbounded following
        ) as top_version_line_numbers,
    row_number() over (partition by s.source_row_id order by s.updated_at desc, s._source_line_number desc) as rn
from signed s
