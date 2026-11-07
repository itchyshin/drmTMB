# Batch 29 (lane b) companion to test-gaussian-q3-per-coef-sd.R (evidence id
# native-gaussian-q3-per-coef-sd-20261102r-m26, rows mu:I, mu:x1, mu:x2 of the
# labelled q = 3 correlated block).
#
# Reviewer deficiency closed: the existing test models only two of the three
# coefficient SDs, so the mu:x2 row is not exercised by an sd() formula. Here a
# Gaussian (1 + x + z | id) block has an sd() formula on EVERY coefficient, each
# with its own group-level selector (continuous w1, two-valued w2, a third
# continuous w3). The exact Gaussian marginal (base R, per group,
# y_g ~ N(X_g beta, Z_g D R D Z_g' + sigma^2 I)) is evaluated at the fitted
# parameters with the three SD vectors built BY HAND from the coefficients and R
# parsed from the fitted correlation names by coefficient name; tolerance 1e-6
# absolute on logLik. Emulated bugs (swapped coefficient sets, rotated SD
# columns, reversed SD vector for each coefficient, flipped correlation sign)
# must each move the oracle by more than 0.1. Scope: likelihood assembly and
# selector alignment at one seed; no calibration, coverage or parity claim.

b29b_q3_fixture <- function(groups = 80L, repeats = 10L, seed = 29901L) {
  set.seed(seed)
  id <- factor(rep(seq_len(groups), each = repeats))
  n <- length(id)
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  w1 <- seq(-1, 1, length.out = groups)
  w2 <- sample(rep(c(-1, 1), length.out = groups))
  w3 <- cos(seq(0, 3 * pi / 2, length.out = groups))[sample.int(groups)]
  R <- matrix(c(1, 0.4, -0.3, 0.4, 1, 0.25, -0.3, 0.25, 1), 3L)
  L <- t(chol(R))
  sds <- cbind(exp(-0.4 + 0.5 * w1), exp(-0.6 - 0.5 * w2), exp(-0.5 + 0.6 * w3))
  b <- t(vapply(seq_len(groups), function(g) {
    drop(diag(sds[g, ]) %*% L %*% stats::rnorm(3L))
  }, numeric(3L)))
  gi <- as.integer(id)
  y <- 0.2 + 0.5 * x - 0.3 * z + b[gi, 1L] + b[gi, 2L] * x + b[gi, 3L] * z +
    stats::rnorm(n, sd = 0.4)
  list(data = data.frame(y = y, x = x, z = z, id = id,
                         w1 = rep(w1, each = repeats), w2 = rep(w2, each = repeats),
                         w3 = rep(w3, each = repeats)),
       w = list(w1, w2, w3))
}

test_that("Gaussian q3 block with an sd() formula on every coefficient: exact oracle and bug sensitivity", {
  skip_on_cran()
  fx <- b29b_q3_fixture()
  dat <- fx$data
  fit <- drmTMB(
    bf(y ~ x + z + (1 + x + z | id), sigma ~ 1,
       sd(id, coef = "(Intercept)") ~ w1,
       sd(id, coef = "x") ~ w2,
       sd(id, coef = "z") ~ w3),
    family = stats::gaussian(), data = dat, control = drm_control(se = FALSE)
  )
  expect_identical(fit$opt$convergence, 0L)
  coefs <- c("(Intercept)", "x", "z")
  keys <- paste0('sd(id, coef = "', coefs, '")')
  co <- lapply(keys, function(k) coef(fit, k))
  expect_named(co[[1L]], c("(Intercept)", "w1"))
  expect_named(co[[2L]], c("(Intercept)", "w2"))
  expect_named(co[[3L]], c("(Intercept)", "w3"))
  curve <- function(cf, w) unname(exp(cf[[1L]] + cf[[2L]] * w))
  sd_mat <- function(co_list = co, w = fx$w) {
    vapply(1:3, function(k) curve(co_list[[k]], w[[k]]), numeric(length(w[[1L]])))
  }
  # Correlation matrix parsed by coefficient NAME from the fitted corpars.
  cors <- fit$corpars$re_cov
  R <- diag(3L)
  for (nm in names(cors)) {
    inner <- sub("^cor\\((.*) \\| id\\)$", "\\1", nm)
    p <- trimws(strsplit(inner, ",", fixed = TRUE)[[1L]])
    i <- match(p[[1L]], coefs)
    j <- match(p[[2L]], coefs)
    expect_false(anyNA(c(i, j)), info = nm)
    R[i, j] <- R[j, i] <- unname(cors[[nm]])
  }
  expect_equal(length(cors), 3L)
  beta <- unname(coef(fit, "mu"))
  sigma <- exp(unname(coef(fit, "sigma")[["(Intercept)"]]))
  oracle <- function(S = sd_mat(), Rm = R) {
    sum(vapply(seq_len(nrow(S)), function(g) {
      rows <- which(as.integer(dat$id) == g)
      Zg <- cbind(1, dat$x[rows], dat$z[rows])
      D <- diag(S[g, ], 3L)
      V <- Zg %*% (D %*% Rm %*% D) %*% t(Zg) + diag(sigma^2, length(rows))
      Rc <- chol(V)
      r <- backsolve(Rc, dat$y[rows] - beta[[1L]] - beta[[2L]] * dat$x[rows] -
                       beta[[3L]] * dat$z[rows], transpose = TRUE)
      -0.5 * length(rows) * log(2 * pi) - sum(log(diag(Rc))) - 0.5 * sum(r^2)
    }, numeric(1L)))
  }
  ref <- oracle()
  ll <- as.numeric(logLik(fit))
  expect_lt(abs(ll - ref), 1e-6)
  S0 <- sd_mat()
  for (k in 1:3) expect_gt(stats::sd(log(S0[, k])), 0.1)
  # By-hand SD vectors agree with the package prediction for the third
  # coefficient (the row the original test did not exercise).
  expect_equal(unname(predict(fit, dpar = keys[[3L]],
                              newdata = data.frame(w3 = fx$w[[3L]]))),
               S0[, 3L], tolerance = 1e-6)
  flipR <- R
  flipR[1L, 2L] <- flipR[2L, 1L] <- -R[1L, 2L]
  rev_col <- function(k) {
    S <- S0
    S[, k] <- rev(S[, k])
    S
  }
  bugs <- c(
    swapped_coef_sets = oracle(S = cbind(curve(co[[3L]], fx$w[[1L]]),
                                         curve(co[[1L]], fx$w[[2L]]),
                                         curve(co[[2L]], fx$w[[3L]]))),
    rotated_sd_columns = oracle(S = S0[, c(2L, 3L, 1L)]),
    reversed_sd_intercept = oracle(S = rev_col(1L)),
    reversed_sd_x = oracle(S = rev_col(2L)),
    reversed_sd_z = oracle(S = rev_col(3L)),
    flipped_cor_I_x = oracle(Rm = flipR)
  )
  for (nm in names(bugs)) expect_gt(abs(bugs[[nm]] - ref), 0.1, label = nm)
  if (nzchar(Sys.getenv("B29B_SHOW_GAPS"))) {
    cat(sprintf("GAP q3 | ll-ref %.2e | %s\n", ll - ref,
                paste(sprintf("%s=%.2f", names(bugs), abs(bugs - ref)), collapse = " ")))
  }
})
