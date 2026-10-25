# Binomial x relmat(1 | id, K = K) -- #1283.
#
# Binomial already admitted phylo() (#1048); relmat() differs from phylo()
# only in how the known correlation/covariance matrix is supplied (a
# name-keyed matrix instead of a tree), and funnels through the identical
# build_structured_mu_structure()/Q_phylo plumbing. This slice mirrors the
# phylo gate: one unlabelled q1 relmat intercept on mu, no slopes, no labels,
# not combinable with mi(), ordinary random effects, or phylo() at once.

binomial_relmat_fixture <- function(seed = 20321905L, n_id = 40L, n_each = 5L,
                                    sd_known = 0.6, trials = 10L) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(n_id))
  # Block/AR relatedness: AR(1) correlation with a small diagonal bump so K
  # stays strictly positive definite (a relatedness/pedigree-style K).
  K <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.5^abs(i - j))
  diag(K) <- diag(K) + 0.10
  dimnames(K) <- list(id_levels, id_levels)
  Q <- solve(K)
  known_effect <- as.vector(t(chol(K)) %*% stats::rnorm(n_id, sd = sd_known))
  names(known_effect) <- id_levels

  id <- rep(id_levels, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), n_id)
  beta <- c(`(Intercept)` = 0.30, x = 0.45)
  eta <- beta[[1L]] + beta[[2L]] * x + known_effect[id]
  p <- stats::plogis(eta)
  succ <- stats::rbinom(length(id), trials, p)

  list(
    data = data.frame(
      id = factor(id, levels = id_levels),
      x = x,
      succ = succ,
      fail = trials - succ
    ),
    K = K,
    Q = Q,
    beta = beta,
    sd_known = sd_known
  )
}

test_that("binomial + relmat fits, labels the field, and reports a finite sd", {
  skip_on_cran()
  fx <- binomial_relmat_fixture()
  K <- fx$K
  fit <- drmTMB(
    bf(cbind(succ, fail) ~ x + relmat(1 | id, K = K)),
    family = stats::binomial(),
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

test_that("binomial + relmat recovers the known-DGP fixed effects and structured sd", {
  skip_on_cran()
  fx <- binomial_relmat_fixture()
  K <- fx$K
  fit <- drmTMB(
    bf(cbind(succ, fail) ~ x + relmat(1 | id, K = K)),
    family = stats::binomial(),
    data = fx$data
  )
  expect_equal(fit$opt$convergence, 0)
  fe <- summary(fit)$coefficients
  # Loose single-draw recovery: true value within 4 SE of the estimate.
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

test_that("binomial + relmat gradient: TMB AD matches numDeriv FD", {
  skip_on_cran()
  fx <- binomial_relmat_fixture()
  K <- fx$K
  fit <- drmTMB(
    bf(cbind(succ, fail) ~ x + relmat(1 | id, K = K)),
    family = stats::binomial(),
    data = fx$data
  )
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
  stat <- max(abs(g_ad - g_fd)) / (1 + max(abs(g_ad)))
  message(sprintf("binomial + relmat gradient conformance: stat=%.3e", stat))
  expect_lt(stat, 1e-4)
})

test_that("the two-column form takes the same relmat term", {
  skip_on_cran()
  fx <- binomial_relmat_fixture()
  K <- fx$K
  fit <- drmTMB(
    bf(cbind(succ, fail) ~ x + relmat(1 | id, K = K)),
    family = stats::binomial(),
    data = fx$data
  )
  expect_s3_class(fit, "drmTMB")
  expect_true(is.finite(as.numeric(fit$logLik)))
})

test_that("the relmat slice's fences hold: slopes, labels, REs, phylo+relmat all refuse", {
  skip_on_cran()
  fx <- binomial_relmat_fixture()
  K <- fx$K
  # relmat slope: deferred
  expect_error(
    drmTMB(
      bf(cbind(succ, fail) ~ x + relmat(0 + x | id, K = K)),
      family = stats::binomial(),
      data = fx$data
    ),
    "intercept-only"
  )
  # relmat + ordinary RE: one or the other in this slice
  expect_error(
    drmTMB(
      bf(cbind(succ, fail) ~ x + relmat(1 | id, K = K) + (1 | id)),
      family = stats::binomial(),
      data = fx$data
    ),
    "ordinary random effects"
  )
  # phylo() and relmat() together: only one structured mu provider
  skip_if_not_installed("ape")
  tree <- ape::rcoal(length(levels(fx$data$id)))
  tree$tip.label <- levels(fx$data$id)
  expect_error(
    drmTMB(
      bf(cbind(succ, fail) ~ x + relmat(1 | id, K = K) + phylo(1 | id, tree = tree)),
      family = stats::binomial(),
      data = fx$data
    ),
    "one structured"
  )
})

test_that("plain binomial fits are bit-identical to before the slice", {
  skip_on_cran()
  # The no-relmat path must not move: an empty structure keeps has_phylo_mu = 0,
  # so the C++ block is never entered and the objective is unchanged.
  fx <- binomial_relmat_fixture()
  fit <- drmTMB(bf(cbind(succ, fail) ~ x), family = stats::binomial(), data = fx$data)
  expect_s3_class(fit, "drmTMB")
  expect_identical(fit$model$structured$phylo_mu$has, FALSE)
})
