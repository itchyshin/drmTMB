# Large-argument accuracy of the Student, Gamma and Beta log-densities
# (#1504, lane f12).
#
# The textbook forms subtract lgamma() values of size x log(x), losing about
# eps * x log(x) per row. Each test below evaluates the compiled objective at
# fixed parameters on rows that are single observations (three replicated
# rows, divided by three), so the tolerance is a PER-OBSERVATION error bound.
# Where the exact value is not available from base R to the required accuracy
# (R's dgamma(), dbeta() and dnbinom() lose 1e-11 to 1e-9 themselves at shape
# 1e8, because they round the scale or the mean first), the reference is an
# mpmath value at 60 digits, pinned below as literals. The bars sit near the
# libm rounding floor, which differs between platforms, and the file fits many
# small models, so it is skipped on CRAN.

skip_on_cran()

ll_row <- function(family, formula, y, ...) {
  dat <- data.frame(y = rep(y, 3L))
  fit <- suppressWarnings(drmTMB(
    formula,
    family = family,
    data = dat,
    control = drm_control(se = FALSE)
  ))
  par <- fit$obj$par
  upd <- list(...)
  for (nm in names(upd)) par[names(par) == nm] <- upd[[nm]]
  -fit$obj$fn(par) / 3
}

# The data-conditioning floor of a location-scale density: an input rounded to
# eps moves the density by about shape * |u| * eps, with u the relative
# residual. Tolerances below add that floor to the 1e-12 ship bar only where
# the caller (not the kernel) forms the rounded input.
eps <- .Machine$double.eps

z_grid <- c(-3, -1.2, -0.4, 0, 0.3, 1, 2.5, 4)

# ---- Student ---------------------------------------------------------------

test_that("student kernel matches stats::dt() to 1e-12 per observation at large nu", {
  mu <- 1
  sigma <- 1.3
  for (nu in c(1e2, 1e4, 1e6, 1e8)) {
    err <- vapply(z_grid, function(z) {
      y <- mu + sigma * z
      got <- ll_row(
        student(), bf(y ~ 1, sigma ~ 1, nu ~ 1), y,
        beta_mu = mu, beta_sigma = log(sigma), beta_nu = log(nu - 2)
      )
      abs(got - (stats::dt((y - mu) / sigma, df = nu, log = TRUE) - log(sigma)))
    }, numeric(1))
    expect_lt(max(err), 1e-12, label = paste("nu =", nu))
  }
})

test_that("student kernel tends to the Gaussian log-density at the O(1/nu) rate", {
  mu <- 1
  sigma <- 1.3
  gap <- vapply(c(1e2, 1e4, 1e6, 1e8), function(nu) {
    worst <- 0
    for (z in z_grid) {
      y <- mu + sigma * z
      got <- ll_row(
        student(), bf(y ~ 1, sigma ~ 1, nu ~ 1), y,
        beta_mu = mu, beta_sigma = log(sigma), beta_nu = log(nu - 2)
      )
      gauss <- stats::dnorm((y - mu) / sigma, log = TRUE) - log(sigma)
      # leading correction is (z^4 / 4 - z^2 / 2 - 1/2) / nu, plus O(1/nu^2)
      expect_lt(abs(got - gauss), (z^4 / 4 + z^2 + 1) / nu)
      worst <- max(worst, abs(got - gauss) * nu)
    }
    worst
  }, numeric(1))
  # the scaled gap is bounded and stable instead of growing with nu
  expect_lt(max(gap), 70)
  expect_lt(abs(gap[[4L]] - gap[[3L]]), 1e-3)
})

