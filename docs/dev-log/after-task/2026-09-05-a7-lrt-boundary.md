# After Task: A7 — port DRM.jl `chibar_pvalue()` / `lrt_boundary()` (#1116)

**Lane.** `claude/parity-a7-lrt-boundary` at
`~/local-scratch/parity-joint/wt-a7-lrt-boundary`, branched from
`ad8fc6524` (origin/main, 2026-09-05). Ledger:
`.unlazy/parity/gates/leaf-a7-lrt-boundary.md`.
**Resume.** A first attempt died on 2026-09-04 20:40 (rate limit) before
reporting. Its uncommitted files were found in the worktree; every number
below was re-measured in this run, and the port's line citations were
re-checked against the pin.

## 1. Goal

Give drmTMB the chi-bar-square boundary-corrected likelihood-ratio test
that DRM.jl already has (`src/chibar.jl` at pin `430ef64cc`), as native R
over `drmTMB` fit objects, and show the port agrees with DRM.jl's own
`lrt_boundary` on committed fixtures.

## 2. Implemented

- `chibar_pvalue(statistic, q = 1L)`: `0.5 * P(chisq_1 > s)` for `q = 1`,
  `+ 0.25 * P(chisq_2 > s)` for `q = 2`, `s = pmax(statistic, 0)`; other
  `q` abort. Follows `src/chibar.jl:83-95`. Vectorised; `NA` propagates.
- `lrt_boundary(full, reduced, q = 1L)`: `statistic = 2 * (logLik(full) -
  logLik(reduced))`, `pvalue = chibar_pvalue(statistic, q)`,
  `pvalue_naive = pchisq(max(statistic, 0), q, lower.tail = FALSE)`, class
  `drm_lrt_boundary` with a print method. Follows `src/chibar.jl:134-140`,
  plus DRM.jl's REML guard (`src/comparison.jl:133-142`, mean-structure
  fingerprint `src/comparison.jl:117-125`) and `lrtest`'s MAP guard
  (`src/comparison.jl:151-158`). R additions beyond the oracle: `df =
  df(full) - df(reduced)` is returned, a `drmTMB_lrt_boundary_df_mismatch`
  warning fires when `df != q`, ML-vs-REML pairs abort, different-`nobs`
  pairs abort, `df(full) <= df(reduced)` aborts, MSPL fits abort.

## 3a. Decisions and Rejected Alternatives

- **ML-vs-REML pairs abort** (DRM.jl only checks the mean structure when
  either fit is REML). Their likelihoods are on different scales whatever
  the mean structure; a silent number would be wrong. Kept as a documented
  tightening.
- **MAP guard applied** although DRM.jl's `lrt_boundary` itself does not
  call `_map_compare_guard` (only `lrtest` does). A shrunk variance has no
  chi-square reference either way; documented as deliberate.
- **`df` reported and checked against `q`** so a user who drops a random
  slope plus its correlation (three parameters) with `q = 1` is warned
  instead of getting a p-value from the wrong mixture.
- **Not appending to DRM.jl's `docs/dev-log/evidence/parity-*.tsv`**: those
  schemas are per-bridge-cell coefficient / SE / interval comparisons of
  `engine = "tmb"` versus `engine = "julia"`; this leaf compares a native R
  function with DRM.jl's native function, which fits none of those column
  sets. The rows are quoted verbatim in section 5 instead.
- **Rejected**: computing the mixture weights from the information matrix
  for correlated `q = 2` components. Out of scope; the oracle does not do
  it and documents the independence assumption, which the port repeats.

## 4. Files Touched

- `R/lrt-boundary.R` (new)
- `tests/testthat/test-lrt-boundary.R` (new)
- `man/lrt-boundary.Rd` (new, roxygen)
- `NAMESPACE` (`export(chibar_pvalue)`, `export(lrt_boundary)`,
  `S3method(print,drm_lrt_boundary)`)
- `NEWS.md` (one bullet under 0.7.0)
- `docs/dev-log/after-task/2026-09-05-a7-lrt-boundary.md` (this file)

## 5. Checks Run

All with `devtools::load_all()` in the worktree, `OPENBLAS_NUM_THREADS=1`.

