# A1 marginal-bootstrap coverage campaign — 2026-07-25 (Totoro)

Coverage evidence for the change made in **PR #843 (Arc A1)**: `simulate.drmTMB()` gained
`re.form`, with `NULL` (marginal) as the new default, and `confint(method = "bootstrap")`
inherits it via `bootstrap_re_form`.

**Interpretation, boundaries, and what may NOT be claimed:**
[`docs/design/246-marginal-bootstrap-coverage.md`](../../../design/246-marginal-bootstrap-coverage.md).

## Headline

The **old** conditional bootstrap covered a nominal 95% random-effect-SD interval
**50.9%** of the time. The **new** marginal default reaches **87.1%** — a large repair,
but **still not nominal**. A1 was necessary and is not sufficient.

| Estimand (nominal 0.95) | marginal | conditional |
| --- | --- | --- |
| RE SD `sd:mu:(1\|g)` | **0.8714** | **0.5092** |
| `sigma` | 0.9319 | 0.9320 |
| `fixef:mu:x` | 0.9437 | 0.9356 |

## Design

Gaussian random intercept `bf(y ~ x + (1 | g), sigma ~ 1)`; truths `beta = 0.5`,
`sigma = 0.7`. Grid `n_groups ∈ {10, 25, 50}` × `n_per ∈ {4, 10}` × `sd_mu ∈ {0.5, 1.0}`
= 12 cells. **1000 replicates per cell** (20 shards × 50), `R = 199` bootstrap refits,
both `bootstrap_re_form = NULL` and `= NA`. 200-way parallel on Totoro.

**72,000 interval rows. Zero attrition. Zero bootstrap refit failures.**

The prediction was **pre-registered in the script header before launch** (see
`a1_coverage.R`), including the condition under which A1's claimed mechanism would be
declared *wrong*. Two of the three predictions held; the third — that marginal would attain
~0.95 — **failed**, and that failure is the operative result.

## Files

| File | What it is |
| --- | --- |
| `a1_coverage.R` | the campaign script, with the pre-registered prediction in its header |
| `a1_analyse.R` | analysis; exact-binomial CIs, **full denominator**, explicit verdict per prediction |
| `a1_coverage_cell_summary.csv` | 72 rows = 12 cells × 3 estimands × 2 arms; `n`, `coverage`, `median_width` |
| `a1_coverage_summary.txt` | the printed analysis, including the attrition table |

**Raw per-replicate output is deliberately NOT committed** (240 shard CSVs, 72,000 rows).
Per `D-50`, campaign outputs stay local rather than in the repo or in GitHub Actions
artifacts. Raw data lives on Totoro at `~/drm_work/results/` with an archive at
`~/drm_work/a1_coverage_results.tar.gz` (2.3 MB). Seeds are deterministic per cell and
shard, so the raw set is reproducible from the committed script alone.

## Reproduce

```bash
ssh totoro
cd ~/drm_work && Rscript a1_analyse.R          # re-print the summary
# full re-run (~35 min at 200-way parallel):
#   cat joblist.txt | xargs -P 200 -n 3 ~/drm_work/run_shard.sh
```

## Scope fence

Gaussian random intercept only, one covariate, constant residual scale, complete data,
percentile intervals as `confint()` currently builds them, `R = 199`. **No claim** about
non-Gaussian families, structured random effects, `sd() ~ x` regressions, bivariate routes,
or missing data. **No capability-ledger cell is promoted by this evidence** — it points
down, and the asymmetric tier fence forbids promotion regardless.
