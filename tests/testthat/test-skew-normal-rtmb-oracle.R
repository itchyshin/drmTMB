# RTMB transcription oracle for the skew-normal family.
#
# WHY THIS EXISTS, and why it is not redundant with the Julia twin.
# The twin (DRM.jl) is a deliberate PORT -- its own source says "Mirrors drmTMB"
# -- so it shares this package's DERIVATION. A shared derivation error is
# invisible to twin agreement. RTMB is a second front-end to TMB's own AD
# engine, so it shares the AD but NONE of the hand-written C++ in
# src/drmTMB.cpp. Agreement here therefore isolates one question that nothing
# else in the suite isolates: was the maths transcribed into C++ correctly?
#
# It certifies TRANSCRIPTION only. It says nothing about coverage, and for an
# approximate likelihood it would say nothing about the approximation (not an
# issue here: this family has no latent variable to integrate out).
#
# The density below is written from the SYMBOLIC DERIVATION, deliberately NOT
# by calling helper-skew-normal-density.R and not by reading the C++. A
# reference transcribed from the thing it checks shares that thing's errors.

skip_if_not_installed("RTMB")

# Azzalini skew-normal on drmTMB's PUBLIC (mean, sd, shape) scale.
#   delta = nu / sqrt(1 + nu^2);  omega = sigma / sqrt(1 - (delta sqrt(2/pi))^2)
#   xi    = mu - omega delta sqrt(2/pi)
#   log f = log 2 - log omega + log phi(z) + log Phi(nu z),  z = (y - xi)/omega
rtmb_skew_normal_logdens <- function(y, mu, sigma, nu) {
  delta <- nu / sqrt(1 + nu^2)
  mean_shift <- delta * sqrt(2 / pi)
  omega <- sigma / sqrt(1 - mean_shift^2)
  z <- (y - (mu - omega * mean_shift)) / omega
  # NOTE: RTMB::dnorm / RTMB::pnorm, NOT stats::. The stats:: versions do not
  # dispatch on RTMB's AD type, so a namespaced stats:: call fails to tape
  # ("Non-numeric argument to mathematical function") rather than silently
  # degrading -- but only if you never attach RTMB, which a package must not do.
  log(2) - log(omega) +
    RTMB::dnorm(z, log = TRUE) +
    RTMB::pnorm(nu * z, log.p = TRUE)
}

test_that("RTMB traces the skew-normal density and its gradient (AD coverage)", {
  skip_if_not_installed("numDeriv")

  set.seed(46709)
  y <- stats::rnorm(64, 1, 2)

  nll <- function(p) {
    RTMB::getAll(p)
    -sum(rtmb_skew_normal_logdens(y, mu, exp(log_sigma), nu))
  }
  pars <- list(mu = 0.5, log_sigma = log(1.5), nu = 1)
  obj <- RTMB::MakeADFun(nll, pars, silent = TRUE)
  v <- unlist(pars)

  # log Phi(.) via pnorm(log.p = TRUE) must survive the AD tape; if RTMB ever
  # loses that, this is the test that says so rather than a silent fallback.
  expect_true(is.finite(obj$fn(v)))
  expect_equal(
    as.numeric(obj$gr(v)),
    numDeriv::grad(function(x) obj$fn(x), v),
    tolerance = 1e-5
  )

  # second-order AD (the sdreport path) must also work
  expect_no_error(RTMB::sdreport(obj))
})

test_that("RTMB reproduces the COMPILED skew-normal log-likelihood (transcription oracle)", {
  set.seed(101)
  n <- 200
  truth <- list(mu = 1.2, sigma = 2, nu = 3.5)
  native <- skew_normal_public_to_native(truth$mu, truth$sigma, truth$nu)
  y <- native$xi + native$omega *
    (native$delta * abs(stats::rnorm(n)) +
       sqrt(1 - native$delta^2) * stats::rnorm(n))

  fit <- drmTMB(bf(y ~ 1), data = data.frame(y = y), family = skew_normal())
  co <- coef(fit)
  mu_hat <- co$mu[[1]]
  sigma_hat <- exp(co$sigma[[1]])
  nu_hat <- co$nu[[1]]

  # The oracle: the C++ objective and an independent R transcription of the
  # same maths, evaluated at the SAME parameters, must agree to ~machine
  # precision. A sign flip, a dropped constant, or a mis-set link shows up here.
  expect_equal(
    sum(rtmb_skew_normal_logdens(y, mu_hat, sigma_hat, nu_hat)),
    as.numeric(stats::logLik(fit)),
    tolerance = 1e-8
  )
})
