# After-task: batch 32, Julia Gaussian structured intercept SD route and NB2 dispersion restart

Date: 2026-11-02. Lane: codex/general-sd-regression (R bridge); DRModels.jl worktree `general-sd-julia` (Julia patch delivered separately, not committed). All work was done in private copies; neither worktree was edited. This note covers Route A and the NB2 fix. Route B (Poisson, NB2 and Gamma coordinate spatial intercept) is a separate R-only patch that applies after this one and extends this note.

## 1. Task goal

Find native SD-regression routes for Gaussian, Binomial/Bernoulli, Poisson, NB2 and Gamma that `engine = "julia"` refuses, and implement the most valuable small ones with a Julia change, an independent-oracle Julia test, an R bridge gate change, and a live native-versus-Julia parity block. The survey is in `b32-julia-gap-table.md` (scratchpad, 22 rows). This note covers:

- Route A: Gaussian structured intercept SD, `relmat(1 | id, K = K)`, `animal(1 | id, A = A)` and coordinate `spatial(1 | id, coords = coords)` with the matching `sd(id, level = ...) ~ z`. Julia change plus R gate change.
- Fix C (Julia, NB2): the NB2 relmat, animal and spatial SD Laplace fitter stalled on a flat part of the dispersion likelihood. It is in this patch because the already-admitted NB2 relmat route gave the wrong answer on a live parity fixture without it, and Route B depends on it.

## 2. Files created or changed

Julia patch (`b32f-julia.patch`, applies to `general-sd-julia` at `e7dbc3f79`):

