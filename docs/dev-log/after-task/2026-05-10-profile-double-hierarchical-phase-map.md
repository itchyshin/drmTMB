# After Task: Profile CI And Double-Hierarchical Phase Map

## Goal

Turn the user's 5 AM priority list into a concrete project map: profile
likelihood confidence intervals should have a first implementable slice, and
the complete double-hierarchical individual-difference model should have a
clear endpoint that separates fitted pieces from planned covariance work.

## What Changed

- Added `docs/design/28-double-hierarchical-endpoint.md`.
- Updated `ROADMAP.md` so Phase 6 is direct-parameter profile-likelihood
  inference and Phase 13 is derived inference for complete
  double-hierarchical models.
- Added a first implementation slice to
  `docs/design/12-profile-likelihood-cis.md`: build a target inventory such as
  `profile_targets(fit)` before exposing `confint.drmTMB(method = "profile")`.
- Updated `docs/design/20-coscale-correlation-pairs.md` and
  `docs/design/04-random-effects.md` so reader-facing prose talks about
  individual averages, mean-model slopes, residual scale, and scale-model
  slopes.
- Recorded this work in `docs/dev-log/check-log.md`.

## Current Status

| Track | Current Status | Next Implementable Slice |
|---|---|---|
| Profile likelihood CIs | Planned | Add an internal profile target inventory for direct parameters |
| Direct fixed-effect intervals | Planned | Start with `mu`, `sigma`, `nu`, `zi`, `hu`, and `rho12` coefficients |
| Random-effect SD intervals | Planned | Profile direct log-SD parameters after target names are stable |
| Derived intervals | Planned | Wait until direct profiles and named derived extractors are stable |
| `corpairs()` | Partly implemented | Extend rows only when new group-level covariance blocks are fitted |
| Complete double-hierarchical model | Planned | Add one cross-formula covariance block at a time |

## Review Notes

Fisher's lens: profile CIs should start with direct internal parameters, not
derived quantities. Boundary flags and failed-inner-optimization messages must
be part of the returned table, not transient warnings.

Noether's lens: the target names must map exactly to fitted object labels and
TMB parameters. Derived quantities such as repeatability or correlation-pair
summaries should wait until their algebra and extractors are stable.

Boole's lens: the first public API should list available targets and reject
unsupported targets with a message that shows the user what can be profiled.

Pat and Rose's lens: reader-facing docs should not depend on shorthand from a
paper. The new wording says what the model components are in ordinary terms
before introducing any field-specific interpretation.

## Checks

- `air format ROADMAP.md docs/design/04-random-effects.md docs/design/12-profile-likelihood-cis.md docs/design/20-coscale-correlation-pairs.md docs/design/28-double-hierarchical-endpoint.md`: passed.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- Rendered roadmap scan confirmed the site includes the Phase 13 rename and the
  new double-hierarchical endpoint-map reference.
- `Rscript -e "devtools::test()"`: passed with 0 failures, 0 warnings, 0 skips,
  and 1480 passing expectations.
- Stale shorthand scan over the touched roadmap and design docs: passed after
  the final wording pass.

## Known Limitations

No profile-likelihood code was added. No cross-formula covariance likelihood
was added. No new `corpairs()` rows are available until the corresponding
covariance blocks are fitted and tested.
