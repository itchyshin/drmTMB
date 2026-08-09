# Offsets on the `mu` formula across univariate families.
#
# The load-bearing check is the constant-offset identity. For any link g and a
# constant offset c, `g(mu) = c + b0 + b1 x` is the same model as
# `g(mu) = b0' + b1 x` with `b0' = b0 + c`. So fitting with `offset(c)` must
# lower the estimated intercept by exactly `c` and leave every slope untouched.
# That holds for identity, log, and logit links alike, which makes one oracle
# sufficient for the whole family set.

new_offset_data <- function(n = 200, const = 0.35, seed = 20260809) {
  set.seed(seed)
  x <- stats::rnorm(n)
  data.frame(x = x, k = rep(const, n))
}

# Each family draws from its own seed so the fixture does not depend on the
# order the cases are built in; sharing one stream made convergence for a given
# family depend on which families were generated before it.
seeded <- function(seed, expr) {
  set.seed(seed)
  force(expr)
}

offset_mu_coefs <- function(fit) {
  out <- as.numeric(stats::coef(fit)$mu)
  names(out) <- names(stats::coef(fit)$mu)
  out
}

# Fit the same model with and without `offset(k)` and return both coefficient
# vectors. Formulas are built as text because `bf()` captures its arguments.
offset_pair <- function(lhs, rest, family_call, dat) {
  build <- function(with_offset) {
    txt <- sprintf(
      "drmTMB(bf(mu = %s ~ x%s%s), data = dat, family = %s)",
      lhs, if (with_offset) " + offset(k)" else "", rest, family_call
    )
    eval(parse(text = txt), envir = environment())
  }
  list(plain = offset_mu_coefs(build(FALSE)), offset = offset_mu_coefs(build(TRUE)))
}

test_that("a constant mu offset shifts the intercept and preserves slopes", {
  skip_on_cran()
  const <- 0.35
  base <- new_offset_data(const = const)
  n <- nrow(base)

  cases <- list(
    gaussian = list(
      lhs = "y", rest = ", sigma = ~1", family = "gaussian()",
      data = seeded(101, transform(base, y = stats::rnorm(n, 1 + 0.5 * x, 0.5)))
    ),
    # Student and skew-normal need data that actually carries the feature their
    # third parameter describes; Gaussian noise leaves `nu` unidentified and the
    # optimizer reports false convergence.
    student = list(
      lhs = "y", rest = ", sigma = ~1, nu = ~1", family = "student()",
      data = seeded(102, transform(base, y = 1 + 0.5 * x + 0.5 * stats::rt(n, df = 4)))
    ),
    skew_normal = list(
      lhs = "y", rest = ", sigma = ~1, nu = ~1", family = "skew_normal()",
      data = seeded(103, transform(
        base,
        y = 1 + 0.5 * x + (stats::rgamma(n, shape = 2, scale = 0.4) - 0.8)
      ))
    ),
    lognormal = list(
      lhs = "y", rest = ", sigma = ~1", family = "lognormal()",
      data = seeded(104, transform(base, y = exp(stats::rnorm(n, 1 + 0.5 * x, 0.4))))
    ),
    gamma = list(
      lhs = "y", rest = ", sigma = ~1", family = "stats::Gamma(link = \"log\")",
      data = seeded(105, transform(base, y = stats::rgamma(n, 4, rate = 4 / exp(1 + 0.5 * x))))
    ),
    beta = list(
      lhs = "y", rest = ", sigma = ~1", family = "beta()",
      data = seeded(106, transform(base, y = pmin(pmax(stats::plogis(0.3 + 0.5 * x +
        stats::rnorm(n, 0, 0.3)), 1e-4), 1 - 1e-4)))
    ),
    # Draw genuinely over-dispersed counts: binomial draws would leave the
    # beta-binomial `sigma` at its boundary and the optimizer would report false
    # convergence even though the mean coefficients are recovered exactly.
    beta_binomial = list(
      lhs = "cbind(succ, fail)", rest = ", sigma = ~1", family = "beta_binomial()",
      data = seeded(107, local({
        mu_i <- stats::plogis(0.3 + 0.5 * base$x)
        conc <- 6
        p_i <- stats::rbeta(n, mu_i * conc, (1 - mu_i) * conc)
        succ <- stats::rbinom(n, 20, p_i)
        transform(base, succ = succ, fail = 20 - succ)
      }))
    )
  )

  # The identity is exact in theory, so the tolerance only absorbs optimizer
  # noise. A mis-plumbed offset misses by the size of the offset itself (0.35
  # here), which is two orders of magnitude above this bound.
  tol <- 1e-3
  for (nm in names(cases)) {
    cs <- cases[[nm]]
    both <- offset_pair(cs$lhs, cs$rest, cs$family, cs$data)
    expect_equal(
      unname(both$offset[[1L]]), unname(both$plain[[1L]]) - const,
      tolerance = tol,
      info = paste0(nm, ": intercept must absorb the constant offset")
    )
    expect_equal(
      unname(both$offset[[2L]]), unname(both$plain[[2L]]),
      tolerance = tol,
      info = paste0(nm, ": slope must be invariant to a constant offset")
    )
  }
})

