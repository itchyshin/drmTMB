# Poisson and NB2 labelled relmat intercept-plus-slope (q = 2) with one
# predictor-dependent SD formula per coefficient: relmat(1 + x | p | id, K = K).
#
# Meaning of the label. Here the label is not an alias. Inside one `mu`
# formula the unlabelled relmat(1 + x | id, K = K) block has two independent
# unit-scale latent fields (intercept and slope, rho = 0), while the labelled
# block relmat(1 + x | p | id, K = K) adds one cross-coefficient correlation
# rho, so the latent prior is R kron K with R = [1 rho; rho 1]. The label does
# not need cross-dpar sharing for this reading; the NB2 animal() route already
# works the same way. These tests check the labelled route against a dense
# Laplace oracle that includes rho, and check it nests the unlabelled fit.
#
# Oracle: a dense Laplace marginal likelihood computed in plain R at the fitted
# parameters and the fitted rho. It uses a dense non-unit-diagonal kernel K
# built in this file (never the package's precision or log-determinant), a
# dpois/dnbinom data term and analytic dense Hessians. The latent vector
# u = (u0, u1) is the unit-scale field with prior covariance R kron K; the
# coefficient SDs scale it multiplicatively, and Laplace is invariant to that
# linear reparameterisation. Tolerances fixed before the first run: 1e-4
# absolute for oracle agreement, 1e-5 for constant-SD equivalence, 1e-6 for
# nesting (labelled logLik no lower than unlabelled) and 1 log-likelihood unit
# for emulated-bug sensitivity. This is a likelihood-evaluation check, not a
# recovery, calibration or parity claim.

lab_q2_fixture <- function(family, seed, groups = 36L, repeats = 16L) {
  set.seed(seed)
  ids <- sprintf("g%02d", seq_len(groups))
  C <- outer(seq_len(groups), seq_len(groups), function(i, j) 0.35^abs(i - j))
  d <- seq(0.8, 1.6, length.out = groups)[sample.int(groups)]
  K <- diag(d) %*% C %*% diag(d)  # non-unit diagonal
  dimnames(K) <- list(ids, ids)
  w <- stats::setNames(sample(rep(c(-1, 1), length.out = groups)), ids)
  v <- stats::setNames(sample(rep(c(-1, 1), each = groups / 2L)), ids)
  s0 <- exp(-1.0 + 0.8 * w)
  s1 <- exp(-1.0 - 0.8 * v)
  L <- t(chol(K))
  z0 <- stats::rnorm(groups)
  z1 <- stats::rnorm(groups)
  b0 <- s0 * drop(L %*% z0)
  b1 <- s1 * drop(L %*% (0.8 * z0 + 0.6 * z1))  # true rho = 0.8
  id <- factor(rep(ids, each = repeats), levels = sample(ids))
  x <- rep(seq(-1.2, 1.2, length.out = repeats), times = groups)
  eta <- 0.8 + 0.25 * x + b0[as.character(id)] + b1[as.character(id)] * x
  y <- if (family == "poisson") {
    stats::rpois(length(eta), exp(eta))
  } else {
    stats::rnbinom(length(eta), size = 0.4^-2, mu = exp(eta))
  }
  data <- data.frame(
    y = y, x = x, id = id,
    w = unname(w[as.character(id)]), v = unname(v[as.character(id)])
  )
  shuffled <- sample(ids)  # supplied K is shuffled against levels(id)
  list(family = family, data = data, K = K, supplied = K[shuffled, shuffled],
       w = w, v = v)
}

lab_q2_family <- function(family) {
  if (family == "poisson") stats::poisson() else nbinom2()
}

lab_q2_formula <- function(fx, label = "p", constant = FALSE, use_Q = FALSE,
                           only = NULL, extra = NULL) {
  K <- fx$supplied
  Q <- solve(K)
  bar <- if (is.null(label)) "1 + x | id" else paste0("1 + x | ", label, " | id")
  arg <- if (use_Q) "Q = Q" else "K = K"
  mu <- stats::as.formula(sprintf("y ~ x + relmat(%s, %s)%s", bar, arg,
                                  if (is.null(extra)) "" else extra))
  environment(mu) <- environment()
  f0 <- stats::as.formula(sprintf(
    'sd(id, level = "relmat", dpar = "mu", coef = "(Intercept)") ~ %s',
    if (constant) "1" else "w"), env = environment())
  f1 <- stats::as.formula(sprintf(
    'sd(id, level = "relmat", dpar = "mu", coef = "x") ~ %s',
    if (constant) "1" else "v"), env = environment())
  sds <- list(f0, f1)
  if (identical(only, "intercept")) sds <- sds[1L]
  if (identical(only, "slope")) sds <- sds[2L]
  if (fx$family == "poisson") {
    do.call(bf, c(list(mu), sds))
  } else {
    do.call(bf, c(list(mu, sigma ~ 1), sds))
  }
}

