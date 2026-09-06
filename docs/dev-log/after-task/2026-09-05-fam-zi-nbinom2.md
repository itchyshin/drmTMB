# After-task: zero-inflated NB2 through `engine = "julia"` (leaf fam-zi-nbinom2)

Date: 2026-09-05
Branch: `claude/parity-fam-zi-nbinom2` (drmTMB), `claude/parity-fam-zi-nbinom2-drmjl` (DRM.jl)
Ledger: `.unlazy/parity/gates/leaf-fam-zi-nbinom2.md`
DRM.jl pin: 430ef64cc

## 1. What the task was

Bring the `zi_nbinom2` route (native `family_type` "zi_nbinom2") up to the four
limbs of "covered" from design 168 -- implementation, focused tests, public
documentation, diagnostic evidence -- and check that DRM.jl's NB2 size
parameterisation matches drmTMB's for the ZERO-INFLATED variant specifically
rather than assuming it carries over from plain `nbinom2`.

## 2. What was actually there when the leaf started

The route already worked. `zi_nbinom2` is not a family in the bridge's registry
sense on either side: drmTMB reaches it as `family = nbinom2()` plus a `zi ~ `
formula part, DRM.jl as `NegBinomial2()` plus a keyed `zi` formula part, and
both the `nbinom2` `fe` registry row and the `zi` dpar vocabulary were already
in place. So this leaf adds **no registry row and no `_bridge_family` case**.
The plan the brief anticipated (a new family admission) did not apply; what was
missing was evidence, documentation -- and, as it turned out, a correctness fix.

## 3. The parameterisation check (the brief's explicit question)

Confirmed by reading both sources, for the zero-inflated variant:

* drmTMB `src/drm_count_kernels.h` `drm_nbinom2_log_density`:
  `alpha = exp(2 * log_sigma)`, so size = 1 / sigma^2. Mixture in
  `src/drmTMB.cpp`: `logspace_add(log_zi, log1m_zi + log_density)` at `y == 0`,
  `log1m_zi + log_density` otherwise, `zi = 1 / (1 + exp(-eta_zi))`.
* DRM.jl `src/negbinomial.jl` `_fit_negbin2_zi`: `r = exp(-2 * eta_sigma)`, so
  size = 1 / sigma^2; `p = r / (r + mu)`. Mixture:
  `_logaddexp(log_pi, log1m_pi + nb)` at `y == 0`, `log1m_pi + nb` otherwise,
  `pi = logistic(X_zi * beta_zi)`.

Identical size mapping, identical mixture algebra, identical logit link. The
1.7e-11 logLik agreement over 1800 observations is the numerical corroboration.

## 4. The defect found, and the fix

`fitted()` and `residuals()` disagreed between the two engines on the SAME
converged fit. DRM.jl's `fitted(fit)` is `means[:mu]`, which for a zero-inflated
count fit deliberately holds the count-component mean; drmTMB's `fitted()` for
`zi_nbinom2` is the unconditional mean `(1 - zi) * mu`.

Measured on drmTMB's own `tests/testthat/test-zi-nbinom2.R` fixture
(`new_zi_nbinom2_data()`, n = 1800, seed 20260613,
`bf(count ~ x + habitat, sigma ~ z, zi ~ w + habitat)`):

| quantity | before | after |
| --- | --- | --- |
| max abs coefficient difference (8 coefs) | 4.56745752330789e-13 | 4.56745752330789e-13 |
| logLik difference | 1.72803993336856e-11 | 1.72803993336856e-11 |
| max abs `fitted()` difference | **1.3665229755584** | 4.83169060316868e-13 |
| max abs `residuals()` difference | **1.3665229755584** | 4.83169060316868e-13 |

