# Beta phylogenetic direct-SD wording audit

The narrow Beta q1 phylogenetic location-SD route is implemented and its
calibration evidence is ratified. The docs had two stale blanket deferrals:
the formula-grammar row still described the recovery as prospective, and the
known-limitations entries said direct latent-SD regression and interval
coverage remained deferred. These statements obscured the exact `mc-0017`
exception.

The route is limited to strict-proportion `beta_family()` models with one
unlabelled q1 phylogenetic intercept in `mu`, fixed-effect family `sigma`, and
`sd(spp_id, level = "phylogenetic") ~ x_tau`. The scale is latent location SD
`tau`, with covariance `D_tau A D_tau`; it is not response-scale `sigma` or
Beta precision `phi`. The formula-grammar, likelihood, and known-limitations
wording now names the narrow route and its exact inference boundary. No claim
of general Beta direct-SD support was added.

The boundary is grounded in the local source and retained evidence:

- `R/drmTMB.R:6365-6377` separates `sd_phylo()` from the ordinary `sd()`
  rejection path and names the exact q1 phylogenetic `mu` exception.
- `tests/testthat/test-beta-phylo-direct-sd.R` checks the q1 model, the
  `D_tau A D_tau` covariance, prediction/profile targets, and negative cases.
- `docs/dev-log/dashboard/capability-ledger/evidence.tsv` records the
  ratified `ev-mc-0017-arc-coverage` evidence. Its 1,200 attempted replicates
  per promotion arm support inference-ready-with-caveats status only for
  `g = 1024, m = 4`; the worst profile-coverage arm is mildly anti-conservative
  (0.9333, exact interval 0.9176–0.9467), and one profile failure is retained
  in the denominator policy.
- `docs/dev-log/simulation-artifacts/2026-07-17-beta-phylo-q1-coverage/`
  retains the campaign summary and source receipts. The distinct/shared arms
  reuse the first 400 point-recovery seeds, so these are not independent
  evidence streams.

`docs/design/03-likelihoods.md` already described the covariance parameterization
and is now explicit about the calibration caveat. The known-limitations note
continues to exclude other species counts, family-`sigma` phylogeny,
phylogenetic random-effect slopes, labels, q>1, REML, missing routes, and
nominal-coverage claims. No fit or
simulation was run for this wording repair; `git diff --check` is the only
validation performed.

**Naturalness assessment:** 2/10, medium confidence; genre: short technical
audit note, entire note reviewed. “The q1 exception has profile-interval
coverage evidence” is specific and bounded; no repair needed. Science = pass
against the retained direct-SD test and ratified coverage row; facts = pass
against the current admission branch and evidence record; references = pass,
each cited local source was opened and checked for the stated claim. Reviewer:
Codex self-review, independent mode, 2026-10-17; the underlying code and
campaign sources are not held-out controls.
