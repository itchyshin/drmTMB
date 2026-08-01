# C16 `mc-0596` completion review — spatial zero-one-beta `sigma` q1

## Decision

**GO — point-fit recovery only.** `mc-0596` is ordinary-ML
`zero_one_beta()` with one unlabelled q1 `spatial(1 | site, coords = coords)`
intercept in `sigma`. This does not admit estimated spatial covariance,
slopes, labels, covariance, q2-plus, other distributional parameters,
profiles, intervals, coverage, or inference.

## Evidence

- The source-pinned focused oracle receipt is in
  `2026-08-01-lane-c-c16-mc-0596-spatial-sigma-oracle-run-5/`; it checks the
  exact fixed spatial covariance-to-precision route, sigma endpoint, full
  mixture, objective, gradient, and latent-SD dependency.
- The final fixture retains four current-source attempts in
  `2026-08-01-lane-c-c16-mc-0596-spatial-sigma-local-run-5/`. The repaired
  DGP uses the identical standardised site order as the fitted carrier. All
  attempts pass convergence, Hessian, gradient, support, latent-mode, clamp,
  boundary, and recovery gates. The fixed-SD fit is diagnostic-only.
- Earlier misordered and missing-diagnostic C16 spatial receipts remain in the
  audit trail and are not substituted for the final source-bound evidence.
- `2026-08-01-lane-c-c16-mc-0596-spatial-sigma-source-binding.tsv` pins the
  model-15 R/C++ blobs, oracle test, and corrected recovery runner.

## Fresh review

| Lens | Verdict | Scope |
| --- | --- | --- |
| Noether | GO | Coordinate ordering, fixed precision, sigma carrier, likelihood, and oracle. |
| Fisher | GO | Full-mixture DGP, repaired all-attempt recovery, and fixed-SD diagnostic. |
| Rose | GO | Source binding, receipt completeness, and claim boundary. |

The only supported ledger change is `mc-0596 -> point_fit_recovery`.