lab_q2_fit <- function(fx, ...) {
  drmTMB(lab_q2_formula(fx, ...), family = lab_q2_family(fx$family),
         data = fx$data, control = drm_control(se = FALSE))
}

lab_q2_free_fit <- function(fx, label = "p") {
  K <- fx$supplied
  mu <- stats::as.formula(sprintf("y ~ x + relmat(1 + x | %s | id, K = K)", label))
  environment(mu) <- environment()
  f <- if (fx$family == "poisson") bf(mu) else bf(mu, sigma ~ 1)
  drmTMB(f, family = lab_q2_family(fx$family), data = fx$data,
         control = drm_control(se = FALSE))
}

lab_q2_sds <- function(fit, fx) {
  key0 <- 'sd_relmat(id, dpar = "mu", coef = "(Intercept)")'
  key1 <- 'sd_relmat(id, dpar = "mu", coef = "x")'
  b0 <- coef(fit, key0)
  b1 <- coef(fit, key1)
  ids <- levels(fx$data$id)
  list(
    s0 = unname(exp(b0[["(Intercept)"]] + b0[["w"]] * fx$w[ids])),
    s1 = unname(exp(b1[["(Intercept)"]] + b1[["v"]] * fx$v[ids])),
    b0 = b0, b1 = b1, keys = c(key0, key1)
  )
}

# Dense Laplace marginal log-likelihood. `K` must be aligned to levels(id).
lab_q2_oracle <- function(fx, K, beta, s0, s1, size = NULL, rho = 0) {
  data <- fx$data
  G <- nlevels(data$id)
  gi <- as.integer(data$id)
  y <- data$y
  Zg <- outer(gi, seq_len(G), function(i, g) as.numeric(i == g))
  Z <- cbind(Zg %*% diag(s0), (Zg * data$x) %*% diag(s1))
  offset <- beta[[1L]] + beta[[2L]] * data$x
  R <- matrix(c(1, rho, rho, 1), 2L, 2L)
  P <- kronecker(solve(R), solve(K))
  logdet_prior <- G * log(det(R)) +
    2 * as.numeric(determinant(K, logarithm = TRUE)$modulus)
  loglik <- function(eta) {
    if (fx$family == "poisson") {
      sum(stats::dpois(y, exp(eta), log = TRUE))
    } else {
      sum(stats::dnbinom(y, size = size, mu = exp(eta), log = TRUE))
    }
  }
  score <- function(eta) {
    mu <- exp(eta)
    if (fx$family == "poisson") y - mu else size * (y - mu) / (mu + size)
  }
  weight <- function(eta) {
    mu <- exp(eta)
    if (fx$family == "poisson") mu else (y + size) * mu * size / (mu + size)^2
  }
  joint <- function(u) {
    loglik(offset + drop(Z %*% u)) - 0.5 * drop(t(u) %*% P %*% u)
  }
  u <- rep(0, 2L * G)
  for (iter in 1:300) {
    eta <- offset + drop(Z %*% u)
    grad <- drop(crossprod(Z, score(eta))) - drop(P %*% u)
    H <- crossprod(Z, weight(eta) * Z) + P
    step <- drop(solve(H, grad))
    f0 <- joint(u)
    scale <- 1
    while (joint(u + scale * step) < f0 && scale > 1e-12) scale <- scale / 2
    u <- u + scale * step
    if (max(abs(scale * step)) < 1e-11) break
  }
  eta <- offset + drop(Z %*% u)
  H <- crossprod(Z, weight(eta) * Z) + P
  joint(u) - 0.5 * logdet_prior -
    0.5 * as.numeric(determinant(H, logarithm = TRUE)$modulus)
}

lab_q2_rho <- function(fit) {
  rho <- fit$obj$report(fit$obj$env$last.par.best)$rho_phylo
  stopifnot(length(rho) == 1L)
  unname(rho)
}

lab_q2_cache <- new.env(parent = emptyenv())
lab_q2_cached <- function(family, seed) {
  key <- paste(family, seed)
  if (is.null(lab_q2_cache[[key]])) {
    fx <- lab_q2_fixture(family, seed)
    lab_q2_cache[[key]] <- list(
      fx = fx,
      labelled = lab_q2_fit(fx),
      unlabelled = lab_q2_fit(fx, label = NULL)
    )
  }
  lab_q2_cache[[key]]
}

