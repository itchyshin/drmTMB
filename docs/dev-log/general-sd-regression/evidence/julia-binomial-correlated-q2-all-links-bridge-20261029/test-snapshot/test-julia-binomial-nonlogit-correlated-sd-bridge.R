test_that("non-logit Julia Binomial route admits a matched correlated q2 SD block", {
  dat <- data.frame(
    y = c(0, 1, 1, 0, 1, 0, 1, 0),
    x = c(-1, 0, 1, -1, 0, 1, -0.5, 0.5),
    w0 = rep(c(-1, 1), each = 4L),
    w1 = rep(c(1, -1), times = 4L),
    id = factor(rep(letters[1:2], each = 4L)),
    site = factor(rep(LETTERS[1:2], times = 4L))
  )
  correlated <- bf(
    y ~ x + (1 + x | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w0,
    sd(id, dpar = "mu", coef = "x") ~ w1
  )
  missing_slope_sd <- bf(
    y ~ x + (1 + x | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w0
  )
  wrong_group <- bf(
    y ~ x + (1 + x | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w0,
    sd(site, dpar = "mu", coef = "x") ~ w1
  )
  ambiguous_targets <- bf(
    y ~ x + (1 + x | id),
    sd(id, dpar = "mu") ~ w0
  )
  extra_block <- bf(
    y ~ x + (1 + x | id) + (1 | site),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w0,
    sd(id, dpar = "mu", coef = "x") ~ w1
  )
  random_sd_predictor <- bf(
    y ~ x + (1 + x | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w0 + (1 | site),
    sd(id, dpar = "mu", coef = "x") ~ w1
  )

  admitted <- drm_julia_binomial_sd_link_route_admitted
  expect_true(admitted(correlated, data = dat, link = "probit"))
  expect_true(admitted(correlated, data = dat, link = "cloglog"))
  expect_false(admitted(missing_slope_sd, data = dat, link = "probit"))
  expect_false(admitted(wrong_group, data = dat, link = "probit"))
  expect_false(admitted(ambiguous_targets, data = dat, link = "probit"))
  expect_false(admitted(extra_block, data = dat, link = "probit"))
  expect_false(admitted(random_sd_predictor, data = dat, link = "probit"))
})

test_that("Julia bridge fits correlated q2 SD regression for all Binomial links", {
  skip_if_not(identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true"),
              "Julia bridge tests are opt-in")
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  for (link in c("logit", "probit", "cloglog")) {
    set.seed(if (link == "probit") 202610271L else 202610272L)
    groups <- 64L
    repeats <- 18L
    id <- factor(rep(seq_len(groups), each = repeats))
    z0_group <- rep(c(-1, 1), each = groups / 2L)
    z1_group <- rep(c(0, 1, 1, 0), each = groups / 4L)
    w0 <- z0_group[as.integer(id)]
    w1 <- z1_group[as.integer(id)]
    x <- rep(seq(-1.2, 1.2, length.out = repeats), times = groups)
    alpha0 <- c("(Intercept)" = -0.65, w0 = 0.55)
    alpha1 <- c("(Intercept)" = -0.75, w1 = 0.6)
    rho <- 0.4
    tau0 <- exp(alpha0[[1L]] + alpha0[[2L]] * z0_group)
    tau1 <- exp(alpha1[[1L]] + alpha1[[2L]] * z1_group)
    z <- matrix(stats::rnorm(2L * groups), nrow = 2L)
    b0 <- tau0 * z[1L, ]
    b1 <- tau1 * (rho * z[1L, ] + sqrt(1 - rho^2) * z[2L, ])
    eta <- -0.1 + 0.25 * x + b0[as.integer(id)] +
      x * b1[as.integer(id)]
    probability <- if (identical(link, "probit")) {
      stats::pnorm(eta)
    } else {
      -expm1(-exp(eta))
    }
    y <- stats::rbinom(length(id), size = 1L, prob = probability)
    dat <- data.frame(y, x, w0, w1, id)
    formula <- bf(
      y ~ x + (1 + x | id),
      sd(id, dpar = "mu", coef = "(Intercept)") ~ w0,
      sd(id, dpar = "mu", coef = "x") ~ w1
    )
    target0 <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
    target1 <- 'sd(id, dpar = "mu", coef = "x")'

    fit_tmb <- drmTMB(
      formula, family = stats::binomial(link), data = dat,
      engine = "tmb", control = drm_control(se = FALSE)
    )
    fit_julia <- drmTMB(
      formula, family = stats::binomial(link), data = dat,
      engine = "julia"
    )

    expect_true(is_converged(fit_tmb), info = link)
    expect_true(is_converged(fit_julia), info = link)
    expect_named(coef(fit_julia, target0), names(alpha0), info = link)
    expect_named(coef(fit_julia, target1), names(alpha1), info = link)
    expect_named(fit_julia$corpars$mu, names(fit_tmb$corpars$mu), info = link)
    expect_true(unname(coef(fit_julia, target0)[["w0"]]) > 0, info = link)
    expect_true(unname(coef(fit_julia, target1)[["w1"]]) > 0, info = link)
    expect_true(
      abs(unname(coef(fit_julia, target0)[["w0"]]) - alpha0[["w0"]]) < 0.8,
      info = paste(link, "intercept SD-slope recovery")
    )
    expect_true(
      abs(unname(coef(fit_julia, target1)[["w1"]]) - alpha1[["w1"]]) < 0.8,
      info = paste(link, "random-slope SD-slope recovery")
    )
    expect_equal(coef(fit_julia, target0), coef(fit_tmb, target0),
                 tolerance = 0.5, info = link)
    expect_equal(coef(fit_julia, target1), coef(fit_tmb, target1),
                 tolerance = 0.5, info = link)
    expect_equal(unname(fit_julia$corpars$mu), unname(fit_tmb$corpars$mu),
                 tolerance = 0.3, info = link)
    expect_true(
      abs(unname(fit_julia$corpars$mu) - rho) < 0.4,
      info = paste(link, "correlation recovery")
    )

    prediction_data <- data.frame(
      id = factor(levels(id), levels = levels(id)),
      w0 = z0_group, w1 = z1_group
    )
    for (target in c(target0, target1)) {
      expect_equal(
        predict(fit_julia, dpar = target, newdata = prediction_data),
        predict(fit_tmb, dpar = target, newdata = prediction_data),
        tolerance = 0.5,
        info = paste(link, target)
      )
    }
  }
})

