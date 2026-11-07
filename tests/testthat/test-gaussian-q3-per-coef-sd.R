# Gaussian ordinary correlated blocks of three and four coefficients with
# per-coefficient sd() formulas. The block runs through the re_cov registry:
# an unstructured correlation R (modified-Cholesky partial correlations, as in
# the Binomial q >= 3 route) and one SD per coefficient and group,
# S_g = D_g R D_g. Coefficients without an sd() formula keep a constant SD.
# The oracle is the exact Gaussian marginal: y_g ~ N(X_g beta, Z_g S_g Z_g' +
# sigma^2 I), computed densely and independently of the TMB objective.

gaussian_q3_sd_fixture <- function(q = 3L, groups = 60L, repeats = 8L,
                                   seed = 20261102L) {
  set.seed(seed)
  id <- factor(rep(seq_len(groups), each = repeats))
  n <- length(id)
  covariates <- c("x", "z", "u")[seq_len(q - 1L)]
  design <- vapply(covariates, function(v) stats::rnorm(n), numeric(n))
  design <- as.data.frame(design)
  w_group <- seq(-1, 1, length.out = groups)
  # Full-rank correlation with mixed signs.
  correlation <- diag(q)
  correlation[upper.tri(correlation)] <- c(0.4, -0.3, 0.2, 0.15, -0.25, 0.1)[
    seq_len(q * (q - 1L) / 2L)
  ]
  correlation[lower.tri(correlation)] <- t(correlation)[lower.tri(correlation)]
  chol_lower <- t(chol(correlation))
  sd_by_group <- cbind(
    exp(-0.5 + 0.4 * w_group),
    exp(-0.8 - 0.3 * w_group),
    matrix(0.3, groups, q - 2L)
  )
  latent <- t(vapply(seq_len(groups), function(g) {
    diag(sd_by_group[g, ]) %*% chol_lower %*% stats::rnorm(q)
  }, numeric(q)))
  zmat <- cbind(1, as.matrix(design))
  b <- latent[as.integer(id), , drop = FALSE]
  eta <- 0.2 + 0.5 * design$x - 0.3 * design$z +
    rowSums(zmat * b)
  data <- data.frame(y = eta + stats::rnorm(n, sd = 0.5), design,
                     w = rep(w_group, each = repeats), id)
  list(data = data, w_group = w_group, coef_names = c("(Intercept)", covariates),
       covariates = covariates)
}

gaussian_q3_block_label <- function(coef_names) {
  paste0("(", paste(sub("(Intercept)", "1", coef_names, fixed = TRUE),
                    collapse = " + "), " | id)")
}

# Correlation matrix from the fitted `re_cov` correlation names, parsed by
# coefficient names (independent of the registry order used by the engine).
gaussian_q3_fitted_correlation <- function(fit, coef_names) {
  q <- length(coef_names)
  values <- fit$corpars$re_cov
  out <- diag(q)
  for (nm in names(values)) {
    inner <- sub("^cor\\((.*) \\| id\\)$", "\\1", nm)
    parts <- strsplit(inner, ",", fixed = TRUE)[[1L]]
    i <- match(parts[[1L]], coef_names)
    j <- match(parts[[2L]], coef_names)
    out[i, j] <- out[j, i] <- unname(values[[nm]])
  }
  out
}

# Group-by-coefficient SD matrix: modelled coefficients come from predict() on
# the sd() formula, the others from the constant block SD.
gaussian_q3_fitted_sd <- function(fit, fixture, modelled) {
  coef_names <- fixture$coef_names
  groups <- length(fixture$w_group)
  label <- gaussian_q3_block_label(coef_names)
  out <- matrix(NA_real_, groups, length(coef_names))
  for (k in seq_along(coef_names)) {
    key <- paste0('sd(id, coef = "', coef_names[[k]], '")')
    out[, k] <- if (coef_names[[k]] %in% modelled) {
      unname(predict(fit, dpar = key,
                     newdata = data.frame(w = fixture$w_group)))
    } else {
      rep(unname(fit$sdpars$mu[[paste0(label, ":", coef_names[[k]])]]), groups)
    }
  }
  out
}

