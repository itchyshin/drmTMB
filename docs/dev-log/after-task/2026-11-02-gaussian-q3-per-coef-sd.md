# After-task report: Gaussian q3 and q4 blocks with per-coefficient sd() (2026-11-02)

## Outcome

Admitted for native TMB. A Gaussian ordinary correlated block of three or four
coefficients, for example `(1 + x + z | id)`, now accepts one
`sd(id, coef = ...) ~ w` formula per coefficient. A coefficient without a
formula keeps a constant SD. The Julia engine has no route for this shape and
was not touched. Poisson and NB2 q3 blocks stay refused.

## What changed

- `src/drmTMB.cpp`, Gaussian (model_type 1) re_cov block: a new data matrix
  `re_cov_member_sd_row` (group by block member, -1 for none). For a member with
  a row, the SD for group g is `exp(X_sd_mu row * beta_sd_mu)` with the same
  soft clamp and overflow guard as the ordinary SD path. The block still uses the
  existing `UNSTRUCTURED_CORR_t` correlation, now with `VECSCALE` built per
  group, so the covariance of group g is `D_g R D_g`. Other families ignore the
  new data (a 1 by 1 matrix of -1 is supplied by default).
- `R/drmTMB.R`: the Gaussian gate now admits exactly one unlabelled
  `correlated_block` of three or four coefficients with sd() formulas, resolves
  targets against the full mu registry, refuses sd() on any other term beside
  the block, builds the sd structure against the registry, and attaches the
  per-member rows (`drm_attach_re_cov_sd_rows`). Start values take the block's
  starting SD for the intercept of each sd() formula. The map fixes
  `log_sd_re_cov` for modelled members and skips the ordinary `log_sd_mu` map.
  `sdpars` reports per-group SDs under each sd() key and drops modelled members
  from the constant `mu` block. The ranef reconstruction
  (`transform_covariance_block_random_effects`) uses the per-group SDs.
- `R/methods.R`: `covariance_registry_member_sd` returns NA when a member has no
  constant SD (a modelled member), instead of a subscript error in `summary()`.
  The covariance summary therefore shows NA SD and covariance for modelled
  members, because their SD differs by group.
- `NEWS.md`: one entry.

## Tests

- New `tests/testthat/test-gaussian-q3-per-coef-sd.R`, 29 expectations.
  Oracle: exact dense Gaussian marginal, `Z_g D_g R D_g Z_g' + sigma^2 I` per
  group, built from `predict()` SDs and the parsed correlation names. It matches
  `logLik()` to 1e-8 for q3 (formulas on the intercept and x, z constant) and
  q4 (formulas on x and u, intercept and z constant). Emulated bugs the oracle
  separates by more than 1e-2: swapped coefficient SDs (q3 and q4), dropped
  correlation (q3 and q4), reversed group order (q3). Also: constant sd()
  formulas reproduce the ordinary q3 log-likelihood (1e-6), summary, vcov,
  ranef and `simulate(re.form = NULL)` run, and refusals are pinned by message
  (q5, unknown coefficient selector, duplicate formula).
- Changed (not receipted): `tests/testthat/test-ordinary-q3-sd.R`. The Gaussian
  q3 sd() refusal pin became a q5 pin with the new message pattern. Poisson and
  NB2 q3 pins are unchanged.
- Changed (RECEIPTED in direct-sd-evidence.tsv, rows citing
  test-gaussian-correlated-q2-sd.R): the single test "Gaussian correlated q3 SD
  regression stays closed" now pins q5 (formula `1 + x + z + u + v`) with the
  pattern "five or more coefficients". No assertion was deleted or loosened; the
  refusal moved to a shape that is still refused because q3 is now admitted.
  The q2 receipts themselves are unaffected (that file still passes 17/17).

## Verification (Totoro, cores 0-3, NOT_CRAN=true)

New file 29 passed; test-ordinary-q3-sd.R 9 passed; neighbours
test-gaussian-correlated-q2-sd.R 17, test-gaussian-sd-slope-regression.R 13,
test-gaussian-independent-pair-sd.R 10, test-gaussian-batch5-sd-regression.R 103
(2 skipped, held route), test-covariance-block-registry.R 184,
test-gaussian-random-intercepts.R 429, test-corpairs.R 116,
test-profile-targets.R 986, test-julia-ordinary-sd-fence-exemption.R 89,
test-gaussian-structured-q2-sd.R 64, test-biv-gaussian.R 948,
test-optimizer-contract.R 200. All with 0 failed and 0 errors.

## Not covered

- No calibration or coverage run; one fixed fixture per shape.
- Marginal `simulate(re.form = NA)` still refuses correlated covariance blocks
  (existing behaviour, with or without sd()).
- Profile or confint targets for the constant `mu` SD of unmodelled members were
  not specifically tested; Wald `confint` runs.
- Not admitted: q5 or larger, labelled q3 blocks (`(1 + x + z | p | id)`), sd()
  on other terms beside the block, sigma-target sd(), missing-response include,
  aggregated Gaussian, Julia engine.
- The full test suite was not run; only the files listed above.
- Process note: the Totoro ControlMaster refused a new session twice (too many
  sessions from sibling lanes), and ssh fell back to a plain key login without
  a Duo prompt; no process was left running.
