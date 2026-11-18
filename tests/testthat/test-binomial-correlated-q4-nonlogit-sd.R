binomial_correlated_q4_nonlogit_cholesky <- function(partial) {
  q <- 4L
  stopifnot(length(partial) == q * (q - 1L) / 2L)
  L <- matrix(0, q, q)
  position <- 0L
  for (i in seq_len(q)) {
    product <- 1
    for (j in seq_len(i - 1L)) {
      position <- position + 1L
      L[i, j] <- product * partial[[position]]
      product <- product * sqrt(1 - partial[[position]]^2)
    }
    L[i, i] <- product
  }
  L
}

test_that("Bernoulli correlated q4 SD regression fits probit and cloglog", {
  set.seed(2026102705L)
  groups <- 256L
  repeats <- 48L
  id <- factor(rep(seq_len(groups), each = repeats))
  x <- stats::rnorm(length(id))
  z <- stats::rnorm(length(id))
  t <- stats::rnorm(length(id))
  sd_predictors <- lapply(seq_len(4L), function(j) {
    as.numeric(scale(stats::rnorm(groups)))
  })
  names(sd_predictors) <- c("w", "h", "j", "k")
  alpha <- list(
    c(log(0.65), 0.65), c(log(0.55), -0.60),
    c(log(0.50), 0.55), c(log(0.45), -0.55)
  )
  tau <- vapply(seq_len(4L), function(j) {
    exp(alpha[[j]][[1L]] + alpha[[j]][[2L]] * sd_predictors[[j]])
  }, numeric(groups))
  partial <- c(0.55, -0.50, 0.50, 0.45, -0.50, 0.55)
  L <- binomial_correlated_q4_nonlogit_cholesky(partial)
  latent <- matrix(stats::rnorm(4L * groups), nrow = 4L)
  random_effects <- vapply(seq_len(groups), function(g) {
    diag(tau[g, ]) %*% L %*% latent[, g]
  }, numeric(4L))
  group_index <- as.integer(id)
  eta <- -0.1 + 0.20 * x - 0.15 * z + 0.12 * t +
    random_effects[1L, group_index] + random_effects[2L, group_index] * x +
    random_effects[3L, group_index] * z + random_effects[4L, group_index] * t
  dat <- data.frame(
    x, z, t, id,
    w = rep(sd_predictors$w, each = repeats),
    h = rep(sd_predictors$h, each = repeats),
    j = rep(sd_predictors$j, each = repeats),
    k = rep(sd_predictors$k, each = repeats)
  )
  keys <- c(
    'sd(id, dpar = "mu", coef = "(Intercept)")',
    'sd(id, dpar = "mu", coef = "x")',
    'sd(id, dpar = "mu", coef = "z")',
    'sd(id, dpar = "mu", coef = "t")'
  )
  formula <- bf(
    y ~ x + z + t + (1 + x + z + t | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w,
    sd(id, dpar = "mu", coef = "x") ~ h,
    sd(id, dpar = "mu", coef = "z") ~ j,
    sd(id, dpar = "mu", coef = "t") ~ k
  )
  inverse_link <- list(
    probit = stats::pnorm,
    cloglog = function(value) -expm1(-exp(value))
  )
  for (link in names(inverse_link)) {
    set.seed(2026102706L + match(link, names(inverse_link)))
    link_data <- dat
    link_data$y <- stats::rbinom(nrow(link_data), 1L, inverse_link[[link]](eta))
    fit <- drmTMB(
      formula, family = stats::binomial(link = link), data = link_data,
      control = drm_control(se = FALSE)
    )

    expect_identical(fit$opt$convergence, 0L, info = link)
    # Point-estimate recovery is checked below. The probit fit can have a
    # non-positive-definite Hessian, so this test makes no Wald-SE claim.
    expect_length(fit$corpars$mu, 6L)
    expect_identical(names(fit$corpars$mu), c(
      "cor((Intercept),x | id)", "cor((Intercept),z | id)",
      "cor((Intercept),t | id)", "cor(x,z | id)", "cor(x,t | id)",
      "cor(z,t | id)"
    ))
    expect_true(all(is.finite(fit$corpars$mu)), info = link)
    expect_true(all(vapply(keys, function(key) {
      all(is.finite(coef(fit, key))) && length(predict(fit, dpar = key)) == groups
    }, logical(1L))), info = link)
    for (j in seq_len(4L)) {
      expect_lt(abs(coef(fit, keys[[j]])[[2L]] - alpha[[j]][[2L]]), 0.35)
      observed_group_sd <- unname(predict(fit, dpar = keys[[j]]))
      expected_group_sd <- exp(
        coef(fit, keys[[j]])[[1L]] +
          coef(fit, keys[[j]])[[2L]] * sd_predictors[[j]]
      )
      expect_equal(observed_group_sd, expected_group_sd, tolerance = 1e-10)
    }
    # Public correlations are marginal and use lexicographic coefficient pairs.
    marginal_correlation <- tcrossprod(L)
    pairs <- utils::combn(seq_len(4L), 2L)
    expected_marginal <- vapply(seq_len(ncol(pairs)), function(j) {
      marginal_correlation[pairs[1L, j], pairs[2L, j]]
    }, numeric(1L))
    expect_lt(max(abs(unname(fit$corpars$mu) - expected_marginal)), 0.45)
    eta_cor <- as.numeric(fit$obj$env$parList(fit$opt$par)$eta_cor_mu)
    expect_equal(length(eta_cor), length(partial))
    expect_lt(max(abs(tanh(eta_cor) - partial)), 0.35)
  }
})
