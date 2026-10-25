# #1567: Gaussian ordinary (1 | g) with a factor fixed effect used to
# start Julia and then abort on coefficient-name spelling. Refuse in R
# before setup. Zero Julia throughout.

gaussian_factor_fe_dat <- function(n = 40L, seed = 20261025) {
  set.seed(seed)
  g <- factor(rep(seq_len(8), each = n / 8))
  x <- stats::rnorm(n)
  f <- factor(rep(c("a", "b", "c"), length.out = n))
  data.frame(y = stats::rnorm(n, mean = 0.3 * x), x = x, f = f, g = g)
}

test_that("gaussian (1 | g) with a factor FE refuses before Julia (#1567)", {
  withr::local_envvar(DRM_JL_PATH = NA, DRM_JL_PHYLO_PATH = NA)
  dat <- gaussian_factor_fe_dat()
  err <- tryCatch(
    drmTMB(
      bf(y ~ x + f + (1 | g), sigma ~ 1),
      family = gaussian(),
      data = dat,
      engine = "julia"
    ),
    error = function(e) e
  )
  expect_s3_class(err, "error")
  msg <- conditionMessage(err)
  expect_match(msg, "does not yet match factor coefficient names")
  expect_false(grepl("needs a local DRModels.jl", msg, fixed = TRUE))
})

test_that("gaussian (1 | g) with a character FE refuses before Julia (#1567)", {
  withr::local_envvar(DRM_JL_PATH = NA, DRM_JL_PHYLO_PATH = NA)
  dat <- gaussian_factor_fe_dat()
  dat$f <- as.character(dat$f)
  err <- tryCatch(
    drmTMB(
      bf(y ~ x + f + (1 | g), sigma ~ x),
      family = gaussian(),
      data = dat,
      engine = "julia"
    ),
    error = function(e) e
  )
  expect_s3_class(err, "error")
  expect_match(conditionMessage(err), "does not yet match factor coefficient names")
})

test_that("numeric-only gaussian (1 | g) still reaches Julia setup (#1567 neighbour)", {
  withr::local_envvar(DRM_JL_PATH = NA, DRM_JL_PHYLO_PATH = NA)
  dat <- gaussian_factor_fe_dat()
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
  expect_match(msg, "JuliaCall package|needs a local DRModels.jl")
  expect_false(grepl("factor coefficient names", msg))
})

test_that("gaussian factor FE without a bar still reaches Julia setup (#1567 neighbour)", {
  withr::local_envvar(DRM_JL_PATH = NA, DRM_JL_PHYLO_PATH = NA)
  dat <- gaussian_factor_fe_dat()
  err <- tryCatch(
    drmTMB(
      bf(y ~ x + f, sigma ~ 1),
      family = gaussian(),
      data = dat,
      engine = "julia"
    ),
    error = function(e) e
  )
  expect_s3_class(err, "error")
  msg <- conditionMessage(err)
  expect_match(msg, "JuliaCall package|needs a local DRModels.jl")
  expect_false(grepl("factor coefficient names", msg))
})
