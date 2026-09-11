test_that("paired phylogenetic-stable plus OU likelihood matches an independent dense oracle", {
  fixture <- phylo_temporal_ou_oracle_fixture()
  tree <- fixture$tree
  fit <- suppressWarnings(drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree) +
         temporal(1 | species, time = elapsed, structure = "ou"), sigma ~ 1),
    data = fixture$data, family = gaussian(), REML = FALSE
  ))
  expect_true(isTRUE(fit$sdr$pdHess))
  expect_equal(
    as.numeric(fit$obj$fn(fit$opt$par)),
    phylo_temporal_ou_dense_nll_at(fit, fit$opt$par, tree),
    tolerance = 1e-7
  )
})

test_that("paired covariance retains stable cross-species covariance and rejects the separable field", {
  fixture <- phylo_temporal_ou_oracle_fixture()
  tree <- fixture$tree
  data <- fixture$data
  A <- ape::vcv(tree, corr = TRUE)
  species <- as.character(data$species)
  elapsed <- data$elapsed
  sd_phylo <- 0.6
  sd_temporal <- 0.75
  sigma <- 0.4
  decay <- 0.45
  correct <- phylo_temporal_ou_dense_covariance(
    species, elapsed, A, sd_phylo, sd_temporal, sigma, decay
  )
  separable <- phylo_temporal_ou_separable_covariance(
    species, elapsed, A, sd_phylo, sd_temporal, sigma, decay
  )
  cross <- which(outer(species, species, `!=`) & abs(outer(elapsed, elapsed, "-")) > 0,
                 arr.ind = TRUE)[1L, ]
  expect_gt(abs(A[species[[cross[[1L]]]], species[[cross[[2L]]]]]), 0)
  expect_equal(
    correct[cross[[1L]], cross[[2L]]],
    sd_phylo^2 * A[species[[cross[[1L]]]], species[[cross[[2L]]]]],
    tolerance = 1e-12
  )
  expect_false(isTRUE(all.equal(correct, separable)))
})

test_that("paired phylogenetic-stable plus OU score and Hessian match the dense oracle", {
  fixture <- phylo_temporal_ou_oracle_fixture(seed = 202609093L)
  tree <- fixture$tree
  fit <- suppressWarnings(drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree) +
         temporal(1 | species, time = elapsed, structure = "ou"), sigma ~ 1),
    data = fixture$data, family = gaussian(), REML = FALSE
  ))
  expect_true(isTRUE(fit$sdr$pdHess))
  objective <- function(par) phylo_temporal_ou_dense_nll_at(fit, par, tree)
  opt <- fit$opt$par
  score <- numDeriv::grad(objective, opt, method.args = list(eps = 1e-6))
  hessian_1 <- numDeriv::hessian(objective, opt, method.args = list(eps = 1e-4))
  hessian_2 <- numDeriv::hessian(objective, opt, method.args = list(eps = 1e-5))
  observed_hessian <- solve(fit$sdr$cov.fixed)
  expect_equal(fit$obj$gr(opt), score, tolerance = 1e-5)
  expect_equal(hessian_1, hessian_2, tolerance = 1e-4)
  expect_equal(unname(observed_hessian), unname(hessian_1), tolerance = 1e-4)
})

