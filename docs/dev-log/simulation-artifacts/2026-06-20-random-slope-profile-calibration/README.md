# Gaussian random-slope fixed-effect PROFILE-interval calibration (500 reps) — Profile cell evidence

**Date:** 2026-06-20 · **Author:** Ada (autonomous) · **Gate:** Fisher

Profile-likelihood interval calibration for the two FIXED-effect mu coefficients of
the Gaussian correlated random-slope model, with Wald alongside. Same DGP as the
random-slope recovery (`2026-06-20-gaussian-random-slope-recovery/`):
`bf(y ~ x + (1 + x | id), sigma ~ 1)`, n_group in {40, 80}, 8 obs/group. Coefficient
profiles use the fast endpoint solver via `profile_engine = "auto"`, which made this
RE-model calibration tractable (~40 min). The random-effect SD intervals are a
separate, harder target and are NOT addressed here.

## Result (`tables/random-slope-profile-summary.csv`; 0 fit errors, 0 CI failures, pdHess 1.000)

| cell | profile coverage | wald coverage | profile width | wald width |
| --- | --- | --- | --- | --- |
| n_group=40 mu:(Intercept) | 0.938 | 0.932 | 0.337 | 0.329 |
| n_group=40 mu:x | 0.932 | 0.922 | 0.295 | 0.288 |
| n_group=80 mu:(Intercept) | 0.966 | 0.960 | 0.239 | 0.236 |
| n_group=80 mu:x | 0.948 | 0.946 | 0.211 | 0.209 |

(coverage MCSE 0.008-0.012.)

## Finding

- **Profile intervals are well-calibrated for the random-slope fixed effects and are
  slightly better than Wald.** Profile intervals are marginally wider (more accurate
  small-sample) so profile coverage exceeds Wald at every cell. Critically, all four
  profile cells clear the project 0.93 floor -- including the n_group=40 slope at
  0.932, where the Wald slope is 0.922 (the cell that holds the Random slopes Wald
  cell at partial). 0 CI failures across all 2000 intervals; nominal by n_group=80
  (0.948-0.966).
- The n_group=40 profile cells (0.932, 0.938) sit just above the floor and are within
  ~1 Monte-Carlo SE of it, so they are best read as "approximately nominal, borderline
  at small group counts," not tight calibration.

## Scope / boundary

Native R/TMB, Gaussian, one correlated random-slope block; profile calibration for the
two FIXED-effect mu coefficients only. Random-effect SD (sd_int, sd_slope) interval
calibration, the random-effect correlation rho, bootstrap intervals, and the Julia
bridge are separate and remain planned. The asserted guarantee is profile-vs-Wald
parity-or-better for the fixed-effect coefficients, all cells above the 0.93 floor,
nominal by n_group=80 -- not a small-n exactness claim.

## How to reproduce

```sh
cd /Users/z3437171/.codex/worktrees/540b/drmTMB
/usr/local/bin/Rscript --vanilla \
  docs/dev-log/simulation-artifacts/2026-06-20-random-slope-profile-calibration/run.R 500
```
