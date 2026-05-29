# Phase 18 Count Structured q1 Helper Artifact Audit

Date: 2026-05-29

## Purpose

This slice applies the merged boundary-gate helper to the real
post-diagnostic `count_structured_q1` GitHub Actions artifact from run
`26626333581`. The reader is the next contributor deciding whether the lane is
ready for a larger diagnostic pilot.

## Result

The helper collapsed 192 parameter rows to 48 fitted replicates. It found 5
fit-diagnostic warning replicates, 5 SD-boundary warning replicates, 1 Hessian
warning replicate, and no unexplained warning-ledger rows. All gate checks were
`ok`, and the decision was `propose_next_pilot`.

The warning cells were `count_structured_q1_007`,
`count_structured_q1_008`, `count_structured_q1_010`,
`count_structured_q1_012`, and `count_structured_q1_020`. Each had two
attempted replicates and one SD-boundary warning. Only
`count_structured_q1_020` also had a Hessian warning and warning-ledger row.

## Boundary

This does not run a larger grid and does not claim recovery or coverage. The
decision only allows the next contributor to design a larger diagnostic pilot
with a condition table, replicate count, MCSE target, interval policy, and
runtime budget.

## Validation

```sh
Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); source("inst/sim/R/sim_registry.R"); source("inst/sim/R/sim_utils.R"); source("inst/sim/R/sim_runner.R"); source("inst/sim/R/sim_uncertainty.R"); source("inst/sim/fit/sim_summarise_count_structured_q1.R"); source("inst/sim/run/sim_write_count_structured_q1_grid.R"); root <- "/tmp/drmTMB-phase18-count-structured-q1-diagnostic-smoke-26626333581/phase18-count_structured_q1-shard-1-of-1-26626333581"; audit <- phase18_audit_count_structured_q1_boundary_gate(root, require_complete = TRUE); print(audit$boundary_gate$overall); print(audit$boundary_gate$conditions[audit$boundary_gate$conditions$fit_diagnostic_warning > 0 | audit$boundary_gate$conditions$sd_boundary_warning > 0 | audit$boundary_gate$conditions$hessian_warning > 0, c("cell_id", "family", "structured_type", "n_level", "sd_structured", "mean_count", "sigma_baseline", "n_fit", "fit_diagnostic_warning", "sd_boundary_warning", "hessian_warning")]); print(audit$boundary_gate$checks); print(audit$boundary_gate$decision)'
air format ROADMAP.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-29-phase18-count-structured-q1-helper-artifact-audit.md
Rscript --vanilla -e "pkgdown::check_pkgdown()"
rg -n 'count structured q1.*formal recovery|formal recovery.*count structured q1|count structured q1.*coverage claims|count structured q1.*coverage claim|count structured q1.*all clean|zero-inflated.*count structured q1.*(implemented|supported|admitted)|structured count slopes.*(implemented|supported|admitted)|count structured q1.*task = "all"|task = "all".*count_structured_q1' README.md NEWS.md ROADMAP.md docs/design inst/sim tests/testthat .github/workflows --glob '!docs/dev-log/**'
git diff --check
```

Results are recorded in `docs/dev-log/check-log.md`.

## Member-Group Review

- Ada kept the slice to a read-back audit of existing artifact evidence.
- Curie checked that the helper decision uses fitted-replicate counts.
- Fisher checked that `propose_next_pilot` is not a recovery claim.
- Grace checked documentation hygiene.
- Rose recorded the helper output as a durable handoff.

No spawned subagents were running.
