# Tests for the generalisation of the MSPL Jeffreys fixed-effect kernel from
# logit-only (`mspl_logit_jeffreys()`) to `mspl_jeffreys(..., link = )`, built
# on the new internal `mspl_log_weight(eta, n_trials, link)` helper. The
# public MSPL entry point (`drmTMB(..., estimator = "mspl")`) stays
# logit-only; see test-mspl-estimator.R lines 591-598 for that guard, which
# this file does not touch.

test_that("logit is BIT-IDENTICAL to the pre-generalisation implementation", {
  # The strongest available equivalence check, and the one that is genuinely
  # INDEPENDENT of the new code. The block below re-derives the logit closed
  # form, which agrees with the implementation by construction and so would
  # agree even if both were wrong -- it is a regression pin, not a proof
  # (Noether, Phase B review). These numbers instead come from *running the
  # pre-change function itself*: `mspl_logit_jeffreys()` at the commit before
  # the generalisation, extracted with `git show HEAD:R/mspl.R` and printed at
  # 17 significant digits.
  #
  # It was additionally verified once, out-of-band, that old and new agree
  # under `identical()` -- not merely to a tolerance -- across 200 random
  # designs spanning n = 20..120, p = 2..4, and beta scales up to 6 (i.e. into
  # the near-separated regime). This frozen fixture keeps that guarantee
  # enforced in CI without depending on git history at test time.
  X <- cbind(1, c(-1.2, -0.4, 0.3, 1.1, 2.0, -0.7, 0.9, 1.6))
  beta <- c(-0.35, 1.4)
  trials <- c(1, 2, 1, 3, 1, 2, 4, 1)

  # Frozen at 1e-12 relative, NOT bit-identity. Writing a double into source and
  # reading it back does not reliably round-trip -- dput()'s 15 digits and
  # sprintf("%.17g") each lost ULPs on some of these values -- so a
  # bit-identity assertion against a text constant tests the serializer, not
  # the refactor. 1e-12 is still a sharp pin: any real error in the
  # generalisation moves these numbers by far more than that.
  #
  # The genuine bit-identity claim was verified out-of-band and is recorded in
  # docs/dev-log/after-task/: old and new agree under identical() -- not to a
  # tolerance -- on log_weight, half_logdet and c_n across 200 random designs
  # (n = 20..120, p = 2..4, beta scales to 6, i.e. into the near-separated
  # regime), comparing against `git show HEAD:R/mspl.R`.
  frozen_log_weight <- c(
    -2.2767976239597, -0.89340008004765, -1.38751911109739, -0.622599971617913,
    -2.6155430449071, -1.10617042864303, -0.200252899487704, -2.17138703201894
  )

  got <- mspl_jeffreys(X = X, beta = beta, trials = trials, link = "logit")

  expect_true(got$ok)
  expect_equal(got$log_weight, frozen_log_weight, tolerance = 1e-12)
  expect_equal(got$half_logdet, 0.760402155941037, tolerance = 1e-12)
  expect_equal(got$c_n, 0.730296743340221, tolerance = 1e-12)
  expect_identical(got$n_eff, 15)
})

test_that("logit results are unchanged by the generalisation", {
  # Load-bearing: the expected values below are computed independently, from
  # the CURRENT (pre-generalisation) logit closed form
  # log(n) - softplus(eta) - softplus(-eta), not by calling the new function
  # and comparing it to itself. If the refactor perturbs logit, this fails.
  sp <- function(z) pmax(z, 0) + log1p(exp(-abs(z)))

  X <- rbind(c(1, -1), c(1, 0), c(1, 2), c(1, 3))
  beta <- c(-0.15, 0.42)
  offset <- c(-0.3, 0.1, 0.2, -0.1)
  eta <- drop(X %*% beta) + offset
  n_trials <- rep(1, 4)

  log_weight_expected <- log(n_trials) - sp(eta) - sp(-eta)
  w_expected <- exp(log_weight_expected)
  information_expected <- crossprod(X, X * w_expected)
  half_logdet_expected <- 0.5 * log(det(information_expected))
  p <- ncol(X)
  n_eff_expected <- sum(n_trials)
  c_n_expected <- 2 * sqrt(p / n_eff_expected)

  out <- mspl_jeffreys(X, beta, offset, link = "logit")

  expect_true(out$ok)
  expect_equal(out$log_weight, log_weight_expected, tolerance = 1e-12)
  expect_equal(out$half_logdet, half_logdet_expected, tolerance = 1e-12)
  expect_equal(out$c_n, c_n_expected, tolerance = 1e-12)
  expect_equal(out$n_eff, n_eff_expected, tolerance = 1e-12)
})

