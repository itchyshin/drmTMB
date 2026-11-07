# After Task: Cumulative-logit SD Regression Through the Julia Bridge

## 1. Goal
Admit and check one missing R-to-Julia bridge cell: a complete-response cumulative-logit model with one ordinary numeric location slope and a matching predictor-dependent SD.

## 2. Implemented
The bridge now admits `bf(score ~ x + (0 + x | id), sd(id, coef = "x") ~ w)` through a family-specific gate. The gate requires one numeric location slope, one matching `sd()` target, a numeric slope variable, and no additional distributional or structured terms. Random intercepts and other unsupported cumulative-logit random-effect shapes remain refused through the bridge.

The scalar model has

\[
b_{g,x} \sim N(0,\tau_g^2), \qquad \log \tau_g = W_g\alpha.
\]

For cumulative logit, this SD is on the latent location scale with fixed logistic residual scale. The test uses 256 groups, 30 observations per group, seed 202610205, and true SD-predictor slope 0.5.

## 3a. Decisions and Rejected Alternatives
The response likelihood, latent random-slope coefficient, and SD predictor are the same across the native TMB fit and Julia bridge formula. TMB uses Laplace integration and Julia uses adaptive Gauss-Hermite quadrature, so the test checks finite likelihoods and point recovery with declared tolerances; it does not require exact likelihood equality. The SD predictor is constant within each group.

I kept the family registry's fixed-effect fence and added one exact exception. Removing the fence for every cumulative-logit random effect would admit shapes without matching tests. The mathematical contract for this slice is `b[g, x] ~ Normal(0, tau[g]^2)` with `log(tau[g]) = W[g] alpha`, where `w` is constant within group.

## 4. Files Touched
- `R/julia-bridge.R`: exact cumulative-logit numeric-slope SD admission helper.
- `R/julia-family-registry.R`: clarified that the narrow exception is separate from the fixed-effect registry row.
- `tests/testthat/test-julia-family-cumulative_logit.R`: positive admission and refusal controls.
- `tests/testthat/test-julia-cumulative-logit-sd-slope-parity.R`: synthetic same-data TMB/Julia fit, recovery, and group-SD prediction checks.
- `vignettes/julia-engine.Rmd`, `vignettes/formula-grammar.Rmd`, `docs/design/01-formula-grammar.md`, `docs/dev-log/known-limitations.md`, `NEWS.md`, `docs/dev-log/dashboard/julia-gates.tsv`, `docs/dev-log/general-sd-regression/inventory.md`, and `.unlazy/general-sd-regression/GATES.md`: synchronized scope and evidence wording.
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv` and `evidence/julia-cumulative-logit-sd-bridge-20261024/`: source-bound receipt, manifests, and run logs.

## 5. Checks Run
- R-side focused tests: 95 expectations passed, with two opt-in engine tests skipped in that light run.
- Live same-data bridge test: 16 expectations passed in 59.7 seconds; no warnings or failures. Both fits converged, the SD slope had the correct direction and fell within the test's point-recovery tolerance, and predicted group SDs increased across the three group-level predictor values. Full output: `docs/dev-log/general-sd-regression/evidence/julia-cumulative-logit-sd-bridge-20261024/test-run-isolated.log`.
- `pkgdown::check_pkgdown()`: no problems found. Pandoc printed its existing `--mathml` deprecation warnings.
- R source parsing passed for the bridge, family registry, and both touched test files.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: `candidate_rows=19118`, `linked_rows=43`, `unlinked_rows=19075`, `evidence_records=53`.
- `git diff --check` passed for the scoped tracked paths. The new test file also passed the final whitespace scan.
- The changed Julia gate TSV parses as 16 rows with 13 columns. The broader `python3 tools/validate-mission-control.py` audit remains red in this candidate tree on registry/artifact count differences and unrelated stale evidence or README checks; the gate registry reports 15 rows where the validator expects 16. This task does not change registry row counts.
- The `graft` executable is not available on `PATH`, so I could not refresh the repository context graph after the bridge edit.
- The Julia path required an absolute checkout path and `~/.juliaup/bin` on `PATH`. A temporary compiled-library copy failed once during an evidence-capture retry; rerunning with an isolated `TMPDIR` passed.

## 6. Tests of the Tests
Before the bridge exception was added, the new fit test failed at the expected fixed-effect-only family guard. The focused route test now accepts the matching numeric slope and rejects a random intercept, a mismatched SD coefficient, and a non-numeric slope. The live fixture also checks recovery direction and tolerance, likelihood finiteness, and group-level prediction ordering. No interval coverage or uncertainty-calibration property is asserted.

## 7a. Issue Ledger
Read-only search found no open issue for this exact cumulative-logit SD bridge cell. The nearby open issues returned by the search concern Poisson/Gamma bridge admission and an older test sweep, so the tracker was left unchanged.

## 8. Consistency Audit
The Julia-engine table now describes this route as a bridge-specific exception. The formula guide, design grammar, known-limitations file, NEWS, dashboard gate, candidate inventory, and active goal ledger state the same boundary. A targeted stale-wording scan found no remaining cumulative-logit claim that Julia parity is wholly absent. The broader required-row denominator remains unchanged and mostly unlinked.

Exact status-inventory patterns checked: `rg -n -i 'cumulative_logit|cumulative-logit' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml`; `rg -n "full.*rejected|block.*rejected|only diagonal|planned.*implemented" README.md docs/dev-log/internal-roadmap.md NEWS.md docs docs/design vignettes`.

## 9. What Did Not Go Smoothly
The scoped lease command remained stuck even when the registry lock was absent, so I stopped only my own attempts. The focused live run first exposed the fixed-effect-only guard, then the test fixture's repeated-group prediction rows, and finally an R temporary-library collision. Each issue was isolated and corrected; the final live run passed. No foreign edits were reverted.

## 10. Known Residuals
This is one complete-response synthetic design and one fitted numeric location slope through the R bridge. It does not establish random-intercept bridge support, correlated or labelled blocks, structured providers, missing-data routes, cross-family parity, calibrated intervals, or programme-wide completion. Interval-coverage validation remains deferred as approved.

## 11. Team Learning
Keep the fixed-effect registry fence intact and add a narrowly checked family exception only when the complete formula shape is explicit. For predictor-dependent SD predictions, each requested row must represent a distinct group when the SD predictor changes.

## 12. Cross-Product Coverage
The paired DRM.jl checkout already had direct cumulative-logit random-slope SD support and its own synthetic test. This task changed no Julia source. The live bridge test exercised that existing implementation through `engine = "julia"` and compared it with native TMB. Julia direct-call API behavior beyond this fixture remains outside the receipt.

This slice covers the R bridge and native TMB comparison for one complete-response cumulative-logit numeric location slope with its matching SD formula. It does NOT cover random intercepts, other families or endpoints, structured providers, correlated blocks, missing-data routes, REML, or interval calibration.

## 13. Next Actions
Continue with the next unverified required capability row after a fresh ownership check. Keep the exact cumulative-logit route in the evidence ledger as unreviewed point-fit evidence; do not promote the family row or close a programme gate from this receipt alone.
