# Native Bernoulli probit and cloglog evidence for the structured provider pair
#   phylo(1 | species, tree) + animal(1 | animal_id, Ainv = ...)   [Ainv]
#   phylo(1 | species, tree) + animal(1 | animal_id, pedigree = ...) [pedigree]
# each with its own predictor-dependent SD. The logit versions exist in
# test-binomial-phylo-animal-ainv-sd.R and
# test-binomial-phylo-animal-pedigree-sd.R; the non-logit links used only
# the dense A input.
#
# Oracle: a dense Laplace approximation written in plain R. For
#   eta = X beta + Z u,  u ~ N(0, Sigma),  Sigma = blockdiag(D_k C_k D_k),
# the Laplace marginal log-likelihood is
#   l(u*) - u*' Sigma^-1 u* / 2 - log|I + Sigma Z' W Z| / 2,
# with W = -d2 l / d eta2 (observed). It is built from the dense A and the
# tree covariance with the fitted mean and SD coefficients, so it does not
# use the Ainv or pedigree code paths under test, nor the TMB template.
#
# Tolerances are fixed before the first run:
#   dense oracle logLik          abs < 1e-4
#   Ainv / pedigree vs dense A   logLik abs < 1e-5, SD coefficients abs < 1e-3
#   constant-SD equivalence      logLik abs < 1e-5, log SD abs < 1e-3,
#                                mean coefficients abs < 1e-3
#   SD-slope sign                strictly positive for both SD slopes
#   max |gradient|               < 2e-2

