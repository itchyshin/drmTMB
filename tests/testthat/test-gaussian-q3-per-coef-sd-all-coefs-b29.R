# Batch 29 (strengthen-a) companion for evidence id
#   native-gaussian-q3-per-coef-sd-20261102r  (test-gaussian-q3-per-coef-sd.R)
# rows mu:I, mu:x1 and mu:x2 of the q = 3 iid correlated block.
#
# Reviewer deficiency closed: the original q3 fit regressed the SD of only
# (Intercept) and x; the third coefficient z kept a constant SD, so the mu:x2
# row was never fitted. Here all three coefficient SDs are regressed, each with
# its own w slope and sign (truth 0.5, -0.4, 0.7 on the log scale), so that
# every selector is exercised.
#
# Oracle (base R, independent of the TMB objective and of predict()): for each
# group the exact Gaussian marginal y_g ~ N(X_g b, Z_g D_g R D_g Z_g' + s^2 I),
# D_g = diag(exp(a_k0 + a_k1 w_g)) built by hand from the fitted sd()
# coefficients, R from the fitted correlation names parsed by coefficient name.
# Tolerance 1e-6 absolute on logLik. Emulated bugs must move the oracle by
# more than b29_q3_gap_floor (declared before the first run, not tuned):
# SD columns of two coefficients swapped (each pair), reversed group order for
# the z column only, each column's w coefficient sign-flipped, R replaced by
# the identity, and the z SD replaced by a constant. Scope: likelihood
# agreement at fitted parameters. No calibration, coverage or parity claim.

b29_q3_gap_floor <- 1

b29_q3_fixture <- function(seed = 20261401L, groups = 60L, repeats = 8L) {
  set.seed(seed)
  id <- factor(rep(sprintf("g%02d", seq_len(groups)), each = repeats))
  n <- length(id)
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  w_group <- as.numeric(scale(stats::rnorm(groups)))
  R <- matrix(c(1, 0.4, -0.3, 0.4, 1, 0.2, -0.3, 0.2, 1), 3L, 3L)
  sd_by_group <- cbind(exp(-0.5 + 0.5 * w_group),
                       exp(-0.8 - 0.4 * w_group),
                       exp(-0.7 + 0.7 * w_group))
  latent <- t(vapply(seq_len(groups), function(g) {
    diag(sd_by_group[g, ]) %*% t(chol(R)) %*% stats::rnorm(3L)
  }, numeric(3L)))
  b <- latent[as.integer(id), , drop = FALSE]
  y <- 0.2 + 0.5 * x - 0.3 * z + rowSums(cbind(1, x, z) * b) +
    stats::rnorm(n, sd = 0.5)
  list(data = data.frame(y = y, x = x, z = z, w = w_group[as.integer(id)], id = id),
       w_group = w_group, groups = groups)
}

b29_q3_fitted_R <- function(fit, coef_names) {
  out <- diag(length(coef_names))
  values <- fit$corpars$re_cov
  for (nm in names(values)) {
    inner <- sub("^cor\\((.*) \\| id\\)$", "\\1", nm)
    parts <- strsplit(inner, ",", fixed = TRUE)[[1L]]
    i <- match(trimws(parts[[1L]]), coef_names)
    j <- match(trimws(parts[[2L]]), coef_names)
    out[i, j] <- out[j, i] <- unname(values[[nm]])
  }
  out
}

b29_q3_loglik <- function(fx, fit, S, R) {
  d <- fx$data
  X <- cbind(1, d$x, d$z)
  beta <- unname(coef(fit, "mu"))
  sig <- exp(unname(coef(fit, "sigma"))[[1L]])
  sum(vapply(seq_len(fx$groups), function(g) {
    rows <- which(as.integer(d$id) == g)
    Zg <- X[rows, , drop = FALSE]
    D <- diag(S[g, ], 3L)
    V <- Zg %*% (D %*% R %*% D) %*% t(Zg) + diag(sig^2, length(rows))
    Rc <- chol(V)
    r <- backsolve(Rc, d$y[rows] - drop(Zg %*% beta), transpose = TRUE)
    -0.5 * length(rows) * log(2 * pi) - sum(log(diag(Rc))) - 0.5 * sum(r^2)
  }, numeric(1L)))
}

test_that("Gaussian q3 block with SD formulas on all three coefficients matches the exact marginal", {
  skip_on_cran()
  fx <- b29_q3_fixture()
  fit <- drmTMB(
    bf(y ~ x + z + (1 + x + z | id), sigma ~ 1,
       sd(id, coef = "(Intercept)") ~ w,
       sd(id, coef = "x") ~ w,
       sd(id, coef = "z") ~ w),
    family = stats::gaussian(), data = fx$data, control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  coef_names <- c("(Intercept)", "x", "z")
  keys <- paste0('sd(id, coef = "', coef_names, '")')
  A <- lapply(keys, function(k) coef(fit, dpar = k))
  for (a in A) expect_named(a, c("(Intercept)", "w"))
  curve <- function(a, w) unname(exp(a[[1L]] + a[[2L]] * w))
  S <- vapply(A, curve, numeric(fx$groups), w = fx$w_group)
  # every column genuinely varies across groups, so a misaligned or swapped
  # column cannot hide
  expect_true(all(apply(log(S), 2L, stats::sd) > 0.25))
  R <- b29_q3_fitted_R(fit, coef_names)
  expect_gt(max(abs(R[upper.tri(R)])), 0.05)

  ll <- as.numeric(logLik(fit))
  expect_lt(abs(ll - b29_q3_loglik(fx, fit, S, R)), 1e-6)

  gap <- function(S_bug, R_bug = R) abs(ll - b29_q3_loglik(fx, fit, S_bug, R_bug))
  bugs <- list(
    swap_I_x = gap(S[, c(2L, 1L, 3L)]),
    swap_I_z = gap(S[, c(3L, 2L, 1L)]),
    swap_x_z = gap(S[, c(1L, 3L, 2L)]),
    reversed_groups_z_only = gap(cbind(S[, 1:2], rev(S[, 3L]))),
    flip_w_I = gap(cbind(curve(c(A[[1]][[1]], -A[[1]][[2]]), fx$w_group), S[, 2:3])),
    flip_w_x = gap(cbind(S[, 1], curve(c(A[[2]][[1]], -A[[2]][[2]]), fx$w_group), S[, 3])),
    flip_w_z = gap(cbind(S[, 1:2], curve(c(A[[3]][[1]], -A[[3]][[2]]), fx$w_group))),
    identity_correlation = gap(S, diag(3L)),
    z_sd_constant = gap(cbind(S[, 1:2], rep(mean(S[, 3L]), fx$groups)))
  )
  if (nzchar(Sys.getenv("B29_PRINT"))) print(round(unlist(bugs), 3))
  for (nm in names(bugs)) {
    expect_gt(bugs[[nm]], b29_q3_gap_floor, label = paste("gap for", nm))
  }
})
