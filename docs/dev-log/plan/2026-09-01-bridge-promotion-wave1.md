# Bridge promotion — wave 1 (PREPARED; applies only after two conditions)

CONDITIONS (both required before the PR is opened):
1. drmTMB PR #1112 MERGED (non-interactive gate fix + honest controls — promoting a route that
   aborts in plain Rscript would be false).
2. DRM.jl #575 resolved (fix landed with the P1.4 gate read from expected.meta.toml) — q4 joins
   wave 1 only if its own gate passes; otherwise wave 1 ships without it.

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
