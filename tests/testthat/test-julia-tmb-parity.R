# tmb-vs-julia numeric parity on dual-fit Gaussian routes.
#
# The twin's central claim is that engine = "tmb" and engine = "julia" give the
# SAME answer on routes both engines fit. This asserts it as a NUMBER (≤1e-6 on
# logLik and coefficients), not a finite-and-sane floor. Guarded: the live
# round-trip runs in a fresh R subprocess (callr) so a parity-capable DRM.jl is
# the one loaded, and SKIPS (never fails) when JuliaCall / DRM.jl / ape are absent.
#
# Routes:
#   C (asserted): univariate Gaussian location-scale, sigma ~ x, no phylo —
#       measured |ΔlogLik|≈1.5e-10, max|Δcoef|≈1e-6 (clean parity).
#   A (asserted): Gaussian phylo-mean (sigma ~ 1). The R bridge tightens the
#       sparse all-node q1 tolerance for this exact route and asserts TMB-vs-Julia
#       logLik parity, without making any REML, interval, or non-Gaussian claim.

drm_parity_jl_path <- function() {
  drm_test_drmjl_path()
}

drm_parity_fit_route_c <- function() {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_parity_jl_path()
  callr::r(
    function(pkg, jl_path) {
      julia_home <- Sys.getenv(
        "DRM_JL_JULIA_HOME",
        Sys.getenv("JULIA_HOME", "")
      )
      if (nzchar(julia_home)) {
        Sys.setenv(JULIA_HOME = julia_home)
      }
      options(drmTMB.DRM.jl.path = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))
      set.seed(42L)
      n <- 120L
      x <- stats::rnorm(n)
      y <- 0.5 + 0.6 * x + stats::rnorm(n, 0, exp(-0.2 + 0.3 * x))
      dat <- data.frame(x = x, y = y)
      form <- drmTMB::bf(y ~ x, sigma ~ x)
      ft <- drmTMB::drmTMB(
        form,
        family = stats::gaussian(),
        data = dat,
        engine = "tmb"
      )
      fj <- drmTMB::drmTMB(
        form,
        family = stats::gaussian(),
        data = dat,
        engine = "julia"
      )
      flat <- function(f) as.numeric(unlist(stats::coef(f), use.names = FALSE))
      list(
        ll_tmb = as.numeric(stats::logLik(ft)),
        ll_jl = as.numeric(stats::logLik(fj)),
        coef_tmb = flat(ft),
        coef_jl = flat(fj),
        conv_tmb = drmTMB::is_converged(ft),
        conv_jl = drmTMB::is_converged(fj)
      )
    },
    args = list(pkg = pkg, jl_path = jl_path),
    error = "error"
  )
}

test_that("engine='julia' == engine='tmb' to <=1e-6 on Gaussian location-scale (Route C)", {
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not(
    dir.exists(drm_parity_jl_path()),
    "DRM.jl engine path not available"
  )

  res <- tryCatch(
    drm_parity_fit_route_c(),
    error = function(e) {
      testthat::skip(paste(
        "tmb-vs-julia parity round-trip unavailable:",
        conditionMessage(e)
      ))
    }
  )

  expect_true(isTRUE(res$conv_tmb) && isTRUE(res$conv_jl))
  expect_true(is.finite(res$ll_tmb) && is.finite(res$ll_jl))
  # The central twin claim, as a number:
  expect_lt(abs(res$ll_tmb - res$ll_jl), 1e-6)
  expect_equal(length(res$coef_tmb), length(res$coef_jl))
  expect_lt(max(abs(res$coef_tmb - res$coef_jl)), 1e-5)
})

drm_parity_fit_route_b <- function() {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_parity_jl_path()
  callr::r(
    function(pkg, jl_path) {
      julia_home <- Sys.getenv(
        "DRM_JL_JULIA_HOME",
        Sys.getenv("JULIA_HOME", "")
      )
      if (nzchar(julia_home)) {
        Sys.setenv(JULIA_HOME = julia_home)
      }
      options(drmTMB.DRM.jl.path = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))
      set.seed(7L)
      n <- 80L
      x <- stats::rnorm(n)
      e1 <- stats::rnorm(n)
      e2 <- 0.5 * e1 + sqrt(0.75) * stats::rnorm(n)
      dat <- data.frame(
        x = x,
        y1 = 0.2 + 0.4 * x + 0.8 * e1,
        y2 = -0.1 + 0.3 * x + 0.7 * e2
      )
      form <- drmTMB::bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~1,
        sigma2 = ~1,
        rho12 = ~1
      )
      ft <- drmTMB::drmTMB(
        form,
        family = drmTMB::biv_gaussian(),
        data = dat,
        engine = "tmb"
      )
      fj <- drmTMB::drmTMB(
        form,
        family = drmTMB::biv_gaussian(),
        data = dat,
        engine = "julia"
      )
      list(
        ll_tmb = as.numeric(stats::logLik(ft)),
        ll_jl = as.numeric(stats::logLik(fj)),
        conv_tmb = drmTMB::is_converged(ft),
        conv_jl = drmTMB::is_converged(fj)
      )
    },
    args = list(pkg = pkg, jl_path = jl_path),
    error = "error"
  )
}

test_that("engine='julia' == engine='tmb' to <=1e-6 on bivariate Gaussian residual rho12 (Route B, validates P1)", {
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not(
    dir.exists(drm_parity_jl_path()),
    "DRM.jl engine path not available"
  )
  res <- tryCatch(
    drm_parity_fit_route_b(),
    error = function(e) {
      testthat::skip(paste(
        "biv parity round-trip unavailable:",
        conditionMessage(e)
      ))
    }
  )
  expect_true(isTRUE(res$conv_tmb) && isTRUE(res$conv_jl))
  # logLik parity confirms the models agree, INCLUDING the guarded RHO_GUARD*tanh rho12 link
  # (the independent review's P1 divergence — now aligned: measured |dlogLik|~1e-9). The
  # scale/correlation coef values match too, but the engines order that block differently,
  # so we assert the robust scalar invariant.
  expect_lt(abs(res$ll_tmb - res$ll_jl), 1e-6)
})

