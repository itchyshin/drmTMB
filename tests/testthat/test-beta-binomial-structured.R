# Beta-binomial x phylo(1 | species)/relmat(1 | id, K = K) -- #1282.
#
# beta_binomial() was the one common denominator-aware count family without a
# structured route: binomial (#1048, phylo) and beta (phylo/animal, and
# relmat in #1283/#1284) already admit phylo()/relmat() on mu through the
# identical build_structured_mu_structure()/Q_phylo plumbing threaded
# generically by make_tmb_data() and the C++ model block. beta_binomial's R
# spec builder never extracted a structured term (the formula fell straight
# to the phase-1 gate), and its make_tmb_data branch (model_type 14)
# hard-coded has_phylo_mu = 0L -- the #1049 pattern where a validated
# structure is silently discarded at data assembly. This slice adds the R
# extraction/validation (mirroring binomial's gate) and the C++ phylo_mu
# contribution to the model 14 block (mirroring model 18's). Deliberately
# narrow: one unlabelled q1 phylo or relmat intercept on mu, no slopes, no
# labels, not combinable with an ordinary mu random effect, sigma random
# effects, mi(), or the other structured provider at once.

beta_binomial_phylo_fixture <- function(seed = 20220928L, n_tip = 12L,
                                        n_each = 6L, sd_phy = 0.5,
                                        trials = 10L, log_phi = 1.5) {
  skip_if_not_installed("ape")
  set.seed(seed)
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("sp_", seq_len(n_tip))
  # Unit height: the reported sd_phylo then sits on the correlation scale.
  tree$edge.length <- tree$edge.length / max(diag(ape::vcv(tree)))
  A <- ape::vcv(tree, corr = TRUE)
  u <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip)) * sd_phy
  species <- factor(rep(tree$tip.label, each = n_each), levels = tree$tip.label)
  idx <- rep(seq_len(n_tip), each = n_each)
  n <- n_tip * n_each
  x <- stats::rnorm(n)
  beta <- c(`(Intercept)` = 0.30, x = 0.40)
  eta <- beta[[1L]] + beta[[2L]] * x + u[idx]
  p <- stats::plogis(eta)
  phi <- exp(log_phi)
  alpha <- p * phi
  beta_shape <- (1 - p) * phi
  p_bb <- stats::rbeta(n, alpha, beta_shape)
  succ <- stats::rbinom(n, trials, p_bb)
  list(
    data = data.frame(
      x = x,
      species = species,
      succ = succ,
      fail = trials - succ
    ),
    tree = tree,
    beta = beta,
    sd_phy = sd_phy
  )
}

beta_binomial_relmat_fixture <- function(seed = 20220929L, n_id = 40L,
                                         n_each = 5L, sd_known = 0.5,
                                         trials = 10L, log_phi = 1.5) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(n_id))
  # Block/AR relatedness: AR(1) correlation with a small diagonal bump so K
  # stays strictly positive definite (a relatedness/pedigree-style K).
  K <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.5^abs(i - j))
  diag(K) <- diag(K) + 0.10
  dimnames(K) <- list(id_levels, id_levels)
  known_effect <- as.vector(t(chol(K)) %*% stats::rnorm(n_id, sd = sd_known))
  names(known_effect) <- id_levels

  id <- rep(id_levels, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), n_id)
  beta <- c(`(Intercept)` = -0.20, x = 0.35)
  eta <- beta[[1L]] + beta[[2L]] * x + known_effect[id]
  p <- stats::plogis(eta)
  phi <- exp(log_phi)
  alpha <- p * phi
  beta_shape <- (1 - p) * phi
  n <- length(id)
  p_bb <- stats::rbeta(n, alpha, beta_shape)
  succ <- stats::rbinom(n, trials, p_bb)

  list(
    data = data.frame(
      id = factor(id, levels = id_levels),
      x = x,
      succ = succ,
      fail = trials - succ
    ),
    K = K,
    beta = beta,
    sd_known = sd_known
  )
}