test_that("labelled relmat q2 SD fits match a dense Laplace oracle with rho", {
  skip_on_cran()
  for (family in c("poisson", "nbinom2")) {
    for (seed in c(20261121L, 20261122L)) {
      cached <- lab_q2_cached(family, seed)
      fx <- cached$fx
      fit <- cached$labelled
      expect_equal(fit$opt$convergence, 0L)
      sds <- lab_q2_sds(fit, fx)
      expect_gt(stats::sd(log(sds$s0)), 0.1)
      expect_gt(stats::sd(log(sds$s1)), 0.1)
      expect_named(sds$b0, c("(Intercept)", "w"))
      expect_named(sds$b1, c("(Intercept)", "v"))
      ids <- levels(fx$data$id)
      K <- fx$K[ids, ids]
      beta <- coef(fit, "mu")
      size <- if (family == "nbinom2") exp(-2 * coef(fit, "sigma")[[1L]]) else NULL
      rho <- lab_q2_rho(fit)
      expect_gt(abs(rho), 0.05)
      reference <- lab_q2_oracle(fx, K, beta, sds$s0, sds$s1, size, rho)
      expect_lt(abs(as.numeric(logLik(fit)) - reference), 1e-4)

      # Emulated bugs must move the oracle by far more than the tolerance.
      shift <- function(z) z[c(length(z), seq_len(length(z) - 1L))]
      bugs <- c(
        swap_sd = lab_q2_oracle(fx, K, beta, sds$s1, sds$s0, size, rho),
        shifted_levels = lab_q2_oracle(fx, K, beta, shift(sds$s0),
                                       shift(sds$s1), size, rho),
        unaligned_K = lab_q2_oracle(fx, unname(fx$supplied), beta, sds$s0,
                                    sds$s1, size, rho),
        one_sd_for_both = lab_q2_oracle(fx, K, beta, sds$s0, sds$s0, size, rho),
        drop_rho = lab_q2_oracle(fx, K, beta, sds$s0, sds$s1, size, 0),
        cross_sign = lab_q2_oracle(fx, K, beta, sds$s0, sds$s1, size, -rho)
      )
      for (nm in names(bugs)) {
        expect_gt(abs(bugs[[nm]] - reference), 1)
      }
    }
  }
})

test_that("labelled relmat q2 estimates one correlation and nests the unlabelled fit", {
  skip_on_cran()
  for (family in c("poisson", "nbinom2")) {
    cached <- lab_q2_cached(family, 20261121L)
    labelled <- cached$labelled
    unlabelled <- cached$unlabelled
    expect_equal(unlabelled$opt$convergence, 0L)
    key <- "cor(mu:(Intercept),mu:x | p | id)"
    expect_named(labelled$corpars$relmat, key)
    rho_hat <- unname(labelled$corpars$relmat[[key]])
    expect_true(is.finite(rho_hat))
    expect_lt(abs(rho_hat), 1)
    expect_equal(lab_q2_rho(labelled), rho_hat, tolerance = 1e-8)
    # Fixed-seed recovery band for the true rho = 0.8, not a calibration claim.
    expect_lt(abs(rho_hat - 0.8), 0.5)
    # The unlabelled fit has independent fields: no correlation parameter, and
    # it is nested in the labelled fit.
    expect_null(unlabelled$corpars$relmat)
    expect_gte(as.numeric(logLik(labelled)),
               as.numeric(logLik(unlabelled)) - 1e-6)
    expect_equal(names(coef(labelled)), names(coef(unlabelled)))
    # The label name is arbitrary within a single formula.
    renamed <- lab_q2_fit(cached$fx, label = "q")
    expect_equal(as.numeric(logLik(renamed)), as.numeric(logLik(labelled)),
                 tolerance = 1e-6)
    expect_named(renamed$corpars$relmat, "cor(mu:(Intercept),mu:x | q | id)")
    # Precision input gives the same fit as covariance input.
    precision <- lab_q2_fit(cached$fx, use_Q = TRUE)
    expect_lt(abs(as.numeric(logLik(precision)) - as.numeric(logLik(labelled))),
              1e-4)
  }
})

test_that("labelled constant coefficient SDs reduce to the plain labelled block", {
  skip_on_cran()
  for (family in c("poisson", "nbinom2")) {
    fx <- lab_q2_fixture(family, 20261121L)
    constant_fit <- lab_q2_fit(fx, constant = TRUE)
    expect_equal(constant_fit$opt$convergence, 0L)
    # Independent oracle with the constant fitted SDs and fitted rho.
    ids <- levels(fx$data$id)
    b0 <- coef(constant_fit, 'sd_relmat(id, dpar = "mu", coef = "(Intercept)")')
    b1 <- coef(constant_fit, 'sd_relmat(id, dpar = "mu", coef = "x")')
    expect_length(b0, 1L)
    expect_length(b1, 1L)
    sds <- list(s0 = rep(exp(unname(b0)), length(ids)),
                s1 = rep(exp(unname(b1)), length(ids)))
    size <- if (family == "nbinom2") {
      exp(-2 * coef(constant_fit, "sigma")[[1L]])
    } else {
      NULL
    }
    reference <- lab_q2_oracle(fx, fx$K[ids, ids], coef(constant_fit, "mu"),
                               sds$s0, sds$s1, size, lab_q2_rho(constant_fit))
    expect_lt(abs(as.numeric(logLik(constant_fit)) - reference), 1e-4)
    if (family == "poisson") {
      # The plain labelled Poisson block (no sd() formulas) is already admitted.
      free_fit <- lab_q2_free_fit(fx)
      expect_equal(free_fit$opt$convergence, 0L)
      expect_lt(abs(as.numeric(logLik(constant_fit)) -
                      as.numeric(logLik(free_fit))), 1e-5)
      expect_equal(lab_q2_rho(constant_fit), lab_q2_rho(free_fit),
                   tolerance = 1e-3)
    }
  }
})

