# After Task: Overnight Finish-Plan Wave 2 (native R/TMB correctness)

## Goal

Acting as Ada in the autonomous overnight run, close the boundary-safe native
R/TMB correctness items from the 2026-06-12 audit's HIGH list, with full
adversarial review and the engine kept honest. Branch
`shannon/overnight-audit-gaps-20260619` off `bd1f3e46`; pushes held for owner
review.

## Implemented (landed)

- **high-4 — non-positive-definite Hessian honesty** (`ce09ba51`). When
  `TMB::sdreport()` succeeds but returns `pdHess = FALSE`, the uncertainty
  state now reports status `non_pd_hessian` (not `ok`) and emits a one-time
  classed `drmTMB_non_pd_hessian` warning at fit time. `print.drmTMB`,
  `check_drm`, and `drm_standard_error_status` flow the new status through;
  Wald SE/CI were already gated on `pdHess` (`drm_has_sdreport_covariance`).
  The legacy synthetic-override path (`status "ok"` + `sdr$pdHess <- FALSE`,
  used by tests) still maps to `sdreport_non_pd_hessian`. New deterministic
  regression tests via a small `drm_sdreport_success_state()` helper.
- **high-6 — single link registry** (`f5405ffe`). `drm_link_registry()` is now
  the single source of truth for the model_type -> link mapping (all 18 fitted
  types). `drm_dpar_link()` reads it with identical behaviour; a new
  contract test asserts every `drm_family` constructor's links equal the
  registry row, so the two definitions cannot drift.
- **high-11 — figure axis labels** (`be40114f`). The figure-gallery bias panel
  mapped `aes(x = bias, y = estimand_label)` but labelled them inverted; swapped
  so the estimate-minus-truth value lands on the value axis. *(Florence should
  confirm the rendered panel; the vignette re-built OK in `devtools::check`.)*
- **Review nits** (`716c6d60`): scoped the accelerator-lint claim wording in
  design 168 (Rose), made the `coef.drmTMB` Rd `\value` regenerable via a
  roxygen `@return` (Emmy), and commented the (since-reverted) cpp site (Gauss).

## Already covered (no change needed)

- **high-3 — dense known-V indefinite `Omega`.** `validate_known_v_matrix()`
  (`R/drmTMB.R:12215`) already rejects non-PSD `V` (eigenvalue floor), and with
  `sigma = exp(.) > 0`, `Omega = V + diag(sigma^2)` is provably positive
  definite, so the MVNORM Cholesky cannot factorize an indefinite matrix. The
  rejection is tested at `test-meta-vcov.R:94` ("positive semidefinite").
  Verified, documented, no code change.

## Attempted and reverted (queued for supervised review)

- **high-2 — stable `atomic::logdet` for q>2 covariance log-determinants**
  (`ffd1ce9d`, reverted `fa7788b6`). Replacing `log(M.determinant())` with
  `atomic::logdet(M)` at the three structured-covariance sites is
  value-equivalent on well-conditioned PD matrices (Gauss compiled a standalone
  check: value diff 0, gradient diff 3.3e-16) and is strictly better at
  boundaries (it returns finite where `log(det)` hits NaN from a slightly
  negative roundoff determinant). But the spatial/phylo q4 path reaches
  near-singular covariances during optimization, so the change shifted a
  weakly-identified spatial q4 fit's convergence enough to flip
  `test-spatial-gaussian.R:573` (the `check_drm` message moved to the near-+/-1
  boundary warning). Whether that new convergence is strictly better needs a
  supervised side-by-side logLik comparison, so the guard was reverted for the
  unsupervised run. **Morning item:** adjudicate the q4 convergence change and
  decide whether the brittle message assertion should be relaxed, then re-land.

## Mathematical Contract

No likelihood, parameterization, or formula grammar changed. high-4 is purely
uncertainty reporting; high-6 reproduces the existing links exactly; high-11 is
a label swap. Public terms `sigma`, `rho12`, `mu`, `nu` unchanged.

## Checks Run

- Five-lens adversarial review (Gauss / Noether / Rose / Fisher / Emmy) of the
  whole branch diff: **0 blocking, 0 high** non-blocking; verdicts approve /
  approve / approve_with_nits / approve / approve_with_nits. Gauss compiled a
  standalone TMB equivalence check; Fisher empirically verified no non-PD fit
  gains valid Wald.
- Full `devtools::test()`: 0 failures after the high-2 revert (the only failure
  was the high-2 spatial q4 message; the 3 new non-PD warnings in
  `test-sparse-fixed-effects` / `test-zero-one-beta` are the intended honesty
  behaviour on genuinely non-PD fits, and those tests do not assert silence).
- `devtools::check(document = FALSE, error_on = "never")`: **0 errors, 0
  warnings, 0 actionable notes** (1 environment NOTE for the ~456s packaged
  test runtime; vignettes, including the figure fix, re-built OK).
- `tools::checkRd()` on the hand-synced man pages: OK. `python3
  tools/validate-mission-control.py`: pass. `git diff --check`: clean.

## Known Limitations

Native R/TMB correctness/honesty and maintainability only. No recovery,
coverage, power, q4/q8 or binomial Julia-bridge parity, release/CRAN,
non-Gaussian REML/AI-REML, or selectable `engine_control` claim. The man pages
were hand-synced (local roxygen2 7.3.2 vs repo 8.0.0) and should be regenerated
on a matching roxygen at the next opportunity.

## Next Actions

1. Supervised: adjudicate + re-land high-2 (stable q>2 logdet) with the spatial
   q4 convergence change reviewed.
2. Deferred (needs Florence/Darwin/Fisher review): the Phase-7 Gaussian-baseline
   article.
3. Julia track (separate lane, `DRM.jl` branch
   `shannon/overnight-audit-verify-20260619`): apply + CI-verify the Issue #9
   Documenter pin, then the Aqua gate and Phase 3 articles.