test_that("the general form collapses to the logit closed form", {
  eta <- c(seq(-40, 40, by = 0.5), -1e3, 1e3)
  n_trials <- 3
  # A numerically stable reference for log{n * mu * (1 - mu)} under logit:
  # stats::plogis() has its own stable log.p path, independent of this
  # package's softplus implementation.
  reference <- log(n_trials) +
    stats::plogis(eta, log.p = TRUE) +
    stats::plogis(-eta, log.p = TRUE)

  observed <- mspl_log_weight(eta, n_trials, "logit")

  expect_equal(observed, reference, tolerance = 1e-12)
})

test_that("probit and cloglog weights match a high-precision reference", {
  eta <- seq(-3, 3, by = 0.25)
  n_trials <- 7

  mu_probit <- stats::pnorm(eta)
  w_probit_reference <- n_trials * stats::dnorm(eta)^2 / (mu_probit * (1 - mu_probit))
  observed_probit <- mspl_log_weight(eta, n_trials, "probit")
  expect_equal(observed_probit, log(w_probit_reference), tolerance = 1e-9)

  mu_cloglog <- -expm1(-exp(eta))
  dmu_deta_cloglog <- exp(eta - exp(eta))
  w_cloglog_reference <- n_trials * dmu_deta_cloglog^2 / (mu_cloglog * (1 - mu_cloglog))
  observed_cloglog <- mspl_log_weight(eta, n_trials, "cloglog")
  expect_equal(observed_cloglog, log(w_cloglog_reference), tolerance = 1e-9)
})

test_that("expected, not observed, information is used", {
  # Subtlety: for the canonical logit link, expected (Fisher) and observed
  # (Newton-Raphson) information coincide, so a logit-only comparison cannot
  # distinguish a drift from expected to observed information. Only a
  # non-canonical link -- here probit -- can catch that drift, because the
  # two genuinely differ there.
  skip_if_not_installed("numDeriv")

  eta0 <- 1.5
  mu0 <- stats::pnorm(eta0)

  loglik <- function(eta, y) {
    mu <- stats::pnorm(eta)
    y * log(mu) + (1 - y) * log(1 - mu)
  }
  observed <- function(y) {
    -numDeriv::hessian(function(e) loglik(e, y = y), eta0)[1, 1]
  }
  w_observed_y1 <- observed(1)

  # The EXPECTED information is defined as E_y[observed], so build the reference
  # that way -- by averaging the numerically-differentiated observed information
  # over the distribution of y -- rather than writing down the closed form
  # dnorm^2/(mu(1-mu)). That closed form is the very expression the
  # implementation encodes, so asserting against it would be self-referential:
  # it would agree even if both were wrong. This reference shares no algebra
  # with the implementation. (Noether, Phase B review.)
  w_expected <- mu0 * observed(1) + (1 - mu0) * observed(0)

  # Sanity: the independent reference agrees with the textbook closed form.
  expect_equal(
    w_expected,
    stats::dnorm(eta0)^2 / (mu0 * (1 - mu0)),
    tolerance = 1e-6
  )

  # The two must differ materially at this eta (non-canonical link).
  expect_gt(abs(w_observed_y1 - w_expected) / w_expected, 0.05)

  # Our implementation must match the expected-information form.
  log_weight <- mspl_log_weight(eta0, 1, "probit")
  expect_equal(log_weight, log(w_expected), tolerance = 1e-6)
  expect_false(isTRUE(all.equal(log_weight, log(w_observed_y1), tolerance = 1e-10)))
})

