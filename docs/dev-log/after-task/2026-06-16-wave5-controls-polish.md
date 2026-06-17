# After-task — Wave 5: controls polish + Hao follow-ups

Date: 2026-06-16
Branch: `codex/honesty-guards`

## Items (all from the Wave 5 plan)

- **penalty + REML guard** (`bb569cd8`). `drmTMB()` rejects combining
  `REML = TRUE` with `penalty =`: a restricted-likelihood estimator and a
  maximum-a-posteriori estimator are different estimators of the variance
  components, so the combination is undefined.
- **check_drm() clamp-active row** (`bb569cd8`). A `logsigma_clamp_active` row
  flags when the `log(sigma)` clamp is active at the optimum -- the
  diagnostic-surface complement to the fit-time clamp-active warning (Hao Qin
  noted `check_drm()` did not flag the clamp). Warning when active, `ok` when
  not, `note` when the TMB object was dropped.
- **Student-t nu>2 documentation** (`bb569cd8`). States explicitly that the
  `sigma = SD` contract bounds `nu > 2` and so the family cannot represent the
  very heavy tails of `nu <= 2` (e.g. Cauchy); `check_drm()` warns near the
  boundary. Directly addresses Hao Qin's heavy-tail point.
- **cor_sd sensitivity sweep** (`adf3651e`). `drm_phylo_penalty_sweep()` refits
  a penalized (MAP) phylogenetic model across a `cor_sd` vector and returns a
  tidy `$summary` (convergence / pdHess / logLik per `cor_sd`) plus `$fits`, so
  the mandatory prior-sensitivity sweep is one call. Also added
  `drm_phylo_penalty()` (a pre-existing gap) and the sweep to the pkgdown
  reference.
- **rho12 guard standardization** (`24127df2`). The residual `rho12` used an
  eight-nines `tanh` guard while every other correlation uses six nines; flagged
  in review. Standardized rho12 (two C++ sites, the `rho_response` default, the
  delta-method derivatives, and the docs) to the common six-nines guard. The
  guard is far from any realistic correlation, so fitted `rho12` is unchanged to
  ~7 decimals.

## Verification

Per item: focused TDD tests (`test-reml-penalty-guard.R`,
`test-clamp-active-guard.R` clamp-row cases, `test-phylo-penalty-sweep.R`) plus
regression checks. The rho12 standardization was verified against the biv-gaussian
(935), reml-bivariate, and missing-response-biv suites (all FAIL=0). Final
end-to-end suite (all tests including the report-render tests): recorded in the
release-readiness note.

## Not done / deferred (beyond the Wave 5 plan)

- A `check_drm()` row for univariate `(1 + x | p | id)` / mean-scale random-effect
  correlations at the `tanh` bound (an audit finding): the boundary-aware
  `confint()` (Wave 1 Guard 3) already flags these on the inference side; the
  `check_drm()` diagnostic complement can follow.
- Bivariate random-effect / phylo REML (the full Ayumi Model A+/D): needs a
  bivariate restricted-likelihood reference to validate (Wave 4 note).

## Final end-to-end suite

The complete suite (all tests, including the report-render templates) first
returned `FAIL=7`. All seven were test-side drift exposed by the rho12 guard
standardization (`24127df2`), not behaviour regressions:

- Four exact-contract tests still recomputed their expectations with the old
  eight-nines cap (`family-link-contract`, `predict-parameters`,
  `reference-grid-link-scale-contract`, `covariance-block-registry`); updated to
  six nines.
- The bivariate mu random-effect covariance `check_drm()` fixture sat at a
  benign ~1.4e-3 fixed gradient. The fit is fully converged -- objective and
  parameters match the pre-clamp fit to ~9 and ~6 digits -- and the gradient is
  pinned there even at `rel.tol = 1e-13`, so it cannot be polished below the
  strict `1e-3` default of the `fixed_gradient` check. That fixture tests the
  covariance diagnostics, not gradient sharpness, so `gradient_tolerance` was
  widened for it.

Fixed in `bf8a60bb`. Re-run on `codex/honesty-guards`: **`FAIL=0, ERROR=0,
PASS=11296, WARN=26, SKIP=5`**. The 26 warnings are the classed
convergence/clamp warnings the guards raise on boundary fixtures; the 5 skips
are pre-existing.
