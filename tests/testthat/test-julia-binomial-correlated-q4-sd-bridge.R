binomial_correlated_sd_bridge_formula <- function() {
  bf(
    y ~ x1 + x2 + x3 + (1 + x1 + x2 + x3 | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w0,
    sd(id, dpar = "mu", coef = "x1") ~ w1,
    sd(id, dpar = "mu", coef = "x2") ~ w2,
    sd(id, dpar = "mu", coef = "x3") ~ w3
  )
}

binomial_correlated_sd_bridge_cholesky <- function(partial) {
  q <- 4L
  stopifnot(length(partial) == q * (q - 1L) / 2L)
  L <- matrix(0, q, q)
  position <- 0L
  for (i in seq_len(q)) {
    row_scale <- 1
    for (j in seq_len(i - 1L)) {
      position <- position + 1L
      L[i, j] <- row_scale * partial[[position]]
      row_scale <- row_scale * sqrt(1 - partial[[position]]^2)
    }
    L[i, i] <- row_scale
  }
  L
}

binomial_correlated_sd_bridge_fixture <- function() {
  data.frame(
    y = c(0, 1, 1, 0, 1, 0, 1, 0),
    x1 = c(-1, 0, 1, -1, 0, 1, -0.5, 0.5),
    x2 = c(0.5, -0.5, 1, -1, 0.5, -0.5, 1, -1),
    x3 = c(1, -1, 0.5, -0.5, -1, 1, -0.5, 0.5),
    w0 = rep(c(-1, 1), each = 4L),
    w1 = rep(c(1, -1), times = 4L),
    w2 = rep(c(-1, -1, 1, 1), times = 2L),
    w3 = rep(c(-1, 1, 1, -1), times = 2L),
    id = factor(rep(letters[1:2], each = 4L))
  )
}

test_that("Julia Binomial bridge admits correlated q4 SD blocks and roundtrips outputs", {
  dat <- binomial_correlated_sd_bridge_fixture()
  formula <- binomial_correlated_sd_bridge_formula()
  missing_member <- bf(
    y ~ x1 + x2 + x3 + (1 + x1 + x2 + x3 | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w0,
    sd(id, dpar = "mu", coef = "x1") ~ w1,
    sd(id, dpar = "mu", coef = "x2") ~ w2
  )
  mis_targeted <- bf(
    y ~ x1 + x2 + x3 + (1 + x1 + x2 + x3 | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w0,
    sd(id, dpar = "mu", coef = "x1") ~ w1,
    sd(id, dpar = "mu", coef = "x2") ~ w2,
    sd(id, dpar = "mu", coef = "not_a_member") ~ w3
  )
  admitted <- drm_julia_binomial_sd_link_route_admitted
  for (link in c("logit", "probit", "cloglog")) {
    expect_true(admitted(formula, data = dat, link = link), info = link)
  }
  expect_false(admitted(missing_member, data = dat, link = "logit"))
  expect_false(admitted(mis_targeted, data = dat, link = "logit"))
  expect_no_error(drm_julia_refuse_binomial_nonlogit_sd(
    formula, stats::binomial(link = "probit")
  ))
  expect_no_error(drm_julia_refuse_binomial_nonlogit_sd(
    formula, stats::binomial(link = "cloglog")
  ))

  recov_labels <- c(
    "id:atanh_partial_rho_21", "id:atanh_partial_rho_31",
    "id:atanh_partial_rho_32_given_1", "id:atanh_partial_rho_41",
    "id:atanh_partial_rho_42_given_1", "id:atanh_partial_rho_43_given_1_2"
  )
  expect_identical(
    drm_julia_ordinary_binomial_recov_label(formula, "binomial"),
    recov_labels
  )
  marshalled <- drm_julia_formula_spec(formula)
  expect_type(marshalled, "character")
  expect_null(names(marshalled))
  expect_length(marshalled, 5L)
  for (j in seq_len(4L)) {
    expect_identical(
      marshalled[[j + 1L]],
      paste0("sd(id, coef(", c("intercept", "x1", "x2", "x3")[[j]],
             ")) ~ w", j - 1L)
    )
  }
  payload_labels <- drm_julia_bridge_payload_coef_labels(
    formula, dat, environment(), family_type = "binomial"
  )
  expect_identical(payload_labels$recov, recov_labels)

  partial <- c(0.5, -0.45, 0.42, 0.4, -0.35, 0.45)
  recov <- stats::setNames(atanh(partial), paste0("recov_", recov_labels))
  translated <- drm_julia_structured_parameters(recov, formula)
  marginal <- tcrossprod(binomial_correlated_sd_bridge_cholesky(partial))
  pairs <- utils::combn(seq_len(4L), 2L)
  expected <- vapply(seq_len(ncol(pairs)), function(j) {
    marginal[pairs[1L, j], pairs[2L, j]]
  }, numeric(1L))
  expected_names <- c(
    "cor((Intercept),x1 | id)", "cor((Intercept),x2 | id)",
    "cor((Intercept),x3 | id)", "cor(x1,x2 | id)",
    "cor(x1,x3 | id)", "cor(x2,x3 | id)"
  )
  expect_named(translated$corpars$mu, expected_names)
  expect_equal(unname(translated$corpars$mu), expected)

  component <- drm_julia_binomial_correlated_sd_component(
    list(formula = formula, data = dat,
         corpars = list(mu = translated$corpars$mu)),
    Filter(is_random_bar_call,
           flatten_plus_terms(formula$entries[[1L]]$rhs)),
    lapply(formula$entries[2:5], function(entry) parse_sd_lhs(entry$lhs))
  )
  coefficients <- c("(Intercept)", "x1", "x2", "x3")
  expect_named(component$members, coefficients)
  expect_equal(unname(component$correlation), unname(marginal),
               tolerance = 1e-12)
  set.seed(2026102704L)
  sampled <- drm_julia_draw_correlated_random_effects(
    component$correlation, matrix(1, nrow = 4L, ncol = 20000L)
  )
  expect_lt(max(abs(cor(t(sampled)) - component$correlation)), 0.02)
})

test_that("Julia bridge fits and simulates correlated q4 SD regression for Bernoulli links", {
  skip_if_not(identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true"),
              "Julia bridge tests are opt-in")
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  groups <- 256L
  repeats <- 32L
  id <- factor(rep(seq_len(groups), each = repeats))
  x1 <- stats::rnorm(length(id))
  x2 <- stats::rnorm(length(id))
  x3 <- stats::rnorm(length(id))
  predictors <- lapply(seq_len(4L), function(j) {
    as.numeric(scale(stats::rnorm(groups)))
  })
  names(predictors) <- paste0("w", 0:3)
  alpha <- list(
    c(log(0.65), 0.60), c(log(0.55), -0.55),
    c(log(0.50), 0.50), c(log(0.45), -0.50)
  )
  tau <- vapply(seq_len(4L), function(j) {
    exp(alpha[[j]][[1L]] + alpha[[j]][[2L]] * predictors[[j]])
  }, numeric(groups))
  partial <- c(0.45, -0.42, 0.46, 0.40, -0.44, 0.41)
  L <- binomial_correlated_sd_bridge_cholesky(partial)
  latent <- matrix(stats::rnorm(4L * groups), nrow = 4L)
  random <- vapply(seq_len(groups), function(g) {
    diag(tau[g, ]) %*% L %*% latent[, g]
  }, numeric(4L))
  group_index <- as.integer(id)
  eta <- -0.1 + 0.20 * x1 - 0.15 * x2 + 0.12 * x3 +
    random[1L, group_index] + random[2L, group_index] * x1 +
    random[3L, group_index] * x2 + random[4L, group_index] * x3
  dat <- data.frame(
    x1, x2, x3, id,
    w0 = rep(predictors$w0, each = repeats),
    w1 = rep(predictors$w1, each = repeats),
    w2 = rep(predictors$w2, each = repeats),
    w3 = rep(predictors$w3, each = repeats)
  )
  formula <- binomial_correlated_sd_bridge_formula()
  expected_correlation_names <- c(
    "cor((Intercept),x1 | id)", "cor((Intercept),x2 | id)",
    "cor((Intercept),x3 | id)", "cor(x1,x2 | id)",
    "cor(x1,x3 | id)", "cor(x2,x3 | id)"
  )
  expected_pairs <- utils::combn(seq_len(4L), 2L)
  expected_marginal <- vapply(seq_len(ncol(expected_pairs)), function(j) {
    tcrossprod(L)[expected_pairs[1L, j], expected_pairs[2L, j]]
  }, numeric(1L))
  prediction_data <- data.frame(
    id = factor(levels(id), levels = levels(id)),
    w0 = predictors$w0, w1 = predictors$w1,
    w2 = predictors$w2, w3 = predictors$w3
  )
  targets <- c(
    'sd(id, dpar = "mu", coef = "(Intercept)")',
    'sd(id, dpar = "mu", coef = "x1")',
    'sd(id, dpar = "mu", coef = "x2")',
    'sd(id, dpar = "mu", coef = "x3")'
  )
  for (link in c("logit", "probit", "cloglog")) {
    probability <- switch(
      link,
      logit = stats::plogis(eta),
      probit = stats::pnorm(eta),
      cloglog = -expm1(-exp(eta))
    )
    set.seed(match(link, c("logit", "probit", "cloglog")) + 2026102705L)
    dat$y <- stats::rbinom(length(id), 1L, probability)
    fit <- drmTMB(
      formula, family = stats::binomial(link = link), data = dat,
      engine = "julia",
      control = drm_control(optimizer = list(g_tol = 1e-5))
    )

    expect_true(is_converged(fit), info = link)
    expect_length(fit$corpars$mu, 6L)
    expect_identical(names(fit$corpars$mu), expected_correlation_names)
    expect_true(max(abs(unname(fit$corpars$mu) - expected_marginal)) < 0.45,
                info = paste(link, "marginal correlation recovery"))
    first_column <- unname(fit$corpars$mu[1:3])
    expected_first_column <- partial[c(1L, 2L, 4L)]
    expect_true(all(sign(first_column) == sign(expected_first_column)),
                info = paste(link, "intercept correlations"))
    expect_true(max(abs(first_column - expected_first_column)) < 0.35,
                info = paste(link, "intercept correlation recovery"))
    for (j in seq_along(targets)) {
      expect_identical(
        names(coef(fit, targets[[j]])),
        c("(Intercept)", paste0("w", j - 1L)),
        info = link
      )
      expect_true(abs(coef(fit, targets[[j]])[[2L]] - alpha[[j]][[2L]]) < 0.45,
                  info = paste(link, targets[[j]]))
      predicted_sd <- predict(fit, dpar = targets[[j]], newdata = prediction_data)
      expect_length(predicted_sd, groups)
      expect_true(all(is.finite(predicted_sd) & predicted_sd > 0))
    }
    simulation <- simulate(
      fit, nsim = 1L,
      seed = match(link, c("logit", "probit", "cloglog")) + 2026102706L
    )
    expect_true(all(unlist(simulation) %in% 0:1), info = link)
  }
})