Fixed on the DRM.jl bridge boundary with `_bridge_fitted_marginal`
(`src/bridge.jl`), so DRM.jl's own `fitted`, `residuals`, `simulate`,
`marginal_parameters` and dpar table keep the component mean they are built on
and only drmTMB's contract surface changes. Selection is `haskey(fit.scales,
:zi)`, which is true for exactly the two zero-inflated count fits and false for
hurdle fits (`scales[:hu]`). The same repair therefore also covers
`zi_poisson`, whose drmTMB mean is `(1 - zi) * mu` as well.

A stale docstring sentence in `_bridge_dpars` ("DRM.jl has no zi/hurdle
families, the other place this trap lives") was false in the direction that
hides exactly this bug; it is replaced with the correct account.

## 5. Evidence measured in this run

All at DRM.jl pin 430ef64cc plus this PR's patch, drmTMB 0.7.0.

* Coefficient + logLik, via `tools/parity_numeric.R` at tol 1e-4:
  `PARITY_PASS`, max|d| 4.56745752330789e-13; logLik -2886.32364387789 (tmb) vs
  -2886.32364387791 (julia).
* Wald SE, via `tools/parity_se.R`'s own `compare_cell` at rtol 1e-3:
  `SE_PASS`, max abs 1.95130729893633e-07, max rel 1.60915216580772e-06 over 8
  SEs. Negative control (`se_julia[1] * 1.10`) -> `SE_FAIL` ->
  `NEGATIVE_CONTROL_OK`, max rel 0.0909093684151215.
  `drmtmb_code_hash` ff7ee8388340220c0c87828c6159ea46682f7b12ddd9b9d6a2c951f03040eb14.
  Rows appended to the pin clone's `docs/dev-log/evidence/parity-fixtures.tsv`
  (`zi_nbinom2_locscale`) and `parity-se.tsv` (`se_zi_nbinom2_locscale` plus its
  negative control).
* `tests/testthat/test-julia-family-zi_nbinom2.R`: FAIL=0 ERR=0 SKIP=0 PASS=41
  live at the pin+patch.
* `test/test_bridge_zi_marginal_mean.jl`: 24/24 pass at the pin+patch.
* Collateral (offline): `test-julia-bridge.R` 139 pass / 2 live skips,
  `test-julia-gate-vs-engine.R` 144 pass, `test-julia-family-registry.R` 22
  pass, native `test-zi-nbinom2.R` 59 pass; 0 failures anywhere.

## 6. Red controls

* **Julia side.** Replaced the patched `src/bridge.jl` with the pristine pin's
  and re-ran the new Julia test: 17 pass / 4 fail / 1 error (the helper is
  `UndefVarError: _bridge_fitted_marginal not defined`; the two zi testsets
  fail on the `(1 - pi) * mu` assertions). Restored byte-identically -- sha256
  7c32b774fe4a314ccbb168dce024a2078c0a029c87b33865b3bd0fd12e3aa96f before and
  after -- and back to 24/24.
* **R side.** Ran the new R test file against the UNPATCHED pin: exactly three
  failures, all in the `fitted()`/`residuals()` block, each reading
  `1.36652298 >= 0.00000001`; every other assertion (parity, refusals, the two
  pinned known gaps) stayed green. Nothing in either repository was modified to
  produce this control.

## 7. NOT COVERED

* Random effects, phylogenetic terms and structured markers on this route.
  DRM.jl refuses `zi` with a random effect itself; that refusal is pinned, not
  lifted.
* Interval coverage. Wald SE agreement is not coverage; no profile or bootstrap
  interval was measured on this route.
* `predict(fit, dpar = "zi")` on a Julia-engine fit still aborts. The bridge
  tags the fit `"nbinom2"`, so `drm_dpar_link()` finds no `zi` row -- even
  though a `zi_nbinom2` row with `zi = "logit"` sits beside it. Pinned as a
  known gap by the test file, not fixed: the repair means making the Julia
  route's `model_type` zi-aware, and that same string is passed straight to
  DRM.jl's `_bridge_family` by `drm_julia_call_fixef_inference()`, so it needs a
  `_bridge_family` alias too and belongs in its own PR.
* `sigma()` on a Julia-engine zi fit returns a list (`sigma`, `zi`) where the
  native engine returns a numeric vector. Loud rather than silent, and a fix
  would touch every family whose DRM.jl `scales` carry an extra key.
* The capability-comparison row `zi_nbinom2` stays at `r_bridge_status`
  "partial". `drm_julia_capability_comparison()` lives in `R/julia-bridge.R`,
  outside this leaf's file set; promoting it (and citing the receipts above) is
  the integrator's call.
* The DRM.jl change was measured at the pin plus the patch, not on DRM.jl
  `origin/main`, which has moved past the pin. The branch itself is cut from
  `origin/main` and the patch applies there; DRM.jl's full suite was not run on
  `origin/main` (no committed Manifest in the worktree).

## 8. Files changed

drmTMB (`claude/parity-fam-zi-nbinom2`):
`tests/testthat/test-julia-family-zi_nbinom2.R` (new),
`docs/design/258-coefficient-naming-contract.md` (section 8.10),
`NEWS.md` (one entry), this report.

DRM.jl (`claude/parity-fam-zi-nbinom2-drmjl`):
`src/bridge.jl` (`_bridge_fitted_marginal`, the two `out` keys that call it, and
the false `_bridge_dpars` docstring sentence),
`test/test_bridge_zi_marginal_mean.jl` (new), `test/runtests.jl` (one include).

Shared evidence (uncommitted, in the pin clone by the programme's convention):
two appended rows in `docs/dev-log/evidence/parity-fixtures.tsv` and
`parity-se.tsv`.

## 9. Order

The DRM.jl PR must merge first: the drmTMB test file's `fitted()`/`residuals()`
block is red against a DRM.jl without `_bridge_fitted_marginal` -- which is the
point of it.
