## 1. Goal

Extend the development R-to-Julia bridge for predictor-dependent random-effect
SDs to the existing complete-response hurdle NB2 route, for one ordinary
location intercept and one independent numeric location slope.

## 2. Implemented

The bridge admits exactly one matched ordinary `mu` random-effect SD formula
for an intercept or selected numeric slope. Both routes require fixed-effect
`sigma` and fixed-effect `hu`. The paired Julia hurdle fitter delegates the
`hu` model to the existing NB2 random-effect SD implementation. Formula
selectors are translated to Julia's canonical `sd` coefficient label.

The same-data synthetic bridge test passed 36 expectations: 8 pure gate and
target-label checks, plus 28 live assertions across two TMB and two Julia
fits. It checks convergence and positive SD-trend recovery in each engine, and
checks that each engine returns positive group-level SD output. The test's
loose coefficient comparison and output checks do not establish numerical
parity of group-level SD predictions. This is narrow point-recovery evidence.

## 3. Mathematical Contract

For a selected random coefficient, the model uses
`log(tau_g) = W_g alpha`; the selected coefficient contributes to the hurdle
NB2 positive-count component. The hurdle-zero probability `hu` remains a
separate fixed-effect predictor, and NB2 overdispersion `sigma` remains
fixed-effect. The SD design must be full rank among groups with at least one
positive count. All-zero groups inform `hu`, but not the count-side SD
regression. The bridge does not introduce a Bernoulli residual scale,
change the existing truncation normalizer, or change covariance scaling.

## 3a. Decisions and Rejected Alternatives

The Julia route calls the existing NB2 Hurdle SD machinery instead of adding a
second hurdle likelihood implementation. The bridge is intentionally limited
to one ordinary intercept or one independent numeric slope. Structured and
correlated blocks, random `sigma` or `hu`, and incomplete responses remain
outside the admitted route.

## 4. Files Touched

- `R/drmTMB.R` and `R/julia-bridge.R`
- `tests/testthat/test-julia-hurdle-nbinom2-sd-bridge.R`
- `tests/testthat/test-hurdle-nbinom2-sd-identifiability.R`
- `NEWS.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/45-cross-dpar-correlation-gate.md`
- `vignettes/formula-grammar.Rmd`
- `vignettes/distribution-families.Rmd`
- `docs/dev-log/general-sd-regression/inventory.md`
- `vignettes/model-map.Rmd`
- `LOOP/lanes/general-sd-regression/arcs.md` and `LOOP/lanes/general-sd-regression/checkpoint.md`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv` and `direct-sd-evidence-summary.md`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/check-log.md`
- Paired DRM.jl worktree: `src/negbinomial.jl` and `test/test_hurdle_negbinomial_sd_identifiability.jl`
- `docs/dev-log/general-sd-regression/evidence/hurdle-nbinom2-sd-bridge-20261025/higher-information-design/`
- `docs/dev-log/general-sd-regression/evidence/hurdle-nbinom2-sd-bridge-20261025/review-repair/`

## 5. Checks Run

- The native positive-count identifiability test passed after its expected-error text was aligned with the guard message.
- Direct paired Julia tests passed: positive-count identifiability (2/2) and the Hurdle NB2 random-intercept SD regression, including its quadrature oracle (17/17).
- The source-pinned R-to-Julia bridge test was rerun after the guards were added; one live Julia bridge test passed with no failures. The exact run output is in `review-repair/console.rerun.log`.
- The review-repair source manifest covers 152 relevant source and test files and is identical before and after the bridge test.
- `DRMTMB_JULIA_TESTS=true NOT_CRAN=true DRM_JL_PATH='<paired DRM.jl worktree>' DRMODELS_JL_PATH='<paired DRM.jl worktree>' JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "julia-hurdle-nbinom2-sd-bridge", reporter = "summary", stop_on_failure = TRUE)'`: exit 0; 36 expectations passed, including the live bridge test.
- The original before/after manifest covered 150 files. The review-repair manifest covers 152 and adds both identifiability tests; all hashes remained identical during the rerun.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: passed after adding four review-repair receipts; 76 evidence records link to 59 distinct candidate rows, with 19,059 rows still unlinked.
- `rmarkdown::render()` passed for `vignettes/distribution-families.Rmd` and `vignettes/model-map.Rmd`; Pandoc emitted its MathJax deprecation warning.
- `git diff --check` on the edited source and documentation paths: passed.
- Earlier failed-route output showing Julia's `hu` refusal is retained beside the passing output in the evidence directory.

