# C16 `mc-0585` completion review — relmat zero-one-beta `mu` q1

## Decision

**GO — point-fit recovery only.** `mc-0585` is ordinary-ML
`zero_one_beta()` with one unlabelled q1 `relmat(1 | species, K = K)`
intercept in `mu`. This does not admit `Q` syntax, slopes, labels,
covariance, q2-plus, other distributional parameters, profiles, intervals,
coverage, or inference.

## Evidence

- The corrected dense oracle and source-pinned focused test receipt are in
  `2026-08-01-lane-c-c16-mc-0585-relmat-mu-oracle-run-2/`. The oracle uses
  `Q = K^-1`, the normalized precision penalty, and the model-15 inward mean
  transform.
- The final local fixture retains four planned current-source attempts in
  `2026-08-01-lane-c-c16-mc-0585-relmat-mu-local-run-2/`: all pass
  convergence, Hessian, gradient, mode-correlation, clamp, boundary, and
  recovery gates. Its IID control is retained as a carrier control only.
- Earlier receipts remain in the audit trail and are not substituted for the
  source-bound final evidence.
- `2026-08-01-lane-c-c16-mc-0585-relmat-mu-source-binding.tsv` pins the
  model-15 R/C++ blobs, repaired oracle test, and telemetry runner.

## Fresh review

| Lens | Verdict | Scope |
| --- | --- | --- |
| Noether | GO | Exact `K` covariance-to-precision map, carrier, and oracle. |
| Fisher | GO | Retained all-attempt recovery, DGP, and IID-control boundary. |
| Rose | GO | Source binding, receipt completeness, and claim boundary. |

The only supported ledger change is `mc-0585 -> point_fit_recovery`.
