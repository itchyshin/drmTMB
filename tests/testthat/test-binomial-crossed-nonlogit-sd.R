test_that("Binomial crossed intercept SD regression supports probit and cloglog", {
  skip_on_cran()

  links <- c("probit", "cloglog")
  for (link_index in seq_along(links)) {
    link <- links[[link_index]]
    set.seed(2026102720L + link_index)
    ng <- 40L
    nh <- 40L
    repeats <- 4L
    levels_g <- paste0("g", seq_len(ng))
    levels_h <- paste0("h", seq_len(nh))
    z_g <- seq(-1, 1, length.out = ng)
    z_h <- seq(-1, 1, length.out = nh)
    alpha_g <- c(`(Intercept)` = log(0.45), w = 0.30)
    alpha_h <- c(`(Intercept)` = log(0.50), v = -0.25)
    b_g <- stats::rnorm(ng, sd = exp(alpha_g[[1L]] + alpha_g[[2L]] * z_g))
    b_h <- stats::rnorm(nh, sd = exp(alpha_h[[1L]] + alpha_h[[2L]] * z_h))
    dat <- expand.grid(
      id_g = levels_g,
      id_h = levels_h,
      rep = seq_len(repeats)
    )
    dat$id_g <- factor(dat$id_g, levels = levels_g)
    dat$id_h <- factor(dat$id_h, levels = levels_h)
    dat$x <- stats::rnorm(nrow(dat))
    dat$w <- z_g[as.integer(dat$id_g)]
    dat$v <- z_h[as.integer(dat$id_h)]
    eta <- -0.2 + 0.4 * dat$x +
      b_g[as.integer(dat$id_g)] + b_h[as.integer(dat$id_h)]
    probability <- if (link == "probit") {
      stats::pnorm(eta)
    } else {
      -expm1(-exp(eta))
    }
    dat$y <- stats::rbinom(nrow(dat), 1L, probability)

    fit <- drmTMB(
      bf(
        y ~ x + (1 | id_g) + (1 | id_h),
        sd(id_g) ~ w,
        sd(id_h) ~ v
      ),
      family = stats::binomial(link = link),
      data = dat,
      control = drm_control(se = FALSE)
    )
    coef_g <- coef(fit, dpar = "sd(id_g)")
    coef_h <- coef(fit, dpar = "sd(id_h)")

    expect_true(is_converged(fit), info = link)
    expect_gt(coef_g[["w"]], 0)
    expect_lt(abs(coef_g[["w"]] - alpha_g[["w"]]), 0.50)
    expect_lt(coef_h[["v"]], 0)
    expect_lt(abs(coef_h[["v"]] - alpha_h[["v"]]), 0.50)
    expect_setequal(names(predict(fit, dpar = "sd(id_g)")), levels_g)
    expect_setequal(names(predict(fit, dpar = "sd(id_h)")), levels_h)
    simulated <- simulate(fit, nsim = 1L, seed = 2026102722L + link_index)[[1L]]
    expect_length(simulated, nrow(dat))
    expect_true(all(simulated %in% 0:1), info = link)
  }
})
