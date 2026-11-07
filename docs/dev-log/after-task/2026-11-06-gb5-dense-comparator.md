# After task: bounded retry for the Gaussian dense comparator

## Goal

Keep the independent Gaussian dense-likelihood comparison useful when its
L-BFGS-B optimizer stops without convergence, as observed in the macOS release
check at commit `4acdff376e17c5c7ba4d90c203cfd618ecc083e2`.

## Implemented

The test retains L-BFGS-B with `factr = 1e3`. Only after a nonzero convergence
code, it retries the returned finite, in-bounds point using `nlminb` with the
same objective and bounds. The retry must converge with a finite, in-bounds
result. Failure diagnostics include both attempts, the gradient at the final
point, and distances from the bounds.

## Mathematical contract

The dense Gaussian likelihood and the fitted-model comparison retain their
existing 1e-5 tolerance. The package fit's own convergence assertion and the
separate dense likelihood oracle remain unchanged. No production model or
scientific tolerance changed.

## Files changed

The GB5 test file contains the comparator helper and its controls. This report
and the check-log fragment record the bounded investigation.

## Checks run

On the local Mac, the single phylogenetic fixture passed 13 expectations. The
whole GB5 file with `NOT_CRAN=true` passed 111 expectations, with two skips for
held structured-plus-structured routes. These are local results, not a full
package or GitHub macOS pass. BLAS was limited to one thread.

## Tests of the tests

A forced one-iteration primary failure exercised the bounded retry; a forced
failed retry was rejected. The controls also check finite starting values,
bounds, and that an ordinarily converged primary result does not retry. These
controls passed eight expectations. The forced code 1 checks the mechanism; it
does not reproduce the GitHub runner's observed code 52.

## Consistency audit

The existing dense objective, fitted log-likelihood comparison, bounds, and
primary stopping rule remain in use. The change is confined to test code.
No formula, likelihood, public documentation, or pkgdown surface changed.

## GitHub issue maintenance

Issue #1678 tracks the comparator failure. This follow-up closes #1678 after
its reviewed change merges; the issue remains open until then.

## What did not go smoothly

The GitHub macOS check reported comparator convergence code 52, while its
likelihood comparison passed. It did not record the returned parameters or
gradient, so that point cannot be classified as stationary or interior. The
same fixture on the local Mac returned code 0; local R was 4.6.0, while the
GitHub runner used R 4.6.2. A first local full-file invocation omitted
`NOT_CRAN` and skipped the substantive fixtures; the reported full-file result
comes from the corrected invocation.

## Team learning

Record both optimizer results and bounded diagnostics when a fallback fails,
so a convergence code does not obscure the next investigation.

## Design and documentation

No model design, formula grammar, user-facing tutorial, or pkgdown navigation
changed.

## Known limitations and next actions

The actual GitHub code-52 point was not reproduced locally. Exact-head macOS
CI must exercise the revised test; the full release matrix remains required.
No coverage, calibration, or broad parity result follows from this test repair.

## Prose review

Self-review, 2026-11-06: perceived AI-like style 2/10 with moderate confidence
for this short technical report. The goal and limitation sections identify the
observed failure and the missing CI point; no wording change was needed.
Science gate: pass for the stated comparator contract. Facts gate: pass against
the test and CI logs. Reference gate: not applicable; no literature is cited.
This is an editorial assessment, not an authorship test.
