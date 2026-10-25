# After task: refuse ordinary mean (1 | g) on the Julia bridge (#1551)

Reader: a drmTMB user who fits Poisson, Gamma, NB2, Beta, or Binomial with
`engine = "julia"` and an ordinary mean `(1 | g)`.

## Goal

Stop those models from running a full Julia fit and then aborting at the
`resd` coefficient-label echo. Refuse in R first, and point the user to
`engine = "tmb"`.

## Implemented

`drm_julia_refuse_ordinary_mean_re_unlabelled()` fires after the fe-only
fence. The cohort is every registry family with `phylo_only`,
`locscale_phylo`, `slope_phylo`, or `structured` set, except `gaussian` and
`biv_gaussian`. Gaussian keeps the working conditional-components route.
Structured `phylo()` / `relmat()` / `animal()` / `spatial()` terms are not
checked here, because `drm_julia_dpar_has_ordinary_bar()` matches only
ordinary `|` bars.

This is option 1 of #1551. Sending a `resd` label and `marginal = "Laplace"`
would widen the experimental Julia engine and is left out.

## Files Changed

- `R/julia-bridge.R`: helper, refuse function, call site, gate-registry row.
- `tests/testthat/test-julia-ordinary-mean-re-fence.R`
- `tests/testthat/test-julia-gate-vs-engine.R`
- `docs/dev-log/dashboard/julia-gates.tsv` and `inst/extdata/julia-gates.tsv`
  regenerated with `Rscript tools/write-julia-gate-registry.R` (17 rows).
- `NEWS.md`

## Checks Run

`pkgload::load_all()` then:

- `testthat::test_file("tests/testthat/test-julia-ordinary-mean-re-fence.R")`:
  FAIL 0 / WARN 0 / SKIP 0 / PASS 24.
- `testthat::test_file("tests/testthat/test-julia-gate-vs-engine.R")`:
  FAIL 0 / WARN 0 / SKIP 1 (`ape` not installed) / PASS 146.

`python3 tools/capability_ledger.py --check-c14-receipt-equivalence`:
C14 receipt equivalence OK; C17 current-source compatibility PASS.
`R/drmTMB.R` and other C17 source files were not edited.

Full package tests and `R CMD check` were not run.

## Tests Of The Tests

The new file fails on unfixed `main` because Poisson `(1 | g)` currently
reaches Julia setup (`needs a local DRModels.jl checkout` when the engine
is missing). Gaussian `(1 | g)` and Poisson fixed effects still reach that
setup message after the fence. The gate-registry test failed until both
`julia-gates.tsv` copies were regenerated; that was the completeness check
working as designed.

## Consistency Audit

Exact searches:

```sh
rg "ordinary_mean_re_unlabelled|residual-SD label" R tests NEWS.md
rg "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" R tests NEWS.md docs/dev-log/known-limitations.md
rg "engine = \"julia\"" README.md docs/dev-log/known-limitations.md NEWS.md vignettes/julia-engine.Rmd
```

No lineage or C17 files were edited. `docs/design/parity-matrix.md` is a
generated file and still says `julia-gates.tsv` has 16 rows. Regenerating
it needs `DRM_JL_PATH` at the pin; that is left for a later refresh.

## What Did Not Go Smoothly

The first focused run of `test-julia-gate-vs-engine.R` failed because the
dashboard and `inst/extdata` gate tables were not regenerated with the new
row. `Rscript tools/write-julia-gate-registry.R` fixed that.

## Team Learning

A new Julia intentional gate is not done when only `drm_julia_intentional_gates()`
and the live fence test change. Both `julia-gates.tsv` copies must be
rewritten in the same change, or the dashboard-match test fails.

## Design-Doc Updates

No formula-grammar or likelihood design doc changed. The user-facing
recovery path is the NEWS bullet and the fence message (`engine = "tmb"`).

## pkgdown / Documentation Updates

No vignette or Rd edit. The Julia engine stays experimental; this PR
narrows a broken admission rather than adding a user-facing method.

## GitHub Issue Maintenance

Closes #1551 if the focused tests pass. Related #1567 (Gaussian factor
labels on the conditional-components route) is not addressed.

## Known Limitations

The Julia route still does not fit these models. The honest next step is
`engine = "tmb"`. Supporting the route needs a `resd` label and
`marginal = "Laplace"`, plus a same-target receipt, and is a later task.

## Next Actions

Independent reviewer pass on the PR. Do not merge.