test_that("cumulative_logit offsets leave the slope invariant", {
  skip_on_cran()
  base <- new_offset_data()
  n <- nrow(base)
  dat <- transform(
    base,
    y = factor(cut(0.5 * x + stats::rlogis(n), c(-Inf, -1, 1, Inf)), ordered = TRUE)
  )
  # An ordinal model has cutpoints rather than an intercept, so the shift is
  # absorbed there; only slope invariance is checkable.
  plain <- drmTMB(bf(mu = y ~ x), data = dat, family = cumulative_logit())
  shifted <- drmTMB(bf(mu = y ~ x + offset(k)), data = dat, family = cumulative_logit())
  expect_equal(
    unname(offset_mu_coefs(shifted)[[1L]]),
    unname(offset_mu_coefs(plain)[[1L]]),
    tolerance = 1e-4
  )
})

test_that("zero_one_beta offsets shift only the interior component", {
  skip_on_cran()
  const <- 0.35
  base <- new_offset_data(const = const)
  n <- nrow(base)
  y <- stats::plogis(0.3 + 0.5 * base$x + stats::rnorm(n, 0, 0.3))
  y[1:20] <- 0
  y[21:35] <- 1
  dat <- transform(base, y = y)
  rest <- ", sigma = ~1, zoi = ~1, coi = ~1"
  both <- offset_pair("y", rest, "zero_one_beta()", dat)
  expect_equal(
    unname(both$offset[[1L]]), unname(both$plain[[1L]]) - const,
    tolerance = 1e-4
  )
  expect_equal(
    unname(both$offset[[2L]]), unname(both$plain[[2L]]),
    tolerance = 1e-4
  )
})

test_that("a mu offset composes with an ordinary random intercept", {
  skip_on_cran()
  # The template adds the offset to eta before folding in random-effect
  # contributions, so the constant-offset identity must survive unchanged. One
  # identity-link and one log-link family is enough to exercise both paths.
  const <- 0.35
  set.seed(2026)
  n_group <- 40
  per <- 8
  n <- n_group * per
  g <- factor(rep(seq_len(n_group), each = per))
  u <- stats::rnorm(n_group, 0, 0.6)
  x <- stats::rnorm(n)
  base <- data.frame(x = x, k = rep(const, n), g = g)

  pair <- function(dat, family_call, rest) {
    co <- function(with_offset) {
      txt <- sprintf(
        "drmTMB(bf(mu = y ~ x + (1 | g)%s%s), data = dat, family = %s)",
        if (with_offset) " + offset(k)" else "", rest, family_call
      )
      as.numeric(stats::coef(eval(parse(text = txt), envir = environment()))$mu)
    }
    list(plain = co(FALSE), offset = co(TRUE))
  }

  gauss <- pair(
    transform(base, y = stats::rnorm(n, 1 + 0.5 * x + u[g], 0.5)),
    "gaussian()", ", sigma = ~1"
  )
  expect_equal(gauss$offset[[1L]], gauss$plain[[1L]] - const, tolerance = 1e-3)
  expect_equal(gauss$offset[[2L]], gauss$plain[[2L]], tolerance = 1e-3)

  gam <- pair(
    transform(base, y = stats::rgamma(n, 6, rate = 6 / exp(1 + 0.5 * x + u[g]))),
    "stats::Gamma(link = \"log\")", ", sigma = ~1"
  )
  expect_equal(gam$offset[[1L]], gam$plain[[1L]] - const, tolerance = 1e-3)
  expect_equal(gam$offset[[2L]], gam$plain[[2L]], tolerance = 1e-3)
})

