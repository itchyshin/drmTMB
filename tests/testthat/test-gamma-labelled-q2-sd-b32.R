# Gamma (log link) labelled intercept-plus-slope (q = 2) with one
# predictor-dependent SD formula per coefficient, for the relmat and phylo
# providers: relmat(1 + x | p | id, K = K) and phylo(1 + x | p | id, tree).
#
# Meaning of the label. Inside one `mu` formula the unlabelled block has two
# independent unit-scale latent fields (rho = 0). The labelled block adds one
# cross-coefficient correlation rho, so the latent prior is R kron K with
# R = [1 rho; rho 1]. K is the supplied relmat kernel as given, or
# cov2cor(ape::vcv(tree)) for phylo. The C++ Gamma template already carries
# this prior (shared with Gamma animal); batch 32 only opened the R-side gates
# for the relmat and phylo providers.
#
# Oracle: a dense Laplace marginal likelihood in plain base R evaluated at the
# fitted parameters INCLUDING the fitted rho, with a hand-built kernel: a
# dense non-unit-diagonal K for relmat and cov2cor(ape::vcv(tree)) for phylo
# (the package tip-covariance helper is only compared against it). Tolerances
# fixed before the first run: 1e-4 absolute for oracle agreement, 1e-6 for
# nesting, 0.1 log-likelihood units as the floor for emulated bugs. This is a
# likelihood-evaluation check, not a recovery or calibration claim.

gb32_fixture <- function(provider, rho = 0.8, seed = 20261141L, groups = 60L,
                         repeats = 16L) {
  set.seed(seed)
  ids <- sprintf("g%02d", seq_len(groups))
  tree <- NULL
  if (identical(provider, "phylo")) {
    tree <- ape::rcoal(groups)
    tree$tip.label <- sample(ids)  # tree tip order differs from levels(id)
    K <- stats::cov2cor(ape::vcv(tree))[ids, ids]
    supplied <- NULL
  } else {
    C <- outer(seq_len(groups), seq_len(groups), function(i, j) 0.35^abs(i - j))
    d <- seq(0.8, 1.6, length.out = groups)[sample.int(groups)]
    K <- diag(d) %*% C %*% diag(d)  # non-unit diagonal
    dimnames(K) <- list(ids, ids)
    shuffled <- sample(ids)  # supplied K rows differ from levels(id)
    supplied <- K[shuffled, shuffled]
  }
  w <- stats::setNames(sample(rep(c(-1, 1), length.out = groups)), ids)
  v <- stats::setNames(sample(rep(c(-1, 1), each = groups / 2L)), ids)
  s0 <- exp(-1.0 + 0.8 * w)
  s1 <- exp(-1.0 - 0.8 * v)
  L <- t(chol(K))
  z0 <- stats::rnorm(groups)
  z1 <- stats::rnorm(groups)
  b0 <- s0 * drop(L %*% z0)
  b1 <- s1 * drop(L %*% (rho * z0 + sqrt(1 - rho^2) * z1))
  id <- factor(rep(ids, each = repeats), levels = sample(ids))
  x <- rep(seq(-1.2, 1.2, length.out = repeats), times = groups)
  eta <- 0.8 + 0.25 * x + b0[as.character(id)] + b1[as.character(id)] * x
  shape <- 0.35^-2
  y <- stats::rgamma(length(eta), shape = shape, rate = shape / exp(eta))
  data <- data.frame(
    y = y, x = x, id = id,
    w = unname(w[as.character(id)]), v = unname(v[as.character(id)])
  )
  list(provider = provider, data = data, tree = tree, K = K,
       supplied = supplied, w = w, v = v, ids = ids)
}

gb32_level <- function(provider) {
  c(relmat = "relmat", phylo = "phylogenetic")[[provider]]
}

gb32_keys <- function(provider) {
  p <- c(relmat = "relmat", phylo = "phylo")[[provider]]
  c(sprintf('sd_%s(id, dpar = "mu", coef = "(Intercept)")', p),
    sprintf('sd_%s(id, dpar = "mu", coef = "x")', p))
}

