# C16 `mc-0593` completion review — phylogenetic zero-one-beta `sigma` q1

## Decision

**GO — point-fit recovery only.** `mc-0593` is ordinary-ML
`zero_one_beta()` with one unlabelled q1 `phylo(1 | species, tree = tree)`
intercept in `sigma`. This does not admit slopes, labels, covariance, q2-plus,
other distributional parameters, profiles, intervals, coverage, or inference.

## Evidence

- The source-pinned focused oracle receipt is in
  `2026-08-01-lane-c-c16-mc-0593-phylo-sigma-oracle-run-4/`; it verifies the
  sigma endpoint, complete atom/interior mixture, phylogenetic precision
  penalty, objective, gradient, and latent-SD dependency.
- The final fixture retains four current-source attempts in
  `2026-08-01-lane-c-c16-mc-0593-phylo-sigma-local-run-4/`. All pass
  convergence, Hessian, gradient, per-group support, latent-mode, clamp,
  boundary, and recovery gates. The fixed-SD fit is diagnostic-only.
- Earlier C16 runner/test receipts remain in the audit trail and are not
  substituted for the final source-bound evidence.
- `2026-08-01-lane-c-c16-mc-0593-phylo-sigma-source-binding.tsv` pins the
  model-15 R/C++ blobs, oracle test, and recovery runner.

## Fresh review

| Lens | Verdict | Scope |
| --- | --- | --- |
| Noether | GO | Sigma endpoint carrier, precision, likelihood, and oracle. |
| Fisher | GO | Full-mixture DGP, all-attempt recovery, and fixed-SD diagnostic. |
| Rose | GO | Source binding, receipt completeness, and claim boundary. |

The only supported ledger change is `mc-0593 -> point_fit_recovery`.
