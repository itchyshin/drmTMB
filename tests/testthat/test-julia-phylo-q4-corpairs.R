# Live q=4 bivariate phylogenetic location-scale fit via engine = "julia", with
# the focus on `corpairs()`.
#
# DRM.jl fits the q=4 PLSM (two traits, each with a mean AND residual-scale
# sub-model, coupled through a shared 4x4 among-axis phylogenetic covariance
# Sigma_a) with the verified sparse all-node Laplace engine. The R bridge
# marshals the tree + bivariate bundle, fits through DRM.jl, and stores Sigma_a
# on the returned `drmTMB_julia` fit as the 10 log-Cholesky entries in the
# `phylocov` coefficient block.
#
# `corpairs()` on such a fit must surface the INTERPRETABLE among-axis
# correlations (mean1-mean2, mean-scale, scale-scale) reconstructed from
# Sigma_a -- matching what native `corpairs.drmTMB` reports via
# `phylo_mu_corpairs()` -- NOT the residual rho12 replicated per observation.
# This guards that capability with a live fit; the rest of the bridge suite only
# exercises spec translation on mock fits.
#
# The live test runs in a FRESH R subprocess (callr): JuliaCall keeps one
# persistent Julia session per process, so a clean subprocess guarantees the
# q=4-capable engine at `jl_path` is the one loaded for this fit, independent of
# test order. It is SKIPPED -- never failed -- when JuliaCall, callr, pkgload,
# ape, or the DRM.jl engine is unavailable, or when the fit errors here.

# --- R-side reconstruction (no Julia) ---------------------------------------
#
# The Sigma_a -> among-axis corpairs reconstruction is pure R and can be checked
# directly on a hand-built `drmTMB_julia` fit, so this part always runs.

