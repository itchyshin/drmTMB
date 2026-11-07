# Native Bernoulli probit and cloglog evidence for the structured provider pair
#   animal(1 | animal_id, A | Ainv | pedigree) + spatial(1 | site, coords)
# each with its own predictor-dependent SD. The logit versions with Ainv and
# pedigree are in test-binomial-phylo-spatial-sd.R; the existing non-logit
# animal-plus-spatial test (test-binomial-animal-spatial-nonlogit-pair-sd.R)
# uses the dense A input only and has no likelihood oracle.
#
# Oracle: a dense Laplace approximation written in plain R. For
#   eta = X beta + Z u,  u ~ N(0, Sigma),  Sigma = blockdiag(D_k C_k D_k),
# the Laplace marginal log-likelihood is
#   l(u*) - u*' Sigma^-1 u* / 2 - log|I + Sigma Z' W Z| / 2,
# with W = -d2 l / d eta2 (observed). It is built from the dense A and the
# spatial covariance with the fitted mean and SD coefficients, so it does not
# use the Ainv or pedigree code paths under test, nor the TMB template.
# The spatial covariance is solve() of drm_spatial_coords_precision(), the
# same helper the existing spatial tests use to simulate; it is not an
# independent construction of the kernel.
#
# Tolerances are fixed before the first run:
#   dense oracle logLik          abs < 1e-4
#   Ainv / pedigree vs dense A   logLik abs < 1e-5, SD coefficients abs < 1e-3
#   constant-SD equivalence      logLik abs < 1e-5, log SD abs < 1e-3,
#                                mean coefficients abs < 1e-3
#   SD-slope sign                strictly positive for both SD slopes
#   max |gradient|               < 2e-2
#   predict() vs coefficients    1e-8

b4_derivatives <- function(y, eta, link) {
  if (identical(link, "probit")) {
    p <- stats::pnorm(eta)
    p1 <- stats::dnorm(eta)
    p2 <- -eta * p1
  } else {
    e <- exp(eta)
    p <- -expm1(-e)
    p1 <- e * exp(-e)
    p2 <- p1 * (1 - e)
  }
  list(
    l = y * log(p) + (1 - y) * log1p(-p),
    d1 = p1 * (y - p) / (p * (1 - p)),
    d2 = p2 * (y - p) / (p * (1 - p)) -
      p1^2 * (y / p^2 + (1 - y) / (1 - p)^2)
  )
}

# blocks: list of list(Z = n x m indicator matrix, Sigma = m x m covariance).
b4_dense_laplace <- function(y, eta_fixed, blocks, link) {
  Z <- do.call(cbind, lapply(blocks, `[[`, "Z"))
  m <- ncol(Z)
  Sigma <- matrix(0, m, m)
  at <- 0L
  for (block in blocks) {
    k <- ncol(block$Z)
    Sigma[at + seq_len(k), at + seq_len(k)] <- block$Sigma
    at <- at + k
  }
  Sigma_inv <- solve(Sigma)
  penalised <- function(u) {
    sum(b4_derivatives(y, eta_fixed + drop(Z %*% u), link)$l) -
      0.5 * drop(crossprod(u, Sigma_inv %*% u))
  }
  u <- numeric(m)
  for (iteration in seq_len(200L)) {
    d <- b4_derivatives(y, eta_fixed + drop(Z %*% u), link)
    gradient <- drop(crossprod(Z, d$d1)) - drop(Sigma_inv %*% u)
    hessian <- crossprod(Z, Z * (-d$d2)) + Sigma_inv
    step <- drop(solve(hessian, gradient))
    scale <- 1
    while (penalised(u + scale * step) < penalised(u) - 1e-12 && scale > 1e-8) {
      scale <- scale / 2
    }
    u <- u + scale * step
    if (max(abs(gradient)) < 1e-10) break
  }
  d <- b4_derivatives(y, eta_fixed + drop(Z %*% u), link)
  W <- -d$d2
  log_det <- as.numeric(determinant(
    diag(m) + Sigma %*% crossprod(Z, Z * W), logarithm = TRUE
  )$modulus)
  sum(d$l) - 0.5 * drop(crossprod(u, Sigma_inv %*% u)) - 0.5 * log_det
}

b4_indicator <- function(index, n_level) {
  Z <- matrix(0, length(index), n_level)
  Z[cbind(seq_along(index), index)] <- 1
  Z
}

