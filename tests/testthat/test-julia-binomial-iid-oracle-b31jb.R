# Independent-oracle companion for the Julia Binomial iid intercept and iid
# numeric-slope SD routes under logit, probit and cloglog. The oracle is the
# base-R exact marginal likelihood in helper-b31jb-oracle.R (fine-grid
# integration over each independent group effect; no drmTMB code, no Laplace),
# evaluated at the live Julia estimates. Agreement is asserted to 1e-3 absolute on the
# logLik; every emulated bug must move the oracle by more than 20 times that.
# The Julia iid route integrates each group by 5-node adaptive Gauss-Hermite
# quadrature, so the tight oracle is a hand-coded 5-node adaptive scheme
# (b31jb_iid_aghq); a separate exact-integral oracle bounds the truncation.
# Claim scope: one fixture per route; no calibration, coverage or broad parity.

b31jb_iid_fixture <- function(link, kind, seed, groups = 50L, repeats = 20L) {
  set.seed(seed)
  levels_id <- sprintf("g%02d", seq_len(groups))
  # Monotone but not symmetric, so the reversed SD vector differs from the SD.
  z_level <- (seq_len(groups) / groups)^1.6 * 2 - 1
  alpha <- c(log(0.7), 0.55)
  sd_level <- b31jb_sd(alpha, z_level)
  idx <- rep(seq_len(groups), each = repeats)
  x <- stats::rnorm(length(idx))
  u <- stats::rnorm(groups)
  eta <- -0.2 + 0.4 * x + if (kind == "intercept") (sd_level * u)[idx]
                          else x * (sd_level * u)[idx]
  y <- stats::rbinom(length(idx), 1L, b31jb_linkinv(link, eta))
  dat <- data.frame(y = y, x = x, z = z_level[idx],
                    id = factor(levels_id[idx], levels = levels_id))
  dat <- dat[sample.int(nrow(dat)), , drop = FALSE]
  list(data = dat, levels = levels_id, z_level = z_level)
}

b31jb_iid_case <- function(link, kind, seed) {
  fx <- b31jb_iid_fixture(link, kind, seed)
  dat <- fx$data
  form <- if (kind == "intercept") {
    bf(y ~ x + (1 | id), sd(id) ~ z)
  } else {
    bf(y ~ x + (0 + x | id), sd(id, coef = "x") ~ z)
  }
  dpar <- if (kind == "intercept") "sd(id)" else 'sd(id, coef = "x")'
  fit <- drmTMB(form, family = stats::binomial(link = link), data = dat,
                engine = "julia")
  beta <- coef(fit, dpar = "mu")
  alpha <- coef(fit, dpar = dpar)
  idx <- match(as.character(dat$id), fx$levels)
  X <- cbind(1, dat$x)
  mult <- if (kind == "intercept") NULL else dat$x
  oracle <- function(beta = beta0, alphas = list(alpha0), zl = fx$z_level,
                     sd_rev = FALSE, mu_sd_swap = FALSE) {
    sdv <- b31jb_sd(alphas[[1L]], zl)
    if (sd_rev) sdv <- rev(sdv)
    b <- beta
    if (mu_sd_swap) { b <- alphas[[1L]]; sdv <- b31jb_sd(beta, zl) }
    b31jb_iid_aghq(dat$y, link, X, b, idx, mult, sdv)
  }
  beta0 <- unname(beta); alpha0 <- unname(alpha)
  base <- oracle()
  gaps <- c(
    selector_swap = oracle(mu_sd_swap = TRUE),
    sd_slope_sign = oracle(alphas = list(c(alpha0[[1L]], -alpha0[[2L]]))),
    reversed_sd_vector = oracle(sd_rev = TRUE),
    sd_intercept_plus_log2 = oracle(alphas = list(alpha0 + c(log(2), 0))),
    wrong_predictor_scrambled = oracle(zl = fx$z_level[
      c(seq(2L, length(fx$z_level), by = 2L),
        seq(1L, length(fx$z_level), by = 2L))])
  ) - base
  exact <- b31jb_iid_exact(dat$y, link, X, beta0, idx, mult,
                           b31jb_sd(alpha0, fx$z_level))
  list(fit = fit, ll = as.numeric(logLik(fit)), base = base, gaps = gaps,
       exact = exact,
       oracle = oracle, beta = beta0, alpha = alpha0)
}

test_that("Julia Binomial iid intercept SD matches an independent Laplace oracle for each link", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  for (link in c("logit", "probit", "cloglog")) {
    res <- b31jb_iid_case(link, "intercept", 20261102L)
    expect_true(res$fit$opt$convergence == 0L, info = link)
    # Julia integrates each group with 5 adaptive Gauss-Hermite nodes, so its
    # logLik is within a small, documented truncation error of the exact
    # integral (observed below 0.02 here); the tight 1e-3 check is against the
    # hand-coded 5-node scheme in b31jb_check().
    expect_lt(abs(res$ll - res$exact), 0.05, label = paste(link, "vs exact"))
    message(b31jb_check(res$ll, res$base, res$gaps,
                        paste("iid intercept", link)))
    b31jb_check_optimum(
      function(beta = res$beta, alphas = list(res$alpha)) {
        res$oracle(beta = beta, alphas = alphas)
      }, res$beta, list(res$alpha), res$base)
  }
})

test_that("Julia Binomial iid numeric-slope SD matches an independent Laplace oracle for each link", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  for (link in c("logit", "probit", "cloglog")) {
    res <- b31jb_iid_case(link, "slope", 20261103L)
    expect_true(res$fit$opt$convergence == 0L, info = link)
    # Julia integrates each group with 5 adaptive Gauss-Hermite nodes, so its
    # logLik is within a small, documented truncation error of the exact
    # integral (observed below 0.02 here); the tight 1e-3 check is against the
    # hand-coded 5-node scheme in b31jb_check().
    expect_lt(abs(res$ll - res$exact), 0.05, label = paste(link, "vs exact"))
    message(b31jb_check(res$ll, res$base, res$gaps,
                        paste("iid slope", link)))
    b31jb_check_optimum(
      function(beta = res$beta, alphas = list(res$alpha)) {
        res$oracle(beta = beta, alphas = alphas)
      }, res$beta, list(res$alpha), res$base)
  }
})
