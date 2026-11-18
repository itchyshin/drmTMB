# After-task report: batch 34, independent oracles for Julia bridge routes

Date: 2026-11-03. Lane: codex/general-sd-regression, HEAD 81553915d.
DRModels.jl: worktree general-sd-julia, HEAD ab8b67127.

## 1. Goal

Two jobs, both test-only.

A. The batch 32 Julia bridge files
`test-julia-b32-gaussian-structured-intercept-bridge.R` and
`test-julia-b32-count-gamma-spatial-intercept-bridge.R` compare Julia with
native drmTMB only, so they were kept unreviewed. Add companion tests that
evaluate an independent base-R likelihood at the live Julia estimates.

B. After DRModels.jl ab8b67127 the Julia iid quadrature is accurate. Add live
tests for the Julia ZeroOneBeta iid intercept and slope SD routes and the
zero-inflated Poisson iid slope SD route against an exact per-group integral,
so the rows left unlinked in batch 31 can be relinked.

## 2. Implemented

Four new files under `tests/testthat/`:

- `helper-b34-julia-oracles.R`: the oracles and fixtures. An exact Gaussian
  marginal, a dense Laplace for Poisson, NB2 (size 1 / sigma^2) and Gamma
  (shape 1 / sigma^2), an exact per-group trapezoid integral, hand ZeroOneBeta
  and ZIP densities, a Henderson tabular A, and the hand coordinate kernel
  exp(-d / median) + 1e-6 I. No drmTMB code is used by any oracle.
- `test-julia-b34-gaussian-structured-oracle.R`: Gaussian relmat (non-unit
  diagonal K), animal (A from a 40-animal inbred pedigree, diagonal 1.25 for
  full-sib offspring) and coordinate spatial.
- `test-julia-b34-count-gamma-structured-oracle.R`: Poisson, NB2 and Gamma
  relmat and coordinate spatial.
- `test-julia-b34-iid-quadrature-oracle.R`: ZeroOneBeta iid intercept and slope
  (three ordinary seeds and two boundary-heavy seeds each) and ZIP iid slope
  (three seeds).

Every fixture shuffles the data rows, uses named levels, and supplies the
kernel (or the coordinates) in a different row order from the factor levels.

Agreement asserted before the live runs, then checked against what was observed:

| File | Oracle | Asserted | Observed worst |
|---|---|---|---|
| Gaussian structured | exact marginal | 1e-8 | 2.8e-13 |
| Poisson, NB2, Gamma structured | dense Laplace | 1e-5 | 3.2e-6 |
| ZeroOneBeta, ZIP iid | exact per-group integral | 1e-6 (first draft 1e-4; tightened by the verifier) | 1.0e-10 |

Every emulated bug must move the oracle by more than 20 times the asserted
agreement. Bugs: selectors swapped, reversed SD vector, cov2cor(K) (relmat and
animal), a mean-distance range (spatial, whose kernel has unit diagonal so
cov2cor would be a no-op), kernel read by position, SD intercept shifted by
log 2; for the iid routes also sign-flipped SD slope, scrambled group
predictor, slope read as intercept, atoms swapped and zi halved. A one-step
profile check asserts the Julia estimates sit at a maximum of the oracle.
Non-live blocks check the hand pedigree A and the grid integral against
`stats::integrate`.

Evidence: three receipt directories
`docs/dev-log/general-sd-regression/evidence/julia-b34-{gaussian-structured,count-gamma-structured}-oracle-20261103b/` and `julia-b34-iid-quadrature-oracle-20261103c/`
(receipt.json, source-manifest.json, test-console.log). All `unreviewed`.

## 3a. Decisions and Rejected Alternatives

- Tolerances were set from the oracle's own numerical error, not copied from
  the b31 house value 1e-3. The Laplace oracle matched Julia to about 1e-6, so
  1e-5 was asserted. The Gaussian marginal is exact, so 1e-8. The iid value is
  the 1e-4 the task specified, later tightened to 1e-6 by the independent verifier (see the verify note). None was loosened after seeing a result.
- The spatial kernel has unit diagonal by construction (plus 1e-6), so the
  cov2cor(K) bug is a no-op there. It was replaced by a mean-distance range
  kernel for spatial. That bug is the weakest: NB2 spatial moves the oracle by
  only 0.0016 (158 times the 1e-5 tolerance). It stays because it is real and
  clears the 20-times rule, but it would not clear it at the 1e-3 house value.
