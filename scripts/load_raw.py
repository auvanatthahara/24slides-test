import csv
import json
import os

import psycopg2

SEEDS_DIR = "seeds"
SCHEMA_FILE = "sql/raw_schema.sql"

# file name -> (raw table, columns in the same order as the CSV header)
FILES = {
    "customers.csv": (
        "raw.customers",
        ["customer_id", "customer_name", "country_code", "billing_currency",
         "signup_date", "is_test_account", "account_status"],
    ),
    "application_transactions.csv": (
        "raw.application_transactions",
        ["transaction_id", "customer_id", "transaction_ts", "transaction_type",
         "status", "amount", "currency", "provider_reference", "ingested_at"],
    ),
    "manual_adjustments.csv": (
        "raw.manual_adjustments",
        ["source_row_id", "spreadsheet_row", "occurred_at", "customer_id",
         "adjustment_type", "amount", "currency", "reason", "approval_status",
         "updated_at"],
    ),
    "fx_rates.csv": (
        "raw.fx_rates",
        ["month_start", "currency", "usd_per_unit"],
    ),
    "finance_control_totals.csv": (
        "raw.finance_control_totals",
        ["month_start", "application_net_revenue_usd", "manual_net_revenue_usd",
         "expected_net_revenue_usd", "expected_application_record_count",
         "expected_manual_record_count"],
    ),
    "capacity_records.csv": (
        "raw.capacity_records",
        ["record_id", "period_start", "team_id", "designer_id",
         "capacity_points", "slides_completed", "logic_version", "updated_at"],
    ),
}


def get_connection():
    return psycopg2.connect(
        host=os.environ.get("POSTGRES_HOST", "localhost"),
        port=os.environ.get("POSTGRES_PORT", "5432"),
        dbname=os.environ.get("POSTGRES_DB", "studioflow"),
        user=os.environ.get("POSTGRES_USER", "studioflow"),
        password=os.environ.get("POSTGRES_PASSWORD", "studioflow"),
    )


def create_tables(conn):
    with open(SCHEMA_FILE) as f:
        ddl = f.read()
    cur = conn.cursor()
    cur.execute(ddl)
    conn.commit()
    cur.close()


def load_csv(conn, filename, table, columns):
    path = os.path.join(SEEDS_DIR, filename)
    cur = conn.cursor()
    cur.execute(f"TRUNCATE TABLE {table}")

    column_names = ", ".join(columns + ["_source_file", "_source_line_number"])
    placeholders = ", ".join(["%s"] * (len(columns) + 2))
    insert_sql = f"INSERT INTO {table} ({column_names}) VALUES ({placeholders})"

    accepted = 0
    rejected = 0

    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        header = next(reader)

        for row in reader:
            line_number = reader.line_num

            if len(row) != len(header):
                cur.execute(
                    "INSERT INTO raw.quarantined_records "
                    "(source_file, source_line_number, expected_field_count, "
                    "actual_field_count, raw_fields) VALUES (%s, %s, %s, %s, %s)",
                    (filename, line_number, len(header), len(row), json.dumps(row)),
                )
                rejected += 1
                continue

            cur.execute(insert_sql, row + [filename, line_number])
            accepted += 1

    conn.commit()
    cur.close()
    return accepted, rejected


def main():
    conn = get_connection()
    create_tables(conn)

    cur = conn.cursor()
    cur.execute("TRUNCATE TABLE raw.quarantined_records")
    conn.commit()
    cur.close()

    print(f"{'file':<32}{'accepted':>10}{'rejected':>10}")
    total_accepted = 0
    total_rejected = 0
    for filename, (table, columns) in FILES.items():
        accepted, rejected = load_csv(conn, filename, table, columns)
        total_accepted += accepted
        total_rejected += rejected
        print(f"{filename:<32}{accepted:>10}{rejected:>10}")
    print(f"{'TOTAL':<32}{total_accepted:>10}{total_rejected:>10}")

    conn.close()


if __name__ == "__main__":
    main()
