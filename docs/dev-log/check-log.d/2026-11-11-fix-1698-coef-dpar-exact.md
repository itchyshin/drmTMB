# 2026-11-11 — fix #1698 coef/fixef dpar exact match

## Goal

Align native `coef()` / `fixef()` with `predict()` on exact `dpar` names; no
`match.arg()` partial matching. Unknown names abort with class
`drmTMB_unknown_dpar` and a "Did you mean" line that lists every prefix match,
or every case-insensitive `adist` tie within cutoff 2, and omits the suggestion
when nothing is close.

## Evidence

- Issue #1698 MRE: `coef(fit, dpar = "s")` silently returned sigma on pre-fix
  `main` via `match.arg()`.
- Shared helpers in `R/utils.R`: `drm_resolve_fitted_dpar_name()`,
  `drm_abort_unknown_fitted_dpar()`, `drm_suggest_closest_name()`.
- `R/methods.R` call sites are unchanged in the review follow-up; `call =
  parent.frame()` makes the error name `coef()` / `predict()`, not the helper.
- `tests/testthat/test-fix-1698-coef-dpar-exact.R`.

## Commands

```sh
cd /agent/repos/drmTMB
Rscript -e 'pkgload::load_all(compile = FALSE); testthat::test_file("tests/testthat/test-fix-1698-coef-dpar-exact.R")'
Rscript -e 'pkgload::load_all(compile = FALSE); testthat::test_file("tests/testthat/test-sd-selector-contract.R")'
```

Main comparison: overlay `main`'s `R/utils.R` and `R/methods.R`, keep the new
test file, `pkgload::load_all(compile = FALSE)`, rerun the same test file.

## Counts

- Branch (`cursor/fix-1698-coef-dpar-exact-d50e`): fix-1698 **38 pass / 0 fail /
  0 skip**; sd-selector **29 pass / 0 fail**.
- `main` sources + new tests: **8 pass / 18 fail / 3 error** (21 failing
  assertions). The 8 passes are exact-name successes plus three vacuous
  `expect_no_match()` checks on an empty message after `dpar = "s"` returns
  silently. Every new classed-error, suggestion-line, mu1/mu2, helper, and
  `drm_fixed_effect_basis()` assertion failed on `main`.

## Capability ledger

`R/methods.R` is in `C17_C14_SOURCE_FILES`. This slice does not recertify. A
tolerance-0 recertify must be done on the Mac afterwards. Other watchlisted
files were not touched: `R/drmTMB.R`, `src/drmTMB.cpp`,
`tests/testthat/test-zero-one-beta.R`,
`tools/run-lane-c-c17c1-c14-model15-compatibility.R`.