gradient_conformance_stat <- function(fit) {
  obj <- fit$obj
  obj$env$random.start <- expression(par[random])
  reset_inner <- function() obj$env$last.par.best <- obj$env$last.par
  if (!is.null(obj$env$random)) {
    TMB::newtonOption(obj, tol = 1e-12, maxit = 5000L)
  }
  theta <- obj$par
  reset_inner()
  g_ad <- obj$gr(theta)
  reset_inner()
  g_fd <- numDeriv::grad(
    function(p) {
      reset_inner()
      obj$fn(p)
    },
    theta,
    method = "Richardson"
  )
  max(abs(g_ad - g_fd)) / (1 + max(abs(g_ad)))
}

test_that("beta_binomial + phylo fits, labels the field, and reports a finite sd", {
  skip_on_cran()
  fx <- beta_binomial_phylo_fixture()
  tree <- fx$tree
  fit <- drmTMB(
    bf(cbind(succ, fail) ~ x + phylo(1 | species, tree = tree)),
    family = beta_binomial(),
    data = fx$data
  )
  expect_s3_class(fit, "drmTMB")
  expect_true(is.finite(as.numeric(fit$logLik)))
  expect_length(fit$coefficients$mu, 2L)
  expect_named(fit$sdpars$mu, "phylo(1 | species)")
  rep <- fit$obj$report(fit$obj$env$last.par.best)
  expect_true(is.finite(as.numeric(rep$sd_phylo)))
  expect_gt(as.numeric(rep$sd_phylo), 0)
})

test_that("beta_binomial + phylo recovers the known-DGP fixed effects and structured sd", {
  skip_on_cran()
  fx <- beta_binomial_phylo_fixture()
  tree <- fx$tree
  fit <- drmTMB(
    bf(cbind(succ, fail) ~ x + phylo(1 | species, tree = tree)),
    family = beta_binomial(),
    data = fx$data
  )
  expect_equal(fit$opt$convergence, 0)
  fe <- summary(fit)$coefficients
  expect_lt(
    abs(fe["mu:(Intercept)", "estimate"] - fx$beta[["(Intercept)"]]),
    4 * fe["mu:(Intercept)", "std_error"]
  )
  expect_lt(
    abs(fe["mu:x", "estimate"] - fx$beta[["x"]]),
    4 * fe["mu:x", "std_error"]
  )
  rep <- fit$obj$report(fit$obj$env$last.par.best)
  sd_hat <- as.numeric(rep$sd_phylo)
  expect_gt(sd_hat, 0)
  expect_lt(sd_hat, 3 * fx$sd_phy + 0.5)
})

test_that("beta_binomial + phylo gradient: TMB AD matches numDeriv FD", {
  skip_on_cran()
  fx <- beta_binomial_phylo_fixture()
  tree <- fx$tree
  fit <- drmTMB(
    bf(cbind(succ, fail) ~ x + phylo(1 | species, tree = tree)),
    family = beta_binomial(),
    data = fx$data
  )
  stat <- gradient_conformance_stat(fit)
  message(sprintf("beta_binomial + phylo gradient conformance: stat=%.3e", stat))
  expect_lt(stat, 1e-4)
})

test_that("beta_binomial + relmat fits, labels the field, and reports a finite sd", {
  skip_on_cran()
  fx <- beta_binomial_relmat_fixture()
  K <- fx$K
  fit <- drmTMB(
    bf(cbind(succ, fail) ~ x + relmat(1 | id, K = K)),
    family = beta_binomial(),
    data = fx$data
  )
  expect_s3_class(fit, "drmTMB")
  expect_true(is.finite(as.numeric(fit$logLik)))
  expect_length(fit$coefficients$mu, 2L)
  expect_named(fit$sdpars$mu, "relmat(1 | id)")
  rep <- fit$obj$report(fit$obj$env$last.par.best)
  expect_true(is.finite(as.numeric(rep$sd_phylo)))
  expect_gt(as.numeric(rep$sd_phylo), 0)
})

