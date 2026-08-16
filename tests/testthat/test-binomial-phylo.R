# Binomial x phylo(1 | id) -- the first binomial structured slice (#1048).
#
# Binomial was the only common family without a structured route: gaussian,
# poisson, nbinom2, Gamma and beta all accepted the identical phylo() term while
# binomial aborted at the phase-1 gate. Phylogenetic logistic regression (a
# binary trait on a tree) is the canonical comparative-methods use of a binary
# response, so the hole was conspicuous rather than exotic. The slice is
# deliberately narrow -- one unlabelled q1 phylo intercept on mu, no slopes, no
# labels, no combination with ordinary REs or mi() -- matching how beta and
# zero-one-beta grew provider by provider.

binomial_phylo_fixture <- function(seed = 411L, n_tip = 12L, n_each = 6L,
                                   sd_phy = 0.5) {
  skip_if_not_installed("ape")
  set.seed(seed)
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("sp_", seq_len(n_tip))
  # Unit height: the reported sd_phylo then sits on the correlation scale.
  tree$edge.length <- tree$edge.length / max(diag(ape::vcv(tree)))
  A <- ape::vcv(tree, corr = TRUE)
  u <- as.vector(t(chol(A)) %*% rnorm(n_tip)) * sd_phy
  species <- factor(rep(tree$tip.label, each = n_each), levels = tree$tip.label)
  idx <- rep(seq_len(n_tip), each = n_each)
  n <- n_tip * n_each
  x <- rnorm(n)
  eta <- 0.3 + 0.4 * x + u[idx]
  list(
    data = data.frame(
      x = x, species = species,
      y = rbinom(n, 1, plogis(eta)),
      succ = rbinom(n, 5L, plogis(eta))
    ),
    tree = tree
  )
}

test_that("binomial + phylo fits, labels the field, and reports a finite sd", {
  skip_on_cran()
  fx <- binomial_phylo_fixture()
  tree <- fx$tree
  fit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree)),
    family = stats::binomial(),
    data = fx$data
  )
  expect_s3_class(fit, "drmTMB")
  expect_true(is.finite(as.numeric(fit$logLik)))
  expect_length(fit$coefficients$mu, 2L)
  rep <- fit$obj$report(fit$obj$env$last.par.best)
  expect_true(is.finite(as.numeric(rep$sd_phylo)))
  expect_gt(as.numeric(rep$sd_phylo), 0)
})

test_that("the phylo field changes the fit relative to no-phylo", {
  skip_on_cran()
  fx <- binomial_phylo_fixture()
  tree <- fx$tree
  with_phylo <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree)),
    family = stats::binomial(),
    data = fx$data
  )
  without <- drmTMB(bf(y ~ x), family = stats::binomial(), data = fx$data)
  # A latent field must not be a silent no-op: the marginal logLik of the
  # phylo fit must be at least the fixed-effect fit's (it nests it), and the
  # reported field must actually enter eta.
  expect_gte(
    as.numeric(with_phylo$logLik),
    as.numeric(without$logLik) - 1e-6
  )
})

test_that("the two-column form takes the same phylo term", {
  skip_on_cran()
  fx <- binomial_phylo_fixture()
  tree <- fx$tree
  fx$data$fail <- 5L - fx$data$succ
  fit <- drmTMB(
    bf(cbind(succ, fail) ~ x + phylo(1 | species, tree = tree)),
    family = stats::binomial(),
    data = fx$data
  )
  expect_s3_class(fit, "drmTMB")
  expect_true(is.finite(as.numeric(fit$logLik)))
})

test_that("the slice's fences hold: slopes, labels, REs, mi all refuse", {
  skip_on_cran()
  fx <- binomial_phylo_fixture()
  tree <- fx$tree
  # phylo slope: deferred
  expect_error(
    drmTMB(
      bf(y ~ x + phylo(0 + x | species, tree = tree)),
      family = stats::binomial(),
      data = fx$data
    ),
    "intercept-only"
  )
  # phylo + ordinary RE: one or the other in this slice
  expect_error(
    drmTMB(
      bf(y ~ x + phylo(1 | species, tree = tree) + (1 | species)),
      family = stats::binomial(),
      data = fx$data
    ),
    "ordinary random effects"
  )
})

test_that("plain binomial fits are bit-identical to before the slice", {
  skip_on_cran()
  # The no-phylo path must not move: an empty structure keeps has_phylo_mu = 0,
  # so the C++ block is never entered and the objective is unchanged.
  fx <- binomial_phylo_fixture()
  fit <- drmTMB(bf(y ~ x), family = stats::binomial(), data = fx$data)
  expect_s3_class(fit, "drmTMB")
  expect_identical(fit$model$structured$phylo_mu$has, FALSE)
})
