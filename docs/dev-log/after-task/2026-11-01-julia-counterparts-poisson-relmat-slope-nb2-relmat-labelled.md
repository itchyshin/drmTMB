# After-task note: Julia counterparts, batch 7 (2026-11-01)

## Scope
Julia work in the paired DRM.jl worktree (general-sd-julia, branch codex/general-sd-regression, HEAD 70dbf564e). Nothing was committed there, and nothing in the drmTMB worktree changed apart from this note.

## What changed in the Julia worktree
1. src/bridge.jl: labelled-matrix alignment from DRM.jl commit 722b25f40 (K_labels, A_labels, structured_group). Applied by hand because the file already carried other uncommitted hunks.
2. Poisson relmat slope-only read side: widened the relmat-slope admission from Binomial to Binomial or Poisson in src/gaussian_core.jl (two places) and src/inference.jl (one place), and let the Poisson structured marginal simulator parse and match a relmat slope. This lets predict_parameters, predict(type = :link) and the marginal simulator (hence bootstrap_result) accept a fitted Poisson relmat slope fit.
3. test/test_poisson_relmat_slope_sd_regression.jl: added read-side assertions (predict_parameters SD equals fitted SD, simulator equals an independent oracle draw, one-replicate bootstrap).

## Evidence (Julia 1.10.12 on Totoro, one thread, scratch copy ~/hsq_work/b7-julia)
- test_bridge_labelled_structured.jl (scratch copy of the 722b25f40 test): 10 of 10 pass.
- test_nb2_relmat_sd_regression.jl: 26 of 26 pass.
- test_poisson_relmat_slope_sd_regression.jl: 28 of 28 pass.
- test_poisson_animal_slope_sd_regression.jl (regression guard for the widened gates): 25 of 25 pass.
- test_binomial_relmat_slope_sd_regression.jl (regression guard): 11 of 11 and 12 of 12 pass.
- Mac, live R bridge: test-julia-poisson-animal-slope-ainv-pedigree-sd-bridge.R, Julia 1.10.0 via JULIA_HOME, DRM_JL_PATH set to the candidate: 2 live tests ran, no failures. A first attempt failed only because bash -l reset PATH and JuliaCall could not find Julia; setting JULIA_HOME fixed it (environment, not model evidence).

## Not covered
- No full Julia test suite run, and no run of test/test_bridge.jl or other bridge files beyond the labelled test.
- Poisson relmat slope has no R bridge admission yet (src/bridge.jl around line 2081 is Binomial-only), so there is no R-to-Julia test for it.
- The labelled-alignment test is not yet in the worktree (only src/bridge.jl was ported, as instructed).
- NB2 relmat uses K only; native NB2 spatial uses coordinates, so there is no coordinate-spatial parity.
- Single fixtures; no calibration, parity or support claim. Totoro cannot run the R bridge, so bridge evidence is Mac-only.
- The Julia worktree is entangled and cannot be committed slice by slice; see the scratchpad file batch7-julia-commit-plan.md.
