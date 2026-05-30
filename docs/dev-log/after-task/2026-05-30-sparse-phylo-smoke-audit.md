# After Task: Sparse Phylo Smoke Benchmark Audit

## Goal

Record the first bounded issue #431 sparse `phylo()` smoke benchmark as
internal planning evidence without changing model-fitting code, formula
grammar, public documentation, or user-facing API.

## Implemented

The benchmark log now includes three local macOS smoke rows for the current
Gaussian `phylo(1 | species, tree = tree)` location path. The cleaned GLLVM.jl
lessons note now says that the first p = 50, 200, and 1000 smoke sizing cells
exist and that issue #431 remains open for row-pressure and API guidance.

## Mathematical Contract

No likelihood, parameterization, optimizer contract, or formula grammar changed.
All runs used Gaussian responses, `sigma ~ 1`, balanced synthetic trees, and
the existing sparse `phylo()` location path with `sparse_fixed = FALSE` and
`aggregate_gaussian = FALSE`.

## Files Changed

- `docs/dev-log/benchmark-results.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/lessons-from-gllvmjl-for-drmtmb.md`
- `docs/dev-log/after-task/2026-05-30-sparse-phylo-smoke-audit.md`

## Checks Run

```sh
/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 500 --species 50 --memory-light true --eval-max 100 --iter-max 100 --output /tmp/drmtmb-sparse-phylo-scaling-20260530-main.csv
/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 2000 --species 200 --memory-light true --eval-max 120 --iter-max 120 --output /tmp/drmtmb-sparse-phylo-scaling-20260530-main.csv
/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 10000 --species 1000 --memory-light true --eval-max 160 --iter-max 160 --output /tmp/drmtmb-sparse-phylo-scaling-20260530-main.csv
Rscript --vanilla -e "x <- read.csv('/tmp/drmtmb-sparse-phylo-scaling-20260530-main.csv', check.names = FALSE); print(x[, c('run_started_utc','r_version','os','machine','TMB_version','rows','species','tree','fit_sec','convergence','iterations','function_evaluations','gradient_evaluations','sigma_hat','sd_phylo_hat','fit_object_mb','model_matrix_mb','tmb_data_mb','gc_used_mb_post_fit','git_sha','git_dirty','benchmark_command')])"
gh issue view 431 --repo itchyshin/drmTMB --comments
rg -n "sparse phylogeny from scratch|add sparse phylogeny|blank implementation task|GLLVM\\.jl speedups|drmTMB speedups|coverage improves|10×|100×|public speed claim|scaling claim|recovery claim|coverage claim|API decision|phylo_relaxed|phylo_representation|dense fallback|tau ~" README.md NEWS.md ROADMAP.md docs/design docs/dev-log/benchmark-results.md docs/dev-log/lessons-from-gllvmjl-for-drmtmb.md vignettes bench/README.md
air format docs/dev-log/benchmark-results.md docs/dev-log/check-log.md docs/dev-log/lessons-from-gllvmjl-for-drmtmb.md docs/dev-log/after-task/2026-05-30-sparse-phylo-smoke-audit.md
git diff --check
```

The benchmark harness recorded R 4.5.2, TMB 1.9.21, Darwin 25.5.0 on arm64,
git SHA `d093bedd`, and `git_dirty = FALSE`.

## Tests Of The Tests

No testthat tests were added because this task records a non-CRAN benchmark
artifact. The useful validation is the benchmark harness metadata, optimizer
convergence codes, macOS max-RSS measurements, and the issue #431 stop-rule
boundary.

## Consistency Audit

The three smoke cells all returned optimizer convergence code 0:

| Rows | Species | Fit seconds | sd_phylo_hat | Max RSS bytes |
| ---: | ---: | ---: | ---: | ---: |
| 500 | 50 | 0.553 | 0.3989654 | 409,518,080 |
| 2,000 | 200 | 1.115 | 0.5086050 | 455,131,136 |
| 10,000 | 1,000 | 5.582 | 0.5065229 | 679,510,016 |

The largest smoke cell stayed below the issue #431 stop rules. The result is
local smoke evidence for the current sparse `phylo()` location path. It is not
a public speed claim, cross-platform benchmark, sparse-fixed-effect benchmark,
biological-inference validation, recovery claim, coverage claim, or transferred
GLLVM.jl speed claim.

The stale-wording scan returned intentional guardrail, no-claim, and historical
check-log hits. It did not reveal a new current-facing public speed, API,
recovery, or coverage claim from this slice.

## GitHub Issue Maintenance

Issue #431 already tracks the sparse-phylo benchmark/API gate. It was updated
with the preliminary smoke output before this docs slice, and this task keeps
the issue open because row-pressure checks and API guidance still remain.

## What Did Not Go Smoothly

The first smoke run was created on the PR #430 branch. The audit reran all
three cells after switching to a fresh branch from `origin/main` so the recorded
CSV points at the merged main SHA.

## Team Learning

Grace kept the claim platform-specific. Rose required the benchmark-results,
check-log, and after-task triangle before calling the slice complete. Jason
kept the issue #431 API gate open. Pat and Darwin kept the contributor-facing
interpretation focused on what the smoke evidence can and cannot support.

## Known Limitations

This slice did not run Linux or Windows benchmarks, compare dense and sparse
phylogenetic likelihoods, combine sparse fixed effects with `phylo()`, test
row-pressure beyond 10,000 rows, or evaluate `sigma ~ x`. It also did not run
`devtools::test()`, `devtools::check()`, `devtools::document()`, or
`pkgdown::check_pkgdown()` because no package code, roxygen, vignettes, or
public documentation changed.

## Next Actions

Use issue #431 for the next benchmark/API decision. The next evidence slice
should test row pressure after the p = 1,000 smoke cell, then decide whether
`docs/design/09-phylogenetic-and-spatial-speed.md` needs API guidance for
large tree or row-count regimes.