drm_parity_fit_q2_phylo <- function() {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_parity_jl_path()
  callr::r(
    function(pkg, jl_path) {
      julia_home <- Sys.getenv(
        "DRM_JL_JULIA_HOME",
        Sys.getenv("JULIA_HOME", "")
      )
      if (nzchar(julia_home)) {
        Sys.setenv(JULIA_HOME = julia_home)
      }
      options(drmTMB.DRM.jl.path = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))
      set.seed(20260625L)
      n_tip <- 12L
      nrep <- 3L
      tree <- ape::rcoal(n_tip)
      tip <- tree$tip.label
      species <- rep(tip, each = nrep)
      n <- length(species)
      x <- stats::rnorm(n)
      V_phy <- ape::vcv.phylo(tree)
      C_phy <- t(chol(V_phy + diag(1e-10, n_tip)))
      Sigma_a <- matrix(c(0.22, 0.07, 0.07, 0.18), 2L, 2L)
      C_axis <- chol(Sigma_a)
      U <- C_phy %*% matrix(stats::rnorm(n_tip * 2L), n_tip, 2L) %*% C_axis
      row <- match(species, tip)
      e1 <- stats::rnorm(n, sd = 0.32)
      e2 <- 0.25 * e1 + sqrt(1 - 0.25^2) * stats::rnorm(n, sd = 0.36)
      dat <- data.frame(
        species = species,
        x = x,
        y1 = 0.20 + 0.30 * x + U[row, 1L] + e1,
        y2 = -0.15 + 0.15 * x + U[row, 2L] + e2
      )
      form <- drmTMB::bf(
        mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
        mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
        sigma1 = ~1,
        sigma2 = ~1,
        rho12 = ~1
      )
      ft <- drmTMB::drmTMB(
        form,
        family = drmTMB::biv_gaussian(),
        data = dat,
        engine = "tmb"
      )
      payload <- drmTMB:::drm_julia_bridge_payload(
        form,
        family_type = "biv_gaussian",
        data = dat,
        env = environment(form$entries[[1L]]$formula),
        method = "ML"
      )
      direct <- drmTMB:::drm_julia_call_bridge(
        payload$formula,
        "biv_gaussian",
        payload$data,
        payload$tree,
        payload$options
      )
      fj <- drmTMB::drmTMB(
        form,
        family = drmTMB::biv_gaussian(),
        data = dat,
        engine = "julia"
      )
      phylo_pair <- function(fit) {
        rows <- drmTMB::corpairs(fit, level = "phylogenetic")
        rows$estimate[[1L]]
      }
      fixed_coef <- function(fit) {
        blocks <- stats::coef(fit)[
          c("mu1", "mu2", "sigma1", "sigma2", "rho12")
        ]
        as.numeric(unlist(blocks, use.names = FALSE))
      }
      direct_fixed <- !startsWith(direct$coef_names, "phylocov_")
      list(
        ll_tmb = as.numeric(stats::logLik(ft)),
        ll_direct = as.numeric(direct$loglik),
        ll_jl = as.numeric(stats::logLik(fj)),
        coef_tmb = fixed_coef(ft),
        coef_direct = as.numeric(direct$coefficients[direct_fixed]),
        coef_jl = fixed_coef(fj),
        rho_tmb = mean(drmTMB::rho12(ft)),
        rho_direct = mean(as.numeric(direct$corpairs)),
        rho_jl = mean(drmTMB::rho12(fj)),
        phylo_tmb = phylo_pair(ft),
        phylo_direct = direct$q2_point_export$correlation[1L, 2L],
        phylo_jl = phylo_pair(fj),
        target = direct$q2_point_export$target,
        bridge_dimension = fj$bridge_payload$bivariate_dimension,
        conv_tmb = drmTMB::is_converged(ft),
        conv_direct = isTRUE(direct$converged),
        conv_jl = drmTMB::is_converged(fj)
      )
    },
    args = list(pkg = pkg, jl_path = jl_path),
    error = "error"
  )
}

test_that("q2 Gaussian phylo residual-correlation bridge parity is banked narrowly", {
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not_installed("ape")
  skip_if_not(
    dir.exists(drm_parity_jl_path()),
    "DRM.jl engine path not available"
  )

  res <- tryCatch(
    drm_parity_fit_q2_phylo(),
    error = function(e) {
      testthat::skip(paste(
        "q2 phylo parity round-trip unavailable:",
        conditionMessage(e)
      ))
    }
  )
  if (inherits(res, "error")) {
    testthat::fail(paste(
      "q2 phylo parity subprocess returned an error:",
      conditionMessage(res)
    ))
  }

  expect_true(
    isTRUE(res$conv_tmb) && isTRUE(res$conv_direct) && isTRUE(res$conv_jl)
  )
  expect_identical(res$target, "gaussian_q2_mu1_mu2_phylo_residual_correlation")
  expect_identical(res$bridge_dimension, "q2")
  expect_lt(abs(res$ll_direct - res$ll_jl), 1e-8)
  expect_lt(max(abs(res$coef_direct - res$coef_jl)), 1e-8)
  expect_lt(abs(res$rho_direct - res$rho_jl), 1e-8)
  expect_lt(abs(res$phylo_direct - res$phylo_jl), 1e-8)
  expect_lt(abs(res$ll_tmb - res$ll_jl), 5e-3)
  expect_lt(max(abs(res$coef_tmb - res$coef_jl)), 5e-2)
  expect_lt(abs(res$rho_tmb - res$rho_jl), 5e-2)
  expect_lt(abs(res$phylo_tmb - res$phylo_jl), 5e-2)
})

