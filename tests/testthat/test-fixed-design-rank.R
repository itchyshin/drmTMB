# #1478: every dense fixed-effect design is rank-checked before fitting,
# not only REML mu. A collinear sigma design must abort at spec-build time
# instead of reporting converged = TRUE and failing later in vcov().

aliased_ls_data <- function(n = 40L, seed = 20261025) {
  set.seed(seed)
  x <- stats::rnorm(n)
  data.frame(
    y = 0.3 + 0.5 * x + stats::rnorm(n, sd = 0.4),
    x = x,
    xdup = x
  )
}

test_that("ML sigma ~ x + xdup aborts before fitting (#1478)", {
  dat <- aliased_ls_data()
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ x + xdup),
      family = gaussian(),
      data = dat
    ),
    "rank-deficient"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ x + xdup),
      family = gaussian(),
      data = dat
    ),
    "sigma"
  )
})

test_that("ML mu ~ x + xdup aborts before fitting (#1478)", {
  dat <- aliased_ls_data()
  expect_error(
    drmTMB(
      bf(y ~ x + xdup, sigma ~ 1),
      family = gaussian(),
      data = dat
    ),
    "rank-deficient.*mu"
  )
})

test_that("REML collinear mu still aborts, now for every estimator (#1478)", {
  dat <- aliased_ls_data()
  expect_error(
    drmTMB(
      bf(y ~ x + xdup, sigma ~ 1),
      family = gaussian(),
      data = dat,
      REML = TRUE
    ),
    "rank-deficient"
  )
})

test_that("a full-rank sigma ~ x design still fits (#1478 neighbour)", {
  dat <- aliased_ls_data()
  fit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = dat
  )
  expect_s3_class(fit, "drmTMB")
  expect_true(is_converged(fit))
})

test_that("unused sd_mu and sd_sigma placeholders are not fixed-effect designs", {
  placeholder <- matrix(0, nrow = 1L, ncol = 1L)
  spec <- list(
    X = list(
      mu = cbind(`(Intercept)` = 1, x = c(0, 1, 0, 1)),
      sigma = cbind(`(Intercept)` = rep(1, 4L)),
      sd_mu = placeholder,
      sd_sigma = placeholder
    )
  )
  expect_true(drmTMB:::drm_validate_fixed_design_rank(spec))

  spec$X$sigma <- cbind(x = 1:4, xdup = 1:4)
  expect_error(
    drmTMB:::drm_validate_fixed_design_rank(spec),
    "rank-deficient.*sigma"
  )
  expect_false(drmTMB:::drm_is_unused_sd_placeholder(
    "sigma",
    matrix(0, nrow = 1L, ncol = 1L)
  ))
  expect_false(drmTMB:::drm_is_unused_sd_placeholder(
    "sd_mu",
    cbind(`(Intercept)` = 1)
  ))
})

test_that("1e-9 near-collinear mu still fits (#1478; abort is exact aliases only)", {
  set.seed(1)
  n <- 80L
  x <- stats::rnorm(n)
  dat <- data.frame(
    y = 0.3 + 0.5 * x + stats::rnorm(n, sd = 0.4),
    x = x,
    x2 = x + 1e-9 * stats::rnorm(n)
  )
  fit <- drmTMB(
    bf(y ~ x + x2, sigma ~ 1),
    family = gaussian(),
    data = dat
  )
  expect_s3_class(fit, "drmTMB")
})
