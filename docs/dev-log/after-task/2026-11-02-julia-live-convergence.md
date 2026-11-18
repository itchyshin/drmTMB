# After-task report: two live Julia convergence failures (2026-11-02)

## 1. Goal

Two live Julia tests failed one convergence expectation each, identically at
`a63b56e6e` and `1d23c75da`: `tests/testthat/test-julia-biv-q2-reml.R:259`
(bivariate phylo q2 REML) and `tests/testthat/test-julia-tmb-parity.R:661`
(Route A Gaussian phylo-mean parity). The task was to find which engine fails,
why, and since when, and to fix each where the fault lives without loosening
any tolerance or assertion.

## 2. Findings

Neither failure is a Julia engine regression. DRModels.jl `5ac051eed` was not
changed and no Julia patch is needed.

**Parity test (line 661): fixture fault, started 2026-10-17.** The fixture drew
the species effect as iid `N(0, 0.45^2)`, but the model fits it with the
phylogenetic correlation matrix. With one observation per tip an iid species
effect cannot be told apart from residual noise, so the phylogenetic SD
collapsed to about 1e-5 in both engines (TMB 6.7e-6, Julia 1.2e-5, identical
log-likelihood -13.26828). That is below the 1e-4 boundary rule in the shared
`convergence_status()` contract, so both engines return "boundary" and
`is_converged()` is FALSE for the TMB fit and the Julia fit. The direct bridge
call still reports `converged = TRUE`, which is why only the three-way `&&`
failed. `4deb47493` (2026-10-17, "share three-valued convergence_status")
changed `is_converged()` from "converged or boundary" to converged-only; before
that the boundary fit counted as converged. The fixture and test were
unchanged since 2026-09-18.

**q2 REML test (line 259): the TMB engine, not Julia.** Julia converges on the
fixture (status "converged", logLik -21.31416). The TMB fit stops with nlminb
code 1, "false convergence (8)", at a point whose exact TMB gradient is 2.7e-8
with a positive-definite Hessian. The same result came from the default,
careful and robust presets, because all three start from the same point, so the
preset ladder cannot clear it. Restarting nlminb from its own endpoint returns
code 0 at the identical point and objective (21.314204298305). Tightening the
TMB inner tolerances changed nothing (gradients identical to 8 digits), so the
cause is nlminb's step-acceptance test at a stationary point, not inner-solver
noise. The Newton polish (grad tolerance 1e-8) cannot help: finite-difference
Hessian steps from this point raise the gradient to 1e-6 to 1e-5. Julia and
TMB agree on the optimum to about 1e-5 in coefficients. This is an
optimizer-control issue in drmTMB. I did not bisect which commit first made
nlminb stop with code 8 here; the test last changed 2026-09-06 and the live
suite is skipped on Totoro and CI, so the date is not known.

## 3. Changes

- `R/drmTMB.R`: new `drm_restart_false_convergence()`, called once after the
  preset ladder and Newton polish. If the selected nlminb result is code 1 with
  a "false convergence" message, it restarts nlminb once from that endpoint
  with the same control, and accepts the restart only when nlminb reports code
  0, the objective did not increase, and the exact gradient is at most 1e-6.
  No `rel.tol`, `x.tol` or other criterion is changed. A result with a larger
  gradient stays as nlminb reported it, and non-nlminb optimizers are skipped.
  The attempts table and selected record carry the new message.
- `tests/testthat/test-julia-tmb-parity.R`: Route A species effect is now drawn
  from `MVN(0, 0.45^2 * cor(tree))`. Seed, n, sigma and every assertion are
  unchanged. The fit now has sd_phylo about 0.24 and status "converged".
- `tests/testthat/test-optimizer-false-convergence-restart.R`: unit tests for
  the helper (accepts a clean restart; refuses large gradient, other messages,
  other optimizers) and a TMB-only test of the q2 phylo REML fit. That fit test
  fails when the helper is mocked out and passes with it.

## 4. Verification

- Live Mac, DRModels.jl `5ac051eed`, one R process each: `test-julia-tmb-parity.R`
  all pass; `test-julia-biv-q2-reml.R` all pass.
- New test file passes (11 expectations).
- Neighbouring files (TMB only, NOT_CRAN=true): the optimizer, convergence, multi-start, newton-polish, profile-targets, structured-re-conversion, objective-at, offset-families, missing-predictor-beta-binomial files and about 55 phase18 files reached before the run was cut had 0 failures and 0 errors. The full suite was not run.

## 5. What this does not cover

- The gradient gate of 1e-6 is my choice, 100 times the polish tolerance and 36
  times the observed 2.7e-8. It is explicit and tested, but it is a threshold.
- Other fixtures that stop with false convergence at larger gradients are
  unchanged.
- The commit that first made nlminb report code 8 on the q2 phylo fixture was
  not identified.
- The helper lives at the single fit site; profile-endpoint refits do not use it.

## 6. Next

Review the 1e-6 gate. Run the full suite on Totoro before merging, since a
fit that used to warn about non-convergence may now report converged.
