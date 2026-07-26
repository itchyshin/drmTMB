# After Task: Scalar A1 ML-versus-REML attribution oracle resolution

## 1. Goal

Implement the approved local scalar-A1 ML-versus-REML oracle and smoke arc,
then prepare—but not run—a fresh Totoro campaign packet.

## 2. Implemented

Added pure paired-accounting helpers, a paired ML/REML smoke runner and
analysis, a deterministic `drmTMB`/`lme4` oracle, focused contract tests, a
frozen protocol, a smoke receipt, and a prepare-only Totoro packet.

## 3a. Decisions and Rejected Alternatives

The post-oracle smoke retained all six ML/REML rows and produced finite
profiles.  All six oracle rows pass: lme4 validates ML endpoints and ML/REML
point-estimate/likelihood parity, while a direct restricted-likelihood profile
validates REML endpoints.  The prior apparent lme4 REML endpoint mismatch was a
measured comparator limitation—its REML profiling path matched the ML curve to
at most `1.5e-10` across the three fixtures—not a
drmTMB discrepancy.

## 4. Files Touched

All additions are confined to
`docs/dev-log/simulation-artifacts/2026-07-26-a1-r999-bootstrap-diagnosis/`,
two focused `tests/testthat/` contracts, this report, and the factual check log.

## 5. Checks Run

The pure paired helper probe and both focused contracts passed.  The standalone
oracle passed six deterministic fixtures, and the post-oracle three-cell,
six-arm smoke wrote paired finite profile rows.  `git diff --check` passed.
The merger now rejects a missing or unexpected scheduled outer-attempt key
before calculating an all-attempt denominator.

## 6. Tests of the Tests

The paired helper test deliberately rejects a missing estimator arm.  The oracle
contract test verifies all six frozen estimator-cell fixtures and reports the
gate result without pinning the current REML mismatch as an accepted outcome;
the standalone oracle is the fail-closed gate.

## 7a. Issue Ledger

No issue was opened.  The comparator discrepancy was resolved without changing
the package: the REML endpoint oracle is now a direct restricted-likelihood
profile.  Whether REML improves coverage remains an unmeasured campaign
question, not a repair or capability claim.

## 8. Consistency Audit

The Gaussian random-effect integral is exact; this is not evidence of Laplace
refit bias.  The passing oracle makes a future coverage campaign technically
ready but does not launch or authorize it.  It does not change profile-first
status, default behavior, Arc D semantics, or any public capability surface.

## 9. What Did Not Go Smoothly

The initial oracle was deliberately fail-closed and exposed that lme4's REML
profile was not a valid REML endpoint reference in this environment.  The
remedy was a matched direct restricted-likelihood reference, not a relaxed
tolerance.  The post-oracle smoke remains plumbing only and was not used as
coverage evidence.

## 10. Known Residuals

The runner records source and helper hashes and accepts an installed-tarball
SHA-256 supplied by the future authenticated campaign environment.  No remote
output or campaign artifact was created.

## 11. Team Learning

No Totoro or GitHub Actions campaign was run.  The prepared packet retains the
future Totoro ceiling of 100 workers and requires fresh written approval.

## 12. Cross-Product Coverage

No cross-product work was required.  This arc does NOT cover Arc D endpoint
semantics or clamps; association or the private sandwich engine; structured,
scale-side, or non-Gaussian random effects; bootstrap calibration or
correction; penalties; missingness; aggregation; other engines; public interval
guidance; capability promotion; or a Totoro coverage campaign.

## Next Actions

Start a fresh task only if Shinichi supplies written compute approval for the
prepared 3,000-attempt Totoro campaign.  That campaign, not this smoke, is the
only route to the pre-registered directional-miss decision rule.
