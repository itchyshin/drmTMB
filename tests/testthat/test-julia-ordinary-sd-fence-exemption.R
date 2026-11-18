# The #1551 fence refuses a BARE ordinary mean bar on the Julia bridge for
# poisson, nbinom2, gamma, beta and binomial. It must not refuse a bar whose
# group carries an ordinary sd() formula, the admitted SD-regression routes
# whose live tests (test-julia-poisson-sd.R, -gamma-sd.R, -negbinomial-sd.R,
# -beta-sd.R, -binomial-sd.R) skip without Julia. Static throughout: no Julia
# is started, so these tests check the R admission gate only. They make no
# claim that the Julia fit itself works; that is the job of the live tests.

sd_fence_dat <- function(n = 80L, seed = 20261101) {
  set.seed(seed)
  g <- factor(rep(seq_len(10), each = n / 10))
  x <- stats::rnorm(n)
  w <- stats::rnorm(n)
  data.frame(
    g = g, x = x, w = w,
    poisson = stats::rpois(n, exp(0.2 + 0.3 * x)),
    gamma = stats::rgamma(n, shape = 2, rate = exp(-0.2 - 0.3 * x)),
    nbinom2 = stats::rnbinom(n, size = 4, mu = exp(0.4 + 0.2 * x)),
    beta = pmin(pmax(stats::rbeta(n, 3, 3), 1e-4), 1 - 1e-4),
    successes = stats::rbinom(n, size = 8, prob = 0.4),
    failures = 8L - stats::rbinom(n, size = 8, prob = 0.4)
  )
}

sd_fence_cells <- function() {
  list(
    poisson = list(family = stats::poisson(), lhs = "poisson ~", extra = ""),
    gamma = list(family = stats::Gamma(link = "log"), lhs = "gamma ~", extra = ", sigma ~ 1"),
    nbinom2 = list(family = nbinom2(), lhs = "nbinom2 ~", extra = ", sigma ~ 1"),
    beta = list(family = beta_family(), lhs = "beta ~", extra = ", sigma ~ 1"),
    binomial = list(family = stats::binomial(), lhs = "cbind(successes, failures) ~", extra = "")
  )
}

sd_fence_formula <- function(cell, bar, sd_rhs = "w", sd_lhs = "sd(g)") {
  sd_part <- if (is.null(sd_rhs)) "" else sprintf(", %s ~ %s", sd_lhs, sd_rhs)
  eval(parse(text = sprintf(
    "bf(%s x + %s%s%s)", cell$lhs, bar, cell$extra, sd_part
  )))
}

sd_fence_error <- function(cell, data, ...) {
  withr::local_envvar(DRM_JL_PATH = NA, DRM_JL_PHYLO_PATH = NA)
  tryCatch(
    drmTMB(sd_fence_formula(cell, ...), family = cell$family, data = data, engine = "julia"),
    error = function(e) e
  )
}

expect_passes_fence <- function(err) {
  expect_s3_class(err, "error")
  msg <- conditionMessage(err)
  expect_false(grepl("residual-SD label", msg, fixed = TRUE))
  expect_match(msg, "JuliaCall package|needs a local DRModels.jl")
}

expect_fenced <- function(err) {
  expect_s3_class(err, "error")
  expect_match(conditionMessage(err), "does not yet send a residual-SD label")
}

test_that("an ordinary intercept or independent slope with sd() passes the #1551 fence", {
  dat <- sd_fence_dat()
  for (nm in names(sd_fence_cells())) {
    cell <- sd_fence_cells()[[nm]]
    expect_passes_fence(sd_fence_error(cell, dat, bar = "(1 | g)"))
    expect_passes_fence(sd_fence_error(cell, dat, bar = "(0 + x | g)"))
    # Constant-SD spelling: same exemption as the predictor-dependent one.
    expect_passes_fence(sd_fence_error(cell, dat, bar = "(1 | g)", sd_rhs = "1"))
  }
})

test_that("a bare ordinary mean bar stays fenced for all five families (#1551)", {
  dat <- sd_fence_dat()
  for (nm in names(sd_fence_cells())) {
    cell <- sd_fence_cells()[[nm]]
    expect_fenced(sd_fence_error(cell, dat, bar = "(1 | g)", sd_rhs = NULL))
    expect_fenced(sd_fence_error(cell, dat, bar = "(0 + x | g)", sd_rhs = NULL))
  }
})

test_that("a correlated ordinary bar with sd() stays fenced outside Binomial", {
  dat <- sd_fence_dat()
  cells <- sd_fence_cells()
  for (nm in c("poisson", "gamma", "nbinom2", "beta")) {
    expect_fenced(sd_fence_error(cells[[nm]], dat, bar = "(1 + x | g)"))
  }
  # Binomial has live ordinary correlated sd() bridge tests, so it is not
  # refused at this gate.
  expect_passes_fence(sd_fence_error(cells$binomial, dat, bar = "(1 + x | g)"))
})

test_that("an sd() entry for a different group does not exempt the bar", {
  dat <- sd_fence_dat()
  dat$h <- factor(rep(seq_len(5), length.out = nrow(dat)))
  err <- withr::with_envvar(
    c(DRM_JL_PATH = NA, DRM_JL_PHYLO_PATH = NA),
    tryCatch(
      drmTMB(
        bf(poisson ~ x + (1 | g), sd(h) ~ w),
        family = stats::poisson(), data = dat, engine = "julia"
      ),
      error = function(e) e
    )
  )
  expect_s3_class(err, "error")
  # Either the fence or an earlier native-grammar refusal, never a pass to
  # Julia setup.
  expect_false(grepl("JuliaCall package|needs a local DRModels.jl", conditionMessage(err)))
})

test_that("the gate helper is exact about groups and families", {
  helper <- drmTMB:::drm_julia_ordinary_mean_bars_have_sd
  with_sd <- bf(y ~ x + (1 | g), sd(g) ~ w)
  bare <- bf(y ~ x + (1 | g))
  other <- bf(y ~ x + (1 | g), sd(h) ~ w)
  two_bars <- bf(y ~ x + (1 | g) + (0 + x | h), sd(g) ~ w)
  q2 <- bf(y ~ x + (1 + x | g), sd(g) ~ w)
  expect_true(helper(with_sd, "poisson"))
  expect_false(helper(bare, "poisson"))
  expect_false(helper(other, "poisson"))
  expect_false(helper(two_bars, "poisson"))
  expect_false(helper(q2, "poisson"))
  expect_true(helper(q2, "binomial"))
})

test_that("Gaussian ordinary (1 | g) with sd() and the fixed-effect Poisson are unaffected", {
  withr::local_envvar(DRM_JL_PATH = NA, DRM_JL_PHYLO_PATH = NA)
  dat <- sd_fence_dat()
  dat$y <- stats::rnorm(nrow(dat))
  err <- tryCatch(
    drmTMB(bf(y ~ x + (1 | g), sigma ~ 1, sd(g) ~ w), family = gaussian(), data = dat, engine = "julia"),
    error = function(e) e
  )
  expect_s3_class(err, "error")
  expect_false(grepl("residual-SD label", conditionMessage(err), fixed = TRUE))
  err <- tryCatch(
    drmTMB(bf(poisson ~ x), family = stats::poisson(), data = dat, engine = "julia"),
    error = function(e) e
  )
  expect_passes_fence(err)
})