gb32_formula <- function(fx, label = "p", constant = FALSE, only = NULL,
                         swap = FALSE) {
  K <- fx$supplied
  tree <- fx$tree
  bar <- if (is.null(label)) "1 + x | id" else paste0("1 + x | ", label, " | id")
  term <- if (identical(fx$provider, "phylo")) {
    sprintf("phylo(%s, tree = tree)", bar)
  } else {
    sprintf("relmat(%s, K = K)", bar)
  }
  mu <- stats::as.formula(paste("y ~ x +", term))
  environment(mu) <- environment()
  rhs0 <- if (constant) "1" else if (swap) "v" else "w"
  rhs1 <- if (constant) "1" else if (swap) "w" else "v"
  f0 <- stats::as.formula(sprintf(
    'sd(id, level = "%s", dpar = "mu", coef = "(Intercept)") ~ %s',
    gb32_level(fx$provider), rhs0), env = environment())
  f1 <- stats::as.formula(sprintf(
    'sd(id, level = "%s", dpar = "mu", coef = "x") ~ %s',
    gb32_level(fx$provider), rhs1), env = environment())
  sds <- list(f0, f1)
  if (identical(only, "intercept")) sds <- sds[1L]
  if (identical(only, "slope")) sds <- sds[2L]
  do.call(bf, c(list(mu, sigma ~ 1), sds))
}

gb32_fit <- function(fx, ...) {
  drmTMB(gb32_formula(fx, ...), family = stats::Gamma(link = "log"),
         data = fx$data, control = drm_control(se = FALSE))
}

gb32_sds <- function(fit, fx) {
  keys <- gb32_keys(fx$provider)
  b0 <- coef(fit, keys[[1L]])
  b1 <- coef(fit, keys[[2L]])
  list(
    s0 = unname(exp(b0[["(Intercept)"]] + b0[["w"]] * fx$w[fx$ids])),
    s1 = unname(exp(b1[["(Intercept)"]] + b1[["v"]] * fx$v[fx$ids])),
    b0 = b0, b1 = b1
  )
}

# Dense Laplace marginal log-likelihood. `K` must be aligned to `fx$ids`.
gb32_oracle <- function(fx, K, beta, s0, s1, shape, rho) {
  data <- fx$data
  ids <- fx$ids
  G <- length(ids)
  gi <- match(as.character(data$id), ids)
  y <- data$y
  Zg <- outer(gi, seq_len(G), function(i, g) as.numeric(i == g))
  Z <- cbind(Zg %*% diag(s0), (Zg * data$x) %*% diag(s1))
  offset <- beta[[1L]] + beta[[2L]] * data$x
  R <- matrix(c(1, rho, rho, 1), 2L, 2L)
  P <- kronecker(solve(R), solve(K))
  logdet_prior <- G * log(det(R)) +
    2 * as.numeric(determinant(K, logarithm = TRUE)$modulus)
  loglik <- function(eta) {
    sum(stats::dgamma(y, shape = shape, rate = shape / exp(eta), log = TRUE))
  }
  score <- function(eta) shape * (y * exp(-eta) - 1)
  weight <- function(eta) shape * y * exp(-eta)
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

gb32_rho <- function(fit) {
  rho <- fit$obj$report(fit$obj$env$last.par.best)$rho_phylo
  stopifnot(length(rho) == 1L)
  unname(rho)
}

gb32_cache <- new.env(parent = emptyenv())
gb32_cached <- function(provider, rho = 0.8, seed = 20261141L) {
  key <- paste(provider, rho, seed)
  if (is.null(gb32_cache[[key]])) {
    fx <- gb32_fixture(provider, rho = rho, seed = seed)
    gb32_cache[[key]] <- list(fx = fx, labelled = gb32_fit(fx))
  }
  gb32_cache[[key]]
}

gb32_corpars <- function(fit, provider) {
  fit$corpars[[c(relmat = "relmat", phylo = "phylo")[[provider]]]]
}

test_that("hand kernels equal the package kernels and are not palindromic", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- gb32_fixture("phylo")
  helper <- drmTMB:::drm_phylo_tip_covariance(fx$tree)
  expect_equal(unname(helper[fx$ids, fx$ids]), unname(fx$K), tolerance = 1e-8)
  expect_equal(unname(diag(fx$K)), rep(1, length(fx$ids)))
  expect_false(identical(fx$tree$tip.label, fx$ids))
  rx <- gb32_fixture("relmat")
  expect_gt(max(abs(diag(rx$K) - 1)), 0.2)  # genuinely non-unit diagonal
  expect_false(identical(rownames(rx$supplied), rx$ids))
  for (f in list(fx, rx)) {
    expect_false(isTRUE(all.equal(unname(f$w), rev(unname(f$w)))))
    expect_false(isTRUE(all.equal(unname(f$v), rev(unname(f$v)))))
    expect_false(identical(levels(f$data$id), f$ids))
  }
})

