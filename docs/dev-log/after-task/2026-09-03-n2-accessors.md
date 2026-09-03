# N2 — heritability()/icc()/repeatability() port (issue #1115)

## 1. Scope

Arc N2 of the overnight true-parity lane: port `heritability()`, `icc()`,
`repeatability()` from `DRM.jl`'s `src/heritability.jl` (issue #1115,
both-ways rule D-204). First slice: delta-method Wald intervals only,
Gaussian, homoscedastic-residual, structured-random-intercept mean
components. Worked in the dedicated `wt-n2` worktree, branch
`claude/night-n2-accessors`, off `main` `0ceb77eb0`. No pushes made.

## 2. What was ported

- `R/heritability.R` (new): generics `heritability()`, `icc()`,
  `repeatability()` and their `.drmTMB` methods, house style matching
  `R/methods.R` (`object` first, `@rdname heritability` shared roxygen,
  `cli::cli_abort()` messaging), a shared `drm_variance_ratio()` builder, and
  `print.drm_heritability`.
- `docs/design/259-heritability-icc-repeatability.md` (new): the symbolic
  alignment table (DRM.jl formula + file:line, drmTMB quantity + file:line,
  scale, gate, twin differences), written before the R code per G1.
- `tests/testthat/test-heritability.R` (new): 6 `test_that()` blocks --
  known-DGP recovery for `icc()`/`repeatability()`, known-DGP recovery for
  `heritability()` (single component), a two-component case, three separate
  refusal cases, and a delta-SE sanity check.
- `_pkgdown.yml`: `heritability`, `icc`, `repeatability` added to the "Model
  fitting and post-fit tools" reference section.
- `docs/design/capability-status.md`: `Heritability/repeatability/ICC
  accessors` row moved `planned` -> `point-fit-recovery`; the stale sentence
  claiming "no implementation in R/" for this row was corrected in the same
  edit (it still correctly names AGHQ/chi-bar-square/model-comparison as
  `planned`).

## 3. Alignment table summary

| Quantity | Formula | drmTMB source |
|---|---|---|
| `icc()`/`repeatability()` | `sigma^2_focal / (sigma^2_focal + sigma^2_resid)` | one entry of `object$sdpars$mu` (squared) over itself plus `drm_constant_residual_sigma(object)^2` |
| `heritability()` | `sigma^2_focal / (sum_k sigma^2_k + sigma^2_resid)` | same focal entry over the sum of **all** of `object$sdpars$mu`, squared, plus residual variance |
| delta SE / Wald CI | epsilon-method analogue | numeric central-difference gradient of the ratio in the working (log-SD) parameters, quadratic form against `drm_sdreport_cov_fixed(object)`, Wald interval clamped to `[0, 1]` |

Working-scale parameter positions are located by matching `object$sdpars$mu`
names back to `object$opt$par` occurrences of `log_sd_mu` (ordinary
`(1 | group)` terms) or `log_sd_phylo` (`phylo`/`animal`/`relmat`/`spatial`
terms, verified to land in the same `sdpars$mu` vector on the closed-form
non-LSS path); residual scale is the single `beta_sigma` position gated by
`drm_constant_residual_sigma()`. Full derivation and file:line citations are
in the design doc.

## 4. Routes the component locator supports

- Ordinary `(1 | group)` random intercepts on `mu` (any number of them).
- `phylo(...)`, `animal(...)`, `relmat(...)`, `spatial(...)`, and
  `phylo_interaction(...)` structured random intercepts on `mu`, on the
  closed-form (non-location-scale-scale) path, because they surface in the
  same `object$sdpars$mu` vector as ordinary random intercepts.
- Mixtures of the two (verified via the two-nested-groups test; not
  separately verified for a phylo+iid mix, though the mechanism is the same
  — noted as a gap below).

Structurally excluded (not a special-cased check, just absent from
`sdpars$mu`): any component modelled with `sd(group) ~ ...`
(location-scale-scale). This matches DRM.jl's explicit rejection of that
case.

## 5. Recovery numbers

DGP: `y = 2 + b_g[grp] + e`, `b_g ~ N(0, 1)`, `e ~ N(0, 0.6^2)`,
`n_groups = 300`, `n_per = 10` (see deviation note below), truth
`icc = 1^2 / (1^2 + 0.6^2) = 0.735294`.

| seed | icc estimate | truth | diff |
|---|---|---|---|
| 1 | 0.6968 | 0.7353 | -0.0385 |
| 2 | 0.7643 | 0.7353 | +0.0290 |
| 3 | 0.7296 | 0.7353 | -0.0057 |
| 4 | 0.7280 | 0.7353 | -0.0073 |
| 5 | 0.7191 | 0.7353 | -0.0162 |

