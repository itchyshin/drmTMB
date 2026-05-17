# After Task: Slice 147 finite transformed-predictor newdata guard

## Goal

Reject `newdata` rows that evaluate to non-finite fixed-effect design-matrix
values after transformed predictor terms are processed.

## Implemented

`drm_fixed_effect_basis()` now validates the fixed-effect prediction design
matrix after `model.matrix()`-style formula evaluation when `newdata` is
supplied. A raw value can be finite but still produce a non-finite model column;
for example, `size = 0` is finite, but `log(size)` is `-Inf`.
The helper names affected sparse-matrix columns without densifying the matrix.

`predict()` now rejects that case with an error naming the affected model
column, such as `"log(size)"`, instead of returning a non-finite prediction.
The `predict.drmTMB()` reference page now tells users that transformed
predictor terms must evaluate to finite design-matrix values.

## Mathematical Contract

This slice does not change the model. It tightens prediction input validation:
for a fixed-effect linear predictor

```text
eta = X(newdata) beta + offset(newdata),
```

every evaluated entry of `X(newdata)` must be finite when users supply
`newdata`. The fitted coefficients, likelihood, links, and formula grammar are
unchanged.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `R/methods.R`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-147-finite-transformed-predictors.md`
- `man/predict.drmTMB.Rd`
- `tests/testthat/test-fixed-effect-basis.R`

## Checks Run

- No-edit scout before the fix:
  `predict()` on a Gaussian `y ~ log(size) + habitat` fit with `size = 0`
  returned `-Inf`.
- `Rscript -e "devtools::test(filter = 'fixed-effect-basis', reporter = 'summary')"`:
  passed before and after formatting/roxygen regeneration.
- A sparse-matrix unit check confirmed the internal term-name helper reports
  `log(size)` without needing a dense matrix conversion.
- Post-fix scout of the same `predict()` call: errored with
  `non-finite design-matrix value` and named `log(size)`.
- `air format NEWS.md ROADMAP.md R/methods.R docs/design/40-emmeans-interface-contract.md tests/testthat/test-fixed-effect-basis.R`:
  passed.
- `Rscript -e "devtools::document()"`: passed and rewrote
  `man/predict.drmTMB.Rd`.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 147 transformed-predictor wording:
  found the expected entries in source files, Rd, tests, and rendered pkgdown
  pages.
- Stale-claim scan for accidental transformed-response, ordinal-response,
  bivariate, non-`mu`, random-effect, empirical-marginalisation, or
  custom-weight `emmeans` support: no new false support claims; matches were
  existing intentional boundary text or unrelated implemented bivariate
  features.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-17-012249-codex-checkpoint.md`.

## Tests Of The Tests

The new regression test uses a model with `log(size)` and `newdata` containing
`size = 0`. Before the fix, the same prediction path returned `-Inf`; after the
fix, both the internal fixed-effect basis path and public `predict()` reject
the request.

The sparse helper test constructs a two-column sparse matrix with an infinite
entry in the `log(size)` column and checks that the term-name helper reports
that column without coercing the matrix to dense form.

## Consistency Audit

The implementation changes validation after formula evaluation only. It does
not alter formula parsing, likelihood parameterization, fitted coefficients,
offset evaluation, link functions, or the supported `emmeans` target set.

NEWS, the Phase 17 roadmap, the `emmeans` design contract, and the
`predict.drmTMB()` reference page now describe the same rule: raw predictors
must be valid, and transformed predictor columns must also be finite after
formula evaluation.

## What Did Not Go Smoothly

The first stale-claim scan used backticks in a shell-quoted pattern and zsh
attempted command substitution. The scan was rerun with safe quoting and the
generated search index excluded.

## Team Learning

Pat should keep user-facing prediction errors focused on the column the user
can fix. Curie should add regression tests for transformed terms whenever
newdata validation moves earlier than base R's model-matrix errors. Rose should
keep separating transformed predictors from transformed responses in prose.

## Known Limitations

- The guard applies to fixed-effect prediction design matrices when `newdata`
  is supplied.
- It does not add transformed-response `emmeans` support, non-`mu` `emmeans`
  support, empirical marginalisation, random-effect workflows, bivariate
  `emmeans`, or blocked model structures.

## Next Actions

Continue scanning prediction and `emmeans` paths for cases where ordinary R
formula evaluation can create valid-looking but uninterpretable prediction
rows. Keep those fixes in narrow validation slices with one failing scout and
one regression test each.
