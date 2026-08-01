# C16 `mc-0587` completion review — phylo-interaction zero-one-beta `mu` q1

## Decision

**GO — point-fit recovery only.** `mc-0587` is ordinary-ML
`zero_one_beta()` with one unlabelled q1
`phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree)`
intercept in `mu`. This does not admit slopes, labels, covariance, q2-plus,
other distributional parameters, profiles, intervals, coverage, or inference.

## Evidence

- The corrected Kronecker dense oracle and source-pinned focused test receipt
  are in `2026-08-01-lane-c-c16-mc-0587-phylo-interaction-mu-oracle-run-2/`.
  They use `Q_pollinator %x% Q_plant`, the matched index map, the normalized
  precision penalty, and the model-15 inward mean transform.
- The final fixture retains four current-source attempts in
  `2026-08-01-lane-c-c16-mc-0587-phylo-interaction-mu-local-run-2/`. All pass
  convergence, Hessian, gradient, latent-mode, clamp, boundary, and recovery
  gates. The IID control is a carrier control only.
- Earlier C16 runner/test receipts remain in the audit trail and are not
  substituted for the final source-bound evidence.
- `2026-08-01-lane-c-c16-mc-0587-phylo-interaction-mu-source-binding.tsv`
  pins the model-15 R/C++ blobs, repaired oracle test, and recovery runner.

## Fresh review

| Lens | Verdict | Scope |
| --- | --- | --- |
| Noether | GO | Kronecker order, parameter map, carrier, and oracle. |
| Fisher | GO | Retained all-attempt recovery, DGP, and IID-control boundary. |
| Rose | GO | Source binding, receipt completeness, and claim boundary. |

The only supported ledger change is `mc-0587 -> point_fit_recovery`.
