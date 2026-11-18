# Independent-oracle companion for the Julia Binomial spatial_coordinate
# intercept and slope SD routes under logit, probit and cloglog. The spatial
# kernel is built by hand (exponential in Euclidean distance, range equal to the
# median positive distance, 1e-6 jitter) from irregular random coordinates
# supplied in a permuted row order, and is compared with the package kernel.
# The dense Laplace oracle in helper-b31jb-oracle.R is evaluated at the live
# Julia estimates. Agreement is asserted to 1e-3 absolute; each emulated bug
# (swapped selector sets, sign-flipped SD slope, reversed SD vector, K x 2,
# maximum-distance range, kernel read by position) must move the oracle by more
# than 20 times that.
# Claim scope: one fixture per route; no calibration, coverage or broad parity.

b31jb_spatial_fixture <- function(link, kind, seed, sites = 48L, repeats = 25L) {
  set.seed(seed)
  levels_s <- sprintf("s%02d", seq_len(sites))
  coords <- cbind(east = stats::runif(sites, 0, 3), north = stats::runif(sites, 0, 2))
  rownames(coords) <- levels_s
  K <- b31jb_spatial_K(coords)
  coords_given <- coords[sample.int(sites), , drop = FALSE]
  z_level <- (seq_len(sites) / sites)^1.5 * 2 - 1
  alpha <- c(log(1.0), 1.0)
  u <- drop(t(chol(K)) %*% stats::rnorm(sites))
  idx <- rep(seq_len(sites), each = repeats)
  x <- 1.3 * stats::rnorm(length(idx))
  field <- (b31jb_sd(alpha, z_level) * u)[idx]
  eta <- -0.1 + 0.4 * x + if (kind == "intercept") field else x * field
  y <- stats::rbinom(length(idx), 1L, b31jb_linkinv(link, eta))
  dat <- data.frame(y = y, x = x, z = z_level[idx],
                    site = factor(levels_s[idx], levels = levels_s))
  dat <- dat[sample.int(nrow(dat)), , drop = FALSE]
  list(data = dat, coords = coords, coords_given = coords_given, K = K,
       levels = levels_s, z_level = z_level,
       K_bugs = list(
         range_max_distance = b31jb_spatial_K(coords, range_fun = max),
         K_by_position = b31jb_spatial_K(coords_given)
       ))
}

for (kind_case in c("intercept", "slope")) local({
  kind <- kind_case
  test_that(paste("Julia Binomial spatial", kind, "SD matches an independent Laplace oracle for each link"), {
    skip_on_cran()
    skip_if_not_installed("JuliaCall")
    drm_skip_live_julia()
    jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
    skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
    drm_test_local_drmjl_path(jl_path)
    drm_test_local_julia_home()

    for (link in c("logit", "probit", "cloglog")) {
      fx <- b31jb_spatial_fixture(link, kind,
                                  if (kind == "intercept") 20261108L else 20261109L)
      coords <- fx$coords_given
      pkg_prec <- drmTMB:::drm_spatial_coords_precision(
        coords, site = fx$data$site, group = "site")$precision
      pkg_K <- solve(as.matrix(pkg_prec))
      dimnames(pkg_K) <- dimnames(pkg_prec)
      expect_equal(pkg_K[fx$levels, fx$levels], fx$K, tolerance = 1e-8,
                   ignore_attr = TRUE)
      form <- if (kind == "intercept") {
        bf(y ~ x + spatial(1 | site, coords = coords),
           sd(site, level = "spatial") ~ z)
      } else {
        bf(y ~ x + spatial(0 + x | site, coords = coords),
           sd(site, level = "spatial") ~ z)
      }
      fit <- drmTMB(form, family = stats::binomial(link = link), data = fx$data,
                    engine = "julia")
      expect_true(fit$opt$convergence == 0L, info = link)
      idx <- match(as.character(fx$data$site), fx$levels)
      res <- b31jb_struct_run(fit, fx$data, link, "sd_spatial(site)", fx$levels,
                              idx, fx$K, fx$z_level,
                              mult = if (kind == "intercept") NULL else fx$data$x,
                              K_bugs = fx$K_bugs)
      message(b31jb_check(res$ll, res$base, res$gaps,
                          paste("spatial", kind, link)))
      b31jb_check_optimum(
        function(beta = res$beta, alphas = list(res$alpha)) {
          res$oracle(beta = beta, alphas = alphas)
        }, res$beta, list(res$alpha), res$base)
    }
  })
})