gaussian_q3_exact_loglik <- function(fixture, beta_mu, sd_matrix, correlation,
                                     sigma, x_fixed) {
  data <- fixture$data
  coef_names <- fixture$coef_names
  group_loglik <- vapply(levels(data$id), function(g) {
    rows <- which(data$id == g)
    gi <- as.integer(g)
    zg <- cbind(1, as.matrix(data[rows, fixture$covariates, drop = FALSE]))
    scale <- diag(sd_matrix[gi, ], length(coef_names))
    covariance <- zg %*% (scale %*% correlation %*% scale) %*% t(zg) +
      diag(sigma^2, length(rows))
    residual <- data$y[rows] - as.vector(x_fixed[rows, , drop = FALSE] %*% beta_mu)
    chol_factor <- chol(covariance)
    whitened <- backsolve(chol_factor, residual, transpose = TRUE)
    -0.5 * length(rows) * log(2 * pi) - sum(log(diag(chol_factor))) -
      0.5 * sum(whitened^2)
  }, numeric(1L))
  sum(group_loglik)
}

gaussian_q3_formula <- function(q, modelled) {
  coef_names <- c("(Intercept)", c("x", "z", "u")[seq_len(q - 1L)])
  rhs <- paste(c("x", "z", "u")[seq_len(q - 1L)], collapse = " + ")
  re <- paste0("(1 + ", rhs, " | id)")
  main <- stats::as.formula(paste("y ~ x + z +", re))
  sd_formulas <- lapply(modelled, function(coef) {
    stats::as.formula(
      paste0('sd(id, coef = "', coef, '") ~ w'),
      env = globalenv()
    )
  })
  do.call(bf, c(list(main, sigma ~ 1), sd_formulas))
}

fit_gaussian_q3_sd <- function(fixture, q, modelled, se = FALSE) {
  drmTMB(
    gaussian_q3_formula(q, modelled), family = stats::gaussian(),
    data = fixture$data, control = drm_control(se = se)
  )
}

gaussian_q3_oracle_for_fit <- function(fit, fixture, modelled,
                                       sd_matrix = NULL, correlation = NULL) {
  coef_names <- fixture$coef_names
  if (is.null(sd_matrix)) {
    sd_matrix <- gaussian_q3_fitted_sd(fit, fixture, modelled)
  }
  if (is.null(correlation)) {
    correlation <- gaussian_q3_fitted_correlation(fit, coef_names)
  }
  x_fixed <- stats::model.matrix(~ x + z, fixture$data)
  gaussian_q3_exact_loglik(
    fixture, coef(fit, "mu"), sd_matrix, correlation,
    exp(unname(coef(fit, "sigma")[[1L]])), x_fixed
  )
}

test_that("Gaussian q3 per-coefficient SD matches the exact marginal likelihood", {
  fixture <- gaussian_q3_sd_fixture(q = 3L)
  modelled <- c("(Intercept)", "x")
  fit <- fit_gaussian_q3_sd(fixture, 3L, modelled)

  expect_equal(fit$opt$convergence, 0L)
  expect_true(is.finite(as.numeric(logLik(fit))))
  expect_named(
    fit$sdpars,
    c('sd(id, coef = "(Intercept)")', 'sd(id, coef = "x")', "mu")
  )
  expect_true(all(vapply(fit$sdpars[1:2], function(v) {
    length(v) == nlevels(fixture$data$id) && all(is.finite(v)) && all(v > 0)
  }, logical(1L))))
  # The unmodelled coefficient keeps one constant SD.
  expect_named(fit$sdpars$mu, "(1 + x + z | id):z")
  expect_length(fit$corpars$re_cov, 3L)

  oracle <- gaussian_q3_oracle_for_fit(fit, fixture, modelled)
  expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 1e-8)

  # Emulated bugs: the oracle must separate the engine from plausible faults.
  sd_fit <- gaussian_q3_fitted_sd(fit, fixture, modelled)
  swapped <- sd_fit[, c(2L, 1L, 3L)]
  expect_gt(
    abs(gaussian_q3_oracle_for_fit(fit, fixture, modelled,
                                   sd_matrix = swapped) -
          as.numeric(logLik(fit))),
    1e-2
  )
  expect_gt(
    abs(gaussian_q3_oracle_for_fit(fit, fixture, modelled,
                                   correlation = diag(3L)) -
          as.numeric(logLik(fit))),
    1e-2
  )
  # Reversed group order (a group-row misalignment) is also detected.
  expect_gt(
    abs(gaussian_q3_oracle_for_fit(fit, fixture, modelled,
                                   sd_matrix = sd_fit[rev(seq_len(nrow(sd_fit))), ]) -
          as.numeric(logLik(fit))),
    1e-2
  )

  # Coarse recovery of the SD regression slopes (truth 0.4 and -0.3).
  expect_lt(abs(coef(fit, 'sd(id, coef = "(Intercept)")')[["w"]] - 0.4), 0.4)
  expect_lt(abs(coef(fit, 'sd(id, coef = "x")')[["w"]] + 0.3), 0.4)
})

