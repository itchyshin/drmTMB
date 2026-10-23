# Phase 19 feasibility batch 1 (Gauss, TMB likelihood/numerical review)

Author: Gauss (`tmb_engineer`/inference reviewer), 2026-08-14.
Worktree: `.worktrees/external-oracle`, drmTMB 0.7.0 (`DESCRIPTION:3`), loaded via
`devtools::load_all(quiet = TRUE)`. `R_PROFILE_USER=/dev/null Rscript --no-init-file`.
Method: actually fit every cell (not reasoned about); console numbers below are
copy-pasted from real runs, not reconstructed. Each fit script is disposable and was
run once per cell (plus one follow-up debug run for cell 2's random-effect structure
and one for cell 3's namespace collision — both noted inline).

Batch verdict counts: **2 VIABLE, 1 BLOCKED (comparator, not drmTMB)**.

---

## ph19-c01 — gaussian location-scale, `sigma ~ Days` vs glmmTMB `dispformula`

- **drm_formula.**
  `drmTMB(bf(mu = Reaction ~ Days + (1 + Days | Subject), sigma = ~ Days), data = sleepstudy, family = gaussian())`
- **comparator_call.**
  `glmmTMB(Reaction ~ Days + (Days | Subject), dispformula = ~ Days, data = sleepstudy)`
- **drmTMB fit.** 0.246 s. `is_converged(fit)` = `TRUE`.
  `coef(fit, "mu")` = `(Intercept)=252.85599, Days=10.08607`.
  `coef(fit, "sigma")` = `(Intercept)=2.81184909, Days=0.08463394`.
- **glmmTMB fit.** `fixef(g)$cond` = `(Intercept)=252.85595, Days=10.08606`.
  `fixef(g)$disp` = `(Intercept)=2.8118492, Days=0.0846339`. `g$sdr$pdHess` = `TRUE`.
- **Matched-scale conversion applied.** Per `158-plan-of-record.md` row "gaussian()":
  both sides are `log(sigma)`, unsquared — compare `coef(fit,"sigma")` to
  `fixef(g)$disp` directly, no transform.
- **Side-by-side (matched scale, log-SD).**

  | coef | drmTMB | glmmTMB | abs diff |
  | --- | --- | --- | --- |
  | mu:(Intercept) | 252.85599 | 252.85595 | 4e-5 |
  | mu:Days | 10.08607 | 10.08606 | 1e-5 |
  | sigma:(Intercept) | 2.81184909 | 2.8118492 | 1e-6 |
  | sigma:Days | 0.08463394 | 0.0846339 | 4e-8 |

  Agreement to 4-5 significant figures on all four coefficients, on the same scale,
  same sign, same link. Both `pdHess = TRUE`.
- **Verdict: VIABLE.** Both fit, both converge, matched-scale numbers agree tightly.
  No trap here (this is the row doc 158 already verified against
  `tests/testthat/test-comparators.R:780-784`); this run reconfirms it on a different,
  real dataset.

---

## ph19-c02 — gaussian, `sigma ~ (1 | Subject)` random-intercept scale (frontier)

- **drm_formula.**
  `drmTMB(bf(mu = Reaction ~ Days, sigma = ~ (1 | Subject)), data = sleepstudy, family = gaussian())`
- **comparator_call.**
  `glmmTMB(Reaction ~ Days, dispformula = ~ (1|Subject), data = sleepstudy)`
- **drmTMB fit.** 0.259 s. `is_converged(fit)` = `TRUE`, `fit$sdr$pdHess` = `TRUE`,
  `fit$opt$convergence` = `0`.
  `coef(fit, "mu")` = `(Intercept)=257.4034, Days=10.5163`.
  `coef(fit, "sigma")` (fixed part) = `(Intercept)=3.627089`.
  This is **not** a fixed-only fit masquerading as a random-effect one — I checked
  the parameter list directly (`fit$obj$env$parList()`) and confirmed a genuine
  18-length `u_sigma` random-effect vector and a fitted `log_sd_sigma = -0.683`
  (log scale). `summary(fit)` reports the random-effect SD on the sigma linear
  predictor explicitly:
  `sd:sigma:(1 | Subject)` `estimate = 0.5057494`, `std_error = 0.1031802`,
  `scale = response`; the fixed sigma intercept back-transforms to
  `distributional-scale sigma = 37.6032` with `std_error = 4.9456`. This is a real,
  non-degenerate, well-identified fit.
- **glmmTMB fit — verifying the "syntactically accepted" claim.** The call runs
  without error (confirms Ada's claim: glmmTMB does **not** reject this formula at
  parse time), but throws a runtime warning:
  `Model convergence problem; non-positive-definite Hessian matrix. See vignette('troubleshooting')`.
  `summary(g)` reports `AIC/BIC/logLik/-2*log(L) = NA` and the dispersion random
  effect collapses to a degenerate near-zero variance component:
  `Subject (Intercept) Variance = 1.521e-12, Std.Dev. = 1.233e-06`. `g$sdr$pdHess`
  = `FALSE`.
- **Matched-scale conversion.** N/A for the comparison itself — there is nothing
  usable on the glmmTMB side to convert. (If it had converged, the conversion would
  be the same as c01's: `log(sigma)` unsquared.)
- **Verdict: BLOCKED (on the comparator side only).** Ada's original framing —
  "no package can express this" — is **false** and should not be the claim; glmmTMB
  accepts the syntax. The correct claim, now confirmed with hard evidence rather than
  assumed, is narrower: **glmmTMB accepts `dispformula = ~ (1|Subject)` but produces
  an unusable fit on this dataset** — non-PD Hessian, undefined logLik/AIC/BIC, and a
  dispersion-RE variance that collapses to ~0 (a boundary/degenerate solution), while
  drmTMB's own fit is clean (`pdHess = TRUE`, convergence 0, non-degenerate
  `sd = 0.506` on the log-sigma scale). This is a genuine frontier cell: drmTMB
  produces a well-behaved answer where glmmTMB's own machinery cannot, but that is an
  *absence of a working comparator*, not an agreement, so it does not meet the VIABLE
  bar (fit + converge + agree). Recommend Ada's write-up be corrected from "no
  package can express this" to "glmmTMB accepts the syntax but its own dispersion-RE
  fit is non-convergent/degenerate here" — the distinction the plan-of-record itself
  asked to be checked.
- **Side note (not a blocker, a gap):** `ranef(fit)` errors with
  `no applicable method for 'ranef' applied to an object of class "drmTMB"` — there
  is currently no extractor for the sigma-side random-effect predictions/BLUPs on a
  drmTMB fit; `summary(fit)` is the only place the RE-SD surfaces. Worth flagging to
  Boole/Emmy if this frontier cell is promoted, since a reader who wants
  per-Subject scale estimates has no accessor.

---

## ph19-c03 — nbinom2 count location-scale, `sigma ~ FoodTreatment` vs glmmTMB `dispformula`

- **drm_formula (as given).**
  `drmTMB(bf(mu = SiblingNegotiation ~ FoodTreatment * SexParent + (1 | Nest), sigma = ~ FoodTreatment), data = Owls, family = nbinom2())`
- **comparator_call.**
  `glmmTMB(SiblingNegotiation ~ FoodTreatment * SexParent + (1 | Nest), dispformula = ~ FoodTreatment, family = nbinom2, data = Owls)`
- **Reproducibility trap found and fixed before fitting.** Running the drm_formula
  exactly as given, in a session with `library(glmmTMB)` already attached (required
  to run the comparator), **fails**:
  ```
  Error in `drm_family_type()` at external-oracle/R/drmTMB.R:314:3:
  ! Currently supported families are `gaussian()`, ... `nbinom2()`, ...
  ```
  Cause: `glmmTMB` also exports a function called `nbinom2()`, and it masks
  `drmTMB::nbinom2()` on the search path (`environmentName(environment(nbinom2))`
  = `"glmmTMB"` after `library(glmmTMB)`). The bare `family = nbinom2()` call then
  passes glmmTMB's family object into `drmTMB()`, which correctly rejects it as
  unsupported. This is a real gotcha for anyone comparing drmTMB against glmmTMB in
  one session with the exact `drm_formula` string as written — it is not a defect in
  either package, but the candidate-cell writeup should say `family = drmTMB::nbinom2()`
  explicitly whenever glmmTMB is also loaded in the same script/session, or load
  drmTMB after glmmTMB and call `library(drmTMB)` last so it sits later on the search
  path. I re-ran with `family = drmTMB::nbinom2()` for everything below.
- **drmTMB fit (namespaced).** 1.95 s. `is_converged(fit)` = `TRUE`, `fit$sdr$pdHess`
  = `TRUE`.
  `coef(fit, "mu")` = `(Intercept)=2.03752206, FoodTreatmentSatiated=-0.63582963, SexParentMale=0.03176616, FoodTreatmentSatiated:SexParentMale=0.10467627`.
  `coef(fit, "sigma")` = `(Intercept)=-0.1887961, FoodTreatmentSatiated=0.6040870`.
- **glmmTMB fit.** `fixef(g)$cond` = `(Intercept)=2.03752367, FoodTreatmentSatiated=-0.63582849, SexParentMale=0.03176311, FoodTreatmentSatiated:SexParentMale=0.10467526`.
  `fixef(g)$disp` = `(Intercept)=0.3775933, FoodTreatmentSatiated=-1.2081753`.
  `g$sdr$pdHess` = `TRUE`.
- **Matched-scale conversion applied.** Per `158-plan-of-record.md` row `nbinom2()`:
  `theta (size) = 1/sigma^2`, so `log(theta) = -2*log(sigma)` — the exact trap the
  task brief called out (sign **and** factor of -2, unlike c01's plain gaussian row).
  `-2 * coef(fit,"sigma")` = `(Intercept)=0.3775922, FoodTreatmentSatiated=-1.208174`.
- **Side-by-side (matched scale, log-theta).**

  | coef | -2 * drmTMB sigma | glmmTMB disp | abs diff |
  | --- | --- | --- | --- |
  | (Intercept) | 0.3775922 | 0.3775933 | 1.1e-6 |
  | FoodTreatmentSatiated | -1.208174 | -1.208175 | 1e-6 |

  Mean-model (`mu`) coefficients agree to 4-5 decimals as well. Both `pdHess = TRUE`.
- **Verdict: VIABLE.** Both fit, both converge with clean Hessians, and the
  `-2*log(sigma) = log(theta)` conversion (not the naive gaussian-style
  no-transform rule) reproduces glmmTMB's dispersion coefficients to ~1e-6. This is
  exactly the trap doc 158 warns about (`158-plan-of-record.md:42-46`, discussed for
  tweedie but the same shape of error applies to any family whose comparator scale
  isn't literally `log(sigma)`) — confirmed here by showing the mismatch would be
  large (~0.57 and ~1.81 in absolute terms) if one incorrectly applied the c01
  no-transform rule instead of the `-2*` rule.

---

## Cross-cutting note for Ada/whoever assembles the final Phase 19 doc

- c01 and c03 are genuinely VIABLE matched-scale agreements on two different
  families (gaussian, nbinom2), each exercising a different conversion rule
  (identity vs `-2*`) — good coverage evidence that the scale-conversion table in
  `158-plan-of-record.md` is being read correctly, not just copied.
- c02 is not a true "no comparator exists" cell — it is a "the comparator exists,
  runs, and fails" cell. The evidence (non-PD Hessian, undefined logLik, degenerate
  ~0 variance component) is now attached; use it instead of the syntactic-rejection
  framing.
- c03 carries a real, previously-undocumented package-masking hazard
  (`glmmTMB::nbinom2` vs `drmTMB::nbinom2`) that will bite any user or test script
  that attaches both packages and calls the bare `nbinom2()` — worth a one-line
  callout in whichever doc eventually explains how to run drmTMB-vs-glmmTMB
  comparisons side by side.