b4_animal_spatial_fixture <- function(link, seed) {
  set.seed(seed)
  n_family <- 10L
  n_offspring <- 4L
  n_site <- 30L
  sires <- paste0("sire_", seq_len(n_family))
  dams <- paste0("dam_", seq_len(n_family))
  offspring <- paste0("offspring_", seq_len(n_family * n_offspring))
  pedigree <- data.frame(
    id = c(sires, dams, offspring),
    dam = c(rep(NA_character_, 2L * n_family), rep(dams, each = n_offspring)),
    sire = c(rep(NA_character_, 2L * n_family), rep(sires, each = n_offspring)),
    stringsAsFactors = FALSE
  )
  A_base <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  animal_levels <- rownames(A_base)
  n_animal <- length(animal_levels)
  animal_order <- rev(seq_len(n_animal))
  A <- A_base[animal_order, animal_order, drop = FALSE]

  site_levels <- paste0("site_", seq_len(n_site))
  coords <- cbind(
    east = seq(0, 1, length.out = n_site),
    north = cos(seq(0, 2 * pi, length.out = n_site))
  )
  rownames(coords) <- site_levels
  spatial_precision <- drmTMB:::drm_spatial_coords_precision(
    coords, site = site_levels, group = "site"
  )
  spatial_cov <- solve(as.matrix(spatial_precision$precision))
  dimnames(spatial_cov) <- list(site_levels, site_levels)

  z_animal <- stats::setNames(
    seq(-1, 1, length.out = n_animal)[sample.int(n_animal)], animal_levels
  )
  z_site <- stats::setNames(
    seq(-1, 1, length.out = n_site)[sample.int(n_site)], site_levels
  )
  alpha_animal <- c(`(Intercept)` = log(0.60), z_animal = 0.5)
  alpha_spatial <- c(`(Intercept)` = log(0.55), z_site = 0.5)
  animal_field_order <- as.vector(t(chol(A)) %*% stats::rnorm(n_animal)) *
    exp(alpha_animal[[1L]] + alpha_animal[[2L]] * z_animal[rownames(A)])
  names(animal_field_order) <- rownames(A)
  animal_field <- animal_field_order[animal_levels]
  site_field <- as.vector(t(chol(spatial_cov)) %*% stats::rnorm(n_site)) *
    exp(alpha_spatial[[1L]] + alpha_spatial[[2L]] * z_site)
  names(site_field) <- site_levels

  design <- expand.grid(
    replicate = seq_len(2L),
    animal_index = seq_len(n_animal),
    site_index = seq_len(n_site)
  )
  x <- stats::rnorm(nrow(design))
  eta <- -0.1 + 0.3 * x +
    animal_field[animal_levels[design$animal_index]] +
    site_field[site_levels[design$site_index]]
  inverse_link <- stats::make.link(link)$linkinv
  dat <- data.frame(
    y = stats::rbinom(nrow(design), 1L, inverse_link(eta)),
    x = x,
    animal_id = factor(animal_levels[design$animal_index],
                       levels = rev(animal_levels)),
    site = factor(site_levels[design$site_index], levels = site_levels),
    z_animal = unname(z_animal[animal_levels[design$animal_index]]),
    z_site = unname(z_site[site_levels[design$site_index]])
  )
  list(
    data = dat, coords = coords, pedigree = pedigree, A = A,
    Ainv = solve(A), spatial_cov = spatial_cov,
    animal_levels = animal_levels, site_levels = site_levels,
    z_animal = z_animal, z_site = z_site
  )
}

# The provider pair needs both SD formulas, so `constant = TRUE` uses
# intercept-only SD formulas (the pair has no SD-free form).
b4_fit <- function(fx, link, provider, constant = FALSE) {
  coords <- fx$coords
  A <- fx$A
  Ainv <- fx$Ainv
  pedigree <- fx$pedigree
  animal_rhs <- switch(
    provider,
    A = quote(animal(1 | animal_id, A = A)),
    Ainv = quote(animal(1 | animal_id, Ainv = Ainv)),
    pedigree = quote(animal(1 | animal_id, pedigree = pedigree))
  )
  mean_formula <- stats::as.formula(
    bquote(y ~ x + .(animal_rhs) + spatial(1 | site, coords = coords)),
    env = environment()
  )
  formula <- if (constant) {
    bf(
      mean_formula,
      sd(animal_id, level = "animal") ~ 1,
      sd(site, level = "spatial") ~ 1
    )
  } else {
    bf(
      mean_formula,
      sd(animal_id, level = "animal") ~ z_animal,
      sd(site, level = "spatial") ~ z_site
    )
  }
  drmTMB(
    formula, family = stats::binomial(link = link), data = fx$data,
    control = drm_control(se = FALSE)
  )
}

b4_sd_curve <- function(coef, z) exp(coef[[1L]] + coef[[2L]] * z)