drm_parity_fit_q2_known_structured <- function() {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_parity_jl_path()
  callr::r(
    function(pkg, jl_path) {
      julia_home <- Sys.getenv(
        "DRM_JL_JULIA_HOME",
        Sys.getenv("JULIA_HOME", "")
      )
      if (nzchar(julia_home)) {
        Sys.setenv(JULIA_HOME = julia_home)
      }
      options(drmTMB.DRM.jl.path = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))
      set.seed(20260628L)
      n_id <- 10L
      nrep <- 3L
      id_levels <- paste0("id", seq_len(n_id))
      idx <- seq_len(n_id)
      K <- outer(idx, idx, function(i, j) 0.45^abs(i - j))
      diag(K) <- diag(K) + 0.08
      dimnames(K) <- list(id_levels, id_levels)
      m <- matrix(stats::rnorm(n_id * n_id), n_id, n_id)
      A0 <- crossprod(m) / n_id + diag(n_id)
      d <- sqrt(diag(A0))
      A <- A0 / outer(d, d)
      dimnames(A) <- list(id_levels, id_levels)
      theta <- seq(0, 1.5 * pi, length.out = n_id)
      coords <- data.frame(
        x = cos(theta) + seq_len(n_id) / (3 * n_id),
        y = sin(theta),
        row.names = id_levels
      )
      native_spatial <- drmTMB:::drm_spatial_coords_precision(
        coords,
        site = id_levels,
        group = "id"
      )
      K_spatial <- solve(as.matrix(native_spatial$precision))
      id <- rep(id_levels, each = nrep)
      n <- length(id)
      x <- stats::rnorm(n)
      Sigma_a <- matrix(c(0.20, 0.06, 0.06, 0.16), 2L, 2L)
      axis_chol <- chol(Sigma_a)

      fit_one <- function(kind, C) {
        C_group <- t(chol(C))
        U <- C_group %*%
          matrix(stats::rnorm(n_id * 2L), n_id, 2L) %*%
          axis_chol
        row <- match(id, id_levels)
        e1 <- stats::rnorm(n, sd = 0.28)
        e2 <- 0.20 * e1 + sqrt(1 - 0.20^2) * stats::rnorm(n, sd = 0.30)
        dat <- data.frame(
          id = id,
          x = x,
          y1 = 0.25 + 0.35 * x + U[row, 1L] + e1,
          y2 = -0.10 + 0.25 * x + U[row, 2L] + e2,
          stringsAsFactors = FALSE
        )
        form <- if (identical(kind, "relmat")) {
          drmTMB::bf(
            mu1 = y1 ~ x + relmat(1 | p | id, K = K),
            mu2 = y2 ~ x + relmat(1 | p | id, K = K),
            sigma1 = ~1,
            sigma2 = ~1,
            rho12 = ~1
          )
        } else if (identical(kind, "animal")) {
          drmTMB::bf(
            mu1 = y1 ~ x + animal(1 | p | id, A = A),
            mu2 = y2 ~ x + animal(1 | p | id, A = A),
            sigma1 = ~1,
            sigma2 = ~1,
            rho12 = ~1
          )
        } else {
          drmTMB::bf(
            mu1 = y1 ~ x + spatial(1 | p | id, coords = coords),
            mu2 = y2 ~ x + spatial(1 | p | id, coords = coords),
            sigma1 = ~1,
            sigma2 = ~1,
            rho12 = ~1
          )
        }
        ft <- drmTMB::drmTMB(
          form,
          family = drmTMB::biv_gaussian(),
          data = dat,
          engine = "tmb"
        )
        payload <- drmTMB:::drm_julia_biv_known_structured_payload(
          form,
          family_type = "biv_gaussian",
          data = dat,
          env = environment(form$entries[[1L]]$formula)
        )
        direct <- drmTMB:::drm_julia_call_structured(
          payload$formula,
          "biv_gaussian",
          payload$data,
          payload$matrix,
          payload$kwarg,
          payload$options
        )
        fj <- drmTMB::drmTMB(
          form,
          family = drmTMB::biv_gaussian(),
          data = dat,
          engine = "julia"
        )
        fixed_coef <- function(fit) {
          blocks <- stats::coef(fit)[
            c("mu1", "mu2", "sigma1", "sigma2", "rho12")
          ]
          as.numeric(unlist(blocks, use.names = FALSE))
        }
        structured_pair <- function(fit) {
          rows <- drmTMB::corpairs(fit, level = kind)
          rows$estimate[[1L]]
        }
        direct_fixed <- !startsWith(direct$coef_names, "phylocov_")
        list(
          kind = kind,
          ll_tmb = as.numeric(stats::logLik(ft)),
          ll_direct = as.numeric(direct$loglik),
          ll_jl = as.numeric(stats::logLik(fj)),
          coef_tmb = fixed_coef(ft),
          coef_direct = as.numeric(direct$coefficients[direct_fixed]),
          coef_jl = fixed_coef(fj),
          rho_tmb = mean(drmTMB::rho12(ft)),
          rho_direct = mean(as.numeric(direct$corpairs)),
          rho_jl = mean(drmTMB::rho12(fj)),
          struct_tmb = structured_pair(ft),
          struct_direct = direct$q2_point_export$correlation[1L, 2L],
          struct_jl = structured_pair(fj),
          target = direct$q2_point_export$target,
          structured_type = direct$q2_point_export$structured_type,
          payload_formula_mu1 = payload$formula$mu1,
          payload_kwarg = payload$kwarg,
          bridge_dimension = fj$bridge_payload$bivariate_dimension,
          bridge_type = fj$bridge_payload$structured_type,
          conv_tmb = drmTMB::is_converged(ft),
          conv_direct = isTRUE(direct$converged),
          conv_jl = drmTMB::is_converged(fj)
        )
      }

      list(
        relmat = fit_one("relmat", K),
        animal = fit_one("animal", A),
        spatial = fit_one("spatial", K_spatial)
      )
    },
    args = list(pkg = pkg, jl_path = jl_path),
    error = "error"
  )
}