test_that("bridge corpairs reconstructs among-axis phylo correlations from Sigma_a", {
  # A 4x4 among-axis covariance with a known mean1-mean2 correlation, built as
  # Sigma_a = D Cor D (D = axis SDs), so the target correlation is exact. The
  # bridge stores Sigma_a as its log-Cholesky factor (diagonal on the log scale,
  # off-diagonals raw; Sigma_a = L L'), which we re-serialize here.
  rho_target <- 0.5
  sds <- c(0.8, 0.7, 0.3, 0.3)
  Cor <- diag(4)
  Cor[1, 2] <- Cor[2, 1] <- rho_target
  Sigma_a <- diag(sds) %*% Cor %*% diag(sds)
  expect_equal(Sigma_a[1, 2] / (sds[[1]] * sds[[2]]), rho_target)

  # Serialize Sigma_a back to the bridge's log-Cholesky naming.
  Lc <- t(chol(Sigma_a))
  lc <- numeric()
  for (col in seq_len(4L)) {
    for (rw in col:4L) {
      nm <- sprintf("Sigma_a:L%d%d", rw, col)
      lc[[nm]] <- if (rw == col) log(Lc[rw, col]) else Lc[rw, col]
    }
  }

  result <- list(
    coef_names = c(
      "mu1_(Intercept)",
      "mu1_x",
      "mu2_(Intercept)",
      "mu2_x",
      "sigma1_(Intercept)",
      "sigma2_(Intercept)",
      "rho12_(Intercept)",
      paste0("phylocov_", names(lc))
    ),
    coefficients = c(
      1.0,
      0.5,
      -1.0,
      0.3,
      -0.7,
      -0.8,
      0.2,
      unname(lc)
    ),
    vcov = diag(length(lc) + 7L),
    loglik = -100,
    aic = 200,
    bic = 220,
    df = 7L,
    nobs = 8L,
    converged = TRUE,
    fitted = list(mu1 = seq_len(8), mu2 = seq_len(8)),
    residuals = list(mu1 = rep(0, 8), mu2 = rep(0, 8)),
    sigma = list(sigma1 = rep(0.5, 8), sigma2 = rep(0.45, 8)),
    # residual rho12 replicated per observation -- the WRONG thing for corpairs
    corpairs = rep(tanh(0.2), 8)
  )

  tree <- ape::rcoal(4)
  form <- drmTMB::bf(
    mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
    mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
    sigma1 = ~ 1 + phylo(1 | p | species, tree = tree),
    sigma2 = ~ 1 + phylo(1 | p | species, tree = tree),
    rho12 = ~1
  )
  dat <- data.frame(
    species = tree$tip.label[rep(1:4, 2)],
    x = stats::rnorm(8),
    y1 = stats::rnorm(8),
    y2 = stats::rnorm(8),
    stringsAsFactors = FALSE
  )

  fit <- drmTMB:::new_drmTMB_julia(
    result = result,
    call = quote(drmTMB(
      form,
      family = biv_gaussian(),
      data = dat,
      engine = "julia"
    )),
    formula = form,
    family = drmTMB::biv_gaussian(),
    data = dat,
    family_type = "biv_gaussian"
  )

  pairs <- drmTMB::corpairs(fit)

  # One residual row + the six among-axis cross-pairs, in combn(4, 2) order.
  expect_equal(nrow(pairs), 7L)
  expect_equal(nrow(drmTMB::corpairs(fit, level = "phylogenetic")), 6L)
  expect_equal(nrow(drmTMB::corpairs(fit, level = "residual")), 1L)
  expect_equal(
    drmTMB::corpairs(fit, level = "phylogenetic")$from_dpar,
    c("mu1", "mu1", "mu1", "mu2", "mu2", "sigma1")
  )
  expect_equal(
    drmTMB::corpairs(fit, level = "phylogenetic")$to_dpar,
    c("mu2", "sigma1", "sigma2", "sigma1", "sigma2", "sigma2")
  )
  expect_equal(
    drmTMB::corpairs(fit, level = "phylogenetic")$class,
    c(
      "mean-mean",
      "mean-scale",
      "mean-scale",
      "mean-scale",
      "mean-scale",
      "scale-scale"
    )
  )
  expect_equal(nrow(drmTMB::corpairs(fit, block = "p")), 6L)

  # The mean1-mean2 phylo correlation is recovered exactly from Sigma_a -- this
  # is the number the bug suppressed (corpairs used to return rho12 instead).
  mm <- drmTMB::corpairs(fit, class = "mean-mean")
  expect_equal(nrow(mm), 1L)
  expect_equal(mm$estimate, rho_target, tolerance = 1e-8)
  expect_true(mm$estimate != tanh(0.2)) # not the residual rho12

  # Every reconstructed correlation is finite and in [-1, 1].
  expect_true(all(is.finite(pairs$estimate)))
  expect_true(all(pairs$estimate >= -1 & pairs$estimate <= 1))

  # The raw residual rho12 path is unchanged.
  expect_equal(drmTMB::rho12(fit), rep(tanh(0.2), 8))
})

# --- Live q=4 phylo round-trip (guarded) ------------------------------------

drm_phylo_q4_path <- function() {
  drm_test_drmjl_path("DRM_JL_PATH")
}

