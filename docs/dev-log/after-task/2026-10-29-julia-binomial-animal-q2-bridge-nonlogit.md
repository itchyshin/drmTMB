# After Task: Julia Binomial Animal q2 SD Bridge Across Links

## 1. Goal

Add a bounded Julia bridge slice for a Binomial animal intercept-plus-slope block with separate predictor-dependent SDs, extending the existing logit route to probit and complementary log-log and retaining honest limits.

## 2. Implemented

The native TMB and development Julia routes fit one supplied-`A` animal block with an intercept and one numeric slope. Each coefficient has its own fixed-effect SD formula, and their correlation remains constant across groups. The R bridge now admits the exact q2 route for all three links, returns public SD target names, and marginally simulates the fitted structured effects. The supported link-specific checks compare the bridge fit with native TMB.

## Mathematical Contract

For group `g`, the two animal effects have covariance `D_g R D_g`, where `D_g` contains the fitted intercept and slope SDs from their separate formulas and `R` is the fitted constant 2 by 2 correlation matrix. The supplied `A` remains the animal covariance kernel. The slope is multiplied by its observation-level covariate. No Bernoulli residual `sigma` is added.

## 3a. Decisions and Rejected Alternatives

Keep the admission exact: one supplied-`A` animal intercept-plus-slope block, with one selected SD formula per coefficient and no extra random-effect terms. The direct Julia fitter supports additional variants, but this bridge receipt covers `A` only; it does not justify claiming `Ainv` or pedigree parity. Keep interval coverage deferred and report point/output checks only.

## 4. Files Touched

- `R/julia-bridge.R`: exact q2 admission for probit and cloglog and public target naming.
- `R/julia-simulate.R`: marginal animal q2 simulation and documentation.
- `tests/testthat/test-julia-binomial-animal-q2-sd.R`: admission negatives, logit workflow and simulation oracle, plus probit/cloglog cross-engine recovery.
- Paired Julia candidate: `src/binomial_sd_regression.jl` and `test/test_binomial_animal_q2_sd.jl` add and test the non-logit q2 route.
- User and developer documentation: `README.md`, `NEWS.md`, `docs/dev-log/internal-roadmap.md`, `docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`, `vignettes/formula-grammar.Rmd`, and `man/simulate.drmTMB.Rd`.
- Focused logs: `docs/dev-log/evidence/general-sd-regression/julia-binomial-animal-q2-bridge-20261029/`.
  `source-manifest.sha256` records the paired code, tests, docs, and retained log hashes.

## 5. Checks Run

- Direct Julia tests passed: existing logit animal q2, 33/33; new probit/cloglog animal q2, 20/20. The retained output is in `julia-direct.log`.
- `devtools::test(filter = "julia-binomial-animal-q2-sd", reporter = "summary", stop_on_failure = TRUE)` passed with two live Julia bridge tests. The retained earlier output is `r-bridge-live.log`; a fresh run against the same code also completed with `DONE` and `Julia bridge: 2 live tests ran`.
- `tools::checkRd("man/simulate.drmTMB.Rd")` exited 0.
- Rendering `vignettes/formula-grammar.Rmd` to a temporary HTML file exited 0; Pandoc emitted its existing `--mathjax` deprecation warning.
- `pkgdown::check_pkgdown()` reported no problems; Pandoc emitted existing `--mathml` deprecation warnings.
- Scoped `git diff --check` passed.
- `Rscript ~/shinichi-brain/tools/check-after-task.R <report>` passed the required section check. It warned that 13 acceptance-ledger files are not runnable because the configured Node/gate-check is missing; ledger state is UNKNOWN, not satisfied.
- The capability inventory search covered README, roadmap, NEWS, known limitations, formula grammar design, formula vignette, and pkgdown navigation. It showed no navigation change was needed.

## 6. Tests of the Tests

The route-admission test rejects a missing coefficient target, a mismatched group, and an extra unpaired IID effect. The logit simulation test compares seeded output with an independently assembled correlated structured draw. The non-logit test exercises the previously refusing admission branch, then checks fitted coefficients, likelihood, named SD predictions, and binary marginal simulation against the native fit. Focused direct Julia tests independently exercise the non-logit fitter.

## 8. Consistency Audit

The public description now distinguishes this supplied-`A` animal q2 slice from q1 animal intercept and slope-only routes. It limits the link claim to logit, probit, and cloglog, records that only the logit fixture checks save/reload, and leaves interval calibration and broader structured-effect parity open. No formula grammar or likelihood parameterization was changed. The existing formula grammar syntax and selector documentation already cover the required `sd(..., coef = ...)` targets. No pkgdown navigation change was needed.

## 7a. Issue Ledger

`gh issue list --state open --search 'Binomial animal q2 SD' --limit 10` returned only broad test-sweep and Phase 18 issues, with no issue specific to this route. The broad Phase 18 tracking issue was left unchanged.

## 9. What Did Not Go Smoothly

An early recovery fixture tied group predictors to matrix ordering, making SD effects partially confounded with the relationship kernel. The final fixture randomizes the group-level SD predictors independently. A separate early cloglog stress fixture exposed a finite-difference mode-solver failure under a negative SD-slope perturbation; the bounded ordinary-condition fixture now passes, and that stress case is not represented as solved.

## 11. Team Learning

For structured SD bridge work, verify group predictor assignment independently of kernel ordering and test public target labels through prediction and simulation. A successful fit alone does not verify that the simulator uses the same coefficient-to-SD mapping.

## 10. Known Residuals

This is one complete-data Binomial animal q2 route using supplied `A`, one intercept, one numeric slope, and a group-constant predictor for each SD. It does not establish `Ainv` or pedigree bridge parity, mixed animal-plus-IID parity, additional slopes, other structured providers, interval calibration, or broad Julia parity. The separate stress optimizer failure remains open.

## 12. Cross-Product Coverage

This slice covers R-to-Julia formula admission, fitted coefficient and likelihood outputs, named SD prediction, marginal simulation, and logit save/reload for the exact supplied-`A` animal q2 route. It does NOT cover `Ainv` or pedigree bridge inputs, mixed animal-plus-IID terms, additional animal slopes, other structured providers, profile or bootstrap interval calibration, every supported response family, or package release readiness.

## 13. Next Actions

Continue the Bernoulli capability map with the next unverified animal provider/input combination. Keep coverage calibration deferred and update the capability ledger only when its exact source-bound checks are linked.