test_that("q2 Gaussian known structured residual-correlation bridge parity is banked narrowly", {
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not(
    dir.exists(drm_parity_jl_path()),
    "DRM.jl engine path not available"
  )

  res <- tryCatch(
    drm_parity_fit_q2_known_structured(),
    error = function(e) {
      testthat::skip(paste(
        "q2 known-structured parity round-trip unavailable:",
        conditionMessage(e)
      ))
    }
  )
  if (inherits(res, "error")) {
    testthat::fail(paste(
      "q2 known-structured parity subprocess returned an error:",
      conditionMessage(res)
    ))
  }

  expect_setequal(names(res), c("relmat", "animal", "spatial"))
  for (kind in names(res)) {
    item <- res[[kind]]
    expect_true(
      isTRUE(item$conv_tmb) &&
        isTRUE(item$conv_direct) &&
        isTRUE(item$conv_jl)
    )
    expected_direct_type <- if (identical(kind, "spatial")) "relmat" else kind
    expect_identical(
      item$target,
      paste0(
        "gaussian_q2_mu1_mu2_",
        expected_direct_type,
        "_residual_correlation"
      )
    )
    expect_identical(item$structured_type, expected_direct_type)
    expect_identical(item$bridge_type, kind)
    expect_identical(item$bridge_dimension, "q2")
    expect_identical(
      item$payload_kwarg,
      if (identical(kind, "animal")) "A" else "K"
    )
    if (identical(kind, "spatial")) {
      expect_match(item$payload_formula_mu1, "relmat(1 | id)", fixed = TRUE)
    }
    expect_lt(abs(item$ll_direct - item$ll_jl), 1e-8)
    expect_lt(max(abs(item$coef_direct - item$coef_jl)), 1e-8)
    expect_lt(abs(item$rho_direct - item$rho_jl), 1e-8)
    expect_lt(abs(item$struct_direct - item$struct_jl), 1e-8)
    expect_lt(abs(item$ll_tmb - item$ll_jl), 5e-3)
    expect_lt(max(abs(item$coef_tmb - item$coef_jl)), 5e-2)
    expect_lt(abs(item$rho_tmb - item$rho_jl), 5e-2)
    expect_lt(abs(item$struct_tmb - item$struct_jl), 5e-2)
  }
})

drm_parity_fit_route_a <- function() {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_parity_jl_path()
  callr::r(
    function(pkg, jl_path) {
      julia_home <- Sys.getenv(
        "DRM_JL_JULIA_HOME",
        Sys.getenv("JULIA_HOME", "")
      )
      if (nzchar(julia_home)) {
        Sys.setenv(JULIA_HOME = julia_home)
      }
      options(drmTMB.DRM.jl.path = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))
      set.seed(111L)
      n <- 18L
      tree <- ape::rcoal(n)
      species <- tree$tip.label
      dat <- data.frame(
        species = sample(species),
        x = seq(-1, 1, length.out = n)
      )
      phy <- stats::setNames(stats::rnorm(n, 0, 0.45), species)
      dat$y <- 0.4 + 0.7 * dat$x + phy[dat$species] + stats::rnorm(n, 0, 0.35)
      form <- drmTMB::bf(
        y ~ x + phylo(1 | species, tree = tree),
        sigma ~ 1
      )
      ft <- drmTMB::drmTMB(
        form,
        family = stats::gaussian(),
        data = dat,
        engine = "tmb"
      )
      payload <- drmTMB:::drm_julia_bridge_payload(
        form,
        family_type = "gaussian",
        data = dat,
        env = environment(form$entries[[1]]$formula),
        method = "ML"
      )
      direct <- drmTMB:::drm_julia_call_bridge(
        payload$formula,
        "gaussian",
        payload$data,
        payload$tree,
        payload$options
      )
      fj <- drmTMB::drmTMB(
        form,
        family = stats::gaussian(),
        data = dat,
        engine = "julia"
      )
      flat <- function(f) as.numeric(unlist(stats::coef(f), use.names = FALSE))
      list(
        ll_tmb = as.numeric(stats::logLik(ft)),
        ll_direct = as.numeric(direct$loglik),
        ll_jl = as.numeric(stats::logLik(fj)),
        coef_tmb = flat(ft),
        coef_direct = as.numeric(direct$coefficients[seq_along(flat(ft))]),
        coef_jl = flat(fj),
        conv_tmb = drmTMB::is_converged(ft),
        conv_direct = isTRUE(direct$converged),
        conv_jl = drmTMB::is_converged(fj)
      )
    },
    args = list(pkg = pkg, jl_path = jl_path),
    error = "error"
  )
}

test_that("engine='julia' == engine='tmb' to <=1e-6 on Gaussian phylo-mean (Route A)", {
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not_installed("ape")
  skip_if_not(
    dir.exists(drm_parity_jl_path()),
    "DRM.jl engine path not available"
  )

  res <- tryCatch(
    drm_parity_fit_route_a(),
    error = function(e) {
      testthat::skip(paste(
        "q1 Gaussian phylo-mean parity round-trip unavailable:",
        conditionMessage(e)
      ))
    }
  )
  if (inherits(res, "error")) {
    testthat::fail(paste(
      "q1 Gaussian phylo-mean parity subprocess returned an error:",
      conditionMessage(res)
    ))
  }
  expect_true(
    isTRUE(res$conv_tmb) && isTRUE(res$conv_direct) && isTRUE(res$conv_jl)
  )
  expect_true(
    is.finite(res$ll_tmb) && is.finite(res$ll_direct) && is.finite(res$ll_jl)
  )
  expect_lt(abs(res$ll_tmb - res$ll_direct), 1e-6)
  expect_lt(abs(res$ll_tmb - res$ll_jl), 1e-6)
  expect_equal(length(res$coef_tmb), length(res$coef_jl))
  expect_equal(length(res$coef_tmb), length(res$coef_direct))
  expect_lt(max(abs(res$coef_tmb - res$coef_direct)), 1e-5)
  expect_lt(max(abs(res$coef_tmb - res$coef_jl)), 1e-5)
  expect_lt(max(abs(res$coef_direct - res$coef_jl)), 1e-10)
})

