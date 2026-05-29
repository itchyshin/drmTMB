# After Task: Phase 18 Tweedie Manual Actions Smoke Audit

Date: 2026-05-28

## Goal

Audit the first manual GitHub Actions `tweedie_fixed_effect` smoke artifact run
after PR #363 merged the manual task.

## Actions Run

- URL: `https://github.com/itchyshin/drmTMB/actions/runs/26608885245`
- Task: `tweedie_fixed_effect`
- Inputs: `n_reps = 2`, `cores = 2`, `backend = "multicore"`,
  `bootstrap_nsim = 0`, `render_report = false`, `condition_shard = 1`,
  `condition_shards = 1`.
- Result: success. The unselected matrix rows skipped cleanly, and the
  selected `tweedie_fixed_effect` row ran setup, task, summary, and artifact
  upload.

## Artifact Audit

The downloaded artifact
`phase18-tweedie_fixed_effect-shard-1-of-1-26608885245` contained:

- `phase18-actions-result.rds`;
- 16 replicate RDS files across 8 condition cells;
- `tweedie-fe-aggregate.csv` with 40 rows;
- `tweedie-fe-replicates.csv` with 80 coefficient rows;
- `tweedie-fe-manifest.csv` with 16 rows;
- `tweedie-fe-failures.csv` with 0 rows;
- `tweedie-fe-wald-intervals.csv` with 80 rows;
- `tweedie-fe-wald-coverage.csv` with 40 rows.

All 16 manifest rows had status `ok`; no replicate was skipped and no warnings
were recorded. All 80 coefficient rows had `converged = TRUE` and
`pdHess = TRUE`. The result object reported
`surface = "tweedie_fixed_effect_grid"` with `backend = "multicore"`,
`requested_cores = 2`, and `cores = 2`.

The eight cells crossed `n = 260, 520`, `zero_regime = low, high`, and
`rho_xz = 0, 0.4`. Mean observed zero fractions stayed low in the low-zero
cells and high in the high-zero cells. This is smoke artifact evidence only;
two replicates per cell cannot support final coverage or operating-character
claims.

## Boundary

This audit does not add a model feature, change formula grammar, expand
Tweedie support beyond univariate fixed effects with intercept-only `nu`, add
condition sharding, or promote any coverage claim.

## Validation

```sh
gh workflow run phase18-simulation-grid.yaml --ref main -f task=tweedie_fixed_effect -f n_reps=2 -f cores=2 -f backend=multicore -f bootstrap_nsim=0 -f bootstrap_cores=2 -f bootstrap_backend=none -f profile_parameters='' -f condition_shard=1 -f condition_shards=1 -f render_report=false -f retention_days=14
gh run watch 26608885245 --interval 30
gh run download 26608885245 --name phase18-tweedie_fixed_effect-shard-1-of-1-26608885245 --dir /tmp/drmTMB-phase18-tweedie-actions-26608885245
find /tmp/drmTMB-phase18-tweedie-actions-26608885245 -maxdepth 4 -type f | sort
Rscript --vanilla -e 'root <- "/tmp/drmTMB-phase18-tweedie-actions-26608885245"; read <- function(name) utils::read.csv(file.path(root, "tables", name)); aggregate <- read("tweedie-fe-aggregate.csv"); replicates <- read("tweedie-fe-replicates.csv"); coverage <- read("tweedie-fe-wald-coverage.csv"); intervals <- read("tweedie-fe-wald-intervals.csv"); failures <- read("tweedie-fe-failures.csv"); manifest <- read("tweedie-fe-manifest.csv"); print(data.frame(file = basename(list.files(file.path(root, "tables"), pattern = "[.]csv$", full.names = TRUE)), rows = vapply(list.files(file.path(root, "tables"), pattern = "[.]csv$", full.names = TRUE), function(p) nrow(utils::read.csv(p)), integer(1)), row.names = NULL)); print(table(manifest$status, useNA = "ifany")); print(nrow(failures)); print(table(replicates$converged, useNA = "ifany")); result <- readRDS(file.path(root, "phase18-actions-result.rds")); print(result$surface); print(result$summary$run$parallel)'
Rscript --vanilla -e 'root <- "/tmp/drmTMB-phase18-tweedie-actions-26608885245"; rep <- utils::read.csv(file.path(root, "tables", "tweedie-fe-replicates.csv")); agg <- utils::read.csv(file.path(root, "tables", "tweedie-fe-aggregate.csv")); print(unique(rep[c("cell_id", "n", "zero_regime", "rho_xz", "target_zero_fraction", "sigma_baseline", "power")])); print(unique(agg[c("cell_id", "n_replicate", "convergence_rate", "pdHess_rate", "warning_rate")])); print(aggregate(observed_zero_fraction ~ cell_id + zero_regime + n + rho_xz, rep, mean))'
air format ROADMAP.md docs/design/133-phase-18-tweedie-fixed-effect-artifact-preflight-slices-1644-1646.md docs/design/41-phase-18-simulation-programme.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-28-phase18-tweedie-actions-smoke-audit.md
Rscript --vanilla -e "pkgdown::check_pkgdown()"
rg -n 'Tweedie.*ready for.*coverage|final coverage claim|coverage claim[^s]|predictor-dependent Tweedie `nu`.*(implemented|supported|admitted)|Tweedie random effects.*(implemented|supported|admitted)|bivariate Tweedie.*(implemented|supported|admitted)|zero-inflation alias.*(implemented|supported|admitted)|hurdle alias.*(implemented|supported|admitted)' README.md NEWS.md ROADMAP.md docs/design inst/sim R src NAMESPACE man tests/testthat .github/workflows --glob '!docs/dev-log/**' --glob '!docs/reference/**' --glob '!docs/articles/**'
git diff --check
```

`pkgdown::check_pkgdown()` reported no problems. The boundary scan returned the
intended new roadmap row plus older standing coverage-boundary references, not
an expanded Tweedie support claim. `git diff --check` was clean.

## Team Review

Ada kept this as an operational audit following the merged task PR. Curie
checked row counts, manifest status, convergence, Hessian status, and warning
counts. Fisher kept the Wald coverage rows framed as two-replicate smoke
artifacts rather than coverage evidence. Grace checked the workflow skip
behavior and artifact upload. Rose recorded the audit in the roadmap, design
note, check log, and after-task report.

No spawned subagents were running.

## Next Actions

The next narrow slice should add a small artifact read-back QA helper or plan a
larger bounded `tweedie_fixed_effect` replication run, but not both in one PR.