test_that("student objective closes monotonically on the Gaussian logLik from eta_nu = 10 to 40", {
  # Simulator wave K: the old kernel climbed past the Gaussian logLik here.
  y <- 1 + 1.3 * z_grid
  dat <- data.frame(y = y)
  fit <- suppressWarnings(drmTMB(
    bf(y ~ 1, sigma ~ 1, nu ~ 1), family = student(), data = dat,
    control = drm_control(se = FALSE)
  ))
  par <- fit$obj$par
  gauss <- sum(stats::dnorm(y, 1, 1.3, log = TRUE))
  ll <- vapply(c(10, 15, 20, 25, 30, 40), function(e) {
    p <- par
    p[names(p) == "beta_mu"] <- 1
    p[names(p) == "beta_sigma"] <- log(1.3)
    p[names(p) == "beta_nu"] <- e
    -fit$obj$fn(p)
  }, numeric(1))
  gap <- abs(ll - gauss)
  expect_true(all(is.finite(ll)))
  # the t log-likelihood closes on the Gaussian one without overshooting
  expect_true(all(diff(gap) <= 1e-12))
  expect_lt(gap[[length(gap)]], 1e-12)
})

# Reference values: mpmath at 60 digits, evaluated at the exact doubles below.
# The Gamma eta is log(2.5) written as a hex double. R without long double
# (arm64 macOS) parses the decimal 0.9162907318741551 one ulp high, and at
# shape 1e8 the density moves by shape * |u| * 1.1e-16 = 4.4e-12 per ulp.
gamma_eta <- 0x1.d5240f0e0e078p-1

gamma_cases <- list(
  list(s = 10000.0, eta = gamma_eta, ls = -4.605170185988092,
    y = c(2.425, 2.4699999999999998, 2.49, 2.5, 2.5075, 2.525, 2.5625, 2.6),
    ref = c(-1.7916830520248554, 2.0561928261178135, 2.6937266335852903, 2.7699325875759335, 2.722026876580926, 2.263290788403601, -0.3286341212994202, -5.0621565927643895)),
  list(s = 1000000.0, eta = gamma_eta, ls = -6.907755278982137,
    y = c(2.4925, 2.497, 2.499, 2.5, 2.50075, 2.5024999999999995, 2.5062499999999996, 2.51),
    ref = c(0.5665101408685314, 4.353150132248229, 4.992904670855935, 5.0725259305699755, 5.027234973536473, 4.5718595137703, 1.9502276375708283, -2.9101965532460534)),
  list(s = 100000000.0, eta = gamma_eta, ls = -9.210340371976184,
    y = c(2.49925, 2.4997, 2.4999, 2.5, 2.500075, 2.50025, 2.5006250000000003, 2.501),
    ref = c(2.874510948522821, 6.655173508078695, 7.295148973466205, 7.375111106064023, 7.330082006494098, 6.87504444189819, 4.250381873003259, -0.6231561204158353))
)

beta_cases <- list(
  list(phi = 10000.0, m = 0.3, eta = -0.8472978603872036, ls = -4.605170185988092,
    y = c(0.286252960249937, 0.29450118409997483, 0.29816706136665827, 0.3, 0.30137470397500626, 0.3045823465833543, 0.3114558664583858, 0.3183293863334173),
    ref = c(-0.08780338888994209, 3.752151339400103, 4.389858334961652, 4.466524177709894, 4.419000782528411, 3.9608484668921085, 1.3646429177670132, -3.390067074382588)),
  list(phi = 10000.0, m = 0.5, eta = 0.0, ls = -4.605170185988092,
    y = c(0.4850007499437547, 0.4940002999775019, 0.4980000999925006, 0.5, 0.5014999250056246, 0.5049997500187484, 0.512499375046871, 0.5199990000749938),
    ref = c(-0.12132170699769403, 3.659517987503251, 4.299377191192777, 4.379353833343406, 4.33436712957331, 3.8794788266772016, 1.2543146607710982, -3.6246506785322925)),
  list(phi = 1000000.0, m = 0.3, eta = -0.8472978603872036, ls = -6.907755278982137,
    y = c(0.29862522797889907, 0.29945009119155963, 0.2998166970638532, 0.3, 0.3001374772021101, 0.30045825734036696, 0.3011456433509174, 0.3018330293614679),
    ref = c(2.2638842469907567, 6.049686773346287, 6.689471123027733, 6.769140306418116, 6.723886466864187, 6.268559832780243, 3.6464989097690657, -1.2158121876211572)),
  list(phi = 1000000.0, m = 0.5, eta = 0.0, ls = -6.907755278982137,
    y = c(0.49850000074999945, 0.49940000029999976, 0.4998000000999999, 0.5, 0.5001499999250001, 0.5004999997500001, 0.5012499993750005, 0.5019999990000007),
    ref = c(2.181956926283487, 5.961965317936785, 6.60196390993719, 6.68196367633741, 6.636963809312263, 6.181964926336826, 3.556963285701368, -1.3180763241128282)),
  list(phi = 100000000.0, m = 0.3, eta = -0.8472978603872036, ls = -9.210340371976184,
    y = c(0.2998625227298387, 0.2999450090919355, 0.2999816696973118, 0.3, 0.3000137477270161, 0.3000458257567204, 0.30011456439180106, 0.30018330302688173),
    ref = c(4.571201773065165, 8.351780184432723, 8.991758761910761, 9.071725709769305, 9.02670031348292, 8.57166754146535, 5.946962079827036, 1.0732378957808144)),
  list(phi = 100000000.0, m = 0.5, eta = 0.0, ls = -9.210340371976184,
    y = c(0.49985000000075, 0.4999400000003, 0.4999800000001, 0.5, 0.500014999999925, 0.50004999999975, 0.500124999999375, 0.500199999999),
    ref = c(4.484548949333105, 8.26454903324692, 8.904549019167545, 8.984549016831457, 8.939549018160923, 8.48454902933201, 5.859549012925891, 0.9845486168313902))
)

