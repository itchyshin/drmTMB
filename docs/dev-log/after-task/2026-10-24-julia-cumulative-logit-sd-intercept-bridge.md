# After Task: Cumulative-Logit Julia Bridge SD Intercept

## 1. Goal

Allow one complete-response cumulative-logit model with an ordinary location random intercept and a matching predictor-dependent SD formula through the R-to-Julia bridge, and check it against native R/TMB on independent synthetic data.

## 2. Implemented

The bridge now admits the exact ordinary-intercept shape when `sd(group)` targets the fitted group. Other cumulative-logit random-effect shapes remain behind the existing refusal. The family registry comment and the Julia guide, formula guide, model map, NEWS, capability inventory, and acceptance ledger distinguish this exception from the family-level fixed-effect registry entry.

## 3a. Decisions and Rejected Alternatives

The bridge exception is limited to one ordinary location intercept whose SD formula names the same group. It does not open the cumulative-logit route for bare random effects, correlated blocks, or structured effects. This preserves the existing fail-closed bridge boundary while admitting the matched SD model.

## 3b. Mathematical Contract

For group `g`, the random intercept is Gaussian with link-scale standard deviation `exp(-1 + 0.5 w_g)` in the synthetic fixture. The formula `bf(score ~ x + (1 | id), sd(id) ~ w)` therefore models the log SD of the cumulative-logit location intercept. This adds no Bernoulli-style residual scale parameter. Julia adaptive quadrature and native TMB Laplace are compared as fitted models, without asserting identical approximation error.

## 4. Files Touched

- `R/julia-bridge.R`
- `R/julia-family-registry.R`
- `tests/testthat/test-julia-cumulative-logit-sd-intercept-parity.R`
- `tests/testthat/test-julia-family-cumulative_logit.R`
- `NEWS.md`
- `vignettes/julia-engine.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/model-map.Rmd`
- `docs/dev-log/general-sd-regression/inventory.md`
- `.unlazy/general-sd-regression/GATES.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/evidence/julia-cumulative-logit-sd-intercept-bridge-20261024/`
- The earlier slope receipt's source snapshots, manifest, and receipt were refreshed to preserve its original tested source after shared registry/test edits.

## 5. Checks Run

- The new test first failed at the cumulative-logit fixed-effect-only bridge fence. After the exact-shape admission was added, its focused filter passed 20 expectations, including 16 live same-data R/TMB and Julia expectations, in 65.87 seconds with exit status 0.
- Both fits converged and had finite log likelihoods. The fitted SD-predictor slopes had the generating positive direction and were within the declared point tolerances. Group SD predictions increased over `w = -1, 0, 1` and agreed within the test tolerance.
- Four route checks admit the matching group and refuse a mismatched SD target.
- R parsing, `pkgdown::check_pkgdown()`, scoped `git diff --check`, and `python3 tools/general-sd-regression/reconcile_evidence.py` passed. The reconciler reported 54 receipt records linked to 43 of 19,118 candidate rows. These counts are evidence links, not completion percentages.
- The exact console log, source manifest, and receipt are under `docs/dev-log/general-sd-regression/evidence/julia-cumulative-logit-sd-intercept-bridge-20261024/`.

## 6. Tests of the Tests

The focused route failed before the adapter change at the intended FE-only rejection. The passing test includes a negative control for an SD formula naming a different group. The synthetic fixture is independent of collaborator data and uses seed `202610206`.

## 7a. Issue Ledger

- No matching open issue was found for this exact bridge SD-intercept slice.
- No issue was edited, opened, or closed. Broad tracker issues were left unchanged.

## 8. Consistency Audit

The bridge admission, formula target, family-registry note, documentation, and receipt all describe one ordinary `mu` intercept with a matching `sd()` formula. The cumulative-logit slope bridge remains a separately tested capability. No TMB likelihood or Julia likelihood parameterization changed. The open-issue searches found no matching open issue dedicated to this SD-intercept bridge slice; broad cumulative-logit and random-effect issues were left untouched.

Exact searches were `repo:itchyshin/drmTMB \"cumulative_logit\" \"sd(\"` and `repo:itchyshin/drmTMB \"cumulative-logit\" \"random-effect\"`. The status inventory search covered `README.md`, `docs/dev-log/internal-roadmap.md`, `NEWS.md`, `docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`, `vignettes/formula-grammar.Rmd`, `vignettes/julia-engine.Rmd`, `vignettes/model-map.Rmd`, `R/julia-family-registry.R`, `R/julia-bridge.R`, and `_pkgdown.yml` with `rg -n -i "cumulative[_ -]logit|cumulative-logit"`.

## 9. What Did Not Go Smoothly

The repository check log already named this report before the report file existed. This audit found and repaired that dangling link. The test runner also printed a generic footer saying zero live Julia tests ran, although its captured output shows Julia starting, completing the fit, and exiting successfully; the receipt records the live expectations directly.

## 10. Known Residuals

This does NOT establish support for other cumulative-logit random-effect shapes, structured or correlated effects, missing-response routes, or other families. It checks one synthetic design and fixed seed. Profile/bootstrap workflows and interval coverage were not checked here; coverage calibration remains deferred. No broad Julia parity or programme gate is closed.

## 11. Team Learning

Before closing a slice, check both directions of report references: a check-log entry can exist while its report file is absent. Memory receipt: route.py returned the LOAD-FIRST manifest, and the relevant random-effect SD hierarchy note was used for the fixed-predictor target contract. Golden Set: not in scope for this one-cell bridge slice.

## 12. Cross-Product Coverage

**Covers:** Native R/TMB and the R-to-Julia bridge for one complete-response cumulative-logit ordinary location random intercept with a matched fixed-predictor SD formula; point recovery, group-SD prediction, route admission, and mismatched-target refusal.

**Does NOT cover:** Other cumulative-logit random-effect shapes, structured or correlated effects, missing-response routes, other families, profile/bootstrap refits, or interval-coverage calibration. Coverage remains deferred, and this slice closes no programme gate.