test_that("the offset vector is stored at full model-frame length", {
  base <- new_offset_data(n = 80)
  dat <- transform(base, y = stats::rnorm(80, 1 + 0.5 * x, 0.5))
  fit <- drmTMB(bf(mu = y ~ x + offset(k), sigma = ~1), data = dat, family = gaussian())
  expect_length(fit$model$offset$mu, nrow(dat))
  expect_equal(as.numeric(fit$model$offset$mu), dat$k)
})

test_that("non-finite offsets are rejected", {
  base <- new_offset_data(n = 60)
  dat <- transform(base, y = stats::rnorm(60, 1 + 0.5 * x, 0.5), e = c(0, runif(59, 1, 3)))
  expect_error(
    drmTMB(bf(mu = y ~ x + offset(log(e)), sigma = ~1), data = dat, family = gaussian()),
    "finite"
  )
})

test_that("offsets remain rejected for the deferred families", {
  base <- new_offset_data(n = 100)
  n <- nrow(base)

  # Truncated and hurdle NB2 renormalise the observed mean over the positive
  # support, so an exposure offset would not scale the reported mean the way it
  # does for plain Poisson/NB2. Deferred deliberately, pending that derivation.
  trunc_dat <- transform(base, y = pmax(stats::rpois(n, exp(1 + 0.5 * x)), 1L))
  expect_error(
    drmTMB(bf(mu = y ~ x + offset(k), sigma = ~1), data = trunc_dat,
           family = truncated_nbinom2()),
    "offset"
  )
  expect_error(
    drmTMB(bf(mu = y ~ x + offset(k), sigma = ~1, hu = ~1), data = trunc_dat,
           family = truncated_nbinom2()),
    "offset"
  )

  # Bivariate families would need per-response offset vectors in the template.
  biv_dat <- transform(base, y1 = stats::rnorm(n), y2 = stats::rnorm(n))
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x + offset(k), mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
      data = biv_dat, family = c(gaussian(), gaussian())
    ),
    "offset"
  )
})

test_that("gaussian aggregation rejects a mu offset", {
  base <- new_offset_data(n = 100)
  dat <- transform(base, y = stats::rnorm(100, 1 + 0.5 * x, 0.5))
  expect_error(
    drmTMB(
      bf(mu = y ~ x + offset(k), sigma = ~1), data = dat, family = gaussian(),
      control = drm_control(aggregate_gaussian = TRUE)
    ),
    "aggregation does not support"
  )
})

test_that("predictions carry the mu offset for a newly supported family", {
  base <- new_offset_data(n = 120)
  dat <- transform(base, y = stats::rgamma(120, 4, rate = 4 / exp(1 + 0.5 * x)))
  fit <- drmTMB(
    bf(mu = y ~ x + offset(k), sigma = ~1), data = dat,
    family = stats::Gamma(link = "log")
  )
  # Doubling the offset must scale the log-link mean by exp(k) exactly.
  nd_lo <- data.frame(x = c(-1, 0, 1), k = rep(0.35, 3))
  nd_hi <- transform(nd_lo, k = k + log(2))
  p_lo <- predict(fit, newdata = nd_lo, dpar = "mu", type = "response")
  p_hi <- predict(fit, newdata = nd_hi, dpar = "mu", type = "response")
  expect_equal(as.numeric(p_hi), 2 * as.numeric(p_lo), tolerance = 1e-6)
})
