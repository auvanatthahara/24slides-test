# Submission — Auvan Atthahara

**Active time spent:** 16 hours

**Recorded demo link or delivery method:** https://youtu.be/BjFLOvXo32k

## 1. What I built

I built a layered PostgreSQL pipeline (`raw` → `staging` → `intermediate` → `analytics`) orchestrated by dbt, fed by a Python extract step that preserves file/line lineage for every row — including malformed ones — instead of relying on `dbt seed`, which would choke on the one structurally malformed CSV row in this dataset. An Airflow DAG runs the pipeline with retries and an explicit reconciliation gate on a monthly schedule with backfill enabled, and Docker Compose runs the whole thing (Postgres + a dependency-free pipeline runner + Airflow) so the core result needs nothing but Docker on the host. The intermediate layer resolves duplicate/replayed application transactions and manual adjustments deterministically, quarantines the one genuinely ambiguous manual-adjustment conflict instead of guessing at it, and unifies three incompatible capacity "logic versions" into one queryable shape via a small seed table. All four required `analytics` relations reconcile against Finance's control totals to within $0.01 for every one of the six months, and idempotency is proven by wiping all Docker volumes, running the pipeline twice, and confirming the resulting tables are byte-for-byte identical (md5 checksums), not just row-count-equal.

## 2. How to reproduce the core result

**Prerequisites:** Docker Desktop only (with Compose v2). No local Python, dbt, or PostgreSQL install needed.

**Setup command(s)**

```bash
cp .env.example .env
docker compose build pipeline
docker compose up -d postgres
```

**First end-to-end pipeline run**

```bash
docker compose run --rm pipeline python scripts/load_raw.py
docker compose run --rm pipeline bash -c "cd dbt && dbt build --profiles-dir ."
```

**Second end-to-end pipeline run**

```bash
docker compose run --rm pipeline python scripts/load_raw.py
docker compose run --rm pipeline bash -c "cd dbt && dbt build --profiles-dir ."
```

Same commands — safe to rerun. The extract step truncates and reloads from the committed `seeds/` snapshot every time, and every dbt model is a full-refresh `view`/`table`, so a rerun recomputes the same result rather than appending to it. Verified directly: after a full `docker compose down -v` (all volumes wiped) and running the above twice in a row, an md5 checksum of the full contents of all 4 `analytics` tables was identical both times.

**Tests and data-quality checks**

`dbt build` above already runs both models and tests together. To run tests only:

```bash
docker compose run --rm pipeline bash -c "cd dbt && dbt test --profiles-dir ."
```

**Airflow alternative** (orchestrated run across the 6 reporting months, with retries/timeouts and a reconciliation gate — same underlying commands, run by Airflow instead of by hand)

```bash
docker compose up -d --build airflow
docker compose exec airflow airflow dags unpause studioflow_pipeline
# UI at http://localhost:8080 -- admin password:
docker compose exec airflow cat /opt/airflow/standalone_admin_password.txt
```

**How to inspect the completed PostgreSQL output**

```bash
docker compose exec postgres psql -U studioflow -d studioflow
# \dt analytics.*
```

Or point any PostgreSQL client (DBeaver, etc.) at `localhost:5434` (port and credentials come from `.env`/`.env.example` — local dev only, not a real secret), database `studioflow`, schema `analytics`.

## 3. Result summary

| Item | Result | Evidence/location |
|---|---|---|
| Monthly revenue reconciles with Finance | Pass — all 6 months within $0.01 | `analytics.mart_monthly_revenue`; `dbt/tests/assert_monthly_revenue_reconciles.sql` |
| Required PostgreSQL relations are available | Pass | `analytics.fct_revenue_events`, `analytics.mart_monthly_revenue`, `analytics.dq_revenue_issues`, `analytics.mart_capacity_unified` |
| Second run is safe | Pass — md5 checksums of all 4 analytics tables identical across two runs from a clean volume wipe | reproduction steps above |
| Capacity points and slides remain separate | Pass | `analytics.mart_capacity_unified.metric_unit` (`points`/`slides`), never summed together |

## 4. Data-quality findings

| Source/category | Count | Severity | Handling | Where to verify |
|---|---:|---|---|---|
| field_count_mismatch (malformed CSV row) | 1 | error | Quarantined at extract (`raw.quarantined_records`), surfaced in `dq_revenue_issues` | `dq_revenue_issues` where `reason_code='field_count_mismatch'` |
| duplicate_delivery (application_transactions) | 10 | warning | Superseded replay; newest `ingested_at` wins, older versions excluded but visible | `dq_revenue_issues` |
| duplicate_delivery (manual_adjustments) | 5 | warning | Superseded correction; newest `updated_at` wins | `dq_revenue_issues` |
| failed_transaction | 10 | warning | Non-`succeeded` status excluded from revenue | `dq_revenue_issues` |
| test_account | 12 (9+3) | warning | `is_test_account` customers excluded | `dq_revenue_issues` |
| unsupported_currency | 5 (4+1) | error | No FX rate for that month/currency (e.g. `IDR`, absent from `fx_rates.csv`), excluded | `dq_revenue_issues` |
| orphan_customer | 4 (3+1) | error | `customer_id` not present in `customers.csv` (e.g. `UNKNOWN99`), excluded | `dq_revenue_issues` |
| invalid_timestamp | 2 | error | Business timestamp failed to cast, excluded | `dq_revenue_issues` |
| outside_reporting_window | 2 | warning | Occurred outside `[2026-01-01, 2026-07-01)` | `dq_revenue_issues` |
| missing_stable_key | 2 | error | Blank/whitespace-only `source_row_id`, can't dedupe idempotently, excluded | `dq_revenue_issues` |
| unapproved_adjustment | 3 | warning | `approval_status` not `approved` (`pending`/`rejected`), excluded | `dq_revenue_issues` |
| ambiguous_source_version | 2 | error | The genuine `MANA0025` conflict — two versions tie on the greatest `updated_at` with different content. Both quarantined, neither guessed at; `context` records the conflict for Finance to resolve | `dq_revenue_issues` where `source_record_id='MANA0025'` |