- Rejected: reusing `helper-b31jb-oracle.R`. It is Binomial-specific and its
  header ties it to b31 receipts.
- Rejected: asserting that the failing boundary-heavy slope seeds fail. See
  section 9.

## 4. Files Touched

New: the four test files above, three evidence directories, this note. No
existing file was edited. The ledger, NEWS and every R, src and Julia source
file are untouched.

## 5. Checks Run

Live Mac, one R process at a time, from a private git-archive copy at HEAD,
`DRM_JL_PATH` at a private git-archive copy of ab8b67127 plus the worktree
Manifest.toml, `NOT_CRAN=true`, Julia 1.10.0, single-threaded.

| File | Passed | Failed | Errors | Skipped | Blocks |
|---|---|---|---|---|---|
| gaussian-structured | 56 | 0 | 0 | 0 | 4 |
| count-gamma-structured | 99 | 0 | 0 | 0 | 6 |
| iid-quadrature | 106 | 0 | 0 | 0 | 6 |

## 6. Tests of the Tests

The emulated-bug gaps are asserted in the tests themselves; the smallest
observed per file are Gaussian 0.0465 (spatial), counts 0.0016 (NB2 spatial,
mean-distance range) and iid 0.019 (ZeroOneBeta slope, atoms swapped). An
earlier run failed on the Gaussian spatial block and one NB2 spatial gap, which
is how the vacuous cov2cor(K) bug on a unit-diagonal kernel and the weak
mean-distance gap were found. The Gaussian oracle is exact, and the iid grid
integral is checked against `stats::integrate` to 1e-9 in a non-live block.

## 7a. Issue Ledger

No GitHub issue was opened or changed. One Julia limitation is recorded in
section 9 for the DRModels.jl owner.

## 8. Consistency Audit

Receipts name `review_status: unreviewed`, list `does_not_establish`, and make
no calibration, coverage or broad parity claim, and none names a whole
engine as covered. No em dashes were used. The ledger fragment
lines, not the ledger, carry the row keys; the ledger was not edited because
another process is editing it.

## 9. What Did Not Go Smoothly

- ZeroOneBeta iid slope, boundary-heavy draws. Seeds 20261409 and 20261412 make
  the Julia route stop with `ArgumentError: matrix contains Infs or NaNs` in
  `_vcov_from_hessian` (`src/zeroonebeta.jl`, standard-error step). The
  estimates converge with gradient near 1e-10, and the Hessian is finite once
  the one response near 2.6e-56 is clamped to 1e-8, so the cause is an
  extreme interior response, not the share of 0 and 1 values. Ordinary seeds
  and the intercept route are unaffected. The tests use seeds 20261410 and
  20261411 and the header states the exclusion; the failure is reported, not
  asserted. It is an error, not a wrong answer. Not fixed here (no Julia edit
  was requested).
- Totoro was not used. The live tests must run on the Mac and the oracles are
  cheap, so there was nothing to move.
- The Julia Manifest warning "project dependencies or compat requirements
  have changed" appears on the private copy; it loaded and ran.

## 10. Known Residuals

- One fixture per structured route and a few seeds per iid route.
- No standard-error, coverage, calibration or fitted() claim.
- Gaussian ML only (the Julia route is dense ML), not REML.
- The mean-distance range gap for NB2 spatial is small (see section 3a).
- Relinking is for the ledger owner: the fragment file has 12 lines (9
  structured, 3 iid) with exact row keys.

## 11. Team Learning

A bug emulation must be checked for being vacuous on the specific kernel. The
unit-diagonal spatial kernel made cov2cor(K) invisible. An oracle that agrees to
1e-6 invites a tighter, honest tolerance than the inherited 1e-3.

## 12. Cross-Product Coverage

Gaussian: relmat, animal, spatial intercept. Poisson, NB2, Gamma: relmat and
spatial intercept (animal is Gaussian only in the b32 bridge). ZeroOneBeta: iid
intercept and slope. ZIP: iid slope. Not covered: pedigree and Ainv providers,
slope and correlated blocks on the structured routes, other families.