nb2_cases <- list(
  list(size = 10000.0, eta = 3.912023005428146, ls = -4.605170185988092,
    y = c(0.0, 1.0, 3.0, 10.0, 20.0, 50.0),
    ref = c(-49.87541511039073, -45.96837964647362, -39.945768212864465, -25.904974468620562, -14.051334630782794, -2.8791104925806184)),
  list(size = 1000000.0, eta = 3.912023005428146, ls = -6.907755278982137,
    y = c(0.0, 1.0, 3.0, 10.0, 20.0, 50.0),
    ref = c(-49.9987500416651, -46.086777034986994, -40.054587490861344, -25.983387548102073, -14.094716370091486, -2.8766416797449166)),
  list(size = 100000000.0, eta = 3.912023005428146, ls = -9.210340371976184,
    y = c(0.0, 1.0, 3.0, 10.0, 20.0, 50.0),
    ref = c(-49.99998750000416, -46.08796499457589, -40.05567942294741, -25.98417456879698, -14.095151952192351, -2.876616930365667))
)

# ---- Gamma -----------------------------------------------------------------

test_that("gamma kernel matches the exact density at shape 1e4, 1e6, 1e8", {
  for (cs in gamma_cases) {
    err <- vapply(seq_along(cs$y), function(i) {
      got <- ll_row(
        stats::Gamma(link = "log"), bf(y ~ 1, sigma ~ 1), cs$y[[i]],
        beta_mu = cs$eta, beta_sigma = cs$ls
      )
      abs(got - cs$ref[[i]])
    }, numeric(1))
    # 1e-12 ship bar; shape 1e8 sits on the conditioning floor
    # shape * |u| * eps = 1e8 * 4e-4 * 1.1e-16 = 4.4e-12 for a 4-sd row, and
    # the measured worst row is 9.1e-13 on Linux and macOS, so allow 1.5e-12
    # there.
    bar <- if (cs$s >= 1e8) 1.5e-12 else 1e-12
    expect_lt(max(err), bar, label = paste("gamma shape =", cs$s))
  }
})

test_that("gamma kernel agrees with stats::dgamma() and its Gaussian limit", {
  for (cs in gamma_cases) {
    mu <- exp(cs$eta)
    got <- vapply(seq_along(cs$y), function(i) {
      ll_row(
        stats::Gamma(link = "log"), bf(y ~ 1, sigma ~ 1), cs$y[[i]],
        beta_mu = cs$eta, beta_sigma = cs$ls
      )
    }, numeric(1))
    ref <- stats::dgamma(cs$y, shape = cs$s, scale = mu / cs$s, log = TRUE)
    # dgamma() rounds scale = mu / shape first: its own error is ~shape*u*eps
    expect_lt(max(abs(got - ref)), 1e-11)
    gauss <- stats::dnorm(cs$y, mu, mu / sqrt(cs$s), log = TRUE)
    # skewness correction is O(1/sqrt(shape)) for |z| <= 4
    expect_lt(max(abs(got - gauss)), 20 / sqrt(cs$s))
  }
})

