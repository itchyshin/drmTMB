# After-Task Report: Count Structured q1 Profile-Failure Example Details

## Purpose

This slice makes the artifact-level profile failure summary show the requested
profile row from each example replicate RDS. The next geometry review can now
see the public structured-SD parameter, truth, estimate, interval endpoints, and
profile status without reconstructing or rerunning the profile.

## Changes

`phase18_audit_count_structured_q1_profile_gate()` now calls
`phase18_count_structured_q1_attach_example_profile_details()` after attaching
example result paths. The helper reads each available example RDS, finds the
requested profile row, and adds `example_profile_detail_status`,
`example_parameter`, `example_truth`, `example_estimate`,
`example_profile_conf_low`, `example_profile_conf_high`,
`example_profile_status`, `example_profile_message`,
`example_profile_target_status`, and `example_profile_target_parameter` to
`failure_summary`.

## Validation

```sh
air format inst/sim/run/sim_write_count_structured_q1_grid.R tests/testthat/test-phase18-count-structured-q1.R ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-29-count-structured-q1-profile-failure-example-details.md
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
print(audit$profile_gate$failure_summary[, c("cell_id", "failure_class", "example_replicate", "example_profile_detail_status", "example_parameter", "example_truth", "example_estimate", "example_profile_conf_low", "example_profile_conf_high", "example_profile_status", "example_profile_target_parameter", "failed_interval")])
EOF
git diff --check
```

The focused `phase18-count-structured-q1` suite passed. On artifact
`26669005577`, all 11 failure-summary rows had
`example_profile_detail_status = "ok"`, `example_profile_status = "failed"`,
and `example_profile_target_parameter = "log_sd_phylo"`. Several failed
examples had structured-SD estimates near zero despite truth 0.6, including
`count_structured_q1_006` replicate 45, `count_structured_q1_003` replicate 33,
and `count_structured_q1_005` replicate 74. `git diff --check` was clean after
formatting.

## Scope Boundaries

This slice does not rerun profiles, change the profile grid, alter the
likelihood, or claim recovery performance. It only reads saved replicate
summaries from the formal-pilot artifact and keeps the lane in
`hold_interval_diagnostic`.

## Review

Ada kept the work inside the artifact audit surface. Fisher kept the new fields
as evidence for the next interval-geometry review rather than a coverage claim.
Curie covered the synthetic RDS path in the focused test. Grace checked the
helper on the downloaded formal-pilot artifact. Rose flagged the near-zero
structured-SD examples as the next diagnostic target.
