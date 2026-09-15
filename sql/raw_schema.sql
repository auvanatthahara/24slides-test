-- Raw landing tables. Everything is text here, typing happens later in dbt.
-- _source_file / _source_line_number track where each row came from.

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS analytics;

CREATE TABLE IF NOT EXISTS raw.customers (
    _raw_id              bigserial PRIMARY KEY,
    customer_id          text,
    customer_name        text,
    country_code         text,
    billing_currency     text,
    signup_date          text,
    is_test_account      text,
    account_status       text,
    _source_file         text NOT NULL,
    _source_line_number  integer NOT NULL,
    _loaded_at           timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS raw.application_transactions (
    _raw_id              bigserial PRIMARY KEY,
    transaction_id       text,
    customer_id          text,
    transaction_ts       text,
    transaction_type     text,
    status               text,
    amount               text,
    currency             text,
    provider_reference   text,
    ingested_at          text,
    _source_file         text NOT NULL,
    _source_line_number  integer NOT NULL,
    _loaded_at           timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS raw.manual_adjustments (
    _raw_id              bigserial PRIMARY KEY,
    source_row_id        text,
    spreadsheet_row      text,
    occurred_at          text,
    customer_id          text,
    adjustment_type      text,
    amount               text,
    currency             text,
    reason               text,
    approval_status      text,
    updated_at           text,
    _source_file         text NOT NULL,
    _source_line_number  integer NOT NULL,
    _loaded_at           timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS raw.fx_rates (
    _raw_id              bigserial PRIMARY KEY,
    month_start          text,
    currency             text,
    usd_per_unit         text,
    _source_file         text NOT NULL,
    _source_line_number  integer NOT NULL,
    _loaded_at           timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS raw.finance_control_totals (
    _raw_id                            bigserial PRIMARY KEY,
    month_start                        text,
    application_net_revenue_usd        text,
    manual_net_revenue_usd             text,
    expected_net_revenue_usd           text,
    expected_application_record_count  text,
    expected_manual_record_count       text,
    _source_file                       text NOT NULL,
    _source_line_number                integer NOT NULL,
    _loaded_at                         timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS raw.capacity_records (
    _raw_id              bigserial PRIMARY KEY,
    record_id            text,
    period_start         text,
    team_id              text,
    designer_id          text,
    capacity_points      text,
    slides_completed     text,
    logic_version        text,
    updated_at           text,
    _source_file         text NOT NULL,
    _source_line_number  integer NOT NULL,
    _loaded_at           timestamptz NOT NULL DEFAULT now()
);

-- Rows that didn't have the right number of columns. Shared across all files.
CREATE TABLE IF NOT EXISTS raw.quarantined_records (
    _raw_id               bigserial PRIMARY KEY,
    source_file           text NOT NULL,
    source_line_number    integer NOT NULL,
    expected_field_count  integer NOT NULL,
    actual_field_count    integer NOT NULL,
    raw_fields            jsonb NOT NULL,
    detected_at           timestamptz NOT NULL DEFAULT now()
);