## 6. Tests of the Tests

Pure checks reject a mismatched SD target and an extra random-effect term, and
verify that intercept and selected-slope formulas both map to Julia's single
`sd` label. The high-information fixtures use independent fixed seeds and
compare estimates with known simulated SD coefficients. The test checks
group-level SD output separately for both engines; these outputs are not
compared numerically across engines. The paired Julia random-intercept test
also passes an independent scalar quadrature likelihood check. The slice has
no deliberate broken-index control, repeated-sample uncertainty calibration,
or interval-coverage evidence.

## 7a. Issue Ledger

No issue search was run. No issue was created or changed.

## 8. Consistency Audit

NEWS, the formula-grammar table, the distribution-family guide, model map,
cross-parameter gate, check log, and implementation inventory now distinguish the
native and candidate Julia routes, state their response and fixed-parameter
restrictions, and require a full-rank SD design across positive-count groups.
The evidence ledger links the exact Hurdle NB2 intercept and slope rows for
native and Julia; all four remain unreviewed, and no broad support row is
promoted.

## 9. What Did Not Go Smoothly

The first live bridge run reproduced an explicit Julia refusal when `hu` was
present. Delegating to the existing NB2 Hurdle SD route fixed that incompatibility.
Independent review then found that all-zero groups could make the count-side SD
design non-identifiable despite full rank over the full group set. Both engines
now check rank only across groups with positive counts. The first native guard
test failed because its expected error substring did not match the correct
message; the assertion was fixed, and the test then passed.
A smaller initial synthetic design also gave weak or negative SD-slope
estimates in both engines, so it was not used as recovery evidence. The retained
high-information design passed the expected-direction checks.

## 10. Known Residuals

The result covers complete-response hurdle NB2 with fixed-effect `sigma` and
`hu`, one ordinary intercept or one independent numeric slope, and matching
SD formulas. It does not calibrate confidence intervals. Structured effects,
correlated blocks, random effects in `sigma` or `hu`, missing-response routes,
broader hurdle parity, and numerical cross-engine group-SD prediction parity
remain open. Evidence is unreviewed and does not
close a programme gate.

## 11. Team Learning

For bridge routes with a second distributional predictor, add a test that
reaches the engine before broadening the family fence. The earlier refusal
proved that target-label correctness alone did not establish model admission.
Hash both engine source trees around live cross-engine recovery runs.

## 12. Cross-Product Coverage

This slice covers a narrow paired R/TMB and Julia point-recovery check and
candidate evidence for four exact rows. It does NOT cover interval calibration,
uncertainty validity, structured or correlated hurdle effects, arbitrary
distributional endpoints, or overall predictor-dependent SD parity.

## 13. Next Actions

Continue with the next required capability row from the frozen inventory. Keep
coverage calibration deferred and the overall programme active.

Memory receipt: `route.py` returned no LOAD-FIRST manifest for this worktree.
The repository instructions, current frozen inventory, paired source, and test
output supplied the technical context. The NotebookLM methods review remains
separate from this implementation slice. Golden Set: not run; this repair adds
a targeted rank guard around existing likelihood machinery and does not change
the likelihood or covariance calculation.

Formal prose assessment: Style 2/10, moderate confidence. Genre and coverage:
engineering after-task report, whole 13-section report. The specific test counts
in Section 5 and the explicit limits in Section 10 are concrete and match the
retained outputs; no repair was needed. Gates: scientific claims are limited to
the positive-count rank condition implemented in both builders; factual claims
match the source, test logs, and manifest; references are not applicable because
this report uses local code and test evidence only. Method: self-review against
the source and run receipts, report revision 2026-10-25; no external examples
were used.