1. `testthat::test_file("tests/testthat/test-lrt-boundary.R")` with
   `DRMTMB_JULIA_TESTS=true DRM_JL_PATH=<pin>`: every expectation passed;
   the null-calibration block was skipped (`skip_on_cran()` without
   `NOT_CRAN`). The live-Julia block printed, verbatim:

   ```
   [lrt_boundary parity ri_strong]   R stat=670.2683467571 p=4.36734975138e-148 naive=8.73469950277e-148 | Julia stat=670.2683467567 p=4.36734975221e-148 naive=8.73469950441e-148 | |dstat|=3.76e-10 |dp|=8.22e-158 |dp_naive|=1.64e-157
   [lrt_boundary parity ri_moderate] R stat=2.2011783231 p=0.0689526429898 naive=0.13790528598 | Julia stat=2.2011783231 p=0.0689526429889 naive=0.137905285978 | |dstat|=2.16e-11 |dp|=9.67e-13 |dp_naive|=1.93e-12
   [lrt_boundary parity ri_boundary] R stat=-0.0000000048 p=0.5 naive=1 | Julia stat=0.0000000000 p=0.499999767016 naive=0.999999534032 | |dstat|=4.84e-09 |dp|=2.33e-07 |dp_naive|=4.66e-07
   [lrt_boundary parity crossed_q2]  R stat=94.4177534910 p=9.13677907321e-22 naive=3.14373067383e-21 | Julia stat=94.4177534911 p=9.13677907301e-22 naive=3.14373067376e-21 | |dstat|=4.52e-11 |dp|=2.07e-32 |dp_naive|=7.11e-32
   ```

   Tolerances asserted: statistic `1e-8` absolute on all four; p-values
   `1e-8` on `ri_strong`, `ri_moderate`, `crossed_q2`; `1e-6` on
   `ri_boundary` (the chisq_1 tail has infinite slope at 0, so a `1e-13`
   difference in a statistic at the boundary moves p by about `3e-7`);
   `chibar_pvalue()` versus `DRM.chibar_pvalue` on the identical statistic
   `1e-12` relative, for `q = 1` and `q = 2`, on every fixture.
2. Same file with `NOT_CRAN=true` (Julia block skipped): 66 expectations
   passed; the final post-rebase run with both live Julia and `NOT_CRAN`
   gave `passed=108 failed=0 warnings=0 skipped=0 errors=0`. That run
   included including the null-calibration block (30 true-null replicates,
   seeds 7001-7030: chi-bar-square rejects at least as often as naive,
   naive rejects at most 5 %, atom fraction >= 0.30), and the single
   variance-at-zero edge case (seed 7001: `sd_b < 1e-4`, `|stat| < 1e-6`,
   `pvalue == 0.5`, `pvalue_naive == 1`, `chibar_pvalue(stat, 2) == 0.75`).
3. Roxygen regeneration under the pinned 7.3.2 (installed into a scratch
   library) and under the machine's 8.0.0: `man/lrt-boundary.Rd` and
   `NAMESPACE` are byte-identical between the two versions and to the
   files in the branch. Both versions also rewrite unrelated pages
   (`man/beta.Rd`, `man/confint.drmTMB.Rd`, `man/drmTMB-package.Rd`,
   `man/drmTMB.Rd`, `man/drm_quantile_residuals.Rd`, `man/make_mesh.Rd`,
   `man/model-fit-extractors.Rd`, plus two new `drm_julia_joint_*.Rd`
   pages under either version); those were restored from `HEAD` and are
   not in this PR (see #1140; note that 7.3.2 also diverges from what is
   committed, so the committed pages were not generated by 7.3.2 either).
4. `RoxygenNote: 7.3.2` in `DESCRIPTION` unchanged.
5. Scope: `git diff --stat origin/main -- R/` names only `R/lrt-boundary.R`.

## 6. Tests of the Tests

