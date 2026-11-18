poisson_correlated_q2_sd_fixture <- function(groups = 160L, repeats = 32L,
                                              seed = 20261027L) {
  set.seed(seed)
  id <- factor(rep(seq_len(groups), each = repeats))
  x <- rep(seq(-1, 1, length.out = repeats), times = groups)
  w_group <- seq(-1, 1, length.out = groups)
  v_group <- sample(rep(c(-1, 1), length.out = groups))
  w <- rep(w_group, each = repeats)
  v <- rep(v_group, each = repeats)
  rho <- 0.4
  z0 <- stats::rnorm(groups)
  z1 <- stats::rnorm(groups)
  tau0 <- exp(-0.45 + 0.4 * w_group)
  tau1 <- exp(-0.85 - 0.35 * v_group)
  b0 <- tau0 * z0
  b1 <- tau1 * (rho * z0 + sqrt(1 - rho^2) * z1)
  eta <- -0.2 + 0.55 * x + b0[as.integer(id)] + b1[as.integer(id)] * x
  data <- data.frame(
    count = stats::rpois(length(id), exp(eta)), x, w, v, id
  )
  list(data = data, w_group = w_group, v_group = v_group,
       truth = c(intercept_sd_slope = 0.4, random_slope_sd_slope = -0.35,
                 rho = rho))
}

poisson_correlated_q2_sd_gh_loglik <- function(
  data, beta_mu, sd_intercept, sd_slope, rho, order = 20L
) {
  off_diagonal <- sqrt(seq_len(order - 1L) / 2)
  jacobi <- diag(0, nrow = order)
  jacobi[cbind(seq_len(order - 1L), seq_len(order - 1L) + 1L)] <- off_diagonal
  jacobi[cbind(seq_len(order - 1L) + 1L, seq_len(order - 1L))] <- off_diagonal
  decomposition <- eigen(jacobi, symmetric = TRUE)
  nodes <- sqrt(2) * decomposition$values
  log_weights <- log(decomposition$vectors[1L, ]^2)
  levels <- levels(data$id)
  group_loglik <- vapply(seq_along(levels), function(group) {
    rows <- which(as.integer(data$id) == group)
    node_loglik <- numeric(order * order)
    position <- 0L
    for (i in seq_len(order)) {
      for (j in seq_len(order)) {
        position <- position + 1L
        b0 <- sd_intercept[[group]] * nodes[[i]]
        b1 <- sd_slope[[group]] *
          (rho * nodes[[i]] + sqrt(1 - rho^2) * nodes[[j]])
        eta <- beta_mu[[1L]] + beta_mu[[2L]] * data$x[rows] + b0 + b1 * data$x[rows]
        node_loglik[[position]] <- log_weights[[i]] + log_weights[[j]] +
          sum(stats::dpois(data$count[rows], exp(eta), log = TRUE))
      }
    }
    max_loglik <- max(node_loglik)
    max_loglik + log(sum(exp(node_loglik - max_loglik)))
  }, numeric(1L))
  sum(group_loglik)
}

test_that("Poisson correlated q2 SD regression recovers both coefficient scales", {
  sim <- poisson_correlated_q2_sd_fixture()
  dat <- sim$data
  key_intercept <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
  key_slope <- 'sd(id, dpar = "mu", coef = "x")'
  formula <- bf(
    count ~ x + (1 + x | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w,
    sd(id, dpar = "mu", coef = "x") ~ v
  )
  fit <- drmTMB(
    formula, family = stats::poisson(), data = dat,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_identical(fit$model$random$mu$n_terms, 2L)
  expect_identical(fit$model$random$mu$n_cors, 1L)
  expect_named(fit$sdpars, c(key_intercept, key_slope))
  expect_true(all(vapply(fit$sdpars, function(x) {
    length(x) == nlevels(dat$id) && all(is.finite(x))
  }, logical(1L))))
  expect_true(all(is.finite(c(
    coef(fit, key_intercept), coef(fit, key_slope), fit$corpars$mu
  ))))
  expect_lt(abs(coef(fit, key_intercept)[["w"]] - sim$truth[["intercept_sd_slope"]]), 0.3)
  expect_lt(abs(coef(fit, key_slope)[["v"]] - sim$truth[["random_slope_sd_slope"]]), 0.3)
  expect_lt(abs(unname(fit$corpars$mu[[1L]]) - sim$truth[["rho"]]), 0.3)

  sd_intercept <- predict(fit, dpar = key_intercept,
                          newdata = data.frame(w = sim$w_group))
  sd_slope <- predict(fit, dpar = key_slope,
                      newdata = data.frame(v = sim$v_group))
  expect_true(all(is.finite(c(sd_intercept, sd_slope))))
  oracle <- poisson_correlated_q2_sd_gh_loglik(
    dat, coef(fit, "mu"), sd_intercept, sd_slope, unname(fit$corpars$mu[[1L]])
  )
  expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 0.5)

  constant_formula <- bf(
    count ~ x + (1 + x | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ 1,
    sd(id, dpar = "mu", coef = "x") ~ 1
  )
  constant <- drmTMB(
    constant_formula, family = stats::poisson(), data = dat,
    control = drm_control(se = FALSE)
  )
  ordinary <- drmTMB(
    bf(count ~ x + (1 + x | id)), family = stats::poisson(), data = dat,
    control = drm_control(se = FALSE)
  )
  expect_equal(as.numeric(logLik(constant)), as.numeric(logLik(ordinary)),
               tolerance = 1e-6)

  dat$z <- stats::rnorm(nrow(dat))
  expect_error(
    drmTMB(
      bf(
        count ~ x + z + (1 + x + z | id),
        sd(id, dpar = "mu", coef = "(Intercept)") ~ w,
        sd(id, dpar = "mu", coef = "x") ~ v,
        sd(id, dpar = "mu", coef = "z") ~ w
      ),
      family = stats::poisson(), data = dat,
      control = drm_control(se = FALSE)
    ),
    "support one unlabelled Poisson intercept-slope block"
  )
})