# ---- Beta ------------------------------------------------------------------

test_that("beta kernel matches the exact density at phi 1e4, 1e6, 1e8", {
  for (cs in beta_cases) {
    err <- vapply(seq_along(cs$y), function(i) {
      got <- ll_row(
        beta_family(), bf(y ~ 1, sigma ~ 1), cs$y[[i]],
        beta_mu = cs$eta, beta_sigma = cs$ls
      )
      abs(got - cs$ref[[i]])
    }, numeric(1))
    # The kernel itself is exact to 2.3e-13 at phi = 1e8 (probe, alpha and beta
    # given). Through the model, alpha = mu * phi inherits one rounding of
    # mu = plogis(eta), which moves the density by phi * |u| * eps; add that
    # floor to the 1e-12 bar. That is 8e-12 at phi = 1e8 for a 4-sd row.
    floor <- 3 * eps * cs$phi * max(abs(cs$y - cs$m))
    expect_lt(max(err), 1e-12 + floor, label = paste("beta phi =", cs$phi, "mu =", cs$m))
    if (cs$phi <= 1e4) expect_lt(max(err), 1e-12)
  }
})

test_that("beta kernel agrees with stats::dbeta() at large phi", {
  for (cs in beta_cases) {
    mm <- 1e-12 + (1 - 2e-12) * stats::plogis(cs$eta)
    phi <- cs$phi
    got <- vapply(seq_along(cs$y), function(i) {
      ll_row(
        beta_family(), bf(y ~ 1, sigma ~ 1), cs$y[[i]],
        beta_mu = cs$eta, beta_sigma = cs$ls
      )
    }, numeric(1))
    ref <- stats::dbeta(cs$y, mm * phi, (1 - mm) * phi, log = TRUE)
    expect_lt(max(abs(got - ref)), 5e-11)
  }
})

test_that("beta kernel is finite and exact for y very close to 0 or 1 (sigma random-slope fits)", {
  # Regression for the C17 model-15 cells: y * p / a rounds to 1 for tiny y, so
  # log(1 + u) must come from log(y) + log(p) - log(a), not from 1 + u.
  mu <- 0.3
  phi <- 2
  eta <- stats::qlogis(mu)
  mm <- 1e-12 + (1 - 2e-12) * mu
  for (y in c(1e-300, 1e-200, 1e-30, 1e-8, 1 - 1e-8, 1 - 1e-15)) {
    got <- ll_row(
      beta_family(), bf(y ~ 1, sigma ~ 1), y,
      beta_mu = eta, beta_sigma = -0.5 * log(phi)
    )
    ref <- stats::dbeta(y, mm * phi, (1 - mm) * phi, log = TRUE)
    expect_true(is.finite(got), label = paste("finite at y =", y))
    expect_lt(abs(got - ref), 1e-10 * max(1, abs(ref)), label = paste("y =", y))
  }
  fit <- suppressWarnings(drmTMB(
    bf(y ~ 1, sigma ~ 1), family = beta_family(),
    data = data.frame(y = rep(c(1e-200, 0.4, 1 - 1e-15), 2L)),
    control = drm_control(se = FALSE)
  ))
  par <- fit$obj$par
  par[names(par) == "beta_mu"] <- eta
  par[names(par) == "beta_sigma"] <- -0.5 * log(phi)
  expect_true(all(is.finite(fit$obj$gr(par))))
  expect_true(all(is.finite(fit$obj$he(par))))
})

# ---- Beta-binomial (main loop and mi() leaf share drm_beta_binomial_log_density)