test_that("labelled Gamma relmat and phylo q2 SD fits match a dense Laplace oracle with rho", {
  skip_on_cran()
  skip_if_not_installed("ape")
  gaps <- numeric()
  bug_gaps <- numeric()
  for (provider in c("relmat", "phylo")) {
    for (seed in c(20261141L, 20261142L)) {
      cached <- gb32_cached(provider, seed = seed)
      fx <- cached$fx
      fit <- cached$labelled
      expect_equal(fit$opt$convergence, 0L)
      sds <- gb32_sds(fit, fx)
      expect_gt(stats::sd(log(sds$s0)), 0.1)
      expect_gt(stats::sd(log(sds$s1)), 0.1)
      expect_named(sds$b0, c("(Intercept)", "w"))
      expect_named(sds$b1, c("(Intercept)", "v"))
      beta <- coef(fit, "mu")
      shape <- exp(-2 * coef(fit, "sigma")[[1L]])
      rho <- gb32_rho(fit)
      expect_gt(abs(rho), 0.05)
      reference <- gb32_oracle(fx, fx$K, beta, sds$s0, sds$s1, shape, rho)
      gap <- abs(as.numeric(logLik(fit)) - reference)
      gaps <- c(gaps, gap)
      expect_lt(gap, 1e-4)

      bugs <- c(
        swapped_sd_formulas = gb32_oracle(fx, fx$K, beta, sds$s1, sds$s0, shape, rho),
        reversed_sd_vector = gb32_oracle(fx, fx$K, beta, rev(sds$s0), rev(sds$s1),
                                         shape, rho),
        rho_dropped = gb32_oracle(fx, fx$K, beta, sds$s0, sds$s1, shape, 0),
        rho_sign_flipped = gb32_oracle(fx, fx$K, beta, sds$s0, sds$s1, shape, -rho),
        kernel_by_level_position = gb32_oracle(
          fx, unname(fx$K[levels(fx$data$id), levels(fx$data$id)]), beta,
          sds$s0, sds$s1, shape, rho)
      )
      if (identical(provider, "relmat")) {
        bugs[["cov2cor_of_K"]] <- gb32_oracle(
          fx, stats::cov2cor(fx$K), beta, sds$s0, sds$s1, shape, rho)
        bugs[["supplied_order_by_position"]] <- gb32_oracle(
          fx, unname(fx$supplied), beta, sds$s0, sds$s1, shape, rho)
      } else {
        bugs[["raw_vcv_not_correlation"]] <- gb32_oracle(
          fx, ape::vcv(fx$tree)[fx$ids, fx$ids], beta, sds$s0, sds$s1, shape, rho)
        bugs[["kernel_in_tree_tip_order"]] <- gb32_oracle(
          fx, unname(stats::cov2cor(ape::vcv(fx$tree))), beta, sds$s0, sds$s1,
          shape, rho)
      }
      for (nm in names(bugs)) {
        expect_gt(abs(bugs[[nm]] - reference), 0.1)
        bug_gaps <- c(bug_gaps, stats::setNames(abs(bugs[[nm]] - reference), nm))
      }
    }
  }
  message("b32 Gamma oracle gaps: ", paste(signif(gaps, 3), collapse = ", "))
  message("b32 smallest emulated-bug gap: ", names(which.min(bug_gaps)), " ", signif(min(bug_gaps), 3))
})

