# C16 `mc-0586` completion review — spatial zero-one-beta `mu` q1

## Decision

**GO — point-fit recovery only.** `mc-0586` is ordinary-ML
`zero_one_beta()` with one unlabelled q1 `spatial(1 | site, coords = coords)`
intercept in `mu`. This does not admit mesh inputs, slopes, labels,
covariance, q2-plus, other distributional parameters, profiles, intervals,
coverage, or inference.

## Evidence

- The corrected spatial dense oracle and source-pinned focused test receipt
  are in `2026-08-01-lane-c-c16-mc-0586-spatial-mu-oracle-run-2/`. They use
  the same deterministic coordinate-to-precision construction and model-15
  inward mean transform as the fitted route.
- The final local fixture retains four current-source attempts in
  `2026-08-01-lane-c-c16-mc-0586-spatial-mu-local-run-2/`. All pass the
  convergence, Hessian, gradient, latent-mode, clamp, boundary, and recovery
  gates. The IID control is retained as a carrier control only.
- Earlier runner/test receipts remain in the audit trail and are not
  substituted for the final source-bound evidence.
- `2026-08-01-lane-c-c16-mc-0586-spatial-mu-source-binding.tsv` pins the
  model-15 R/C++ blobs, repaired oracle test, and recovery runner.

## Fresh review

| Lens | Verdict | Scope |
| --- | --- | --- |
| Noether | GO | Coordinate precision map, endpoint carrier, and dense oracle. |
| Fisher | GO | Retained all-attempt recovery, DGP, and IID-control boundary. |
| Rose | GO | Source binding, receipt completeness, and claim boundary. |

The only supported ledger change is `mc-0586 -> point_fit_recovery`.
