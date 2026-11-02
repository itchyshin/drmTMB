# Boundary pins for ordinary q >= 3 correlated blocks with sd() formulas.
# Gaussian q3 and q4 blocks with per-coefficient sd() formulas are admitted
# (2026-11-02, see test-gaussian-q3-per-coef-sd.R); Gaussian blocks of five or
# more coefficients stay refused. Poisson/NB2 refuse any q3 block even without
# sd(). These tests pin the designed refusals so that an accidental partial
# admission fails loudly.

ordinary_q3_sd_fixture <- function(groups = 24L, repeats = 8L,
                                   seed = 20261101L) {
  set.seed(seed)
  id <- factor(rep(seq_len(groups), each = repeats))
  n <- length(id)
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  w <- rep(seq(-1, 1, length.out = groups), each = repeats)
  b <- matrix(stats::rnorm(3L * groups, sd = 0.4), ncol = 3L)
  eta <- 0.2 + 0.3 * x - 0.2 * z + b[as.integer(id), 1L] +
    b[as.integer(id), 2L] * x + b[as.integer(id), 3L] * z
  data.frame(
    y = eta + stats::rnorm(n, sd = 0.5),
    count = stats::rpois(n, exp(eta / 2)),
    nb = stats::rnbinom(n, mu = exp(eta / 2), size = 3),
    x, z, w, id
  )
}

test_that("Gaussian q3 block without sd() still fits (constant SDs only)", {
  dat <- ordinary_q3_sd_fixture()
  fit <- drmTMB(
    bf(y ~ x + z + (1 + x + z | id), sigma ~ 1), family = stats::gaussian(),
    data = dat, control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  expect_true(is.finite(as.numeric(logLik(fit))))
})

test_that("Gaussian q5 block with sd() on any coefficient is refused cleanly", {
  dat <- ordinary_q3_sd_fixture()
  dat$u <- stats::rnorm(nrow(dat))
  dat$v <- stats::rnorm(nrow(dat))
  pattern <- "correlated random-effect block of five or more coefficients"
  fit_with <- function(sd_formula) {
    drmTMB(
      bf(y ~ x + z + (1 + x + z + u + v | id), sigma ~ 1, sd_formula),
      family = stats::gaussian(), data = dat,
      control = drm_control(se = FALSE)
    )
  }
  expect_error(fit_with(sd(id, coef = "(Intercept)") ~ w), pattern)
  expect_error(fit_with(sd(id, coef = "x") ~ w), pattern)
  expect_error(fit_with(sd(id, coef = "v") ~ w), pattern)
})

test_that("Poisson and NB2 q3 blocks are refused with or without sd()", {
  dat <- ordinary_q3_sd_fixture()
  sd_w <- sd(id, coef = "(Intercept)") ~ w
  expect_error(
    drmTMB(bf(count ~ x + z + (1 + x + z | id), sd_w),
           family = stats::poisson(), data = dat,
           control = drm_control(se = FALSE)),
    "support one unlabelled\\s+Poisson\\s+intercept-slope block"
  )
  expect_error(
    drmTMB(bf(count ~ x + z + (1 + x + z | id)),
           family = stats::poisson(), data = dat,
           control = drm_control(se = FALSE)),
    "Ordinary correlated Poisson random effects"
  )
  expect_error(
    drmTMB(bf(nb ~ x + z + (1 + x + z | id), sigma ~ 1, sd_w),
           family = nbinom2(), data = dat,
           control = drm_control(se = FALSE)),
    "Ordinary correlated NB2 random effects"
  )
  expect_error(
    drmTMB(bf(nb ~ x + z + (1 + x + z | id), sigma ~ 1),
           family = nbinom2(), data = dat,
           control = drm_control(se = FALSE)),
    "Ordinary correlated NB2 random effects"
  )
})
