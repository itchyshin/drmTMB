# Live R-to-Julia bridge test for native Poisson animal slope-only SD
# regression with `Ainv` and `pedigree` providers.
#
# Native route and fixtures: test-poisson-animal-slope-ainv-pedigree-sd-regression.R
# (non-unit-diagonal K; pedigree with inbred animals, diag(A) = 1.25).
# Existing Ainv-only parity file: test-julia-poisson-animal-ainv-slope-sd-parity.R.
#
# Same-data TMB vs Julia comparison. Tolerances fixed before the first run and
# taken from the Ainv-only parity file: coefficients 1e-4 relative, log
# likelihood 1e-3 relative, name-aligned SD predictions 1e-4 relative. They are
# not loosened here to make a fit pass. A pedigree reaches Julia as the dense
# relationship matrix `A` (converted in R); `Ainv` reaches it as `Ainv`.
# Candidate-level evidence only: one fixture per provider, no calibration or
# support claim.

poisson_slope_bridge_fixture <- function(A, seed, n_each = 16L,
                                         shuffle_rows = FALSE) {
  set.seed(seed)
  id_levels <- rownames(A)
  n_id <- length(id_levels)
  z_id <- stats::setNames(rep(c(-0.5, 0.5), length.out = n_id), id_levels)
  alpha <- c(`(Intercept)` = log(0.7), z = 0.35)
  slope <- as.vector(t(chol(A)) %*% stats::rnorm(n_id)) *
    exp(alpha[[1L]] + alpha[[2L]] * z_id[id_levels])
  names(slope) <- id_levels
  # Row blocks in reverse provider order, so the first-seen level order of the
  # data differs from rownames(A); data factor levels are lexical.
  block_order <- if (isTRUE(shuffle_rows)) rev(id_levels) else id_levels
  id_chr <- rep(block_order, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), times = n_id)
  z <- unname(z_id[id_chr])
  eta <- 0.25 + 0.2 * x + slope[id_chr] * x
  data <- data.frame(
    y = stats::rpois(length(eta), exp(eta)),
    id = factor(id_chr, levels = sort(id_levels)),
    x = x,
    z = z
  )
  list(data = data, alpha = alpha, z_id = z_id)
}

poisson_slope_bridge_ainv_fixture <- function() {
  n_id <- 96L
  order <- c(seq.int(1L, n_id, by = 2L), seq.int(2L, n_id, by = 2L))
  id_levels <- paste0("id", seq_len(n_id))
  A_base <- 1.7 * 0.35^abs(outer(seq_len(n_id), seq_len(n_id), `-`))
  dimnames(A_base) <- list(id_levels, id_levels)
  A <- A_base[order, order]
  Q <- solve(A)
  dimnames(Q) <- dimnames(A)
  fx <- poisson_slope_bridge_fixture(A, seed = 20261101L, shuffle_rows = TRUE)
  c(fx, list(A = A, Ainv = Q))
}

poisson_slope_bridge_pedigree_fixture <- function() {
  n_family <- 12L
  n_inbred <- 4L
  fam <- sprintf("%02d", seq_len(n_family))
  ped_rows <- function(f) {
    data.frame(
      id = c(paste0("sire", f), paste0("dam", f), paste0("fsm", f),
             paste0("fsf", f), sprintf("inbred%s_%d", f, seq_len(n_inbred))),
      dam = c(NA, NA, rep(paste0("dam", f), 2L),
              rep(paste0("fsf", f), n_inbred)),
      sire = c(NA, NA, rep(paste0("sire", f), 2L),
               rep(paste0("fsm", f), n_inbred)),
      stringsAsFactors = FALSE
    )
  }
  pedigree <- do.call(rbind, lapply(fam, ped_rows))
  A <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  fx <- poisson_slope_bridge_fixture(A, seed = 20261102L, shuffle_rows = TRUE)
  c(fx, list(A = A, pedigree = pedigree))
}