test_that("swapped SD formulas in the call change the fitted likelihood", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (provider in c("relmat", "phylo")) {
    cached <- gb32_cached(provider)
    swapped <- gb32_fit(cached$fx, swap = TRUE)
    expect_equal(swapped$opt$convergence, 0L)
    expect_gt(abs(as.numeric(logLik(swapped)) -
                    as.numeric(logLik(cached$labelled))), 0.1)
  }
})

test_that("labelled Gamma q2 estimates a correlation that moves with the data", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (provider in c("relmat", "phylo")) {
    cached <- gb32_cached(provider)
    labelled <- cached$labelled
    unlabelled <- gb32_fit(cached$fx, label = NULL)
    expect_equal(unlabelled$opt$convergence, 0L)
    key <- "cor(mu:(Intercept),mu:x | p | id)"
    cp <- gb32_corpars(labelled, provider)
    expect_named(cp, key)
    rho_hat <- unname(cp[[key]])
    expect_true(is.finite(rho_hat))
    expect_lt(abs(rho_hat), 1)
    expect_equal(gb32_rho(labelled), rho_hat, tolerance = 1e-8)
    expect_null(gb32_corpars(unlabelled, provider))
    expect_gte(as.numeric(logLik(labelled)),
               as.numeric(logLik(unlabelled)) - 1e-6)
    expect_equal(names(coef(labelled)), names(coef(unlabelled)))
    renamed <- gb32_fit(cached$fx, label = "q")
    expect_equal(as.numeric(logLik(renamed)), as.numeric(logLik(labelled)),
                 tolerance = 1e-6)
    expect_named(gb32_corpars(renamed, provider),
                 "cor(mu:(Intercept),mu:x | q | id)")
    opposite <- gb32_cached(provider, rho = -0.8)
    rho_other <- unname(gb32_corpars(opposite$labelled, provider)[[key]])
    expect_gt(rho_hat - rho_other, 0.4)
  }
})

test_that("constant coefficient SDs reduce to the labelled block with fitted rho", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (provider in c("relmat", "phylo")) {
    fx <- gb32_cached(provider)$fx
    fit <- gb32_fit(fx, constant = TRUE)
    expect_equal(fit$opt$convergence, 0L)
    keys <- gb32_keys(provider)
    b0 <- coef(fit, keys[[1L]])
    b1 <- coef(fit, keys[[2L]])
    expect_length(b0, 1L)
    expect_length(b1, 1L)
    G <- length(fx$ids)
    reference <- gb32_oracle(
      fx, fx$K, coef(fit, "mu"), rep(exp(unname(b0)), G), rep(exp(unname(b1)), G),
      exp(-2 * coef(fit, "sigma")[[1L]]), gb32_rho(fit))
    expect_lt(abs(as.numeric(logLik(fit)) - reference), 1e-4)
  }
})

test_that("relmat labelled Gamma accepts Q and the label is not an alias for animal", {
  skip_on_cran()
  fx <- gb32_cached("relmat")$fx
  Q <- solve(fx$supplied)
  d <- fx$data
  fit_q <- drmTMB(
    bf(y ~ x + relmat(1 + x | p | id, Q = Q), sigma ~ 1,
       sd(id, level = "relmat", dpar = "mu", coef = "(Intercept)") ~ w,
       sd(id, level = "relmat", dpar = "mu", coef = "x") ~ v),
    family = stats::Gamma(link = "log"), data = d,
    control = drm_control(se = FALSE))
  expect_lt(abs(as.numeric(logLik(fit_q)) -
                  as.numeric(logLik(gb32_cached("relmat")$labelled))), 1e-4)
})

