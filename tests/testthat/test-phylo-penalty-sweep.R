# drm_phylo_penalty_sweep() refits a penalized (MAP) phylogenetic model across a
# range of cor_sd values so the analyst can judge whether a coupling is data-
# informed or prior-shaped. The test exercises the sweep mechanics (one MAP fit
# per cor_sd, a tidy summary, and the fits for downstream extraction) and the
# input validation.

sweep_phylo_fixture <- function(n_tip = 20L, n_each = 2L, seed = 4L) {
  set.seed(seed)
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("sp_", seq_len(n_tip))
  A <- ape::vcv(tree, corr = TRUE)
  u <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip)) * 0.6
  tip <- rep(seq_len(n_tip), each = n_each)
  n <- n_tip * n_each
  x <- stats::rnorm(n)
  list(
    data = data.frame(
      y = 0.3 + 0.5 * x + u[tip] + stats::rnorm(n, 0, 0.5),
      x = x,
      species = factor(tree$tip.label[tip], levels = tree$tip.label)
    ),
    tree = tree
  )
}

test_that("drm_phylo_penalty_sweep runs one MAP fit per cor_sd and returns a summary + fits", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- sweep_phylo_fixture()
  tree <- fx$tree
  cor_sd <- c(0.25, 0.5, 1)
  out <- drm_phylo_penalty_sweep(
    bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
    data = fx$data,
    family = gaussian(),
    cor_sd = cor_sd
  )
  expect_named(out, c("summary", "fits"))
  expect_equal(nrow(out$summary), length(cor_sd))
  expect_equal(out$summary$cor_sd, cor_sd)
  expect_true(all(
    c("cor_sd", "convergence", "pdHess", "logLik", "error") %in%
      names(out$summary)
  ))
  expect_length(out$fits, length(cor_sd))
  estimators <- vapply(out$fits, function(f) f$estimator, character(1L))
  expect_true(all(estimators == "MAP"))
})

test_that("drm_phylo_penalty_sweep validates cor_sd", {
  skip_if_not_installed("ape")
  fx <- sweep_phylo_fixture()
  tree <- fx$tree
  expect_error(
    drm_phylo_penalty_sweep(
      bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
      data = fx$data,
      cor_sd = c(-1, 0.5)
    ),
    "cor_sd"
  )
})
