{{ config(materialized='ephemeral') }}

select
    t.*,
    row_number() over (
        partition by t.transaction_id
        order by t.ingested_at desc nulls last, t._source_line_number desc
    ) as rn
from {{ ref('stg_application_transactions') }} t
