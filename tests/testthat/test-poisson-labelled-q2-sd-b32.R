# Native Poisson labelled intercept-plus-slope (q = 2) with one predictor-
# dependent SD formula per coefficient, on two providers:
#
#   animal(1 + x | p | id, A = A)          (and Ainv = solve(A))
#   spatial(1 + x | p | id, coords = coords)
#
# Meaning of the label: inside one `mu` formula the labelled block adds one
# cross-coefficient correlation rho, so the unit-scale latent prior is
# R kron K with R = [1 rho; rho 1]; the unlabelled block has rho = 0. The
# coefficient SDs scale the fields multiplicatively. These routes were refused
# at the R gate only; the C++ template already carries this prior for Poisson.
#
# Oracle: a dense Laplace marginal likelihood in plain R at the fitted
# parameters INCLUDING the fitted rho. It shares no code with the package or
# the template. The kernel is built here: a Henderson A from an inbred
# pedigree (tabular method) for animal(), and an exponential kernel with range
# equal to the median positive pairwise distance and diagonal 1 + 1e-6 from
# irregular coordinates for spatial().
#
# Tolerances fixed before the first run: 1e-4 absolute on the log-likelihood
# for oracle agreement; every emulated bug must move the oracle by more than
# 0.1 (1000 times the tolerance). This is a likelihood-evaluation check, not a
# recovery, calibration or parity claim.

b32p_pedigree_A <- function(n = 30L, n_founders = 6L) {
  sire <- dam <- rep(NA_integer_, n)
  for (i in seq.int(n_founders + 1L, n)) {
    pool <- seq(max(1L, i - 9L), i - 1L)  # recent animals: inbreeding arises
    pars <- sample(pool, 2L)
    sire[i] <- pars[[1L]]
    dam[i] <- pars[[2L]]
  }
  A <- matrix(0, n, n)
  for (i in seq_len(n)) {
    for (j in seq_len(i - 1L)) {
      a <- if (is.na(sire[i])) 0 else A[j, sire[i]]
      b <- if (is.na(dam[i])) 0 else A[j, dam[i]]
      A[i, j] <- A[j, i] <- 0.5 * (a + b)
    }
    A[i, i] <- 1 + if (is.na(sire[i])) 0 else 0.5 * A[sire[i], dam[i]]
  }
  ids <- sprintf("an%02d", seq_len(n))
  dimnames(A) <- list(ids, ids)
  A
}

b32p_kernel <- function(xy) {
  d <- sqrt(outer(xy[, 1], xy[, 1], "-")^2 + outer(xy[, 2], xy[, 2], "-")^2)
  K <- exp(-d / stats::median(d[upper.tri(d)]))
  diag(K) <- diag(K) + 1e-6
  dimnames(K) <- list(rownames(xy), rownames(xy))
  K
}

b32p_fixture <- function(provider, seed, rho = 0.8, groups = 30L,
                         repeats = 16L) {
  set.seed(seed)
  coords <- NULL
  if (provider == "animal") {
    K <- b32p_pedigree_A(groups)
    ids <- rownames(K)
  } else {
    ids <- sprintf("st%02d", seq_len(groups))
    xy <- cbind(east = stats::runif(groups, 0, 10),
                north = stats::runif(groups, 0, 6))
    rownames(xy) <- ids
    K <- b32p_kernel(xy)
    coords <- xy[sample.int(groups), , drop = FALSE]  # shuffled rows
  }
  # Non-palindromic group-level SD predictors.
  w <- stats::setNames(seq(-1, 1, length.out = groups)[sample.int(groups)], ids)
  v <- stats::setNames(sample(c(rep(-1, 8), rep(1, 12), rep(0.3, 10))), ids)
  s0 <- exp(-0.9 + 0.5 * w)
  s1 <- exp(-1.0 - 0.5 * v)
  L <- t(chol(K))
  z0 <- stats::rnorm(groups)
  z1 <- stats::rnorm(groups)
  b0 <- s0 * drop(L %*% z0)
  b1 <- s1 * drop(L %*% (rho * z0 + sqrt(1 - rho^2) * z1))
  id <- factor(rep(ids, each = repeats), levels = sample(ids))
  x <- rep(seq(-1.2, 1.2, length.out = repeats), times = groups)
  eta <- 0.6 + 0.25 * x + b0[as.character(id)] + b1[as.character(id)] * x
  data <- data.frame(
    y = stats::rpois(length(eta), exp(eta)), x = x, id = id,
    w = unname(w[as.character(id)]), v = unname(v[as.character(id)])
  )
  shuffled <- sample(ids)
  list(provider = provider, data = data, K = K, coords = coords, w = w, v = v,
       supplied = K[shuffled, shuffled])
}

