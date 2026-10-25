# FX3b twin pairing (drmTMB #1564 with DRModels.jl #1129). Julia-engine
# fits used to pass `mle_nonexistent = FALSE` to the twin rules, so the Julia
# geometry screen (Poisson / NB2 cone, Gaussian all-sigma collapse) never
# reached R. The bridge now ships the Julia `convergence_status` string, and
# R reads a Julia "degenerate" into the geometry slot.

drm_julia_status_stub <- function(bridge_status = NULL) {
  V <- diag(c(0.04, 0.01, 0.02))
  dimnames(V) <- rep(list(c("mu:(Intercept)", "mu:x", "sigma:(Intercept)")), 2L)
  bridge <- list(loglik = -12.3, converged = TRUE)
  bridge[["convergence_status"]] <- bridge_status
  structure(
    list(
      bridge = bridge,
      logLik = -12.3,
      vcov = V,
      sdpars = list(),
      opt = list(convergence = 0L)
    ),
    class = "drmTMB_julia"
  )
}

test_that("Julia-engine status reads the bridge convergence_status key", {
  # Every R-visible signal is clean: optimiser code 0, finite log-likelihood,
  # a positive-definite covariance with small SEs, no random effects.
  expect_identical(
    convergence_status(drm_julia_status_stub("converged")),
    "converged"
  )
  # The Julia geometry screen fired; R cannot see it except through the key.
  degenerate <- drm_julia_status_stub("degenerate")
  expect_identical(convergence_status(degenerate), "degenerate")
  expect_false(is_converged(degenerate))
  # A bridge without the key (an older DRModels.jl) leaves the slot FALSE.
  expect_identical(convergence_status(drm_julia_status_stub()), "converged")
})

# ---- Live: drmTMB(engine = "julia") against DRModels.jl itself ---------------

# All-zero counts: the DRModels.jl test_poisson_mle_existence.jl r03 draw.
drm_cs_parity_allzero <- function() {
  data.frame(
    y = rep(0, 8),
    x = c(
      -0.0292785730789077, -2.07527755306188, -1.26224739973712,
      -0.135456173606004, -1.05584042635037, 0.218711141103825,
      0.915790979674801, 0.0391185640938337
    )
  )
}

# Fit natively in DRModels.jl and return its own status string.
drm_cs_parity_julia_status <- function(dat, formula, family) {
  JuliaCall::julia_assign("drm_cs_rdat", dat)
  cols <- paste(
    vapply(names(dat), function(v) {
      sprintf("%s = Float64.(drm_cs_rdat.%s)", v, v)
    }, character(1)),
    collapse = ", "
  )
  JuliaCall::julia_command(sprintf("drm_cs_dat = (; %s);", cols))
  JuliaCall::julia_eval(sprintf(
    "String(drmTMB_backend.convergence_status(drmTMB_backend.drm(drmTMB_backend.%s, drmTMB_backend.%s; data = drm_cs_dat)))",
    formula, family
  ))
}

test_that("all-zero Poisson with engine = 'julia' is degenerate in R and Julia", {
  skip_on_cran()
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  drmTMB:::drm_julia_setup()

  dat <- drm_cs_parity_allzero()
  fit <- suppressWarnings(
    drmTMB(bf(y ~ x), family = poisson(), data = dat, engine = "julia")
  )
  expect_identical(convergence_status(fit), "degenerate")
  expect_false(is_converged(fit))
  # Julia's own verdict, as it crossed the bridge.
  expect_identical(fit$bridge[["convergence_status"]], "degenerate")
  # DRModels.jl #1129: the step-1 flag requires `fit.geometry === :ok`.
  expect_false(fit$bridge[["converged"]])
  native <- suppressWarnings(drm_cs_parity_julia_status(
    dat,
    "bf(drmTMB_backend.@formula(y ~ 1 + x))",
    "Poisson()"
  ))
  expect_identical(native, "degenerate")
})

