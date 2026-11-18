# After Task: Julia Binomial phylogenetic plus IID SD bridge

## 1. Goal

Admit and exercise the mixed Julia Binomial route with a phylogenetic random intercept, an independent IID random intercept, and a predictor-dependent SD formula for each component.

## 2. Implemented

The R bridge now admits this exact mixed route for probit and cloglog, sends coefficient labels under the canonical Julia `sd` and `sd_phylo` blocks, and resolves the ordinary target to its fitted block. Julia marginal simulation now includes the IID component alongside the phylogenetic component.

## 3a. Decisions and Rejected Alternatives

Kept the route narrow: one phylogenetic intercept plus one ordinary IID intercept, with matching unselected SD targets. The bridge uses the fitted engine's canonical block names rather than descriptor hashes. The test uses a unit-height tree so native and Julia covariance scales match for this fixture. No kernel normalization change or uncertainty-coverage claim was made.

## 4. Files Touched

- `R/julia-bridge.R` (scoped bridge admission, label mapping, fitted-block resolution)
- `R/julia-simulate.R` (mixed phylogenetic plus IID marginal draw)
- `tests/testthat/test-julia-binomial-phylo-iid-sd-bridge.R`
- `docs/dev-log/check-log.d/2026-10-29-julia-binomial-phylo-iid-sd-bridge.md`
- This report.

## 5. Checks Run

- Pure R focused test: passed 12 expectations; the live test skipped without `DRM_JL_PATH`.
- Live R-to-Julia focused test, Julia 1.10.0 and DRM.jl worktree `../general-sd-julia`: passed. Both probit and cloglog routes fit on TMB and Julia, checked convergence, SD-slope direction and engine differences, predicted target SDs, compared log likelihoods, and generated marginal simulations.
- Adjacent live animal-plus-IID Binomial probit/cloglog bridge test: passed (one Julia bridge test, all assertions). This confirms the SD-block resolver change did not disturb the neighboring structured provider.
- The focused Julia receipt is linked to the exact frozen probit and cloglog candidate rows in `direct-sd-evidence.tsv`; `reconcile_evidence.py` passed with 20,350 candidate rows, 224 evidence records, 201 distinct linked rows, and 20,149 unlinked rows. This is evidence linking only; no row was promoted.
- `git diff --check -- R/julia-bridge.R`: passed; a full-worktree diff check still reports a pre-existing trailing blank line in `tests/testthat/test-binomial-sd-integration.R`, which is outside this slice and was left untouched.
- `graft ask` could not run because the `graft` executable is unavailable in this environment. `route.py` found no LOAD-FIRST manifest for the managed worktree. I inspected the exact bridge, simulator and test spans directly.
- No full package check, documentation build, or coverage calibration was run. No public help page or formula grammar changed.

## 6. Tests of the Tests

The initial live test failed at Julia's coefficient-label echo because R supplied descriptor-hashed keys while the fitted model exposed `sd` and `sd_phylo`. After correcting labels, output extraction exposed the same stale hashed-key assumption for the ordinary target; that lookup is now mapped to `sd`. The completed live test also checks negative admission cases for missing or mismatched SD targets and a random-slope formula.

## 7a. Issue Ledger

No issue was changed during this bounded bridge slice. The source-level work and receipt remain in the candidate worktree; issue tracking should be reconciled during the programme's next integration checkpoint.

## 8. Consistency Audit

The symbolic model remains `log(tau_g) = W_g alpha` for each latent intercept, with the phylogenetic component using the supplied tree covariance and the IID component using an independent Gaussian effect. The fixture uses independent synthetic data and identical unit-height tree scaling across engines. The mixed-route simulator now requires and uses both SD targets. No user documentation or support table was changed, so README, NEWS, roadmap, formula grammar and pkgdown navigation were not edited.

## 9. What Did Not Go Smoothly

The first live fit uncovered a bridge marshalling mismatch that pure admission tests could not detect. Subsequent runs found two testthat-version incompatibilities in assertion arguments. Each was corrected and the full live fixture then passed.

## 10. Known Residuals

This is one Julia bridge combination: Binomial probit/cloglog, one phylogenetic random intercept plus one IID random intercept, with matching predictor-dependent SD formulas. It does not establish support for other links, random slopes, correlated blocks, other structured providers, other families, broad parity, calibrated uncertainty, or interval coverage. The broader SD-regression programme remains in progress.

## 11. Team Learning

Bridge admission tests need a live marshalling check whenever a model has multiple SD targets: the target descriptors, Julia's canonical coefficient blocks, and R's output extractor must all agree. The first live failure exposed that missing layer.

Memory receipt: used the general-SD memory entry to preserve the narrow candidate-evidence boundary and structured-kernel scaling semantics. Golden Set: NOT RUN; this slice did not touch a registered repeated-mistake class. The user owns the programme and has authorized this SD lane to continue; the separate DRM.jl parity lane was not edited.

## 12. Cross-Product Coverage

The live test compares native TMB and Julia on synthetic Binomial probit and cloglog examples and exercises Julia marginal simulation. It is point-fit and output evidence for this exact route. It does NOT cover other links, providers, response families, random-effect shapes, general parity, calibrated uncertainty, or interval coverage. Coverage validation remains deferred by user decision.
