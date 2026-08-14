# MD9b joint Gaussian recovery: completion receipt

## Immutable run receipt

- Host: `totoro` (384 cores); campaign cap: 60 one-core workers, below the
  binding 150-core shared-server cap.
- Start/end: 2026-08-13 21:53:14--21:53:32 MDT.
- Source base: `bdd6526501970f77567551165885cfb777f7ee28` plus the recorded
  worktree diff SHA-256
  `3860ab11d3e1e6073eff2ed98b7b94bf156d24f94cb3ce87374233e7408c0d36`.
- Source manifest SHA-256:
  `19641129ac467fab82df780255928cd27342a4e3f463ffddd96bab35aad05118`.
- Combined result-file manifest SHA-256:
  `49c66199653aa6ebac0f8472ee3bdf5774f5db39aed4adbe6c1b49344cdba08c`.
- Artifacts: 60 disjoint CSV shards, 3,000 unique deterministic attempts, and
  regenerated replicate-, cell-, and parameter-level summaries in
  `simulation-artifacts/2026-08-13-joint-mi-gaussian-recovery/`.

## Gaussian decision

**PROMOTE to `point_fit_recovery` for the exact MD9b Gaussian scope.** All 12
preregistered MCAR cells (`n = 300, 600, 1200`; predictor correlation `0.2,
0.6`; independent missingness `0.2, 0.4`) retained 250/250 usable fits. Across
all 3,000 attempts there were zero errors, convergence failures, non-positive
definite Hessians, or gradient exclusions. The largest absolute mean error was
`0.01415` for `sigma_x2` (about 1.2% of its truth 1.2); it is reported rather
than described as zero bias.

The claim is limited to fixed-effect Gaussian response and predictor models,
two bare continuous predictors, a common imputation right-hand side, constant
response `sigma`, and MCAR masking. It does **not** cover MAR/MNAR, response
missingness, random or structured terms, offsets, REML, additional or mixed
predictors, interval calibration, or coverage.

## Poisson decision

**KEEP experimental numerical proof.** The ordinary Poisson MD9b route has a
separate fixed-DGP one-dimensional quadrature oracle; its observed-data NLL
difference from the TMB/Laplace objective is `0.0109669`, within the fixed
`0.05` tolerance. It has no recovery or coverage evidence and is not a general
non-Gaussian admission.

## Independent review

- Fisher: PASS for Gaussian `point_fit_recovery` after status reconciliation;
  HOLD anything broader.
- Noether: PASS: DGP, R payload, C++ likelihood, oracle, and recovery labels
  align.
- Rose: evidence gate PASS; promotion closeout required this receipt and the
  stale-status corrections above.