test_that("Binomial probit and cloglog animal (A, Ainv, pedigree) plus spatial SDs match a dense Laplace oracle", {
  skip_on_cran()
  for (link in c("probit", "cloglog")) {
    fx <- b4_animal_spatial_fixture(
      link, if (link == "probit") 20261401L else 20261402L
    )
    fits <- list(
      A = b4_fit(fx, link, "A"),
      Ainv = b4_fit(fx, link, "Ainv"),
      pedigree = b4_fit(fx, link, "pedigree")
    )

    for (nm in names(fits)) {
      fit <- fits[[nm]]
      info <- paste(link, nm)
      expect_identical(fit$opt$convergence, 0L, info = info)
      expect_true(max(abs(fit$obj$gr(fit$opt$par))) < 2e-2, info = info)
      expect_setequal(names(coef(fit)),
                      c("mu", "sd_animal(animal_id)", "sd_spatial(site)"))
      expect_gt(coef(fit, "sd_animal(animal_id)")[["z_animal"]], 0)
      expect_gt(coef(fit, "sd_spatial(site)")[["z_site"]], 0)

      animal_sd <- predict(fit, dpar = "sd_animal(animal_id)")
      site_sd <- predict(fit, dpar = "sd_spatial(site)")
      expect_equal(
        animal_sd[fx$animal_levels],
        b4_sd_curve(coef(fit, "sd_animal(animal_id)"), fx$z_animal),
        tolerance = 1e-8, info = info
      )
      expect_equal(
        site_sd[fx$site_levels],
        b4_sd_curve(coef(fit, "sd_spatial(site)"), fx$z_site),
        tolerance = 1e-8, info = info
      )

      mu <- coef(fit, "mu")
      D_animal <- animal_sd[rownames(fx$A)]
      D_site <- site_sd[fx$site_levels]
      blocks <- list(
        list(Z = b4_indicator(
               match(as.character(fx$data$animal_id), rownames(fx$A)),
               nrow(fx$A)),
             Sigma = outer(D_animal, D_animal) * fx$A),
        list(Z = b4_indicator(as.integer(fx$data$site),
                              length(fx$site_levels)),
             Sigma = outer(D_site, D_site) * fx$spatial_cov)
      )
      dense <- b4_dense_laplace(
        fx$data$y, mu[[1L]] + mu[[2L]] * fx$data$x, blocks, link
      )
      expect_lt(abs(as.numeric(logLik(fit)) - dense), 1e-4, label = info)
    }

    for (nm in c("Ainv", "pedigree")) {
      fit <- fits[[nm]]
      info <- paste(link, nm, "vs A")
      expect_lt(abs(as.numeric(logLik(fit)) - as.numeric(logLik(fits$A))),
                1e-5, label = info)
      expect_equal(coef(fit, "sd_animal(animal_id)"),
                   coef(fits$A, "sd_animal(animal_id)"),
                   tolerance = 1e-3, info = info)
      expect_equal(coef(fit, "sd_spatial(site)"),
                   coef(fits$A, "sd_spatial(site)"),
                   tolerance = 1e-3, info = info)
    }

    simulated <- simulate(fits$Ainv, nsim = 1L, seed = 20261403L)
    expect_true(all(simulated[[1L]] %in% c(0, 1)), info = link)
  }
})

test_that("Binomial probit and cloglog animal plus spatial constant SDs agree across A, Ainv and pedigree and match a dense oracle", {
  skip_on_cran()
  for (link in c("probit", "cloglog")) {
    fx <- b4_animal_spatial_fixture(
      link, if (link == "probit") 20261404L else 20261405L
    )
    fit_a <- b4_fit(fx, link, "A", constant = TRUE)
    expect_identical(fit_a$opt$convergence, 0L, info = link)
    for (provider in c("Ainv", "pedigree")) {
      info <- paste(link, provider)
      fit <- b4_fit(fx, link, provider, constant = TRUE)
      expect_identical(fit$opt$convergence, 0L, info = info)
      expect_lt(abs(as.numeric(logLik(fit)) - as.numeric(logLik(fit_a))),
                1e-5, label = info)
      expect_equal(coef(fit, "mu"), coef(fit_a, "mu"),
                   tolerance = 1e-3, info = info)
      expect_equal(coef(fit, "sd_animal(animal_id)"),
                   coef(fit_a, "sd_animal(animal_id)"),
                   tolerance = 1e-3, info = info)
      expect_equal(coef(fit, "sd_spatial(site)"),
                   coef(fit_a, "sd_spatial(site)"),
                   tolerance = 1e-3, info = info)

      animal_sd <- exp(coef(fit, "sd_animal(animal_id)")[["(Intercept)"]])
      site_sd <- exp(coef(fit, "sd_spatial(site)")[["(Intercept)"]])
      mu <- coef(fit, "mu")
      blocks <- list(
        list(Z = b4_indicator(
               match(as.character(fx$data$animal_id), rownames(fx$A)),
               nrow(fx$A)),
             Sigma = animal_sd^2 * fx$A),
        list(Z = b4_indicator(as.integer(fx$data$site),
                              length(fx$site_levels)),
             Sigma = site_sd^2 * fx$spatial_cov)
      )
      dense <- b4_dense_laplace(
        fx$data$y, mu[[1L]] + mu[[2L]] * fx$data$x, blocks, link
      )
      expect_lt(abs(as.numeric(logLik(fit)) - dense), 1e-4, label = info)
    }
  }
})
