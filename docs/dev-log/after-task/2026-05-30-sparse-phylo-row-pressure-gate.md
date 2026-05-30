# After Task: Sparse Phylo Row-Pressure Gate

## Goal

Record bounded local evidence for issue #431: whether the current tree-only
Gaussian `phylo()` location path can fit a 100,000-row, 1,000-species
row-pressure case on the local macOS development machine, and whether that
evidence changes the public `phylo()` API. Here row pressure means many
observation rows relative to the number of species levels, not a larger tree or
broader model-family stress test.

## Implemented

The benchmark log now includes the 100,000-row / 1,000-species row-pressure
case. The phylogenetic/spatial speed design note now records the gate decision:
keep `phylo()` tree-only for now, do not add a dense/sparse switch, and do not
add `phylo(A = ...)` or `phylo(Ainv = ...)` from this evidence. Known precision
or relationship-matrix inputs remain a `relmat()` concern unless a later design
task reopens the API.

## Mathematical Contract

No likelihood, parameterization, formula grammar, or fitted-object API changed.
The benchmark concerns the existing Gaussian sparse `phylo()` location path:
related species are allowed to have similar mean responses through
`phylo(1 | species, tree = tree)`, while `sigma ~ 1` keeps the residual scale
constant.

## Files Changed

- `docs/dev-log/benchmark-results.md`
- `docs/design/09-phylogenetic-and-spatial-speed.md`
- `docs/dev-log/lessons-from-gllvmjl-for-drmtmb.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-30-sparse-phylo-row-pressure-gate.md`

## Checks Run

```sh
/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 100000 --species 1000 --memory-light true --eval-max 200 --iter-max 200 --output /tmp/drmtmb-sparse-phylo-row-pressure-20260530-post432-main.csv
Rscript --vanilla -e "x <- read.csv('/tmp/drmtmb-sparse-phylo-row-pressure-20260530-post432-main.csv', check.names = FALSE); print(x[, c('run_started_utc','r_version','os','machine','TMB_version','rows','species','tree','fit_sec','convergence','iterations','function_evaluations','gradient_evaluations','sigma_hat','sd_phylo_hat','fit_object_mb','model_matrix_mb','tmb_data_mb','gc_used_mb_post_fit','git_sha','git_dirty','benchmark_command')])"
Rscript --vanilla -e "devtools::load_all(quiet = TRUE); testthat::test_file('tests/testthat/test-phylo-utils.R'); testthat::test_file('tests/testthat/test-phylo-gaussian.R')"
gh issue view 431 --repo itchyshin/drmTMB --comments
rg -n "sparse phylogeny from scratch|add sparse phylogeny|blank implementation task|GLLVM\\.jl speedups|drmTMB speedups|coverage improves|10×|100×|public speed claim|scaling claim|recovery claim|coverage claim|API decision|phylo_relaxed|phylo_representation|dense fallback|phylo\\(A|Ainv|tau ~" README.md NEWS.md ROADMAP.md docs/design docs/dev-log/benchmark-results.md docs/dev-log/lessons-from-gllvmjl-for-drmtmb.md vignettes bench/README.md
air format docs/dev-log/benchmark-results.md docs/design/09-phylogenetic-and-spatial-speed.md docs/dev-log/lessons-from-gllvmjl-for-drmtmb.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-sparse-phylo-row-pressure-gate.md
git diff --check
```

The benchmark harness recorded R 4.5.2, TMB 1.9.21, Darwin 25.5.0 on arm64,
git SHA `7c045d21`, and `git_dirty = FALSE`.

## Tests Of The Tests

The benchmark result is paired with existing dense-parity tests for tiny trees:
`tests/testthat/test-phylo-utils.R` checks the sparse precision against dense
Brownian covariance, and `tests/testthat/test-phylo-gaussian.R` checks selected
fitted Gaussian objectives against dense marginal likelihood comparators. Those
tests guard the benchmark from becoming only a timing row with no correctness
anchor.

## Consistency Audit

The row-pressure run converged with optimizer code 0 after 45 iterations and 69
function evaluations. Fit time was 25.471 seconds. The fitted phylogenetic
standard deviation estimate was `sd_phylo_hat = 0.5014775`; the residual scale
estimate was `sigma_hat = 0.4013018`.

Object sizes were 47.43359 MB for the fitted object, 15.26065 MB for the model
matrix, and 22.09883 MB for the TMB data object. Post-fit R heap was
196.0538 MB. macOS `/usr/bin/time -l` reported max RSS 2,253,438,976 bytes and
peak footprint 768,132,752 bytes.

The stale-wording scan returned intentional guardrail, no-claim, and historical
entries. It did not reveal a new current-facing public speed, API, recovery, or
coverage claim from this slice.

No README, NEWS, vignette, roxygen, pkgdown navigation, R code, or C++ code
changed. Public-facing documentation and pkgdown generated docs do not need an
update for this internal benchmark gate.

## GitHub Issue Maintenance

PR #433 is intended to close issue #431 by converting the smoke plus
row-pressure evidence into durable repo notes and by recording the narrow API
decision. The issue does not close broad sparse-phylo benchmarking,
cross-platform performance, or matrix-input design questions.

## What Did Not Go Smoothly

The first row-pressure run was collected on PR #432's head commit. The final
closeout branch reran the benchmark after PR #432 merged, so the recorded CSV
points at the post-merge main SHA `7c045d21`.

## Team Learning

Ada kept the task scoped to benchmark documentation plus the API gate. Grace
kept the memory evidence tied to macOS `/usr/bin/time -l`. Jason kept
`phylo()` tree-only and left matrix inputs under `relmat()` for now. Fisher kept
the result out of recovery and coverage claims. Rose kept the stale-wording scan
and issue closeout explicit.

## Known Limitations

This is one local macOS run. It does not test Linux or Windows memory
behaviour, repeated-run variability, sparse fixed-effect combinations,
aggregation, `sigma ~ x1`, bivariate coscale models, non-Gaussian families,
biological inference, recovery, coverage, million-row readiness, or any
transferred GLLVM.jl speedup claim.

## Next Actions

Leave broader sparse-phylo speed work to future benchmark tasks. Do not add
`phylo(A = ...)`, `phylo(Ainv = ...)`, a dense/sparse switch, or branch-rate
syntax without a separate design task and validation evidence.
