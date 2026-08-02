# C16 `mc-0597` completion review — phylo-interaction zero-one-beta `sigma` q1

## Decision

**GO — point-fit recovery only.** `mc-0597` is ordinary-ML
`zero_one_beta()` with one unlabelled q1
`phylo_interaction(1 | plant:pollinator, tree1, tree2)` intercept in `sigma`.
This does not admit slopes, labels, covariance, q2-plus, other distributional
parameters, profiles, intervals, coverage, or inference.

## Evidence

- The source-pinned focused oracle receipt is in
  `2026-08-01-lane-c-c16-mc-0597-phylo-interaction-sigma-oracle-run-4/`; it
  checks the exact Kronecker precision/order, sigma endpoint, full mixture,
  objective, gradient, and latent-SD dependency.
- The final fixture retains four current-source attempts in
  `2026-08-01-lane-c-c16-mc-0597-phylo-interaction-sigma-local-run-4/`. All
  attempts pass convergence, Hessian, gradient, per-cell support, latent-mode,
  clamp, boundary, and recovery gates. The fixed-SD fit is diagnostic-only.
- `2026-08-01-lane-c-c16-mc-0597-phylo-interaction-sigma-source-binding.tsv`
  pins the model-15 R/C++ blobs, oracle test, and recovery runner.

## Fresh review

| Lens | Verdict | Scope |
| --- | --- | --- |
| Noether | GO | Kronecker ordering, precision, sigma carrier, likelihood, and oracle. |
| Fisher | GO | Full-mixture DGP, all-attempt recovery, and fixed-SD diagnostic. |
| Rose | GO | Source binding, receipt completeness, and claim boundary. |

The only supported ledger change is `mc-0597 -> point_fit_recovery`.