test_that("paired covariance has the prespecified reductions", {
  species <- c("a", "a", "a", "b", "b", "b")
  elapsed <- c(0, 1, 3, 0, 1, 3)
  A <- matrix(c(1, 0.35, 0.35, 1), 2, dimnames = list(c("a", "b"), c("a", "b")))
  sd_phylo <- 0.6
  sd_temporal <- 0.8
  sigma <- 0.4
  decay <- -log(0.5)
  full <- phylo_temporal_ou_dense_covariance(
    species, elapsed, A, sd_phylo, sd_temporal, sigma, decay
  )
  no_stable <- phylo_temporal_ou_dense_covariance(
    species, elapsed, A, 0, sd_temporal, sigma, decay
  )
  no_temporal <- phylo_temporal_ou_dense_covariance(
    species, elapsed, A, sd_phylo, 0, sigma, decay
  )
  identity_A <- diag(2)
  dimnames(identity_A) <- list(c("a", "b"), c("a", "b"))
  identity_phylo <- phylo_temporal_ou_dense_covariance(
    species, elapsed, identity_A, sd_phylo, sd_temporal, sigma, decay
  )
  expect_equal(unname(no_stable[1:3, 1:3]),
               sd_temporal^2 * 0.5^abs(outer(elapsed[1:3], elapsed[1:3], "-")) + diag(sigma^2, 3),
               tolerance = 1e-12)
  expect_equal(no_temporal,
               sd_phylo^2 * A[species, species] + diag(sigma^2, length(species)),
               tolerance = 1e-12)
  expect_equal(identity_phylo[1, 4], 0, tolerance = 1e-12)
  expect_equal(full[1, 3], sd_phylo^2 + sd_temporal^2 * 0.5^3, tolerance = 1e-12)
})

test_that("paired dense reference mutations detect the wrong covariance mechanisms", {
  fixture <- phylo_temporal_ou_oracle_fixture(seed = 202609094L)
  tree <- fixture$tree
  data <- fixture$data
  A <- ape::vcv(tree, corr = TRUE)
  species <- as.character(data$species)
  elapsed <- data$elapsed
  sd_phylo <- 0.6
  sd_temporal <- 0.75
  sigma <- 0.4
  decay <- 0.45
  correct <- phylo_temporal_ou_dense_covariance(
    species, elapsed, A, sd_phylo, sd_temporal, sigma, decay
  )
  diagonal_A <- diag(nrow(A))
  dimnames(diagonal_A) <- dimnames(A)
  no_phylo_offdiag <- phylo_temporal_ou_dense_covariance(
    species, elapsed, diagonal_A, sd_phylo, sd_temporal, sigma, decay
  )
  shared_ou <- sd_phylo^2 * A[species, species] +
    sd_temporal^2 * exp(-decay * abs(outer(elapsed, elapsed, "-"))) +
    diag(sigma^2, length(species))
  no_stable <- phylo_temporal_ou_dense_covariance(
    species, elapsed, A, 0, sd_temporal, sigma, decay
  )
  permuted_A <- A
  dimnames(permuted_A) <- list(rev(rownames(A)), rev(colnames(A)))
  misaligned_tree <- phylo_temporal_ou_dense_covariance(
    species, elapsed, permuted_A, sd_phylo, sd_temporal, sigma, decay
  )
  expect_false(isTRUE(all.equal(correct, no_phylo_offdiag)))
  expect_false(isTRUE(all.equal(correct, phylo_temporal_ou_separable_covariance(
    species, elapsed, A, sd_phylo, sd_temporal, sigma, decay
  ))))
  expect_false(isTRUE(all.equal(correct, shared_ou)))
  expect_false(isTRUE(all.equal(correct, no_stable)))
  expect_false(isTRUE(all.equal(correct, misaligned_tree)))

  latent <- c(0.4, -0.2, 0.7)
  gaps <- c(0, 0.5, 2.5)
  normalized <- -stats::dnorm(latent[[1L]], 0, 1, log = TRUE)
  unnormalized <- latent[[1L]]^2 / 2
  for (node in 2:3) {
    transition <- exp(-decay * gaps[[node]])
    transition_sd <- sqrt(1 - transition^2)
    normalized <- normalized - stats::dnorm(
      latent[[node]], transition * latent[[node - 1L]], transition_sd, log = TRUE
    )
    unnormalized <- unnormalized +
      (latent[[node]] - transition * latent[[node - 1L]])^2 / (2 * transition_sd^2)
  }
  expect_false(isTRUE(all.equal(normalized, unnormalized)))
})
