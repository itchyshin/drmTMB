# After-task report: G4 save, refit and inference semantics (2026-11-01)

## Scope

Test-only slice. New file `tests/testthat/test-sd-regression-g4-semantics.R`
checks save/refit/inference behaviour of predictor-dependent random-effect SD
fits. No source changes, no existing test edited, no receipted test touched.

## Fits covered

One fit per family, mixing ordinary and structured routes, one q2 route.
Fixtures are small (24 groups, 10 rows per group) and seeded.

- Gaussian: ordinary `(1 | id)`, `sd(id) ~ w`.
- Poisson: ordinary `(1 | id)`, `sd(id) ~ w`.
- Binomial: `relmat(1 | id, K)`, shuffled non-unit-diagonal K.
- NB2: `animal(1 | id, A)`, shuffled non-unit-diagonal A.
- Gamma: `phylo(1 + x | id)` (q2), one SD formula per coefficient.

## Checks and results

(a) saveRDS/readRDS: coef(), logLik(), predict(dpar = SD) and
predict(dpar = SD, newdata = group-level rows) are identical after the round
trip. The newdata prediction equals exp(a0 + a1 * covariate) computed from the
coefficients, and a sign-reversed formula differs (sensitivity).

(b) update(fit, data = same data) refits to the same coefficients and logLik
(relative 1e-6). The same call on data with the SD covariate reversed gives a
different SD slope (sensitivity).

(c) Refit on one seeded simulate(fit, re.form = NA) draw converges and returns
the same coefficient names, SD target names and SD prediction level names.

(d) confint() on an SD coefficient. Wald works for every route (finite,
brackets the estimate, correct tmb_parameter). Method "profile" is accepted for
every route. Recorded outcome on these fixtures: finite interval for Gaussian,
Poisson and Gamma q2; `conf.status = "clamp_limited"` with NA bounds and a
message for Binomial relmat and NB2 animal. The test accepts either a finite
bracketing interval or an explicit non-wald, non-profile status with a message,
so a silent NA fails. An unknown SD target is refused with an error.

(e) The fit stores the SD design: `model$random_scale$mu$X_list` (ordinary) or
`model$random_scale$phylo$X_list` (structured; animal and relmat also use the
phylo slot) holds one row per group with the covariate column in the group
order of `group_levels_list`. The stored provider precision, inverted at the tip
nodes, reproduces the true kernel to 1e-8, including the non-unit diagonal and
shuffled order, before and after a save/read round trip.

## Commands

On Totoro (cores 0-3, one R process): `test_file` on the new file gave
passed 210, failed 0, error 0, skipped 0 (about 20 seconds).

## Not covered

Constant-SD equivalence and dense-oracle likelihoods (held by the per-family
files), calibration or coverage of the intervals, bootstrap intervals,
spatial and pedigree providers, the Julia engine, and more than one
simulated draw per route.

## Open items

- Profile intervals for Binomial relmat and NB2 animal are clamp-limited on
  this fixture. This is reported behaviour, not a failure; a larger fixture
  may remove it.
- The structured routes store the SD design under `random_scale$phylo` even
  for animal and relmat; the Binomial fit also carries a `phylo2` slot. This
  is an internal naming quirk, pinned only by this file.
