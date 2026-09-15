# Submission — [your name]

**Active time spent:** [for example: 9 hours]

**Recorded demo link or delivery method:** [private link, attachment name, or delivery method]

## 1. What I built

In 3–5 sentences, explain your approach and the main components you chose.

[Write here]

## 2. How to reproduce the core result

Start from a clean clone. Replace the examples below with the exact commands a
reviewer should run. You may use any appropriate approach, such as Airflow, dbt,
Docker Compose, Makefile, Python, or SQL.

**Prerequisites**

[For example: Docker Desktop, Python 3.12, or no prerequisites beyond PostgreSQL]

**Setup command(s)**

```bash
# Replace with your command(s)
```

**First end-to-end pipeline run**

```bash
# Replace with your command(s)
```

**Second end-to-end pipeline run**

```bash
# Replace with the same or another safe rerun command
```

**Tests and data-quality checks**

```bash
# Replace with your command(s)
```

**How to inspect the completed PostgreSQL output**

[State the connection method or command that gives the reviewer access to schema `analytics`. Do not include real credentials.]

## 3. Result summary

| Item | Result | Evidence/location |
|---|---|---|
| Monthly revenue reconciles with Finance | [Pass / variance explained] | [model, query, or report] |
| Required PostgreSQL relations are available | [Pass / partial] | [relation names] |
| Second run is safe | [Pass / partial] | [test, query, or log] |
| Capacity points and slides remain separate | [Pass / partial] | [model or query] |

## 4. Data-quality findings

List the records or categories you found and how your pipeline handled them.

| Source/category | Count | Severity | Handling | Where to verify |
|---|---:|---|---|---|
| [Example: malformed CSV row] | [count] | [error/warning] | [quarantined/excluded/etc.] | [relation, query, or log] |

## 5. Key modelling decisions

| Decision | Why | Trade-off or assumption |
|---|---|---|
| [Example: business-key deduplication] | [reason] | [assumption/trade-off] |

## 6. Components implemented

| Component | Status | How to verify |
|---|---|---|
| PostgreSQL pipeline | [Complete / Partial / Not attempted] | [location or command] |
| dbt | [Complete / Partial / Not attempted] | [location or command] |
| Airflow or alternative | [Complete / Partial / Not attempted] | [location or command] |
| Docker | [Complete / Partial / Not attempted] | [location or command] |
| Google Sheets/dry-run export | [Complete / Partial / Not attempted] | [location or command] |
| CI/CD | [Complete / Partial / Not attempted] | [location or command] |
| Spark | [Complete / Partial / Not attempted] | [location or command] |
| Data governance | [Complete / Partial / Not attempted] | [location or command] |
| Database security | [Complete / Partial / Not attempted] | [location or command] |
| PostgreSQL function | [Complete / Partial / Not attempted] | [location or command] |
| External-data enrichment | [Complete / Partial / Not attempted] | [location or command] |

## 7. Recorded end-to-end demo

Confirm that the recording shows: the pipeline entry point, completed execution,
reconciled revenue, one data-quality finding, safe second-run evidence, and the
capacity interface. You may show your face or not; this choice does not affect
scoring.

[Confirm or add any context]

## 8. Unfinished work and next steps

What did you deliberately not build, what remains incomplete, and what would you
do next in production?

[Write here]