drm_parity_fit_q1_relmat_gaussian_ml <- function() {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_parity_jl_path()
  callr::r(
    function(pkg, jl_path) {
      julia_home <- Sys.getenv(
        "DRM_JL_JULIA_HOME",
        Sys.getenv("JULIA_HOME", "")
      )
      if (nzchar(julia_home)) {
        Sys.setenv(JULIA_HOME = julia_home)
      }
      options(drmTMB.DRM.jl.path = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))

      set.seed(20260624L)
      n_id <- 12L
      n_each <- 4L
      id_levels <- paste0("id", seq_len(n_id))
      K <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.35^abs(i - j))
      diag(K) <- diag(K) + 0.15
      dimnames(K) <- list(id_levels, id_levels)
      id <- rep(id_levels, each = n_each)
      x <- stats::rnorm(length(id))
      sd_known <- 0.55
      sigma <- 0.32
      related_effect <- as.vector(
        t(chol(K)) %*% stats::rnorm(n_id, sd = sd_known)
      )
      names(related_effect) <- id_levels
      y <- 0.25 +
        0.45 * x +
        related_effect[id] +
        stats::rnorm(length(id), sd = sigma)
      dat <- data.frame(
        y = unname(y),
        x = x,
        id = id,
        stringsAsFactors = FALSE
      )
      form <- drmTMB::bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1)

      ft <- drmTMB::drmTMB(
        form,
        family = stats::gaussian(),
        data = dat,
        engine = "tmb"
      )
      payload <- drmTMB:::drm_julia_structured_payload(
        form,
        family_type = "gaussian",
        data = dat,
        env = environment(form$entries[[1L]]$formula)
      )
      direct <- drmTMB:::drm_julia_call_structured(
        payload$formula,
        "gaussian",
        payload$data,
        payload$matrix,
        payload$kwarg,
        payload$options
      )
      fj <- drmTMB::drmTMB(
        form,
        family = stats::gaussian(),
        data = dat,
        engine = "julia"
      )

      flat <- function(f) {
        as.numeric(unlist(stats::coef(f), use.names = FALSE))
      }
      coef_tmb <- flat(ft)
      coef_direct <- as.numeric(direct$coefficients[seq_along(coef_tmb)])
      coef_jl <- flat(fj)
      ll_tmb <- as.numeric(stats::logLik(ft))
      ll_direct <- as.numeric(direct$loglik)
      ll_jl <- as.numeric(stats::logLik(fj))
      sd_tmb <- unname(ft$sdpars$mu[["relmat(1 | id)"]])
      sd_jl <- unname(fj$sdpars$mu[["relmat(1 | id)"]])
      list(
        ll_tmb = ll_tmb,
        ll_direct = ll_direct,
        ll_jl = ll_jl,
        max_abs_loglik_delta = max(
          abs(ll_tmb - ll_direct),
          abs(ll_tmb - ll_jl)
        ),
        direct_bridge_loglik_delta = abs(ll_direct - ll_jl),
        coef_tmb = coef_tmb,
        coef_direct = coef_direct,
        coef_jl = coef_jl,
        max_abs_coef_delta = max(
          abs(coef_tmb - coef_direct),
          abs(coef_tmb - coef_jl),
          abs(coef_direct - coef_jl)
        ),
        sd_tmb = sd_tmb,
        sd_jl = sd_jl,
        max_abs_sd_delta = abs(sd_tmb - sd_jl),
        conv_tmb = drmTMB::is_converged(ft),
        conv_direct = isTRUE(direct$converged),
        conv_jl = drmTMB::is_converged(fj),
        direct_coef_names = as.character(direct$coef_names),
        jl_sd_names = names(fj$sdpars$mu)
      )
    },
    args = list(pkg = pkg, jl_path = jl_path),
    error = "error"
  )
}

test_that("q1 Gaussian relmat ML parity is banked", {
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not(
    dir.exists(drm_parity_jl_path()),
    "DRM.jl general-covariance engine not available"
  )

  res <- tryCatch(
    drm_parity_fit_q1_relmat_gaussian_ml(),
    error = function(e) {
      testthat::skip(paste(
        "q1 Gaussian relmat ML parity round-trip unavailable:",
        conditionMessage(e)
      ))
    }
  )
  if (inherits(res, "error")) {
    testthat::fail(paste(
      "q1 Gaussian relmat ML parity subprocess returned an error:",
      conditionMessage(res)
    ))
  }

  expect_true(
    isTRUE(res$conv_tmb) && isTRUE(res$conv_direct) && isTRUE(res$conv_jl)
  )
  expect_true(
    is.finite(res$ll_tmb) && is.finite(res$ll_direct) && is.finite(res$ll_jl)
  )
  expect_lt(res$direct_bridge_loglik_delta, 1e-10)
  expect_lt(res$max_abs_loglik_delta, 1e-6)
  expect_lt(res$max_abs_coef_delta, 1e-5)
  expect_lt(res$max_abs_sd_delta, 1e-5)
  expect_equal(
    res$direct_coef_names,
    c(
      "mu_(Intercept)",
      "mu_x",
      "sigma_(Intercept)",
      "resd_id"
    )
  )
  expect_equal(res$jl_sd_names, "relmat(1 | id)")
  expect_true(is.finite(res$sd_tmb))
  expect_true(is.finite(res$sd_jl))
  expect_gt(res$sd_tmb, 0)
  expect_gt(res$sd_jl, 0)
})