Red control (G5): planted `df = 2` in place of `df = 1` in the `q = 1`
branch of `chibar_pvalue()` (a df error), re-ran the file with live Julia.
First pass (default summary cap of 10 reports, whole file): 10 closed-form
failures reported, e.g. `chibar_pvalue(stat, 1)` actual `0.44` versus
expected `0.31`; the parity block's own failures were beyond the cap, and
its printed rows showed `|dp| = 9.74e-02` on `ri_moderate` but `|dp| =
1.38e-146` on `ri_strong` and `1.44e-21` on `crossed_q2` — an absolute
`1e-8` tolerance is vacuous where p is that small, and `all.equal()` falls
back to an absolute tolerance below `1e-12`. The parity test was therefore
strengthened with log-scale comparisons (`|d log p| < p_tol`, and
`log(chibar_pvalue())` versus `log(DRM.chibar_pvalue)` at `1e-10`).
Second pass (parity test only, cap lifted, same planted defect): `TOTAL
expectations: passed=30 failed=12` — `ri_strong` log pvalue and both
log-`chibar_pvalue` checks; `ri_moderate` pvalue, log pvalue, and all four
`chibar_pvalue` checks; `crossed_q2` log pvalue and both log-`chibar_pvalue`
checks. `ri_boundary` cannot fail this plant: at `s = 0` both `chisq_1` and
`chisq_2` tails are `1`, so every mixture returns `0.5`; that fixture is
carried by its statistic and identical-`chibar_pvalue` checks on the other
fixtures. With the defect restored the whole file passes (`TOTAL
expectations: passed=108 failed=0 warnings=0 skipped=0 errors=0`, live
Julia and `NOT_CRAN=true`, after rebasing onto `origin/main` `ea3156d73`).
The port was then restored from a byte copy taken before planting;
`shasum -a 256 R/lrt-boundary.R` =
`93cb314b6d5eda399d560c8037e8195a021caae389222456b0b20f7a2e341c66` before
and after.

## 7a. Issue Ledger

- #1116 (DRM.jl feature being ported): addressed on the drmTMB side by this
  PR.
- #1140 (roxygen 8.0.0 versus RoxygenNote 7.3.2): not touched; regeneration
  noise reverted as that issue describes. New observation for that issue:
  roxygen 7.3.2 also rewrites seven committed pages on today's main.

## 8. Consistency Audit

- Line citations in `R/lrt-boundary.R` re-checked against the pin:
  `chibar.jl:83-95`, `chibar.jl:134-140`, `comparison.jl:133-142`,
  `comparison.jl:151-158` correct; `_mean_structure` was cited as
  `119-129` by the previous attempt and is `117-125` — fixed.
- `anova.drmTMB` implements no LRT, `confint(method = "wald")` only flags
  `wald_at_boundary`: the roxygen text saying this pair is the first
  boundary-correct p-value in the package holds on today's main.
- `logLik()`, `nobs()`, `$df`, `$REML`, `$estimator`, `$penalty`,
  `$coefficients` exist on both `drmTMB` and `drmTMB_julia` fits, so
  `lrt_boundary()` accepts either; only native fits were exercised.

## 9. What Did Not Go Smoothly

- First roxygen run used the machine's 8.0.0 and touched three unrelated
  files; a second run under 7.3.2 touched seven. Both cleaned up.
- The default testthat failure cap (10) hid the live-Julia failures in the
  first red-control run; re-run with the cap lifted.
- `remotes::install_version()` failed once for want of a CRAN mirror.

## 10. Known Residuals

- `q = 2` weights assume independent components, as in the oracle.
- `lrt_boundary()` on `engine = "julia"` fits is untested (accepted by
  class check only).
- The `ri_boundary` fixture's p-value agreement is `2.3e-7`, held at
  `1e-6`, not the ledger's `1e-8`; the three interior fixtures meet `1e-8`.
- Merge gate (G8) pending for the integrator; not merged here.

## 11. Team Learning

A statistic sitting exactly at a boundary is the one place where two
optimisers' `1e-9` disagreement becomes a visible p-value difference;
state the tolerance per fixture and say why, rather than loosening the
global one.

## 12. Cross-Product Coverage

Native `q = 1` (random intercept), native `q = 2` (two crossed
intercepts), true-null boundary, REML same-mean, REML different-mean
(refused), ML-vs-REML (refused), MAP (refused), MSPL (refused via
`drm_abort_mspl_inference`), different `nobs` (refused), reversed
arguments (refused). Not covered: bivariate fits, `engine = "julia"`
fits, random slopes.