b32p_formula <- function(fx, label = "p", constant = FALSE, use_Ainv = FALSE,
                         only = NULL) {
  A <- fx$supplied
  Ainv <- solve(A)
  coords <- fx$coords
  lab <- if (is.null(label)) "" else paste0(label, " | ")
  term <- switch(
    fx$provider,
    animal = sprintf("animal(1 + x | %sid, %s)", lab,
                     if (use_Ainv) "Ainv = Ainv" else "A = A"),
    spatial = sprintf("spatial(1 + x | %sid, coords = coords)", lab)
  )
  mu <- stats::as.formula(paste("y ~ x +", term))
  environment(mu) <- environment()
  f0 <- stats::as.formula(sprintf(
    'sd(id, level = "%s", dpar = "mu", coef = "(Intercept)") ~ %s',
    fx$provider, if (constant) "1" else "w"), env = environment())
  f1 <- stats::as.formula(sprintf(
    'sd(id, level = "%s", dpar = "mu", coef = "x") ~ %s',
    fx$provider, if (constant) "1" else "v"), env = environment())
  sds <- list(f0, f1)
  if (identical(only, "intercept")) sds <- sds[1L]
  do.call(bf, c(list(mu), sds))
}

b32p_fit <- function(fx, ...) {
  drmTMB(b32p_formula(fx, ...), family = stats::poisson(), data = fx$data,
         control = drm_control(se = FALSE))
}

b32p_keys <- function(provider) {
  c(sprintf('sd_%s(id, dpar = "mu", coef = "(Intercept)")', provider),
    sprintf('sd_%s(id, dpar = "mu", coef = "x")', provider))
}

b32p_sds <- function(fit, fx) {
  keys <- b32p_keys(fx$provider)
  b0 <- coef(fit, keys[[1L]])
  b1 <- coef(fit, keys[[2L]])
  ids <- levels(fx$data$id)
  list(
    s0 = unname(exp(b0[["(Intercept)"]] + b0[["w"]] * fx$w[ids])),
    s1 = unname(exp(b1[["(Intercept)"]] + b1[["v"]] * fx$v[ids])),
    b0 = b0, b1 = b1, keys = keys
  )
}

# Dense Laplace marginal log-likelihood. `K` must be aligned to levels(id).
b32p_oracle <- function(data, K, beta, s0, s1, rho) {
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
  joint <- function(u) {
    sum(stats::dpois(y, exp(offset + drop(Z %*% u)), log = TRUE)) -
      0.5 * drop(t(u) %*% P %*% u)
  }
  u <- rep(0, 2L * G)
  for (iter in 1:300) {
    eta <- offset + drop(Z %*% u)
    mu <- exp(eta)
    grad <- drop(crossprod(Z, y - mu)) - drop(P %*% u)
    H <- crossprod(Z, mu * Z) + P
    step <- drop(solve(H, grad))
    f0 <- joint(u)
    scale <- 1
    while (joint(u + scale * step) < f0 && scale > 1e-12) scale <- scale / 2
    u <- u + scale * step
    if (max(abs(scale * step)) < 1e-11) break
  }
  mu <- exp(offset + drop(Z %*% u))
  H <- crossprod(Z, mu * Z) + P
  joint(u) - 0.5 * logdet_prior -
    0.5 * as.numeric(determinant(H, logarithm = TRUE)$modulus)
}

