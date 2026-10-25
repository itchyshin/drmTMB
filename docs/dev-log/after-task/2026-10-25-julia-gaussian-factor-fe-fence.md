# After task: refuse Gaussian ordinary (1 | g) with a factor FE (#1567)

Reader: a drmTMB user who fits `gaussian()` with `engine = "julia"`, an
ordinary mean `(1 | g)`, and a factor in the mean formula.

## Goal

Stop that model from running a full Julia fit and then aborting because
DRM.jl returns `f: b` while drmTMB expects `fb`. Refuse in R first, and
point the user to `engine = "tmb"`.

## Implemented

`drm_julia_refuse_gaussian_ordinary_re_factor_fe()` fires after the
fe-only fence. It checks three things: the family is `gaussian`, the
`mu` formula has an ordinary `|` bar, and a non-bar `mu` predictor is a
factor, character, or logical column in `data`. Numeric-only Gaussian
`(1 | g)` and Gaussian factor FE without a bar still reach Julia setup.

This is option 1 of #1567. Sending `labels = true` plus a `resd` label
would widen the experimental Julia engine and is left out.

## Files Changed

- `R/julia-bridge.R`: helper, refuse function, call site, gate-registry row.
- `tests/testthat/test-julia-gaussian-factor-fe-fence.R`
- `tests/testthat/test-julia-gate-vs-engine.R`
- `docs/dev-log/dashboard/julia-gates.tsv` and `inst/extdata/julia-gates.tsv`
- `NEWS.md`

## Checks Run

`pkgload::load_all()` then:

- `testthat::test_file("tests/testthat/test-julia-gaussian-factor-fe-fence.R")`:
  FAIL 0 / WARN 0 / SKIP 0 / PASS 11.
- `testthat::test_file("tests/testthat/test-julia-gate-vs-engine.R")`:
  FAIL 0 / WARN 0 / SKIP 1 (`ape` not installed) / PASS 146.

`R/drmTMB.R` and other C17 source files were not edited. Full package
tests and `R CMD check` were not run.

## Tests Of The Tests

The new file fails on unfixed `main` because `y ~ x + f + (1 | g)`
reaches Julia setup (`needs a local DRModels.jl checkout` when the
engine is missing). Numeric-only `(1 | g)` and factor FE without a bar
still reach that setup message.

## Consistency Audit

```sh
rg "gaussian_ordinary_re_factor_fe|factor coefficient names" R tests NEWS.md
rg "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" R tests NEWS.md docs/dev-log/known-limitations.md
```

No lineage or C17 files were edited. `docs/design/parity-matrix.md` is
generated and still reports the previous gate count.

## What Did Not Go Smoothly

The gate registry needs both `julia-gates.tsv` copies rewritten in the
same change, as #1551 already showed.

## Team Learning

A Julia admission bug that only appears after the fit should be fenced
in R first when the experimental engine is not being widened.

## Design-Doc Updates

No formula-grammar or likelihood design doc changed.

## pkgdown / Documentation Updates

No vignette or Rd edit. The recovery path is the NEWS bullet and the
fence message.

## GitHub Issue Maintenance

Closes #1567 if the focused tests pass. Related #1551 (missing `resd`
label on non-Gaussian ordinary bars) is a separate PR.

## Known Limitations

The Julia route still does not fit Gaussian `(1 | g)` with a factor
fixed effect. The honest next step is `engine = "tmb"`.

## Next Actions

Independent reviewer pass on the PR. Do not merge.
