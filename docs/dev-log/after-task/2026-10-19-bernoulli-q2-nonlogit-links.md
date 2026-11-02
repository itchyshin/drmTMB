# After Task: Bernoulli Correlated-q2 Probit and Cloglog Links

## Goal

Keep correlated Bernoulli random-intercept/random-slope SD regression exercised
under the supported probit and complementary log-log links, and check its
marginal likelihood independently of the TMB objective.

## Implemented

Extended the independent two-dimensional Gauss-Hermite test helper to evaluate
logit, probit, or cloglog Bernoulli probabilities. Added deterministic synthetic
q2 fits for probit and cloglog with separate group-level predictors for the
intercept and slope SDs. Both cases check convergence, Hessian status, finite SD
coefficients and predictions, and agreement with the independent marginal
likelihood oracle.

This records native candidate support for these two links in this ordinary q2
layout. It does not establish the wider programme's family, provider, endpoint,
engine, recovery, or uncertainty requirements.

## Mathematical Contract

For each group, the tested latent covariance is

\[
\Sigma_g = D_g R D_g,\qquad
D_g = \operatorname{diag}\{\exp(W_{0g}\alpha_0),
                              \exp(W_{1g}\alpha_1)\},
\]

where the two SD designs are fixed at the group level and \(R\) has one fitted
correlation. The response likelihood uses the selected binomial link. The
test's independent Gauss-Hermite calculation integrates both latent effects
under that same covariance and link.

## Files Changed

- `tests/testthat/test-binomial-correlated-sd.R`
- `docs/dev-log/check-log.d/2026-10-19-bernoulli-q2-nonlogit-links.md`
- This report.

## Checks Run

- Independent exploratory q2 smoke, with seed `20261019`, fitted probit and
  cloglog data successfully in 13.97 seconds total; each fit had convergence
  code 0, a positive-definite Hessian, and finite SD coefficients and
  predictions.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript --vanilla -e
  'devtools::test(filter = "binomial-correlated-sd", reporter = "summary")'`:
  exit code 0.
- The test helper now computes the oracle under the requested link and compares
  each optimized fit's marginal likelihood to that independent quadrature
  result with absolute tolerance 0.5.

No package-wide suite, Julia live-engine test, rendered documentation build, or
calibration campaign was run for this slice.

## Tests Of The Tests

The new tests would detect a q2 fit that silently used the wrong response link:
the fitted marginal likelihood would disagree with the link-specific
independent quadrature oracle. The data are generated independently of the
fitter with deterministic seeds. The test does not include an injected wrong
link or wrong-index mutation control; existing q2 covariance tests separately
check coefficient-to-axis indexing and the `D R D` transformation.

## Consistency Audit

Read the current TMB binomial link map and searched the design and likelihood
notes for link and clamp wording. The exact search was:

```sh
rg -n -i 'Bernoulli.*logit|logit.*Bernoulli|probit|cloglog|soft clamp|clamp' \
  docs/design/18-random-effect-scale-models.md \
  docs/design/03-likelihoods.md \
  docs/dev-log/general-sd-regression/native-bernoulli-status.md
```

The correlated-q2 subsection still calls its example “logit Bernoulli,” while
the candidate builder accepts all three binomial links and the new test
demonstrates probit and cloglog fitting. The design file has overlapping work
on ten refs, so it was left unchanged. The earlier read-only math review also
identified that the SD equations omit the effective smooth clamp. Both doc
issues remain for an owner-coordinated edit. No user-facing behavior was
changed in this test-only slice.

## GitHub Issue Maintenance

Searched open issues in `itchyshin/drmTMB` for binomial random-effect SD
regression. The search returned the broad simulation-framework issue #59 and
the unrelated test-sweep issue #1463, but no issue dedicated to this q2 link
regression. No issue or PR was changed.

## What Did Not Go Smoothly

The first lane-lease attempt could not write its registry outside the workspace
and reported “GRANTED” despite exiting unsuccessfully. I retried with the
explicit path-specific lane identity under the approved escalation, verified
the lease, and released it after the test passed. Because the test file was an
existing untracked candidate file, ordinary `git diff` did not display its
changes; I verified the new test's presence and then ran it directly.

## Team Learning

For a multi-link likelihood path, syntax admission is weak evidence. A separate
link-specific marginal-likelihood oracle checks that the selected link reaches
the entire q2 integration route, including the correlated latent effects.

## Known Limitations

This evidence covers two seeded native R/TMB q2 fixtures in a dirty development
candidate. It does not establish interval calibration, replicated parameter
recovery, all three links across every q2 layout, Julia parity, or support for
structured effects. The existing native calibration first look remains
`look2_required`; this test does not change that result.

## Next Actions

- Add the corresponding Julia non-logit q2 regression after the active Julia
  `test/` lease clears and the owner confirms the path is available.
- Reconcile the design equations and Bernoulli link wording after reviewing
  ownership on `docs/design/18-random-effect-scale-models.md`.
- Continue the Bernoulli uncertainty-calibration gate and the programme-wide
  family/effect inventory without narrowing the original scope.
