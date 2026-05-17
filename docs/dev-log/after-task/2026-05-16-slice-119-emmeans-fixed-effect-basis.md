# After Task: Slice 119 emmeans fixed-effect basis

## Goal

Prepare one internal implementation bridge for future `emm_basis.drmTMB()`
work: a helper that returns the fixed-effect design matrix, coefficients,
optional covariance, offset, link, and linear predictor for one fitted
distributional parameter.

## Implemented

`drm_fixed_effect_basis()` now builds the fixed-effect basis for a requested
`dpar`. It returns `X`, `bhat`, optional `V`, `offset`, `eta`, `link`, and full
coefficient labels. `predict.drmTMB()` now uses that helper for the
fixed-effect component, then applies the existing conditional random-effect,
covariance-block, structured-effect, and residual-scale additions where those
paths already existed.

This is internal plumbing only. Slice 119 does not add `emmeans` as a
dependency, export an `emmeans` method, register S3 methods, implement
contrasts, or advertise user-facing estimated marginal means.

## Mathematical Contract

For one requested distributional parameter, the helper computes the native
linear predictor

```text
eta = X beta + offset
```

where `X` is the fitted `dpar` model matrix for `newdata`, `beta` is
`coef(fit, dpar)`, and `offset` is the stored or newly evaluated offset for
that same formula. When `covariance = TRUE`, `V` is the fixed-effect covariance
submatrix aligned to `names(beta)`.

The helper does not change the scale target. A log-link count-model `mu`
remains a linear predictor for the conditional count mean before the inverse
link, and response-scale values still come from the existing `predict()` inverse
link.

## Files Changed

- `R/methods.R`
- `tests/testthat/test-fixed-effect-basis.R`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-190148-codex-checkpoint.md`

## Checks Run

- `air format R/methods.R tests/testthat/test-fixed-effect-basis.R ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md`
- `Rscript -e "devtools::test(filter = 'fixed-effect-basis', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'fixed-effect-basis|predict-parameters|reference-grid-link-scale-contract|poisson-mean|nbinom2-location-scale|truncated-nbinom2-location-scale', reporter = 'summary')"`
- `Rscript -e "devtools::test(reporter = 'summary')"`
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `rg -n 'Slice 119|drm_fixed_effect_basis|eta = X beta \\+ offset|fixed-effect basis|public `emmeans`|internal plumbing' ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md pkgdown-site/ROADMAP.html`
- `rg -n 'exported `emmeans` method|implemented `emmeans`|emmeans support is implemented|public `emmeans` support|contrast workflow|contrast API.*implemented|slope.*implemented' DESCRIPTION NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md pkgdown-site --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'`
- `Rscript tools/codex-checkpoint.R --goal "Slice 119 emmeans fixed-effect basis" --next "rebase onto origin/main after Slice 118 merge, rerun git diff --check, commit, push, open PR"`

All checks passed. The final stale-claim scan found only the intentional "not
exported" wording and unrelated existing slope-status text.

## Tests Of The Tests

The new test first tried to use a Gaussian `offset()` formula and failed because
the current formula grammar rejects that unsupported path. I changed the test
to the implemented count-model `mu` offset path, so the test evidence now
matches the supported formula grammar rather than broadening the claim.

The test checks coefficient-name alignment, explicit offsets,
`predict(type = "link")` parity, covariance submatrix alignment, covariance as
an opt-in, and the missing-covariance error path.

## Consistency Audit

`ROADMAP.md`, `docs/design/39-visualization-grammar.md`, and
`docs/design/40-emmeans-interface-contract.md` all describe the helper as
internal plumbing for a future `emm_basis()` path. The generated roadmap page
contains the same claim after `pkgdown::build_site()`.

The stale-claim scan did not find new text saying public `emmeans` support is
implemented. Existing slope-status hits are unrelated to this slice.

## What Did Not Go Smoothly

Offset support was easy to overstate because `drm_prediction_offset()` exists
for prediction, but formula support is intentionally narrower. Rose's correction
is to tie future offset tests to the specific families and `dpar` formulas that
`docs/design/01-formula-grammar.md` marks as implemented.

## Team Learning

Ada should keep implementation bridges small enough that they can be used by
existing code immediately; routing `predict.drmTMB()` through the helper gave
Curie a strong regression signal without exposing a new public surface. Boole
and Pat should keep the future `emmeans` language explicit: internal basis
support is useful, but users still need `prediction_grid()` and
`predict_parameters()` until the public method is tested.

## Known Limitations

- No `recover_data.drmTMB()` or `emm_basis.drmTMB()` method exists yet.
- No `emmeans` dependency or conditional registration hook was added.
- Bivariate, zero-inflated, hurdle, ordinal expected-score, random-effect,
  structured-effect, contrast, slope, and interval-aware targets remain blocked
  until their algebra and tests are explicit.

## Next Actions

Rebase Slice 119 onto `main` after Slice 118 is merged, then open a focused PR.
The next `emmeans` slice should add a private preflight for
`recover_data()`-style model-frame reconstruction or start the first public
method only if direct `emmeans::ref_grid()` comparisons can be tested cleanly.
