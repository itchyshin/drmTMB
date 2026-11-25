# Pins the CURRENT refusal of phylo()/relmat() mu intercepts on beta_binomial()
# (drmTMB #1282; DRModels.jl admits BetaBinomial phylo). The refusal is a
# deferral, not a statistical limit, and the message must say so by name.
test_that("beta_binomial phylo()/relmat() refuse and name the deferral (#1282)", {
  skip_if_not_installed("ape")
  set.seed(1282)
  tree <- ape::rtree(8)
  tree$tip.label <- paste0("s", 1:8)
  K <- diag(8)
  dimnames(K) <- list(tree$tip.label, tree$tip.label)
  dat <- data.frame(
    sp = factor(rep(tree$tip.label, each = 4), levels = tree$tip.label),
    x = stats::rnorm(32)
  )
  dat$success <- stats::rbinom(32, 10, 0.5)
  dat$failure <- 10L - dat$success
  for (f in list(
    bf(cbind(success, failure) ~ x + phylo(1 | sp, tree = tree)),
    bf(cbind(success, failure) ~ x + relmat(1 | sp, K = K))
  )) {
    expect_error(
      drmTMB(f, family = beta_binomial(), data = dat),
      "Structured-effect syntax is planned, not implemented"
    )
    expect_error(
      drmTMB(f, family = beta_binomial(), data = dat),
      "beta-binomial"
    )
  }
})
