# After Task: Lane C C3 Poisson spatial labelled q2 blocker

## 1. Goal

Attempt C0-08 only: ordinary Poisson `mu` with one labelled spatial
intercept--slope covariance block and a local point-recovery receipt.

## 2. Implemented

No C0-08 admission was retained.  The tentative parser, test, and runner
changes were reverted before commit after review found a prohibited interval
surface.  This report is the durable C3 blocker receipt.

## 3a. Decisions and Rejected Alternatives

The proposed latent target was the same fixed-precision q2 field used by C0-07,
with two positive SDs and
\(\rho = 0.999999\tanh(\eta)\).  The implementation algebra and shared
q2 penalty were coherent, including the zero-correlation reduction.  That is
not enough to admit the formula under the current Lane C boundary.

## 4. Files Touched

Only this Lane C blocker report is intended for commit.  The raw, uncommitted
attempt directories remain in the worktree as forensic evidence because they
are not a valid recovery receipt and must not be silently discarded.

## 5. Checks Run

- Lane preflight: no Claude lane detected in its 12-hour window (weak evidence).
- Tentative focused `test-count-structured-mu.R`: passed before reversion.
- Tentative local spatial fixture: 3/3 numerical fits and IID control passed.
- Fresh Noether, Fisher, and Rose review: BLOCKER.

## 6. Tests of the Tests

The tentative R joint-precision oracle checked the shared penalty, its
zero-correlation reduction, AD gradient, and nonzero-correlation liveness.
Review found that it reuses the package-supplied precision and therefore is not
an independent spatial-precision construction.  That issue is secondary to the
hard interval-surface blocker below.

## 8. Consistency Audit

When the spatial q2 parameter was active, the generic profile registry mapped
the two spatial SDs to `log_sd_phylo` and the spatial correlation to
`eta_cor_phylo`, making `profile_targets()` and profile intervals available.
That violates this plan's no-profile/no-interval and Lane B boundary.  The
current committed code therefore continues to reject spatial labelled q2.

## 7a. Issue Ledger

No issue, capability, ledger, dashboard, public documentation, or API state
changed.  C0-08 remains not implemented.

## 9. What Did Not Go Smoothly

The first local runner used `sim$coords`, which the formula DSL rejects; all
three parser failures are retained.  The corrected fixture then passed
numerically, but its runner hash was changed after the run and its source SHA
was only `HEAD-dirty`; it is not reproducible point-recovery evidence.  The
raw attempts remain intentionally unstaged.

## 11. Team Learning

For count q2 routes, parser admission is also an inference-surface admission
because generic profile discovery follows active internal parameters.  A local
fit and likelihood oracle cannot establish a point-fit-only capability while
that route remains reachable.

## 10. Known Residuals

C0-08, C0-09, and C0-10 remain rejected.  C4--C8 do not begin: progressing
through the provider cohort would repeat the same profile-surface violation.
No interval feasibility, recovery promotion, or public capability is claimed.

## 12. Cross-Product Coverage

This blocker covers the interaction between a proposed ordinary-Poisson spatial
q2 `mu` admission and the existing profile-target registry.  It does NOT cover
profile-exclusion implementation, interval validity, relmat or animal q2,
NB2 scale-side structures, zero-one-beta random effects, bivariate association,
REML, missingness, aggregation, the Julia engine, or any capability promotion.

A fresh owner-approved plan must decide whether to (1) design a count-q2
profile exclusion contract with Lane B ownership, or (2) explicitly redesign
the scope and evidence required for public interval exposure.  Neither action
is authorized by this Lane C plan.
