# After-task report: Julia q2/q3/q4 SD-regression feature work (2026-11-07)

## Task goal

Make DRModels.jl fit six shapes it used to refuse and that native drmTMB
already supports, then show R-versus-Julia numerical agreement for each. The
Julia work lives on `claude/q2-final-20261107` (draft PR on DRModels.jl, not
merged). This report belongs to evidence PR #1684 and changes no parity verdict.

## Files created or changed

Julia side (DRModels.jl, branch `claude/q2-final-20261107`):

- `src/poisson.jl`, `src/negbinomial.jl`: animal and relmat intercept-plus-slope
  with one SD per coefficient (Poisson, NB2), Laplace marginal likelihood.
- `src/gaussian_ranef.jl`, `src/bridge.jl`: Gaussian animal and relmat q2.
- `src/gaussian_ordinary_q34_sd.jl`: Gaussian ordinary q2, q3, q4, exact marginal.
- `src/gaussian_sigma_sd_laplace.jl`: joint mu+sigma and structured sigma with SD formulas.
- `src/gaussian_core.jl`, `src/inference.jl`: `predict`/`predict_parameters` flags and a
  marginal simulator, added after adversarial review found crashes.
- Tests: one file per route (animal q2, NB2 relmat, q3/q4, ordinary q2, sigma Laplace,
  `test_q2_sd_simulate.jl`).

drmTMB side (this PR): evidence under
`docs/dev-log/parity-crosswalk-evidence-20261107/`, `PLAN-julia-feature-work.md`,
`PROPOSED-verdict-flips.md` (proposal only; nothing applied).

## Checks run and exact outcomes

- Per-route Julia tests pass (Poisson animal 8/8, NB2 relmat 11/11, q3/q4 30, ordinary q2 22,
  sigma 35+36, simulate 78).
- R-versus-Julia agreement, one dataset per route, ML, at the optimum: coefficients and SDs
  agree to at most 1.2e-7 in SE units and log-likelihood to at most 1e-9, across all
  routes. Tables and scripts are in the evidence directory.
- Full Julia suite on the integration tip, four shards: see "Suite result" below.

## Suite result

Final tip `f4b30ee26`, four shards. Seven files fail; each fails identically on
origin/main: `test_binomial_animal_slope_iid_sd_regression`, `test_analytic_grad`,
`test_stored_loglik_at_optimum`, `test_lane_j4_predict_numerics`, `test_qgate_jet`,
`test_sentinel_mixed_family`, `test_q4_laplace` (the last needs `fit_q4_julia.jl`, absent
on main). No new failures. Draft PR: itchyshin/DRModels.jl#1261 (not merged).

## Consistency audit

- The R side supports every route, so Julia was the gap, not R. Native R was not edited.
- Syntax follows the project rules: `sigma`, `sd(...)` formulas, unlabelled q2 means two
  independent fields (rho fixed at 0).
- `predict` is population-level only; no conditional modes are stored.

## Tests of the tests

- Each route compares the fitted marginal likelihood with an independent dense
  Laplace or MvNormal oracle at the fitted theta.
- Adversarial review (4 dimensions, 3 skeptics) found real crashes in `predict`,
  `drm_bridge(newdata)`, `simulate` and bootstrap; each now has a test.

## What did not go smoothly

- The stress design `sigma ~ 1 + (1|site)` with 200 by 200 crossed groups, n = 2400,
  fails in both Julia and R (false convergence, infinite SEs). It is recorded as a failure,
  not as agreement. Cause is undiagnosed.
- Merge conflicts in `src/bridge.jl` and `src/gaussian_ranef.jl` between parallel branches,
  resolved by hand.
- `test_q4_laplace.jl` ends the Julia process when `fit_q4_julia.jl` is missing, which
  killed one shard; its remaining files were rerun separately.

## Team learning and process improvements

Parallel worktrees per route worked; the integration merge was the costly step. Run the
shard driver with a per-file process guard next time.

## Design-doc updates

None yet. Verdict flips need a separate reviewed PR (see `PROPOSED-verdict-flips.md`).

## pkgdown/documentation updates

None.

## GitHub issue maintenance

None.

## Known limitations and next actions

- Single seed per route; this is agreement at the optimum, not calibration or coverage.
- No REML, labelled-rho forms, spatial or phylo q2, or conditional fields.
- Bridge R-coefficient names for two-target fits are hashed (`sdtarget_*`).
- Gaussian sigma-intercept stress failure above; dense engine capped at 600 latent
  coordinates; Gaussian q2 capped at 5000 rows.
- Plain `sigma ~ 1 + animal(1|id)` without an SD formula is still gap #963.
- Next: draft PR on DRModels.jl, then a separate reviewed drmTMB PR for verdict flips
  (only Gaussian ordinary q3/q4 flips outright), conditional on Julia landing and the pin moving.

## Wave 2 addendum (2026-11-08)

Julia side: draft PR itchyshin/DRModels.jl#1263, stacked on #1261, branch `claude/q2-wave2-merge-20261107`. It adds labelled correlated slopes with a free rho, phylogenetic and spatial q2, Gamma and NB2 two-field SD routes, joint mu+sigma SD Laplace for Gamma and NB2, and post-fit methods. Evidence folders `wave2-*` are under `docs/dev-log/parity-crosswalk-evidence-20261107/`.

Suite result on the merge tip: four shards. Seven files fail identically on origin/main. One extra failure, `test_skewnormal.jl`, was a test-isolation defect: two new test files used a bare `using Distributions`, which made `SkewNormal` ambiguous for later files in the same process. Fixed by importing only the needed names; the three files re-ran clean together. The whole suite was not re-run after that test-only change.

Not agreeing: Gamma crossed joint mu+sigma (different local maxima, 0.016 log-likelihood gap). Open: Poisson phylo slope-SD SE gap of 3e-3 relative; labelled phylo/spatial; mesh/SPDE; REML; NB2/Gamma structured sigma; multi-seed evidence. No parity verdict was changed; flips remain proposals in `PROPOSED-verdict-flips.md`.
