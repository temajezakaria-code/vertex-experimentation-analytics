# Vertex Commerce — A/B Testing & Experimentation Analytics

![SQL](https://img.shields.io/badge/SQL-4479A1?style=for-the-badge&logo=postgresql&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Excel](https://img.shields.io/badge/Microsoft_Excel-217346?style=for-the-badge&logo=microsoft-excel&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![Jupyter](https://img.shields.io/badge/Jupyter-F37626?style=for-the-badge&logo=jupyter&logoColor=white)

## Business Problem

Vertex Commerce runs dozens of A/B tests per quarter across checkout,
pricing, onboarding, search, email, and recommendations, but leadership has
no consolidated view of whether the testing program itself is statistically
sound — are tests properly powered? Are guardrail metrics being checked?
Are "wins" real, or noise?

## Dataset

**This dataset is entirely synthetic, with every experiment's true effect
programmed in advance.** Real companies never publish raw, multi-test,
user-level experiment data — this is the only way to build a portfolio
project where statistical findings can be verified against known ground
truth rather than just narrated. 30 experiments, 433,900 user assignments
(2024-2025), with deliberately embedded pitfalls: underpowered tests, true
nulls, novelty-effect decay, segment heterogeneity, and guardrail-metric
regressions.

## Executive Experimentation Summary

![Executive Summary](images/dashboard1_executive_summary.png)

## Test Results Detail

![Test Results Detail](images/dashboard2_test_results.png)

## Power & Sample Size Planning

![Power Planning](images/dashboard3_power_planning.png)

## Guardrail Monitoring

![Guardrail Monitoring](images/dashboard4_guardrail_monitoring.png)

## Key Findings

1. **Every single test in the portfolio — 30 of 30 — was statistically
   underpowered** to detect a 5% relative lift, even tests with 7,000-9,500
   users per arm. This is the headline finding of the whole analysis.
2. **Only 3 of 30 tests (10%) reached statistical significance** — largely
   explained by the underpowering above, not by the ideas being bad.
3. **Zero sample ratio mismatch (SRM) issues found** across all 30 tests —
   the randomization infrastructure itself is clean.
4. **2 of 30 tests showed a primary-metric win paired with a guardrail
   regression** — both roughly doubled the refund/complaint rate.
5. **The single largest revenue-lift result in the portfolio ($2.27/user)
   came from a test that was NOT statistically significant** (n=600 per
   arm) — a promising result a primary-metric-only review would wrongly
   discard.

*(Full list: 15 insights, 10 risks, 15 recommendations, 10 quick wins, 10
long-term opportunities in [`docs/business_insights.md`](docs/business_insights.md).)*

## Top 3 Recommendations

1. Establish a mandatory minimum sample size based on formal power
   calculations — not intuition.
2. Add a mandatory guardrail-metric check to the standard test evaluation
   template before any test can ship.
3. Re-test the "Micro-Copy Tweaks on CTA" result specifically — the
   highest-potential, most under-examined finding in the portfolio.

## Excel Dashboard

![Excel Dashboard](images/excel1_dashboard.png)

Pivot-style summaries, conditional formatting, VLOOKUP/INDEX-MATCH — see
[`Excel/vertex_experiments_dashboard.xlsx`](Excel/vertex_experiments_dashboard.xlsx).

## Critical Assessment & Next Steps

Full limitations documented in
[`docs/business_insights.md`](docs/business_insights.md), headline items:

- This dataset is synthetic with programmed ground truth — built this way
  specifically so findings could be verified, not just claimed.
- No multiple-comparisons correction was applied across the 30-test
  portfolio — with 30 simultaneous tests, 1-2 significant results could
  occur by chance alone, a nuance stated explicitly rather than treating
  "3 wins" as unambiguously meaningful.
- The classic "peeking problem" (early stopping inflating false positives)
  is discussed conceptually but not directly simulated or corrected for in
  this version.

## Project Contents

| Folder | Contents |
|---|---|
| [`SQL/`](SQL) | Schema + 10 queries, including a two-proportion z-test and sample ratio mismatch check computed directly in SQL |
| [`notebooks/`](notebooks) | Formal hypothesis testing, statistical power analysis, novelty-decay curve fitting, p-value meta-analysis |
| [`Excel/`](Excel) | KPI workbook — pivots, conditional formatting, VLOOKUP/INDEX-MATCH |
| [`data/`](data) | Synthetic data generator with programmed ground truth |
| [`docs/`](docs) | Full insights/recommendations report |

**SQL highlight** (two-proportion z-test computed directly in SQL — full
query in [`SQL/02_analysis_queries.sql`](SQL/02_analysis_queries.sql)):
```sql
(p2-p1) / SQRT(p_pool*(1-p_pool)*(1.0/n1+1.0/n2)) AS z_score
```

## Tools & Techniques

SQL (window functions, CTEs, manually-computed statistical tests) ·
Statistics (hypothesis testing, power analysis, meta-analysis) · Excel
(pivot-style summaries, conditional formatting, VLOOKUP/INDEX-MATCH) ·
Power BI dashboard design · Experimentation methodology (SRM checks,
guardrail metrics, novelty effects, segment heterogeneity)

---

© 2026 Temaje Zakaria. All rights reserved.
