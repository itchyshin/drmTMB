# #1551: ordinary mean (1 | g) on families that escape the fe-only fence
# used to start Julia and then abort at the resd coef_labels echo.
# Refuse in R before setup. Zero Julia throughout.

ordinary_mean_re_dat <- function(n = 40L, seed = 20261025) {
  set.seed(seed)
  g <- factor(rep(seq_len(8), each = n / 8))
  x <- stats::rnorm(n)
  list(
    poisson = data.frame(y = stats::rpois(n, exp(0.2 + 0.3 * x)), x = x, g = g),
    gamma = data.frame(y = stats::rgamma(n, shape = 2, rate = exp(-0.2 - 0.3 * x)), x = x, g = g),
    nbinom2 = data.frame(y = stats::rnbinom(n, size = 4, mu = exp(0.4 + 0.2 * x)), x = x, g = g),
    beta = data.frame(
      y = pmin(pmax(stats::rbeta(n, 3, 3), 1e-4), 1 - 1e-4),
      x = x,
      g = g
    ),
    binomial = data.frame(
      successes = stats::rbinom(n, size = 8, prob = 0.4),
      failures = 8L - stats::rbinom(n, size = 8, prob = 0.4),
      x = x,
      g = g
    )
  )
}

expect_ordinary_mean_re_fence <- function(formula, family, data) {
  withr::local_envvar(DRM_JL_PATH = NA, DRM_JL_PHYLO_PATH = NA)
  err <- tryCatch(
    drmTMB(formula, family = family, data = data, engine = "julia"),
    error = function(e) e
  )
  expect_s3_class(err, "error")
  msg <- conditionMessage(err)
  expect_match(msg, "does not yet send a residual-SD label")
  expect_false(grepl("needs a local DRModels.jl", msg, fixed = TRUE))
}

test_that("the unlabelled ordinary-mean cohort matches the registry helper (#1551)", {
  fams <- drmTMB:::drm_julia_ordinary_mean_re_unlabelled_families()
  expect_true(all(c("poisson", "gamma", "nbinom2", "beta", "binomial") %in% fams))
  expect_false("gaussian" %in% fams)
  expect_false("biv_gaussian" %in% fams)
})

test_that("poisson/gamma/nbinom2/beta/binomial ordinary (1 | g) refuse before Julia (#1551)", {
  dat <- ordinary_mean_re_dat()
  expect_ordinary_mean_re_fence(
    bf(y ~ x + (1 | g)),
    stats::poisson(),
    dat$poisson
  )
  expect_ordinary_mean_re_fence(
    bf(y ~ x + (1 | g), sigma ~ 1),
    stats::Gamma(link = "log"),
    dat$gamma
  )
  expect_ordinary_mean_re_fence(
    bf(y ~ x + (1 | g), sigma ~ 1),
    nbinom2(),
    dat$nbinom2
  )
  expect_ordinary_mean_re_fence(
    bf(y ~ x + (1 | g), sigma ~ 1),
    beta_family(),
    dat$beta
  )
  expect_ordinary_mean_re_fence(
    bf(cbind(successes, failures) ~ x + (1 | g)),
    stats::binomial(),
    dat$binomial
  )
})

test_that("gaussian ordinary (1 | g) is not fenced and still reaches Julia setup (#1551 neighbour)", {
  withr::local_envvar(DRM_JL_PATH = NA, DRM_JL_PHYLO_PATH = NA)
  n <- 40L
  g <- factor(rep(seq_len(8), each = 5))
  x <- stats::rnorm(n)
  dat <- data.frame(y = stats::rnorm(n, mean = 0.3 * x), x = x, g = g)
  err <- tryCatch(
    drmTMB(
      bf(y ~ x + (1 | g), sigma ~ 1),
      family = gaussian(),
      data = dat,
      engine = "julia"
    ),
    error = function(e) e
  )
  expect_s3_class(err, "error")
  msg <- conditionMessage(err)
  expect_match(
    msg,
    "JuliaCall package|needs a local DRModels.jl"
  )
  expect_false(grepl("residual-SD label", msg))
})

test_that("poisson fixed-effect (no bar) is not fenced (#1551 neighbour)", {
  withr::local_envvar(DRM_JL_PATH = NA, DRM_JL_PHYLO_PATH = NA)
  n <- 40L
  x <- stats::rnorm(n)
  dat <- data.frame(y = stats::rpois(n, exp(0.2 + 0.3 * x)), x = x)
  err <- tryCatch(
    drmTMB(bf(y ~ x), family = stats::poisson(), data = dat, engine = "julia"),
    error = function(e) e
  )
  expect_s3_class(err, "error")
  msg <- conditionMessage(err)
  expect_match(
    msg,
    "JuliaCall package|needs a local DRModels.jl"
  )
  expect_false(grepl("residual-SD label", msg))
})
