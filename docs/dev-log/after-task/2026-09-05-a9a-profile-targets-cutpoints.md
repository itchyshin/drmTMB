# A9a (#1156 + #1144): `profile_targets()` lists the Julia engine's full target union; both ordinal cutpoint endpoints are Newton-polished

**Reader**: anyone touching `drm_profile_targets()` or the ordinal cutpoint
engine in `R/profile.R`; anyone reading `profile_targets()` output on an
`engine = "julia"` fit; anyone extending the #1130 Newton-polish symmetry to
another constrained solve. Leaf ledger:
`.unlazy/parity/gates/leaf-a9a.md`. Worktree branch `claude/parity-a9a`
from `origin/main` at `c062a2285`. DRM.jl pin `430ef64cc`.

## 1. Goal

Two defects that both live in `R/profile.R`:

1. **#1156** -- `drm_profile_targets()` returned early for `drmTMB_julia`
   objects with only the phylogenetic SD inventory, so discovery listed 1
   target where `confint()` accepted several. Make discovery report the union
   the engine accepts.
2. **#1144** -- the constrained ordinal cutpoint endpoint solve was left
   wherever `nlminb` alone stopped, while the free fit is Newton-polished
   (#1130). Apply the same polish to BOTH endpoints; leave
   `PROFILE_ENDPOINT_GRADIENT_TOL = 1e-3` untouched.

## 2. Implemented

* `R/profile.R`: new internal `drm_julia_profile_target_union(object)` =
  `rbind(drm_julia_wald_targets, drm_julia_wald_scale_targets, drm_julia_profile_targets)`,
  deduplicated by `parm`, validated; `drm_profile_targets()`'s Julia branch
  now returns it. Native row order (fixed effects, `sigma` alias, SD rows).
* `R/profile.R` `ordinal_cutpoint_profile_evaluator()`: after the inner
  `nlminb`, `if (isTRUE(object$control$newton_polish)) opt <- drm_newton_polish(opt, fn_free, gr_free)`
  -- the same call and the same control the main endpoint evaluator uses
  (`profile_endpoint_evaluator()`), before the fell-below and gradient guards.
* `tests/testthat/test-julia-bridge.R`: the one granted expectation
  (`expect_equal(targets$parm, "sd:mu:phylo(1 | species)")`) replaced by the
  five-name union, plus one subsetting line so the following SD-row
  expectations in the same block keep their one-row `targets`.
* New `tests/testthat/test-profile-targets-julia.R` (4 synthetic tests, no
  Julia; 1 live test gated by `drm_skip_live_julia()`).
* New `tests/testthat/test-ordinal-cutpoint-profile.R` (3 tests, TMB only).
* `NEWS.md`: one new #1156 section; one #1144 bullet appended to the #1130
  section.

## 3a. Decisions and Rejected Alternatives

* **Union built in `R/profile.R`, not by widening `drm_julia_profile_targets()`.**
  `drm_julia_confint()` and the bootstrap path already `rbind()` that
  function with `drm_julia_wald_targets()`; widening it would duplicate every
  fixed-effect row and make `drm_julia_validate_inference_targets()` (which
  requires exactly one matching row) reject a valid `parm`. A test pins that
  `drm_julia_profile_targets()` still returns the SD row alone.
* **`sigma` alias listed with `profile_ready = FALSE`.** It is what
  `drm_julia_wald_confint()` already reports (`missing_tmb_parameter`); making
  it profile-able needs the validator and the inference call in
  `R/julia-bridge.R`, outside OWNS. Rejected: dropping the row (then the
  Julia inventory would not be name-matched to TMB's five direct rows).
* **Derived `phylo_total_variance_share` row stays TMB-only.** The bridge has
  no counterpart; listing it not-ready would advertise a target the engine
  has no code path for.
* **Polish guarded by `object$control$newton_polish`**, mirroring #1130's
  main-endpoint fix so `drm_control(newton_polish = FALSE)` switches both
  sides off together. A test pins that direction too.
* **Gradient assertion at 1e-6** in the new ordinal test: more than two orders
  below the unpolished stops (3.6e-4 .. 1.9e-3) and two above the polish
  target (1e-8), so a reverted polish fails and optimiser noise passes.

## 4. Files Touched

* `R/profile.R` (modified: union helper + Julia branch; cutpoint evaluator polish)
* `tests/testthat/test-julia-bridge.R` (modified: the granted expectation near line 381)
* `tests/testthat/test-profile-targets-julia.R` (new)
* `tests/testthat/test-ordinal-cutpoint-profile.R` (new)
* `NEWS.md` (modified)
* `docs/dev-log/after-task/2026-09-05-a9a-profile-targets-cutpoints.md` (new, this file)
* `.unlazy/parity/gates/leaf-a9a.md` (EVIDENCE lines, main checkout, not on the branch)

## 5. Checks Run

All measured in this session (2026-09-05), `devtools::load_all()` on the
worktree, `OPENBLAS_NUM_THREADS=1`, Julia runs with
`DRMTMB_JULIA_TESTS=true DRM_JL_PATH=DRM_JL_PHYLO_PATH=.../drmjl-430ef64cc`.

**G1 (RED, #1156)** -- `bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)`,
Gaussian ML, `ape::rcoal(32)` seed 202606:

```
TMB   n = 6 : fixef:mu:(Intercept) | fixef:mu:x | fixef:sigma:(Intercept) | sigma | sd:mu:phylo(1 | species) | derived:phylo_total_variance_share(species)
Julia n = 1 : sd:mu:phylo(1 | species)
```

**G2 (after)** -- same fits:

```
Julia n = 5 : fixef:mu:(Intercept) | fixef:mu:x | fixef:sigma:(Intercept) | sigma | sd:mu:phylo(1 | species)
Julia ready: fixef:mu:(Intercept) | fixef:mu:x | fixef:sigma:(Intercept) | sd:mu:phylo(1 | species)
setdiff TMB\Julia: derived:phylo_total_variance_share(species)
setdiff Julia\TMB:  (empty)
confint fixef:mu:(Intercept)      lower=-0.600724   upper=1.56298  status=profile
confint fixef:mu:x                lower=-0.00840885 upper=0.677999 status=profile
confint fixef:sigma:(Intercept)   lower=-0.360717   upper=0.205908 status=profile
confint sd:mu:phylo(1 | species)  lower=0.177059    upper=1.45383  status=profile
```

**G3 (#1144)** -- committed random-intercept fixture
(`test-arc2a-mu-random-intercept.R`, seed 9, `y ~ x + (1 | id)`, 4 levels,
level 0.95). Free-fit max|grad| = 8.45699e-10. Endpoint max|grad| at the
solved endpoints, BEFORE (polish planted out) -> AFTER:

```
1|2 lower  endpoint=-1.292162019  3.60947e-04 -> 3.26747e-10
1|2 upper  endpoint=-0.7608963231 9.39927e-04 -> 3.18070e-09   (after: -0.7608963229)
2|3 lower  endpoint=-0.2273995286 1.93606e-03 -> 4.08562e-14
2|3 upper  endpoint= 0.2851323027 1.39623e-03 -> 6.74389e-09   (after:  0.2851323025)
3|4 lower  endpoint= 0.7515015157 9.68328e-04 -> 3.32556e-09   (after:  0.7515015149)
3|4 upper  endpoint= 1.282950044  8.94652e-04 -> 3.32402e-09
```

Two of six endpoints were above the 1e-3 guard before; all six were still
ACCEPTED (nlminb code 0 does not consult the gradient). Intervals move by
< 1e-9. The committed fixed-effect fixture (`test-profile-targets.R`, seed
20260812, level 0.80) went 5.05e-08 / 1.42e-05 / 4.72e-05 / 7.12e-09 ->
1.58e-14 / 3.92e-12 / 5.54e-11 / 7.12e-09 with intervals
[-1.0613300302, -0.4621264568] and [0.3535125449, 0.9417268093] unchanged
to 1e-9 (upper 2|3: 0.9417268093 -> 0.9417268096).

**Tests** (this run):

* `test-ordinal-cutpoint-profile.R`: 29 expectations, 0 failed.
* `test-profile-targets-julia.R`: 5 tests, 0 failed, 0 skipped when live
  (`Julia bridge: 1 live test ran`); 4 pass + 1 skip without `DRM_JL_PATH`.
* `test-julia-bridge.R`: 0 failed, 2 live skips (no `DRM_JL_PATH` in that run).
* `test-profile-targets.R` 76 tests / 0 failed / 1 skipped;
  `test-profile-plots.R` 6/0; `test-profile-shape-boundary.R` 5/0;
  `test-arc-d-profile-trace.R` 4/0.
* Vignette chunk `penguin-intervals` (`bivariate-nongaussian.Rmd`): the
  `biv_lognormal()` penguin fit's `confint(parm = "rho12", method = "profile",
  profile_engine = "endpoint")` = [0.2613086623, 0.4482706264], status
  `profile`, finite (fit + profile chunk reproduced in a script; the R = 99
  bootstrap chunk was not rerun).

## 6. Tests of the Tests

RED controls, each planted, run, then restored byte-identically (sha256 of
`R/profile.R` `ee3213a504120a427db95432acb29631b02f65b9541b99d48e13c6d82ce5dea7`
before and after each):

* **(a) union reverted** (`return(drm_julia_profile_targets(object))`):
  `test-profile-targets-julia.R` live run -> `tests=5 failed=10`; the live
  G2 test fails with `Expected julia_targets$parm to have length 5. Actual
  length: 1.` and the synthetic test with `actual "sd:mu:phylo(1 | species)"`
  vs the five expected names.
* **(b) polish reverted** (the `drm_newton_polish()` block removed):
  `test-ordinal-cutpoint-profile.R` -> `tests=3 failed=8`, quoting
  `0.000361 / 0.000940 / 0.001936 / 0.001396 / 0.000968 / 0.000895 >= 1e-06`
  on the six random-intercept endpoints and `0.000014 / 0.000047` on the
  fixed-effect fixture.

## 7a. Issue Ledger

* #1156 -- addressed (drmTMB side). Residual: `sigma` alias is Wald-only on
  Julia (see 10).
* #1144 -- addressed for both endpoints of the cutpoint profile.
* Not opened: a derived `phylo_total_variance_share` counterpart for the
  bridge (out of this leaf's scope; noted for the integrator).

## 8. Consistency Audit

* Every other caller of `drm_profile_targets()` in `R/profile.R` (confint
  bootstrap path, `profile()`, Wald path, refit diagnostics) was checked:
  Julia fits dispatch to `confint.drmTMB_julia` / the Julia bootstrap path
  before those lines, so widening the Julia inventory does not reach a
  TMB-only code path.
* `drm_julia_reconstruction_status()` still calls
  `drm_julia_profile_targets()` directly (SD-only) -- unchanged semantics.
* Bivariate `biv_gaussian` Julia fits: `drm_julia_wald_targets()` marks its
  fixed-effect rows not-ready (`missing_tmb_parameter`), and the four SD rows
  come from `drm_julia_profile_targets_biv()`; the union simply lists both.
  Not exercised live in this leaf.
* Other constrained solves with the #1130 asymmetry: the main endpoint
  (`profile_endpoint_evaluator`, fixed in f3) and now the cutpoint
  evaluator are the only two `nlminb` inner solves in `R/profile.R`
  (`grep -n "stats::nlminb" R/profile.R` -> lines 3691 and 3933).

## 9. What Did Not Go Smoothly

* The ledger's G3 RED premise ("stops at a gradient above 1e-3 on a committed
  ordinal fixture") did NOT reproduce on the first committed fixture tried
  (`test-profile-targets.R`: max 4.7e-05). It reproduced on the committed
  random-intercept fixture (`test-arc2a-mu-random-intercept.R`, seed 9) at
  two of six endpoints (1.94e-3, 1.40e-3). The asymmetry is real on every
  fixture; the ">1e-3" part is fixture-dependent.
* First attempt at the live target test filtered TMB's derived row by
  `target_class != "derived"`; the actual class is `"derived-summary"`.
  Fixed and rerun live.
* `drmTMB()` has no `threads` argument (that belongs to `confint()`); the
  first G1 script died on it.
* The DRM.jl parity tools (`tools/parity_fixture.R`, `parity_se.R`) compare
  families across engines; this leaf admits no family and produced no
  `parity-*.tsv` rows.

## 10. Known Residuals

* `sigma` (response-scale alias) is listed on the Julia fit but
  `profile_ready = FALSE`; `confint(parm = "sigma", method = "profile")` on
  a Julia fit is refused with the not-ready message, while the TMB fit
  profiles it. Wiring it needs `drm_julia_validate_inference_targets()` and
  the inference call -- outside this leaf's OWNS. So G2's "every listed
  target is accepted by profile confint" is met for the four ready rows, not
  for `sigma`.
* TMB lists `derived:phylo_total_variance_share(species)`; Julia does not.
  Name-match holds on the five direct rows only.
* The cutpoint polish changed no reported interval by more than 1e-9 on the
  two fixtures measured; no fixture was found where the unpolished solve
  produced a visibly wrong cutpoint interval.
* `R CMD check` was not run; the touched test files and the four profile
  files were.

## 11. Team Learning

* nlminb's code 0 never consults the gradient, so "accepted" endpoints can sit
  at 2e-3 while the free fit sits at 1e-9. Any new constrained inner solve
  must reuse the `newton_polish` block, not just the gradient guard.
* When a Julia inventory needs widening, check every `rbind()` consumer
  first: the one-target validator turns a duplicated row into a refusal.

## 12. Cross-Product Coverage

Engine axis (`engine = "julia"`, `profile_targets()`):
* covers ✓ univariate Gaussian phylo ML (live), synthetic payload / no-payload
  fixtures, empty-inventory fit.
* does NOT cover ✗ bivariate `biv_gaussian` q4 live, Julia REML fits, the
  `_xfam` / joint Julia classes (`confint.drmTMB_julia_xfam`,
  `confint.drmTMB_julia_joint` have their own paths and were not measured),
  non-Gaussian Julia families' `profile_targets()` output.

Solver axis (`newton_polish` on the cutpoint evaluator):
* covers ✓ fixed-effect `cumulative_logit()` and random-intercept
  `cumulative_logit()`, `newton_polish = FALSE` direction.
* does NOT cover ✗ phylo / relmat ordinal fits, `level` other than 0.80 /
  0.95, `PROFILE_ENDPOINT_GRADIENT_TOL` behaviour under a code-1 stop (no
  fixture reached code 1).
