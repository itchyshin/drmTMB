# After Task: R7 fixed-alpha OU application decision

## Goal

Use the new fixed-alpha OU sensitivity workflow on real and simulated examples,
then decide whether free-rate OU development is worth continuing now.

## Implemented

Added a deterministic cell runner and retained an empirical/simulation receipt
under `docs/dev-log/evidence/ou-fixed-alpha-r7/`. The first full-script attempt
was deliberately discarded because this execution surface terminates shell
commands at 30 seconds; the retained cells run independently and preserve their
own CSV diagnostics.

## Mathematical Contract

Each cell compares BM with exactly one prespecified location-side OU alpha,
using root-depth normalization, identical rows/tree/formula/control settings,
and ML. The comparison is conditional sensitivity, not alpha estimation or
generic model selection.

## Files Changed

- `tools/run-phylo-ou-r7-cell.R`
- `docs/dev-log/evidence/ou-fixed-alpha-r7/`
- this report and `docs/dev-log/check-log.md`

## Checks Run

All 15 small retained cells returned `OU_FIXED_ALPHA_R7_CELL_PASS`; all their
fits had convergence code zero, positive-definite Hessians, and no warnings.
The full Ayumi helper grid also completed and reproduces R6. The separately
retained full 657-species AVONET batch has a false-converged BM fit and two
careful-preset OU fits, so it is recorded as feasibility evidence rather than
an AIC comparison. `git diff --check` will be run before the commit.

## Tests Of The Tests

The two simulation settings use the same fixed tree/seed/truth but sharply
different OU amplitude and residual SD. Both remain in the receipt even though
neither made the true-alpha OU grid member lowest-AIC, preventing a
positive-control-only account.

## Consistency Audit

R7 does not widen the package capability. Its result agrees with the existing
fixed-alpha documentation: BM remains default; `ou_sensitivity()` remains
experimental; free-alpha/full OU-v1 remains parked.

## GitHub Issue Maintenance

A complete future-development issue draft is retained locally. The requested
GitHub issue creation was rejected by the external-action safety layer because
the repository-specific publication needed a fresh confirmation; no external
issue was created or modified.

## What Did Not Go Smoothly

The full Ayumi grid cannot run in one 30-second local shell invocation. The
AVONET published tree also required the same tiny non-positive-edge repair used
in the Ayumi receipt. Both conditions are explicit in the provenance.

## Team Learning

Clean convergence and a positive Hessian do not make alpha comparison
informative. Fixed-alpha sensitivity is still useful because it exposes that
uncertainty transparently without pretending to estimate a rate.

## Known Limitations

R7 is four examples, not a recovery or selection study. The AVONET subset is a
fast deterministic usability subset, not a representative analysis. Nothing
here establishes that OU is generally worse than BM.

## Next Actions

Keep BM as default and use fixed-alpha sensitivity only where biologically
prespecified values are meaningful. Create the parked future-development issue
only after the requested repository-specific publication confirmation.