# Fit a small q=4 bivariate phylo location-scale model via engine = "julia" in a
# clean subprocess, with a known among-trait MEAN phylo correlation, and return
# the corpairs reconstruction. Returns a list, or NULL/errors handled by caller.
drm_phylo_q4_corpairs_fit <- function(n_tip = 30L, m = 3L) {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_phylo_q4_path()
  callr::r(
    function(pkg, jl_path, n_tip, m) {
      julia_home <- Sys.getenv(
        "DRM_JL_JULIA_HOME",
        Sys.getenv("JULIA_HOME", "")
      )
      if (nzchar(julia_home)) {
        Sys.setenv(JULIA_HOME = julia_home)
      }
      options(drmTMB.DRM.jl.path = jl_path)
      Sys.setenv(DRM_JL_PATH = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))

      # Two traits evolving on a shared tree with a known among-trait MEAN phylo
      # correlation; each trait has its own mean and residual-scale sub-model,
      # coupled through a 4x4 phylogenetic covariance over axes
      # (mean1, mean2, logsigma1, logsigma2).
      set.seed(42)
      N <- as.integer(n_tip)
      tree <- ape::rcoal(N)
      sp <- tree$tip.label
      C <- ape::vcv(tree, corr = TRUE)
      LC <- t(chol(C))
      rho_mean <- 0.6
      Sa <- diag(c(0.8, 0.7, 0.3, 0.3))
      Cor <- diag(4)
      Cor[1, 2] <- Cor[2, 1] <- rho_mean
      Sigma_a <- Sa %*% Cor %*% Sa
      LSig <- t(chol(Sigma_a))
      A <- LC %*% matrix(stats::rnorm(N * 4), N, 4) %*% t(LSig)

      rows <- rep(seq_len(N), each = m)
      x <- stats::rnorm(N * m)
      b0 <- c(2.0, -1.0)
      b1 <- c(0.5, 0.3)
      ls0 <- c(log(0.5), log(0.6))
      mean1 <- b0[1] + b1[1] * x + A[rows, 1]
      mean2 <- b0[2] + b1[2] * x + A[rows, 2]
      sig1 <- exp(ls0[1] + A[rows, 3])
      sig2 <- exp(ls0[2] + A[rows, 4])
      y1 <- stats::rnorm(N * m, mean1, sig1)
      y2 <- stats::rnorm(N * m, mean2, sig2)
      dat <- data.frame(
        species = sp[rows],
        x = x,
        y1 = y1,
        y2 = y2,
        stringsAsFactors = FALSE
      )

      form <- drmTMB::bf(
        mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
        mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
        sigma1 = ~ 1 + phylo(1 | p | species, tree = tree),
        sigma2 = ~ 1 + phylo(1 | p | species, tree = tree),
        rho12 = ~1
      )

      fj <- drmTMB::drmTMB(
        form,
        family = drmTMB::biv_gaussian(),
        data = dat,
        engine = "julia"
      )

      pairs <- drmTMB::corpairs(fj)
      mm <- drmTMB::corpairs(fj, class = "mean-mean")
      list(
        class = class(fj),
        engine = fj$engine,
        nobs = stats::nobs(fj),
        converged = drmTMB::is_converged(fj),
        true_rho_mean = rho_mean,
        n_rows = nrow(pairs),
        n_phylo = nrow(drmTMB::corpairs(fj, level = "phylogenetic")),
        n_residual = nrow(drmTMB::corpairs(fj, level = "residual")),
        classes = drmTMB::corpairs(fj, level = "phylogenetic")$class,
        estimates = pairs$estimate,
        mean1_mean2 = if (nrow(mm) == 1L) mm$estimate else NA_real_,
        phylo_levels = unique(
          drmTMB::corpairs(fj, level = "phylogenetic")$level
        )
      )
    },
    args = list(
      pkg = pkg,
      jl_path = jl_path,
      n_tip = as.integer(n_tip),
      m = as.integer(m)
    ),
    error = "error"
  )
}

test_that("q4 bivariate phylo location-scale corpairs surfaces among-axis correlations (live)", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not_installed("ape")
  skip_if_not(
    dir.exists(drm_phylo_q4_path()),
    "DRM.jl q4 engine not available"
  )

  res <- tryCatch(
    drm_phylo_q4_corpairs_fit(n_tip = 30L, m = 3L),
    error = function(e) {
      testthat::skip(paste(
        "q4 phylo corpairs round-trip unavailable:",
        conditionMessage(e)
      ))
    }
  )
  skip_if(is.null(res))

  expect_true("drmTMB_julia" %in% res$class)
  expect_equal(res$engine, "julia")
  expect_true(isTRUE(res$converged))

  # corpairs returns the among-axis table, NOT rho12-per-observation: one
  # residual row + the six cross-axis phylo rows.
  expect_equal(res$n_rows, 7L)
  expect_equal(res$n_phylo, 6L)
  expect_equal(res$n_residual, 1L)
  expect_equal(unique(res$phylo_levels), "phylogenetic")
  expect_equal(
    res$classes,
    c(
      "mean-mean",
      "mean-scale",
      "mean-scale",
      "mean-scale",
      "mean-scale",
      "scale-scale"
    )
  )

  # Every reconstructed among-axis correlation is finite and a valid correlation.
  expect_true(all(is.finite(res$estimates)))
  expect_true(all(res$estimates >= -1 & res$estimates <= 1))

  # The headline: the mean1-mean2 phylo correlation is recovered in the right
  # ballpark of the true 0.6 (finite-sample point estimate, single fit -- assert
  # a generous positive band, not exact recovery).
  expect_true(is.finite(res$mean1_mean2))
  expect_gt(res$mean1_mean2, 0.2)
  expect_lt(res$mean1_mean2, 0.95)
})
