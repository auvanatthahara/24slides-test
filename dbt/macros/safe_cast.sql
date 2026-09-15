{# postgres has no try_cast, so check the format with regex before casting #}

{% macro safe_to_date(column_name) -%}
    case when {{ column_name }} ~ '^\d{4}-\d{2}-\d{2}$'
        then ({{ column_name }})::date
        else null
    end
{%- endmacro %}

{% macro safe_to_timestamptz(column_name) -%}
    case when {{ column_name }} ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:?\d{2})?$'
        then ({{ column_name }})::timestamptz
        else null
    end
{%- endmacro %}

{% macro safe_to_numeric(column_name) -%}
    case when {{ column_name }} ~ '^[0-9]+(\.[0-9]+)?$'
        then ({{ column_name }})::numeric
        else null
    end
{%- endmacro %}
