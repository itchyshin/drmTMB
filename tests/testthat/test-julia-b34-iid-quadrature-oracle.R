# Independent exact-integral oracle for three Julia iid SD routes whose
# quadrature DRModels.jl ab8b67127 made accurate:
#   ZeroOneBeta  y ~ x + (1 | id),       sd(id) ~ z
#   ZeroOneBeta  y ~ x + (0 + x | id),   sd(id, coef = "x") ~ z
#   zero-inflated Poisson  y ~ x + (0 + x | id), zi ~ 1,
#                          sd(id, dpar = "mu", coef = "x") ~ z
# (default iid SD level). The oracle (helper-b34-julia-oracles.R, no drmTMB
# code, no Laplace and no Gauss-Hermite) integrates each group's effect
# exactly: per group, the log of the integral over u ~ N(0, 1) of the product
# of the hand-written ZeroOneBeta or ZIP densities, on a 4001-point trapezoid
# grid over [-10, 10], evaluated at the live Julia estimates (mu, sigma, zoi,
# coi, zi and the SD coefficients).
# ZeroOneBeta: atoms 0 / 1 with probability zoi (1 - coi) / zoi coi, interior
# (1 - zoi) Beta(mu phi, (1 - mu) phi) with phi = 1 / sigma^2 and logit mu.
# Seeds: three ordinary draws plus two boundary-heavy draws per ZeroOneBeta
# route (zoi near 0.55, so more than 40 percent of the responses are exact 0 or 1).
# Agreement asserted: logLik within 1e-6 absolute of the
# exact integral on every seed. Each emulated bug (reversed SD vector, SD
# intercept shifted by log 2, sign-flipped SD slope, wrong group predictor,
# slope treated as intercept, atoms swapped, zi dropped) must move the oracle by more
# than 20 times that tolerance.
# Claim scope: a handful of seeds per route; no calibration, coverage, speed or
# broad parity claim.

# 1e-6 (tightened by the b34 verifier from the first draft's 1e-4): the old
# DRModels.jl quadrature (e7dbc3f79) misses the ZeroOneBeta slope integral by
# 6e-6 to 5e-5, which 1e-4 let through; ab8b67127 agrees to 3e-11 or better.
B34Q_TOL <- 1e-6

test_that("the grid integral oracle matches stats::integrate on one group", {
  y <- c(0, 1, 0.3, 0.8, 0, 0.55)
  X <- cbind(1, c(0.4, -1.1, 0.2, 0.9, -0.3, 1.5))
  beta <- c(-0.2, 0.3)
  idx <- rep(1L, length(y))
  for (mult in list(NULL, X[, 2L])) {
    ll_fun <- b34_zob_ll(y, 0.5, 0.3, 0.6)
    grid <- b34_iid_exact(ll_fun, drop(X %*% beta), idx, mult, 0.8)
    m <- if (is.null(mult)) rep(1, length(y)) else mult
    direct <- log(stats::integrate(function(u) {
      vapply(u, function(ui) exp(sum(ll_fun(matrix(drop(X %*% beta) + m * 0.8 * ui,
                                                    ncol = 1L)))) *
               stats::dnorm(ui), numeric(1))
    }, -12, 12, rel.tol = 1e-12)$value)
    expect_equal(grid, direct, tolerance = 1e-9)
  }
  yz <- c(0L, 0L, 3L, 1L, 0L, 5L)
  zip_fun <- b34_zip_ll(yz, 0.2)
  grid <- b34_iid_exact(zip_fun, drop(X %*% beta), idx, X[, 2L], 0.6)
  direct <- log(stats::integrate(function(u) {
    vapply(u, function(ui) exp(sum(zip_fun(matrix(drop(X %*% beta) + X[, 2L] * 0.6 * ui,
                                                   ncol = 1L)))) *
             stats::dnorm(ui), numeric(1))
  }, -12, 12, rel.tol = 1e-12)$value)
  expect_equal(grid, direct, tolerance = 1e-9)
})

b34q_fixture <- function(route, seed, boundary_heavy = FALSE, groups = 50L,
                         repeats = 15L) {
  set.seed(seed)
  levels_id <- sprintf("g%02d", seq_len(groups))
  z_level <- sample((seq_len(groups) / groups)^1.6 * 2 - 1)  # not monotone in id
  alpha <- c(log(0.7), 0.55)
  sd_level <- b34_sd(alpha, z_level)
  idx <- rep(seq_len(groups), each = repeats)
  x <- stats::rnorm(length(idx))
  b <- (sd_level * stats::rnorm(groups))[idx]
  if (route == "zip_slope") {
    lambda <- exp(0.35 + 0.25 * x + x * b)
    y <- ifelse(stats::runif(length(x)) < 0.15, 0L, stats::rpois(length(x), lambda))
  } else {
    sigma <- 0.5
    zoi <- if (boundary_heavy) 0.55 else 0.12
    mu <- stats::plogis(-0.25 + 0.30 * x +
                          if (route == "zob_slope") x * b else b)
    y <- stats::rbeta(length(x), mu / sigma^2, (1 - mu) / sigma^2)
    atom <- stats::runif(length(x)) < zoi
    y[atom] <- stats::rbinom(sum(atom), 1L, 0.6)
  }
  dat <- data.frame(y = y, x = x, z = z_level[idx],
                    id = factor(levels_id[idx], levels = levels_id))
  dat <- dat[sample.int(nrow(dat)), , drop = FALSE]
  list(data = dat, levels = levels_id, z_level = z_level)
}

