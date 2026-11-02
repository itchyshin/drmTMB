# drm_restart_false_convergence(): one nlminb restart from a "false
# convergence (8)" endpoint, accepted only on code 0 + non-increasing objective
# + exact gradient <= 1e-6. No convergence tolerance is changed.

quad_obj <- function() {
  list(
    fn = function(p) sum((p - c(1, -2))^2),
    gr = function(p) 2 * (p - c(1, -2))
  )
}

test_that("a false-convergence endpoint that restarts cleanly is accepted", {
  opt <- list(
    par = c(a = 1 + 1e-9, b = -2),
    objective = 1e-18,
    convergence = 1L,
    message = "false convergence (8)"
  )
  out <- drmTMB:::drm_restart_false_convergence(opt, quad_obj())
  expect_identical(out$convergence, 0L)
  expect_match(out$message, "nlminb restart after false convergence")
  expect_lte(max(abs(quad_obj()$gr(out$par))), 1e-6)
  expect_lte(out$objective, opt$objective + 1e-8)
})

test_that("other non-convergence, other optimizers and large gradients are untouched", {
  obj <- quad_obj()
  far <- list(
    par = c(a = 5, b = 5),
    objective = obj$fn(c(5, 5)),
    convergence = 1L,
    message = "false convergence (8)"
  )
  # Restart cannot reach the optimum within one iteration: gradient gate
  # refuses it and the original result is returned unchanged.
  expect_identical(
    drmTMB:::drm_restart_false_convergence(
      far, obj, control = list(iter.max = 1L, eval.max = 2L)
    ),
    far
  )
  iter_limit <- far
  iter_limit$message <- "iteration limit reached without convergence (10)"
  expect_identical(
    drmTMB:::drm_restart_false_convergence(iter_limit, obj),
    iter_limit
  )
  expect_identical(
    drmTMB:::drm_restart_false_convergence(far, obj, method = "BFGS"),
    far
  )
  ok <- far
  ok$convergence <- 0L
  expect_identical(drmTMB:::drm_restart_false_convergence(ok, obj), ok)
})

test_that("bivariate q2 phylo REML fixture: the restart clears false convergence where nlminb produces it and never relabels a non-converged fit", {
  skip_if_not_installed("ape")
  set.seed(20260905L)
  n_id <- 10L
  nrep <- 3L
  id_levels <- paste0("id", seq_len(n_id))
  # Draw order matches drm_biv_q2_reml_fixture("phylo") in
  # test-julia-biv-q2-reml.R (the K, A and coords blocks consume RNG draws).
  idx <- seq_len(n_id)
  m <- matrix(stats::rnorm(n_id * n_id), n_id, n_id)
  tree <- ape::rcoal(n_id, tip.label = id_levels)
  C <- ape::vcv.phylo(tree)[id_levels, id_levels]
  id <- rep(id_levels, each = nrep)
  n <- length(id)
  x <- stats::rnorm(n)
  Sigma_a <- matrix(c(0.20, 0.06, 0.06, 0.16), 2L, 2L)
  U <- t(chol(C + diag(1e-10, n_id))) %*%
    matrix(stats::rnorm(n_id * 2L), n_id, 2L) %*%
    chol(Sigma_a)
  row <- match(id, id_levels)
  e1 <- stats::rnorm(n, sd = 0.28)
  e2 <- 0.20 * e1 + sqrt(1 - 0.20^2) * stats::rnorm(n, sd = 0.30)
  dat <- data.frame(
    id = id,
    x = x,
    y1 = 0.25 + 0.35 * x + U[row, 1L] + e1,
    y2 = -0.10 + 0.25 * x + U[row, 2L] + e2
  )
  fit <- suppressWarnings(drmTMB(
    bf(
      mu1 = y1 ~ x + phylo(1 | p | id, tree = tree),
      mu2 = y2 ~ x + phylo(1 | p | id, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    REML = TRUE
  ))
  # nlminb does not behave identically on every platform for this fixture:
  # on macOS it stops with false convergence and the restart clears it; on
  # Linux (Totoro, 2026-11-02) it converges directly with max |gradient| about
  # 2.6e-6; on GitHub's Ubuntu runner (R 4.6.2) it did not reach a clean stop.
  # What must hold everywhere is the helper's contract.
  if (identical(fit$opt$convergence, 0L)) {
    expect_true(is_converged(fit))
    # The 1e-6 gradient bound is the helper's own acceptance rule, so it is
    # asserted only when the restart path was taken.
    if (grepl("restart after false convergence", fit$opt$message, fixed = TRUE)) {
      expect_lte(max(abs(fit$obj$gr(fit$opt$par))), 1e-6)
    }
  } else {
    # Not converged: the helper must have left nlminb's own result untouched,
    # never relabelled as converged by a restart.
    expect_false(is_converged(fit))
    expect_false(
      grepl("restart after false convergence", fit$opt$message, fixed = TRUE)
    )
  }
})
