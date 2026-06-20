# Non-Gaussian fixed-effect mu PROFILE-interval calibration (500 reps x 6 families) — Profile cell evidence

**Date:** 2026-06-20 · **Author:** Ada (autonomous) · **Gate:** Fisher

Profile-likelihood interval calibration for the fixed-effect `mu` coefficients across
the six implemented one-response non-Gaussian families, with Wald computed alongside.
Coefficient profiles use the fast endpoint solver via `profile_engine = "auto"` (the
endpoint engine now handles fixed-effect coefficients), which made this 6-family x
2-n x 500-rep calibration tractable (~24 min).

## Design (deterministic, `master_seed = 20260620`)

- Families: poisson, nbinom2, Gamma, lognormal, beta, student. `mu = b0 + b1*x` on the
  family link; `b0 = 0.5`, `b1 = 0.4`. `n in {300, 600}`, 500 reps/cell.
- `confint(method = "profile")` and `method = "wald")` for `mu:(Intercept)` and
  `mu:x`; coverage of the link-scale truth, widths, conf.status tracked.

## Result (`tables/nongaussian-profile-summary.csv`; 0 fit errors)

Profile coverage tracks Wald to within Monte-Carlo noise at every cell (MCSE
0.008-0.012); widths near-identical. Both reach nominal by n=600. Selected cells:

| family | n=300 intercept / slope (profile) | n=600 intercept / slope (profile) |
| --- | --- | --- |
| poisson | 0.964 / 0.936 | 0.968 / 0.944 |
| nbinom2 | 0.936 / 0.936 | 0.950 / 0.958 |
| Gamma | 0.958 / 0.944 | 0.950 / 0.950 |
| lognormal | 0.962 / 0.944 | 0.940 / 0.946 |
| beta | 0.960 / 0.956 | 0.952 / 0.950 |
| student | 0.936 / 0.930 | 0.952 / 0.946 |

## Finding

- **Profile intervals track Wald to within Monte-Carlo noise for non-Gaussian
  fixed-effect mu coefficients across all six families**, reaching nominal by n=600
  (the across-the-board ~0.95 statement holds at n>=600; at n=300 three slope cells
  are mildly sub-nominal, below). 0 profile CI failures across all 6000 profile
  intervals.
- The weakest cells are the n=300 slopes for the count/heavy-tailed families
  (nbinom2 0.936, poisson 0.936, student 0.930) -- mildly below nominal under BOTH
  profile and Wald; this is the same small-n behaviour that holds the Non-Gaussian
  Wald cell at `partial`.
- Profile is marginally MORE robust than Wald on the student n=300 cells: profile
  produced intervals on all 500 reps, while Wald had 2 CI failures (non-pdHess fits).

## Scope / boundary

Native R/TMB, fixed-effect mu only, six one-response families, complete data. Profile
calibration for the two mu coefficients, in parity with the existing Wald cell (same
small-n undercoverage on the count/heavy-tailed n=300 slopes). The asserted guarantee
is profile-vs-Wald parity and ~0.95 calibration at n>=600. Not random/structured
effects, not scale/shape (`sigma`, `nu`) intervals, not the Julia bridge.

## How to reproduce

```sh
cd /Users/z3437171/.codex/worktrees/540b/drmTMB
/usr/local/bin/Rscript --vanilla \
  docs/dev-log/simulation-artifacts/2026-06-20-nongaussian-profile-calibration/run.R 500
```
