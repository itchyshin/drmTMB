# After Task: Binomial Phylogenetic-Interaction SD Julia Bridge

## Goal

Fit one Binomial location intercept with a predictor-dependent SD on an existing two-tree phylogenetic-interaction effect through the R-to-Julia bridge.

## Implemented

The bridge now maps the observed pair covariance to a related-matrix `K` route and retains the public `sd_phylo(pair_id)` target. The admitted shape is one complete-response q1 intercept with one-to-one pair IDs and pair-constant SD predictors. Same-data comparisons passed for logit, probit, and cloglog. Group SD prediction and seeded marginal simulation also passed.

## Mathematical Contract

For observed pair levels (i=(h_i,p_i)), the bridge supplies `K[i,j] = C1[h_i,h_j] * C2[p_i,p_j]`, using the existing normalized tip covariances from each tree. The fitted pair SD multiplies this covariance through the existing related-matrix SD parameterization. The bridge does not expand the observed pair set to the full Cartesian product and does not change the native covariance convention.

## Files Changed

- `R/julia-bridge.R`: admission, pair covariance marshalling, coefficient-target mapping, and SD prediction support.
- `R/julia-simulate.R`: marginal simulation from the retained pair-level `K`.
- `tests/testthat/test-julia-binomial-phylo-interaction-sd-bridge.R`: malformed-route, payload, three-link fit, pair-prediction, and seeded simulation checks.
- `NEWS.md` and `docs/dev-log/known-limitations.md`: current support boundary.
- `vignettes/formula-grammar.Rmd`: Bernoulli interaction bridge status.
- `docs/dev-log/check-log.md` and the general SD-regression lane checkpoint.
- `LOOP/lanes/general-sd-regression/arcs.md` and `checkpoint.md`: programme status.
- `docs/dev-log/check-log.md`: exact verification receipt.

## Checks Run

- Fit-free command: `Rscript -e 'devtools::test(filter="julia-binomial-phylo-interaction-sd-bridge", reporter="summary", stop_on_failure=TRUE)'` passed; the live test was skipped because the Julia environment was not supplied to that invocation.
- Live command: `PATH="$HOME/.juliaup/bin:$PATH" DRM_JL_PATH="$PWD/../general-sd-julia" OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 Rscript -e 'devtools::test(filter="julia-binomial-phylo-interaction-sd-bridge", reporter="summary", stop_on_failure=TRUE)'` passed with one live test block for logit, probit, and cloglog. It checks convergence, SD coefficients, log likelihood, pair-specific SD predictions aligned to product-tree order, and repeatable marginal simulation.
- `git diff --check` on the implementation and test files passed.
- `pkgdown::check_pkgdown()` passed with existing Pandoc `--mathml` deprecation warnings. Two `pkgdown::build_site()` attempts were stopped after exceeding estimates: the first after 2.5 minutes, the retry after 5 minutes while reading `man/make_mesh.Rd`. No full site-build result is claimed.
- One native TMB fit emitted an `NA/NaN function evaluation` warning during the live test; both engines converged and all assertions passed. The warning remains recorded as a limitation.

## Tests Of The Tests

The new test first failed on missing tree bindings and a missing Julia `sd` coefficient label. The live fit then exposed prediction-order and structured-term stripping gaps; the test failed at each boundary before the corresponding fix. It also rejects a split pair ID and an extra IID random effect. The final run exercised all three supported Binomial links.

## Consistency Audit

The R formula and Julia conversion retain the pair-level SD target. Prediction outputs are matched by pair identity; TMB's product-tree order is host-fastest, while Julia outputs first-observed groups. The status search was `rg -n "phylo_interaction|phylogenetic_interaction|Julia.*Binomial|Binomial.*structured" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml vignettes/bipartite-phylogenetic-interactions.Rmd`. Existing formula grammar already describes the native target; the R-to-Julia bridge scope is stated in NEWS, known limitations, and the formula-grammar vignette. No equation or user formula syntax changed.

## GitHub Issue Maintenance

`gh issue list --state open --search 'phylo_interaction Binomial SD Julia' --limit 10` returned no matching open issues. No issue was opened or changed.

## What Did Not Go Smoothly

The first live fit found that the structured payload still advertised a `resd` label although the Binomial related-matrix fitter reports `sd`. The follow-up exposed two output-path omissions: the fixed-effect design builder retained the interaction marker, and prediction vectors use different group orderings across engines. These were corrected and checked by pair label.

## Team Learning

Structured bridge conversions need to update formula metadata, coefficient labels, prediction design, and simulator covariance as one path. A successful optimizer call alone did not verify any of those public-output boundaries.

## Known Limitations

Only one q1 Binomial interaction intercept is admitted. Multiple responses, slopes, multiple providers, incomplete predictor data, non-unique pair mappings, and within-pair-varying SD predictors are outside this route. This is point-estimate and workflow evidence, not interval-coverage calibration or broad family/effect parity. The paired local DRM.jl checkout was exercised; a released/shared DRM.jl build was not.

## Next Actions

Continue with the next unresolved Bernoulli capability row, then map the remaining distribution/effect combinations. Keep uncertainty coverage validation deferred and report each route's exact boundary.

## Follow-up Evidence Reconciliation

The formula grammar, formula vignette, and known-limitations page now state the tested Julia bridge boundary accurately. The same focused-test run is linked separately to the three link-specific Binomial candidate rows: logit, probit, and cloglog. Each links to this report, the exact bridge test, and a source manifest covering the R bridge/simulator and paired Julia source files. The frozen 19,118-row denominator remains unchanged; the reconciliation links three additional candidate rows and does not promote them to general support.

The evidence reconciler passed with 92 receipt records and 72 distinct linked candidate rows. `git diff --check` passed on the edited documentation and evidence files. No test rerun is claimed; the live result remains the one documented under Checks Run above.
