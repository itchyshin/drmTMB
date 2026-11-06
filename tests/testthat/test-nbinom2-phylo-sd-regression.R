test_that("NB2 phylogenetic intercepts admit predictor-dependent SDs", {
  set.seed(20261027)
  n_species <- 48L
  repeats <- 18L
  tree <- ape::rcoal(n_species)
  A <- ape::vcv.phylo(tree)
  species <- tree$tip.label
  z <- stats::rnorm(n_species)
  alpha <- c(-0.2, 0.5)
  tau <- exp(alpha[[1L]] + alpha[[2L]] * z)
  phylo_effect <- as.vector(t(chol(A)) %*% stats::rnorm(n_species)) * tau
  dat <- data.frame(
    species = rep(species, each = repeats),
    z = rep(z, each = repeats)
  )
  mu <- exp(0.25 + rep(phylo_effect, each = repeats))
  dat$count <- stats::rnbinom(
    nrow(dat), size = 1 / 0.35^2, mu = mu
  )

  fit <- drmTMB(
    bf(
      count ~ 1 + phylo(1 | species, tree = tree),
      sigma ~ 1,
      sd(species, level = "phylogenetic") ~ z
    ),
    data = dat,
    family = nbinom2()
  )

  sd_coef <- coef(fit, "sd_phylo(species)")
  expect_named(sd_coef, c("(Intercept)", "z"))
  expect_equal(unname(sd_coef[["z"]]), alpha[[2L]], tolerance = 0.45)
  expect_true(all(is.finite(predict_parameters(fit)$sd_phylo)))

  fit_constant <- drmTMB(
    bf(
      count ~ 1 + phylo(1 | species, tree = tree),
      sigma ~ 1,
      sd(species, level = "phylogenetic") ~ 1
    ),
    data = dat,
    family = nbinom2()
  )
  fit_fixed_sd <- drmTMB(
    bf(count ~ 1 + phylo(1 | species, tree = tree), sigma ~ 1),
    data = dat,
    family = nbinom2()
  )
  expect_equal(
    as.numeric(logLik(fit_constant)),
    as.numeric(logLik(fit_fixed_sd)),
    tolerance = 1e-5
  )
})