**Total: 58 issue rows across 11 distinct reason codes** (the closed set also includes `invalid_numeric_amount`, implemented but with 0 occurrences in this dataset variant). Nothing silently disappears — every excluded or flagged record remains visible. Accepted: 221 of 257 loaded application transactions, 14 of 22 deduplicated manual adjustments — 235 total accepted revenue events.

## 5. Key modelling decisions

| Decision | Why | Trade-off or assumption |
|---|---|---|
| Text-only `raw` schema, typing deferred to dbt staging | Keeps extract dumb and safe — a bad cast can never silently drop a row before dbt sees it | Slightly more verbose staging models (explicit regex-guarded casts) |
| Custom Python loader instead of `dbt seed` for source CSVs | `dbt seed` expects every row to match the header's field count; the one malformed row would abort or misalign the whole load | An extra moving part outside dbt, documented and tested independently |
| Ephemeral "ranked" dbt models shared by each `_resolved`/`_issues` pair | Lets a superseded version get a `duplicate_delivery` issue without recomputing the dedup window function twice | Slightly less obvious than one big model; the pattern needs explaining |
| Full truncate-and-reload extract + `table` materialization throughout | `seeds/` is a static snapshot, not a stream — this is the simplest thing that makes reruns trivially idempotent | Wouldn't scale as-is to genuinely incremental/streaming ingestion (noted below) |
| Quarantine (not guess) the `MANA0025` conflict | The contract is explicit: don't fabricate a tiebreaker for a genuine business conflict — only Finance can decide | Reduces accepted manual-adjustment revenue by that record's value until resolved |
| Seed-driven capacity logic-version mapping (`seed_capacity_logic_versions.csv`) | A 4th logic version becomes a one-row seed addition, not a code change, as long as it reuses the existing `points`/`slides` measure columns | A genuinely new measure type would still need one new `CASE WHEN` branch in `int_capacity_records_resolved` — documented, not hidden |
| Custom `generate_schema_name` macro | Required to land marts in schema `analytics` exactly (not a dbt-prefixed variant) from one `dbt build` covering all layers | Standard, well-known dbt override pattern |

## 6. Components implemented

| Component | Status | How to verify |
|---|---|---|
| PostgreSQL pipeline | Complete | `sql/raw_schema.sql`, `scripts/load_raw.py`, `dbt/` |
| dbt | Complete — sources, staging/intermediate/marts layers, 1 seed, 45 schema tests + 2 singular reconciliation tests. dbt-native `contract: enforced` config not added: explicitly optional per the brief, and the underlying semantic types are already correct and verified (`\d` on every mart) | `docker compose run --rm pipeline bash -c "cd dbt && dbt build --profiles-dir ."` |
| Airflow or alternative | Complete — 1 DAG, 5 tasks (load, seed, run, test, reconciliation gate), retries/timeouts, `@monthly` schedule with `catchup=True`, verified across a clean backfill of all 6 reporting months | `airflow/dags/studioflow_pipeline_dag.py`; `docker compose up -d --build airflow` |
| Docker | Complete — `postgres`, `pipeline`, `airflow` services; core result needs nothing but Docker on the host | `docker-compose.yml` |
| Google Sheets/dry-run export | Not attempted | — |
| CI/CD | Not attempted | — |
| Spark | Not attempted (not needed for this data volume, per the brief) | — |
| Data governance | Not attempted | — |
| Database security | Not attempted | — |
| PostgreSQL function | Not attempted | — |
| External-data enrichment | Not attempted | — |

## 7. Recorded end-to-end demo

The recording shows: the pipeline entry point, a completed run, `analytics.mart_monthly_revenue` reconciled, at least one `dq_revenue_issues` finding (e.g. the `MANA0025` conflict or the malformed CSV row), the second-run/idempotency evidence, and `analytics.mart_capacity_unified` showing `metric_unit`.

## 8. Unfinished work and next steps

Deliberately not build: Google Sheets export, CI/CD, external-data enrichment, Spark, a data governance write-up, PostgreSQL roles/grants, and a PostgreSQL function. 

One planned verification is not completed: deliberately breaking a value to prove `reconciliation_gate` fails loudly, not just that it passes when things are already correct. Its happy-path behavior is verified across 6 real backfill runs; a forced-failure run wasn't performed due to time.

Next in production: (1) CI running this same `docker compose` flow on every PR; (2) PostgreSQL roles/grants for least-privilege access to `analytics`; (3) revisiting the extract/load strategy if this ever became genuinely incremental/streaming data rather than a static snapshot; (4) the Google Sheets dry-run export.