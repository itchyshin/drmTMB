# After Task: Julia Poisson animal-slope raw A/Ainv evidence registration

## 1. Goal

Link the source-bound Julia Poisson animal random-slope SD test to its exact required covariance and precision provider rows.

## 2. Implemented

Copied the Julia test receipt and supporting source files into the drmTMB evidence tree. Added two unreviewed `focused_test` records for the Julia Poisson log-link animal numeric-slope route: `A_covariance` and `Ainv_precision`.

## 3a. Decisions and Rejected Alternatives

The test uses a supplied non-unit covariance `A = S R S` and its inverse `Ainv = A^{-1}`. It checks the same fitted route under both inputs, compares the fitted objective with a dense Laplace calculation using `A`, and checks seeded marginal simulation against the raw covariance. I kept the records unreviewed and did not label the single fixed-seed test as recovery evidence.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/evidence/poisson-animal-slope-raw-a-20261024/`: receipt, console log, command, source snapshots, test, and source manifest.
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv` and `direct-sd-evidence-summary.md`: two provider rows linked.
- `docs/dev-log/check-log.d/2026-10-24-julia-poisson-animal-slope-raw-a-evidence.md`.
- `LOOP/lanes/general-sd-regression/checkpoint.md`.
- This report.

## 5. Checks Run

- The existing Julia receipt reports 25/25 checks passing in 21.6 seconds. I reran the exact test locally; 25/25 passed in 21.8 seconds. SHA-256 hashes matched before and after for `src/poisson.jl`, `src/inference.jl`, `src/DRModels.jl`, and the test file.
- All source hashes in the copied receipt matched the current Julia candidate before registration.
- `python3 tools/general-sd-regression/reconcile_evidence.py --summary docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`: passed with 19,118 candidate rows, 50 receipt records, and 41 distinct rows linked.
- After-task structure validation passed. Its acceptance-ledger state is `UNKNOWN` because no runnable gate node/check is present; this does not satisfy a programme gate.

## 6. Tests of the Tests

The non-unit covariance makes raw-versus-normalized scaling observable. The dense Laplace objective uses the supplied `A`; the seeded simulator oracle also uses `A`. The test additionally compares `A` and `Ainv`, named SD predictions, serialization, and one bootstrap refit. No test code changed during this registration step.

## 7a. Issue Ledger

No issue action was needed for registration of evidence for an existing route. No issue was opened, commented on, or closed.

## 8. Consistency Audit

Both required rows match the same Julia Poisson log-link animal numeric-slope target and differ only by covariance versus precision input. Both remain `direct_sd_claim=none` and `review_status=unreviewed`. The registration adds no TMB or R-bridge claim.

## 9. What Did Not Go Smoothly

The Graft command was unavailable in this shell. I used the checked-in test graph card and the frozen required-row table, then validated the link with the evidence reconciler. The first lease extension encountered a busy registry lock and was stopped before writing; after the lock cleared, the exact-path claim succeeded.

## 10. Known Residuals

This evidence covers two Julia provider-input rows for one Poisson effect route. It does NOT cover native TMB parity, the R-to-Julia bridge, other Poisson effects, other response families, or interval-coverage calibration. The programme remains open and no acceptance gate closes. The 19,118 candidate rows are not a completion denominator.

## 11. Team Learning

Keep provider-specific evidence keyed to the exact target row. For covariance scaling, pair A/Ainv equivalence with a dense likelihood oracle and a seeded simulator oracle that both use the raw non-unit matrix.

## 12. Cross-Product Coverage

This entry covers Julia Poisson log-link animal numeric slopes with `A_covariance` and `Ainv_precision`. It does NOT cover native TMB, the R-to-Julia bridge, Binomial or other response families, other effect types, or non-animal providers. No public docs, pkgdown navigation, NEWS, or design contract changed because this was evidence registration only.

## Next Actions

Review and resolve ownership of `R/julia-bridge.R` before enabling the same Poisson `Ainv` animal-slope route through `engine = "julia"`. Preserve the existing same-data bridge test and keep all unsupported rows visible.