b32p_rho <- function(fit) {
  rho <- fit$obj$report(fit$obj$env$last.par.best)$rho_phylo
  stopifnot(length(rho) == 1L)
  unname(rho)
}

b32p_cache <- new.env(parent = emptyenv())
b32p_cached <- function(provider, seed, rho = 0.8) {
  key <- paste(provider, seed, rho)
  if (is.null(b32p_cache[[key]])) {
    fx <- b32p_fixture(provider, seed, rho)
    b32p_cache[[key]] <- list(fx = fx, fit = b32p_fit(fx))
  }
  b32p_cache[[key]]
}

b32p_seed <- 20261131L

test_that("independent pedigree A is inbred and the spatial kernel matches the package", {
  skip_on_cran()
  set.seed(b32p_seed)
  A <- b32p_pedigree_A(30L)
  expect_gt(max(diag(A)), 1.05)          # genuinely inbred, non-unit diagonal
  expect_true(isSymmetric(A))
  expect_gt(min(eigen(A, symmetric = TRUE, only.values = TRUE)$values), 1e-8)
  # The same package-native kernel is reached by the coordinate route and by a
  # hand-built K supplied through relmat(): identical likelihood.
  fx <- b32p_cached("spatial", b32p_seed)$fx
  fit_sp <- b32p_cached("spatial", b32p_seed)$fit
  K <- fx$supplied
  d <- fx$data
  fit_rel <- drmTMB(
    bf(y ~ x + relmat(1 + x | p | id, K = K),
       sd(id, level = "relmat", dpar = "mu", coef = "(Intercept)") ~ w,
       sd(id, level = "relmat", dpar = "mu", coef = "x") ~ v),
    family = stats::poisson(), data = d, control = drm_control(se = FALSE)
  )
  expect_lt(abs(as.numeric(logLik(fit_sp)) - as.numeric(logLik(fit_rel))), 1e-4)
})

test_that("Poisson labelled q2 SD fits match a dense Laplace oracle with rho", {
  skip_on_cran()
  for (provider in c("animal", "spatial")) {
    cached <- b32p_cached(provider, b32p_seed)
    fx <- cached$fx
    fit <- cached$fit
    expect_equal(fit$opt$convergence, 0L)
    sds <- b32p_sds(fit, fx)
    expect_gt(stats::sd(log(sds$s0)), 0.1)
    expect_gt(stats::sd(log(sds$s1)), 0.1)
    expect_named(sds$b0, c("(Intercept)", "w"))
    expect_named(sds$b1, c("(Intercept)", "v"))
    ids <- levels(fx$data$id)
    K <- fx$K[ids, ids]
    beta <- coef(fit, "mu")
    rho <- b32p_rho(fit)
    expect_gt(abs(rho), 0.05)
    reference <- b32p_oracle(fx$data, K, beta, sds$s0, sds$s1, rho)
    gap <- abs(as.numeric(logLik(fit)) - reference)
    expect_lt(gap, 1e-4)
    message(sprintf("[b32 poisson %s] oracle gap = %.3e, rho = %.4f",
                    provider, gap, rho))

    bugs <- list(
      swapped_sd_formulas = b32p_oracle(fx$data, K, beta, sds$s1, sds$s0, rho),
      reversed_sd_vector = b32p_oracle(fx$data, K, beta, rev(sds$s0),
                                       rev(sds$s1), rho),
      rho_dropped = b32p_oracle(fx$data, K, beta, sds$s0, sds$s1, 0),
      rho_sign_flipped = b32p_oracle(fx$data, K, beta, sds$s0, sds$s1, -rho),
      kernel_by_position = {
        pos <- if (provider == "animal") {
          unname(fx$supplied)
        } else {
          xy <- fx$coords
          rownames(xy) <- sort(rownames(xy))
          unname(b32p_kernel(xy))
        }
        b32p_oracle(fx$data, pos, beta, sds$s0, sds$s1, rho)
      }
    )
    if (provider == "animal") {
      # A has a non-unit diagonal, so turning it into a correlation matrix is
      # a real error. (The spatial kernel diagonal is 1 + 1e-6: not testable.)
      bugs$cov2cor_kernel <- b32p_oracle(fx$data, stats::cov2cor(K), beta,
                                         sds$s0, sds$s1, rho)
    }
    for (nm in names(bugs)) {
      expect_gt(abs(bugs[[nm]] - reference), 0.1)
    }
    message(sprintf("[b32 poisson %s] smallest bug gap = %.3f (%s)", provider,
                    min(abs(unlist(bugs) - reference)),
                    names(which.min(abs(unlist(bugs) - reference)))))
  }
})