bb_exact <- function(k, n, a, b) {
  # exact reference: lchoose + sum of logs, no lgamma difference
  s <- function(x, m) if (m > 0) sum(log(x + seq_len(m) - 1)) else 0
  lchoose(n, k) + s(a, k) + s(b, n - k) - s(a + b, n)
}

test_that("beta-binomial matches the exact density to 1e-12 at phi 1e4, 1e6, 1e8", {
  n <- 20L
  for (phi in c(1e4, 1e6, 1e8)) {
    for (m in c(0.3, 0.5)) {
      mm <- 1e-12 + (1 - 2e-12) * stats::plogis(stats::qlogis(m))
      err <- vapply(c(0L, 1L, 4L, 6L, 10L, 15L, 20L), function(k) {
        dat <- data.frame(success = rep(k, 3L), failure = rep(n - k, 3L))
        fit <- suppressWarnings(drmTMB(
          bf(cbind(success, failure) ~ 1, sigma ~ 1),
          family = beta_binomial(), data = dat,
          control = drm_control(se = FALSE)
        ))
        par <- fit$obj$par
        par[names(par) == "beta_mu"] <- stats::qlogis(m)
        par[names(par) == "beta_sigma"] <- -0.5 * log(phi)
        abs(-fit$obj$fn(par) / 3 - bb_exact(k, n, mm * phi, (1 - mm) * phi))
      }, numeric(1))
      expect_lt(max(err), 1e-12, label = paste("phi =", phi, "mu =", m))
    }
  }
})

# ---- NB2 (drm_count_kernels.h; reported, not changed in this lane) ---------

test_that("nbinom2 matches the exact density at size 1e4, 1e6, 1e8 when alpha * y < 1e-2", {
  for (cs in nb2_cases) {
    err <- vapply(seq_along(cs$y), function(i) {
      got <- ll_row(
        nbinom2(), bf(y ~ 1, sigma ~ 1), cs$y[[i]],
        beta_mu = cs$eta, beta_sigma = cs$ls
      )
      abs(got - cs$ref[[i]])
    }, numeric(1))
    expect_lt(max(err), 1e-12, label = paste("nbinom2 size =", cs$size))
  }
})

# ---- AD gradient and Hessian at every branch switch ------------------------

grad_check <- function(fit, par, h = 1e-6, tol = 1e-6) {
  g <- fit$obj$gr(par)
  num <- vapply(seq_along(par), function(i) {
    step <- h * max(1, abs(par[[i]]))
    up <- par
    dn <- par
    up[[i]] <- up[[i]] + step
    dn[[i]] <- dn[[i]] - step
    (fit$obj$fn(up) - fit$obj$fn(dn)) / (2 * step)
  }, numeric(1))
  expect_lt(max(abs(g - num) / pmax(1, abs(g))), tol)
  he <- fit$obj$he(par)
  expect_true(all(is.finite(he)))
}

fit_at <- function(family, formula, y) {
  suppressWarnings(drmTMB(
    formula, family = family, data = data.frame(y = y),
    control = drm_control(se = FALSE)
  ))
}

set_par <- function(fit, ...) {
  par <- fit$obj$par
  upd <- list(...)
  for (nm in names(upd)) par[names(par) == nm] <- upd[[nm]]
  par
}

test_that("student gradient and Hessian are correct either side of the nu = 100 switch", {
  fit <- fit_at(student(), bf(y ~ 1, sigma ~ 1, nu ~ 1), c(0.2, 1, 2.4, -1.1))
  for (d in c(-1e-8, 0, 1e-8)) {
    grad_check(fit, set_par(fit, beta_mu = 1, beta_sigma = log(1.3), beta_nu = log(98 * (1 + d))))
  }
  # x = z^2 / nu crosses the log1p series switch at 0.01 (nu = 1000)
  z <- sqrt(0.01 * 1000)
  fit2 <- fit_at(student(), bf(y ~ 1, sigma ~ 1, nu ~ 1), 1 + 1.3 * z)
  for (d in c(-1e-8, 0, 1e-8)) {
    grad_check(fit2, set_par(fit2, beta_mu = 1, beta_sigma = log(1.3), beta_nu = log(998 * (1 + d))))
  }
})

