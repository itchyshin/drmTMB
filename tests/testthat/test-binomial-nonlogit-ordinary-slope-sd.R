test_that("probit and cloglog ordinary slopes support SD regression", {
  skip_on_cran()

  for (link in c("probit", "cloglog")) {
    set.seed(if (link == "probit") 20261036L else 20261037L)
    groups <- 100L
    repeats <- 30L
    id <- factor(rep(seq_len(groups), each = repeats))
    z_group <- rep(c(-1, 1), each = groups / 2L)
    z <- z_group[as.integer(id)]
    x <- rep(seq(-1.5, 1.5, length.out = repeats), times = groups)
    alpha <- c(`(Intercept)` = -0.65, z = 0.5)
    slope_sd <- exp(alpha[[1L]] + alpha[[2L]] * z_group)
    b <- stats::rnorm(groups, sd = slope_sd)
    eta <- -0.1 + 0.3 * x + x * b[as.integer(id)]
    probability <- if (link == "probit") {
      stats::pnorm(eta)
    } else {
      -expm1(-exp(eta))
    }
    y <- stats::rbinom(length(eta), size = 1L, prob = probability)
    dat <- data.frame(y, x, z, id)

    fit <- drmTMB(
      bf(y ~ x + (0 + x | id), sd(id, coef = "x") ~ z),
      family = stats::binomial(link = link),
      data = dat,
      control = drm_control(se = FALSE)
    )
    sd_coef <- coef(fit, dpar = 'sd(id, coef = "x")')
    sd_hat <- predict(fit, dpar = 'sd(id, coef = "x")')
    sim <- simulate(fit, nsim = 1L, seed = 20261038L)

    expect_true(is_converged(fit), info = link)
    expect_equal(fit$family$link, link)
    expect_gt(sd_coef[["z"]], 0)
    expect_lt(abs(sd_coef[["z"]] - alpha[["z"]]), 0.6)
    expect_equal(
      unname(sd_hat),
      as.vector(exp(stats::model.matrix(~z, data.frame(z = z_group)) %*% sd_coef)),
      tolerance = 1e-8
    )
    expect_equal(nrow(sim), nrow(dat))
    expect_true(all(sim[[1L]] %in% c(0, 1)))
  }
})
