# After Task: Scalar A1 ML-versus-REML attribution oracle stop

## 1. Goal

Implement the approved local scalar-A1 ML-versus-REML oracle and smoke arc,
then prepare—but not run—a fresh Totoro campaign packet.

## 2. Implemented

Added pure paired-accounting helpers, a paired ML/REML smoke runner and
analysis, a deterministic `drmTMB`/`lme4` oracle, focused contract tests, a
frozen protocol, a smoke receipt, and a prepare-only Totoro packet.

## 3a. Decisions and Rejected Alternatives

The smoke retained all six ML/REML rows and produced finite profiles.  The
oracle passed all ML rows and REML at 50 groups, but failed REML profile endpoint
agreement at 10 and 25 groups despite matching likelihoods and point estimates.
The largest upper-endpoint difference was 0.0798, exceeding tolerance 0.0112.

## 4. Files Touched

All additions are confined to
`docs/dev-log/simulation-artifacts/2026-07-26-a1-r999-bootstrap-diagnosis/`,
two focused `tests/testthat/` contracts, this report, and the factual check log.

## 5. Checks Run

The pure paired helper probe and both focused contracts passed.  The three-cell,
six-arm smoke wrote paired finite profile rows.  The standalone oracle failed
closed at the documented REML endpoint mismatch.  `git diff --check` passed.

## 6. Tests of the Tests

The paired helper test deliberately rejects a missing estimator arm.  The oracle
contract test verifies all six frozen estimator-cell fixtures and reports the
gate result without pinning the current REML mismatch as an accepted outcome;
the standalone oracle is the fail-closed gate.

## 7a. Issue Ledger

No issue was opened.  The unresolved REML profile endpoint disagreement is a
fresh diagnostic question, not a repair claim or a capability regression.

## 8. Consistency Audit

The Gaussian random-effect integral is exact; this is not evidence of Laplace
refit bias.  The failure blocks the proposed ML/REML coverage campaign.  It does
not change profile-first status, default behavior, Arc D semantics, or any
public capability surface.

## 9. What Did Not Go Smoothly

The oracle did not pass its REML endpoint gate at two low-group cells.  This is
the planned stop condition.  The smoke had already been run while the oracle
was being completed; it is explicitly retained as plumbing only and was not
used to prepare a compute launch.

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

Start a fresh, separately approved REML-profile geometry/oracle investigation.
It must first determine whether the lme4 REML profile extraction or drmTMB REML
profile construction explains the g=10/25 endpoint difference.  Do not launch
the prepared coverage campaign until that gate passes.