test_that("gamma gradient and Hessian are correct at the Stirling and series switches", {
  fit <- fit_at(stats::Gamma(link = "log"), bf(y ~ 1, sigma ~ 1), c(2.1, 2.7, 3.9))
  for (d in c(-1e-8, 0, 1e-8)) {
    grad_check(fit, set_par(fit, beta_mu = log(2.5), beta_sigma = -0.5 * log(30 * (1 + d))))
  }
  # |log(y / mu)| = 0.5 is the expm1 series switch
  for (w in c(-0.5, 0.5)) {
    for (d in c(-1e-8, 0, 1e-8)) {
      f <- fit_at(stats::Gamma(link = "log"), bf(y ~ 1, sigma ~ 1), 2.5 * exp(w + d))
      grad_check(f, set_par(f, beta_mu = log(2.5), beta_sigma = -0.5 * log(5)))
    }
  }
})

test_that("beta gradient and Hessian are correct at the Stirling and series switches", {
  fit <- fit_at(beta_family(), bf(y ~ 1, sigma ~ 1), c(0.31, 0.5, 0.64))
  mu_eta <- stats::qlogis(0.3)
  for (d in c(-1e-8, 0, 1e-8)) {
    # alpha + beta = phi = 30, and alpha = 0.3 * 100 = 30
    for (phi in c(30, 100)) {
      grad_check(fit, set_par(fit, beta_mu = mu_eta, beta_sigma = -0.5 * log(phi * (1 + d))))
    }
  }
  # u_a = y p / a - 1 = +-0.1 is the x - log1p(x) series switch
  for (u in c(-0.1, 0.1)) {
    for (d in c(-1e-8, 0, 1e-8)) {
      f <- fit_at(beta_family(), bf(y ~ 1, sigma ~ 1), 0.3 * (1 + u + d))
      grad_check(f, set_par(f, beta_mu = mu_eta, beta_sigma = -0.5 * log(20)))
    }
  }
})

test_that("beta-binomial gradient and Hessian are correct at the drm_lgamma_ratio switch", {
  dat <- data.frame(success = c(3, 7, 11), failure = c(17, 13, 9))
  fit <- suppressWarnings(drmTMB(
    bf(cbind(success, failure) ~ 1, sigma ~ 1),
    family = beta_binomial(), data = dat, control = drm_control(se = FALSE)
  ))
  # alpha = mu * phi = 100 at phi = 100 / 0.3; beta = 100 at phi = 100 / 0.7
  for (phi in c(100 / 0.3, 100 / 0.7)) {
    for (d in c(-1e-8, 0, 1e-8)) {
      grad_check(fit, set_par(
        fit, beta_mu = stats::qlogis(0.3), beta_sigma = -0.5 * log(phi * (1 + d))
      ))
    }
  }
})


# ---- mi() Beta, zero-one Beta and Gamma priors (#1548) ----------------------
#
# The mi() imputation priors evaluate the same densities as the response
# kernels above, so they reuse the same pinned references. Each fit has the
# eight case values as observed predictor rows plus one row whose predictor
# and response are both missing (it adds nothing to the objective). With the
# mi() slope at 0 the response rows reduce to dnorm(y, 0.5, 1), so
# -fn - sum(dnorm) is the sum of the eight prior log-densities.

mi_prior_sum <- function(family, x, ..., y_last = NA_real_) {
  dat <- data.frame(
    y = c(rep(c(0.2, 0.9), length.out = length(x)), y_last),
    x = c(x, NA_real_)
  )
  fit <- suppressWarnings(drmTMB(
    bf(y ~ mi(x), sigma ~ 1),
    data = dat,
    impute = list(x = impute_model(x ~ 1, family = family)),
    missing = miss_control(response = "include", predictor = "model"),
    control = drm_control(se = FALSE)
  ))
  par <- fit$obj$par
  par[names(par) == "beta_mu"] <- c(0.5, 0)
  par[names(par) == "beta_sigma"] <- 0
  upd <- list(...)
  for (nm in names(upd)) par[names(par) == nm] <- upd[[nm]]
  y_obs <- dat$y[!is.na(dat$y)]
  -fit$obj$fn(par) - sum(stats::dnorm(y_obs, 0.5, 1, log = TRUE))
}

