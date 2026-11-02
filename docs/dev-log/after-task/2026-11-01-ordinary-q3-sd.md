# After-task report: ordinary q3 blocks with sd() formulas (2026-11-01)

## Outcome

Not admitted. The probe found that the route needs a new engine layer in each
family, so per the task rule the work stopped at a design report. Nothing in
R/ or src/ changed. Two test changes ship: a new boundary-pin file and a
tightened message pattern on an existing refusal pin.

## What the probe found (R probe on the private copy, no SD, then with SD)

- Gaussian `(1 + x + z | id)` without sd() fits. It does not use the ordinary
  mu random-effect arrays. `remove_qgt2_random_mu_terms` strips any term with
  more than two coefficients, and the block is carried by the separate re_cov
  registry (`n_re_cov_blocks`, `log_sd_re_cov`, `theta_re_cov`, dense
  `UNSTRUCTURED_CORR_t` with `VECSCALE` and one constant SD per member).
- Gaussian q3 with sd() is refused by a designed message ("cannot be combined
  with a correlated random-effect block of three or more coefficients"). The
  old pin comment calling this an internal metadata error was stale; the
  message is clean and is now pinned by pattern.
- Poisson and NB2 refuse any q3 block, with or without sd(), at the
  correlated-term gate ("support one unlabelled Poisson intercept-slope
  block"). Their C++ branches only apply the q2 pair conditioning
  (`mu_re_pos == 1` with `mu_re_pair_index`).
- Only Binomial (model_type 18) has the q >= 3 ordinary route with per-
  coefficient SD rows: modified-Cholesky partial correlations, row-major, with
  `sd_row` applied per coefficient.

## Why it is a new engine layer

1. Gaussian: per-group SD has to enter the re_cov path. That needs a per-member
   SD row for each latent group in `re_cov_*` data, `sd_mu_group` use inside the
   block loop, sd target resolution against re_cov members (today
   `drm_scalar_sd_mu_targets` reads only the ordinary `re_mu` registry), start
   values, `sdpars` and `predict(dpar = sd(...))` plumbing, and the simulate and
   ranef reconstruction at the `log_sd_re_cov` sites in R/drmTMB.R.
2. Poisson and NB2: first a q3 correlated route must exist at all. That means
   the `binomial_correlated` flag in `build_random_mu_structure`, the Binomial
   q >= 3 C++ block copied into each family branch, the `eta_cor_mu` start and
   the corpars, simulate and ranef switches that currently test
   `identical(spec$model_type, "binomial")` (R/drmTMB.R near lines 26172 and
   26793), then the sd target gate.
3. Each of the three is a separate compile and recovery cycle. Together they
   exceed the 3 hour line.

## Suggested design for the next lane

Do Poisson first, because it is the smallest: port the Binomial q >= 3
modified-Cholesky block (src/drmTMB.cpp, model_type 18, mu_re_block_q logic)
into the Poisson and NB2 mu random-effect loops, generalise the three
`binomial`-only R switches to a `partial_cor_q3` family set, then add the sd
target gate. Oracle: dense Laplace at the fitted parameters (Poisson/NB2) with
the covariance S_g = D_g R D_g and a non-unit-diagonal check via shuffled levels.
Gaussian should follow by giving the re_cov block a per-group SD row; the exact
marginal oracle in test-gaussian-correlated-q2-sd.R extends to q3 directly
(Z is n by 3, S_g = D_g R D_g, plus sigma^2 I).

## Tests

- New: tests/testthat/test-ordinary-q3-sd.R, 9 expectations: Gaussian q3
  without sd() fits; Gaussian q3 with sd() on each coefficient refused by
  pattern; Poisson and NB2 q3 refused with and without sd() by pattern.
- Tightened: the Gaussian q3 pin in test-gaussian-correlated-q2-sd.R now
  carries the refusal message pattern and a corrected comment. No assertion or
  tolerance was removed or loosened. The pin stays at q3 because q3 was not
  admitted, so no swap to q4 was made.
- Counts: test-ordinary-q3-sd.R 9 passed, 0 failed, 0 errors, 0 skipped.
  test-gaussian-correlated-q2-sd.R 17 passed, 0 failed, 0 errors, 0 skipped.

## Not covered

No numeric oracle, no recovery run, no Julia engine check. Poisson and NB2
neighbour files were not re-run because no R or C++ code changed.
