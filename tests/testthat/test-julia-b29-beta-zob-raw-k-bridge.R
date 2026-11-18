# Batch 29: DRM.jl uses a relmat K / animal A AS SUPPLIED (raw) for Beta and
# ZeroOneBeta intercepts and for the Beta animal SD route, as native drmTMB does
# (DRModels.jl commit d5e3e6b11). Phylo stays on the correlation form (not tested here).
#
# Boundary: the drmTMB R bridge (`engine = "julia"`) does not route structured
# terms for beta_family() or zero_one_beta() at all (drm_julia_structured_family_tag()
# aborts), so there is no bridge refusal of a non-unit-diagonal K to remove. The live
# parity below therefore calls the Julia engine directly through JuliaCall on the
# same data and the same K, and compares it with native TMB (se = FALSE).
# Tolerances were fixed before the live runs: every coefficient (mu, sigma, log SD,
# SD regression, zoi, coi) within 1e-3 absolute, logLik within 1e-2 absolute.
# One fixture per route; no SE, coverage or broad parity claim.

test_that("the bridge still refuses Beta/ZeroOneBeta structured terms (no K-scale refusal exists)", {
  id_levels <- paste0("id", 1:4)
  K <- diag(c(1.5, 0.7, 2, 1))
  dimnames(K) <- list(id_levels, id_levels)
  for (fam in c("beta", "zero_one_beta")) {
    err <- tryCatch(
      drmTMB:::drm_julia_structured_family_tag(fam),
      error = function(e) conditionMessage(e)
    )
    expect_type(err, "character")
    expect_false(grepl("unit", err, fixed = TRUE))
    expect_false(grepl("diagonal", err, fixed = TRUE))
  }
  src <- paste(deparse(body(drmTMB:::drm_julia_structured_payload)), collapse = "\n")
  expect_false(grepl("unit-diagonal", src, fixed = TRUE))
})

b29_live_setup <- function(.local_envir = parent.frame()) {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path, .local_envir = .local_envir)
  drm_test_local_julia_home(.local_envir = .local_envir)
  drmTMB:::drm_julia_setup()
  JuliaCall::julia_command("using Main.drmTMB_backend")
}

# Non-unit-diagonal K (diagonal about 0.45 to 2.6), correlated off-diagonals.
# Rows are in K order, so Julia's first-seen group order equals the K order.
b29_fixture <- function(seed, n_group = 30L, n_each = 12L, sd_scale = 0.7) {
  set.seed(seed)
  id_levels <- paste0("g", seq_len(n_group))
  d <- sqrt(seq(0.45, 2.6, length.out = n_group))
  corr <- outer(seq_len(n_group), seq_len(n_group), function(i, j) 0.4^abs(i - j))
  K <- diag(d) %*% corr %*% diag(d)
  dimnames(K) <- list(id_levels, id_levels)
  stopifnot(any(abs(diag(K) - 1) > 0.3))
  dat <- data.frame(
    id = factor(rep(id_levels, each = n_each), levels = id_levels),
    x = rep(seq(-1, 1, length.out = n_each), n_group)
  )
  z_group <- rep(c(-1, 1), length.out = n_group)
  dat$z <- z_group[as.integer(dat$id)]
  u <- as.vector(t(chol(K)) %*% stats::rnorm(n_group))
  list(K = K, dat = dat, u = u, z_group = z_group, sd_scale = sd_scale)
}

b29_draw_beta <- function(eta) {
  mu <- stats::plogis(eta)
  phi <- 1 / 0.35^2
  pmin(pmax(stats::rbeta(length(mu), mu * phi, (1 - mu) * phi), 1e-6), 1 - 1e-6)
}

# Fit through the Julia engine directly (not the bridge) and return
# c(coef(fit), logLik).
b29_julia_fit <- function(dat, K, formula_src, family_src) {
  JuliaCall::julia_assign("b29_y", dat$y)
  JuliaCall::julia_assign("b29_x", dat$x)
  JuliaCall::julia_assign("b29_z", dat$z)
  JuliaCall::julia_assign("b29_g", as.character(dat$id))
  JuliaCall::julia_assign("b29_K", unname(K))
  kw <- if (grepl("animal", formula_src, fixed = TRUE)) "A" else "K"
  code <- paste0(
    "let f = drm(", formula_src, ", ", family_src,
    "; data = (; y = b29_y, x = b29_x, z = b29_z, g = b29_g), ", kw,
    " = b29_K, se = false); vcat(coef(f), f.loglik) end"
  )
  JuliaCall::julia_eval(code)
}