b3_derivatives <- function(y, eta, link) {
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
b3_dense_laplace <- function(y, eta_fixed, blocks, link) {
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
    sum(b3_derivatives(y, eta_fixed + drop(Z %*% u), link)$l) -
      0.5 * drop(crossprod(u, Sigma_inv %*% u))
  }
  u <- numeric(m)
  for (iteration in seq_len(200L)) {
    d <- b3_derivatives(y, eta_fixed + drop(Z %*% u), link)
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
  d <- b3_derivatives(y, eta_fixed + drop(Z %*% u), link)
  W <- -d$d2
  log_det <- as.numeric(determinant(
    diag(m) + Sigma %*% crossprod(Z, Z * W), logarithm = TRUE
  )$modulus)
  sum(d$l) - 0.5 * drop(crossprod(u, Sigma_inv %*% u)) - 0.5 * log_det
}

b3_indicator <- function(index, n_level) {
  Z <- matrix(0, length(index), n_level)
  Z[cbind(seq_along(index), index)] <- 1
  Z
}

b3_phylo_animal_fixture <- function(link, seed) {
  set.seed(seed)
  n_family <- 10L
  n_offspring <- 4L
  n_tip <- 32L
  n_replicate <- 3L
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
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("species_", seq_len(n_tip))
  species_levels <- tree$tip.label
  phylo_cov <- drmTMB:::drm_phylo_tip_covariance(tree)[species_levels,
                                                       species_levels]

  z_animal <- stats::setNames(
    seq(-1, 1, length.out = n_animal)[sample.int(n_animal)], animal_levels
  )
  z_tree <- stats::setNames(
    seq(-1, 1, length.out = n_tip)[sample.int(n_tip)], species_levels
  )
  alpha_animal <- c(`(Intercept)` = log(0.55), z_animal = 0.5)
  alpha_tree <- c(`(Intercept)` = log(0.50), z_tree = 0.5)
  animal_field_order <- as.vector(t(chol(A)) %*% stats::rnorm(n_animal)) *
    exp(alpha_animal[[1L]] +
      alpha_animal[[2L]] * z_animal[rownames(A)])
  names(animal_field_order) <- rownames(A)
  animal_field <- animal_field_order[animal_levels]
  tree_field <- as.vector(t(chol(phylo_cov)) %*% stats::rnorm(n_tip)) *
    exp(alpha_tree[[1L]] + alpha_tree[[2L]] * z_tree)
  names(tree_field) <- species_levels

  design <- expand.grid(
    replicate = seq_len(n_replicate),
    animal_index = seq_len(n_animal),
    tip_index = seq_len(n_tip)
  )
  x <- stats::rnorm(nrow(design))
  eta <- -0.1 + 0.3 * x +
    animal_field[animal_levels[design$animal_index]] +
    tree_field[species_levels[design$tip_index]]
  inverse_link <- stats::make.link(link)$linkinv
  dat <- data.frame(
    y = stats::rbinom(nrow(design), 1L, inverse_link(eta)),
    x = x,
    animal_id = factor(animal_levels[design$animal_index],
                       levels = rev(animal_levels)),
    species = factor(species_levels[design$tip_index], levels = species_levels),
    z_animal = unname(z_animal[animal_levels[design$animal_index]]),
    z_tree = unname(z_tree[species_levels[design$tip_index]])
  )
  list(
    data = dat, tree = tree, pedigree = pedigree, A = A,
    Ainv = solve(A), phylo_cov = phylo_cov,
    animal_levels = animal_levels, species_levels = species_levels,
    z_animal = z_animal, z_tree = z_tree
  )
}

# The provider pair needs both SD formulas, so `constant = TRUE` uses
# intercept-only SD formulas (the pair has no SD-free form).
b3_fit <- function(fx, link, provider, constant = FALSE) {
  tree <- fx$tree
  A <- fx$A
  Ainv <- fx$Ainv
  pedigree <- fx$pedigree
  formula <- switch(
    paste(provider, constant),
    "A FALSE" = bf(
      y ~ x + phylo(1 | species, tree = tree) + animal(1 | animal_id, A = A),
      sd(species, level = "phylogenetic") ~ z_tree,
      sd(animal_id, level = "animal") ~ z_animal
    ),
    "Ainv FALSE" = bf(
      y ~ x + phylo(1 | species, tree = tree) +
        animal(1 | animal_id, Ainv = Ainv),
      sd(species, level = "phylogenetic") ~ z_tree,
      sd(animal_id, level = "animal") ~ z_animal
    ),
    "pedigree FALSE" = bf(
      y ~ x + phylo(1 | species, tree = tree) +
        animal(1 | animal_id, pedigree = pedigree),
      sd(species, level = "phylogenetic") ~ z_tree,
      sd(animal_id, level = "animal") ~ z_animal
    ),
    "A TRUE" = bf(
      y ~ x + phylo(1 | species, tree = tree) + animal(1 | animal_id, A = A),
      sd(species, level = "phylogenetic") ~ 1,
      sd(animal_id, level = "animal") ~ 1
    ),
    "Ainv TRUE" = bf(
      y ~ x + phylo(1 | species, tree = tree) +
        animal(1 | animal_id, Ainv = Ainv),
      sd(species, level = "phylogenetic") ~ 1,
      sd(animal_id, level = "animal") ~ 1
    ),
    "pedigree TRUE" = bf(
      y ~ x + phylo(1 | species, tree = tree) +
        animal(1 | animal_id, pedigree = pedigree),
      sd(species, level = "phylogenetic") ~ 1,
      sd(animal_id, level = "animal") ~ 1
    )
  )
  drmTMB(
    formula, family = stats::binomial(link = link), data = fx$data,
    control = drm_control(se = FALSE)
  )
}

b3_sd_curve <- function(coef, z) exp(coef[[1L]] + coef[[2L]] * z)

test_that("Binomial probit and cloglog phylo plus animal (A, Ainv, pedigree) SDs match a dense Laplace oracle", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (link in c("probit", "cloglog")) {
    fx <- b3_phylo_animal_fixture(
      link, if (link == "probit") 20261301L else 20261302L
    )
    fit_a <- b3_fit(fx, link, "A")
    fit_ainv <- b3_fit(fx, link, "Ainv")
    fit_ped <- b3_fit(fx, link, "pedigree")

    for (nm in c("A", "Ainv", "pedigree")) {
      fit <- list(A = fit_a, Ainv = fit_ainv, pedigree = fit_ped)[[nm]]
      info <- paste(link, nm)
      expect_identical(fit$opt$convergence, 0L, info = info)
      expect_true(max(abs(fit$obj$gr(fit$opt$par))) < 2e-2, info = info)
      expect_setequal(names(coef(fit)),
                      c("mu", "sd_phylo(species)", "sd_animal(animal_id)"))
      expect_gt(coef(fit, "sd_phylo(species)")[["z_tree"]], 0)
      expect_gt(coef(fit, "sd_animal(animal_id)")[["z_animal"]], 0)

      animal_sd <- predict(fit, dpar = "sd_animal(animal_id)")
      tree_sd <- predict(fit, dpar = "sd_phylo(species)")
      expect_equal(
        animal_sd[fx$animal_levels],
        b3_sd_curve(coef(fit, "sd_animal(animal_id)"), fx$z_animal),
        tolerance = 1e-8, info = info
      )
      expect_equal(
        tree_sd[fx$species_levels],
        b3_sd_curve(coef(fit, "sd_phylo(species)"), fx$z_tree),
        tolerance = 1e-8, info = info
      )

      mu <- coef(fit, "mu")
      D_animal <- animal_sd[rownames(fx$A)]
      D_tree <- tree_sd[fx$species_levels]
      blocks <- list(
        list(Z = b3_indicator(
               match(as.character(fx$data$animal_id), rownames(fx$A)),
               nrow(fx$A)),
             Sigma = outer(D_animal, D_animal) * fx$A),
        list(Z = b3_indicator(as.integer(fx$data$species),
                              length(fx$species_levels)),
             Sigma = outer(D_tree, D_tree) * fx$phylo_cov)
      )
      dense <- b3_dense_laplace(
        fx$data$y, mu[[1L]] + mu[[2L]] * fx$data$x, blocks, link
      )
      expect_lt(abs(as.numeric(logLik(fit)) - dense), 1e-4, label = info)
    }

    for (nm in c("Ainv", "pedigree")) {
      fit <- list(Ainv = fit_ainv, pedigree = fit_ped)[[nm]]
      info <- paste(link, nm, "vs A")
      expect_lt(abs(as.numeric(logLik(fit)) - as.numeric(logLik(fit_a))),
                1e-5, label = info)
      expect_equal(coef(fit, "sd_animal(animal_id)"),
                   coef(fit_a, "sd_animal(animal_id)"),
                   tolerance = 1e-3, info = info)
      expect_equal(coef(fit, "sd_phylo(species)"),
                   coef(fit_a, "sd_phylo(species)"),
                   tolerance = 1e-3, info = info)
    }

    simulated <- simulate(fit_ainv, nsim = 1L, seed = 20261303L)
    expect_true(all(simulated[[1L]] %in% c(0, 1)), info = link)
  }
})