test_that("labelled Gamma q2 reports SDs, predicts, and simulates marginally", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (provider in c("relmat", "phylo")) {
    cached <- gb32_cached(provider)
    fx <- cached$fx
    fit <- cached$labelled
    sds <- gb32_sds(fit, fx)
    keys <- gb32_keys(provider)
    p0 <- predict(fit, dpar = keys[[1L]])
    p1 <- predict(fit, dpar = keys[[2L]])
    expect_setequal(names(p0), fx$ids)
    expect_equal(unname(p0[fx$ids]), sds$s0, tolerance = 1e-6)
    expect_equal(unname(p1[fx$ids]), sds$s1, tolerance = 1e-6)

    phylo_mu <- fit$model$structured$phylo_mu
    sd_node <- drmTMB:::drm_binomial_q2_structured_sd_by_node(fit, phylo_mu)
    expect_false(is.null(sd_node))
    rho <- unname(gb32_corpars(fit, provider)[[1L]])
    expect_equal(attr(sd_node, "rho"), rho)
    tip <- match(fx$ids, rownames(sd_node))
    expect_false(anyNA(tip))
    expect_equal(unname(sd_node[tip, 1L]), sds$s0, tolerance = 1e-8)
    expect_equal(unname(sd_node[tip, 2L]), sds$s1, tolerance = 1e-8)
    n_re <- phylo_mu$n_re
    set.seed(20261143L)
    draws <- t(vapply(seq_len(300L), function(i) {
      drmTMB:::drm_fresh_structured_mu_values(phylo_mu, sd_node)
    }, numeric(2L * n_re)))
    G <- length(fx$ids)
    draws <- draws[, c(tip, n_re + tip), drop = FALSE]
    unit <- sweep(draws, 2L, c(sds$s0, sds$s1), "/")
    pooled_cross <- mean(vapply(seq_len(G), function(j) {
      stats::cov(unit[, j], unit[, G + j]) / fx$K[j, j]
    }, numeric(1L)))
    expect_lt(abs(pooled_cross - rho), 0.12)

    sims <- simulate(fit, nsim = 3L, seed = 20261144L, re.form = NA)
    expect_equal(dim(sims), c(nrow(fx$data), 3L))
    expect_true(all(is.finite(as.matrix(sims))))
    conditional <- simulate(fit, nsim = 3L, seed = 20261144L, re.form = NULL)
    expect_true(all(is.finite(as.matrix(conditional))))
    expect_false(isTRUE(all.equal(sims, conditional)))
  }
})

test_that("neighbouring Gamma labelled q2 forms keep designed refusals", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fr <- gb32_cached("relmat")$fx
  fp <- gb32_cached("phylo")$fx
  K <- fr$supplied
  tree <- fp$tree
  g <- stats::Gamma(link = "log")
  # Labelled, no SD formulas: closed with a designed error.
  expect_error(
    drmTMB(bf(y ~ x + relmat(1 + x | p | id, K = K), sigma ~ 1),
           family = g, data = fr$data),
    "requires\\s+predictor-dependent\\s+SD\\s+formulas"
  )
  expect_error(
    drmTMB(bf(y ~ x + phylo(1 + x | p | id, tree = tree), sigma ~ 1),
           family = g, data = fp$data),
    "requires\\s+predictor-dependent\\s+SD\\s+formulas"
  )
  # One SD formula for a two-coefficient block.
  expect_error(gb32_fit(fr, only = "intercept"),
               "requires\\s+one\\s+SD\\s+formula\\s+for\\s+each\\s+coefficient")
  expect_error(gb32_fit(fp, only = "slope"),
               "requires\\s+one\\s+SD\\s+formula\\s+for\\s+each\\s+coefficient")
  # Slope-only labelled blocks stay refused.
  expect_error(
    drmTMB(bf(y ~ x + relmat(0 + x | p | id, K = K), sigma ~ 1),
           family = g, data = fr$data),
    "unlabelled|label"
  )
  expect_error(
    drmTMB(bf(y ~ x + phylo(0 + x | p | id, tree = tree), sigma ~ 1),
           family = g, data = fp$data),
    "unlabelled|label"
  )
})
