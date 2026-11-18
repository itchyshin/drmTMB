# After Task: Bernoulli probit correlated q3 SD bridge

## 1. Goal

Fit and simulate a Bernoulli probit model with an ordinary correlated random intercept plus two slopes, each with its own predictor-dependent SD, through the R-to-Julia bridge. Keep this as a bounded milestone within the broader family and effect programme.

## 2. Implemented

The R bridge admits one unlabelled ordinary q3 block with a selected SD formula for each coefficient. It marshals those formulas as positional parts so DRM.jl parses each SD marker rather than treating selector-bearing keys as Julia function definitions. The bridge maps Julia's three partial correlations to the public pairwise correlation names used by native TMB.

The Julia marginal simulator now draws a correlated coefficient vector for each group and scales each coefficient by its own predicted SD. The reference documentation, formula-grammar vignette, NEWS, and Julia Binomial inventory row describe the q3 probit slice and its warning.

## 3a. Decisions and Rejected Alternatives

- The live test points at the paired general-SD Julia candidate. The unrelated main DRM.jl checkout rejects coefficient selectors in `sd()` and was left untouched.
- The implementation keeps the existing log-SD formulas, random-effect correlation, and kernel conventions. It adds no correlation regression.
- Coverage validation remains deferred under the user's earlier direction.
- Assumption: this milestone is limited to one ordinary iid q3 block with an intercept and two numeric slopes. Other coefficient layouts require separate admission and evidence.

## 4. Files Touched

- `R/julia-bridge.R`
- `R/julia-simulate.R`
- `tests/testthat/test-julia-binomial-correlated-q3-sd-bridge.R`
- `NEWS.md`
- `docs/dev-log/general-sd-regression/inventory.md`
- `vignettes/formula-grammar.Rmd`
- `man/simulate.drmTMB.Rd`
- `docs/dev-log/check-log.d/2026-10-26-julia-binomial-correlated-q3-sd-bridge.md`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-correlated-q3-sd-bridge-20261026/receipt.md`

## 5. Checks Run

- The fit-free q3 bridge and sampler test passed. Its 20,000-draw simulation recovered the requested coefficient correlation matrix within 0.02.
- The q2 fit-free bridge test passed. Its opt-in live tests were skipped in that run; a separate follow-up below passed both q2 probit and cloglog live bridge cases.
- The opt-in q3 live test passed one end-to-end block with 14 live expectations against the paired Julia candidate. The same-data TMB and Julia fits passed coefficient, correlation, and group-SD prediction checks; the Julia marginal simulator returned binary responses.
- `devtools::document()` generated the simulation reference.
- `pkgdown::check_pkgdown()` found no problems and printed deprecated MathML warnings.
- `rmarkdown::render("vignettes/formula-grammar.Rmd", output_file="/tmp/drmtmb-formula-grammar-q3.html", quiet=TRUE)` completed with a deprecated MathJax warning.
- The full site render to `/tmp/drmtmb-q3-sd-pkgdown` exceeded its four-minute estimate and was stopped while rendering pages. It is partial.
- Scoped `git diff --check` passed on the implementation, test, NEWS, inventory, and generated Rd paths. An unscoped check also reported a pre-existing trailing blank line in `tests/testthat/test-binomial-sd-integration.R`, outside this slice.

## 6. Tests of the Tests

Before the serializer change, a live run failed while parsing selector-bearing SD keys. A run pointed at the wrong DRM.jl checkout then reached `bf()` and failed because that checkout lacks selector-aware SD markers. Against the paired Julia candidate, the live test passed the fit and output checks; its first simulation attempt exposed that the R simulator only admitted independent intercepts. The new pure sampler test checks the resulting coefficient dependence directly, and the final live run passed the same test end to end. An incomplete q3 SD specification remains a negative admission test.

## 7a. Issue Ledger

The targeted open-issue search found no matching issue. No issue was opened, commented on, or closed.

## 8. Consistency Audit

The formula still has three fixed-predictor SD formulas on the location scale. The Bernoulli model has no free residual `sigma`. NEWS and the Julia capability inventory now name the probit q3 case and the Hessian caveat. The formula-grammar vignette no longer says all non-logit correlated blocks are unavailable; it limits the new statement to probit q3 and leaves cloglog blocks and other layouts open. The API reference was regenerated from roxygen. The package README continues to describe Julia work as a development candidate.

Search used: `rg -n 'Bernoulli.*sd|correlated q3|q = 3|q=3|correlated.*block' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml`.

## 9. What Did Not Go Smoothly

The first live run used the unrelated DRM.jl main checkout. It exposed two distinct issues: selector-specific formula keys failed before model assembly, and that checkout does not implement the selector-aware SD markers already present in the paired candidate. After switching to the paired candidate and fixing formula transport, the first simulation attempt exposed the independent-intercept-only R simulator gate. The full site render also exceeded its initial estimate and was stopped.

## 10. Known Residuals

The live q3 fit emitted a numerically singular Hessian warning for coordinate 12. Its Wald SE is not trustworthy. This fixture tests cross-engine point and output agreement, not recovery against known truth. No profile or bootstrap interval was tested, and no coverage validation was run. Live evidence covers one probit q3 ordinary block on the local paired Julia candidate, not released DRM.jl, cloglog q3, other block sizes, structured effects, other families, or the full pkgdown site.

## 11. Team Learning

Set `DRM_JL_PATH` to the exact paired candidate before any live R-to-Julia check. A successful direct Julia test does not prove that the R formula serializer or simulation wrapper can carry the same target. Keep serializer, fit, output, and simulation checks in the same small fixture when a route crosses all four layers.

## 12. Cross-Product Coverage

For Bernoulli probit, the ordinary iid q3 intercept-plus-two-slope block now has live fitting, coefficient/correlation output, group-SD prediction, and marginal simulation checks on TMB and the paired Julia candidate. The test does NOT cover calibrated uncertainty, profile or bootstrap intervals, coverage, cloglog q3, other block sizes, structured or crossed effects, or any non-Bernoulli family. The overall programme remains open.

## Next Actions

Continue with the next unimplemented Bernoulli random-effect type in the capability inventory, then broaden to the next response family after reviewing its engine-specific prerequisites.