All 5 seeds within 0.05; `heritability()` equals `icc()` in every seed
(single component). Two-component test (two nested iid groups, `sd_g = 1`,
`sd_g2 = 0.5`, `sd_e = 0.6`): `heritability(component = "(1 | grp)") =
0.5044 < icc(component = "(1 | grp)") = 0.6147`, the expected direction
(heritability's denominator is larger).

## 6. Deviation: DGP size (n_groups = 300, not 60)

The task sketch specified `n_groups = 60, n_per = 10`. A 20-seed pilot at
that size found the ML `icc()` point estimate has sampling SD ~= 0.039, so a
strict `< 0.05` per-seed check failed 2 of the first 5 seeds purely from real
sampling noise, not an estimator bug. The 20-seed pilot's mean error, -0.02,
was originally (wrongly) read as "expected ML downward shrinkage"; Rose's
2026-09-03 verdict ran a 150-replicate Monte Carlo at the same `n_groups =
60` and found the mean error is -0.002 (MC SE ~0.0032) -- within one MC SE of
zero, so the -0.02 pilot number was noise, not a known bias mechanism. That
attribution has been removed from the code comment and this note; no bias
claim is made. Rather than loosen the tolerance or hand-pick seeds that
happen to pass, `n_groups` was raised to 300 (fits remain sub-second; a
10-seed pilot there had max |diff| = 0.039, about 22% headroom against 0.05),
keeping the originally-specified 0.05 tolerance with a reliable margin. Full
rationale is in a code comment at the top of `test-heritability.R`.

## 7. Test-block-count deviation (gate-driven, not silently absorbed)

The gate's own `CHECK` commands count `test_that()` blocks matching a regex
in the test name (one row per block in `testthat::test_file()`'s
`as.data.frame()` output), requiring `>= 2` blocks matching "recover" and
`>= 3` blocks matching "refuse". The task brief described these as
single combined checks ("a known-DGP test", "x3 refuse cases in one test").
To satisfy the gate's literal block-count check, the recovery test was split
into two blocks (`icc()`/`repeatability()` recovery; `heritability()`
recovery) sharing a `heritability_recovery_fits()` helper, and the refuse
test into three blocks (heteroscedastic sigma; no random component;
non-Gaussian family). No assertion content changed, only the `test_that()`
boundaries.

## 8. Not covered

- `method = "profile"` (accepted in the signature, always aborts naming
  `method = "delta"`).
- Non-Gaussian families and `biv_gaussian` fits (same scope DRM.jl itself
  excludes / a separate existing gate).
- Heteroscedastic residual `sigma ~ x` (gated out, tested).
- `sd(group) ~ ...` mean components (structurally excluded, not directly
  tested with an explicit refuse case beyond the natural "no structured mean
  component" path, since such a term never appears in `sdpars$mu`).
- A phylo/animal/relmat/spatial second component paired with an iid first
  component was not exercised directly (the two-component test uses two
  nested iid groups per the task's explicit "or two nested groups if the
  parser allows" allowance); the underlying mechanism (both land in
  `sdpars$mu`) was verified by direct code reading and by the single-phylo
  `sdpars$mu` merge path (`R/drmTMB.R:21917-21929`), not by an additional fit.
- Bias-corrected point estimate (DRM.jl's `bias_correct` also reports a
  second-order-corrected estimate; this port reports only the plug-in
  estimate).
- REML fits were probed manually (confirmed `cov.fixed`/`opt$par` still
  carry `beta_sigma`/`log_sd_mu`) but not added as a dedicated test case in
  this slice.
- Any coverage claim for the delta-method interval — documented in the
  roxygen and design doc as a sanity check only.

## 9. Question for the owner (naming collision, not resolved here)

`R/methods.R`'s `drm_derived_summary_rows()` (unchanged by this work) already
prints `summary()` rows labelled `"repeatability"` and
`"phylogenetic_signal"`, but its formula for **every** row is
`re_variance / (total_re_var + residual_variance)` — i.e. the
*heritability*-style total-variance denominator, not the focal-vs-residual
denominator DRM.jl (and this port's `icc()`/`repeatability()`) use. The two
will disagree whenever a fit has two or more structured mean components.
Recorded in the design doc section 3 point 5; needs a maintainer decision on
whether to rename one of the two surfaces or document the difference in
both places. No `summary()` code was touched.

## 10. Verification

- `tests/testthat/test-heritability.R`: 38 expectations, all passing
  (`devtools::load_all()` + `testthat::test_file()`).
- CI-like run: `testthat::test_dir("tests/testthat", filter =
  "heritability|methods|summary")` — 72 test blocks, 581 expectations
  passed, 0 failed, 0 errors.
- `python3 -m unittest tools/tests/test_capability_ledger.py` — OK (80
  tests).
- `pkgdown::check_pkgdown()` — no problems found.
- `git diff --quiet origin/main -- R/methods.R` — clean (summary() rows
  untouched).
- Gate re-verification (`gate-check.mjs --reverify --approve
  .unlazy/night/gates/leaf-n2.md`): N2-G1 through N2-G8 all PASS. N2-G9
  (Rose review) and N2-G10 (PR merge) are outside this arc's scope.

## 11. Repair loop (Rose adversarial review, 2026-09-03)

Rose's fresh-Opus verdict
(`scratchpad/rose/2026-09-03-rose-n2-verdict.md`) refuted 4 findings against
the first slice. Fixed in this round:

1. **REFUTED (most serious) — random slopes not gated.** A
   `bf(y ~ 1 + x + (1 + x | blk), sigma ~ 1)` fit was silently accepted and
   returned a confident number (estimate + SE + CI) that summed an
   intercept-column variance and a per-unit-of-`x` slope-column variance
   while dropping `eta_cor_mu`, the intercept-slope correlation. Fixed:
   `drm_variance_ratio_reject_random_slopes()` (`R/heritability.R`) checks
   (a) `"eta_cor_mu" %in% names(object$opt$par)` and (b)
   `object$model$random$mu$coef_names` containing anything other than
   `"(Intercept)"`, and aborts naming the term for all three accessors. Two
   new "refuse slope" tests cover the correlated case (`(1 + x | blk)`) and
   the uncorrelated slope-only case (`(0 + x | blk)`, which has no
   `eta_cor_mu` so it exercises check (b) alone). See design doc section 2,
   point 6 for the full derivation and probe evidence.
2. **REFUTED (documentation) — wrong `component` label.** The roxygen
   `@param`, design doc, and (implicitly) any future user copying
   `"phylo(1 | species, tree = tree)"` from the docs would hit an abort: the
   real `sdpars$mu` label drops non-grouping arguments and is
   `"phylo(1 | species)"` (`"animal(1 | id)"` for `animal()`, etc.). Fixed:
   `@param component` corrected, design doc section 1 and section 3 point 1
   corrected, and a new runnable `\donttest{}` `@examples` block fits a real
   `phylo()` model and calls `icc(phylo_fit, component = "phylo(1 | species)")`
   so `R CMD check` exercises the documented label. A new "documented label"
   test reads the literal `component = "..."` string out of
   `R/heritability.R`'s own roxygen source (not a hand-duplicated second
   copy) and asserts it equals a real fit's `sdpars$mu` name and that
   `icc()` runs with it.
3. **REFUTED (prose, minor) — unsupported "-0.02 ML shrinkage" claim.**
   `test-heritability.R`'s top comment and this note's section 6 had
   attributed the 20-seed pilot's mean error (-0.02) to "the expected ML
   downward shrinkage." Rose's 150-replicate Monte Carlo at the same
   `n_groups = 60` found the mean error is -0.002 (MC SE ~0.0032) — within
   one MC SE of zero, so -0.02 was pilot noise, not a known bias mechanism.
   Fixed: both places now state the honest fact (raised `n_groups` to keep
   the per-seed tolerance clear of sampling noise) with no bias-mechanism
   claim attached. The decision to raise `n_groups` is unchanged and still
   correct — only the explanation attached to it was wrong.

Not applied this round (recorded, not silently dropped — Rose's remaining
"concrete safeguards" 3 and 4, and her "REFUTED in part" Attack 5 finding):

- **Attack 5 (REFUTED in part) — the shared roxygen never mentions the
  `summary()` naming collision**, only the design doc and after-task do.
  Rose: "Escalating in a dev log while leaving the user-facing help silent
  is the wrong end to fix first." Not fixed here because the coordinator's
  repair-loop scope (items 1-3 plus gate N2-G11) did not list it and G11
  does not check for it; flagged here as the next concrete, low-cost fix (one
  sentence in the shared `@rdname heritability` roxygen block).
- **Safeguard 4 — position indexing has no runtime assertion.**
  `drm_variance_ratio_positions()` maps `sdpars$mu` names to `opt$par`
  positions by prefix-regex + ordinal rank, and
  `drm_variance_ratio_delta()` (`R/heritability.R:333`, pre-repair-loop line
  numbering) indexes `cov_fixed[denom_positions, denom_positions]` with no
  assertion that `dimnames(cov_fixed)[[1]]` matches `names(theta_hat)` in
  the same order. Rose confirmed order invariance and correct mapping for
  every route she probed (ordinary REs regardless of declaration order,
  mixed iid+phylo, mixed LSS+phylo), and noted a `log_sd_phylo2` block would
  fail safe (routes to `NA`, which already aborts) rather than silently
  wrong — so this is a robustness hardening, not a known bug. Not applied
  this round; a `stopifnot(identical(dimnames(cov_fixed)[[1]],
  names(object$opt$par)))` guard would close it cheaply in a follow-up.
- **UNTESTABLE-HERE (Rose's own label) — no cross-engine numeric comparison
  against a live DRM.jl run, and `spatial()`/`relmat()`/
  `phylo_interaction()` routes are still claimed in section 4 above but not
  directly exercised by a test** (only `phylo()` and `animal()` were, both
  by Rose and by the "documented label" test added here for `phylo()`).
  Recorded as an open gap, not resolved — these routes share the same
  `structured$phylo_mu$has` / `sdpars$mu` merge mechanism verified for
  `phylo()`/`animal()`, but that is code-reading evidence, not a fit.
