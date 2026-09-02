# Bridge promotion — wave 1 (PREPARED; applies only after two conditions)

CONDITIONS (both required before the PR is opened):
1. drmTMB PR #1112 MERGED (non-interactive gate fix + honest controls — promoting a route that
   aborts in plain Rscript would be false).
2. DRM.jl #575 is FIXED (PR #579, draft; panel-verified; full suite 9203/0/0) and its bridge
   re-measure GATE-PASSED on the coef/logLik axes (1.9e-05 / 1.7e-04) — but the wave-1 bar also
   requires a same-target SE receipt, which the re-measure did not produce, and the row's own
   coverage evidence independently blocks a status move. **q4 stays OUT of wave 1** until a
   same-target SE receipt exists AND #579 merges; wave 1 ships with the four rows below once
   condition 1 (#1112 merge) fires.

PROMOTION BAR (proposed to the maintainer; his sign-off IS the promotion authority):
experimental → partial on the bridge axis requires (a) a same-target point+SE parity receipt on
the committed fixture, verified against the retained evidence file, and (b) the route running
unopted in a non-interactive session post-#1112. "partial" — NOT "covered" — because bridge-side
inference (profile/bootstrap through engine="julia") remains unqualified (G3).

## Wave-1 rows (receipt-verified to the digit — Rose audit wf_ae8e8440 + 2026-09-01 runner 11/11)

| row | receipt | source |
|---|---|---|
| base_gaussian_location_scale | SE parity 1.498725653859e-07 abs / 2.169e-06 rel (SE_PASS) | parity-se.tsv; Rose HOLDS |
| biv_gaussian_residual | SE parity 9.17587137869158e-08 abs / 1.835e-06 rel (SE_PASS) | parity-se.tsv; Rose HOLDS |
| plain_binomial_nonphylo | 1.26789215931788e-09 abs / 2.482e-08 rel, comparator hash f3e754a4… | parity-se.tsv; Rose verified exactly |
| gaussian_response_mask | include==drop equality; cross-engine |Δlogℓ|≈4e-10; live-bridge R test | Rose HOLDS (both test files verified) |

CANDIDATE (flag for maintainer, not auto-included): gaussian_phylo_mean — phylo-SD agreement
1.50e-08 verified, but its coverage narrative was the R1 repair site; promote only if the
maintainer accepts the point-parity receipt as sufficient for "partial".
DEFERRED: biv_q4_phylo_reml (gated on #575/P1.4) · phylo_count_large_p (SE agreement loosens
~100× at large p, DRM.jl#487) · phylo_gamma_beta_binomial, general_covariance_structured,
location_scale_scale (receipts not yet same-target-verified on the bridge axis) ·
cross_family_latent (no native comparator) · engine_control_surface (unsupported by design).

MECHANICS when conditions fire: fresh branch `claude/bridge-promotion-wave1` off drmTMB main →
edit r_bridge_status for the approved rows (+ claim_boundary one-liner citing this note + the
receipt) in BOTH TSVs → regenerate/sync → Rose forbidden-claim scan on the diff → DRAFT PR,
maintainer merges. Scoreboard PR #576 and the artifact update AFTER the ledger merges (derive,
never lead).
