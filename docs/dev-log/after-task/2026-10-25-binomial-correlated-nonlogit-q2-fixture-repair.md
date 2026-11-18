# After Task: Correlated Binomial q2 Recovery Fixture Repair

## 1. Goal

Correct the probit and complementary log-log synthetic generator for native correlated Binomial intercept and slope SD regression, then verify recovery of both SD trends and their shared correlation.

## 2. Implemented

The probit and cloglog cases now generate correlated intercept and slope effects from a shared standard-normal draw. The deterministic design uses 160 groups, 32 observations per group, true SD slopes of 0.65 and -0.5, and correlation 0.5. Each link gets a separate response seed. The test checks signed recovery, convergence, Hessian status, finite group SD predictions, and an independent Gauss-Hermite marginal likelihood.

## 3a. Decisions and Rejected Alternatives

The first correlated 120-group fixture converged with a positive-definite Hessian but did not recover the intercept SD trend. I increased the information in the design rather than widening the recovery bounds. The final tolerance is 0.15 for each SD slope and 0.2 for the correlation, with separate sign checks.

## 4. Files Touched

- `tests/testthat/test-binomial-correlated-sd.R`
- `docs/dev-log/check-log.d/2026-10-25-binomial-correlated-nonlogit-q2-fixture-repair.md`
- This report.

## 5. Checks Run

- The first run reached the new assertions and exposed a testthat API mismatch: `expect_gt()` did not accept `info`. Replacing those calls with labelled `expect_true()` assertions fixed the test harness issue.
- A higher-information pilot with 160 groups and 32 observations per group recovered the probit values as 0.613, -0.551, and 0.573 for truths 0.65, -0.5, and 0.5. The cloglog pilot recovered 0.579, -0.472, and 0.418.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-binomial-correlated-sd.R", reporter = "summary")'`: passed with exit code 0 in about 77 seconds.
- `git diff --check` and the report checks are recorded in the paired check-log fragment.
- No package-wide tests, Julia bridge fit, interval-coverage campaign, vignette render, or full site build was run.

## 6. Tests of the Tests

The test first failed on the testthat assertion API, then failed on the weak-information fixture. The final test checks nonzero signed SD trends and a positive correlation near the generating value. It retains the independent quadrature likelihood comparison. Separate latent draws would make the true correlation zero, so sharing `z0` is necessary for this test to check its stated model.

## 7a. Issue Ledger

Read-only GitHub issue search for `repo:itchyshin/drmTMB binomial correlated random effect SD` returned general test-sweep issues #1463 and #1464. Neither tracks this fixture defect, so no issue or PR was changed.

## 8. Consistency Audit

For group `g`, the latent effects follow

\[
\begin{pmatrix}b_{0g}\\b_{1g}\end{pmatrix}
\sim N\!\left(0, D_g R D_g\right),\quad
D_g=\operatorname{diag}(\tau_{0g},\tau_{1g}),\quad
R=\begin{pmatrix}1&\rho\\\rho&1\end{pmatrix}.
\]

The generator uses `b0 = tau0 * z0` and `b1 = tau1 * (rho * z0 + sqrt(1 - rho^2) * z1)`, with independent standard-normal `z0` and `z1`. The native q2 covariance transform and selected Binomial link match this model. The test's independent quadrature calculation integrates both effects under the same group-specific covariance and link.

Exact targeted search used: `rg -n -i 'Bernoulli.*logit|logit.*Bernoulli|probit|cloglog|soft clamp|clamp' docs/design/18-random-effect-scale-models.md docs/design/03-likelihoods.md docs/dev-log/general-sd-regression/native-bernoulli-status.md`. The public vignette continues to show its logit example and does not claim interval coverage. No formula, likelihood, NEWS, or pkgdown changes were needed. The shared design document and main check log have divergent work on hundreds of refs; the main check-log update remains pending documentation-lane coordination.

## 9. What Did Not Go Smoothly

The original fixture used independent random draws for the intercept and slope while setting `rho` to 0.35. The test therefore fit a correlated model to data whose generating correlation was zero. The original group count also gave weak recovery of the intercept SD trend under one link.

## 10. Known Residuals

This is one deterministic native TMB point-recovery fixture for the ordinary correlated q2 Binomial block under probit and cloglog links. It does not establish interval coverage, Julia parity, structured-provider parity, or recovery across other Binomial layouts. The broader implementation goal remains open.

## 11. Team Learning

For correlated random-effect recovery fixtures, construct both coefficients from an explicit shared latent draw. Check group-level recovery before treating a passing likelihood oracle as recovery evidence.

## 12. Cross-Product Coverage

This test does NOT cover Julia fitting, the R-to-Julia bridge, phylogenetic or animal Binomial blocks, other random-effect layouts, interval coverage, or package-wide checks. No overall programme gate closes from this fixture repair.