test_that("labelled relmat q2 reports SDs per coefficient and group", {
  skip_on_cran()
  for (family in c("poisson", "nbinom2")) {
    cached <- lab_q2_cached(family, 20261121L)
    fx <- cached$fx
    fit <- cached$labelled
    sds <- lab_q2_sds(fit, fx)
    ids <- levels(fx$data$id)
    p0 <- predict(fit, dpar = sds$keys[[1L]])
    p1 <- predict(fit, dpar = sds$keys[[2L]])
    expect_setequal(names(p0), ids)
    expect_equal(unname(p0[ids]), sds$s0, tolerance = 1e-6)
    expect_equal(unname(p1[ids]), sds$s1, tolerance = 1e-6)
    simulated <- simulate(fit, nsim = 1L, seed = 20261123L, re.form = NULL)
    expect_length(simulated[[1L]], nrow(fx$data))
    expect_true(all(is.finite(simulated[[1L]])))
  }
})

test_that("neighbouring labelled count q2 routes stay refused with designed errors", {
  skip_on_cran()
  fx <- lab_q2_fixture("poisson", 20261121L)
  fx_nb <- lab_q2_fixture("nbinom2", 20261121L)
  d <- fx$data
  K <- fx$supplied
  sd_int <- sd(id, level = "relmat", dpar = "mu", coef = "(Intercept)") ~ w
  sd_x <- sd(id, level = "relmat", dpar = "mu", coef = "x") ~ v

  # Only one of the two coefficients gets an SD formula.
  expect_error(
    lab_q2_fit(fx, only = "intercept"),
    "requires\\s+one\\s+SD\\s+formula\\s+for\\s+each\\s+coefficient"
  )
  expect_error(
    lab_q2_fit(fx_nb, only = "slope"),
    "intercept\\s+plus\\s+one\\s+slope\\s+with\\s+one\\s+SD\\s+formula\\s+per\\s+coefficient"
  )

  # Ordinary random effect beside the labelled relmat q2 block.
  expect_error(
    lab_q2_fit(fx, extra = " + (1 | id)"),
    "non-inflated\\s+model\\s+with\\s+complete\\s+responses|cannot\\s+be\\s+combined"
  )

  # Zero inflation keeps the complete-data gate.
  expect_error(
    drmTMB(bf(y ~ x + relmat(1 + x | p | id, K = K), zi ~ 1, sd_int, sd_x),
           family = stats::poisson(), data = d),
    "non-inflated\\s+model\\s+with\\s+complete\\s+responses"
  )

  # NB2 labelled relmat q2 without SD formulas stays closed.
  expect_error(
    drmTMB(bf(y ~ x + relmat(1 + x | p | id, K = K), sigma ~ 1),
           family = nbinom2(), data = fx_nb$data),
    "only\\s+the\\s+implemented\\s+labelled\\s+covariance\\s+forms"
  )

  # Labelled phylo and spatial q2 SD blocks are not part of this slice.
  skip_if_not_installed("ape")
  tree <- ape::rcoal(nlevels(d$id))
  tree$tip.label <- levels(d$id)
  sd_phy0 <- sd(id, level = "phylogenetic", dpar = "mu",
                coef = "(Intercept)") ~ w
  sd_phy1 <- sd(id, level = "phylogenetic", dpar = "mu", coef = "x") ~ v
  expect_error(
    drmTMB(bf(y ~ x + phylo(1 + x | p | id, tree = tree), sd_phy0, sd_phy1),
           family = stats::poisson(), data = d),
    "require\\s+one\\s+structured\\s+coefficient"
  )
  expect_error(
    drmTMB(bf(y ~ x + phylo(1 + x | p | id, tree = tree), sigma ~ 1,
              sd_phy0, sd_phy1),
           family = nbinom2(), data = fx_nb$data),
    "NB2\\s+structured\\s+SD\\s+regression\\s+currently\\s+supports"
  )
})
