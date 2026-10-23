# #575 exact REML gradient — gate progress log

- G1 (derivation, no code): DONE. Alignment note at
  `docs/src/developer-notes/reml-q4-exact-gradient.md` in worktree
  `scratchpad/wt-exact-grad` (branch `feat/575-exact-reml-gradient`).
  Key result: the implemented REML objective collapses to
  `L_REML = −J(ẑ;φ) − ½logdet𝓗 + ½logdetP` with `z = (u,β)` and
  `𝓗 = [[A,B],[B',D]]`, i.e. the SAME Laplace form as the ML objective in
  `fit_q4_sparse_tmb.jl`. So the exact O(p) ML gradient machinery transfers
  term-by-term with `Vblk → Ω_i = Vsel_blk + G_i S⁻¹ G_iᵀ`. 9-row alignment
  table with per-term code locations and parameterisations.

- G2 (exact gradient, test-first): DONE / GREEN.
  RED commit 7a05a7ca (test), GREEN commit 12f758ec (impl).
  `DRM.reml_nll_and_exact_grad` / `DRM.reml_nll_exact` in src/reml_q4.jl.
  Exact vs step-scanned central difference on biv-q4-phylo-reml (max abs err):
    ML-scale start   2.82e-8   (rel 2.41e-9)
    DRM.jl optimum   6.14e-8
    TMB fitted point 3.18e-8
  ‖∇_z J‖ certified < 1e-8 at all three (joint Newton reaches ~5e-13).
  SIDE FINDING (fixed in the REML path, flagged for the ML path): at an exactly
  diagonal Λ — fit_q4_reml's own 0.3I default warm start — `prior_precision`
  drops zeros, so H_uu's cross-axis entries are STRUCTURALLY absent and the
  Takahashi selected inverse cannot supply the logdet trace. Two lc gradient
  components were wrong by 0.037 and 13.70 there. `_reml_prior_precision` stores
  the full 4×4 axis block. `marginal_and_exact_grad` shares the degeneracy.

- G3 (certification + wiring): DONE. commit f5f8a600.
  fg! now uses reml_nll_and_exact_grad; inner flag = ‖∇_z J‖ < 1e-6; final
  evaluation through the same exact path; exact-gradient polish at 10× tighter
  g_tol (adopt only if converged, no worse objective, strictly better g_residual,
  caches restored on rejection).
  Measured (drm() engine inputs, defaults, g_tol=1e-3, iterations=300):
    cold start       reml_loglik -219.614005  converged=true  g_residual 9.47e-5
    warm at phi_TMB  reml_loglik -219.614006  converged=true  g_residual 8.93e-5
    baseline (FD)    -219.630231 ;  drmTMB -219.613986 ; floor_ll -219.6206
  Both routes reach the SAME point → the reported basin-dependence was an
  artefact of FD/mode noise. Next: G4 no-regression + flip @test_broken.

- G4 (no-regression + target): DONE. commit 35201b00. Branch pushed.
  test_575_q4_optimum.jl @test_broken -> @test, PASSES.
  All listed no-regression files green (see exact-grad-summary.md).