test_that("Binomial probit and cloglog phylo plus animal constant SDs agree across A, Ainv and pedigree and match a dense oracle", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (link in c("probit", "cloglog")) {
    fx <- b3_phylo_animal_fixture(
      link, if (link == "probit") 20261304L else 20261305L
    )
    fit_a <- b3_fit(fx, link, "A", constant = TRUE)
    for (provider in c("Ainv", "pedigree")) {
      info <- paste(link, provider)
      fit <- b3_fit(fx, link, provider, constant = TRUE)
      expect_identical(fit_a$opt$convergence, 0L, info = info)
      expect_identical(fit$opt$convergence, 0L, info = info)
      expect_lt(abs(as.numeric(logLik(fit)) - as.numeric(logLik(fit_a))),
                1e-5, label = info)
      expect_equal(coef(fit, "mu"), coef(fit_a, "mu"),
                   tolerance = 1e-3, info = info)
      expect_equal(coef(fit, "sd_animal(animal_id)"),
                   coef(fit_a, "sd_animal(animal_id)"),
                   tolerance = 1e-3, info = info)
      expect_equal(coef(fit, "sd_phylo(species)"),
                   coef(fit_a, "sd_phylo(species)"),
                   tolerance = 1e-3, info = info)

      animal_sd <- exp(coef(fit, "sd_animal(animal_id)")[["(Intercept)"]])
      tree_sd <- exp(coef(fit, "sd_phylo(species)")[["(Intercept)"]])
      mu <- coef(fit, "mu")
      blocks <- list(
        list(Z = b3_indicator(
               match(as.character(fx$data$animal_id), rownames(fx$A)),
               nrow(fx$A)),
             Sigma = animal_sd^2 * fx$A),
        list(Z = b3_indicator(as.integer(fx$data$species),
                              length(fx$species_levels)),
             Sigma = tree_sd^2 * fx$phylo_cov)
      )
      dense <- b3_dense_laplace(
        fx$data$y, mu[[1L]] + mu[[2L]] * fx$data$x, blocks, link
      )
      expect_lt(abs(as.numeric(logLik(fit)) - dense), 1e-4, label = info)
    }
  }
})