b29_compare <- function(jl, native_vec, native_ll, label, tol_coef = 1e-3, tol_ll = 1e-2) {
  expect_equal(length(jl) - 1L, length(native_vec))
  d <- max(abs(jl[seq_along(native_vec)] - native_vec))
  ll <- abs(jl[length(jl)] - native_ll)
  expect_lt(d, tol_coef, label = paste(label, "max coef diff"))
  expect_lt(ll, tol_ll, label = paste(label, "logLik diff"))
  message("B29 ", label, ": max coef diff ", signif(d, 3), "; logLik diff ",
          signif(ll, 3), "; logLik native ", signif(native_ll, 8))
  invisible(list(coef = d, ll = ll))
}

for (marker in c("relmat", "animal")) {
  local({
    marker <- marker
    karg <- if (marker == "relmat") "K" else "A"

    test_that(paste("Beta", marker, "intercept agrees across engines, non-unit K"), {
      b29_live_setup()
      fx <- b29_fixture(20261110L)
      dat <- fx$dat
      K <- fx$K  # the formula needs a named object
      dat$y <- b29_draw_beta(0.2 + 0.3 * dat$x + fx$sd_scale * fx$u[as.integer(dat$id)])
      form <- if (marker == "relmat") bf(y ~ x + relmat(1 | id, K = K)) else
        bf(y ~ x + animal(1 | id, A = K))
      native <- drmTMB(form, family = beta_family(), data = dat, engine = "tmb",
                       control = drm_control(se = FALSE))
      expect_equal(native$opt$convergence, 0L)
      nvec <- c(coef(native, dpar = "mu"), coef(native, dpar = "sigma"),
                log(unname(native$sdpars$mu)))
      src <- paste0("bf(@formula(y ~ x + ", marker, "(1 | g)), @formula(sigma ~ 1))")
      jl <- b29_julia_fit(dat, K, src, "Beta()")
      b29_compare(jl, unname(nvec), as.numeric(logLik(native)),
                  paste("Beta", marker, "intercept"))
    })

    test_that(paste("ZeroOneBeta", marker, "intercept agrees across engines, non-unit K"), {
      b29_live_setup()
      fx <- b29_fixture(20261111L)
      dat <- fx$dat
      K <- fx$K
      dat$y <- b29_draw_beta(0.2 + 0.3 * dat$x + fx$sd_scale * fx$u[as.integer(dat$id)])
      atom <- stats::runif(nrow(dat)) < 0.15
      dat$y[atom] <- stats::rbinom(sum(atom), 1, 0.45)
      Ainv <- solve(K)  # native zero_one_beta() takes the animal precision, Ainv = A^-1
      dimnames(Ainv) <- dimnames(K)
      form <- if (marker == "relmat")
        bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1, zoi ~ 1, coi ~ 1) else
        bf(y ~ x + animal(1 | id, Ainv = Ainv), sigma ~ 1, zoi ~ 1, coi ~ 1)
      native <- drmTMB(form, family = zero_one_beta(), data = dat, engine = "tmb",
                       control = drm_control(se = FALSE))
      expect_equal(native$opt$convergence, 0L)
      nvec <- c(coef(native, dpar = "mu"), coef(native, dpar = "sigma"),
                log(unname(native$sdpars$mu)),
                coef(native, dpar = "zoi"), coef(native, dpar = "coi"))
      src <- paste0("bf(@formula(y ~ x + ", marker, "(1 | g)), @formula(sigma ~ 1), ",
                    "@formula(zoi ~ 1), @formula(coi ~ 1))")
      jl <- b29_julia_fit(dat, K, src, "ZeroOneBeta()")
      b29_compare(jl, unname(nvec), as.numeric(logLik(native)),
                  paste("ZeroOneBeta", marker, "intercept"))
    })
  })
}

test_that("Beta animal sd(id, animal) ~ z agrees across engines, non-unit A", {
  b29_live_setup()
  fx <- b29_fixture(20261112L)
  dat <- fx$dat
  A <- fx$K
  sd_g <- exp(log(0.5) + 0.5 * fx$z_group)
  dat$y <- b29_draw_beta(0.2 + 0.3 * dat$x + (sd_g * fx$u)[as.integer(dat$id)])
  form <- bf(y ~ x + animal(1 | id, A = A), sd(id, level = "animal") ~ z)
  native <- drmTMB(form, family = beta_family(), data = dat, engine = "tmb",
                   control = drm_control(se = FALSE))
  expect_equal(native$opt$convergence, 0L)
  nvec <- c(coef(native, dpar = "mu"), coef(native, dpar = "sigma"),
            native$coefficients[["sd_animal(id)"]])
  src <- "bf(@formula(y ~ x + animal(1 | g)), @formula(sigma ~ 1), @formula(sd(g, animal) ~ z))"
  jl <- b29_julia_fit(dat, A, src, "Beta()")
  b29_compare(jl, unname(nvec), as.numeric(logLik(native)), "Beta animal SD ~ z")
})
