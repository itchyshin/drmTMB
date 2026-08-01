# C16 `mc-0583` completion review — phylogenetic zero-one-beta `mu` q1

## Decision

**GO — point-fit recovery only.** `mc-0583` is the exact ordinary-ML
`zero_one_beta()` route with one unlabelled q1 `phylo(1 | species, tree = tree)`
intercept in `mu`. This is a single-cell ledger transition. It does not support
profiles, intervals, coverage, inference readiness, q2-plus effects, slopes,
labels, covariance, or structured effects in another distributional parameter.

## Evidence bound to the decision

- Four planned source-pinned recovery attempts are retained in
  `2026-08-01-lane-c-c16-mc-0583-phylo-mu-local-run-2/`; all passed the local
  convergence, Hessian, gradient, boundary, and latent-mode gates.
- The focused model-15 oracle run is retained in
  `2026-08-01-lane-c-c16-wave-a-oracle-tests-run-4/`; it exercises the full
  zero/one/interior mixture, phylogenetic precision penalty, objective,
  finite-difference gradient, and nonzero-SD dependency sentinel.
- The four-seed IID `mu` endpoint control is retained in
  `2026-08-01-lane-c-c16-zob-iid-controls-run-2/`. It is a carrier control,
  not a substitute for the phylogenetic recovery evidence.
- `2026-08-01-lane-c-c16-wave-a-model15-source-equivalence.tsv` binds the
  recovery, oracle, and control source revisions to identical `R/drmTMB.R` and
  `src/drmTMB.cpp` model sources.

## Fresh independent review

| Lens | Verdict | Scope checked |
| --- | --- | --- |
| Noether | GO | Parameter map, endpoint routing, mixture and precision oracle. |
| Fisher | GO | Exact DGP, retained four attempts, local recovery threshold and carrier control. |
| Rose | GO | Claim boundary, source equivalence, retained attempts and no-profile fence. |

All three reviews apply only to `mc-0583` at `point_fit_recovery` grade.
