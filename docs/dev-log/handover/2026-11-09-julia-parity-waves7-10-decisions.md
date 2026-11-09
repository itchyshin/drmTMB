# R-Julia parity, waves 7 to 10: decisions and state

Reader: Shinichi, or the next session continuing the parity lane.

## State

Julia (DRModels.jl) work is a stack of nine draft pull requests, none merged by us. Review in this order: #1261, #1263, #1264, #1266, #1267, #1268, #1270, #1271, #1272. Heads at the last check: f4b30ee26, 9c9572e3a, 04581709d, e5ae24539, bd6df5026, fd5d6c0dc, e7e0e81a5, f6417475b, 0bfcde2bb.

Full suite on the exact tips of #1270, #1271 and #1272: Julia 1.10.12 passes every file; Julia 1.12.7 fails only five files that also fail on origin/main (test_stored_loglik_at_optimum, test_binomial_spatial_sd_regression, test_locscale_raw_k_regression, test_relmat_raw_k_regression, test_reml_q4_missing_response).

drmTMB side: draft PR #1687 (R warns on a failed Julia fit, prints FAILED FIT; not run against the real Julia bridge) and evidence PR #1684 (every verdict flip is still PROPOSED).

## Decisions made without asking, and why

1. Censored routes stay refused. drmTMB has no censored likelihood to match (issue 1455), so there is nothing to agree with.
2. The Gamma restart extension to the single-field phylo/spatial route and NB2 two-field was not shipped. Evidence of a lower mode there is thin.
3. Default `q4_f_reltol` stays 1e-7. It stops up to about 1e-3 log-likelihood short on flat q=4 ridges; users who need R-level agreement pass 1e-12 (cost about 1.8x median).
4. Binomial q=1 spatial stays on the old mean-distance kernel. drmTMB has no Binomial spatial route, so there is no R target. It is inconsistent with Binomial q=2 inside Julia; switching is a two-line change if wanted.
5. The field-1 restart patch (`candidate_field1_starts.patch` under docs/dev-log/lowermode-check-20261108/) is not applied. It changed no fit on 150 seeds.
6. Binomial independent sd-z restarts (#1272) always run when an SD formula has a covariate. Median cost about 7.9x on those fits, above the 5x line I set. Kept because the usual boundary trigger left both known cells about 2 nats below the best optimum, and 40 fresh seeds went from 5 and 12 bad fits to 0. Intercept-only SD fits pay nothing. One-line fallback: `force = false`.
7. Parity-matrix verdicts do not flip in any of these PRs. Flips need a separate reviewed drmTMB PR after Julia merges and the pin moves.
8. Remote Control was switched off on my own finished sublanes so they could be archived, because you asked for them to be closed.

## Known gaps

- 145 Julia-behind refusal cells at wave 8 (gap map, 3008 cells); wave 9 closed some, not re-measured.
- Two Binomial independent-slope cells where Julia stopped below a point its own objective scores higher are fixed by #1272 on the two reproduction cells and 40 fresh seeds; correlated blocks, q=4 and non-logit links were not measured.
- The BLUP NaN path is unit-tested on the helper only.
- Shard load estimates in test/shard_assign_N16.txt predate waves 9 and 10.
- Agreement checks use small committed datasets, one per route, Julia 1.10 for the gap map.

## Cleanup left for you

Totoro: `~/drm_w8final_20261109`, `/home/snakagaw/drm_w9_20261109`, `/home/snakagaw/drm_w9v_20261109`, `~/drm_w10_20261109`. Older stray processes (a julia ncores_new.jl, test_bootstrap_sigma_r.jl, three `while :; do :; done` loops, 4 to 6 days old) are not ours and were left alone.
