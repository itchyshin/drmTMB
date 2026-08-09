test_that("MSPL logit Jeffreys kernel agrees with grouped Bernoulli expansion", {
  X <- cbind(`(Intercept)` = 1, x = c(-1.2, -0.3, 0.4, 1.1))
  beta <- c(-0.2, 0.7)
  offset <- c(-0.4, 0.1, 0.3, -0.2)
  trials <- c(2L, 3L, 1L, 4L)
  frequency <- c(1L, 2L, 3L, 1L)
  grouped <- mspl_logit_jeffreys(X, beta, offset, trials, frequency)
  repeat_n <- trials * frequency
  expanded <- mspl_logit_jeffreys(
    X = X[rep(seq_len(nrow(X)), repeat_n), , drop = FALSE], beta = beta,
    offset = offset[rep(seq_len(nrow(X)), repeat_n)]
  )
  expect_true(grouped$ok)
  expect_true(expanded$ok)
  expect_equal(grouped$half_logdet, expanded$half_logdet, tolerance = 1e-12)
  expect_equal(grouped$n_eff, sum(repeat_n))
  expect_equal(grouped$c_n, 2 * sqrt(ncol(X) / sum(repeat_n)))
})

test_that("Jeffreys kernel retains finite offsets and is invariant to row order", {
  X <- cbind(1, c(-2, -0.5, 0.2, 1.3, 2.1))
  beta <- c(0.25, -0.8)
  offset <- c(-4, -0.25, 0.1, 2.5, 6)
  out <- mspl_logit_jeffreys(X, beta, offset, trials = c(1L, 2L, 3L, 1L, 2L))
  perm <- c(5L, 2L, 1L, 4L, 3L)
  reordered <- mspl_logit_jeffreys(
    X[perm, , drop = FALSE], beta, offset[perm], trials = c(1L, 2L, 3L, 1L, 2L)[perm]
  )
  expect_true(out$ok)
  expect_equal(out$half_logdet, reordered$half_logdet, tolerance = 1e-12)
  expect_equal(out$eta, drop(X %*% beta) + offset)
})

test_that("Jeffreys penalty follows the exact contrast and rescaling shift", {
  X <- cbind(1, c(-1.5, -0.1, 0.8, 2.0, 3.1))
  beta <- c(0.3, -0.4)
  base <- mspl_logit_jeffreys(X, beta)
  # gamma = C beta and X_gamma = X C^{-1}; eta must be unchanged.
  C <- matrix(c(1, 0.4, 0, 7), 2L, 2L, byrow = TRUE)
  transformed <- mspl_logit_jeffreys(X %*% solve(C), drop(C %*% beta))
  expect_true(base$ok)
  expect_true(transformed$ok)
  expect_equal(transformed$eta, base$eta, tolerance = 1e-14)
  expect_equal(transformed$half_logdet, base$half_logdet - log(abs(det(C))), tolerance = 1e-12)
})

test_that("Jeffreys kernel exposes rank failure and keeps extreme eta on log scale", {
  rank_bad <- mspl_logit_jeffreys(cbind(1, 1), c(0, 0))
  expect_false(rank_bad$ok)
  expect_identical(rank_bad$code, "rank_deficient_information")
  expect_false(rank_bad$diagnostics$full_rank)

  extreme <- mspl_logit_jeffreys(cbind(1, c(-1, 1)), c(1000, 0))
  expect_true(extreme$ok)
  expect_true(all(is.finite(extreme$log_weight)))
  expect_true(is.finite(extreme$half_logdet))
})

test_that("Jeffreys half log determinant matches independent determinant oracles", {
  X <- rbind(c(1, -1), c(1, 0), c(1, 2), c(1, 3))
  beta <- c(-0.15, 0.42)
  offset <- c(-0.3, 0.1, 0.2, -0.1)
  out <- mspl_logit_jeffreys(X, beta, offset)
  eta <- drop(X %*% beta) + offset
  w <- stats::plogis(eta) * stats::plogis(-eta)
  info <- crossprod(X, X * w)
  determinant_oracle <- 0.5 * log(det(info))
  # Cauchy--Binet for a two-column design: det(X' W X) is the sum over
  # row pairs of squared two-by-two minors times their two weights.
  pairs <- utils::combn(seq_len(nrow(X)), 2L)
  cb_det <- sum(apply(pairs, 2L, function(ind) det(X[ind, , drop = FALSE])^2 * prod(w[ind])))
  expect_true(out$ok)
  expect_equal(out$half_logdet, determinant_oracle, tolerance = 1e-12)
  expect_equal(exp(2 * out$half_logdet), cb_det, tolerance = 1e-12)
})

