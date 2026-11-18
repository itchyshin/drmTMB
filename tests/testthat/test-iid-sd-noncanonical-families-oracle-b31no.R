# Batch 31 (group no) companion for the native ordinary (iid) intercept and
# independent-slope SD rows of
#   beta, beta_binomial, cumulative_logit, hurdle_nbinom2 (truncated_nbinom2
#   with hu ~ 1), zi_poisson (poisson with zi ~ 1).
# Intercept: `(1 | id)` with `sd(id) ~ w`; slope: `(0 + x | id)` with
# `sd(id, coef = "x") ~ w`.
#
# Ledger deficiency addressed: those rows had only Julia parity / recovery
# receipts, no independent oracle and no emulated-bug sensitivity. A base-R
# dense Laplace marginal (helper-sb26-oracle.R) is evaluated at the fitted
# parameters (fixed effects, dispersion, zi / hu, cutpoints) with the SD vector
# built by hand from the fitted coefficients and a random-permutation selector
# grid (not palindromic). The beta-binomial, hurdle NB2, zero-inflated Poisson,
# cumulative-logit and Beta densities are written by hand in
# helper-b31no-oracle.R and checked there against numerical integrals or
# brute-force sums; eta derivatives come from a five-point stencil. Tolerance
# 1e-4 absolute on logLik; every emulated bug (reversed SD, flipped selector)
# must move the oracle by more than 0.1. No calibration, coverage or parity
# claim.

b31no_iid_case <- function(family, shape, seed, per_group = 24L) {
  set.seed(seed)
  field <- b29b_make_field("iid")
  lev <- field$levels
  G <- length(lev)
  z <- field$zlev
  a <- if (shape == "I") c(log(0.9), 1.0) else c(log(0.8), 1.2)
  u <- stats::setNames(stats::rnorm(G) * exp(a[[1L]] + a[[2L]] * z[lev]), lev)
  n <- G * per_group
  chr <- sample(rep(lev, length.out = n))
  x <- stats::rnorm(n)
  w <- if (shape == "x") x else 1
  eta <- (if (family == "cumulative_logit") 0 else 0.1) + 0.4 * x + w * u[chr]
  dat <- data.frame(x = x, id = factor(chr, levels = lev), w = unname(z[chr]))
  cuts_true <- c(-0.9, 0.3, 1.2)
  if (family == "beta") {
    phi <- 1 / 0.3^2
    dat$y <- pmin(pmax(stats::rbeta(n, stats::plogis(eta) * phi,
                                    (1 - stats::plogis(eta)) * phi), 1e-6), 1 - 1e-6)
  } else if (family == "beta_binomial") {
    phi <- 1 / 0.4^2
    p <- stats::rbeta(n, stats::plogis(eta) * phi, (1 - stats::plogis(eta)) * phi)
    dat$success <- stats::rbinom(n, 12L, p)
    dat$failure <- 12L - dat$success
  } else if (family == "cumulative_logit") {
    lat <- eta + stats::rlogis(n)
    dat$score <- ordered(findInterval(lat, cuts_true) + 1L, levels = 1:4)
  } else if (family == "hurdle_nbinom2") {
    mu <- exp(eta)
    size <- 1 / 0.5^2
    p0 <- stats::dnbinom(0, size = size, mu = mu)
    zero <- stats::runif(n) < stats::plogis(-0.5)
    uu <- p0 + pmax(stats::runif(n), .Machine$double.eps) * (1 - p0)
    dat$y <- ifelse(zero, 0, stats::qnbinom(uu, size = size, mu = mu))
  } else {
    zero <- stats::runif(n) < 0.25
    dat$y <- ifelse(zero, 0L, stats::rpois(n, exp(eta)))
  }
  lhs <- switch(family, beta = "y", beta_binomial = "cbind(success, failure)",
                cumulative_logit = "score", hurdle_nbinom2 = "y", zi_poisson = "y")
  re <- if (shape == "I") "(1 | id)" else "(0 + x | id)"
  sdt <- if (shape == "I") "sd(id) ~ w" else 'sd(id, coef = "x") ~ w'
  extra <- switch(family, beta = ", sigma ~ 1", beta_binomial = ", sigma ~ 1",
                  cumulative_logit = "", hurdle_nbinom2 = ", sigma ~ 1, hu ~ 1",
                  zi_poisson = ", zi ~ 1")
  form <- eval(parse(text = sprintf("bf(%s ~ x + %s%s, %s)", lhs, re, extra, sdt)))
  fam <- switch(family, beta = beta_family(), beta_binomial = beta_binomial(),
                cumulative_logit = cumulative_logit(),
                hurdle_nbinom2 = truncated_nbinom2(),
                zi_poisson = stats::poisson(link = "log"))
  fit <- suppressWarnings(drmTMB(form, family = fam, data = dat,
                                 control = drm_control(se = FALSE)))
  info <- paste(family, shape)
  key <- if (shape == "I") "sd(id)" else 'sd(id, coef = "x")'
  co <- coef(fit, key)
  expect_named(co, c("(Intercept)", "w"))
  bh <- coef(fit, "mu")
  eta_fixed <- if ("(Intercept)" %in% names(bh)) {
    bh[["(Intercept)"]] + bh[["x"]] * dat$x
  } else {
    expect_identical(names(bh), "x")
    bh[["x"]] * dat$x
  }
  sig <- function() exp(unname(coef(fit, "sigma")[[1L]]))
  deriv <- switch(family,
    beta = {
      ph <- 1 / sig()^2
      b31no_fd(function(e) b31no_dbeta_log(dat$y, stats::plogis(e), ph))
    },
    beta_binomial = {
      ph <- 1 / sig()^2
      b31no_fd(function(e) {
        m <- stats::plogis(e)
        b31no_dbetabinom_log(dat$success, 12, m * ph, (1 - m) * ph)
      })
    },
    cumulative_logit = {
      cuts <- unname(fit$ordinal$cutpoints)
      yy <- as.integer(dat$score)
      b31no_fd(function(e) b31no_dcumlogit_log(yy, e, cuts))
    },
    hurdle_nbinom2 = {
      hu <- stats::plogis(unname(coef(fit, "hu")[[1L]]))
      sz <- 1 / sig()^2
      b31no_fd(function(e) b31no_dhurdlenb_log(dat$y, exp(e), sz, hu))
    },
    zi_poisson = {
      zi <- stats::plogis(unname(coef(fit, "zi")[[1L]]))
      b31no_fd(function(e) b31no_dzip_log(dat$y, exp(e), zi))
    })
  terms <- list(b31no_term(field, dat, "id", w, co, z,
                           if (shape == "I") "intercept" else "slope"))
  b31no_check(fit, deriv, eta_fixed, terms, info)
}

for (fam_ in c("beta", "beta_binomial", "cumulative_logit", "hurdle_nbinom2",
               "zi_poisson")) {
  local({
    fam <- fam_
    test_that(paste(fam, "iid intercept SD: dense Laplace oracle and bug sensitivity"), {
      skip_on_cran()
      b31no_iid_case(fam, "I", 31500L + match(fam, c("beta", "beta_binomial",
        "cumulative_logit", "hurdle_nbinom2", "zi_poisson")))
    })
    test_that(paste(fam, "iid slope SD: dense Laplace oracle and bug sensitivity"), {
      skip_on_cran()
      b31no_iid_case(fam, "x", 31510L + match(fam, c("beta", "beta_binomial",
        "cumulative_logit", "hurdle_nbinom2", "zi_poisson")))
    })
  })
}
