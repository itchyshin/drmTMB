test_that("Julia Binomial bridge admits tested links for correlated q3 SD blocks", {
  dat <- data.frame(
    y = c(0, 1, 1, 0, 1, 0, 1, 0),
    x1 = c(-1, 0, 1, -1, 0, 1, -0.5, 0.5),
    x2 = c(0.5, -0.5, 1, -1, 0.5, -0.5, 1, -1),
    w0 = rep(c(-1, 1), each = 4L),
    w1 = rep(c(1, -1), times = 4L),
    w2 = rep(c(-1, -1, 1, 1), times = 2L),
    id = factor(rep(letters[1:2], each = 4L))
  )
  correlated <- bf(
    y ~ x1 + x2 + (1 + x1 + x2 | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w0,
    sd(id, dpar = "mu", coef = "x1") ~ w1,
    sd(id, dpar = "mu", coef = "x2") ~ w2
  )
  missing_member <- bf(
    y ~ x1 + x2 + (1 + x1 + x2 | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w0,
    sd(id, dpar = "mu", coef = "x1") ~ w1
  )

  admitted <- drm_julia_binomial_sd_link_route_admitted
  expect_true(admitted(correlated, data = dat, link = "logit"))
  expect_true(admitted(correlated, data = dat, link = "probit"))
  expect_true(admitted(correlated, data = dat, link = "cloglog"))
  expect_no_error(
    drm_julia_refuse_binomial_nonlogit_sd(
      correlated, stats::binomial(link = "logit")
    )
  )
  expect_no_error(
    drm_julia_refuse_binomial_nonlogit_sd(
      correlated, stats::binomial(link = "cloglog")
    )
  )
  expect_false(admitted(missing_member, data = dat, link = "probit"))

  recov_labels <- c(
    "id:atanh_partial_rho_21", "id:atanh_partial_rho_31",
    "id:atanh_partial_rho_32_given_1"
  )
  expect_identical(
    drm_julia_ordinary_binomial_recov_label(correlated, "binomial"),
    recov_labels
  )
  marshalled <- drm_julia_formula_spec(correlated)
  expect_type(marshalled, "character")
  expect_null(names(marshalled))
  expect_length(marshalled, 4L)
  expect_identical(marshalled[[2L]], "sd(id, coef(intercept)) ~ w0")
  expect_identical(marshalled[[3L]], "sd(id, coef(x1)) ~ w1")
  expect_identical(marshalled[[4L]], "sd(id, coef(x2)) ~ w2")
  payload_labels <- drm_julia_bridge_payload_coef_labels(
    correlated, dat, environment(), family_type = "binomial"
  )
  expect_identical(payload_labels$recov, recov_labels)
  partial <- c(0.35, -0.25, 0.4)
  recov <- stats::setNames(atanh(partial), paste0("recov_", recov_labels))
  translated <- drm_julia_structured_parameters(recov, correlated)
  expected_rho23 <- partial[[1L]] * partial[[2L]] +
    sqrt(1 - partial[[1L]]^2) * sqrt(1 - partial[[2L]]^2) * partial[[3L]]
  expect_named(translated$corpars$mu, c(
    "cor((Intercept),x1 | id)", "cor((Intercept),x2 | id)",
    "cor(x1,x2 | id)"
  ))
  expect_equal(unname(translated$corpars$mu),
               c(partial[[1L]], partial[[2L]], expected_rho23))

  sim_correlations <- c(
    "cor((Intercept),x1 | id)" = partial[[1L]],
    "cor((Intercept),x2 | id)" = partial[[2L]],
    "cor(x1,x2 | id)" = expected_rho23
  )
  component <- drm_julia_binomial_correlated_sd_component(
    list(formula = correlated, data = dat,
         corpars = list(mu = sim_correlations)),
    Filter(is_random_bar_call,
           flatten_plus_terms(correlated$entries[[1L]]$rhs)),
    lapply(correlated$entries[2:4], function(entry) {
      parse_sd_lhs(entry$lhs)
    })
  )
  expect_named(component$members, c("(Intercept)", "x1", "x2"))
  expect_equal(component$correlation, matrix(
    c(1, partial[[1L]], partial[[2L]],
      partial[[1L]], 1, expected_rho23,
      partial[[2L]], expected_rho23, 1),
    nrow = 3L,
    dimnames = list(c("(Intercept)", "x1", "x2"),
                    c("(Intercept)", "x1", "x2"))
  ))
  expect_equal(
    drm_julia_align_group_sd(stats::setNames(c(0.5, 0.7), c("b", "a")),
                             c("a", "b"), "sd(id, coef(x1))", "id"),
    c(0.7, 0.5)
  )
  set.seed(202610275L)
  sampled <- drm_julia_draw_correlated_random_effects(
    component$correlation, matrix(1, nrow = 3L, ncol = 20000L)
  )
  expect_lt(max(abs(cor(t(sampled)) - component$correlation)), 0.02)
})

test_that("Julia bridge fits and simulates correlated q3 probit SD regression", {
  skip_if_not(identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true"),
              "Julia bridge tests are opt-in")
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  groups <- 80L
  repeats <- 12L
  id <- factor(rep(seq_len(groups), each = repeats))
  w0_group <- rep(c(-1, 1), each = groups / 2L)
  w1_group <- rep(c(-1, -1, 1, 1), length.out = groups)
  w2_group <- rep(c(-1, 1, 1, -1), length.out = groups)
  w0 <- w0_group[as.integer(id)]
  w1 <- w1_group[as.integer(id)]
  w2 <- w2_group[as.integer(id)]
  x1 <- rep(seq(-1.2, 1.2, length.out = repeats), times = groups)
  x2 <- rep(c(-1, 1), length.out = length(id))
  alpha_probit <- list(
    c("(Intercept)" = -0.7, w0 = 0.45),
    c("(Intercept)" = -0.65, w1 = 0.4),
    c("(Intercept)" = -0.75, w2 = 0.5)
  )
  partial <- c(0.35, -0.25, 0.4)
  chol_r <- rbind(
    c(1, 0, 0),
    c(partial[[1L]], sqrt(1 - partial[[1L]]^2), 0),
    c(partial[[2L]], sqrt(1 - partial[[2L]]^2) * partial[[3L]],
      sqrt(1 - partial[[2L]]^2) * sqrt(1 - partial[[3L]]^2))
  )
  formula <- bf(
    y ~ x1 + x2 + (1 + x1 + x2 | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w0,
    sd(id, dpar = "mu", coef = "x1") ~ w1,
    sd(id, dpar = "mu", coef = "x2") ~ w2
  )
  targets <- c(
    'sd(id, dpar = "mu", coef = "(Intercept)")',
    'sd(id, dpar = "mu", coef = "x1")',
    'sd(id, dpar = "mu", coef = "x2")'
  )
  prediction_data <- data.frame(
    id = factor(levels(id), levels = levels(id)),
    w0 = w0_group, w1 = w1_group, w2 = w2_group
  )
  for (link in "probit") {
    alpha <- alpha_probit
    tau <- rbind(
      exp(alpha[[1L]][[1L]] + alpha[[1L]][[2L]] * w0_group),
      exp(alpha[[2L]][[1L]] + alpha[[2L]][[2L]] * w1_group),
      exp(alpha[[3L]][[1L]] + alpha[[3L]][[2L]] * w2_group)
    )
    set.seed(if (identical(link, "probit")) 202610273L else 202610278L)
    latent <- chol_r %*% matrix(stats::rnorm(3L * groups), nrow = 3L)
    random <- tau * latent
    eta <- -0.1 + 0.2 * x1 - 0.15 * x2 +
      random[1L, as.integer(id)] +
      random[2L, as.integer(id)] * x1 +
      random[3L, as.integer(id)] * x2
    probability <- if (identical(link, "probit")) {
      stats::pnorm(eta)
    } else {
      stats::plogis(eta)
    }
    y <- stats::rbinom(length(id), size = 1L, prob = probability)
    dat <- data.frame(y, x1, x2, w0, w1, w2, id)
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
    expect_length(fit_julia$corpars$mu, 3L)
    expect_named(fit_julia$corpars$mu, names(fit_tmb$corpars$mu), info = link)
    for (i in seq_along(targets)) {
      expect_named(coef(fit_julia, targets[[i]]), names(alpha[[i]]), info = link)
      expect_equal(
        coef(fit_julia, targets[[i]]), coef(fit_tmb, targets[[i]]),
        tolerance = 0.5, info = link
      )
    }
    for (target in targets) {
      expect_equal(
        predict(fit_julia, dpar = target, newdata = prediction_data),
        predict(fit_tmb, dpar = target, newdata = prediction_data),
        tolerance = 0.5,
        info = paste(link, target)
      )
    }
    simulated <- simulate(
      fit_julia, nsim = 1L,
      seed = if (identical(link, "probit")) 202610274L else 202610279L
    )
    expect_true(all(unlist(simulated) %in% 0:1), info = link)
  }
})
