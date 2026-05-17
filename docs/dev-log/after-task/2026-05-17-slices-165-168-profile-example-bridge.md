# After Task: Slices 165-168 Profile Example Bridge

## Goal

Make the reader-facing profile-likelihood confidence-interval examples match
the implemented direct and row-specific profile paths before moving to derived
and bootstrap intervals.

## Implemented

The model-workflow article now shows four profile-example boundaries:

- constant residual `sigma` uses a fitted-object direct target;
- predictor-dependent `sigma`, `sigma1`, `sigma2`, and `rho12` use supplied
  `newdata` rows;
- random-effect SD examples copy exact target names from `profile_targets()`;
- random-effect correlation examples stay separate from residual `rho12`.

`docs/design/12-profile-likelihood-cis.md` now records the same Slice 165-168
contract, and `ROADMAP.md` marks Slices 165-168 complete.

## Mathematical Contract

For `sigma`, `sigma1`, and `sigma2`, the fitted linear predictor is on the
log-standard-deviation scale and the reported interval is transformed by
`exp()`. For residual `rho12`, the fitted linear predictor is transformed back
to the bounded residual-correlation scale. For random-effect SDs and
correlations, the public target must map to a direct TMB parameter or linear
combination and appear as `profile_ready` in `profile_targets()`.

This task did not change likelihoods, transformations, formula grammar, or TMB
parameterization.

## Files Changed

- `vignettes/model-workflow.Rmd`
- `docs/design/12-profile-likelihood-cis.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slices-165-168-profile-example-bridge.md`

## Checks Run

- `air format vignettes/model-workflow.Rmd docs/design/12-profile-likelihood-cis.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slices-165-168-profile-example-bridge.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "profile-targets|summary", reporter = "summary")'`:
  passed.
- `Rscript -e 'pkgload::load_all(".", quiet = TRUE); rmarkdown::render("vignettes/model-workflow.Rmd", output_dir = tempfile("model-workflow-render-"), quiet = FALSE)'`:
  passed.
- `Rscript -e 'pkgdown::build_site(preview = FALSE)'`: passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with "No problems found."
- `git diff --check`: passed.
- Stale direct-`sigma` and derived-profile scan returned only the expected
  constant-`sigma` roxygen/manual example in `R/methods.R` and
  `man/summary.drmTMB.Rd`.
- Stale credible-interval and derived-q4 scan returned no matches.
- Rendered-site scan confirmed the new source and generated article/roadmap
  wording.

## Tests Of The Tests

No new tests were added because this slice block changed examples and design
notes rather than interval code. The focused tests already exercise the examples
that this prose now points to: constant `sigma` profiles, row-specific `sigma`
profiles, bivariate `sigma1`/`sigma2` profiles, row-specific residual `rho12`
profiles, direct random-effect SD profiles, ordinary random-effect correlation
profiles, univariate `mu`/`sigma` correlation profiles, bivariate group-level
correlation targets, and profile-aware `summary()` rows.

## Consistency Audit

The workflow article, profile-CI design note, roadmap table, and rendered
pkgdown article now tell the same story: direct profile intervals are available
only for direct fitted-object targets or generated one-row `newdata` targets.
Derived q4 correlations, nonlinear variance ratios, and custom contrasts remain
status-only until a later interval method exists.

The prose-style pass used the applied-user lens from the project-local
`prose-style-review` skill: examples now tell readers which call to make next
instead of only listing target names.

## What Did Not Go Smoothly

The first stale scan was intentionally broad and surfaced many valid existing
mentions of residual `rho12` being separate from group-level correlations. I
reran narrower scans and recorded the exact patterns in the check log.

## Team Learning

- Ada kept this as a stacked documentation and validation slice instead of
  turning it into a new inference-method task.
- Fisher kept profile-likelihood confidence intervals separate from bootstrap
  intervals and Bayesian credible intervals.
- Pat pushed the workflow article toward copyable examples and action-oriented
  status interpretation.
- Grace required render, pkgdown build/check, `git diff --check`, and
  stale-wording scans before closure.
- Rose made the check-log and after-task report carry the "who is working"
  roster and the next-slice boundary.
- Boole kept `sigma`, `sigma1`, `sigma2`, `rho12`, `sd:mu:*`, and `cor:*`
  target names stable.

## Known Limitations

- This task does not add new profile, bootstrap, or derived-interval machinery.
- Predictor-dependent response-scale targets still need supplied `newdata`.
- q4 ordinary and phylogenetic endpoint correlations remain derived
  unstructured-correlation rows with unavailable profile intervals.
- Random-effect slope examples are examples for existing direct targets; they
  are not a claim that every future structured-dependence random-slope block is
  implemented.

## Next Actions

Start Slice 169 by marking q4 derived correlation and covariance-product
interval boundaries explicitly before auditing parametric-bootstrap feasibility
in Slice 170.
