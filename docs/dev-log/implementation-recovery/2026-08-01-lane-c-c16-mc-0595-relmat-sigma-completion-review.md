# C16 `mc-0595` completion review — relmat zero-one-beta `sigma` q1

## Decision

**GO — point-fit recovery only.** `mc-0595` is ordinary-ML
`zero_one_beta()` with one unlabelled q1 `relmat(1 | species, K = K)`
intercept in `sigma`. This does not admit supplied-precision `Q`, slopes,
labels, covariance, q2-plus, other distributional parameters, profiles,
intervals, coverage, or inference.

## Evidence

- The source-pinned focused oracle receipt is in
  `2026-08-01-lane-c-c16-mc-0595-relmat-sigma-oracle-run-4/`; it checks the
  exact covariance-to-precision conversion, sigma endpoint, full mixture,
  objective, gradient, and latent-SD dependency.
- The final fixture retains four current-source attempts in
  `2026-08-01-lane-c-c16-mc-0595-relmat-sigma-local-run-4/`. All pass
  convergence, Hessian, gradient, per-group support, latent-mode, clamp,
  boundary, and recovery gates. The fixed-SD fit is diagnostic-only.
- Earlier C16 runner/test receipts remain in the audit trail and are not
  substituted for the final source-bound evidence.
- `2026-08-01-lane-c-c16-mc-0595-relmat-sigma-source-binding.tsv` pins the
  model-15 R/C++ blobs, oracle test, and recovery runner.

## Fresh review

| Lens | Verdict | Scope |
| --- | --- | --- |
| Noether | GO | `K` orientation, precision normalisation, sigma carrier, likelihood, and oracle. |
| Fisher | GO | Full-mixture DGP, all-attempt recovery, and fixed-SD diagnostic. |
| Rose | GO | Source binding, receipt completeness, and claim boundary. |

The only supported ledger change is `mc-0595 -> point_fit_recovery`.
