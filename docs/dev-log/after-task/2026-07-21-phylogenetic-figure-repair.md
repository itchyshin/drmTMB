# After-task report: phylogenetic interval-figure repair

## 1. Goal

Repair the broken interval figure in the phylogenetic mixed-model article and
verify that the figure remains legible in the rendered pkgdown page.

## 2. Implemented

The vignette now matches residual and phylogenetic SD intervals by exact
parameter name, draws both intervals with a compact segment-and-point recipe,
and stops rendering if a parameter is missing or an estimate is outside its
paired interval. The deprecated horizontal-errorbar geometry and its visible
warning were removed. Nearby output and interval interpretation were also
corrected.

## 3. Mathematical Contract

The figure reports two distinct response-scale standard deviations from one
Gaussian phylogenetic mixed model: residual `sigma` and the phylogenetic
location-effect SD. The lines are the default 95% Wald intervals returned by
`confint()` after transformation from log SD. A positive lower endpoint is not
a boundary test because the transformation itself is positive.

## 3a. Decisions and Rejected Alternatives

Name-based matching was chosen over swapping positional rows because table
order can change silently. A compact forest plot was retained instead of
adding a decorative tree or covariance heatmap. Warning suppression was
rejected; the deprecated geometry was removed. Raw observations were not
placed on the SD axis.

## 4. Files Touched

- `vignettes/phylogenetic-models.Rmd`
- `docs/dev-log/figure-audits/2026-07-21-phylogenetic-models/`
- `docs/dev-log/check-log.md`
- this report

## 5. Checks Run

- `pkgdown::build_article("phylogenetic-models", new_process = FALSE)`: PASS.
- `devtools::test(filter = "phylo-gaussian", stop_on_failure = TRUE)`: 385
  passes, 0 failures, and 19 expected legacy `sd_phylo*()` deprecation warnings.
- `pkgdown::check_pkgdown()`: PASS with no problems.
- Rendered HTML warning scan: PASS; no deprecated-geometry or translated-
  aesthetic output remains.
- `git diff --check`: PASS.

## 6. Tests of the Tests

The render-time assertions test the failure mode directly: both expected
`confint()` parameter names must match, and every fitted point must lie within
its paired lower and upper endpoints. This would have rejected the previous
misassembled table, where the phylogenetic point lay far outside the residual
interval drawn beside it.

## 7a. Issue Ledger

| Issue | Severity | Resolution |
|---|---|---|
| residual interval drawn on phylogenetic row | P0 | fixed by exact `parm` matching |
| residual interval omitted | P0 | both matched rows are now required |
| deprecated ggplot geometry leaked warnings | P1 | replaced with `geom_segment()` |
| transformed interval described as a zero-variance test | P1 | corrected in visible prose |
| mobile labels too long | P1 | shortened direct labels and enlarged relative type |
| accessor examples flooded or overstated output | P2 | print one constant residual SD and species-tip states only |

## 8. Consistency Audit

The equation, accessor output, confidence-interval table, plot, caption, and alt
text now distinguish residual `sigma` from the phylogenetic location SD. No
formula grammar, likelihood, extractor, estimator, or capability wording was
changed. The figure uses the same `sigma` and phylogenetic-SD terms as the rest
of the article.

## 9. What Did Not Go Smoothly

The first local HTTP server and headless-browser calls were blocked by the
sandbox and had to be rerun with approved local-only permissions. The first
mobile inspection also showed that the scientifically correct plot still used
labels that were too long; a second render shortened them.

## 10. Known Residuals

The display is one illustrative simulated fit, not a recovery or coverage
study. It does not validate Wald coverage or test a variance boundary. The
article deliberately remains a one-figure tutorial.

## 11. Team Learning

Florence and Tufte independently found the same statistical row mismatch.
Figure assembly should use semantic parameter keys rather than row positions,
and the rendered HTML must be checked for warnings as well as the PNG itself.

## 12. Cross-Product Coverage

This repair affects only the drmTMB pkgdown article. No DRM.jl, gllvmTMB,
mission-control, C++, or package API surface requires synchronization.
It does NOT cover REML, likelihood penalties, fitting engines, missing-response
routes, simulation aggregation, coverage calibration, or any other family or
provider.

## 13. Handoff

After merge, allow the pkgdown workflow to deploy, then verify the live article
contains two correctly paired intervals and no warning block above the figure.