test_that("negative Huber uses the paper sign and has the expected knots", {
  x <- c(-2, -1, -0.25, 0, 0.25, 1, 2)
  out <- mspl_negative_huber(x, gradient = TRUE)
  expect_true(all(out$value <= 0))
  expect_equal(out$value, c(-1.5, -0.5, -0.03125, 0, -0.03125, -0.5, -1.5))
  expect_equal(out$gradient, c(1, 1, 0.25, 0, -0.25, -1, -1))
  expect_equal(mspl_huber_cost(x), -out$value)
})

test_that("q1 and q2 Cholesky maps reconstruct finite positive-definite covariance", {
  q1 <- mspl_cholesky_q1(log(1.7))
  q2 <- mspl_cholesky_q2(c(log(1.4), log(0.6), 1.3))
  expect_true(q1$ok)
  expect_equal(q1$covariance, q1$cholesky %*% t(q1$cholesky), tolerance = 1e-14)
  expect_equal(unname(q1$penalty_coordinates), log(q1$cholesky[1, 1]))
  expect_true(q2$ok)
  expect_equal(unname(q2$covariance), q2$cholesky %*% t(q2$cholesky), tolerance = 1e-12)
  expect_true(all(eigen(q2$covariance, symmetric = TRUE)$values > 0))
  expect_equal(q2$correlation[1, 2], tanh(1.3), tolerance = 1e-14)
  expect_equal(q2$penalty_coordinates[["log_l22"]], log(q2$cholesky[2, 2]), tolerance = 1e-12)
  expect_equal(q2$penalty_coordinates[["l21"]], q2$cholesky[2, 1], tolerance = 1e-12)

  near_boundary <- mspl_cholesky_q2(c(0, 0, 300))
  expect_true(near_boundary$ok)
  expect_true(is.finite(near_boundary$cholesky[2, 2]))
  expect_true(near_boundary$cholesky[2, 2] > 0)
  expect_equal(mspl_logsech(300), log(2) - 300, tolerance = 1e-14)
  expect_true(is.finite(near_boundary$penalty_coordinates[["log_l22"]]))
})

test_that("penalty components use paper Cholesky coordinates and one p/n_eff/c_n contract", {
  X <- cbind(1, c(-1, 0, 1, 2))
  beta <- c(0.1, -0.2)
  psi <- c(log(1.2), -0.7, 0.3)
  q2_map <- mspl_cholesky_q2(psi)
  out <- mspl_penalty_components(X, beta, psi, q = 2, trials = c(2L, 1L, 3L, 1L))
  expect_true(out$ok)
  expect_equal(out$p, 2L)
  expect_equal(out$n_eff, 7)
  expect_equal(out$c_n, 2 * sqrt(2 / 7))
  expect_equal(out$variance_negative_huber, sum(mspl_negative_huber(q2_map$penalty_coordinates)))
  expect_equal(out$variance_map$penalty_coordinates, q2_map$penalty_coordinates)
  expect_equal(out$log_objective_bonus, out$c_n * (out$jeffreys_bonus + out$variance_negative_huber))
  expect_equal(out$nll_penalty, -out$log_objective_bonus)
  expect_identical(mspl_penalty_components(X, beta, psi)$code, "missing_q")
})

test_that("numerical diagnostics are factual and make no eligibility decision", {
  d <- mspl_numerical_diagnostics(diag(c(1, 4)))
  expect_identical(d$status, "ok")
  expect_true(d$full_rank)
  expect_equal(d$condition_number, 4)
  expect_false("eligible" %in% names(d))
})