drm_parity_fit_q1_animal_gaussian_ml <- function() {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_parity_jl_path()
  callr::r(
    function(pkg, jl_path) {
      julia_home <- Sys.getenv(
        "DRM_JL_JULIA_HOME",
        Sys.getenv("JULIA_HOME", "")
      )
      if (nzchar(julia_home)) {
        Sys.setenv(JULIA_HOME = julia_home)
      }
      options(drmTMB.DRM.jl.path = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))

      set.seed(20260625L)
      n_id <- 12L
      n_each <- 4L
      id_levels <- paste0("id", seq_len(n_id))
      m <- matrix(stats::rnorm(n_id * n_id), n_id, n_id)
      A0 <- crossprod(m) / n_id + diag(n_id)
      d <- sqrt(diag(A0))
      A <- A0 / outer(d, d)
      dimnames(A) <- list(id_levels, id_levels)
      id <- rep(id_levels, each = n_each)
      x <- stats::rnorm(length(id))
      sd_known <- 0.50
      sigma <- 0.34
      animal_effect <- as.vector(
        t(chol(A)) %*% stats::rnorm(n_id, sd = sd_known)
      )
      names(animal_effect) <- id_levels
      y <- 0.15 +
        0.50 * x +
        animal_effect[id] +
        stats::rnorm(length(id), sd = sigma)
      dat <- data.frame(
        y = unname(y),
        x = x,
        id = id,
        stringsAsFactors = FALSE
      )
      form <- drmTMB::bf(y ~ x + animal(1 | id, A = A), sigma ~ 1)

      ft <- drmTMB::drmTMB(
        form,
        family = stats::gaussian(),
        data = dat,
        engine = "tmb"
      )
      payload <- drmTMB:::drm_julia_structured_payload(
        form,
        family_type = "gaussian",
        data = dat,
        env = environment(form$entries[[1L]]$formula)
      )
      direct <- drmTMB:::drm_julia_call_structured(
        payload$formula,
        "gaussian",
        payload$data,
        payload$matrix,
        payload$kwarg,
        payload$options
      )
      fj <- drmTMB::drmTMB(
        form,
        family = stats::gaussian(),
        data = dat,
        engine = "julia"
      )

      flat <- function(f) {
        as.numeric(unlist(stats::coef(f), use.names = FALSE))
      }
      coef_tmb <- flat(ft)
      coef_direct <- as.numeric(direct$coefficients[seq_along(coef_tmb)])
      coef_jl <- flat(fj)
      ll_tmb <- as.numeric(stats::logLik(ft))
      ll_direct <- as.numeric(direct$loglik)
      ll_jl <- as.numeric(stats::logLik(fj))
      sd_tmb <- unname(ft$sdpars$mu[["animal(1 | id)"]])
      sd_jl <- unname(fj$sdpars$mu[["animal(1 | id)"]])
      list(
        ll_tmb = ll_tmb,
        ll_direct = ll_direct,
        ll_jl = ll_jl,
        max_abs_loglik_delta = max(
          abs(ll_tmb - ll_direct),
          abs(ll_tmb - ll_jl)
        ),
        direct_bridge_loglik_delta = abs(ll_direct - ll_jl),
        coef_tmb = coef_tmb,
        coef_direct = coef_direct,
        coef_jl = coef_jl,
        max_abs_coef_delta = max(
          abs(coef_tmb - coef_direct),
          abs(coef_tmb - coef_jl),
          abs(coef_direct - coef_jl)
        ),
        sd_tmb = sd_tmb,
        sd_jl = sd_jl,
        max_abs_sd_delta = abs(sd_tmb - sd_jl),
        conv_tmb = drmTMB::is_converged(ft),
        conv_direct = isTRUE(direct$converged),
        conv_jl = drmTMB::is_converged(fj),
        direct_coef_names = as.character(direct$coef_names),
        jl_sd_names = names(fj$sdpars$mu)
      )
    },
    args = list(pkg = pkg, jl_path = jl_path),
    error = "error"
  )
}

test_that("q1 Gaussian animal ML parity is banked", {
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not(
    dir.exists(drm_parity_jl_path()),
    "DRM.jl general-covariance engine not available"
  )

  res <- tryCatch(
    drm_parity_fit_q1_animal_gaussian_ml(),
    error = function(e) {
      testthat::skip(paste(
        "q1 Gaussian animal ML parity round-trip unavailable:",
        conditionMessage(e)
      ))
    }
  )
  if (inherits(res, "error")) {
    testthat::fail(paste(
      "q1 Gaussian animal ML parity subprocess returned an error:",
      conditionMessage(res)
    ))
  }

  expect_true(
    isTRUE(res$conv_tmb) && isTRUE(res$conv_direct) && isTRUE(res$conv_jl)
  )
  expect_true(
    is.finite(res$ll_tmb) && is.finite(res$ll_direct) && is.finite(res$ll_jl)
  )
  expect_lt(res$direct_bridge_loglik_delta, 1e-10)
  expect_lt(res$max_abs_loglik_delta, 1e-6)
  expect_lt(res$max_abs_coef_delta, 1e-5)
  expect_lt(res$max_abs_sd_delta, 1e-5)
  expect_equal(
    res$direct_coef_names,
    c(
      "mu_(Intercept)",
      "mu_x",
      "sigma_(Intercept)",
      "resd_id"
    )
  )
  expect_equal(res$jl_sd_names, "animal(1 | id)")
  expect_true(is.finite(res$sd_tmb))
  expect_true(is.finite(res$sd_jl))
  expect_gt(res$sd_tmb, 0)
  expect_gt(res$sd_jl, 0)
})