test_that("boundary, inflated-SE and all-zero Poisson fits match DRModels.jl status", {
  skip_on_cran()
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  drmTMB:::drm_julia_setup()

  # Boundary: residual correlation 0.995 between the two responses, so the
  # fitted |rho12| sits above 0.98 with small, finite SEs.
  set.seed(20261018)
  n <- 200
  x <- rnorm(n)
  z1 <- rnorm(n)
  z2 <- 0.995 * z1 + sqrt(1 - 0.995^2) * rnorm(n)
  boundary_dat <- data.frame(
    y1 = 0.5 + 0.3 * x + z1,
    y2 = -0.2 + 0.1 * x + z2,
    x = x
  )
  # Inflated SEs: two near-collinear covariates. The covariance stays
  # positive definite, and their SEs (about 265) clear both the floor of 50
  # and 1000 times the median of the small SEs.
  set.seed(20261019)
  n <- 100
  x1 <- rnorm(n)
  inflated_dat <- data.frame(
    y = 1 + 0.5 * x1 + rnorm(n),
    x1 = x1,
    x2 = x1 + 5e-4 * rnorm(n)
  )

  cases <- list(
    list(
      id = "rho12_boundary",
      expected = "boundary",
      r = function() {
        drmTMB(
          bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
          family = biv_gaussian(), data = boundary_dat, engine = "julia"
        )
      },
      dat = boundary_dat,
      jl_formula = paste0(
        "bf(mu1 = drmTMB_backend.@formula(y1 ~ 1 + x), ",
        "mu2 = drmTMB_backend.@formula(y2 ~ 1 + x), ",
        "sigma1 = drmTMB_backend.@formula(sigma1 ~ 1), ",
        "sigma2 = drmTMB_backend.@formula(sigma2 ~ 1), ",
        "rho12 = drmTMB_backend.@formula(rho12 ~ 1))"
      ),
      jl_family = "Gaussian()"
    ),
    list(
      id = "inflated_se",
      expected = "degenerate",
      r = function() {
        drmTMB(
          bf(y ~ x1 + x2, sigma ~ 1),
          family = gaussian(), data = inflated_dat, engine = "julia"
        )
      },
      dat = inflated_dat,
      jl_formula = paste0(
        "bf(drmTMB_backend.@formula(y ~ 1 + x1 + x2), ",
        "drmTMB_backend.@formula(sigma ~ 1))"
      ),
      jl_family = "Gaussian()"
    ),
    list(
      id = "allzero_poisson",
      expected = "degenerate",
      r = function() {
        drmTMB(
          bf(y ~ x),
          family = poisson(), data = drm_cs_parity_allzero(), engine = "julia"
        )
      },
      dat = drm_cs_parity_allzero(),
      jl_formula = "bf(drmTMB_backend.@formula(y ~ 1 + x))",
      jl_family = "Poisson()"
    )
  )

  for (case in cases) {
    fit <- suppressWarnings(case$r())
    r_status <- convergence_status(fit)
    jl_status <- suppressWarnings(
      drm_cs_parity_julia_status(case$dat, case$jl_formula, case$jl_family)
    )
    expect_identical(r_status, jl_status, info = case$id)
    expect_identical(r_status, case$expected, info = case$id)
    expect_identical(fit$bridge[["convergence_status"]], jl_status, info = case$id)
    if (identical(case$id, "inflated_se")) {
      # The route is step 5, not a failed covariance or optimiser.
      expect_true(isTRUE(fit$bridge[["converged"]]), info = case$id)
      expect_true(drmTMB:::drm_twin_vcov_positive_definite(fit$vcov), info = case$id)
      expect_true(
        drmTMB:::drm_twin_inflated_se_is_true(
          drmTMB:::drm_standard_errors_from_vcov(fit$vcov)
        ),
        info = case$id
      )
    }
  }
})
