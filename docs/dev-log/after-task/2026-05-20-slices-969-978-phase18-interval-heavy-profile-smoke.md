# Slices 969-978: Phase 18 Interval-Heavy Profile Smoke

## Goal

Ada ran a tiny profile-enabled interval-heavy smoke for Student-t shape and
bivariate residual `rho12`.

## Run

The run called `phase18_run_interval_heavy_summary_smoke()` with:

- `profile_parameters = c("nu:w", "rho12:w")`;
- `profile_level = 0.70`;
- `profile_args = list(ystep = 0.75)`;
- `n_rep = 1`;
- no bootstrap.

## Validation

Output root:

- `inst/sim/results/slice-969-interval-heavy-profile-smoke/`

Rendered report:

- `inst/sim/results/slice-969-interval-heavy-profile-smoke/interval-heavy-summary/report/phase18-first-wave-summary.html`

Observed rows:

- Aggregate rows: 16.
- Profile interval rows: 2.
- Profile coverage rows: 2.
- Interval failure rows: 0.
- Failure rows: 0.
- Profile statuses: `ok`.
- Profile parameters: `nu:w`, `rho12:w`.

The rendered report includes `profile` evidence and the interval-coverage
summary.

## Mathematical Contract

No code changed in this slice. The run validates the existing profile interval
path through the new interval-heavy summary runner.

## Team Learning

- Ada: `nu:w` and `rho12:w` can be requested together because each surface only
  profiles matching parameter rows.
- Fisher: the first profile-enabled interval-heavy smoke produced finite
  profile intervals for both targets.
- Curie: profile coverage artifacts are correctly staged into the report.
- Grace: no profile or report failures appeared in this tiny smoke.
- Pat: the report exposes profile evidence in the same interval-coverage
  section as Wald evidence.
- Rose: bootstrap remains deliberately separate and should be tested with a
  tiny capped smoke, not assumed from profile success.

## Known Limitations

- One replicate and a 70% profile interval are smoke evidence only.
- Bootstrap was not run in this slice.

## Next Actions

1. Run a tiny bootstrap-enabled interval-heavy smoke with very small `nsim`.
2. Keep bootstrap worker counts capped and recorded.
