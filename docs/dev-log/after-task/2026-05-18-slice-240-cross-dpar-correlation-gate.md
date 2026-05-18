# Slice 240 Cross-Dpar Correlation Gate

## Goal

Record which cross-distributional-parameter random-effect correlation surfaces
can enter Phase 18 Wave A, and keep planned non-Gaussian, slope-level, shape,
inflation, hurdle, one-inflation, and `rho12` random-effect covariance surfaces
out of broad simulations until focused gates close.

## Implemented

- Added `docs/design/45-cross-dpar-correlation-gate.md`.
- Linked the gate from the Phase 18 simulation programme.
- Updated `ROADMAP.md` and `NEWS.md` with the same fitted-versus-planned
  boundary.
- Added this check-log entry.

## Mathematical Contract

Residual correlation, group-level covariance, structured covariance, and known
sampling covariance are separate model layers:

```text
rho12_i = tanh(X_rho12[i, ] beta_rho12)
u_j ~ MVN(0, Sigma_group)
z ~ MVN(0, sigma_z^2 K)
y ~ MVN(mu, V_known + Omega_estimated)
```

Only the first line is residual `rho12`. Only the last line contains known
sampling covariance `V`, and `V` is not estimated. Fitted random-effect
correlations are constant block hyperparameters except for the already fitted
q=2 intercept-level `corpair()` lanes.

## Files Changed

- `docs/design/45-cross-dpar-correlation-gate.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format docs/design/45-cross-dpar-correlation-gate.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-240-cross-dpar-correlation-gate.md`
- `Rscript -e "devtools::test(filter = 'biv-gaussian|corpairs|profile-targets|check-drm|nongaussian-scale-boundary|student-location-scale|nongaussian-structured-boundary|beta-location-scale|beta-binomial|spatial-gaussian|phylo-gaussian', reporter = 'summary')"`
- `git diff --check`
- `rg -n 'Pending\.' docs/design/45-cross-dpar-correlation-gate.md docs/dev-log/after-task/2026-05-18-slice-240-cross-dpar-correlation-gate.md`
- `rg -n '\bzi\b.*random effects.*implemented|\bnu\b.*random effects.*implemented|rho12 random-effect|random effects in rho12.*implemented' docs/design/45-cross-dpar-correlation-gate.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md`

## Tests Of The Tests

This is a documentation and status-gate slice. The targeted tests cover
existing fitted correlation surfaces and existing unsupported-boundary tests:
bivariate Gaussian covariance, `corpairs()`, `profile_targets()`,
`check_drm()`, non-Gaussian scale/shape boundaries, and non-Gaussian structured
boundaries.

## Consistency Audit

The new gate aligns with:

- `docs/design/12-profile-likelihood-cis.md` for direct versus derived profile
  targets;
- `docs/design/20-coscale-correlation-pairs.md` for residual `rho12` versus
  latent random-effect `corpair()` syntax;
- `docs/design/34-validation-debt-register.md` for non-Gaussian, shape,
  inflation, hurdle, one-inflation, and structured validation debt;
- `docs/design/44-structured-slope-parity-gate.md` for spatial, phylogenetic,
  animal, and `relmat()` one-slope status.

## What Did Not Go Smoothly

The main risk is over-compression. Saying "correlations are fixed" is false
for residual `rho12 = ~ x` and for fitted q=2 `corpair()` regression lanes, but
saying "correlations can be modelled" overstates slope-level, q=4, and
non-Gaussian covariance support. The gate therefore names each correlation
layer separately.

## Team Learning

Ada kept the Wave A admission rule explicit. Fisher separated fitted interval
targets from planned covariance surfaces. Pat kept the user-facing fallback
examples concrete. Noether kept `rho12`, `Sigma_group`, structured `K`, and
known `V` mathematically separate. Rose flagged the stale-promise risk around
`zi`, `hu`, `zoi`, `coi`, `nu`, and random effects in `rho12`.

## Known Limitations

This slice does not add likelihood code, new extractors, or new simulation
runners. It does not implement mixed-distribution bivariate models,
non-Gaussian cross-parameter covariance, shape random effects, random effects
in `rho12`, animal/`relmat()` fitting, or slope-level `mu`/`sigma` covariance.

## Next Actions

Use the next implementation slice for either a coordinate-spatial one-slope
smoke surface or a Poisson/NB2 non-Gaussian `mu` random-effect simulation
surface, depending on which Wave A gap is more urgent after the stacked
random-slope gate PRs merge.