test_that("Poisson labelled q2 estimates one correlation that moves with the data", {
  skip_on_cran()
  for (provider in c("animal", "spatial")) {
    pos <- b32p_cached(provider, b32p_seed, rho = 0.6)
    neg <- b32p_cached(provider, b32p_seed, rho = -0.6)
    key <- "cor(mu:(Intercept),mu:x | p | id)"
    cp <- pos$fit$corpars[[provider]]
    cn <- neg$fit$corpars[[provider]]
    expect_named(cp, key)
    expect_named(cn, key)
    expect_true(is.finite(cp[[1L]]) && abs(cp[[1L]]) < 1)
    expect_equal(unname(cp[[1L]]), b32p_rho(pos$fit), tolerance = 1e-8)
    expect_equal(unname(cn[[1L]]), b32p_rho(neg$fit), tolerance = 1e-8)
    expect_gt(unname(cp[[1L]]) - unname(cn[[1L]]), 0.3)
    message(sprintf("[b32 poisson %s] rho_hat: %.3f (true +0.6) vs %.3f (true -0.6)",
                    provider, cp[[1L]], cn[[1L]]))
    # The label name is arbitrary; the unlabelled fit has no correlation and is
    # nested in the labelled one.
    renamed <- b32p_fit(pos$fx, label = "q")
    expect_equal(as.numeric(logLik(renamed)), as.numeric(logLik(pos$fit)),
                 tolerance = 1e-6)
    expect_named(renamed$corpars[[provider]],
                 "cor(mu:(Intercept),mu:x | q | id)")
    unlabelled <- b32p_fit(pos$fx, label = NULL)
    expect_null(unlabelled$corpars[[provider]])
    expect_gte(as.numeric(logLik(pos$fit)),
               as.numeric(logLik(unlabelled)) - 1e-6)
    expect_equal(names(coef(pos$fit)), names(coef(unlabelled)))
  }
})

test_that("animal labelled q2 with Ainv equals the A fit, and constants reduce to the plain block", {
  skip_on_cran()
  cached <- b32p_cached("animal", b32p_seed)
  fit_ainv <- b32p_fit(cached$fx, use_Ainv = TRUE)
  expect_lt(abs(as.numeric(logLik(fit_ainv)) - as.numeric(logLik(cached$fit))),
            1e-4)
  for (provider in c("animal", "spatial")) {
    fx <- b32p_cached(provider, b32p_seed)$fx
    const_fit <- b32p_fit(fx, constant = TRUE)
    expect_equal(const_fit$opt$convergence, 0L)
    keys <- b32p_keys(provider)
    ids <- levels(fx$data$id)
    s0 <- rep(exp(unname(coef(const_fit, keys[[1L]]))), length(ids))
    s1 <- rep(exp(unname(coef(const_fit, keys[[2L]]))), length(ids))
    reference <- b32p_oracle(fx$data, fx$K[ids, ids], coef(const_fit, "mu"),
                             s0, s1, b32p_rho(const_fit))
    expect_lt(abs(as.numeric(logLik(const_fit)) - reference), 1e-4)
  }
})

