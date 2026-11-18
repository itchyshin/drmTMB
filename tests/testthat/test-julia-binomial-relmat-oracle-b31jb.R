# Independent-oracle companion for the Julia Binomial relmat intercept SD
# route under logit, probit and cloglog. K is a hand-built irregular
# exponential kernel with a non-constant diagonal, supplied to drmTMB with its
# rows in a permuted order relative to the data levels. The dense Laplace
# oracle in helper-b31jb-oracle.R is evaluated at the live Julia estimates with
# K aligned by name. Agreement is asserted to 1e-3 absolute; each emulated bug
# (swapped selector sets, sign-flipped SD slope, reversed SD vector, K x 2,
# cov2cor(K), kernel read by position) must move the oracle by more than 20
# times that.
# Claim scope: one fixture per route; no calibration, coverage or broad parity.

b31jb_relmat_fixture <- function(link, seed, groups = 50L, repeats = 25L) {
  set.seed(seed)
  levels_id <- sprintf("id%02d", seq_len(groups))
  order_k <- sample.int(groups)
  coordinate <- (seq_len(groups) / groups)^1.7
  scale_k <- seq(0.7, 1.6, length.out = groups)
  Kfull <- outer(scale_k, scale_k) *
    exp(-abs(outer(coordinate, coordinate, `-`)) / 0.25)
  dimnames(Kfull) <- list(levels_id, levels_id)   # aligned to levels
  K_given <- Kfull[order_k, order_k]               # what the user supplies
  z_level <- (seq_len(groups) / groups)^1.5 * 2 - 1
  alpha <- c(log(0.9), 0.9)
  u <- drop(t(chol(Kfull)) %*% stats::rnorm(groups))
  idx <- rep(seq_len(groups), each = repeats)
  x <- 1.3 * stats::rnorm(length(idx))
  eta <- -0.1 + 0.4 * x + (b31jb_sd(alpha, z_level) * u)[idx]
  y <- stats::rbinom(length(idx), 1L, b31jb_linkinv(link, eta))
  dat <- data.frame(y = y, x = x, z = z_level[idx],
                    id = factor(levels_id[idx], levels = levels_id))
  dat <- dat[sample.int(nrow(dat)), , drop = FALSE]
  list(data = dat, K = Kfull, K_given = K_given, levels = levels_id,
       z_level = z_level,
       K_bugs = list(
         cov2cor_K = stats::cov2cor(Kfull),
         K_by_position = unname(K_given)
       ))
}

test_that("Julia Binomial relmat intercept SD matches an independent Laplace oracle for each link", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  for (link in c("logit", "probit", "cloglog")) {
    fx <- b31jb_relmat_fixture(link, 20261107L)
    expect_gt(max(diag(fx$K)) - min(diag(fx$K)), 1)  # non-constant diagonal
    K_given <- fx$K_given
    fit <- drmTMB(
      bf(y ~ x + relmat(1 | id, K = K_given),
         sd(id, level = "relmat") ~ z),
      family = stats::binomial(link = link), data = fx$data, engine = "julia"
    )
    expect_true(fit$opt$convergence == 0L, info = link)
    idx <- match(as.character(fx$data$id), fx$levels)
    res <- b31jb_struct_run(fit, fx$data, link, "sd_relmat(id)", fx$levels,
                            idx, fx$K, fx$z_level, K_bugs = fx$K_bugs)
    message(b31jb_check(res$ll, res$base, res$gaps, paste("relmat", link)))
    b31jb_check_optimum(
      function(beta = res$beta, alphas = list(res$alpha)) {
        res$oracle(beta = beta, alphas = alphas)
      }, res$beta, list(res$alpha), res$base)
  }
})
