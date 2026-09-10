# T3-9 — measured marginal Toeplitz profile campaign proposal

The frozen T3-8 contract requires 4,000 profiles: 1,000 each in P1, P2, P3,
and descriptive stress cell S1. The retained five-seed pre-run completed all 15
fits with three finite profile intervals each in 2.08--4.01 seconds per data
set (median 2.35 seconds).

## Proposed DRAC/Fir array

- **Target:** DRAC/Fir, checked live immediately before submission.
- **Array:** 4,000 independent tasks, one generated data set per task.
- **Resources per task:** one CPU, `OMP_NUM_THREADS=1`, `OPENBLAS_NUM_THREADS=1`,
  2 GB RAM, and a 10-minute wall-time limit.
- **Estimated compute:** about 2.6 CPU-hours at the observed median, plus
  scheduler and restart allowance. The 10-minute limit gives substantial room
  for the observed 4.01-second maximum without creating a long-running task.
- **Storage:** live Fir inspection found `/project` already at its 500K file
  quota, and compute nodes do not mount `/nearline`. Each task therefore writes
  one compressed immutable artifact under the backed-up Fir home filesystem;
  expanded CSV evidence is node-local only. Mirror the completed immutable
  artifacts to Totoro, then remove the temporary Fir staging after retained
  evidence is verified. Do not store campaign outputs in the package working
  tree until the reverify step selects the complete retained set.
- **Failure policy:** every array index writes one result record. A timeout,
  fit failure, or missing endpoint remains in the all-attempt denominator;
  reruns use the same deterministic index/seed only for infrastructure failure,
  with both attempts retained.

The planned campaign evaluates the T3-8 profile-only mean-effect claim. It does
not authorize Wald intervals, covariance-parameter intervals, forecasts, a
release, a push, or a merge.

## Authorization needed

Before submission, verify Fir capacity and the current durable project path,
then obtain explicit authorization for this exact 4,000-task campaign.
