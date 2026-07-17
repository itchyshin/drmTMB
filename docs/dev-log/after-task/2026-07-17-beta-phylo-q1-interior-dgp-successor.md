# After Task: Beta phylogenetic q1 direct-SD interior-DGP successor

## Goal

Establish whether the bounded Beta phylogenetic q1 direct-latent-SD route has
prospective recovery evidence after replacing only the finite-precision response
generator that stopped the prior campaign.

## Implemented

The successor adds an isolated runner with a machine-strict conditional-Beta
generator. It redraws only a non-interior response, records redraw telemetry,
retains cap exhaustion as a failed attempt, and leaves the stopped runner and
its campaign unchanged.

## Mathematical Contract

For `y ~ x_mu + phylo(1 | spp_id, tree = tree)`, `sigma ~ x_sigma`, and
`sd(spp_id, level = "phylogenetic") ~ x_tau`, family `sigma` obeys
`phi_i = sigma_i^-2`. The direct-SD coefficients describe latent location-field
SD `tau_s`; they are not family `sigma`, precision `phi`, or conditional
response SD.

## Files Changed

The new runner and focused tests are `tools/run-beta-phylo-q1-sd-interior-recovery.R`
and `tests/testthat/test-beta-phylo-q1-sd-interior-recovery-runner.R`. The
frozen design, seed audit, and symbolic note live under
`docs/dev-log/simulation-designs/2026-07-16-beta-phylo-q1-interior-dgp/` and
`docs/dev-log/2026-07-16-beta-phylo-q1-interior-dgp-symbolic-alignment.md`.
Formula, likelihood, capability, roadmap, limitations, and check-log surfaces
were synchronized.

## Checks Run

Focused runner and Beta tests passed locally. Totoro completed an authenticated
4,800-attempt campaign at 32 workers with BLAS pinned; source `863f7dab`,
runner/design/DLL hashes, seed audit, output manifest, and completion seal all
authenticated. The capability ledger generator and its 37 tests, runtime
oracle, and `pkgdown::check_pkgdown()` passed. The repaired `--as-cran` source
check completed its 573-second test phase and vignette tail without a test
failure.

## Tests Of The Tests

The focused tests force endpoint redraws and a cap exhaustion, verify that only
the affected response redraws, reject clipping/epsilon/restart paths, retain a
failed cap attempt, and preserve the independent likelihood/gradient and
wrong-precision/latent-double-scaling sentinels.

## Consistency Audit

Both `g=1024,m=4` arms pass independently, producing
`PASS_EXACT_TWO_G1024_M4`. The retained stress grid is not uniformly clean:
`shared_g256_m02` has one warning and `pdHess=0.9975`, so it remains a failed
stress-quality cell and is explicitly not pooled into the promotion decision.
Fisher and Rose independently approved only the stated point-fit-recovery
claim.

## GitHub Issue Maintenance

No issue action was taken. This is a fresh successor evidence record, and no
existing issue was changed because the implementation/capability decision is
being carried by the single successor PR.

## What Did Not Go Smoothly

The first local one-fit artifact used an inherited unquoted SHA command and was
quarantined before evidence use. The successor quotes artifact paths and was
rerun from a new authenticated namespace. Monitoring initially counted
`*.sha256.tsv` receipts as shards; the final denominator was verified from the
4800 retained raw attempts, never from that file count. The first source check
also showed that both runner tests needed a source-tarball skip because `tools/`
is intentionally excluded; the tests still run in a development checkout.

## Team Learning

Finite-precision response generation needs its own frozen DGP lineage and
telemetry. A strict-interior redraw is an individual-response operation, not an
attempt retry, and output receipts need a filename convention that cannot be
mistaken for a retained attempt.

## Known Limitations

This is a finite-precision conditional-Beta, univariate ML q1, direct latent-SD
recovery claim. It does not cover family-sigma phylogeny, hierarchical/random
RHS effects in `sd()`, q>1, labels/slopes, REML, missing routes, intervals,
coverage, `inference_ready`, `supported`, or a universal species-count rule.

## Next Actions

Open one successor PR after the final local package and rendered-surface gates
pass. Keep the stopped HOLD campaign and the lower-information stress failures
visible in the PR and follow-up handover.