- `src/gaussian_lss.jl`: `_drm_gaussian_structured_sd_slope` now takes `slope::Union{Symbol,Nothing}`; `nothing` is the structured intercept (loading 1, member `:intercept`). Slope behaviour and messages are unchanged.
- `src/gaussian_core.jl`: new router leg for one structured intercept (`animal`, `relmat` or `spatial`) with one matching SD formula, no ordinary component and no phylogenetic SD. Every other combination keeps its route and refusal.
- `src/negbinomial.jl`: `_fit_nb2_animal_sd_laplace` restarts once from `log sigma = log 0.5` when the first fit ends below `log sigma = -3.5`, and keeps the better optimum. The objective is read from the optimiser result because the closure `nll` assigns the enclosing name `value`.
- New `test/test_gaussian_structured_sd_intercept.jl` and `test/test_nb2_structured_sd_plateau_restart.jl` (found by the suite's directory discovery, so `runtests.jl` is unchanged).

R patch (`b32f-r-routeA.patch`, applies to `general-sd-regression` at `993905ff6`):

- `R/julia-bridge.R`: new shape gate `drm_julia_spatial_sd_intercept_route_admitted`; the structured payload admits the coordinate spatial intercept for Gaussian only and renames the SD target to `sd(g, relmat)`; a comment on `fitted.drmTMB_julia` records what the bridge slot is on the structured routes.
- `tests/testthat/test-julia-b32-gaussian-structured-intercept-bridge.R` (new).
- `NEWS.md`: one entry.
- This note.

Not changed: `docs/design/18-random-effect-scale-models.md`, `_pkgdown.yml`, the evidence ledger (owned by another lane; no reviewed row is claimed here).

## 3. Checks run and exact outcomes

Julia, Totoro, Julia 1.10.0, cores 374-376, one thread, one process per core, private copy only:

- New `test_gaussian_structured_sd_intercept.jl`: 106 pass (103 in the route testset, 3 in the `drm_bridge` testset), 0 fail.
- New `test_nb2_structured_sd_plateau_restart.jl`: 32 pass, 0 fail with the patch; 23 pass and 9 fail with the base `negbinomial.jl` (earlier worker and verifier runs, not repeated here).
- 16 neighbour files, all passing with the patch, 0 fail: `gaussian_structured_sd_slope` 92, `bridge_gaussian_relmat_spatial_slope_sd` 6, `gaussian_structured` 8 (three testsets of 4, 2, 2), `bridge_labelled_structured` 10, `bridge_formula_constructs` 200, `nb2_relmat_sd_regression` 26, `nb2_animal_sd_regression` 28 (19 and 9), `nb2_animal_slope_sd_regression` 15 (8 and 7), `nb2_spatial_slope_sd_regression` 15, `nb2_relmat_slope_sd_regression` 10, `negbinomial_sd_regression` 36 (19, 6, 5, 6), `nb2_animal_sd_bootstrap` 12, `nb2_animal_slope_sd_bootstrap` 13, `nb2_dispersion_seed` 13, `nb2_phylo_laplace` 10 (9 and 1), `relmat_counts_nb2` 18 (7, 2, 7, 2).

R, Mac, Julia 1.10.0 (`JULIA_HOME` set), one R process at a time, `NOT_CRAN=true`, `DRM_JL_PATH` at the private patched Julia copy:

- Live (Mac, patched private Julia copy): the Gaussian file has 6 tests and 54 expectations, 0 failed, 0 skipped (three live parity blocks, one live `fitted()` pin, one payload block, one first-appearance-order block). The b25 and b26 files (unchanged at this stage) pass live: 45 and 29 expectations, 0 failed.

R, Totoro, non-live:

- Non-live, Totoro, private copy at the Route A state: files matching `julia-b18` to `julia-b32`, `marker-slope`, `offset` and `admission-census`: 239 pass, 0 fail, 0 errors, 25 skipped (the live blocks).

Live native (TMB, `se = FALSE`) versus Julia parity, tolerances fixed beforehand (coefficients 1e-3, log-likelihood 1e-2), one fixture per row, absolute differences:

| Route | mu | sigma | sd block | logLik |
|---|---|---|---|---|
| Gaussian relmat intercept | 5.0e-13 | 1.9e-12 | 6.8e-12 | 1.4e-11 |
| Gaussian animal intercept | 2.1e-12 | 2.9e-13 | 3.7e-12 | 1.7e-12 |
| Gaussian spatial intercept | 9.7e-13 | 1.7e-13 | 3.8e-12 | 1.6e-11 |

Seed-sweep numbers from an earlier scratch run are not quoted here or in `NEWS.md`, because the sweep script is not part of this patch and cannot be rerun from it. The NB2 stall is evidenced by the two seeds (2 and 6) pinned in `test_nb2_structured_sd_plateau_restart.jl`, which fail on the base source, and by the live NB2 relmat parity fixture in the Route B patch, which failed on base Julia with a log-likelihood gap of 33.3.

## 4. Consistency audit

- Em-dash scan of the new test files, the gap table and this note: none. The NEWS entry names Gaussian and NB2 only; it has no `engine = "julia"` pairing with all, any or every family.
- `docs/dev-log/known-limitations.md` and `README.md` were not searched.
- The structured error text near `R/julia-bridge.R:11593` still says spatial intercepts are Binomial only. It is shared by many routes and was left alone; it is only reached for shapes the gates do not admit.

## 5. Tests of the tests

- Julia route test: the oracle is a dense `MvNormal` log density built in the test with no fitter code. Emulated bugs that the test must catch and does: slope loading used for an intercept (nll gap above 0.5), SD formula ignored, SD covariate sign flipped, kernel rows reversed, correlation-rescaled kernel (relmat and animal only; vacuous for the unit-diagonal spatial kernel, which the test says). Against the unpatched source it errors on all three kinds ("`sd(g)` must name the grouping").
- NB2 plateau test: fails 9 of 32 on the base source and passes 32 of 32 with the patch. Its oracle writes the NB2 pmf by hand and finds the Laplace mode with a separate optimiser run. The emulated bug is the pre-fix answer (`log sigma = -8`), which the oracle must score more than 5 units worse.
- R payload pin for shuffled named coordinates: with the `rownames(matrix) <- ...` line in `drm_julia_structured_matrix()` removed, the new first-appearance-order block fails (2 expectations in the Gaussian file); with it, it passes. This is a regression pin for the alignment path, not a fix: the audit below found no alignment bug.
- R live parity: the Gaussian blocks error against unpatched Julia (it refuses the model), and pass against patched Julia.

## 6. What did not go smoothly

- The first live count run failed on NB2 relmat. That route was already admitted before this batch, so the disagreement was in shipped behaviour. Cause: `_nb2_laplace_setup` clamps the NB2 size at `exp(8)`, so the likelihood is flat below `log sigma = -4` and LBFGS can stop there with a zero gradient.
- My first restart still failed because the closure `nll` assigns `value`, the same name the enclosing function used for the objective, so `value` always held the last `nll` call. This is the shared-box pattern already described in a comment in `gaussian_lss.jl` (#549). The fix reads `Optim.minimum`. The original function still reads `value` after finite-difference gradient calls; the difference is at the optimum to 1e-8, and I did not change it.
- A first Gaussian test asserted that the fixed intercept is within 0.6 of the truth; it is confounded with the mean of the structured field (error 1.06 on the spatial fixture). I removed that assertion and kept the slope on x.
- The first version of this batch reported `fitted()` differing from native by up to 6.0 on one Poisson spatial fixture and left it uninvestigated. It was investigated in the follow-up described next.

`fitted()` investigation (follow-up):

- Cause: `fitted()` on an `engine = "julia"` fit returns the bridge slot, which is DRModels.jl's population-level value (inverse link of `X beta`, random-effect modes at zero; `src/bridge.jl`, `_bridge_fitted_marginal`, and the comment above the `"fitted"` key in `_bridge_flatten`). Native `fitted()` is the conditional mean, which includes the modes. The Julia value equals `exp(X beta-hat)` to 1e-7 in data row order; the native value does not. Row alignment of the spatial payload and the conditional random-effect order are not involved: the bridge keeps no random-effect payload for these routes (`fit$conditional_re` is `NULL`), and the log-likelihood parity under shuffled coordinate names rules out a kernel misalignment.
- Reach: measured live on 30 groups, the same gap appears on every structured route tried, including routes merged earlier (Gaussian spatial and relmat intercepts without an SD formula, Gaussian spatial slope SD, Binomial spatial and relmat SD, Poisson relmat SD), with differences of 0.19 on the probability scale (Binomial) to 4.5 (counts) while coefficients and log-likelihood agree. It is a definition difference in `fitted()` and `residuals()`, not a coefficient or likelihood error, and not new to this batch.
- Response in this patch: no behaviour change; a comment on `fitted.drmTMB_julia`, the NEWS "not covered" sentence, and a live pin that fitted equals `X beta` in data row order. A real fix needs DRModels.jl to export the conditional modes (the Gaussian ordinary-component path already does) and the R side to rebuild the conditional mean; that is a separate change.

## 7. Team learning and process improvements

- A live parity block per already-admitted route is worth its cost: the ledger had no Julia row for Poisson, NB2 or Gamma `relmat(1 | g, K)`, and the first measurement found a 33-unit gap.
- Before calling a native-versus-engine difference a bug, decompose it: here `fitted()` equals `exp(X beta)` on the Julia side to 1e-7, which named the cause in one step.
- Any Julia closure that reassigns an enclosing variable should be renamed; read objectives from the optimiser result.
- A number in NEWS must come from a script that is in the patch; scratch sweeps are leads, not claims.

## 8. Design-doc updates

None. `docs/design/18-random-effect-scale-models.md` was not edited; the admitted routes are documented in `NEWS.md` and this note. A later doc pass should add the route to the Julia admission list.

## 9. pkgdown and documentation updates

None. No exported function, argument, or help page changed. `NEWS.md` has one entry. No pkgdown navigation change.

## 10. GitHub issue maintenance

Not checked: this was a private-copy task and no network or `gh` calls were made. No issue was commented on, opened, or closed. The `fitted()` and `residuals()` definition difference on the structured bridge routes deserves its own issue.

## 11. Known limitations and next actions

Limits of the evidence:

- One fixed fixture per route in the committed tests. No standard errors, interval coverage, calibration, or broad parity claim.
- `fitted()` and `residuals()` differ from native on every structured bridge route (section 6). `simulate()` and stored conditional `predict()` are refused. `predict(newdata)`, `summary()`, `confint()` and `vcov()` were not compared.
- Gaussian structured intercept: ML only; REML, sigma-side structure, ordinary terms next to the structured term, `Ainv`, and `Q` stay refused.
- The NB2 restart fires only when `log sigma` ends below -3.5. A fixture where both starts stall would still report the better of two stalls; it has not been observed.
- The NB2 phylogenetic SD route, Poisson `spatial(0 + x | id)`, and the precision (`Q`) input for `relmat` remain open. The gap table ranks them.

Next actions:

1. Review and apply the Julia patch, then this R patch. The R live tests need `DRM_JL_PATH` at a Julia checkout that includes the Julia patch.
2. Apply the Route B patch only after the Julia patch is merged (NB2 relmat needs the dispersion restart).
3. Open an issue for `fitted()` and `residuals()` on the structured bridge routes (export conditional modes, or document the population-level definition in `?fitted.drmTMB`).
4. Add a Julia ledger row for the new route only after review; this note claims none.

## Route B addendum (R-only patch, applies after Route A)

Route B: coordinate `spatial(1 | id, coords = coords)` with `sd(id, level = "spatial") ~ z` for Poisson, NB2 and Gamma. The bridge sends the native fixed kernel as a raw relmat `K` into the relmat intercept SD route those families already had, so there is no Julia routing change. Dependency: the Julia patch must be merged first, because the NB2 relmat route gives a wrong answer without the dispersion restart (live parity fixture, log-likelihood gap 33.3 on unpatched Julia).

Files: `R/julia-bridge.R` (the payload admits Poisson, NB2 and Gamma for the shape gate; `drm_julia_structured_matrix()` takes `spatial_sd_admitted`; one stale comment), new `tests/testthat/test-julia-b32-count-gamma-spatial-intercept-bridge.R`, `NEWS.md` (one entry), and the pin updates in `tests/testthat/test-julia-b25-gamma-nb2-slope-bridge.R` and `test-julia-b26-nb2-spatial-slope-bridge.R`: the two expectations that the Gamma and NB2 spatial intercept payloads are refused now assert the new gate instead, because that is admitted. No tolerance was loosened.

Checks (R, same setup as section 3):

- Live (Mac, patched private Julia copy): the count and Gamma file has 10 tests and 92 expectations, 0 failed, 0 skipped (six live parity blocks, three live `fitted()` pins inside the spatial blocks, gate, payload, refusal and first-appearance-order blocks); the Gaussian file 6 tests and 54 expectations; the updated b25 and b26 files 45 and 29 expectations, all 0 failed.
- Non-live, Totoro, private copy at the Route B state: all 176 `julia` test files before the last test additions, 3623 pass, 0 fail, 0 errors, 233 skipped (the live blocks); then the named files `julia-b18` to `julia-b32`, `marker-slope`, `offset` and `admission-census` again with the final tests: 275 pass, 0 fail, 0 errors, 31 skipped. Re-run of the two new files non-live on the Mac with the final tests: count and Gamma file 42 expectations, 6 skipped; Gaussian file 25 expectations, 3 skipped; 0 failed.

Live native versus Julia parity (tolerances fixed beforehand: coefficients 1e-3, log-likelihood 1e-2), absolute differences:

| Route | mu | sigma | sd block | logLik |
|---|---|---|---|---|
| Poisson spatial intercept | 2.1e-8 | none | 3.3e-8 | 2.3e-6 |
| Poisson relmat intercept | 9.1e-10 | none | 1.3e-8 | 1.8e-6 |
| NB2 spatial intercept | 8.2e-9 | 7.4e-8 | 2.0e-8 | 2.1e-6 |
| NB2 relmat intercept | 2.7e-9 | 5.5e-8 | 2.7e-8 | 1.8e-6 |
| Gamma spatial intercept | 3.8e-8 | 5.2e-8 | 6.7e-8 | 6.3e-6 |
| Gamma relmat intercept | 5.5e-8 | 4.9e-8 | 1.6e-8 | 2.7e-6 |

Admission scope: the gate reuses the Binomial spatial shape gate, so extra random effects, a modelled `sigma`, Beta, a spatial slope and a spatial intercept without an `sd` formula are refused (pinned in the non-live blocks). Poisson `spatial(0 + x | id)` stays refused.

Safe to admit: yes for the one spatial and one relmat fixture per family and the stated scope, provided the Julia patch lands first and the NEWS "not covered" list stays (no SE, coverage, calibration or broad parity claim; `fitted()` and `residuals()` are population-level, as on the earlier structured routes). The 36-fit sweep and the stall counts quoted in the first version are not claimed.
