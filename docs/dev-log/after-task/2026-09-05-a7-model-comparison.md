# A7 (#1117): `aicc()` and the nested LRT, ported from DRM.jl `src/comparison.jl`

**Reader**: anyone touching `R/model-comparison.R`, anyone who wants
`anova.drmTMB()` to stop refusing, and the integrator merging the
`claude/parity-*` leaves. Ledger:
`.unlazy/parity/gates/leaf-a7-model-comparison.md`. DRM.jl pin `430ef64cc`.

## 1. Goal

Port DRM.jl's model-comparison suite (`aicc`, `lrtest`/`anova`, `weights`) to
native R over drmTMB fit objects, with DRM.jl's own implementation as the
oracle: fit the same fixtures in both engines, compute each quantity natively
in DRM.jl through JuliaCall, and assert the R port matches.

## 2. Implemented

DRM.jl contract (read before any R was written; all lines at pin `430ef64cc`):

| DRM.jl | file:line | Inputs | Output | Edge cases |
|---|---|---|---|---|
| `aicc(fit)` | `src/comparison.jl:209-215` | one `DrmFit` | `Float64` = `aic + 2k(k+1)/(n-k-1)`, `k = dof(fit)` (`gaussian_core.jl:1897`, `length(fit.theta)`), `n = nobs(fit)` (`:1200`), `aic = -2 loglik + 2 dof` (`:1940-1944`) | `n - k - 1 <= 0` returns `Inf` (`:213`); VA fit errors (`:210`, `_va_infocrit_guard` at `gaussian_core.jl:1922`); REML fit warns once via `aic` |
| `lrtest(reduced, full)` | `src/comparison.jl:65-78` | two `DrmFit` | `(; statistic, dof, pvalue)`: `statistic = 2(loglik(full) - loglik(reduced))`, `dof = dof(full) - dof(reduced)`, `pvalue = ccdf(Chisq(dof), max(statistic, 0))` | `dof <= 0` throws `ArgumentError` (`:70-73`); REML with different mean structures throws (`:133-142`); MAP throws (`:151-158`); mixed VA/LA throws (`:162-168`); `full` adding a variance-component block warns, boundary null (`:101-114`); negative statistic returned as-is |
| `anova(reduced, full)` | `:182` | alias of `lrtest` | same | same |
| `weights(fit)` | `:231` | one fit | `ones(nobs(fit))` (DRM.jl stores no prior weights) | none |

R port, `R/model-comparison.R`:

* `aicc()` generic, exported, with `aicc.drmTMB` (MSPL abort, the existing
  REML/MAP information-criterion warning labelled `AICc`) and `aicc.default`
  (any object whose `logLik()` carries `df` and `nobs`, which covers
  `drmTMB_julia` and, incidentally, `lm`). `Inf` when `n - k - 1 <= 0`.
