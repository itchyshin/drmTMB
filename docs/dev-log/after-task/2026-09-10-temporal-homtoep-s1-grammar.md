# After Task: Temporal homogeneous Toeplitz S1 grammar and layout

## Goal

Admit the canonical direct temporal Toeplitz formula and validate its discrete,
complete repeated-measures layout without exposing an unimplemented likelihood.

## Implemented

`temporal(1 | id, time = occasion, structure = "homtoep")` now parses. It accepts
finite integer occasions only when every retained ID has the same complete, equally
spaced schedule of 3--12 occasions. The layout retains the sorted schedule, the
input-row occasion index, and the existing row-to-latent-state mapping.

## Mathematical Contract

S1 represents a correlation by the number of equal discrete intervals between two
occasions. Therefore an irregular schedule is not a Toeplitz panel and is directed
to OU. S1 stores only metadata; it does not evaluate the Toeplitz covariance.

## Files Changed

The temporal marker documentation, parser, layout helpers, generated `temporal.Rd`,
new parser tests, gate runner, child/master ledgers, and check log changed.

## Checks Run

- `Rscript --vanilla tools/temporal-homtoep-gates.R T3-1` returned
  `TEMPORAL_HOMTOEP_T3_1_PASS`.
- New parser/layout tests passed.
- Existing `test-temporal-parser.R`, `test-temporal-gaussian-smoke.R`,
  `test-temporal-identities.R`, `test-temporal-ou.R`, and
  `test-temporal-ou-dense-oracle.R` passed.
- `devtools::document()` regenerated `man/temporal.Rd`.
- `git diff --check` passed before the commit.

## Tests Of The Tests

The S1 tests initially failed before implementation because `homtoep` was rejected,
valid even-lag panels inherited AR1's odd-lag rule, irregular panels were admitted,
and no schedule metadata existed. The final tests also prove that duplicate raw keys
are checked before omission and that an admitted Toeplitz fit stops before it can be
misinterpreted as OU.

## Consistency Audit

The status inventory still lists AR1 and OU as fitted temporal routes. This remains
correct: the marker help says the Toeplitz provider is deferred, and the fit path
returns an explicit development error. No README, NEWS, vignette, pkgdown navigation,
or design-likelihood claim was widened.

## GitHub Issue Maintenance

The overlapping-issue search found #1302 for phylogenetically correlated temporal
OU only. No direct Toeplitz issue existed, and this internal grammar checkpoint did
not require an issue or external update.

## What Did Not Go Smoothly

The lane preflight initially reported parser-file divergence with another active
branch. Its merge-base diff showed that branch changes only `mi()` and a structured
slope-label guard, not temporal code, and no live lease covered these paths. S1
therefore proceeded without overwriting the other lane's work.

## Team Learning

A formula can be safely admitted ahead of its native provider when the later fitting
entry point fails explicitly. This gives parser/layout tests a stable contract while
preventing accidental use of an incorrect existing likelihood.

## Known Limitations

No Toeplitz likelihood, extraction, simulation, covariance oracle, profile
inference, recovery, or calibration exists yet. Ordinary random intercepts are also
deferred for this first direct Toeplitz provider.

## Next Actions

S2 will add the native covariance provider using the T3-2 reflection map, then prove
its marginal likelihood, score, Hessian, and conditional modes against an
independent dense covariance oracle.
