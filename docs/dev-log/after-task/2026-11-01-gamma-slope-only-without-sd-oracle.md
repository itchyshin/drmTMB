# After-task report: plain structured fits without an sd() formula (2026-11-01)

## Goal

Two review notes said that plain fits with no sd(...) formula were admitted as
a side effect of the SD-regression routes. The shapes are NB2
phylo_interaction(0 + x | plant:pollinator, ...), Gamma ordinary (1 | g) plus an
animal, phylo or spatial intercept, and Gamma slope-only phylo, spatial, relmat
and animal blocks. The task was to check each plain shape against a dense
Laplace oracle with constant SDs, and to add a refusal for any shape that
disagrees.

## What changed

One new test file, tests/testthat/test-structured-plain-fits-no-sd-oracle.R.
No change to R/ or src/. No refusal was needed because every shape agreed with
its oracle.

For each shape the file checks:

- logLik of the plain fit against a dense, drmTMB-independent Laplace marginal
  likelihood at the fitted parameters with constant SDs (tolerance 1e-5
  absolute for the Gamma intercept routes, 1e-4 for the slope-only Gamma routes
  and NB2 interaction);
- equality of the plain fit with the sd(...) ~ 1 fit (1e-4 on logLik, 1e-3 on
  mu coefficients);
- emulated-bug sensitivity (each must move the oracle by more than 0.05):
  a cyclically mislabelled K, a mis-scaled K, swapped or halved SDs, a wrong
  loading for the interaction field, and a swapped Kronecker order;
- non-unit-diagonal K with shuffled level order for relmat (K and Q) and animal
  (Ainv); trees and spatial kernels supply the correlation form, as in the
  sibling tests, and are stored in shuffled order too.

Tolerances were fixed before the first run and none was loosened. One thing
did change after the first run: my first mislabelling bug emulation reversed
the dimnames of K. The Toeplitz-type kernels are symmetric under reversal, so
that emulation moved the oracle by about 1e-13 and could not detect anything.
I replaced it with a cyclic relabelling, which is a stronger check. All oracle
and equivalence assertions were untouched.

## Evidence

Run on the Mac in a private copy, one R process at a time.

- test-structured-plain-fits-no-sd-oracle.R: 87 passed, 0 failed, 0 errors,
  0 skipped.
- Neighbours (all test-gamma-*.R plus test-nbinom2-phylo-interaction-sd.R):
  811 passed, 0 failed, 0 errors, 4 skipped (the skips are live Julia tests and
  one spatial skip that were already skipped before this change).

## Not covered

Julia engine, calibration, simulation recovery, missing responses, and plain
shapes other than the ones listed. Non-unit-diagonal K is not available for
tree and spatial providers, so those two are checked on the correlation form
only.
