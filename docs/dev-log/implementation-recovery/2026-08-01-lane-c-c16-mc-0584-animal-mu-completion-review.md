# C16 `mc-0584` completion review — animal zero-one-beta `mu` q1

## Decision

**GO — point-fit recovery only.** `mc-0584` is ordinary-ML
`zero_one_beta()` with one unlabelled q1 `animal(1 | species, Ainv = Ainv)`
intercept in `mu`. This does not admit slopes, labels, covariance, q2-plus,
other distributional parameters, profiles, intervals, coverage, or inference.

## Evidence

- The initial formula-environment failures and the telemetry-runner failures
  are retained in the audit trail; neither is represented as a successful fit.
- The final post-repair fixture retains four planned attempts, all passing the
  convergence, Hessian, gradient, latent-mode, clamp, boundary, and recovery
  gates: `2026-08-01-lane-c-c16-mc-0584-animal-mu-local-run-4/`.
- The corrected dense oracle and its focused source-pinned execution receipt
  are retained in `2026-08-01-lane-c-c16-mc-0584-animal-mu-oracle-run-2/`.
  The oracle uses the model-15 inward mean transform and full animal-precision
  penalty.
- `2026-08-01-lane-c-c16-mc-0584-animal-mu-source-binding.tsv` records the
  relevant model-15 R/C++ source identities for the oracle and recovery.
- The shared IID `mu` endpoint control remains a carrier control only; it is
  not substituted for the animal-precision recovery evidence.

## Fresh review

| Lens | Verdict | Scope |
| --- | --- | --- |
| Noether | GO | Exact parameter map, `Ainv` precision, C++ endpoint route, and corrected oracle. |
| Fisher | GO | Retained all-attempt accounting and local recovery gate. |
| Rose | GO | Source binding, claim boundary, and explicit runner-failure retention. |

The only supported ledger change is `mc-0584 -> point_fit_recovery`.
