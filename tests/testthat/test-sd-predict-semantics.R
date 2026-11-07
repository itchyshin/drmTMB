# Pins the documented predict() semantics for predictor-dependent random-effect
# SD parameters (G1 condition C5, docs/dev-log/general-sd-regression/
# g1-joint-contract-review-20261101.md section 4):
#   * type = "link" is the clamped log SD, type = "response" is its exponential;
#   * the value is the multiplier on the supplied kernel, with no sqrt(K_gg);
#   * without newdata there is one value per group, named by group level;
#   * newdata rows are group-level rows, one value per row, named by rownames.
#
# Tolerances, fixed before the first run: 1e-10 absolute for identities that
# are exact in floating point (X %*% beta, exp(link)); the clamp checks are
# inequalities. No recovery, calibration or Julia claim is made here.

sps_fit_ordinary <- function() {
  set.seed(20261101L)
  n_id <- 30L
  n_each <- 6L
  ids <- paste0("g", seq_len(n_id))
  z_id <- stats::setNames(seq(-1, 1, length.out = n_id), ids)
  effect <- stats::rnorm(n_id, sd = exp(-0.6 + 0.4 * z_id))
  names(effect) <- ids
  id <- factor(rep(ids, each = n_each), levels = ids)
  x <- stats::rnorm(length(id))
  dat <- data.frame(
    y = 0.2 + 0.5 * x + effect[as.character(id)] +
      stats::rnorm(length(id), sd = 0.4),
    id = id, x = x, z = unname(z_id[as.character(id)])
  )
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sd(id) ~ z),
    family = stats::gaussian(), data = dat, control = drm_control(se = FALSE)
  )
  list(fit = fit, ids = ids, z_id = z_id)
}

test_that("ordinary SD prediction is the clamped log SD on group-level rows", {
  skip_on_cran()
  fx <- sps_fit_ordinary()
  fit <- fx$fit
  expect_equal(fit$opt$convergence, 0L)
  beta <- coef(fit, "sd(id)")

  # No newdata: one value per group, named by group level.
  link <- predict(fit, dpar = "sd(id)", type = "link")
  resp <- predict(fit, dpar = "sd(id)")
  expect_length(link, length(fx$ids))
  expect_named(link, fx$ids)
  expect_named(resp, fx$ids)
  # Inside the clamp band the soft clamp is the identity.
  expect_equal(
    unname(link), unname(beta[[1L]] + beta[[2L]] * fx$z_id[fx$ids]),
    tolerance = 1e-10
  )
  expect_equal(unname(resp), exp(unname(link)), tolerance = 1e-10)

  # newdata: each row is one group-level row, so the result has one value per
  # row (here 3 rows, unrelated to the 180 observations), named by rownames.
  nd <- data.frame(z = c(-1, 0, 1), row.names = c("a", "b", "c"))
  nd_link <- predict(fit, newdata = nd, dpar = "sd(id)", type = "link")
  expect_named(nd_link, c("a", "b", "c"))
  expect_equal(
    unname(nd_link), unname(beta[[1L]] + beta[[2L]] * nd$z),
    tolerance = 1e-10
  )
  expect_equal(
    unname(predict(fit, newdata = nd, dpar = "sd(id)")),
    exp(unname(nd_link)), tolerance = 1e-10
  )

  # The link scale is the CLAMPED log SD, not X %*% beta: a far-out group-level
  # row saturates at the clamp ceiling and the response stays finite.
  far <- data.frame(z = 100 / beta[[2L]])
  raw <- unname(beta[[1L]] + beta[[2L]] * far$z)
  far_link <- unname(predict(fit, newdata = far, dpar = "sd(id)", type = "link"))
  expect_gt(raw, 15)
  expect_lt(far_link, raw)
  expect_lte(far_link, 15 + 1e-8)
  expect_true(is.finite(unname(predict(fit, newdata = far, dpar = "sd(id)"))))
})

test_that("structured SD prediction is the multiplier on the supplied kernel", {
  skip_on_cran()
  n_id <- 30L
  n_each <- 6L
  ids <- paste0("id", seq_len(n_id))
  # Non-unit diagonal (1.7) so sqrt(K_gg) is visibly not 1, and a shuffled
  # order so any positional reading would also differ.
  K <- 1.7 * 0.45^abs(outer(seq_len(n_id), seq_len(n_id), `-`))
  dimnames(K) <- list(ids, ids)
  K <- K[c(seq.int(1L, n_id, by = 2L), seq.int(2L, n_id, by = 2L)),
         c(seq.int(1L, n_id, by = 2L), seq.int(2L, n_id, by = 2L))]
  set.seed(20261102L)
  z_id <- stats::setNames(seq(-1, 1, length.out = n_id), ids)
  effect <- as.vector(t(chol(K)) %*% stats::rnorm(n_id)) *
    exp(-0.6 + 0.4 * z_id[rownames(K)])
  names(effect) <- rownames(K)
  id <- factor(rep(ids, each = n_each), levels = ids)
  x <- stats::rnorm(length(id))
  dat <- data.frame(
    y = 0.2 + 0.5 * x + effect[as.character(id)] +
      stats::rnorm(length(id), sd = 0.4),
    id = id, x = x, z = unname(z_id[as.character(id)])
  )
  fit <- drmTMB(
    bf(y ~ x + relmat(1 | id, K = K), sd(id, level = "relmat") ~ z),
    family = stats::gaussian(), data = dat, control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  beta <- coef(fit, "sd_relmat(id)")

  resp <- predict(fit, dpar = "sd_relmat(id)")
  link <- predict(fit, dpar = "sd_relmat(id)", type = "link")
  expect_length(resp, n_id)
  expect_setequal(names(resp), ids)
  multiplier <- exp(beta[[1L]] + beta[[2L]] * z_id[names(resp)])
  # The prediction is the multiplier exp(W beta), with no sqrt(K_gg) factor.
  expect_equal(unname(resp), unname(multiplier), tolerance = 1e-10)
  expect_equal(unname(link), log(unname(multiplier)), tolerance = 1e-10)
  marginal <- unname(multiplier) *
    sqrt(diag(K)[match(names(resp), rownames(K))])
  expect_gt(max(abs(unname(resp) - marginal)), 0.1 * min(unname(resp)))

  # newdata rows are group-level rows with no kernel node: population
  # multipliers only, one per row, named by rownames.
  nd <- data.frame(z = c(-1, 1), row.names = c("p", "q"))
  nd_resp <- predict(fit, newdata = nd, dpar = "sd_relmat(id)")
  expect_named(nd_resp, c("p", "q"))
  expect_equal(
    unname(nd_resp), exp(unname(beta[[1L]] + beta[[2L]] * nd$z)),
    tolerance = 1e-10
  )
})
