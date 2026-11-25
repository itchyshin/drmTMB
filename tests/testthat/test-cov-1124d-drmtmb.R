# drmTMB() input guards that return before optimization.

tiny_gaussian <- function() {
  set.seed(1124)
  data.frame(y = stats::rnorm(12), x = stats::rnorm(12))
}

test_that("drmTMB rejects a bare formula and a non-data-frame", {
  dat <- tiny_gaussian()
  expect_error(
    drmTMB(y ~ x, data = dat),
    "drm_formula"
  )
  expect_error(
    drmTMB(bf(y ~ x), data = as.matrix(dat)),
    "must be a data frame"
  )
})

test_that("missing-response and imputation routes name the unsupported family", {
  dat <- data.frame(
    y1 = c(1, 2, NA),
    y2 = c(1, 2, 3),
    x = c(0, 1, 2)
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ 1, sigma2 = ~ 1, rho12 = ~ 1),
      family = biv_lognormal(),
      data = dat,
      missing = miss_control(response = "include")
    ),
    "not implemented for the"
  )

  proportion <- data.frame(y = c(0.2, 0.4, 0.6), x = c(1, NA, 3))
  expect_error(
    drmTMB(
      bf(y ~ x),
      family = zero_one_beta(),
      data = proportion,
      impute = list(x = x ~ 1)
    ),
    "impute"
  )
})

test_that("public start labels that do not belong to the model are refused", {
  dat <- tiny_gaussian()
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      data = dat,
      control = drm_control(
        se = FALSE,
        start = list("phylo_sd:mu" = 1)
      )
    ),
    "no phylogenetic"
  )

  dat$id <- gl(3, 4)
  expect_error(
    drmTMB(
      bf(y ~ (1 | id), sigma ~ 1),
      data = dat,
      control = drm_control(
        se = FALSE,
        start = list("sd:mu:(1 | id)" = -1)
      )
    ),
    "positive number"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 + x | id), sigma ~ 1),
      data = dat,
      control = drm_control(
        se = FALSE,
        start = list("cor:mu:cor((Intercept),x | id)" = 1.2)
      )
    ),
    "strictly between -1 and 1"
  )
})
