# P1.4 promotion re-measure — DRM.jl#575 exact REML gradient fix

## Setup
- Bridge pointed at fixed worktree via `Sys.setenv(DRM_JL_PATH = ".../scratchpad/wt-exact-grad")`, branch `feat/575-exact-reml-gradient` @ 35201b00, set BEFORE `library(devtools)`/`load_all`.
- Julia project instantiated: `julia --project=<worktree> -e 'using Pkg; Pkg.instantiate()'` (silent success).
- Script: `.../scratchpad/q4-fixture-bridge-parity-v3.R`, identical to v2 (default TMB control, warm Julia throwaway fit on head(dat,60), durable capture) except the DRM_JL_PATH redirect.
- Fixture: `/private/tmp/DRMjl-bridge-route-diagnostic/test/parity/q4-reml/biv-q4-phylo-reml` (biv_gaussian, REML=TRUE, phylo q4 layout).

## Result line (verbatim)
```
Q4_FIXTURE_BRIDGE_PARITY_V3 conv_tmb=TRUE conv_julia=TRUE ll_delta=1.9169825e-05 max_coef_delta=0.00016828466 tmb_s=0.928 julia_s=0.876 n_common=7 tmb_conv_msg=NA
```

Wall times: TMB fit 0.928 s, Julia fit 0.876 s (warm). Total script run ~ well under budget.

## Recorded promotion tolerance (quoted verbatim from expected.toml [tol], re-derived 2026-08-25 post-#477)
```
[tol]
atol_loglik = 0.03
atol_coef = 0.0251
rtol_coef = 0.10
```
(atol_coef/rtol_coef = 10% of drmTMB's own Wald SEs on this fixture's data; atol_loglik = cross-optimum reml_ll spread from independently g-converged restarts, per expected.meta.toml reml_restriction_note.)

## Verdict
- ll_delta = 1.917e-05 vs atol_loglik = 0.03 → PASS (≈1560x margin)
- max_coef_delta = 1.683e-04 vs atol_coef = 0.0251 → PASS (≈149x margin)
- Both engines converged (conv_tmb=TRUE, conv_julia=TRUE), n_common=7 coefficients compared.

**GATE-PASS**

## Notes
- A Julia extension precompile warning (`LogExpFunctionsInverseFunctionsExt`) appeared during first-call setup but was non-fatal — the run proceeded to a valid completed fit and result line.
- No source edits made; no pushes/posts.