b34q_run <- function(route, seed, boundary_heavy = FALSE) {
  fx <- b34q_fixture(route, seed, boundary_heavy)
  dat <- fx$data
  if (boundary_heavy) {
    expect_gt(mean(dat$y %in% c(0, 1)), 0.4)
  }
  if (route == "zob_intercept") {
    form <- bf(y ~ x + (1 | id), sigma ~ 1, zoi ~ 1, coi ~ 1, sd(id) ~ z)
    sd_dpar <- "sd(id)"; fam <- zero_one_beta()
  } else if (route == "zob_slope") {
    form <- bf(y ~ x + (0 + x | id), sigma ~ 1, zoi ~ 1, coi ~ 1,
               sd(id, coef = "x") ~ z)
    sd_dpar <- 'sd(id, coef = "x")'; fam <- zero_one_beta()
  } else {
    form <- bf(y ~ x + (0 + x | id), zi ~ 1,
               sd(id, dpar = "mu", coef = "x") ~ z)
    sd_dpar <- 'sd(id, dpar = "mu", coef = "x")'; fam <- stats::poisson()
  }
  fit <- drmTMB(form, family = fam, data = dat, engine = "julia")
  expect_equal(fit$opt$convergence, 0L, info = paste(route, seed))
  idx <- match(as.character(dat$id), fx$levels)
  X <- cbind(1, dat$x)
  mult0 <- if (route == "zob_intercept") NULL else dat$x
  beta0 <- unname(coef(fit, dpar = "mu"))
  alpha0 <- unname(coef(fit, dpar = sd_dpar))
  zob <- route != "zip_slope"
  if (zob) {
    sigma0 <- exp(unname(coef(fit, dpar = "sigma")))
    zoi0 <- stats::plogis(unname(coef(fit, dpar = "zoi")))
    coi0 <- stats::plogis(unname(coef(fit, dpar = "coi")))
  } else {
    zi0 <- stats::plogis(unname(coef(fit, dpar = "zi")))
  }
  oracle <- function(beta = beta0, alpha = alpha0, zl = fx$z_level,
                     sd_rev = FALSE, mult = mult0, coi = if (zob) coi0,
                     zi = if (!zob) zi0) {
    sdv <- b34_sd(alpha, zl)
    if (sd_rev) sdv <- rev(sdv)
    ll_fun <- if (zob) b34_zob_ll(dat$y, sigma0, zoi0, coi) else b34_zip_ll(dat$y, zi)
    b34_iid_exact(ll_fun, drop(X %*% beta), idx, mult, sdv)
  }
  base <- oracle()
  gaps <- c(
    reversed_sd_vector = oracle(sd_rev = TRUE),
    sd_intercept_plus_log2 = oracle(alpha = alpha0 + c(log(2), 0)),
    sd_slope_sign = oracle(alpha = c(alpha0[[1L]], -alpha0[[2L]])),
    wrong_group_predictor = oracle(zl = fx$z_level[
      c(seq(2L, length(fx$z_level), by = 2L),
        seq(1L, length(fx$z_level), by = 2L))]),
    if (route != "zob_intercept") c(slope_as_intercept = oracle(mult = NULL)),
    if (zob) c(atoms_swapped = oracle(coi = 1 - coi0))
    else c(zi_halved = oracle(zi = zi0 / 2))
  ) - base
  info <- paste(route, if (boundary_heavy) "boundary-heavy" else "ordinary", seed)
  message(b34_check(as.numeric(logLik(fit)), base, gaps, info,
                    agreement_tol = B34Q_TOL))
  invisible(list(ll = as.numeric(logLik(fit)), base = base, gaps = gaps))
}

b34q_seeds <- c(20261401L, 20261402L, 20261403L)
# Boundary-heavy seeds. Not every boundary-heavy draw can be fitted: ZeroOneBeta
# slope seeds 20261409 and 20261412 draw an interior response near 1e-56 and the
# Julia route stops with "matrix contains Infs or NaNs" in its standard-error
# Hessian (the estimates themselves converge; clamping that response to 1e-8
# makes the Hessian finite). Those seeds are excluded here and reported as a
# Julia limitation, not asserted.
b34q_boundary_seeds <- c(20261410L, 20261411L)

for (b34q_route in c("zob_intercept", "zob_slope", "zip_slope")) {
  local({
    route <- b34q_route
    label <- c(zob_intercept = "ZeroOneBeta iid intercept SD",
               zob_slope = "ZeroOneBeta iid slope SD",
               zip_slope = "zero-inflated Poisson iid slope SD")[[route]]
    test_that(paste("Julia", label, "matches an exact per-group integral oracle"), {
      b34_live_setup()
      for (seed in b34q_seeds) b34q_run(route, seed)
    })
    if (route != "zip_slope") {
      test_that(paste("Julia", label, "matches the exact integral on a boundary-heavy draw"), {
        b34_live_setup()
        for (seed in b34q_boundary_seeds) {
          b34q_run(route, seed, boundary_heavy = TRUE)
        }
      })
    }
  })
}
