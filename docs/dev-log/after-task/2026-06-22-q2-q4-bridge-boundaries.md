# After Task: q2 and q4 Bridge Boundaries

## Goal

Bank the current q2 and q4 bridge evidence without converting partial bridge
signals into broad support claims.

## Implemented

The q2 phylo bridge row now records an intentional pre-JuliaCall error for the
mu1/mu2-only phylogenetic route. The q4 bridge rows now record live corpairs
point-extractor evidence while keeping full parity, intervals, and coverage out
of scope.

## Mathematical Contract

The q2 row is a target-separation contract: bivariate location-only phylo is not
all-four q4 phylo, and it needs its own payload before bridge parity can be
tested. The q4 row is an extractor contract: reconstructing point correlations
from `Sigma_a` is not a restricted-likelihood, interval, or coverage result.

## Files Changed

- `docs/dev-log/dashboard/structured-re-q2-bridge-boundary.tsv`
- `docs/dev-log/dashboard/structured-re-q4-bridge-boundary.tsv`
- `docs/dev-log/dashboard/structured-re-q4-extractor-parity.tsv`
- `docs/dev-log/dashboard/structured-re-balance-matrix.tsv`
- `docs/dev-log/dashboard/structured-re-finish-100-slices.tsv`
- `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`
- `docs/dev-log/dashboard/structured-re-reml-scope-gate.tsv`
- `docs/dev-log/dashboard/structured-re-julia-twin-sync.tsv`
- `docs/design/211-structured-reml-status.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript --vanilla -e 'devtools::test(filter = "julia-gate-vs-engine")'
DRM_JL_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot \
  DRM_JL_PHYLO_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot \
  Rscript --vanilla -e 'devtools::test(filter = "julia-phylo-q4-corpairs")'
tools/validate-mission-control.py
git diff --check
```

The q2 gate test passed with 143 assertions. The q4 corpairs test passed with
27 assertions. The mission-control validator passed with 15 executable-evidence
rows, and `git diff --check` was clean.

## Tests Of The Tests

The q2 test exercises a failure path: the bridge gate rejects the partial q4
payload before JuliaCall. The q4 test exercises a neighbouring live path:
R-via-Julia reconstruction returns point extractor values for corpairs, but the
dashboard rows still require separate parity and interval gates.

## Consistency Audit

The q2 status is now consistent across the executable-evidence table, bridge
boundary table, balance matrix, finish ledger, and check log. The q4 status is
consistent across the extractor parity table, q4 bridge boundary table, balance
matrix, finish ledger, and check log. The REML scope gate now distinguishes
bridge-only q1 sigma admission from native TMB REML support.

## GitHub Issue Maintenance

No GitHub issue was opened, edited, or replied to. The Ayumi issue remains
parked until current issue text is reviewed and the exact final reply is
approved.

## What Did Not Go Smoothly

The q2 status looked like ordinary planned bridge work at first, but the live
test evidence showed a stronger truth: the current route is an intentional
error because the payload is interpreted as a partial q4 block. That needed a
status-wording correction, not an implementation shortcut.

## Team Learning

Ada and Rose should keep target separation visible before asking Emmy to extend
bridge payloads. Fisher should treat q4 corpairs as point-extractor evidence
until interval accounting and parity evidence exist.

## Known Limitations

This report does not add q2 bridge support, q4 full parity, q4 REML, q4
intervals, calibrated coverage, non-Gaussian REML, public optimizer controls,
or broad R bridge support.

## Next Actions

Add a q2-specific payload contract before attempting q2 bridge parity. Add a
q4 all-four deterministic fixture before promoting q4 beyond point-extractor
evidence.

## Update 2026-06-23

The q2 phylo `mu1`/`mu2` bridge row is no longer an intentional-error row for
the complete-response exact-Gaussian ML fixture. The bridge now admits the q2
phylo target and rejects only invalid one-axis or three-axis phylo payloads.
The old partial-q4 interpretation is retained here as historical evidence, but
the live dashboard boundary is now:

- q2 phylo: one narrow native/direct/R-via-Julia ML fixture is covered.
- q2 spatial/animal/relmat: direct and bridge same-target routes remain
  planned or blocked.
- q4 all-four: point/corpairs evidence is separate from q4 intervals, q4 REML,
  AI-REML, and coverage.

Aggregate q2 bridge support is still not promoted.
