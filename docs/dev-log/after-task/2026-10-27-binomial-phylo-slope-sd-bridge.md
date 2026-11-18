# After Task: Binomial phylogenetic slope-only SD bridge

## 1. Goal

Allow the R-to-Julia bridge to fit a Binomial phylogenetic random slope with a
predictor-dependent SD, using `phylo(0 + x | species)` and
`sd(species, level = "phylogenetic") ~ z`.

## 2. Implemented

The R bridge admits this exact slope-only Binomial shape and retains its
phylogenetic SD target in formula serialization. DRM.jl label reconstruction
now enables its existing slope-only parser under the same Binomial
phylogenetic-SD gate already used by fitting and prediction.

## 3a. Decisions and Rejected Alternatives

The coefficient is a random slope on the model's link scale. For tip `g`, its
latent slope has SD `exp(W_g alpha)` and the supplied phylogenetic covariance
continues to define the field scaling. This slice does not change that
covariance or add a Bernoulli residual scale. A weak fixture was not kept with
looser coefficient tolerances: its estimates were near a boundary and the
Hessian was singular, so the synthetic design was strengthened instead.

## 4. Files Touched

- `R/julia-bridge.R`
- `tests/testthat/test-julia-binomial-phylo-sd.R`
- `tests/testthat/test-julia-binomial-phylo-slope-sd.R`
- Paired DRM.jl worktree: `src/bridge.jl`
- `docs/dev-log/check-log.md`

All source trees were already dirty. Changes were kept to the stated route,
label reconstruction and tests; unrelated diffs remain untouched.

## 5. Checks Run

- `Rscript --vanilla -e 'devtools::test(filter = "julia-binomial-phylo-sd", stop_on_failure = TRUE)'` passed 40 expectations; three live-engine blocks were skipped because Julia was not enabled.
- `JULIA_HOME=/Users/z3437171/.juliaup/bin DRMTMB_JULIA_TESTS=true DRM_JL_PATH="$PWD/../general-sd-julia" Rscript --vanilla -e 'devtools::test(filter = "julia-binomial-phylo-slope-sd", stop_on_failure = TRUE)'` passed 18/18 in 45.8 seconds on Julia 1.10.0 for logit, probit, and cloglog.
- `git diff --check` passed for all touched paths.

The live fixture checks convergence, matching SD coefficients and log
likelihood, and predicted tip SDs. It is point-recovery evidence only.

## 6. Tests of the Tests

The live test first failed at the bridge label-fidelity guard, showing that the
R route gate alone did not exercise the full bridge. A weak fixture produced
nearly boundary SDs, divergent coefficients and a singular-Hessian warning. A
48-tip fixture established cross-engine agreement but did not recover the
probit/cloglog SD slope within the predeclared broad tolerance. The final test
uses a balanced 80-tip, 40-observation-per-tip fixture and passed all 18
assertions across the three links.

## 7a. Issue Ledger

No issue was changed in this bounded implementation slice. The parent
programme and overlapping issues remain open for integration review.

## 8. Consistency Audit

The formula-spec test checks both the serialized random-slope term and the
matching SD formula. The parser permission is limited to Binomial fits with a
phylogenetic SD target. No covariance scaling or other family route changed.
The broader status inventory and site search remain for the integration pass.

## 9. What Did Not Go Smoothly

JuliaCall initialization made the first broad test run exceed its estimate. I
stopped it at 111.5 seconds while an unrelated probit profile test was still
running. A smaller live fixture then exposed weak SD identification. Neither
run is counted as a passing receipt; both are recorded in the check log.

## 10. Known Residuals

The live-fit evidence covers logit, probit, and cloglog only for this
phylogenetic slope-only Binomial route. Interval coverage remains deferred, as
agreed. The user-facing family guide and capability inventory still need a
coordinated update.

## 11. Team Learning

For cross-engine bridge work, add an opt-in live test of the exact newly
admitted formula. Formula marshalling can pass while fitted-column label
reconstruction still rejects the same structure.

## 12. Cross-Product Coverage

This slice covers the drmTMB-to-DRM.jl bridge for one Binomial phylogenetic
slope-only SD route across logit, probit, and cloglog links. It does NOT cover
other distribution families, other random-effect structures, interval
coverage, package-wide parity, or the remaining public documentation inventory. Next,
coordinate the guide/status update and continue the Bernoulli route inventory.
