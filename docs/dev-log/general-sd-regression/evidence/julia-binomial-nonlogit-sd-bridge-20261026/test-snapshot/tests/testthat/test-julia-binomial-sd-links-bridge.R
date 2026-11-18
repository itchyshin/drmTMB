test_that("Julia bridge recognizes the three Binomial links", {
  for (link in c("logit", "probit", "cloglog")) {
    expect_identical(
      drmTMB:::drm_julia_bridge_family_type(stats::binomial(link)),
      "binomial",
      info = link
    )
  }
})

test_that("Julia bridge admits matching ordinary routes and probit phylogenetic SD", {
  dat <- data.frame(
    y = c(0, 1, 1, 0, 1, 0),
    x = c(-1, 0, 1, -1, 0, 1),
    w = rep(c(-1, 1), each = 3L),
    id = factor(rep(c("a", "b"), each = 3L))
  )
  matching <- bf(y ~ x + (1 | id), sd(id) ~ w)
  wrong_group <- bf(y ~ x + (1 | id), sd(other) ~ w)
  structured <- bf(y ~ x + phylo(1 | id, tree = tree),
                   sd(id, level = "phylogenetic") ~ w)

  expect_true(drmTMB:::drm_julia_binomial_sd_link_route_admitted(
    matching, data = dat
  ))
  expect_false(drmTMB:::drm_julia_binomial_sd_link_route_admitted(
    wrong_group, data = dat
  ))
  expect_true(drmTMB:::drm_julia_binomial_sd_link_route_admitted(
    structured, data = dat, link = "probit"
  ))
  expect_false(drmTMB:::drm_julia_binomial_sd_link_route_admitted(
    structured, data = dat, link = "cloglog"
  ))
})

test_that("Julia bridge preserves probit and cloglog Binomial SD links", {
  skip_if_not(identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true"),
              "Julia bridge tests are opt-in")

  for (link in c("probit", "cloglog")) {
    set.seed(if (link == "probit") 202610241L else 202610242L)
    groups <- 144L
    repeats <- 25L
    id <- factor(rep(seq_len(groups), each = repeats))
    w_group <- seq(-1, 1, length.out = groups)
    w <- w_group[as.integer(id)]
    x <- stats::rnorm(length(id))
    true_sd <- exp(-0.8 + 0.45 * w_group)
    b <- stats::rnorm(groups, sd = true_sd)
    eta <- -0.1 + 0.35 * x + b[as.integer(id)]
    probability <- stats::binomial(link = link)$linkinv(eta)
    dat <- data.frame(y = stats::rbinom(length(id), 1L, probability),
                      x = x, w = w, id = id)
    form <- bf(y ~ x + (1 | id), sd(id) ~ w)
    target <- "sd(id)"
    fit_tmb <- drmTMB(form, family = stats::binomial(link), data = dat,
                      engine = "tmb", control = drm_control(se = FALSE))
    fit_julia <- drmTMB(form, family = stats::binomial(link), data = dat,
                        engine = "julia", control = drm_control())

    expect_true(is_converged(fit_tmb), info = link)
    expect_true(is_converged(fit_julia), info = link)
    beta_tmb <- coef(fit_tmb, dpar = target)
    beta_julia <- coef(fit_julia, dpar = target)
    expect_true(unname(beta_tmb[["w"]]) > 0, info = link)
    expect_true(unname(beta_julia[["w"]]) > 0, info = link)
    expect_true(abs(unname(beta_tmb[["w"]]) - 0.45) < 0.3, info = link)
    expect_true(abs(unname(beta_julia[["w"]]) - 0.45) < 0.3, info = link)
    expect_true(abs(unname(beta_tmb[["w"]]) - beta_julia[["w"]]) < 0.4,
                info = link)

    prediction_data <- data.frame(
      id = factor(levels(id)[1:3], levels = levels(id)),
      w = c(-1, 0, 1)
    )
    pred_tmb <- predict(fit_tmb, newdata = prediction_data, dpar = target)
    pred_julia <- predict(fit_julia, newdata = prediction_data, dpar = target)
    expect_true(all(diff(as.numeric(pred_tmb)) > 0), info = link)
    expect_true(all(diff(as.numeric(pred_julia)) > 0), info = link)
    expect_equal(as.numeric(pred_julia), as.numeric(pred_tmb), tolerance = 0.4)
  }
})