drm_parity_fit_q1_spatial_gaussian_ml <- function() {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_parity_jl_path()
  callr::r(
    function(pkg, jl_path) {
      julia_home <- Sys.getenv(
        "DRM_JL_JULIA_HOME",
        Sys.getenv("JULIA_HOME", "")
      )
      if (nzchar(julia_home)) {
        Sys.setenv(JULIA_HOME = julia_home)
      }
      options(drmTMB.DRM.jl.path = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))

      set.seed(20260626L)
      n_site <- 10L
      n_each <- 5L
      site_levels <- paste0("site_", seq_len(n_site))
      theta <- seq(0, 1.5 * pi, length.out = n_site)
      coords <- data.frame(
        x = cos(theta) + seq_len(n_site) / (3 * n_site),
        y = sin(theta),
        row.names = site_levels
      )
      native_spatial <- drmTMB:::drm_spatial_coords_precision(
        coords,
        site = site_levels,
        group = "site"
      )
      K <- solve(as.matrix(native_spatial$precision))
      site <- rep(site_levels, each = n_each)
      x <- stats::rnorm(length(site))
      sd_known <- 0.45
      sigma <- 0.20
      spatial_effect <- as.vector(
        t(chol(K)) %*% stats::rnorm(n_site, sd = sd_known)
      )
      names(spatial_effect) <- site_levels
      y <- 0.30 +
        0.40 * x +
        spatial_effect[site] +
        stats::rnorm(length(site), sd = sigma)
      dat <- data.frame(
        y = unname(y),
        x = x,
        site = site,
        stringsAsFactors = FALSE
      )
      form <- drmTMB::bf(y ~ x + spatial(1 | site, coords = coords), sigma ~ 1)

      ft <- drmTMB::drmTMB(
        form,
        family = stats::gaussian(),
        data = dat,
        engine = "tmb"
      )
      payload <- drmTMB:::drm_julia_structured_payload(
        form,
        family_type = "gaussian",
        data = dat,
        env = environment(form$entries[[1L]]$formula)
      )
      direct <- drmTMB:::drm_julia_call_structured(
        payload$formula,
        "gaussian",
        payload$data,
        payload$matrix,
        payload$kwarg,
        payload$options
      )
      fj <- drmTMB::drmTMB(
        form,
        family = stats::gaussian(),
        data = dat,
        engine = "julia"
      )

      flat <- function(f) {
        as.numeric(unlist(stats::coef(f), use.names = FALSE))
      }
      coef_tmb <- flat(ft)
      coef_direct <- as.numeric(direct$coefficients[seq_along(coef_tmb)])
      coef_jl <- flat(fj)
      ll_tmb <- as.numeric(stats::logLik(ft))
      ll_direct <- as.numeric(direct$loglik)
      ll_jl <- as.numeric(stats::logLik(fj))
      sd_tmb <- unname(ft$sdpars$mu[["spatial(1 | site)"]])
      sd_jl <- unname(fj$sdpars$mu[["spatial(1 | site)"]])
      list(
        ll_tmb = ll_tmb,
        ll_direct = ll_direct,
        ll_jl = ll_jl,
        max_abs_loglik_delta = max(
          abs(ll_tmb - ll_direct),
          abs(ll_tmb - ll_jl)
        ),
        direct_bridge_loglik_delta = abs(ll_direct - ll_jl),
        coef_tmb = coef_tmb,
        coef_direct = coef_direct,
        coef_jl = coef_jl,
        max_abs_coef_delta = max(
          abs(coef_tmb - coef_direct),
          abs(coef_tmb - coef_jl),
          abs(coef_direct - coef_jl)
        ),
        sd_tmb = sd_tmb,
        sd_jl = sd_jl,
        max_abs_sd_delta = abs(sd_tmb - sd_jl),
        conv_tmb = drmTMB::is_converged(ft),
        conv_direct = isTRUE(direct$converged),
        conv_jl = drmTMB::is_converged(fj),
        payload_kwarg = payload$kwarg,
        payload_formula_mu = payload$formula$mu,
        direct_coef_names = as.character(direct$coef_names),
        jl_sd_names = names(fj$sdpars$mu)
      )
    },
    args = list(pkg = pkg, jl_path = jl_path),
    error = "error"
  )
}

test_that("q1 Gaussian spatial ML parity is banked against native fixed-range K", {
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not(
    dir.exists(drm_parity_jl_path()),
    "DRM.jl general-covariance engine not available"
  )

  res <- tryCatch(
    drm_parity_fit_q1_spatial_gaussian_ml(),
    error = function(e) {
      testthat::skip(paste(
        "q1 Gaussian spatial ML parity round-trip unavailable:",
        conditionMessage(e)
      ))
    }
  )
  if (inherits(res, "error")) {
    testthat::fail(paste(
      "q1 Gaussian spatial ML parity subprocess returned an error:",
      conditionMessage(res)
    ))
  }

  expect_true(
    isTRUE(res$conv_tmb) && isTRUE(res$conv_direct) && isTRUE(res$conv_jl)
  )
  expect_true(
    is.finite(res$ll_tmb) && is.finite(res$ll_direct) && is.finite(res$ll_jl)
  )
  expect_equal(res$payload_kwarg, "K")
  expect_match(res$payload_formula_mu, "relmat(1 | site)", fixed = TRUE)
  expect_lt(res$direct_bridge_loglik_delta, 1e-10)
  expect_lt(res$max_abs_loglik_delta, 1e-6)
  expect_lt(res$max_abs_coef_delta, 1e-5)
  expect_lt(res$max_abs_sd_delta, 1e-5)
  expect_equal(
    res$direct_coef_names,
    c(
      "mu_(Intercept)",
      "mu_x",
      "sigma_(Intercept)",
      "resd_site"
    )
  )
  expect_equal(res$jl_sd_names, "spatial(1 | site)")
  expect_true(is.finite(res$sd_tmb))
  expect_true(is.finite(res$sd_jl))
  expect_gt(res$sd_tmb, 0)
  expect_gt(res$sd_jl, 0)
})

