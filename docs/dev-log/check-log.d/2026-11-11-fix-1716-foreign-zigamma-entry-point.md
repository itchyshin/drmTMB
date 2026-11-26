# 2026-11-11 — fix #1716 foreign ziGamma refusal (entry-point revision)

## Scope

Move the #1716 guard off a top-level rebind of `drm_family_type()` and onto
`drm_eval_family_arg()` in `R/family.R`. Foreign zero-inflated, hurdle, and
truncated stats `family` arguments are refused with class
`drmTMB_foreign_inflation_family` before `drm_family_type()` or
`drm_impute_family_type()` can route them to a plain non-inflation family.
`R/drmTMB.R` stays byte-identical to `main` (C17 watchlist).

## Path-proof (Code Reviewer item 1)

User-facing family arguments are evaluated only in `drm_eval_family_arg()`:

- `drmTMB()` in `R/drmTMB.R`
- `impute_model()` in `R/missing-data.R`
- `drm_resolve_priors()` in `R/fixed-priors-workflow.R`

Downstream helpers pass family into `drmTMB()` and therefore through the same
function: `biv_associate()` unpacks a two-element list and calls `drmTMB()`
once per margin; `drm_phylo_penalty_sweep()` forwards `family` to `drmTMB()`.
There is no `update.drmTMB()`. `simulate()` / `predict()` reuse a fitted
object's already-admitted family.

`drm_family_type()` is not rebound. A hand-built Gamma family whose
`initialize` mentions `ziformula` still classifies as `"gamma"` if that
classifier is called directly; `drm_eval_family_arg()` refuses it. Wrapping
`drm_family_type()` would have missed `impute_model()`, which uses
`drm_impute_family_type()` and has the same Gamma silent-misfit branch.

## Evidence

R 4.3.3, `pkgload::load_all()` from this branch. `{glmmTMB}` 1.1.8 is
installed on this VM, so the live constructor tests ran.

```text
python3 tools/capability_ledger.py --check
capability-ledger: OK (31 generated outputs)

python3 tools/capability_ledger.py --check-c14-receipt-equivalence
C14 receipt equivalence: OK (3 eligible, 7 source-different retained receipts; C17 current-source compatibility PASS)

git hash-object R/drmTMB.R
git rev-parse origin/main:R/drmTMB.R
5be5ba5480117fd8527e28b1bba7670d4e09cbca
5be5ba5480117fd8527e28b1bba7670d4e09cbca

Rscript -e 'pkgload::load_all(".", compile = FALSE); testthat::test_file("tests/testthat/test-fix-1716-foreign-zigamma.R")'
fix-1716-foreign-zigamma: 13 tests / 43 expectations, 0 fail, 0 skip

Rscript -e 'pkgload::load_all(".", compile = FALSE); testthat::test_file("tests/testthat/test-env-skip-census.R")'
env-skip-census: 3 tests / 5 expectations, 0 fail

test-family-link-contract.R 4 tests / 92 expectations, 0 fail
test-control-family-validators.R 9 tests / 83 expectations, 0 fail
test-gamma-location-scale.R 7 tests / 76 expectations, 0 fail
```