test_that("labelled q2 reports SDs per coefficient and group, and simulates marginally", {
  skip_on_cran()
  for (provider in c("animal", "spatial")) {
    cached <- b32p_cached(provider, b32p_seed)
    fx <- cached$fx
    fit <- cached$fit
    sds <- b32p_sds(fit, fx)
    ids <- levels(fx$data$id)
    p0 <- predict(fit, dpar = sds$keys[[1L]])
    p1 <- predict(fit, dpar = sds$keys[[2L]])
    expect_setequal(names(p0), ids)
    expect_equal(unname(p0[ids]), sds$s0, tolerance = 1e-6)
    expect_equal(unname(p1[ids]), sds$s1, tolerance = 1e-6)
    cond <- simulate(fit, nsim = 1L, seed = 20261132L, re.form = NULL)
    expect_length(cond[[1L]], nrow(fx$data))
    expect_true(all(is.finite(cond[[1L]])))

    # Marginal simulation: E[y_i] = exp(offset_i + Var(re_i) / 2) with
    # Var(re_i) = K_gg (s0^2 + x^2 s1^2 + 2 rho x s0 s1). Compared by a pooled
    # standardised statistic; the rho-dropped mean must be clearly worse.
    nsim <- 1500L
    sim <- as.matrix(simulate(fit, nsim = nsim, seed = 20261133L, re.form = NA))
    K <- fx$K[ids, ids]
    gi <- as.integer(fx$data$id)
    x <- fx$data$x
    beta <- coef(fit, "mu")
    rho <- b32p_rho(fit)
    expected <- function(r) {
      v <- diag(K)[gi] * (sds$s0[gi]^2 + x^2 * sds$s1[gi]^2 +
                            2 * r * x * sds$s0[gi] * sds$s1[gi])
      exp(beta[[1L]] + beta[[2L]] * x + v / 2)
    }
    se <- apply(sim, 1L, stats::sd) / sqrt(nsim)
    z2 <- function(r) mean(((rowMeans(sim) - expected(r)) / se)^2)
    message(sprintf("[b32 poisson %s] marginal mean z2: fitted rho %.2f, rho=0 %.2f",
                    provider, z2(rho), z2(0)))
    expect_lt(z2(rho), 2.5)
    expect_gt(z2(0), z2(rho) + 0.1)
  }
})

test_that("neighbouring labelled Poisson q2 routes stay refused or unchanged", {
  skip_on_cran()
  for (provider in c("animal", "spatial")) {
    fx <- b32p_cached(provider, b32p_seed)$fx
    # One SD formula for two coefficients.
    expect_error(
      b32p_fit(fx, only = "intercept"),
      "requires\\s+one\\s+SD\\s+formula\\s+for\\s+each\\s+coefficient"
    )
  }
  # A zero-inflated labelled block keeps the complete-data gate.
  fx <- b32p_cached("animal", b32p_seed)$fx
  A <- fx$supplied
  d <- fx$data
  expect_error(
    drmTMB(bf(y ~ x + animal(1 + x | p | id, A = A), zi ~ 1,
              sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ w,
              sd(id, level = "animal", dpar = "mu", coef = "x") ~ v),
           family = stats::poisson(), data = d),
    "non-inflated\\s+model\\s+with\\s+complete\\s+responses"
  )
  # Missing-response integration stays closed for the labelled block.
  d_miss <- d
  d_miss$y[c(3L, 40L)] <- NA
  expect_error(
    drmTMB(bf(y ~ x + animal(1 + x | p | id, A = A),
              sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ w,
              sd(id, level = "animal", dpar = "mu", coef = "x") ~ v),
           family = stats::poisson(), data = d_miss,
           missing = miss_control(response = "include")),
    "complete\\s+responses"
  )
})
