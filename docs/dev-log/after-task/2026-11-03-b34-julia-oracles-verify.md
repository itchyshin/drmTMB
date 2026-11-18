# After-task report: independent verification of the batch 34 Julia oracles

Date: 2026-11-03. Lane: codex/general-sd-regression. Verified against drmTMB
HEAD 81553915d (R/ and src/ hashes also match the later HEAD 5d4979208) and
DRModels.jl ab8b67127. Verifier: a separate reviewer, not the author.

## 1. Goal

Check the worker's batch 34 patch (three live oracle test files, helper, three
evidence directories, ledger fragment) from fresh private copies: applies,
passes live, oracles independent, emulated bugs far above tolerance, tests fail
when the Julia source is wrong, receipts and fragment hashes true, every linked
row_key actually fitted.

## 2. Implemented

One change to the worker's patch. In `test-julia-b34-iid-quadrature-oracle.R`
the agreement tolerance goes from 1e-4 to 1e-6. Reason: run against DRModels.jl
e7dbc3f79 (the parent of the quadrature fix), the ZeroOneBeta slope fixtures
agree to 6e-6 to 5e-5, so at 1e-4 the slope row could not tell the old
quadrature from the new one. Observed agreement on ab8b67127 is 1.0e-10 or
better, so 1e-6 leaves four orders of margin. Tightening only. The iid
evidence was rerun and re-issued as
`julia-b34-iid-quadrature-oracle-20261103c`; the worker's `...20261103b` iid
directory is dropped from the patch. The other two evidence directories and
all other files are the worker's, unchanged.

## 3a. Decisions and Rejected Alternatives

- Tighten rather than keep 1e-4: the evidence should be able to fail on the
  defect it claims to certify. No tolerance was loosened anywhere.
- Rejected: a Julia patch. No Julia defect affects a claim; the boundary-heavy
  Hessian error (seeds 20261409 and 20261412) is disclosed and not asserted.
- Rejected: granting the iid rows on the worker's 1e-4 receipt.

## 4. Files Touched

The worker's 14 files with the iid test, the iid evidence directory (renamed
to `...20261103c`) and the worker's after-task note adjusted, plus this note.
No existing repository file is edited. The ledger and NEWS are untouched.

## 5. Checks Run

Fresh archives of drmTMB 81553915d and DRModels.jl ab8b67127 (plus worktree
Manifest.toml); patch applied with `git apply`; Mac, live Julia 1.10.0, one R
process at a time, single thread.

| Run | Passed | Failed | Errors |
|---|---|---|---|
| Gaussian structured, ab8b67127 | 56 | 0 | 0 |
| Poisson/NB2/Gamma structured, ab8b67127 | 99 | 0 | 0 |
| iid quadrature at 1e-6, ab8b67127 | 106 | 0 | 0 |
| iid quadrature at 1e-4 (worker), e7dbc3f79 | 98 | 8 | 0 |
| iid quadrature at 1e-6, e7dbc3f79 | 93 | 13 | 0 |
| Gaussian structured, e7dbc3f79 | 8 | 0 | 3 (route not admitted) |
| Gaussian structured, K and A forced through cov2cor in the Julia source | 52 | 4 | 0 |

All agreement numbers reproduce the worker's (Gaussian 2.8e-13, Laplace 3.2e-6
worst, iid 1.0e-10 worst). Totoro was not used.

## 6. Tests of the Tests

- Real Julia-source mutation: cov2cor applied to relmat K and animal A in
  `gaussian_lss.jl`. The relmat and animal blocks fail (oracle disagreement
  0.59 and 0.020); spatial is unaffected, as it should be.
- Old quadrature (e7dbc3f79): ZeroOneBeta intercept, ZeroOneBeta slope and ZIP
  slope all fail at 1e-6.
- The count, NB2 and Gamma structured tests also pass on e7dbc3f79: those Julia
  routes pre-date ab8b67127, so these are independent oracles for existing
  behaviour, not a capability test.
- The worker's emulated-bug gaps (smallest: NB2 spatial 0.0016, 158 times
  1e-5; Gaussian spatial 0.0465; ZeroOneBeta slope 0.019) reproduce.

## 7a. Issue Ledger

No issue opened. Residual weakness: the NB2 spatial range-bug gap is only 158
times its tolerance.

## 8. Consistency Audit

All receipt, manifest, console-log and fragment hashes recomputed and match.
Every fragment row_key exists in `required-rows.tsv` and is fitted literally:
q=1 intercepts on relmat, animal and spatial; ZeroOneBeta iid intercept;
ZeroOneBeta and ZIP slope-only fits (the slope member). No correlated-block row
is linked. No em dashes. No NEWS edit, so no engine = "julia" with all, any or
every family wording. The `does_not_establish` entries contain "any family not
named here" as a negation only.

## 9. What Did Not Go Smoothly

The first iid test at 1e-4 passed on the old quadrature for the slope route.
Fixed here. The worker's drmTMB HEAD had moved (5d4979208, evidence only), so
source hashes were rechecked against the live worktree: identical.

## 10. Known Residuals

One fixture per structured route; a few seeds per iid route. Boundary-heavy
ZeroOneBeta slope seeds 20261409 and 20261412 make the Julia standard-error
step stop (Infs or NaNs); a Julia limitation, not asserted. No SE, coverage,
calibration or fitted() claim; Gaussian is ML only.

## 11. Team Learning

Run a new oracle test against the commit before the fix it certifies. A
tolerance that the old code also meets is not evidence for the fix.

## 12. Cross-Product Coverage

Gaussian relmat, animal, spatial intercept SD; Poisson, NB2, Gamma relmat and
spatial intercept SD; ZeroOneBeta iid intercept and slope SD; ZIP iid slope SD.
Not covered: slope or correlated blocks on the structured routes, other
providers and families.
