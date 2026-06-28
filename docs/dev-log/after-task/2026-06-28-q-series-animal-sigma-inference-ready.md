# Q-Series animal sigma inference-ready promotion

## 1. Goal

Promote exactly `qseries_animal_q1_sigma_one_slope` to `inference_ready` for
interval and coverage status after Fisher accepted the raw-Wald sigma-channel
evidence and Rose required a synchronized status edit.

## 2. Implemented

This promotes exactly `qseries_animal_q1_sigma_one_slope` under the raw
uncorrected log-SD Wald-z interval channel with SR1000 retained-attempt
denominator accounting and does not claim pedigree/Ainv bridge marshalling,
matched `mu+sigma`, spatial sigma, animal q2, q4/q8, REML, AI-REML, bridge
support, `supported`, or public support.

Updated the support-cell row in
`docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv` to
`interval_status = inference_ready` and `coverage_status = inference_ready`.

Added endpoint evidence rows for animal `sigma:(Intercept)` and `sigma:x` in
`docs/dev-log/dashboard/structured-re-sigma-slope-inference-evidence.tsv`, and
added the compact widget summary row in
`docs/dev-log/dashboard/structured-re-q-series-inference-evidence-summary.tsv`.

Updated the spatial/animal sigma admission audit so the animal row is no
longer `calibration_required`; it is now
`promoted_after_fisher_rose_signoff` with `promotion_decision =
promote_exact_cell`.

Synchronized `tools/validate-mission-control.py`,
`tests/testthat/test-structured-re-conversion-contracts.R`, `README.md`,
`NEWS.md`, `ROADMAP.md`, `docs/design/01-formula-grammar.md`,
`docs/design/218-structured-q-series-completion-map.md`,
`docs/dev-log/dashboard/README.md`, and `docs/dev-log/check-log.md`.

## 3a. Decisions and Rejected Alternatives

The estimand is the direct structured residual-scale SD in the Gaussian
`sigma` formula:

- `sd:sigma:animal(1 | id)`, truth 0.50;
- `sd:sigma:animal(0 + x | id)`, truth 0.38.

The accepted interval channel is raw uncorrected log-SD Wald-z. The
location-axis bias+t correction does not apply to sigma. Profile intervals
remain diagnostic-only because the finite-profile rates are 891/1000 and
726/1000.

I did not promote `supported`. One-sided misses are still asymmetric, and
support-grade evidence needs g-stress or skew/bias-aware sigma intervals.

I did not promote spatial sigma, animal q2, matched `mu+sigma`, q4/q8,
non-Gaussian rows, bridge support, REML, or AI-REML.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-sigma-slope-inference-evidence.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-inference-evidence-summary.tsv`
- `docs/dev-log/dashboard/structured-re-sigma-slope-spatial-animal-admission-audit.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-28-q-series-animal-sigma-inference-ready.md`

## 5. Checks Run

- Fisher subagent audit: accepted promotion for the exact row under raw
  uncorrected log-SD Wald-z, with SR1000 retained-attempt denominator
  accounting and profile diagnostic-only wording.
- Rose subagent audit: blocked partial promotion and required synchronized
  support-cell, evidence, validator, test, docs, check-log, and after-task
  updates before the row could be called `inference_ready`.
- `python3 tools/validate-mission-control.py`: passed with
  `mission_control_ok` after the coordinated update.

## 6. Tests of the Tests

The validator now requires exactly five Q-Series interval+coverage
`inference_ready` rows and exactly six sigma endpoint evidence rows. The
focused test now includes `qseries_animal_q1_sigma_one_slope` in the signed-off
inference-ready cell set and checks the animal intercept one-sided miss counts
directly.

## 7a. Issue Ledger

- `qseries_animal_q1_sigma_one_slope`: promoted to `inference_ready` with
  caveats.
- `qseries_spatial_q1_sigma_one_slope`: still blocked because
  `sigma:(Intercept)` finite-Wald rate is 0.9360 after SR1000.
- `qseries_animal_q2_mu1_mu2_one_slope`: unchanged; q2 animal remains a
  separate row-level arc.

No GitHub issue was opened. This is a PR #685 evidence/status tranche.

## 8. Consistency Audit

NEWS, README, ROADMAP, formula grammar, the Q-Series completion map, dashboard
README, validator, focused tests, support-cell TSV, evidence sidecars, and
check-log now agree on five `inference_ready` Q-Series rows:

- `qseries_phylo_q1_sigma_one_slope`;
- `qseries_animal_q1_sigma_one_slope`;
- `qseries_relmat_q1_sigma_one_slope`;
- `qseries_phylo_q2_mu1_mu2_one_slope`;
- `qseries_relmat_q2_mu1_mu2_one_slope`.

The documentation keeps sigma evidence separate from the location-axis q2
bias+t correction, and it keeps `supported`, REML, AI-REML, bridge support,
spatial sigma, animal q2, matched `mu+sigma`, q4/q8, count, and non-Gaussian
rows unpromoted.

## 9. What Did Not Go Smoothly

The first TSV update helper used a base-pipe expression that R rejected inside
the here-doc. I reran the TSV update idempotently with an explicit `if`
assignment before validating.

The first mission-control run caught animal endpoint claim-boundary wording
that mentioned `bias+t` without the required phrase "does not apply to sigma".
That guard worked as intended.

## 10. Known Residuals

The row is `inference_ready`, not `supported`. Support requires g-stress,
skew/bias-aware sigma intervals, and a stricter one-sided miss audit. The
profile channel remains diagnostic-only at deployment g=8.

The next bounded Q-Series tranche is likely q2 spatial/animal location-slope
top-up or non-Gaussian count recovery, not q4/q8 inference.

## 11. Team Learning

Rose's block was useful: it prevented a support-cell-only promotion. Status
changes must update the support-cell row, endpoint evidence, compact widget
summary, admission/audit sidecar, validator, tests, public prose, check-log,
and after-task report in one coherent edit.
