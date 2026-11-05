test_that("correlated Binomial q3 SD regression recovers all probit and cloglog targets", {
  links <- c("probit", "cloglog")
  for (link_index in seq_along(links)) {
    link <- links[[link_index]]
    set.seed(2026102810L + link_index)
    groups <- 128L
    repeats <- 40L
    id <- factor(rep(seq_len(groups), each = repeats))
    x <- stats::rnorm(length(id))
    z <- stats::rnorm(length(id))
    w_group <- as.numeric(scale(stats::rnorm(groups)))
    h_group <- as.numeric(scale(stats::rnorm(groups)))
    j_group <- as.numeric(scale(stats::rnorm(groups)))
    w <- rep(w_group, each = repeats)
    h <- rep(h_group, each = repeats)
    j <- rep(j_group, each = repeats)
    alpha <- list(
      c(log(0.65), 0.45),
      c(log(0.55), -0.45),
      c(log(0.50), 0.40)
    )
    tau0 <- exp(alpha[[1L]][[1L]] + alpha[[1L]][[2L]] * w_group)
    tau1 <- exp(alpha[[2L]][[1L]] + alpha[[2L]][[2L]] * h_group)
    tau2 <- exp(alpha[[3L]][[1L]] + alpha[[3L]][[2L]] * j_group)
    partial <- c(0.20, -0.20, 0.25)
    s21 <- sqrt(1 - partial[[1L]]^2)
    s31 <- sqrt(1 - partial[[2L]]^2)
    s32 <- sqrt(1 - partial[[3L]]^2)
    u <- matrix(stats::rnorm(3L * groups), nrow = 3L)
    b0 <- tau0 * u[1L, ]
    b1 <- tau1 * (partial[[1L]] * u[1L, ] + s21 * u[2L, ])
    b2 <- tau2 * (
      partial[[2L]] * u[1L, ] + s31 * partial[[3L]] * u[2L, ] +
        s31 * s32 * u[3L, ]
    )
    eta <- -0.10 + 0.20 * x - 0.15 * z + b0[as.integer(id)] +
      b1[as.integer(id)] * x + b2[as.integer(id)] * z
    probability <- if (link == "probit") {
      stats::pnorm(eta)
    } else {
      -expm1(-exp(eta))
    }
    dat <- data.frame(
      y = stats::rbinom(length(id), 1L, probability), x, z, w, h, j, id
    )
    keys <- c(
      'sd(id, dpar = "mu", coef = "(Intercept)")',
      'sd(id, dpar = "mu", coef = "x")',
      'sd(id, dpar = "mu", coef = "z")'
    )
    formula <- bf(
      y ~ x + z + (1 + x + z | id),
      sd(id, dpar = "mu", coef = "(Intercept)") ~ w,
      sd(id, dpar = "mu", coef = "x") ~ h,
      sd(id, dpar = "mu", coef = "z") ~ j
    )

    fit <- drmTMB(
      formula, family = stats::binomial(link = link), data = dat
    )

    expect_equal(fit$opt$convergence, 0L, info = link)
    expect_true(isTRUE(fit$sdr$pdHess), info = link)
    expect_length(fit$corpars$mu, 3L)
    expect_true(all(is.finite(fit$corpars$mu)), info = link)
    for (i in seq_along(keys)) {
      estimated <- coef(fit, keys[[i]])
      expect_true(all(is.finite(estimated)), info = paste(link, keys[[i]]))
      expect_lt(
        abs(unname(estimated[[2L]]) - alpha[[i]][[2L]]), 0.35
      )
      predicted <- predict(fit, dpar = keys[[i]])
      expect_setequal(names(predicted), levels(id))
      predictor <- list(w_group, h_group, j_group)[[i]]
      expected <- exp(estimated[[1L]] + estimated[[2L]] * predictor)
      expect_equal(
        unname(predicted[levels(id)]), unname(expected), tolerance = 1e-10,
        info = paste(link, keys[[i]])
      )
    }
    simulated <- simulate(
      fit, nsim = 1L, seed = 2026102820L + link_index
    )[[1L]]
    expect_length(simulated, nrow(dat))
    expect_true(all(simulated %in% 0:1), info = link)
  }
})
