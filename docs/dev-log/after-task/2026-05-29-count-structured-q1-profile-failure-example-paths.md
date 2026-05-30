# After-Task Report: Count Structured q1 Profile-Failure Example Result Paths

## Purpose

This slice makes the artifact-level profile failure summary point directly to
the downloaded replicate RDS files. The next profile-geometry diagnostic should
not have to reconstruct paths from `cell_id` and `example_replicate` by hand.

## Changes

`phase18_audit_count_structured_q1_profile_gate()` now attaches
`example_result_path` and `example_result_exists` to `failure_summary` rows when
`example_replicate` is present. The path points to
`results/<cell_id>/replicate_<replicate>.rds` inside the normalized artifact
directory. Existing paths are normalized with `normalizePath()` so tests and
downstream diagnostics see platform-native separators.

## Validation

```sh
air format inst/sim/run/sim_write_count_structured_q1_grid.R tests/testthat/test-phase18-count-structured-q1.R ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-29-count-structured-q1-profile-failure-example-paths.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-count-structured-q1', reporter = 'summary')"
Rscript --vanilla - <<'EOF'
out <- "/tmp/drmtmb-count-structured-formal-lJ18lP/phase18-count_structured_q1-shard-1-of-1-26669005577"
source("inst/sim/R/sim_registry.R")
source("inst/sim/R/sim_utils.R")
source("inst/sim/R/sim_runner.R")
source("inst/sim/R/sim_uncertainty.R")
source("inst/sim/fit/sim_summarise_count_structured_q1.R")
source("inst/sim/run/sim_write_count_structured_q1_grid.R")
audit <- phase18_audit_count_structured_q1_profile_gate(
  out,
  require_complete = TRUE,
  watch_cells = c("count_structured_q1_003", "count_structured_q1_005")
)
print(audit$profile_gate$failure_summary[, c("cell_id", "failure_class", "example_replicate", "example_result_exists", "failed_interval")])
EOF
git diff --check
```

The focused `phase18-count-structured-q1` suite passed. On artifact
`26669005577`, all 11 failure-summary rows had `example_result_exists = TRUE`.
After Windows CI reported mixed separators in the synthetic artifact audit test,
the helper normalized existing paths and the focused suite plus formal artifact
smoke test still passed. `git diff --check` was clean after formatting. The
stale-claim scan found only intended negative wording and the earlier
workflow-plumbing row.

## Scope Boundaries

This slice does not load or inspect the replicate RDS files, change profile
computation, or change the `hold_interval_diagnostic` decision. It only records
artifact paths that the next diagnostic can use.

## Review

Ada kept the path attachment inside the artifact wrapper. Fisher kept paths tied
to failed requested profile intervals. Curie covered path existence in the
focused test. Grace checked the real artifact. Rose kept this as routing
evidence rather than a geometry finding.
