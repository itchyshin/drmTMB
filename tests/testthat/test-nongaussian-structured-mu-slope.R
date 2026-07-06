# Row-87 admission: non-count family structured mu ONE-SLOPE cells.
#
# These are native TMB ML/Laplace point-fit and extractor cells for non-count
# `mu` one-slope structured dependence: Gamma x relmat, Student x spatial, and
# beta x animal. This is recovery-only evidence. It does NOT imply retained
# denominators, intervals, coverage, labelled covariance, multiple structured
# slopes, scale/shape/inflation structured slopes, REML, AI-REML, bridge
# support, or public-support promotion, all of which remain planned.

test_that("non-count structured mu one-slope cells fit and expose intercept + slope SDs", {
  testthat::skip_if_not_installed("ape")

  ## --- Gamma x relmat(1 + x | id, K) ---
  set.seed(2026070601)
  gl <- paste0("g", seq_len(8L))
  gid <- factor(rep(gl, each = 12L), levels = gl)
  gx <- stats::rnorm(length(gid))
  g_int <- stats::rnorm(8L, sd = 0.30)
  g_slp <- stats::rnorm(8L, sd = 0.20)
  names(g_int) <- gl
  names(g_slp) <- gl
  gmu <- exp(0.4 + 0.25 * gx + g_int[as.character(gid)] + g_slp[as.character(gid)] * gx)
  dat_gamma <- data.frame(
    y = stats::rgamma(length(gid), shape = 25, scale = gmu / 25),
    x = gx,
    id = gid
  )
  K_gamma <- diag(8L)
  dimnames(K_gamma) <- list(gl, gl)

  fit_gamma <- drmTMB(
    bf(y ~ x + relmat(1 + x | id, K = K_gamma), sigma ~ 1),
    family = stats::Gamma(link = "log"),
    data = dat_gamma,
    control = drm_control(se = FALSE)
  )
  expect_s3_class(fit_gamma, "drmTMB")
  expect_equal(as.integer(fit_gamma$opt$convergence), 0L)
  expect_true("relmat_mu" %in% names(fit_gamma$random_effects))
  expect_true("relmat(1 | id)" %in% names(fit_gamma$sdpars$mu))
  expect_true("relmat(0 + x | id)" %in% names(fit_gamma$sdpars$mu))

  ## --- Student x spatial(1 + x | id, coords) ---
  set.seed(2026070602)
  sl <- paste0("s", seq_len(8L))
  sid <- factor(rep(sl, each = 20L), levels = sl)
  sx <- stats::rnorm(length(sid))
  s_int <- stats::rnorm(8L, sd = 0.25)
  s_slp <- stats::rnorm(8L, sd = 0.20)
  names(s_int) <- sl
  names(s_slp) <- sl
  smu <- 0.2 + 0.5 * sx + s_int[as.character(sid)] + s_slp[as.character(sid)] * sx
  dat_student <- data.frame(
    y = smu + 0.25 * stats::rt(length(sid), df = 12),
    x = sx,
    id = sid
  )
  coords_student <- data.frame(
    x = rep(seq_len(4L), each = 2L),
    y = rep(seq_len(2L), times = 4L),
    row.names = sl
  )

  fit_student <- drmTMB(
    bf(y ~ x + spatial(1 + x | id, coords = coords_student), sigma ~ 1),
    family = student(),
    data = dat_student,
    control = drm_control(se = FALSE)
  )
  expect_s3_class(fit_student, "drmTMB")
  expect_equal(as.integer(fit_student$opt$convergence), 0L)
  expect_true("spatial_mu" %in% names(fit_student$random_effects))
  expect_true("spatial(1 | id)" %in% names(fit_student$sdpars$mu))
  expect_true("spatial(0 + x | id)" %in% names(fit_student$sdpars$mu))

  ## --- beta x animal(1 + x | id, pedigree) ---
  set.seed(2026070603)
  bl <- paste0("b", seq_len(8L))
  bid <- factor(rep(bl, each = 20L), levels = bl)
  bx <- stats::rnorm(length(bid))
  b_int <- stats::rnorm(8L, sd = 0.30)
  b_slp <- stats::rnorm(8L, sd = 0.20)
  names(b_int) <- bl
  names(b_slp) <- bl
  blink <- -0.2 + 0.45 * bx + b_int[as.character(bid)] + b_slp[as.character(bid)] * bx
  bmu <- stats::plogis(blink)
  phi <- 8
  by <- stats::rbeta(length(bid), shape1 = bmu * phi, shape2 = (1 - bmu) * phi)
  by <- pmin(pmax(by, 1e-4), 1 - 1e-4)
  dat_beta <- data.frame(y = by, x = bx, id = bid)
  ped_beta <- data.frame(id = bl, dam = NA_character_, sire = NA_character_)

  fit_beta <- drmTMB(
    bf(y ~ x + animal(1 + x | id, pedigree = ped_beta), sigma ~ 1),
    family = beta(),
    data = dat_beta,
    control = drm_control(se = FALSE)
  )
  expect_s3_class(fit_beta, "drmTMB")
  expect_equal(as.integer(fit_beta$opt$convergence), 0L)
  expect_true("animal_mu" %in% names(fit_beta$random_effects))
  expect_true("animal(1 | id)" %in% names(fit_beta$sdpars$mu))
  expect_true("animal(0 + x | id)" %in% names(fit_beta$sdpars$mu))

  ## --- Boundary preserved: multiple slopes and labelled covariance stay rejected ---
  dat_gamma$z <- stats::rnorm(nrow(dat_gamma))
  expect_error(
    drmTMB(
      bf(y ~ x + z + relmat(1 + x + z | id, K = K_gamma), sigma ~ 1),
      family = stats::Gamma(link = "log"),
      data = dat_gamma
    ),
    "intercept and one-slope"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + relmat(1 + x | p | id, K = K_gamma), sigma ~ 1),
      family = stats::Gamma(link = "log"),
      data = dat_gamma
    ),
    "unlabelled q=1"
  )
})
