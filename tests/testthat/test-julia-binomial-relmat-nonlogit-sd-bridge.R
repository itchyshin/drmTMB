test_that("Julia Binomial relmat SD agrees with TMB for probit and cloglog", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")

  for (link in c("probit", "cloglog")) {
    set.seed(if (link == "probit") 20261071L else 20261072L)
    n_group <- 64L
    n_rep <- 24L
    id_levels <- paste0("id", seq_len(n_group))
    K <- outer(seq_len(n_group), seq_len(n_group), function(i, j) 0.35^abs(i - j))
    dimnames(K) <- list(id_levels, id_levels)
    z_group <- as.numeric(scale(stats::rnorm(n_group)))
    names(z_group) <- id_levels
    alpha <- c(`(Intercept)` = log(0.5), z = 0.55)
    unit_field <- as.vector(t(chol(K)) %*% stats::rnorm(n_group))
    latent <- unit_field * exp(alpha[[1L]] + alpha[["z"]] * z_group)
    names(latent) <- id_levels

    id <- factor(rep(id_levels, each = n_rep), levels = id_levels)
    z <- unname(z_group[as.character(id)])
    x <- stats::rnorm(length(id))
    eta <- -0.2 + 0.35 * x + latent[as.character(id)]
    family <- stats::binomial(link = link)
    y <- stats::rbinom(length(eta), size = 1L, prob = family$linkinv(eta))
    dat <- data.frame(y, x, id, z)
    formula <- bf(
      y ~ x + relmat(1 | id, K = K),
      sd(id, level = "relmat") ~ z
    )

    native <- drmTMB(
      formula, family = family, data = dat, engine = "tmb"
    )
    julia <- drmTMB(
      formula, family = family, data = dat, engine = "julia"
    )

    dpar <- "sd_relmat(id)"
    native_coef <- coef(native, dpar = dpar)
    julia_coef <- coef(julia, dpar = dpar)
    expect_identical(native$opt$convergence, 0L)
    expect_identical(julia$opt$convergence, 0L)
    expect_true(all(is.finite(julia_coef)))
    expect_named(julia_coef, names(native_coef))
    expect_gt(unname(julia_coef[["z"]]), 0.15)
    expect_lt(abs(unname(julia_coef[["z"]]) - alpha[["z"]]), 0.4)
    expect_equal(unname(julia_coef), unname(native_coef), tolerance = 0.15,
                 label = paste("SD coefficients under", link))
    expect_equal(as.numeric(logLik(julia)), as.numeric(logLik(native)),
                 tolerance = 0.15, label = paste("log likelihood under", link))

    native_sd <- predict(native, dpar = dpar)
    julia_sd <- predict(julia, dpar = dpar)
    names(native_sd) <- sub("^sd_relmat\\(id\\):", "", names(native_sd))
    names(julia_sd) <- sub("^sd_relmat\\(id\\):", "", names(julia_sd))
    expect_setequal(names(julia_sd), id_levels)
    expect_equal(unname(julia_sd[id_levels]), unname(native_sd[id_levels]),
                 tolerance = 0.15, label = paste("predicted SD under", link))
    expect_equal(unname(julia_sd[id_levels]),
                 unname(exp(alpha[[1L]] + alpha[["z"]] * z_group)),
                 tolerance = 0.35, label = paste("DGP SD under", link))
  }
})
