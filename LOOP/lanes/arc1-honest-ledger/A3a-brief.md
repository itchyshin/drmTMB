# A3a brief (ready to dispatch when R/julia-bridge.R is free)

Dispatch to the S1a builder (tmb_engineer, Sonnet, effort high) or a fresh one with this text. Gates: `.unlazy/arc1-honest-ledger/gates/leaf-A3a.md` (G1-G6).

Scope, all in `R/julia-bridge.R` and its generated TSVs; every refusal fires in R before Julia boots, in drmTMB's own wording, naming the working alternative:
1. q4 block-diagonal phylo (`phylo(1|p|sp)` on means, `phylo(1|ps|sp)` on scales): `drm_julia_biv_phylo_dimension()` must read the marker labels, not only the dpar set; refuse the block-diagonal layout (measured DIFFERENT_MODEL: df 13 native vs 17 bridge, `docs/dev-log/evidence/julia-r-parity/arc1-model-identity/sweep.tsv`). Dense q4 stays admitted with its receipt unchanged (D-273: both paths tested).
2. `truncated_nbinom2()` + `hu`: refuse, pointing to `nbinom2()` + `hu` (the hurdle route the bridge supports).
3. REML random slope: refuse the `(1 + x | g)` REML case in R instead of letting DRModels' ArgumentError pass through (matrix row "Gaussian random slope (mean)").
4. The 21 late Julia failures in the sweep (REFUSED rows): ordinary `(1|g)` / `(1+x|g)` on non-Gaussian families (bridge coefficient-label errors), bivariate q4 with ordinary random effects, non-Gaussian `sigma` random effects, multi-term `sigma` random effects, binomial non-mean random effects. One gate per group.
5. Gate rows in `drm_julia_intentional_gates()` for every census REFUSE_UNGATED key (39 keys, grouped by message); regenerate `inst/extdata/julia-gates.tsv` and the dashboard copy with `tools/write-julia-gate-registry.R`.
6. T1-T4, T6 refusals where a user route exists (AGHQ, VA/ELBO, heritability/icc/repeatability on `drmTMB_julia` fits, `anova()` LRT, Gaussian phylo RI + slope); where none exists or a refusal already fires, record which in the test file (A3b signs the fences).
7. Tests: `tests/testthat/test-julia-bridge-refusals-arc1.R`, mock-driven, no Julia; assert the boot is not reached for each refusal; register in the source-tree manifest if it reads `tools/`.
8. Re-run `tools/julia-admission-census.R`; update the census test's expected lists to match exactly (EXPECTED_UNGATED_REFUSALS empty).
Do not touch `R/drmTMB.R`, `R/methods.R` (except if the Cursor lane has released it and a refusal truly belongs there), or the tip receipt (regenerated LAST by the conductor after A3b).