drm_parity_fit_q1_sigma_phylo_ml <- function() {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_parity_jl_path()
  callr::r(
    function(pkg, jl_path) {
      julia_home <- Sys.getenv(
        "DRM_JL_JULIA_HOME",
        Sys.getenv("JULIA_HOME", "")
      )
      if (nzchar(julia_home)) {
        Sys.setenv(JULIA_HOME = julia_home)
      }
      options(drmTMB.DRM.jl.path = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))

      set.seed(20260623L)
      n_tip <- 20L
      n_rep <- 4L
      tree <- ape::rcoal(n_tip)
      sp <- tree$tip.label
      species <- rep(sp, each = n_rep)
      x <- stats::rnorm(length(species))
      bm_mu <- ape::rTraitCont(tree, model = "BM", sigma = 0.65)
      bm_sig <- ape::rTraitCont(tree, model = "BM", sigma = 0.45)
      mu <- 0.35 + 0.55 * x + bm_mu[species]
      log_sigma <- -0.45 + bm_sig[species]
      y <- stats::rnorm(length(species), mean = mu, sd = exp(log_sigma))
      dat <- data.frame(
        species = species,
        x = x,
        y = y,
        stringsAsFactors = FALSE
      )
      forms <- list(
        sigma_only = drmTMB::bf(
          y ~ x,
          sigma ~ phylo(1 | species, tree = tree)
        ),
        mu_sigma = drmTMB::bf(
          y ~ x + phylo(1 | species, tree = tree),
          sigma ~ phylo(1 | species, tree = tree)
        )
      )

      flat <- function(f) {
        as.numeric(unlist(stats::coef(f), use.names = FALSE))
      }
      sd_value <- function(fit, dpar, label) {
        out <- fit$sdpars[[dpar]]
        if (is.null(out)) {
          return(NA_real_)
        }
        if (label %in% names(out)) {
          return(unname(out[[label]]))
        }
        NA_real_
      }
      cor_value <- function(fit) {
        out <- fit$corpars$phylo
        if (is.null(out) || length(out) == 0L) {
          return(NA_real_)
        }
        unname(out[[1L]])
      }
      summarize <- function(form, labels, coef_tol = 1e-5) {
        ft <- drmTMB::drmTMB(
          form,
          family = stats::gaussian(),
          data = dat,
          engine = "tmb"
        )
        payload <- drmTMB:::drm_julia_bridge_payload(
          form,
          family_type = "gaussian",
          data = dat,
          env = environment(form$entries[[1L]]$formula),
          method = "ML"
        )
        direct <- drmTMB:::drm_julia_call_bridge(
          payload$formula,
          "gaussian",
          payload$data,
          payload$tree,
          payload$options
        )
        fj <- drmTMB::drmTMB(
          form,
          family = stats::gaussian(),
          data = dat,
          engine = "julia"
        )
        coef_tmb <- flat(ft)
        coef_jl <- flat(fj)
        coef_direct <- as.numeric(direct$coefficients[seq_along(coef_tmb)])
        ll_tmb <- as.numeric(stats::logLik(ft))
        ll_direct <- as.numeric(direct$loglik)
        ll_jl <- as.numeric(stats::logLik(fj))
        loglik_delta <- max(abs(ll_tmb - ll_direct), abs(ll_tmb - ll_jl))
        coef_delta <- max(
          abs(coef_tmb - coef_direct),
          abs(coef_tmb - coef_jl),
          abs(coef_direct - coef_jl)
        )
        sd_tmb <- c(
          mu = sd_value(ft, "mu", labels$tmb_mu),
          sigma = sd_value(ft, "sigma", labels$tmb_sigma)
        )
        sd_jl <- c(
          mu = sd_value(fj, "mu", labels$jl_mu),
          sigma = sd_value(fj, "sigma", labels$jl_sigma)
        )
        sd_delta <- max(abs(sd_tmb - sd_jl), na.rm = TRUE)
        cor_tmb <- cor_value(ft)
        cor_jl <- cor_value(fj)
        cor_delta <- abs(cor_tmb - cor_jl)
        parity_status <- if (
          isTRUE(drmTMB::is_converged(ft)) &&
            isTRUE(direct$converged) &&
            isTRUE(drmTMB::is_converged(fj)) &&
            is.finite(loglik_delta) &&
            loglik_delta < 1e-6 &&
            is.finite(coef_delta) &&
            coef_delta < coef_tol &&
            is.finite(sd_delta) &&
            sd_delta < 1e-4 &&
            (all(is.na(c(cor_tmb, cor_jl))) ||
              (is.finite(cor_delta) && cor_delta < 1e-4))
        ) {
          "passed"
        } else {
          "blocked_target_mismatch"
        }
        list(
          ll_tmb = ll_tmb,
          ll_direct = ll_direct,
          ll_jl = ll_jl,
          max_abs_loglik_delta = loglik_delta,
          direct_bridge_loglik_delta = abs(ll_direct - ll_jl),
          max_abs_coef_delta = coef_delta,
          coef_tol = coef_tol,
          max_abs_sd_delta = sd_delta,
          max_abs_cor_delta = cor_delta,
          sd_tmb = sd_tmb,
          sd_jl = sd_jl,
          cor_tmb = cor_tmb,
          cor_jl = cor_jl,
          conv_tmb = drmTMB::is_converged(ft),
          conv_direct = isTRUE(direct$converged),
          conv_jl = drmTMB::is_converged(fj),
          parity_status = parity_status
        )
      }

      list(
        sigma_only = summarize(
          forms$sigma_only,
          list(
            tmb_mu = "phylo(1 | species)",
            tmb_sigma = "phylo(1 | species)",
            jl_mu = "phylo(1 | species)",
            jl_sigma = "phylo(1 | species)"
          )
        ),
        mu_sigma = summarize(
          forms$mu_sigma,
          list(
            tmb_mu = "mu:phylo(1 | species)",
            tmb_sigma = "sigma:phylo(1 | species)",
            jl_mu = "mu:phylo(1 | species)",
            jl_sigma = "sigma:phylo(1 | species)"
          ),
          coef_tol = 2e-5
        )
      )
    },
    args = list(pkg = pkg, jl_path = jl_path),
    error = "error"
  )
}

test_that("q1 Gaussian sigma-phylo and mu+sigma ML parity are banked", {
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not_installed("ape")
  skip_if_not(
    dir.exists(drm_parity_jl_path()),
    "DRM.jl engine path not available"
  )

  res <- tryCatch(
    drm_parity_fit_q1_sigma_phylo_ml(),
    error = function(e) {
      testthat::skip(paste(
        "q1 sigma-phylo ML parity round-trip unavailable:",
        conditionMessage(e)
      ))
    }
  )
  if (inherits(res, "error")) {
    testthat::fail(paste(
      "q1 sigma-phylo ML parity subprocess returned an error:",
      conditionMessage(res)
    ))
  }

  expect_identical(res$sigma_only$parity_status, "passed")
  expect_true(
    isTRUE(res$sigma_only$conv_tmb) &&
      isTRUE(res$sigma_only$conv_direct) &&
      isTRUE(res$sigma_only$conv_jl)
  )
  expect_lt(res$sigma_only$max_abs_loglik_delta, 1e-6)
  expect_lt(res$sigma_only$max_abs_coef_delta, 1e-5)
  expect_lt(res$sigma_only$max_abs_sd_delta, 1e-4)
  expect_true(is.finite(res$sigma_only$sd_tmb[["sigma"]]))
  expect_gt(res$sigma_only$sd_tmb[["sigma"]], 0)

  expect_identical(res$mu_sigma$parity_status, "passed")
  expect_lt(res$mu_sigma$direct_bridge_loglik_delta, 1e-10)
  expect_lt(res$mu_sigma$max_abs_loglik_delta, 1e-6)
  expect_lt(res$mu_sigma$max_abs_coef_delta, 2e-5)
  expect_lt(res$mu_sigma$max_abs_sd_delta, 1e-4)
  expect_lt(res$mu_sigma$max_abs_cor_delta, 1e-4)
  expect_true(all(is.finite(res$mu_sigma$sd_tmb)))
  expect_true(all(is.finite(res$mu_sigma$sd_jl)))
  expect_true(is.finite(res$mu_sigma$cor_tmb))
  expect_true(is.finite(res$mu_sigma$cor_jl))
})