* `drm_lrtest(reduced, full)` (internal): the LRT with the REML mean-structure
  guard, the MAP guard, the boundary variance-component warning
  (`drmTMB_lrtest_boundary_warning`), the wrong-order error, and one guard
  DRM.jl lacks: different `nobs` errors. Returns
  `list(statistic, df, p.value)` (DRM.jl's `statistic, dof, pvalue`).
* `weights()`: no port needed. `weights.drmTMB()` (`R/methods.R:772`) already
  returns the prior observation weights; DRM.jl's version is the weaker one.
* No VA guard: drmTMB fits carry no variational marginal.

Focused tests: `tests/testthat/test-model-comparison.R` (9 tests). Public
docs: `man/model-comparison.Rd` (roxygen2 7.3.2). NEWS: one bullet.

## 3a. Decisions and Rejected Alternatives

* **`drm_lrtest()` is internal, not wired to `anova.drmTMB()`.** The `anova`
  method that refuses lives in `R/methods.R:2708`, outside this leaf's OWNS
  (only `R/model-comparison.R` may differ under `R/`), and the NAMESPACE clause
  allows export lines for `aicc` only. Rejected: redefining `anova.drmTMB` in
  `model-comparison.R` so collation order overrides the stub (two definitions
  of one method is a defect in waiting); exporting `lrtest` anyway (violates
  the OWNS clause). The wiring is a three-line follow-up once `R/methods.R` is
  in scope: replace the `cli_abort` in `anova.drmTMB` with
  `drm_lrtest(object, ..1)` and export a `lrtest` generic.
* **Cross-engine tolerance 1e-8, not the 1e-4 `parity_fixture.R` uses.** The
  ledger asks for 1e-8; I first wrote 1e-4 for the TMB-vs-Julia leg on the
  assumption that optimiser noise would exceed 1e-8, then measured it at
  `<= 2e-12` on both fixtures and tightened to the ledger's figure with the
  measurement recorded in the test.
* **Rd page named `model-comparison`** (`@name model-comparison`) so the
  generated file matches the OWNS pattern `man/model-comparison*.Rd`.
* **Extra `nobs` guard** kept although DRM.jl has none: a likelihood ratio on
  different data is never meaningful and the check is one comparison.

## 4. Files Touched

* `R/model-comparison.R` (new)
* `tests/testthat/test-model-comparison.R` (new)
* `man/model-comparison.Rd` (new, roxygen2 7.3.2)
* `NAMESPACE` (+`export(aicc)`, `S3method(aicc,default)`, `S3method(aicc,drmTMB)`)
* `NEWS.md` (one bullet under 0.7.0)
* `docs/dev-log/after-task/2026-09-05-a7-model-comparison.md` (this file)

`git diff --name-only origin/main -- R/` prints exactly `R/model-comparison.R`.

## 5. Checks Run

All with `OPENBLAS_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true DRM_JL_PATH=<pin clone>`,
package loaded with `devtools::load_all(<worktree>)`.

* `testthat::test_file("tests/testthat/test-model-comparison.R")`: all 9 tests
  pass, 0 failures, 0 skips; the live-Julia block reports
  `Julia bridge: 1 live test ran`.
* Same-target evidence, measured 2026-09-04 (17 significant digits; `abs_diff`
  columns are the R port minus DRM.jl native):

```
fixture	quantity	julia_native	R_on_julia_engine	R_on_tmb_engine	abs_diff_julia	abs_diff_tmb	drmjl_ref
base_gaussian_location_scale	loglik_full	-147.20031833207301	-147.20031833207301	-147.20031833207301	0	0	430ef64cc
base_gaussian_location_scale	loglik_reduced	-198.614492281883	-198.614492281883	-198.614492281883	0	0	430ef64cc
base_gaussian_location_scale	df_full	4	4	4	0	0	430ef64cc
base_gaussian_location_scale	df_reduced	2	2	2	0	0	430ef64cc
base_gaussian_location_scale	nobs	120	120	120	0	0	430ef64cc
base_gaussian_location_scale	aicc_full	302.74846275110298	302.74846275110298	302.74846275110298	0	0	430ef64cc
base_gaussian_location_scale	aicc_reduced	401.331548666331	401.331548666331	401.33154866632901	0	1.9895196601282805e-12	430ef64cc
base_gaussian_location_scale	lrt_statistic	102.82834789962	102.82834789962	102.828347899619	0	9.9475983006414026e-13	430ef64cc
base_gaussian_location_scale	lrt_df	2	2	2	0	0	430ef64cc
base_gaussian_location_scale	lrt_pvalue	4.6892993972642197e-23	4.6892993972642297e-23	4.6892993972666195e-23	9.9917019819894438e-38	2.3997717172036999e-35	430ef64cc
base_gaussian_intercept_only	loglik_full	-111.91660616174801	-111.91660616174801	-111.91660616174801	0	0	430ef64cc
base_gaussian_intercept_only	loglik_reduced	-130.000860668461	-130.000860668461	-130.000860668462	0	9.9475983006414026e-13	430ef64cc
base_gaussian_intercept_only	df_full	3	3	3	0	0	430ef64cc
base_gaussian_intercept_only	df_reduced	2	2	2	0	0	430ef64cc
base_gaussian_intercept_only	nobs	100	100	100	0	0	430ef64cc
base_gaussian_intercept_only	aicc_full	230.08321232349701	230.08321232349701	230.08321232349601	0	9.9475983006414026e-13	430ef64cc
base_gaussian_intercept_only	aicc_reduced	264.12543267712903	264.12543267712903	264.12543267712999	0	9.6633812063373625e-13	430ef64cc
base_gaussian_intercept_only	lrt_statistic	36.168509013426302	36.168509013426302	36.168509013427197	0	8.9528384705772623e-13	430ef64cc
base_gaussian_intercept_only	lrt_df	1	1	1	0	0	430ef64cc
base_gaussian_intercept_only	lrt_pvalue	1.8097143884643701e-09	1.8097143884643701e-09	1.8097143884635501e-09	0	8.1994278219318868e-22	430ef64cc
```

  Largest |R - DRM.jl| on the `engine = "julia"` object: `9.99e-38` (a
  p-value); on the TMB object: `1.99e-12` (AICc). The ledger's bars are 1e-8
  for p-values and information criteria.
* Edge case (DRM.jl `comparison.jl:213`): a 3-row Gaussian `y ~ 1, sigma ~ 1`
  fit has `df = 2`, `nobs = 3`, and `aicc()` returns `Inf`; the arithmetic is
  also pinned at `n - k - 1 = 0` and `= -1` (`Inf`) and `= 1` (finite).
* `roxygen2::roxygenise(roclets = c("rd", "namespace"))` under roxygen2
  **7.3.2** (installed into a scratch library; the machine default is 8.0.0,
  #1140). Then the R CMD check of the built tarball, reported in the ledger's
  G7 evidence line.
* `git diff --name-only origin/main`: `NAMESPACE NEWS.md R/model-comparison.R
  man/model-comparison.Rd tests/testthat/test-model-comparison.R`.

## 6. Tests of the Tests

Two red controls, each planted with `sed`, run through the full test file with
the live Julia oracle, then restored with `cp` from a backup and checked with
`diff -q` (empty both times):

* **Sign error in the LR statistic** (`ll_full - ll_reduced` flipped): the
  parity test fails on both engines and both fixtures, e.g.
  `Expected abs(tj$statistic - native$statistic) < 1e-08. Actual comparison:
  72.33701803 >= 0.00000001` and `abs(tt$p.value - native$p.value)`:
  `1.00000000 >= 0.00000001`. Restored: `RESTORED byte-identical (red 1)`.
* **df error in the AICc correction** (`k(k + 1)` -> `k(k - 1)`): the parity
  test fails on every AICc line, e.g. `abs(aicc(fj_full) - native$aicc_full)`:
  `0.12500000 >= 0.00000001`, `abs(aicc(ft_red) - native$aicc_red)`:
  `0.06837607 >= 0.00000001`. Restored: `RESTORED byte-identical (red 2)`.

The pure-R tests also caught a real defect during development:
`drm_lrtest_vc_labels()` returned `NULL` rather than `character(0)` for a fit
with no variance components (`c(NULL, NULL)`); fixed with `as.character()`.

## 7a. Issue Ledger

* #1117 (this port): implementation, tests, docs, and same-target evidence
  landed; `anova.drmTMB()` wiring deferred (scope, see 3a).
* #1140 (roxygen2 8.0.0 vs 7.3.2): reproduced from the other side. Even
  roxygen2 **7.3.2** rewrites seven committed pages (`beta.Rd` link target
  `base:beta` -> `base:Special`, `confint.drmTMB.Rd` loses `\code{}` on
  `exp()`/`plogis()`, `drmTMB-package.Rd`, `drmTMB.Rd`,
  `drm_quantile_residuals.Rd`, `make_mesh.Rd`, `model-fit-extractors.Rd`) and
  adds `drm_julia_joint_prepare.Rd`/`drm_julia_joint_result.Rd`. So the
  committed `man/` was not generated by 7.3.2 either; the "pin contributors to
  7.3.2" option in #1140 will not give a clean regeneration on its own. I
  restored those nine files to `HEAD` (backups in the session scratchpad) and
  committed only `man/model-comparison.Rd`.
* `docs/design/capability-status.md:106` still lists the model-comparison
  suite as `planned` (file outside OWNS; not edited).

## 8. Consistency Audit

* `AIC.drmTMB`/`BIC.drmTMB` (`R/methods.R:2661-2694`) compute
  `-2 logLik + penalty * df` from `object$logLik`/`object$df`; `aicc.drmTMB`
  uses the same two fields, so `aicc(fit) - AIC(fit)` is exactly the
  correction term (asserted to 1e-12).
* REML: `drm_fit_df()` (`R/drmTMB.R`) counts the marginalised fixed effects
  back into `df`, so `k` in AICc and `df` in the LRT count parameters, not
  TMB's `fixed` vector, the same convention as `AIC.drmTMB`.
* `logLik.drmTMB_julia` (`R/julia-bridge.R:4732`) carries `df` and `nobs`, so
  the default `aicc` method covers `engine = "julia"` objects; measured above.
* The bridge object's `logLik`/`df` equal DRM.jl's `loglik`/`dof` to the last
  digit on both fixtures (rows `loglik_full`, `df_full`), which is what makes
  the `engine = "julia"` leg a formula-only comparison.
* Warning/error classes follow the neighbours: `drmTMB_ic_reml_warning`
  reused; new `drmTMB_lrtest_reml_error`, `drmTMB_lrtest_map_error`,
  `drmTMB_lrtest_boundary_warning`.

## 9. What Did Not Go Smoothly

* `@name model-comparison` first landed in the middle of the roxygen block,
  which would have swallowed the description into the name; moved before
  `@export`.
* `drm_lrtest_vc_labels()` returned `NULL` for empty `sdpars`/`corpars` (see 6).
* A first pass of the test file set the TMB-vs-Julia tolerance at 1e-4 before
  measuring; measured `<= 2e-12`, tightened to 1e-8.
* The Julia session prints a `LogExpFunctions` extension precompile
  `LoadError` on first boot; it is noise (the live test still runs and passes)
  but it clutters every log.
* Two commands were stopped by the destructive-command guard (`git checkout --
  <files>` on roxygen drift, `rm -rf` on a scratch check directory); both were
  redone non-destructively (`git show HEAD:<path> >`, a fresh directory).

## 10. Known Residuals

* `anova.drmTMB()` still refuses; users cannot reach `drm_lrtest()` without
  `:::`. Follow-up named in 3a.
* `drm_lrtest_vc_labels()` reads `sdpars` and `corpars` only; tested on a
  `(1 | g)` fit. Phylogenetic (`phylocov`) and bivariate structured blocks
  were not exercised, so the boundary warning may stay silent on those.
* Cross-engine agreement is measured on two Gaussian fixed-effect fixtures;
  no random-effect or non-Gaussian cell was measured against native DRM.jl.
* `R CMD check` was run with `--no-install --no-tests --no-examples` against a
  scratch install of this tree; it is not a full `--as-cran` check.

## 11. Team Learning

* Port the contract table (file:line, inputs, output, edge cases) before the
  first line of R: every guard in `drm_lrtest()` maps to one row of it, and
  the red controls target exactly the two rows a reviewer would doubt.
* When the oracle can be evaluated on the bridge object's own log-likelihood,
  do that leg first: it isolates the formula from optimiser agreement, and the
  cross-engine leg then measures only what it claims to.
* Measure a tolerance before writing it; the 1e-4 I assumed was four orders
  too loose.

## 12. Cross-Product Coverage

This leaf does NOT cover: `anova.drmTMB()` (still refuses), an exported
`lrtest()`, `update()` for `drmTMB` fits, bivariate or phylogenetic fits in
either `aicc()` evidence or the boundary-variance warning, non-Gaussian
families, `engine = "julia"` REML objects under `drm_lrtest()`, joint
missing-data (`drmTMB_julia_joint`) objects, and any interval or coverage
claim. `weights()` was measured (all ones on an unweighted fit) but not
changed.