test_that("gamma mi() prior matches the exact density at shape 1e4, 1e6, 1e8", {
  for (cs in gamma_cases) {
    got <- mi_prior_sum(
      stats::Gamma(link = "log"), cs$y,
      beta_mi = cs$eta, log_sigma_mi = cs$ls
    )
    # eight rows, each held to the response kernel's bar above
    bar <- 8 * if (cs$s >= 1e8) 1.5e-12 else 1e-12
    expect_lt(abs(got - sum(cs$ref)), bar, label = paste("gamma mi shape =", cs$s))
  }
})

test_that("gamma mi() quadrature integrand is exact for a missing predictor at shape 1e4, 1e6, 1e8", {
  # The last row has the predictor missing and the response observed. At slope
  # 0 its marginal is dnorm(y) times the integral of the prior, which is 1.
  for (cs in gamma_cases) {
    got <- mi_prior_sum(
      stats::Gamma(link = "log"), cs$y,
      beta_mi = cs$eta, log_sigma_mi = cs$ls, y_last = 0.4
    )
    bar <- 8 * 1.5e-12 + 1e-11
    expect_lt(abs(got - sum(cs$ref)), bar, label = paste("gamma mi integrand shape =", cs$s))
  }
})

test_that("beta mi() prior matches the exact density at phi 1e4, 1e6, 1e8", {
  for (cs in beta_cases) {
    got <- mi_prior_sum(
      beta_family(), cs$y,
      beta_mi = cs$eta, log_sigma_mi = cs$ls
    )
    # same per-row bar as the response kernel, including the mu-rounding floor
    floor <- 3 * eps * cs$phi * max(abs(cs$y - cs$m))
    bar <- 8 * (1e-12 + floor)
    expect_lt(abs(got - sum(cs$ref)), bar, label = paste("beta mi phi =", cs$phi, "mu =", cs$m))
  }
})

test_that("zero-one beta mi() prior matches the exact density at phi 1e4, 1e6, 1e8", {
  eta_zoi <- stats::qlogis(0.1)
  log_one_minus_zoi <- -log1p(exp(eta_zoi))
  for (cs in beta_cases) {
    got <- mi_prior_sum(
      zero_one_beta(), cs$y,
      beta_mi = cs$eta, log_sigma_mi = cs$ls, beta_zoi = eta_zoi
    )
    floor <- 3 * eps * cs$phi * max(abs(cs$y - cs$m))
    bar <- 8 * (1e-12 + floor)
    ref <- sum(cs$ref) + 8 * log_one_minus_zoi
    expect_lt(abs(got - ref), bar, label = paste("zero-one beta mi phi =", cs$phi, "mu =", cs$m))
  }
})

test_that("beta and gamma mi() priors are unchanged at ordinary shape", {
  # Ordinary shapes must agree with stats::dbeta() and stats::dgamma(), which
  # are accurate there, to rounding.
  x_beta <- c(0.12, 0.3, 0.47, 0.81)
  for (phi in c(0.8, 5, 40)) {
    got <- mi_prior_sum(
      beta_family(), x_beta,
      beta_mi = stats::qlogis(0.4), log_sigma_mi = -0.5 * log(phi)
    )
    mm <- 1e-12 + (1 - 2e-12) * 0.4
    ref <- sum(stats::dbeta(x_beta, mm * phi, (1 - mm) * phi, log = TRUE))
    expect_lt(abs(got - ref), 1e-12, label = paste("beta mi phi =", phi))
  }
  x_gamma <- c(0.4, 1.3, 2.2, 5.9)
  for (s in c(0.7, 4, 25)) {
    got <- mi_prior_sum(
      stats::Gamma(link = "log"), x_gamma,
      beta_mi = log(2), log_sigma_mi = -0.5 * log(s)
    )
    ref <- sum(stats::dgamma(x_gamma, shape = s, scale = 2 / s, log = TRUE))
    expect_lt(abs(got - ref), 1e-12, label = paste("gamma mi shape =", s))
  }
})

