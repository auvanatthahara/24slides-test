import os
from datetime import timedelta

import pendulum
import psycopg2
from airflow import DAG
from airflow.exceptions import AirflowException
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

PROJECT_DIR = "/opt/airflow/project"
RECONCILIATION_TOLERANCE_USD = 0.01

default_args = {
    "retries": 2,
    "retry_delay": timedelta(minutes=2),
    "execution_timeout": timedelta(minutes=10),
}


def check_reconciliation():
    conn = psycopg2.connect(
        host=os.environ.get("POSTGRES_HOST", "postgres"),
        port=os.environ.get("POSTGRES_PORT", "5432"),
        dbname=os.environ.get("POSTGRES_DB", "studioflow"),
        user=os.environ.get("POSTGRES_USER", "studioflow"),
        password=os.environ.get("POSTGRES_PASSWORD", "studioflow"),
    )
    cur = conn.cursor()
    cur.execute(
        "select month_start, variance_usd from analytics.mart_monthly_revenue "
        "where abs(variance_usd) > %s order by month_start",
        (RECONCILIATION_TOLERANCE_USD,),
    )
    bad_months = cur.fetchall()
    cur.close()
    conn.close()

    if bad_months:
        details = ", ".join(f"{month} (variance {variance})" for month, variance in bad_months)
        raise AirflowException(f"Monthly revenue reconciliation failed for: {details}")

    print(f"Reconciliation gate passed: all months within ${RECONCILIATION_TOLERANCE_USD} tolerance.")


with DAG(
    dag_id="studioflow_pipeline",
    description="StudioFlow revenue + capacity pipeline: load, build, test, reconcile.",
    default_args=default_args,
    schedule="@monthly",
    start_date=pendulum.datetime(2026, 1, 1, tz="UTC"),
    # end_date is inclusive of that logical date, so this is set one day
    # before July to get exactly 6 runs (Jan-Jun) instead of 7.
    end_date=pendulum.datetime(2026, 6, 30, tz="UTC"),
    catchup=True,
    max_active_runs=1,
    tags=["studioflow"],
) as dag:

    load_raw = BashOperator(
        task_id="load_raw",
        bash_command=f"cd {PROJECT_DIR} && python scripts/load_raw.py",
    )

    dbt_seed = BashOperator(
        task_id="dbt_seed",
        bash_command=f"cd {PROJECT_DIR}/dbt && dbt seed --profiles-dir .",
    )

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=f"cd {PROJECT_DIR}/dbt && dbt run --profiles-dir .",
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=f"cd {PROJECT_DIR}/dbt && dbt test --profiles-dir .",
    )

    reconciliation_gate = PythonOperator(
        task_id="reconciliation_gate",
        python_callable=check_reconciliation,
    )

    load_raw >> dbt_seed >> dbt_run >> dbt_test >> reconciliation_gate
