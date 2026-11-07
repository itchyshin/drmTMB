# Batch 28: DRM.jl uses a relmat K AS SUPPLIED (raw) on every Poisson, NB2 and
# Gamma relmat route, as native drmTMB does. The bridge's old refusal of a
# non-unit-diagonal K on the Poisson relmat slope SD route is therefore gone.
# Tolerances were fixed before the live runs: coefficients (every block) within
# 1e-3 absolute, logLik within 1e-2 absolute, native TMB (se = FALSE) as the
# comparator on the same fixture. One fixture per route; no SE, coverage or
# broad parity claim. Phylo stays on the correlation form (not tested here).

test_that("the Poisson relmat slope SD route no longer refuses a non-unit K", {
  id_levels <- paste0("id", 1:4)
  K <- diag(c(1.5, 0.7, 2, 1))
  dimnames(K) <- list(id_levels, id_levels)
  data <- data.frame(
    id = factor(rep(id_levels, each = 2L), levels = id_levels),
    x = rep(c(-1, 1), 4L),
    z = rep(c(-1, 1), each = 4L),
    y = c(0L, 1L, 2L, 0L, 1L, 3L, 0L, 1L)
  )
  slope <- bf(
    y ~ x + relmat(0 + x | id, K = K),
    sd(id, level = "relmat") ~ z
  )
  payload <- NULL
  expect_no_error(
    payload <- drm_julia_structured_payload(slope, "poisson", data, environment())
  )
  expect_equal(unname(payload$matrix), unname(K))  # sent as supplied, not rescaled
  expect_false(any(grepl(
    "unit-diagonal", deparse(body(drm_julia_structured_payload)), fixed = TRUE
  )))
  # Intercept routes for the three count families also send K unchanged.
  for (fam in c("poisson", "nbinom2", "gamma")) {
    intercept <- bf(y ~ x + relmat(1 | id, K = K))
    d <- data
    if (identical(fam, "gamma")) d$y <- d$y + 0.5
    expect_no_error(
      p <- drm_julia_structured_payload(intercept, fam, d, environment())
    )
    expect_equal(unname(p$matrix), unname(K))
  }
})

b28_compare <- function(julia, native, label, tol_coef = 1e-3, tol_ll = 1e-2) {
  expect_equal(native$opt$convergence, 0L)
  expect_equal(julia$opt$convergence, 0L)
  dpars <- names(coef(native))
  expect_gte(length(dpars), 1L)
  diffs <- list()
  for (dpar in dpars) {
    nc <- coef(native, dpar = dpar)
    jc <- coef(julia, dpar = dpar)
    expect_named(jc, names(nc))
    diffs[[dpar]] <- max(abs(unname(jc) - unname(nc)))
    expect_lt(diffs[[dpar]], tol_coef, label = paste(label, "coef diff", dpar))
  }
  ll <- abs(as.numeric(logLik(julia)) - as.numeric(logLik(native)))
  expect_lt(ll, tol_ll, label = paste(label, "logLik diff"))
  message(
    "B28 ", label, ": ",
    paste(names(diffs), signif(unlist(diffs), 3), collapse = "; "),
    "; logLik diff ", signif(ll, 3),
    "; logLik native ", signif(as.numeric(logLik(native)), 8),
    " julia ", signif(as.numeric(logLik(julia)), 8)
  )
  invisible(list(coef = diffs, ll = ll))
}

b28_live_setup <- function(.local_envir = parent.frame()) {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path, .local_envir = .local_envir)
  drm_test_local_julia_home(.local_envir = .local_envir)
}

# Non-unit-diagonal K (diagonal about 0.45 to 2.6), correlated off-diagonals.
b28_fixture <- function(seed, n_group = 40L, n_each = 16L) {
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
  z_group <- sample(rep(c(-1, 1), length.out = n_group))
  dat$z <- z_group[as.integer(dat$id)]
  u <- as.vector(t(chol(K)) %*% stats::rnorm(n_group))
  list(K = K, dat = dat, u = u, z_group = z_group)
}

b28_draw_y <- function(fam, eta, n) {
  switch(fam,
    poisson = stats::rpois(n, exp(eta)),
    nbinom2 = stats::rnbinom(n, size = 1 / 0.42^2, mu = exp(eta)),
    gamma = stats::rgamma(n, shape = 1 / 0.35^2, rate = (1 / 0.35^2) / exp(eta))
  )
}

b28_family <- function(fam) {
  switch(fam, poisson = stats::poisson(), nbinom2 = nbinom2(),
         gamma = Gamma(link = "log"))
}

for (fam in c("poisson", "nbinom2", "gamma")) {
  local({
    fam <- fam
    test_that(paste("relmat intercept agrees across engines, non-unit K:", fam), {
      b28_live_setup()
      fx <- b28_fixture(20261108L + nchar(fam))
      dat <- fx$dat
      K <- fx$K  # the formula needs a named object
      dat$y <- b28_draw_y(fam, 0.3 + 0.2 * dat$x + 0.4 * fx$u[as.integer(dat$id)],
                          nrow(dat))
      form <- bf(y ~ x + relmat(1 | id, K = K))
      native <- drmTMB(form, family = b28_family(fam), data = dat,
                       engine = "tmb", control = drm_control(se = FALSE))
      julia <- drmTMB(form, family = b28_family(fam), data = dat,
                      engine = "julia")
      b28_compare(julia, native, paste(fam, "relmat intercept"))
    })

    test_that(paste("relmat slope-only SD agrees across engines, non-unit K:", fam), {
      b28_live_setup()
      fx <- b28_fixture(20261109L + nchar(fam))
      dat <- fx$dat
      K <- fx$K  # the formula needs a named object
      sd_g <- exp(log(0.5) + 0.5 * fx$z_group)
      slope <- (sd_g * fx$u)[as.integer(dat$id)]
      dat$y <- b28_draw_y(fam, 0.3 + 0.2 * dat$x + dat$x * slope, nrow(dat))
      form <- bf(
        y ~ x + relmat(0 + x | id, K = K),
        sd(id, level = "relmat") ~ z
      )
      native <- drmTMB(form, family = b28_family(fam), data = dat,
                       engine = "tmb", control = drm_control(se = FALSE))
      julia <- drmTMB(form, family = b28_family(fam), data = dat,
                      engine = "julia")
      b28_compare(julia, native, paste(fam, "relmat slope SD"))
    })
  })
}