# ---- R-side beta-binomial densities (#1548) ---------------------------------
#
# The R pmf behind the beta_binomial d/p/q closure and the R log-density used
# for beta-binomial mi() predictors carried the same lgamma sum as the old
# compiled kernel.

test_that("R beta-binomial densities match the exact density at phi 1e4 to 1e12", {
  n <- 20L
  ks <- c(0L, 1L, 4L, 6L, 10L, 15L, 20L)
  for (phi in c(1e4, 1e6, 1e8, 1e10, 1e12)) {
    for (m in c(0.3, 0.5)) {
      a <- m * phi
      b <- (1 - m) * phi
      ref <- vapply(ks, function(k) bb_exact(k, n, a, b), numeric(1))
      sigma <- 1 / sqrt(phi)
      got_mi <- drm_beta_binomial_missing_predictor_log_density(
        ks, n, mu = m, sigma = sigma
      )
      # the mi() helper rebuilds phi from sigma: phi * eps relative rounding
      ref_mi <- vapply(ks, function(k) {
        p <- 1 / sigma^2
        bb_exact(k, n, m * p, (1 - m) * p)
      }, numeric(1))
      expect_lt(max(abs(got_mi - ref_mi)), 1e-12,
        label = paste("mi() helper phi =", phi, "mu =", m))
      native <- drm_beta_shapes(m, sigma)
      ref_d <- vapply(ks, function(k) {
        bb_exact(k, n, native$shape1, native$shape2)
      }, numeric(1))
      got_d <- log(drm_beta_binomial_dpmf(
        ks, list(mu = m, sigma = sigma, trials = rep(n, length(ks)))
      ))
      expect_lt(max(abs(got_d - ref_d)), 1e-12,
        label = paste("dpmf phi =", phi, "mu =", m))
    }
  }
})

test_that("R lgamma ratio agrees with lgamma() below the switch and is continuous at it", {
  for (m in c(0, 1, 3, 20, 500)) {
    x <- c(0.5, 7, 99.999)
    expect_equal(drm_lgamma_ratio(x, m), lgamma(x + m) - lgamma(x), tolerance = 1e-14)
    # either side of x = 100 the two branches agree to rounding
    lo <- drm_lgamma_ratio(100 * (1 - 1e-12), m)
    hi <- drm_lgamma_ratio(100, m)
    expect_lt(abs(hi - lo), 1e-11 * max(1, m))
  }
})

test_that("beta and gamma mi() prior gradients are correct at the Stirling switch", {
  mi_fit <- function(family, x) {
    suppressWarnings(drmTMB(
      bf(y ~ mi(x), sigma ~ 1),
      data = data.frame(y = c(0.2, 0.9, 0.4, 0.6), x = c(x, NA_real_)),
      impute = list(x = impute_model(x ~ 1, family = family)),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ))
  }
  # The last row has the predictor missing and the response observed, so the
  # quadrature copies are on the tape too.
  fb <- mi_fit(beta_family(), c(0.31, 0.5, 0.64))
  fg <- mi_fit(stats::Gamma(link = "log"), c(2.1, 2.7, 3.9))
  for (d in c(-1e-8, 0, 1e-8)) {
    # phi = alpha + beta = 30, and alpha = 0.3 * 100 = 30
    for (phi in c(30, 100)) {
      grad_check(fb, set_par(fb,
        beta_mu = c(0.5, 0.4), beta_sigma = 0,
        beta_mi = stats::qlogis(0.3), log_sigma_mi = -0.5 * log(phi * (1 + d))
      ))
    }
    grad_check(fg, set_par(fg,
      beta_mu = c(0.5, 0.1), beta_sigma = 0,
      beta_mi = log(2.5), log_sigma_mi = -0.5 * log(30 * (1 + d))
    ))
  }
})
