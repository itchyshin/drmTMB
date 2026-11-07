# After Task: Gaussian slope SD bridge label repair

## 1. Goal

Make the existing ordinary Gaussian independent-slope SD route fit through the paired R-to-Julia bridge and record fresh source-bound point-recovery evidence.

## 2. Implemented

The Julia bridge now maps the selected Gaussian slope SD target to DRM.jl's canonical `sd` coefficient block for one ordinary `mu` intercept or one matching numeric slope. The admission helper requires a matching group and coefficient, fixed-effect-only `sigma`, and no structured terms or random effects in the SD formula. The native Gaussian builder and generic C++ SD-row mapping were already present.

## 3a. Decisions and Rejected Alternatives

The fix changes only Gaussian output-label mapping for the exact scalar SD route. I left correlated and structured slopes, multiple targets, residual-scale random effects, and other Gaussian combinations outside this admission. The test uses one synthetic complete-data design and does not justify interval-coverage claims.

## 4. Files Touched

- `R/julia-bridge.R`: exact Gaussian route guard and canonical `sd` block mapping.
- `NEWS.md`, `docs/design/01-formula-grammar.md`, `docs/dev-log/general-sd-regression/inventory.md`, `docs/dev-log/known-limitations.md`, and `vignettes/julia-engine.Rmd`: describe the paired candidate route and its limits.
- `docs/dev-log/general-sd-regression/evidence/gaussian-sd-slope-current-20261025/`: console, source manifest, and two unreviewed row receipts.
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv` and its generated summary: link current source-bound recovery evidence to the existing native and Julia slope rows.
- This report, `docs/dev-log/check-log.md`, and `LOOP/lanes/general-sd-regression/arcs.md`.

**Mathematical Contract**

For group `g`, the selected random slope is `b_xg ~ Normal(0, tau_g^2)` with `log(tau_g) = alpha_0 + alpha_1 w_g`. It enters the location predictor as `b_xg * x_ig`. The SD predictor `w` is constant within group; `sigma` remains fixed.

## 5. Checks Run

The combined source-bound command passed the native recovery filter with 12 expectations and the live bridge filter with two Julia fits and 22 expectations. The bridge checks coefficient labels and estimates, log-likelihood agreement, and group-SD predictions. The 13-file manifest had identical SHA-256 values before and after both filters. Exact output and receipts are in `evidence/gaussian-sd-slope-current-20261025/`.

`rmarkdown::render("vignettes/julia-engine.Rmd", ...)` exited 0. Pandoc reported its existing `--mathjax` deprecation warning. `pkgdown::check_pkgdown()` returned `No problems found`, with existing `--mathml` deprecation warnings. The evidence reconciler passed with 19,118 candidate rows, 79 receipts, 60 linked rows, and 19,058 unlinked rows. The targeted `git diff --check` passed. `slop_check.py` found zero findings in this report.

The after-task structure check passed. Its acceptance-ledger check returned `UNKNOWN` because the candidate unlazy ledger has no runnable node or gate-check command; no programme gate is advanced by this report.

## 6. Tests of the Tests

The first live Julia parity attempt reached the engine and failed at the coefficient-label echo because no payload label was built for `sd`. After the narrow mapping repair, the same paired filter passed. A prior attempt using a relative Julia path skipped both bridge tests; it was retried with the absolute paired-worktree path. The native test separately checks constant-SD likelihood equivalence and refuses the correlated q2 block.

## 7a. Issue Ledger

Open issue #1551 concerns bare Poisson and Gamma random intercepts that fail at DRM.jl's `resd` echo and require a Laplace-control decision. It does not cover a Gaussian selected SD slope. No issue was opened, edited, or closed.

## 8. Consistency Audit

The formula, DGP, bridge predicate, and public target all identify the same numeric slope and group-level predictor. The vignettes and inventory describe one ordinary q1 candidate route and distinguish point parity from interval calibration. The source-bound receipts remain `unreviewed` and do not promote either candidate row.

## 9. What Did Not Go Smoothly

The prior Gaussian slope receipt had stale hashes for three R files, so it could not establish the live bridge state. The relative path in the first rerun also failed to survive the test runner's working-directory change. The absolute-path run exposed the actual label-mapping defect, which the final source-bound run verified as fixed.

## 10. Known Residuals

This is one seeded synthetic design. It does not establish broad Gaussian parity, calibrated intervals, profile or bootstrap integrity, correlated or structured slope support, or cross-engine support for every Gaussian direct-SD shape. Both candidate worktrees remain dirty. The full package test and check suites remain outstanding.

## 11. Team Learning

For a bridge route that reaches Julia but fails its coefficient echo, inspect the exact internal dpar key before changing likelihood code. Run the focused parity test with an absolute paired-worktree path, then bind the result to before-and-after hashes for both engines.

## 12. Cross-Product Coverage

This slice changes the R-to-Julia bridge label mapping and documents the one tested Gaussian slope route. It does NOT cover other Gaussian random-effect types or endpoints, non-Gaussian families, broad provider parity, public inference calibration, full package checks, or release readiness. Coverage calibration remains deferred as agreed; all broader programme gates remain open.

## Next Actions

Continue with the next unreceipted required family/effect/backend row after checking current source ownership and the existing candidate diffs.
