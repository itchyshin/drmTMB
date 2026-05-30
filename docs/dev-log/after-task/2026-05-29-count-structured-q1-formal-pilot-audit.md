# After-Task Report: Count Structured q1 Formal-Pilot Audit

Date: 2026-05-29

## Task

Audit the first stable-set formal pilot for ordinary Poisson and NB2 count
models with one q=1 structured `mu` intercept.

## Result

GitHub Actions run `26669005577` succeeded on `main` at
`f7e090f26729057cf3f4597dc903e8ec384324a0`. The selected
`count_structured_q1` job `78608250703` finished in 8m35s and uploaded
`phase18-count_structured_q1-shard-1-of-1-26669005577`.

The fit-level boundary gate passed: 10/1000 fitted replicates had
SD-boundary warnings, no fitted replicate had a Hessian warning, and no
warning-ledger row was unexplained. The profile interval gate did not pass:
the artifact had 973 `ok` and 27 failed direct `log_sd_phylo` profile
intervals, and `count_structured_q1_001` had 11/100 failed profile intervals.

The audit decision is `hold_interval_diagnostic`. This result does not permit
a larger recovery-grid design, bootstrap interval work, or broad recovery or
coverage claims.

## Files

- Added
  `docs/design/140-phase-18-count-structured-q1-formal-pilot-audit-slices-1774-1782.md`.
- Updated `ROADMAP.md`.
- Updated `docs/design/41-phase-18-simulation-programme.md`.
- Updated `docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md`.
- Updated `docs/dev-log/check-log.md`.

## Validation

```sh
gh run view 26669005577 --repo itchyshin/drmTMB --job 78608250703
gh run download 26669005577 --repo itchyshin/drmTMB --dir /tmp/drmtmb-count-structured-formal-lJ18lP
Rscript --vanilla - <<'EOF'
out <- "/tmp/drmtmb-count-structured-formal-lJ18lP/phase18-count_structured_q1-shard-1-of-1-26669005577"
source("inst/sim/R/sim_registry.R")
source("inst/sim/R/sim_utils.R")
source("inst/sim/R/sim_runner.R")
source("inst/sim/R/sim_uncertainty.R")
source("inst/sim/fit/sim_summarise_count_structured_q1.R")
source("inst/sim/run/sim_write_count_structured_q1_grid.R")
audit <- phase18_audit_count_structured_q1_boundary_gate(out, require_complete = TRUE)
print(audit$boundary_gate$decision)
print(audit$boundary_gate$overall)
print(audit$boundary_gate$checks)
EOF
air format docs/design/140-phase-18-count-structured-q1-formal-pilot-audit-slices-1774-1782.md ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-29-count-structured-q1-formal-pilot-audit.md
git diff --check
```

Results:

- The successful Actions rerun and selected job runtime were verified.
- The artifact was downloaded and audited from a temporary directory.
- The boundary helper returned `propose_next_pilot` for fit-level diagnostics,
  but the profile interval stop rule returned the overall audit decision to
  `hold_interval_diagnostic`.
- `air format` ran on the touched documentation files.
- `git diff --check` was clean.

## Standing Review

- Ada kept the lane at interval diagnostic evidence.
- Fisher treated the 70% coverage rows as descriptive, not as promotion
  evidence.
- Curie checked row counts, boundary diagnostics, profile interval status, and
  the two watch cells.
- Grace checked the successful Actions rerun and artifact download.
- Rose kept the wording from drifting into broad recovery or coverage claims.
- No spawned subagents were running.
