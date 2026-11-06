test_that("Tweedie relmat SD bridge admits and marshals only its fitted cell", {
  K <- outer(1:4, 1:4, function(i, j) 0.5^abs(i - j))
  dat <- data.frame(
    y = rep(c(0.2, 0.8, 1.1), length.out = 12),
    x = seq(-1, 1, length.out = 12),
    id = factor(rep(letters[1:4], each = 3), levels = letters[1:4]),
    z = rep(c(0, 1, 1, 0), each = 3)
  )
  form <- bf(
    y ~ x + relmat(1 | id, K = K),
    sigma ~ 1,
    nu ~ 1,
    sd(id, level = "relmat") ~ z
  )

  expect_true(drmTMB:::drm_julia_tweedie_relmat_sd_route_admitted(form))
  expect_equal(drmTMB:::drm_julia_structured_family_tag("tweedie", form),
               "tweedie")

  payload <- drmTMB:::drm_julia_structured_payload(
    form, "tweedie", dat, environment()
  )
  expect_equal(payload$kwarg, "K")
  expect_equal(payload$matrix, K)
  expect_false(grepl("K = K", payload$formula$mu, fixed = TRUE))

  no_sd <- bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1, nu ~ 1)
  expect_false(drmTMB:::drm_julia_tweedie_relmat_sd_route_admitted(no_sd))
  expect_error(
    drmTMB:::drm_julia_structured_family_tag("tweedie", no_sd),
    "general-covariance"
  )

  bad_sigma <- bf(
    y ~ x + relmat(1 | id, K = K), sigma ~ x, nu ~ 1,
    sd(id, level = "relmat") ~ z
  )
  expect_false(drmTMB:::drm_julia_tweedie_relmat_sd_route_admitted(bad_sigma))
})

test_that("Tweedie relmat SD fit crosses the public Julia bridge with K", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261030L)
  # Use an information-rich fixture for point parity: the small bridge smoke
  # fixture can leave the native Tweedie Hessian singular even when Julia fits.
  groups <- 32L
  repeats <- 8L
  group_levels <- paste0("group_", seq_len(groups))
  group_index <- rep(seq_len(groups), each = repeats)
  group <- factor(group_levels[group_index], levels = group_levels)
  kernel_order <- rev(seq_len(groups))
  correlation <- outer(kernel_order, kernel_order,
                       function(i, j) 0.4^abs(i - j))
  kernel_scale <- rep(c(1, 1.5), length.out = groups)
  K <- diag(kernel_scale) %*% correlation %*% diag(kernel_scale)
  dimnames(K) <- list(group_levels[kernel_order], group_levels[kernel_order])
  z_group <- rep(c(-1, 1), each = groups / 2)
  z <- z_group[group_index]
  x <- stats::runif(length(group), -1, 1)
  alpha <- c("(Intercept)" = log(0.45), z = 0.45)
  latent_unit <- stats::setNames(
    as.vector(t(chol(K)) %*% stats::rnorm(groups)),
    group_levels[kernel_order]
  )
  tau <- stats::setNames(exp(alpha[[1L]] + alpha[[2L]] * z_group),
                         group_levels)
  latent <- tau[names(latent_unit)] * latent_unit
  mu <- exp(0.25 + 0.2 * x + latent[group_levels[group_index]])
  y <- drmTMB:::rtweedie_compound(
    length(mu), mu = mu, phi = 0.7^2, power = 1.4
  )
  dat <- data.frame(y, x, z, group)
  form <- bf(
    y ~ x + relmat(1 | group, K = K),
    sigma ~ 1,
    nu ~ 1,
    sd(group, level = "relmat") ~ z
  )
  dpar <- "sd_relmat(group)"

  fit_timed <- function(label, expr) {
    cat("\nStarting Tweedie related-matrix SD fit:", label, "\n")
    flush.console()
    started <- proc.time()[["elapsed"]]
    result <- force(expr)
    elapsed <- proc.time()[["elapsed"]] - started
    cat(sprintf("Finished Tweedie related-matrix SD fit: %s (%.1f seconds)\n",
                label, elapsed))
    flush.console()
    result
  }
  fit_julia <- fit_timed("Julia", drmTMB(
    form, family = tweedie(), data = dat, engine = "julia"
  ))
  fit_tmb <- fit_timed("TMB", drmTMB(
    form, family = tweedie(), data = dat, engine = "tmb"
  ))

  expect_true(is_converged(fit_julia))
  expect_equal(fit_tmb$opt$convergence, 0L)
  julia_sd <- coef(fit_julia, dpar = dpar)
  tmb_sd <- coef(fit_tmb, dpar = dpar)
  expect_named(julia_sd, c("(Intercept)", "z"))
  expect_named(tmb_sd, names(julia_sd))
  expect_equal(unname(julia_sd), unname(tmb_sd), tolerance = 0.15)
  group_sd <- predict(fit_julia, dpar = dpar)
  tmb_group_sd <- predict(fit_tmb, dpar = dpar)
  expect_length(group_sd, groups)
  expect_identical(names(group_sd), paste0(dpar, ":", levels(group)))
  expect_setequal(sub("^.*:", "", names(group_sd)), names(tmb_group_sd))
  expect_equal(unname(group_sd),
               unname(tmb_group_sd[sub("^.*:", "", names(group_sd))]),
               tolerance = 0.15)
  julia_public <- predict_parameters(fit_julia, dpar = dpar)
  tmb_public <- predict_parameters(fit_tmb, dpar = dpar)
  expect_identical(julia_public$dpar, tmb_public$dpar)
  expect_identical(julia_public$component, tmb_public$component)
  expect_setequal(julia_public$row_label, tmb_public$row_label)
  tmb_public_order <- match(julia_public$row_label, tmb_public$row_label)
  expect_false(anyNA(tmb_public_order))
  expect_equal(julia_public$estimate,
               tmb_public$estimate[tmb_public_order], tolerance = 0.15)
  expect_true(all(is.finite(group_sd) & group_sd > 0))
  expect_equal(as.numeric(logLik(fit_julia)), as.numeric(logLik(fit_tmb)),
               tolerance = 1.0)
})