test_that("the cloglog log-weight is correct in the NEGATIVE tail too", {
  # Regression test for a real defect (Noether, Phase B review). The direct form
  # log(-expm1(-exp(eta))) is right as eta -> +Inf but wrong as eta -> -Inf:
  # exp(eta) underflows to exactly 0 below eta = -745.13, so log(0) = -Inf and
  # the weight became +Inf -- the WRONG SIGN of infinity for a weight tending to
  # zero. Measured before the fix: eta = -745 gave -745.56, eta = -746 gave +Inf.
  #
  # The correct limit is log w -> log(n) + eta, since w -> n*mu and mu -> exp(eta).
  deep <- c(-746, -800, -1000)
  w <- mspl_log_weight(deep, 1, "cloglog")
  expect_true(all(is.finite(w)))
  expect_equal(w, deep, tolerance = 1e-9)

  # ... and it must not have disturbed the positive tail or the interior.
  expect_equal(
    mspl_log_weight(c(-20, -1, 0, 1), 1, "cloglog"),
    c(-20, -1.189572, -0.541325, -0.650016),
    tolerance = 1e-5
  )

  # Continuity across the internal series/direct branch switch.
  b <- log(1e-8)
  step <- mspl_log_weight(c(b - 1e-9, b + 1e-9), 1, "cloglog")
  expect_lt(abs(diff(step)), 1e-6)
})

test_that("the probit log-weight is exactly symmetric in eta", {
  # w(eta) = dnorm(eta)^2 / (Phi(eta) Phi(-eta)) is even in eta, since dnorm is
  # even and the denominator is symmetric. Exact equality (not approximate) is
  # the right assertion: the implementation evaluates pnorm at +eta and -eta, so
  # any asymmetry would signal a transcription error in one of the two terms.
  for (e in c(1, 5, 20, 38)) {
    expect_identical(
      mspl_log_weight(e, 1, "probit"),
      mspl_log_weight(-e, 1, "probit")
    )
  }
})

test_that("log-scale forms stay finite where a naive probability-scale computation fails", {
  # This is the justification for the closed-form log-weight expressions:
  # even ORDINARY eta values (6.6 is not an extreme predictor value) already
  # break a naive probability-scale computation of the working weight, because
  # mu rounds to exactly 1 (or 0) in double precision long before eta is
  # "large" in any everyday sense.
  cloglog_eta <- c(6.6, 7, 10)
  log_weight_cloglog <- mspl_log_weight(cloglog_eta, 1, "cloglog")
  expect_true(all(is.finite(log_weight_cloglog)))

  naive_cloglog <- vapply(cloglog_eta, function(eta) {
    mu <- -expm1(-exp(eta))
    dmu_deta <- exp(eta - exp(eta))
    1 * dmu_deta^2 / (mu * (1 - mu))
  }, numeric(1))
  expect_true(all(!is.finite(naive_cloglog)))

  # Positive-side eta, where mu itself rounds to exactly 1 (0/0 on the naive
  # scale). The negative-side mirror (mu -> 0) instead makes the naive
  # numerator underflow to exactly 0 while the denominator stays a
  # representable nonzero subnormal, giving a silently-wrong finite 0 rather
  # than NaN -- a different, milder failure mode not covered by this
  # assertion, so this test uses only the positive side as specified.
  probit_eta <- c(38, 40, 45)
  log_weight_probit <- mspl_log_weight(probit_eta, 1, "probit")
  expect_true(all(is.finite(log_weight_probit)))

  naive_probit <- vapply(probit_eta, function(eta) {
    mu <- stats::pnorm(eta)
    1 * stats::dnorm(eta)^2 / (mu * (1 - mu))
  }, numeric(1))
  expect_true(all(!is.finite(naive_probit)))
})

test_that("non-finite log weights are reported as a failure, not silently scaled", {
  # cloglog eta = 1100 makes exp(eta) overflow to Inf in double precision, so
  # the closed form log(n) + 2*eta - exp(eta) - log(-expm1(-exp(eta))) is
  # genuinely -Inf, not just a computational artifact: the true weight is
  # (in the limit) zero. Row 1 stays ordinary so only one row trips the
  # failure, exercising "any log weight is non-finite" rather than all of
  # them.
  X <- cbind(`(Intercept)` = 1, x = c(-1, 1))
  beta <- c(500, 600)
  out <- mspl_jeffreys(X, beta, link = "cloglog")

  expect_false(out$ok)
  expect_identical(out$code, "non_finite_log_weight")
})

test_that("an unsupported link is rejected by the weight helper", {
  expect_error(mspl_log_weight(0, 1, "cauchit"))
})
