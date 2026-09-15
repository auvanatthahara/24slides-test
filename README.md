# Task 1: StudioFlow — Data Engineer Work Sample

This assessment is for a **Data Engineer** working between
Software Engineers and Data Analysts.

## Timebox

Submit within **48-72 hours**. Expected active effort is **8–12 hours**. Document
unfinished work in `SUBMISSION.md`. A smaller, correct solution is stronger than
a broad unfinished platform.

PostgreSQL is mandatory. You own the repository structure, environment,
dependencies, setup, pipeline, and run commands. dbt, Airflow, Docker, Google
Sheets delivery, and CI/CD resemble our environment and add production-readiness
evidence when implemented correctly. Defensible alternatives are allowed.

Spark is optional and not expected for this data volume.

## Business case

StudioFlow's monthly operating report combines application revenue, Finance's
manual spreadsheet adjustments, and designer capacity. Today it is assembled by
hand and does not consistently reconcile.

Revenue sources can contain replays, corrections, invalid records, test
customers, unsupported values, and late deliveries. Every source record must
remain accountable even when it is excluded from a mart.

Designer capacity has three definitions:

- through 2022: team-owned capacity in points;
- from 2023: designer-owned capacity in points;
- a new 2026 definition: designer-owned output in slides.

Points and slides are not compatible measures and must not be summed together.

## Contract first

Read [DATA_CONTRACT.md](./DATA_CONTRACT.md) before implementation. It defines the
input, reproducibility, output, data-quality, and optional external-data interfaces
used for consistent evaluation. You may organize the implementation freely and
may add tables or columns, but the required interfaces must remain available.

No application scaffold, dependency file, database container, credentials file,
or framework configuration is supplied. Evaluation must work from a clean clone
without undocumented machine state.

## Required work

### 1. Revenue foundation

Build a layered PostgreSQL pipeline that:

- deterministically resolves duplicate deliveries and source corrections;
- normalizes statuses and transaction signs;
- converts supported currencies using the supplied monthly FX rates;
- combines accepted application and manual Finance events;
- exposes excluded or suspect records instead of silently dropping them;
- reconciles January through June 2026 against Finance control totals.

### 2. Reliability and data quality

Demonstrate:

- a stable business grain;
- idempotent reruns;
- closed, machine-readable reason codes;
- physical source-file and line-number lineage for malformed rows;
- useful error/warning severity;
- important uniqueness, not-null, relationship, accepted-value, and
  reconciliation tests;
- a second end-to-end run that does not change accepted business facts.

### 3. Evolving capacity logic

Create one unified consumer interface that preserves owner, unit, logic version,
and source lineage. A consumer must be able to aggregate compatible measurements
without writing year-specific logic. Explain how a fourth logic version would be
introduced.

### 4. Production engineering

Productionize as much as fits the timebox. Partial components must not break the
core solution.

- **dbt:** sources, layers, suitable materializations, contracts, and tests;
- **Airflow or equivalent:** logical intervals, retries/timeouts, a failing
  reconciliation/DQ gate, and safe rerun/backfill;
- **Docker:** lightweight, reproducible execution including PostgreSQL;
- **Google Sheets:** idempotent batched refresh; a credential-free dry-run export
  with metadata is sufficient evidence, while a real upload is optional;
- **CI/CD:** PostgreSQL integration, two pipeline runs, tests, and clear failure.

### 5. Optional external-data enrichment

Find one public dataset or API that adds defensible value to this operating
report. Examples include calendar, geographic, currency-reference, or
demographic-prediction data. Gender prediction is allowed, but it must be stored
as a probabilistic enrichment rather than a person's definitive identity.

This task is optional. If attempted, follow the external-data contract exactly.
Evaluation must run from the committed immutable snapshot and must not require a
live API, account, or credential. A real provider adapter may be included as
additional evidence.

We evaluate reproducibility, lineage, idempotency, failure handling, source
authority, privacy, licensing, and business justification—not whether an
arbitrary prediction about a person is “correct”.

### 6. Other optional evidence

- Spark used for a justified capability or concrete scale plan;
- data governance covering authority, ownership, classification, retention,
  SLAs, and contract changes;
- PostgreSQL roles/grants and least-privilege verification;
- a justified, tested PostgreSQL function with a stable interface;

## Recorded end-to-end demo

Submit one recorded demo, up to 10 minutes. You may show your face or not.
You need to speak in English with your voice, text to speech tools are prohibited.
The recording must show the end-to-end path you chose:

1. the supplied data and your pipeline/design entry point;
2. a completed pipeline execution or Airflow/dbt/Docker equivalent;
3. the reconciled revenue output and at least one visible data-quality finding;
4. evidence of a second run being safe; and
5. the capacity interface preserving logic version and unit.

The video is evidence of ownership and communication, not a test of editing,
presentation polish, or a particular tool. If recording is inaccessible, request
an equivalent live demonstration before the deadline.

## Submission

Copy `SUBMISSION_TEMPLATE.md` to `SUBMISSION.md`, then replace every bracketed
prompt with your answer. The template is a short form for the reviewer: explain
your approach, provide reproducible commands, show results and data-quality
findings, then list trade-offs or unfinished work.

Submit **one complete repository**, not the template as a separate file. Your
submission must contain your implementation, the provided `seeds/` data, and the
completed `SUBMISSION.md`. Organize all other files freely. There is no required
file name or runner: document the method you chose so a reviewer can reproduce
the core pipeline and run it a second time.

Share a private Git repository link and grant the interview team read access. If
that is not possible, submit a ZIP of the repository contents without `.git`.
Neither submission form may include credentials, `.env` files, private keys, or
undocumented dependencies on your machine or accounts.

Your `SUBMISSION.md` must state every command needed to reproduce the result and
how the reviewer can inspect the completed PostgreSQL relations. Include the
recorded demo as a private link or provide it with the submission. Do not require
the reviewer to use personal accounts, private credentials, or an undocumented
machine state.

