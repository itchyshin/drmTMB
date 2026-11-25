# #1756: Gaussian `(1 | g) + (0 + x | g)` (same group, independent slope) used
# to abort on engine = "julia" with "raw coefficient labels are not unique".

test_that("same-group independent slope sends one resd label per component", {
  mk <- function(rhs) list(entries = list(
    list(dpar = "mu", rhs = rhs, structured = list()),
    list(dpar = "sigma", rhs = quote(1), structured = list())
  ))
  expect_identical(
    drm_julia_gaussian_same_group_ind_resd_labels(
      mk(quote(x + (1 | g) + (0 + x | g))), "gaussian"
    ),
    c("g", "g:x")
  )
  # not the same-group shape, or not Gaussian: no extra labels
  expect_null(drm_julia_gaussian_same_group_ind_resd_labels(
    mk(quote(x + (1 | g) + (1 | h))), "gaussian"
  ))
  expect_null(drm_julia_gaussian_same_group_ind_resd_labels(
    mk(quote(x + (1 | g) + (0 + x | g))), "poisson"
  ))
})

test_that("Gaussian (1 | g) + (0 + x | g) agrees across engines, ML and REML", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(1)
  G <- 30L; m <- 8L
  g <- factor(rep(seq_len(G), each = m)); x <- stats::rnorm(G * m)
  y <- 0.3 + 0.5 * x + stats::rnorm(G)[g] + stats::rnorm(G)[g] * x +
    stats::rnorm(G * m)
  d <- data.frame(y, x, g)
  f <- bf(y ~ x + (1 | g) + (0 + x | g))
  for (reml in c(FALSE, TRUE)) {
    a <- drmTMB(f, data = d, engine = "tmb", REML = reml)
    b <- drmTMB(f, data = d, engine = "julia", REML = reml)
    expect_equal(as.numeric(logLik(b)), as.numeric(logLik(a)), tolerance = 1e-6)
    expect_equal(unlist(coef(b)), unlist(coef(a))[names(unlist(coef(b)))],
                 tolerance = 1e-6)
    # Julia labels SDs by bare component (`g`, `g:x`), native by `(1 | g)`: compare values.
    expect_equal(unname(unlist(b$sdpars)), unname(unlist(a$sdpars)),
                 tolerance = 1e-6)
  }
})
