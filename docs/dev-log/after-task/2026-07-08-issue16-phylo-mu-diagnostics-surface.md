# After Task: Fix `phylo_mu_diagnostics` false positive on `sd_phylo(...) ~ .` surfaces (#16)

Meta: 2026-07-08 · Claude (Opus 4.8) · repo `drmTMB` · branch
`drmtmb/fix-16-phylo-mu-diagnostics` off `main` `bed29701`.

## 1. Goal

`check_drm()` on a fitted direct-SD *surface* model (`sd_phylo(...) ~ .`) reported
`phylo_mu_diagnostics` with `status=error` and set `attr(chk, "ok") = FALSE`, even
though the fit was healthy (`conv=0`, finite positive per-group SDs). Reported by
A. Mizuno (2026-07-08). Goal: eliminate the false error while still erroring on a
genuinely non-finite/non-positive fitted phylogenetic SD.

## 2. Implemented

- New internal helper `phylo_mu_diagnostic_sd_values(object, phylo_mu)` in
  `R/check.R`. For a direct-SD surface model (`random_scale$phylo$n_models > 0`) it
  returns the fitted per-group surface SDs (`object$sdpars[[dpar]]`, the same source
  the sibling `check_phylo_direct_sd_model` already reads), restricted to surface
  dpars whose target is a phylo_mu endpoint. Otherwise it returns the scalar SDs as
  before.
- `check_phylo_mu_diagnostics()` now consumes that helper. `finite_positive_sd` is
  computed over the returned values (error only when genuinely non-finite/non-positive);
  the residual-scale ratio / `weak_sd` logic is unchanged. A new surface branch of the
  `value` text reports `n_group`, `phylo_sd_range=[min,max]`, `median_phylo_sd`, and
  `min_sd_ratio`; the scalar single-coef (`phylo_sd=`) and multi-coef (`n_coef=` /
  `min_phylo_sd=`) branches are preserved verbatim.

## 3a. Decisions and Rejected Alternatives

- **Summarise, not defer.** The surface is already fully diagnosed by
  `check_phylo_direct_sd_model`, but `phylo_mu_diagnostics` uniquely adds the
  SD-vs-residual-scale ratio, so I kept the row alive (per the handover brief:
  "summarise the fitted surface instead") rather than returning `NULL` for surfaces.
- **Source of SD values.** The handover suggested `obj$report()$sd_phylo_group`; I used
  `object$sdpars[[dpar]]` instead — identical fitted values, no dependency on the TMB
  object being retained (`keep_tmb_object`), and consistent with the sibling check.
- Name collision caught during verification: my first helper name `phylo_mu_sd_summary`
  already exists in `R/methods.R` with a different 3-arg signature. Renamed to
  `phylo_mu_diagnostic_sd_values`.

## 4. Files Touched

- `R/check.R` — new helper + surface-aware SD acquisition and value text.
- `tests/testthat/test-check-drm.R` — new regression test (surface → `ok` + summary;
  NA-injected surface → `error`).
- `docs/dev-log/after-task/2026-07-08-issue16-phylo-mu-diagnostics-surface.md` — this note.

## 5. Checks Run

- `testthat::test_file("test-check-drm.R")` → FAIL 0 | PASS 262 (+10 from the new test).
- Regression sweep of every file touching `phylo_mu_diagnostics` or the scalar-SD text:
  `test-phylo-gaussian` (PASS 385), `test-nbinom2-location-scale` (157),
  `test-poisson-mean` (138), `test-biv-gaussian` (948) → all FAIL 0.
- Manual repro (`scratchpad/repro_16.R`) before/after: `errors 1 → 0`,
  `attr ok FALSE → TRUE`.

## 6. Tests of the Tests

- The regression test fails on pre-fix code: the repro reproduced the exact
  `phylo_mu_diagnostics` error and `attr ok = FALSE` before the edit.
- The negative arm (NA-injected surface → `error`, message "non-positive or non-finite")
  guards against the fix over-suppressing genuine failures.

## 7a. Issue Ledger

- Closes #16 (pending PR). No new issues opened.

## 8. Consistency Audit

- Rose sweep: the only surface-SD grammar is `sd_phylo` / `sd_phylo1` / `sd_phylo2`
  (`R/parse-formula.R`). There is no `sd_spatial`/`sd_animal`/`sd_relmat`, so the sibling
  checks `check_spatial_mu_diagnostics` and `check_known_relatedness_mu_diagnostics`
  cannot encounter a per-group SD surface — the bug is phylo-specific and fully covered.

## 9. What Did Not Go Smoothly

- Two documented gotchas bit during verification and were fixed immediately: the
  `phylo_mu_sd_summary` name collision, and `bf()` NSE (`tree = sim$tree` → assign
  `tree <- sim$tree` and pass the bare symbol).

## 10. Known Residuals

- The residual-scale ratio for the tiny synthetic fixture is large (`min_sd_ratio≈4.3`)
  because the fixture is near-deterministic; this is a fixture property, not a concern.
- #18 (inflated SE despite clean `pdHess`) is the next task and is unrelated to this row.

## 11. Team Learning

- `object$sdpars[[dpar]]` is an *endpoint-aware accessor*, not a plain list slot — treat
  it as the canonical R-side source of the fitted per-group SD surface.
- Before adding a package-level helper, grep the name across `R/` — `phylo_mu_sd_summary`
  already existed and silently shadowed dispatch until the verification run surfaced it.

## 12. Cross-Product Coverage

- **covers ✓**: univariate `sd_phylo(...) ~ .` and bivariate `sd_phylo1/2(...) ~ .`
  direct-SD surfaces (all `has_sd_phylo_model == 1` mu-targeted phylo effects), plus the
  unchanged scalar single-coef and multi-coef phylo-SD paths.
- **does NOT cover ✗**: no change to `check_phylo_direct_sd_model`, to the spatial /
  animal / relmat diagnostics (no surface-SD grammar exists for them), to `sigma`-targeted
  phylo SD surfaces, or to interval/coverage certification. #18 (inflated SE despite clean
  `pdHess`) is a separate task, untouched here.
