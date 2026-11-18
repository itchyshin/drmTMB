# Ordinary SD target resolver review

Read-only review of `R/random-effect-targets.R` and `tests/testthat/test-random-effect-targets.R`; no fits or tests were run.

## Findings

**The earlier bivariate-registry blocker is resolved.** `drm_ordinary_sd_target_members()` now accepts dpars aligned with source terms and validates each expanded axis against the combined registry (`R/random-effect-targets.R:11–25, 30–60`). The added fixture uses `build_biv_mu_random_structure()` and verifies mixed endpoint order and global latent/group positions; the alias assertions select the correct `mu1`/`mu2` coefficient (`tests/testthat/test-random-effect-targets.R:25–40, 110–120`). This matches the existing bivariate registry, which expands and records the endpoint dpar per axis (`R/drmTMB.R:17090–17114, 17190–17286`).

The global latent-position to observation-group mapping remains coherent: `latent_pos0` comes from `term_id0`, and `obs_group_index0` matches each observation's global `index0` into that local position set (`R/random-effect-targets.R:38–44`). Parsed coefficients are checked against `re$coef_names` and their within-block position metadata. Pair validation now checks that a paired member precedes the current latent positions, all paired members point to one other axis, and the pairing preserves group order and levels (`:62–77`). Tests exercise independent same-group slopes, a correlated intercept/slope block, a corrupted group pair index, and a labelled bivariate q4 registry (`tests/testthat/test-random-effect-targets.R:123–153`). These checks fit the current representations: independent slopes have no pair index, a q2 correlated block has an explicit slope-to-intercept map, and the q4 cross-endpoint covariance remains outside `re_pair_index0` while its four coefficient members retain axis/dpar identity.

One integration-hardening gap remains: pair validation does not verify that the paired axis has the expected `group_names`/`covariance_labels` or a compatible `re_cor_id0`; it currently relies on the current builder's pair-index construction plus equal group-level vectors. A deliberately corrupted pair pointing to another axis with the same levels could pass those checks. Add such negative metadata tests (or tighten the invariant) before a model builder relies on this resolver as its sole structural validation. This is not a blocker for the current unintegrated identity prototype.

Same-group candidate ambiguity is now tested across distinct labelled endpoint blocks and within one dpar, including explicit block selection (`tests/testthat/test-random-effect-targets.R:123–136`). Empty terms now fail closed when the registry is nonempty, while a genuinely empty registry returns an empty candidate list (`R/random-effect-targets.R:3–10`; tests at `:155–160`). Further malformed-shape cases such as missing index matrices or a wrong correlation id would strengthen the internal contract before integration.

## Scope

This module is an identity resolver only; it does not admit models or change likelihoods. The revised tests support identity resolution against ordinary univariate and real combined bivariate registries, including q2 and q4 member layouts. This review does not certify integration into family builders, downstream likelihood use, or the broader random-effect SD programme. No fits or tests were run during this review; the reported green test results are from the parent agent.

## Re-review of pair-validation hardening

The earlier pair-metadata concern is resolved for this internal resolver. The current code validates that each paired member points backward to a single distinct coefficient axis, that the pair indices enumerate the paired axis in order, and that both axes have matching group factor/name and covariance-block label. It also requires one in-range current correlation id and rejects incompatible paired correlation-id metadata (`R/random-effect-targets.R`, `drm_ordinary_sd_target_members()` pair-validation block).

The added negative cases cover the relevant corruptions: a same-level but wrong-group pair, a same-group but wrong-block pair, an out-of-range current correlation id, and a paired-axis correlation id incompatible with the current axis. Those checks complement the existing valid correlated intercept/slope case and bivariate q4 member case. The parent reports 56 assertions passing; I did not rerun them.

**Disposition:** no blocker remains for the module’s stated role as an internal identity resolver, provided callers retain their separate family/endpoint/engine/model-admission gates. This review does not approve fitting admission, builder integration, likelihood behavior, or direct-SD support; each requires its own review and evidence. No fits or tests were run here.
