# F3 -- nlminb reports convergence short of the true optimum (issue #1130)

## 1. Reader and scope

Reader: a `drmTMB` maintainer verifying arc f3 of the parity follow-up
programme (owner decision D-213 #3) closed issue #1130 correctly and did not
touch anything outside its fence. Worked in the dedicated `wt-f3` worktree,
branch `claude/followup-f3`, off `origin/main` `281863149`. No pushes made,
no PR opened; local commits only.

Scope: `R/drmTMB.R` (the optimizer/nlminb region), `R/control.R`, a new
`tests/testthat/test-optimizer-tolerance.R`, `man/drm_control.Rd`,
`NEWS.md`, a design doc. No DRM.jl edit; no other `R/` file touched.

## 2. The problem

DRM.jl's #609 lane reported a cross-engine gap of `1.086e-5` on
`bf(y ~ x + (1 | g), sigma ~ x)` newdata `mu` at `x = 0.8`, against a `4e-6`
parity bar. The evidence in hand said DRM.jl's own optimum was robust
(sweeping its gradient tolerance moved its coefficients `1.3e-11`), and that
re-running drmTMB's `nlminb` with `rel.tol = x.tol = 1e-14` moved the R
intercept `1.05e-5`, landing within `6.4e-8` of DRM.jl -- but reporting
`nlminb` code 1 ("singular convergence").

## 3. Reproduction on this branch's base

The RED fixture, its 144-row CSV and both R oracle scripts live on DRM.jl
branch `fix/563-s10-lss-ranef-gtol` @ `744d28b3` (read-only reference; never
edited). Copied the fixture to
`tests/testthat/fixtures/s10-varying-scale.csv` and reproduced directly:

- **Default `nlminb`**: `convergence == 0` ("relative convergence (4)"), but
  the exact TMB gradient at that point (`obj$gr(opt$par)`) has 2-norm
  `3.46e-4`, max component `2.94e-4` -- not small. Predicted `mu` at
  `newdata x = 0.8` matches the R-oracle value baked into the DRM.jl test
  file to `~1e-10` (expected: the oracle *is* this unpolished default
  output).
- **Tight `nlminb` (`rel.tol = x.tol = 1e-14`)**: reports `convergence == 1`
  ("singular convergence (7)"), moves the intercept `1.053e-5`, and its
  gradient is `2.18e-4` -- still not small, and not obviously closer to a
  verified stationary point than the default.

Both numbers match the ledger's evidence (`1.05e-5` / `1.086e-5`) closely,
confirming the ~1e-5 shortfall exists on this branch's base before any
change.

## 4. Three mechanisms, measured

**(a) tighten `rel.tol`/`x.tol` globally, or (b) only for location-scale
fits.** Rejected. Both share nlminb's underlying failure mode: its stopping
rules are relative-objective/step based, not gradient based, so pushing them
tighter does not reliably converge closer to the true optimum -- on this
fixture it instead pushed nlminb into its own finite-difference noise floor,
reported as a spurious "singular convergence" code, while the gradient at
the new point was *not* smaller than at the default. Fixing this would also
require deciding, case by case, whether to trust a non-zero nlminb code that
might or might not be close to the truth (see the trap, ยง5).

**(c) a final Newton polish at the reported optimum, using the TMB gradient
and a numerical Hessian.** Chosen. `obj$gr()` is TMB's exact outer gradient.
Building a numerical Hessian by finite-differencing it
(`stats::optimHess(par, obj$fn, obj$gr)`) and taking Newton steps from
nlminb's reported optimum:

| step | step norm | gradient (max abs) |
|---|---|---|
| 0 (nlminb default) | -- | 2.94e-4 |
| 1 | 1.077e-5 | 1.79e-9 |
| 2 | 8.60e-11 | 3.46e-14 |

One step already reaches `1.79e-9`; the step-1 movement (`1.077e-5`) matches
both the reported cross-engine gap and mechanism (a)'s movement, all three
being the same shortfall seen three ways. After the polish, predicted `mu`
at `newdata x = 0.8` differs from the DRM.jl-fixture's (unpolished)
R-oracle value by `1.086e-5` -- essentially exactly the originally reported
cross-engine gap, reproduced without ever running DRM.jl. That is strong
self-consistency evidence that the polish lands where DRM.jl's own optimizer
independently verified the answer to be.

**Cost, same machine, `OPENBLAS_NUM_THREADS=1`, median of 3-5 fits:**

| fit | `newton_polish = FALSE` | `newton_polish = TRUE` |
|---|---|---|
| small Gaussian, no RE (n=60, 3 params) | 0.017 s | 0.018 s |
| location-scale (#1130 fixture, n=144, RE, 5 params) | 0.120 s | 0.136 s |
| phylogenetic random intercept (n=192, 4 fixed params) | 0.142 s | 0.120 s (noise) |

Full numbers and discussion: `docs/design/260-nlminb-newton-polish-optimizer-tolerance.md`.

**Choice: mechanism (c).** Best correctness-per-cost by a wide margin: it
fixes the cell (self-consistently, without touching DRM.jl or nlminb's own
tolerances), costs single-digit milliseconds on a location-scale fit and is
unmeasurable on a small or phylo fit, and it sidesteps the non-zero
convergence code question in (a)/(b) by deriving convergence from the
gradient it can actually verify. Usability does not bend and it does not
need to here.

## 5. The convergence-code decision (the trap)

nlminb's `convergence` code describes its own stopping criterion, not
whether the returned point is a stationary point of the TMB objective; two
directions of dishonesty were observed (ยง3): a `convergence == 0` fit that
was not actually near-stationary, and a `convergence == 1` fit that was.
**Decision:** `drm_newton_polish()` ignores nlminb's code as an input and
re-derives convergence from the polished exact gradient. If the polish
drives `max(abs(gradient))` at or below `1e-8` (default `max_iter = 3`),
`opt$convergence` is set to `0L` with an honest message identifying the
polish, regardless of what nlminb reported. If the polish cannot reach that
(non-finite Hessian/step, or the objective would get worse -- each a
`break`, never a "worse" acceptance), nlminb's original code/message are
left untouched, so a genuinely non-converged fit still triggers
`drm_warn_if_not_converged()` and shows up in `fit$optimizer_attempts` /
`check_drm()` exactly as before.

## 6. What changed

- `drm_newton_polish()` (`R/drmTMB.R`, next to `drm_optimize_with_preset_retry()`).
- Called from `drm_fit_spec()` right after `drm_optimize_with_preset_retry()`
  returns, before `drm_warn_if_not_converged()`.
- `drm_control(newton_polish = TRUE)` (`R/control.R`): opt-out, documented.
- `man/drm_control.Rd` regenerated (`devtools::document()`; discarded
  unrelated stale roxygen drift in `man/confint.drmTMB.Rd` and two new,
  unrelated `.Rd` files the same run produced for pre-existing, already-
  committed functions this task never touched).
- `tests/testthat/test-optimizer-tolerance.R` (new) and
  `tests/testthat/fixtures/s10-varying-scale.csv` (new, copied from DRM.jl
  `744d28b3`).
- `docs/design/260-nlminb-newton-polish-optimizer-tolerance.md` (new).
- `NEWS.md` entry.

## 7. Verification

- `test-optimizer-tolerance.R`: 3 `test_that()` blocks, 8 expectations, all
  pass. One named with "tolerance" and "optimum" (f3-G1); one named with
  "stationary" asserting gradient norm below `1e-6` at the reported optimum
  and that a further, much tighter polish (`grad_tol = 1e-12`) moves
  estimates by less than `1e-7` (f3-G2).
- Regression: `test-optimizer-tolerance.R`, `test-control.R`,
  `test-check-conditioning.R`, `test-start-contract.R` all pass (0
  failed/errored). Also ran `test-fit-convergence-warning.R`,
  `test-optimizer-contract.R`, `test-optimizer-escalation.R`, and
  `test-check-drm.R` (which construct or check `opt$convergence`/`message`
  most directly): all pass -- those tests exercise
  `drm_convergence_label()`/`drm_warn_if_not_converged()` on synthetic `opt`
  objects, not the real `drm_optimize_with_preset_retry()` + polish path, so
  they were not expected to move.

## 8. Not covered

- The non-Gaussian S9 cells (DRM.jl #606; Bernoulli and ordinal theta gaps
  ~1e-5) and the prediction "factors" case are suspected same-class
  shortfalls but were not re-measured here.
- Cost on high-dimensional fixed-effect surfaces (many fixed parameters,
  where `optimHess()`'s extra gradient evaluations would be more expensive)
  was not measured.
- `R/julia-bridge.R`'s `drm_julia_translate_control()` allowlist does not
  mention `newton_polish` (harmless no-op under `engine = "julia"`, which
  never touches `nlminb`/`obj$gr`/`obj$fn`); that file is out of this leaf's
  scope.

## 9. Gate summary

Ledger: `.unlazy/followup/gates/leaf-f3.md`. f3-G1 through f3-G6 checked
locally before running the ledger's own `gate-check.mjs`; see the assistant
reply for the recorded PASS lines.

## Rose pass and the defect it caught (coordinator, 2026-09-03 ~11:55 UTC)

Verdict: `scratchpad/rose/2026-09-03-rose-f3-verdict.md`. Attacks 1 and 2 SURVIVED: the polish does
guard its step (it is accepted only if the objective does not increase, so an indefinite or
ill-conditioned Hessian cannot push the fit uphill), and it does not stamp convergence on a fit that
genuinely fails, because nlminb's own code and message are left untouched when the polish cannot
reach the gradient tolerance.

Attack 3 REFUTED the branch, and the defect was real. `obj$fn()` returns TMB's value carrying a stray
`logarithm` attribute that nlminb's own `$objective` never has. Assigning it unstripped into
`opt$objective` leaked that attribute through `stored_loglik` into the object `logLik()` hands to
users, and broke `tests/testthat/test-animal-relmat-gaussian.R:1096`, a real test that this arc's own
regression sweep never ran. Fixed by stripping at both points where the value enters the polish.
Verified directly: `opt$objective` now carries no attributes, `logLik()` carries exactly
`df, nobs, estimator, class`, and that test passes (357 assertions, 0 failures).

The lesson, recorded because it generalises: a regression sweep chosen by the author of the change
tests the files the author was thinking about. Rose picked files by a property of the CODE (every
test file asserting a tolerance of 1e-6 or tighter) and found the one that mattered. After the fix a
broader 13-file sweep, including the full zero-one-beta suite, ran clean at 2054 assertions and 0
failures, and the numeric blast radius claim itself held: the single failure was the attribute, not
the shifted numbers.

## 10. CI failure and the defect it caught (coordinator, 2026-09-03 ~12:10 UTC)

CI failed rebuilding `vignettes/bivariate-nongaussian.Rmd` at chunk `penguin-intervals`:
`plot.window(): need finite 'xlim' values`. The coordinator reproduced and diagnosed it: on this
branch, `confint(fit_log, parm = "rho12", method = "profile", profile_engine = "endpoint")` returned
`conf.status == "profile_failed"` with `NA` bounds; on `main` it returns `0.2613087` to `0.4482706`;
with `drm_control(newton_polish = FALSE)` on this branch it works again.

**Mechanism.** The profile compares the free (unconstrained) optimum's nll against a series of
CONSTRAINED endpoint solves (`profile_endpoint_evaluator()`, `R/profile.R`). Only the free fit was
Newton-polished (to a gradient of `~1e-9`-`1e-14`); the constrained endpoint solve was left at
whatever `nlminb` alone reached. On the penguin `rho12` cell, one endpoint stopped with `nlminb` code
1 and a maximum absolute free-parameter gradient of `0.002724` -- comfortably above
`PROFILE_ENDPOINT_GRADIENT_TOL` (`1e-3`, issue #705) -- so
`profile_endpoint_convergence_accepted()` correctly rejected it as not actually at a constrained
minimum, and the profile crossing search had no finite endpoint to bracket.

**The guard was correct; the two sides of the comparison were not.** `PROFILE_ENDPOINT_GRADIENT_TOL`
exists precisely to catch a constrained solve that stopped short of its true minimum, because that
inflates the profiled nll and narrows the interval (#705's own rationale). Polishing only the free
side reproduces exactly that asymmetry from the other direction: the free side's nll is now lower
than an honest, equally-converged constrained side would report, which is the same bias in reverse.
**Fix: polish both sides**, not loosen the guard.

**What changed.** `drm_newton_polish()` (`R/drmTMB.R`) was refactored to take `fn`/`gr` as plain
functions (matching `obj$fn`/`obj$gr`'s signature) instead of an `obj`-shaped list, so the same
tested polish can run on `profile_endpoint_evaluator()`'s free-parameter closures (`fn_free`/
`gr_free`, `R/profile.R`) as well as the original full-parameter TMB objective. The endpoint's
`solve_from()` now polishes its `nlminb` result the same way, gated on
`object$control$newton_polish` so `drm_control(newton_polish = FALSE)` skips both sides and keeps
the comparison symmetric in that direction too. `PROFILE_ENDPOINT_GRADIENT_TOL` is untouched at
`1e-3`.

**Verified.** Penguin `rho12` endpoint profile: `lower = 0.2613087`, `upper = 0.4482706`,
`conf.status = "profile"` -- matching `main` exactly, with the default (polished) fit. With
`drm_control(newton_polish = FALSE)` the same interval is reproduced (`0.2613087`, `0.4482706`),
confirming both sides are symmetric whether polished or not. The full `test-profile-targets.R` suite
(973 assertions), `test-profile-plots.R`, `test-profile-shape-boundary.R`, and
`test-arc-d-profile-trace.R` all pass. The vignette re-renders end to end
(`rmarkdown::render("vignettes/bivariate-nongaussian.Rmd", ...)`).

**New test.** `tests/testthat/test-optimizer-tolerance.R`, "profile endpoint polish keeps the rho12
interval finite and not narrowed (#1130 CI)": fits the penguin bivariate lognormal model
(`palmerpenguins`, `skip_if_not_installed`), asserts a finite, `conf.status == "profile"` endpoint CI
for `rho12`, and asserts its width is not more than `1e-4` narrower than the width from an otherwise
identical fit with `newton_polish = FALSE` -- catching a future regression that silently re-narrows
the interval by unpolishing only one side.

**Scope note.** `R/profile.R` also has a second, structurally identical `stats::nlminb()` call inside
`ordinal_cutpoint_profile_evaluator()` (constrained ordinal-cutpoint endpoint solves, also gated by
`profile_endpoint_convergence_accepted()`), which is suspected to have the exact same asymmetry but
was **not** touched here: the coordinator's widened OWNS names "R/profile.R (the constrained endpoint
solve only)", and `profile_endpoint_evaluator()` -- the one the vignette actually exercises -- is
that solve. Fixing `ordinal_cutpoint_profile_evaluator()` the same way is a natural, low-risk
follow-up but is out of this leaf's scope; flagging it rather than fixing it silently.

**Two defects, two authors, neither caught by the change's own author.** This is the second defect in
this arc found by someone other than the engineer who wrote the fix: Rose's adversarial pass found
the stray-attribute leak (a correctness defect invisible to every numeric-tolerance assertion because
it was never a numeric difference, just an extra attribute nlminb's own `$objective` never carries);
the coordinator's CI run found the profile asymmetry (a correctness defect invisible to
`test-optimizer-tolerance.R` because that file only ever fit and inspected `drmTMB()` objects
directly, never called `confint(..., method = "profile", profile_engine = "endpoint")`). For the
regression sweep in ยง7/f3-G3 to have caught either on its own, it would have needed two properties
neither the sweep nor the author selected for: (1) coverage by *consumer*, not by *file the author
was editing* -- every public entry point that reads `opt$objective`/`opt$par` off a polished fit
(`logLik()`, `confint(method = "profile")`, `check_drm()`, `predict()`, ...), not just the optimizer
and control test files; and (2) at least one test per consumer whose assertion is sensitive to the
*kind* of change the fix makes (an attribute leaking through, or one side of a two-sided comparison
moving and not the other), not only to the *coefficient values* changing. A sweep built from
"grep every file that calls `drmTMB()`" would still have missed both; a sweep built from "list every
place downstream of `opt` that treats the free fit's polish level as an invariant" would have caught
both before either report came back.