test_that("beta_binomial + relmat recovers the known-DGP fixed effects and structured sd", {
  skip_on_cran()
  fx <- beta_binomial_relmat_fixture()
  K <- fx$K
  fit <- drmTMB(
    bf(cbind(succ, fail) ~ x + relmat(1 | id, K = K)),
    family = beta_binomial(),
    data = fx$data
  )
  expect_equal(fit$opt$convergence, 0)
  fe <- summary(fit)$coefficients
  expect_lt(
    abs(fe["mu:(Intercept)", "estimate"] - fx$beta[["(Intercept)"]]),
    4 * fe["mu:(Intercept)", "std_error"]
  )
  expect_lt(
    abs(fe["mu:x", "estimate"] - fx$beta[["x"]]),
    4 * fe["mu:x", "std_error"]
  )
  rep <- fit$obj$report(fit$obj$env$last.par.best)
  sd_hat <- as.numeric(rep$sd_phylo)
  expect_gt(sd_hat, 0)
  expect_lt(sd_hat, 3 * fx$sd_known + 0.5)
})

test_that("beta_binomial + relmat gradient: TMB AD matches numDeriv FD", {
  skip_on_cran()
  fx <- beta_binomial_relmat_fixture()
  K <- fx$K
  fit <- drmTMB(
    bf(cbind(succ, fail) ~ x + relmat(1 | id, K = K)),
    family = beta_binomial(),
    data = fx$data
  )
  stat <- gradient_conformance_stat(fit)
  message(sprintf("beta_binomial + relmat gradient conformance: stat=%.3e", stat))
  expect_lt(stat, 1e-4)
})

test_that("the beta_binomial structured slice's fences hold", {
  skip_on_cran()
  fx <- beta_binomial_relmat_fixture()
  K <- fx$K
  # relmat slope: deferred
  expect_error(
    drmTMB(
      bf(cbind(succ, fail) ~ x + relmat(0 + x | id, K = K)),
      family = beta_binomial(),
      data = fx$data
    ),
    "intercept-only"
  )
  # relmat + ordinary mu RE: one or the other in this slice
  expect_error(
    drmTMB(
      bf(cbind(succ, fail) ~ x + relmat(1 | id, K = K) + (1 | id)),
      family = beta_binomial(),
      data = fx$data
    ),
    "ordinary random effects"
  )
  # phylo() and relmat() together: only one structured mu provider
  fx_phylo <- beta_binomial_phylo_fixture()
  tree <- fx_phylo$tree
  species_as_id <- as.character(fx_phylo$data$species)
  data_both <- fx_phylo$data
  data_both$id <- factor(species_as_id, levels = levels(fx_phylo$data$species))
  K_tip <- diag(nlevels(data_both$id))
  dimnames(K_tip) <- list(levels(data_both$id), levels(data_both$id))
  expect_error(
    drmTMB(
      bf(cbind(succ, fail) ~ x + relmat(1 | id, K = K_tip) +
        phylo(1 | species, tree = tree)),
      family = beta_binomial(),
      data = data_both
    ),
    "one structured"
  )
})

test_that("plain beta_binomial fits are bit-identical to before the slice", {
  skip_on_cran()
  # The no-structured path must not move: an empty structure keeps
  # has_phylo_mu = 0, so the C++ block is never entered and the objective is
  # unchanged.
  fx <- beta_binomial_relmat_fixture()
  fit <- drmTMB(
    bf(cbind(succ, fail) ~ x),
    family = beta_binomial(),
    data = fx$data
  )
  expect_s3_class(fit, "drmTMB")
  expect_identical(fit$model$structured$phylo_mu$has, FALSE)
})