# Same-data TMB vs Julia comparison on one formula.
expect_poisson_slope_bridge_parity <- function(formula, fx) {
  native <- drmTMB(
    formula, family = stats::poisson(), data = fx$data,
    engine = "tmb", control = drm_control(se = FALSE)
  )
  julia <- drmTMB(
    formula, family = stats::poisson(), data = fx$data, engine = "julia"
  )
  dpar <- "sd_animal(id)"
  expect_equal(native$opt$convergence, 0L)
  expect_equal(julia$opt$convergence, 0L)

  native_sd_coef <- coef(native, dpar = dpar)
  julia_sd_coef <- coef(julia, dpar = dpar)
  expect_named(julia_sd_coef, names(native_sd_coef))
  expect_true(all(is.finite(julia_sd_coef)))
  expect_equal(unname(julia_sd_coef), unname(native_sd_coef),
               tolerance = 1e-4)
  expect_lt(abs(unname(julia_sd_coef[["z"]]) - fx$alpha[["z"]]), 0.4)

  native_mu <- coef(native, dpar = "mu")
  julia_mu <- coef(julia, dpar = "mu")
  expect_named(julia_mu, names(native_mu))
  expect_equal(unname(julia_mu), unname(native_mu), tolerance = 1e-4)

  expect_equal(as.numeric(logLik(julia)), as.numeric(logLik(native)),
               tolerance = 1e-3)

  native_sd <- predict(native, dpar = dpar)
  julia_sd <- predict(julia, dpar = dpar)
  names(native_sd) <- sub("^sd_animal\\(id\\):", "", names(native_sd))
  names(julia_sd) <- sub("^sd_animal\\(id\\):", "", names(julia_sd))
  expect_setequal(names(julia_sd), names(native_sd))
  expect_equal(unname(julia_sd[names(native_sd)]), unname(native_sd),
               tolerance = 1e-4)
  # Predictions follow the fitted SD coefficients and the group predictor by
  # level name, not by position.
  expected_sd <- exp(julia_sd_coef[["(Intercept)"]] +
    julia_sd_coef[["z"]] * fx$z_id[names(julia_sd)])
  expect_equal(unname(julia_sd), unname(expected_sd), tolerance = 1e-8)
  invisible(julia)
}

skip_unless_live_julia_poisson_slope <- function(.env = parent.frame()) {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path, .local_envir = .env)
  drm_test_local_julia_home(.local_envir = .env)
}

test_that("Poisson animal-slope Ainv and pedigree payloads are aligned for Julia", {
  fx <- poisson_slope_bridge_ainv_fixture()
  Ainv <- fx$Ainv
  formula <- bf(
    y ~ x + animal(0 + x | id, Ainv = Ainv),
    sd(id, level = "animal") ~ z
  )
  expect_true(drm_julia_poisson_animal_sd_slope_route_admitted(formula))
  payload <- drm_julia_structured_payload(
    formula, "poisson", fx$data, environment()
  )
  first_seen <- unique(as.character(fx$data$id))
  expect_false(identical(first_seen, rownames(Ainv)))
  idx <- match(first_seen, rownames(Ainv))
  expect_identical(payload$kwarg, "Ainv")
  expect_equal(unname(payload$matrix),
               unname(Ainv[idx, idx, drop = FALSE]), tolerance = 0)

  fp <- poisson_slope_bridge_pedigree_fixture()
  pedigree <- fp$pedigree
  formula_ped <- bf(
    y ~ x + animal(0 + x | id, pedigree = pedigree),
    sd(id, level = "animal") ~ z
  )
  expect_true(drm_julia_poisson_animal_sd_slope_route_admitted(formula_ped))
  payload_ped <- drm_julia_structured_payload(
    formula_ped, "poisson", fp$data, environment()
  )
  first_seen_ped <- unique(as.character(fp$data$id))
  expect_false(identical(first_seen_ped, rownames(fp$A)))
  idx_ped <- match(first_seen_ped, rownames(fp$A))
  expect_identical(payload_ped$kwarg, "A")
  expect_equal(unname(payload_ped$matrix),
               unname(fp$A[idx_ped, idx_ped, drop = FALSE]), tolerance = 0)
  expect_equal(max(diag(payload_ped$matrix)), 1.25, tolerance = 1e-12)
})

test_that("Poisson animal slope SD with Ainv agrees across TMB and Julia", {
  skip_unless_live_julia_poisson_slope()
  fx <- poisson_slope_bridge_ainv_fixture()
  Ainv <- fx$Ainv
  formula <- bf(
    y ~ x + animal(0 + x | id, Ainv = Ainv),
    sd(id, level = "animal") ~ z
  )
  julia <- expect_poisson_slope_bridge_parity(formula, fx)
  expect_identical(julia$bridge_payload$kwarg, "Ainv")
})

test_that("Poisson animal slope SD with a pedigree agrees across TMB and Julia", {
  skip_unless_live_julia_poisson_slope()
  fx <- poisson_slope_bridge_pedigree_fixture()
  pedigree <- fx$pedigree
  formula <- bf(
    y ~ x + animal(0 + x | id, pedigree = pedigree),
    sd(id, level = "animal") ~ z
  )
  julia <- expect_poisson_slope_bridge_parity(formula, fx)
  expect_identical(julia$bridge_payload$kwarg, "A")
})
