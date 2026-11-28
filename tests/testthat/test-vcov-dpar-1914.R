test_that("vcov(..., dpar) returns one fixed-effect block (#1914)", {
  set.seed(20261127)
  n <- 60L
  dat <- data.frame(
    x = stats::rnorm(n),
    g = factor(rep(1:6, each = 10)),
    y = stats::rnorm(n)
  )
  fit <- drmTMB(
    drm_formula(y ~ x + (1 | g), sigma ~ x),
    family = gaussian(),
    data = dat,
    control = drm_control(se = TRUE)
  )

  full <- vcov(fit)
  mu_block <- vcov(fit, dpar = "mu")
  mu_coef <- coef(fit, dpar = "mu")

  expect_length(mu_coef, 2L)
  expect_equal(dim(mu_block), c(2L, 2L))
  expect_equal(rownames(mu_block), paste0("mu:", names(mu_coef)))
  expect_equal(colnames(mu_block), rownames(mu_block))

  keep <- rownames(mu_block)
  expect_equal(mu_block, full[keep, keep, drop = FALSE])
})

test_that("vcov(..., dpar) matches sigma block on Gaussian mu and sigma slopes", {
  set.seed(20260525)
  dat <- data.frame(
    y = 0.3 + 0.6 * seq(-1, 1, length.out = 36) + stats::rnorm(36, sd = 0.7),
    x = seq(-1, 1, length.out = 36)
  )
  fit <- drmTMB(bf(y ~ x, sigma ~ x), data = dat, control = drm_control(se = TRUE))

  full <- vcov(fit)
  for (dpar in names(coef(fit))) {
    block <- vcov(fit, dpar = dpar)
    keep <- rownames(block)
    expect_equal(block, full[keep, keep, drop = FALSE])
  }
})