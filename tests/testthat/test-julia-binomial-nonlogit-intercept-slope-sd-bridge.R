test_that("non-logit Julia Binomial route pairs each independent coefficient with its SD", {
  dat <- data.frame(
    y = c(0, 1, 1, 0, 1, 0, 1, 0),
    x = c(-1, 0, 1, -1, 0, 1, -0.5, 0.5),
    w0 = rep(c(-1, 1), each = 4L),
    w1 = rep(c(1, -1), times = 4L),
    id = factor(rep(letters[1:2], each = 4L))
  )
  intercept_slope <- bf(
    y ~ x + (1 | id) + (0 + x | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w0,
    sd(id, dpar = "mu", coef = "x") ~ w1
  )
  missing_slope_sd <- bf(
    y ~ x + (1 | id) + (0 + x | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w0
  )
  wrong_group <- bf(
    y ~ x + (1 | id) + (0 + x | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w0,
    sd(other, dpar = "mu", coef = "x") ~ w1
  )

  admitted <- drm_julia_binomial_sd_link_route_admitted
  expect_true(admitted(intercept_slope, data = dat))
  expect_false(admitted(missing_slope_sd, data = dat))
  expect_false(admitted(wrong_group, data = dat))
})

test_that("probit and cloglog Julia Binomial bridge intercept-slope SD pairs", {
  skip_if_not(identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true"),
              "Julia bridge tests are opt-in")
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  for (link in c("probit", "cloglog")) {
    set.seed(if (link == "probit") 202610261L else 202610262L)
    groups <- 60L
    repeats <- 40L
    id <- factor(rep(seq_len(groups), each = repeats))
    w0_group <- rep(c(-1, 1), each = groups / 2L)
    w1_group <- rep(rep(c(-1, 1), each = groups / 4L), 2L)
    w0 <- w0_group[as.integer(id)]
    w1 <- w1_group[as.integer(id)]
    x <- stats::rnorm(length(id))
    alpha0 <- c(`(Intercept)` = -0.7, w0 = 0.35)
    alpha1 <- c(`(Intercept)` = -0.9, w1 = 0.45)
    b0 <- stats::rnorm(groups, sd = exp(alpha0[[1L]] + alpha0[[2L]] * w0_group))
    b1 <- stats::rnorm(groups, sd = exp(alpha1[[1L]] + alpha1[[2L]] * w1_group))
    eta <- 0.2 + 0.3 * x + b0[as.integer(id)] + x * b1[as.integer(id)]
    y <- stats::rbinom(
      length(id), 1L,
      stats::binomial(link = link)$linkinv(eta)
    )
    dat <- data.frame(y, x, w0, w1, id)
    formula <- bf(
      y ~ x + (1 | id) + (0 + x | id),
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
      formula, family = stats::binomial(link), data = dat, engine = "julia"
    )

    expect_true(is_converged(fit_tmb), info = link)
    expect_true(is_converged(fit_julia), info = link)
    beta0_tmb <- coef(fit_tmb, dpar = target0)
    beta0_julia <- coef(fit_julia, dpar = target0)
    beta1_tmb <- coef(fit_tmb, dpar = target1)
    beta1_julia <- coef(fit_julia, dpar = target1)
    expect_named(beta0_julia, names(alpha0), info = link)
    expect_named(beta1_julia, names(alpha1), info = link)
    expect_true(unname(beta0_tmb[["w0"]]) > 0, info = link)
    expect_true(unname(beta0_julia[["w0"]]) > 0, info = link)
    expect_true(unname(beta1_tmb[["w1"]]) > 0, info = link)
    expect_true(unname(beta1_julia[["w1"]]) > 0, info = link)
    expect_true(abs(unname(beta0_tmb[["w0"]] - alpha0[["w0"]])) < 0.5,
                info = link)
    expect_true(abs(unname(beta0_julia[["w0"]] - alpha0[["w0"]])) < 0.5,
                info = link)
    expect_true(abs(unname(beta1_tmb[["w1"]] - alpha1[["w1"]])) < 0.5,
                info = link)
    expect_true(abs(unname(beta1_julia[["w1"]] - alpha1[["w1"]])) < 0.5,
                info = link)

    pred_data <- data.frame(
      id = factor(levels(id)[1:4], levels = levels(id)),
      w0 = w0_group[1:4], w1 = w1_group[1:4]
    )
    pred0_tmb <- predict(fit_tmb, newdata = pred_data, dpar = target0)
    pred0_julia <- predict(fit_julia, newdata = pred_data, dpar = target0)
    pred1_tmb <- predict(fit_tmb, newdata = pred_data, dpar = target1)
    pred1_julia <- predict(fit_julia, newdata = pred_data, dpar = target1)
    expect_equal(as.numeric(pred0_julia), as.numeric(pred0_tmb), tolerance = 0.6,
                 info = link)
    expect_equal(as.numeric(pred1_julia), as.numeric(pred1_tmb), tolerance = 0.6,
                 info = link)

    profile_parms <- profile_targets(fit_julia)$parm
    intercept_profile <- paste0("fixef:", target0, ":w0")
    slope_profile <- paste0("fixef:", target1, ":w1")
    expect_true(intercept_profile %in% profile_parms, info = link)
    expect_true(slope_profile %in% profile_parms, info = link)
    if (identical(link, "probit")) {
      bootstrap_ci <- confint(
        fit_julia,
        parm = slope_profile,
        method = "bootstrap",
        R = 2L,
        seed = 202610263L,
        level = 0.8
      )
      expect_identical(bootstrap_ci$parm, slope_profile)
      expect_identical(bootstrap_ci$method, "bootstrap")
      expect_identical(bootstrap_ci$conf.status, "bootstrap")
      expect_equal(bootstrap_ci$bootstrap.n + bootstrap_ci$bootstrap.failed, 2L)
      expect_gte(bootstrap_ci$bootstrap.n, 1L)
      expect_gte(bootstrap_ci$bootstrap.failed, 0L)
      expect_true(is.finite(bootstrap_ci$lower))
      expect_true(is.finite(bootstrap_ci$upper))
    }
  }
})
