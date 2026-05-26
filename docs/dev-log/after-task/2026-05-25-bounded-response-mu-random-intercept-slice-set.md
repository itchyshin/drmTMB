# After Task: Bounded-Response `mu` Random-Intercept Slice Set

## Goal

Close the paired bounded-response `mu` random-intercept set after adding
ordinary unlabelled location random intercepts for both `beta()` and
`beta_binomial()`.

## Implemented

The set now has two fitted first slices:

- `beta()` supports `bf(prop ~ x + (1 | id), sigma ~ z)` for strict `(0, 1)`
  responses.
- `beta_binomial()` supports
  `bf(cbind(success, failure) ~ x + (1 | id), sigma ~ z)` for counted
  successes out of known trials.

Both routes expose the fitted location random-effect SD in `sdpars$mu`, the
conditional effects in `random_effects$mu`, direct profile targets through
`profile_targets()`, and replication diagnostics through `check_drm()`.

## Checks Run

The slice-specific reports record focused parse, test, documentation, pkgdown,
stale-wording, and issue-maintenance checks. The set-level closeout added the
full package check:

```sh
Rscript -e "devtools::check()"
```

`R CMD check` completed in 5m 6.1s with:

```text
0 errors | 0 warnings | 0 notes
```

Final safe stale scans also distinguished current support from historical
fixed-effect planning rows and still-planned neighbours.

## Consistency Audit

The current status inventory now reports the same boundary:

- ordinary `mu` random intercepts are fitted for `beta()` and
  `beta_binomial()`;
- random slopes, labelled covariance blocks, bounded-response `sigma` random
  effects, exact 0/1 boundary mass, `zoi`/`coi`, structured bounded responses,
  known covariance, and bivariate or mixed bounded-response models remain
  planned or unsupported;
- broad Phase 18 fixed-effect proportion artifacts remain historical evidence
  for the fixed-effect lane, not formal recovery evidence for the new
  random-intercept slices.

## GitHub Issue Maintenance

Issue #57 now has both local status comments:

- beta `mu` random intercepts:
  https://github.com/itchyshin/drmTMB/issues/57#issuecomment-4538004084
- beta-binomial `mu` random intercepts:
  https://github.com/itchyshin/drmTMB/issues/57#issuecomment-4538301435

No issue was closed. The tutorial gate remains open because the fuller
reader-facing mixed-model example and any formal ADEMP/artifact lane are still
future work.

## What Did Not Go Smoothly

The final closeout scan was first run with shell-interpreted backticks in the
pattern, which produced harmless `zsh: command not found: mu` noise. The scan
was rerun with safe quoting before being treated as evidence.

## Team Learning

- Ada kept the set bounded to the two proportion-family first slices.
- Boole kept syntax to ordinary unlabelled `(1 | id)` terms.
- Gauss and Noether checked that the latent effects enter the relevant logit
  location predictors and not the `sigma` formulas.
- Curie and Fisher kept deterministic source-level recovery separate from
  future operating-characteristics claims.
- Grace closed with full `devtools::check()` in addition to the prior full
  `devtools::test()` and pkgdown checks.
- Rose kept historical fixed-effect artifact rows from becoming stale support
  claims for random-effect recovery.
- No spawned subagents were running.

## Known Limitations

The set is still a first-slice implementation. It does not add bounded-response
random slopes, labelled covariance, `sigma` random effects, exact 0/1 boundary
mass, `zoi`/`coi`, structured effects, known covariance, formal recovery grids,
or mixed/bivariate bounded-response models.

## Next Actions

The next safe project lane is a separate ADEMP/artifact plan for the two
ordinary bounded-response `mu` random-intercept slices, followed by a small
reader-facing mixed-model tutorial only after that evidence path is in place.