test_that("Gaussian q3 with constant sd() formulas equals the ordinary q3 fit", {
  skip_on_cran()
  fixture <- gaussian_q3_sd_fixture(q = 3L)
  constant <- drmTMB(
    bf(y ~ x + z + (1 + x + z | id), sigma ~ 1,
       sd(id, coef = "(Intercept)") ~ 1,
       sd(id, coef = "x") ~ 1,
       sd(id, coef = "z") ~ 1),
    family = stats::gaussian(), data = fixture$data,
    control = drm_control(se = FALSE)
  )
  ordinary <- drmTMB(
    bf(y ~ x + z + (1 + x + z | id), sigma ~ 1), family = stats::gaussian(),
    data = fixture$data, control = drm_control(se = FALSE)
  )
  expect_equal(as.numeric(logLik(constant)), as.numeric(logLik(ordinary)),
               tolerance = 1e-6)
})

test_that("Gaussian q4 per-coefficient SD matches the exact marginal likelihood", {
  skip_on_cran()
  fixture <- gaussian_q3_sd_fixture(q = 4L, groups = 70L, repeats = 10L)
  modelled <- c("x", "u")
  formula <- bf(
    y ~ x + z + (1 + x + z + u | id), sigma ~ 1,
    sd(id, coef = "x") ~ w, sd(id, coef = "u") ~ w
  )
  fit <- drmTMB(formula, family = stats::gaussian(), data = fixture$data,
                control = drm_control(se = FALSE))
  expect_equal(fit$opt$convergence, 0L)
  expect_length(fit$corpars$re_cov, 6L)
  expect_named(
    fit$sdpars,
    c('sd(id, coef = "x")', 'sd(id, coef = "u")', "mu")
  )
  expect_named(
    fit$sdpars$mu,
    paste0("(1 + x + z + u | id):", c("(Intercept)", "z"))
  )

  oracle <- gaussian_q3_oracle_for_fit(fit, fixture, modelled)
  expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 1e-8)

  sd_fit <- gaussian_q3_fitted_sd(fit, fixture, modelled)
  expect_gt(
    abs(gaussian_q3_oracle_for_fit(fit, fixture, modelled,
                                   sd_matrix = sd_fit[, c(1L, 3L, 2L, 4L)]) -
          as.numeric(logLik(fit))),
    1e-2
  )
  expect_gt(
    abs(gaussian_q3_oracle_for_fit(fit, fixture, modelled,
                                   correlation = diag(4L)) -
          as.numeric(logLik(fit))),
    1e-2
  )
})

test_that("Gaussian q3 SD fit supports summary, ranef and conditional simulation", {
  skip_on_cran()
  fixture <- gaussian_q3_sd_fixture(q = 3L)
  fit <- fit_gaussian_q3_sd(fixture, 3L, c("(Intercept)", "x"), se = TRUE)
  expect_true(all(is.finite(diag(vcov(fit)))))
  expect_no_error(summary(fit))
  re <- ranef(fit)
  expect_true(length(re) > 0L)
  sim <- simulate(fit, nsim = 2L, seed = 1L, re.form = NULL)
  expect_equal(nrow(sim), nrow(fixture$data))
  expect_equal(ncol(sim), 2L)
  expect_true(all(is.finite(as.matrix(sim))))
})

test_that("Gaussian q3 SD refusals stay designed", {
  fixture <- gaussian_q3_sd_fixture(q = 3L, groups = 30L)
  dat <- fixture$data
  dat$v <- stats::rnorm(nrow(dat))
  dat$t <- stats::rnorm(nrow(dat))
  # Blocks of five or more coefficients stay closed.
  expect_error(
    drmTMB(
      bf(y ~ x + z + (1 + x + z + u + v | id), sigma ~ 1,
         sd(id, coef = "(Intercept)") ~ w),
      family = stats::gaussian(), data = transform(dat, u = dat$t),
      control = drm_control(se = FALSE)
    ),
    "correlated random-effect block of five or more coefficients"
  )
  # A selector that names no member of the block is refused.
  expect_error(
    drmTMB(
      bf(y ~ x + z + (1 + x + z | id), sigma ~ 1,
         sd(id, coef = "v") ~ w),
      family = stats::gaussian(), data = dat,
      control = drm_control(se = FALSE)
    ),
    "No ordinary random-effect SD target matches"
  )
  # Duplicate formulas for one coefficient are refused.
  expect_error(
    drmTMB(
      bf(y ~ x + z + (1 + x + z | id), sigma ~ 1,
         sd(id, coef = "x") ~ w, sd(id, coef = "x") ~ 1),
      family = stats::gaussian(), data = dat,
      control = drm_control(se = FALSE)
    ),
    "Duplicate"
  )
})
