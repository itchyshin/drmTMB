# After Task: OU-sigma R1 local recovery-calibration readiness

## Goal

Create and test a reproducible local readiness calibration for the existing independent Gaussian ML phylogenetic OU location and residual-log-scale intercept fields. This is not a recovery campaign.

## Implemented

The frozen R1 contract specifies height-one trees, stationary root-plus-edge OU draws, sixteen ordinary cells, two retained one-observation-per-species negative controls, and three fixed starts. The runner produces deterministic smoke and largest-cell timing receipts. The verifier checks the independent covariance oracle, identifiers, denominators, diagnostics, current-source receipt hashes, and the no-claim boundary.

## Mathematical Contract

The simulator independently draws \(u \sim OU(\alpha_\mu,0.45)\) and \(v \sim OU(\alpha_\sigma,0.25)\) on the same scaled rooted tree, then draws repeated observations with \(\log \sigma_i=-1+v_i\). The registry assertion confirms the separate `mu`/`sigma` latent and alpha slots before the internal calibration-only start injection. It does not fit a phylogenetic cross-field correlation.

## Files Changed

`docs/design/263-phylo-ou-sigma-recovery-calibration.md`; the runner and verifier under `tools/`; one focused test; and the retained smoke/preflight receipts under `docs/dev-log/implementation-recovery/2026-09-12-phylo-ou-sigma-r1/`.

## Checks Run

- `Rscript tools/verify-phylo-ou-sigma-recovery-calibration.R --all` passed.
- `Rscript tools/verify-phylo-ou-sigma-recovery-calibration.R --smoke` passed with a retained weak negative-control result.
- The source-current twelve-fit preflight projected all 54 predeclared attempts at 183.46 seconds, below the 25-minute local calibration threshold; `campaign_launch=FALSE`.
- `Rscript -e 'testthat::test_file("tests/testthat/test-phylo-ou-sigma-recovery-calibration.R", reporter = "summary")'` passed.
- Unlazy reverify reported all nine R1 gates met.

## Tests Of The Tests

The covariance oracle builds root-and-edge loadings independently of the package helper and detects omitted-root mutation. The smoke replay compares two retained runs after excluding wall time. The negative control preserves non-positive-definite fits instead of filtering them out. The provenance validator fails if either current runner or contract hash differs from either receipt.

## Consistency Audit

The formula grammar, README, NEWS, known limitations, vignettes, and implementation map already describe G13 as local-fit/oracle evidence only and retain the recovery fence. The R1 document is a new design receipt and does not widen that public capability. Search used: `rg -n "alpha_sigma|decay_phylo:sigma|phylogenetic OU|phylo.*model = \\"ou\\"" README.md NEWS.md docs/dev-log/internal-roadmap.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes _pkgdown.yml`.

## GitHub Issue Maintenance

No issue was changed. `gh issue list --state open --search 'OU phylogenetic' --limit 20` could not reach GitHub, so open-issue status was not inferred.

## What Did Not Go Smoothly

The original G13 one-row control also had an aliased covariate, so it could not isolate replication weakness. R1 removes that covariate. Completion review also found stale reduced receipts and a duplicate design number; the final receipt verifies both smoke and preflight hashes, and the contract uses available design number 263.

## Team Learning

For a readiness-only slice, define a smaller receipt schema explicitly and verify it as strictly as a campaign schema; otherwise a truthful scope fence can still leave reproducibility fail-open.

## Known Limitations

No complete local calibration, retained recovery campaign, profile/interval/coverage result, or model-selection result was run. The 54-fit projection permits a later local calibration but is not an approval for a larger campaign. Correlation, temporal terms, REML, slopes, direct-SD, bivariate, missing-response, and non-Gaussian OU remain deferred.

## Next Actions

If a recovery claim is wanted, run the frozen 16-cell ordinary calibration under this design, retain the full campaign schema, assess failures and likelihood flatness, and seek separate approval before any campaign exceeding 30 minutes.
