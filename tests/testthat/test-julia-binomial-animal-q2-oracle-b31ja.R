# Batch 31 (group ja) independent-oracle companion for the live Julia Binomial
# animal(1 + x | id) correlated q2 block with an sd() formula on each
# coefficient. Companions covered (14 ledger rows, one fit covers the mu:I and
# mu:x1 targets of a (provider, link) pair):
#   provider A (covariance): logit, probit, cloglog
#   provider Ainv (precision): logit
#   provider pedigree: logit, probit, cloglog
# Existing tests (test-julia-binomial-animal-q2-sd.R, -q2-sd-ainv.R,
# -q2-pedigree.R) compare Julia with native TMB at loose tolerances only; none
# has an independent oracle or emulated-bug sensitivity.
#
# Here a base-R dense joint-Newton Laplace oracle (helper-b31ja-oracle.R:
# Henderson tabular A from an inbred pedigree whose diag(A) varies between 1.25
# and 1.67, hand-built 2m x 2m covariance (S_k S_l' * R_kl * A), hand-derived
# observed Bernoulli derivatives) is evaluated at the Julia estimates, with the
# SD vectors built by hand from the fitted coefficients and the correlation
# read from the fitted cor((Intercept),x | id). The Julia logLik must agree to
# 1e-3 absolute; every emulated bug (swapped coefficient sets, reversed SD
# vector for each coefficient, A * 2, A * 1.3, cov2cor(A) with a non-constant
# diagonal, A read by position, flipped rho) must move the oracle by more than
# 20 times that. The SD selectors are random (non-palindromic, non-monotone)
# and A's row order differs from the factor level order.
# Scope: one fixture per route; no calibration, coverage or broad parity claim.

b31ja_q2_fixture <- function(link, seed, n_family = 12L, repeats = 24L) {
  set.seed(seed)
  an <- b31ja_inbred_animals(n_family)
  A <- an$A
  m <- nrow(A)
  lev <- sort(rownames(A))              # factor level order differs from A order
  z0 <- stats::setNames(b31ja_selector(m), rownames(A))
  z1 <- stats::setNames(b31ja_selector(m), rownames(A))
  idx <- rep(seq_len(m), each = repeats)
  id <- factor(lev[idx], levels = lev)
  x <- stats::rnorm(length(id))
  a0 <- c(-0.6, 0.5)
  a1 <- c(-0.75, 0.6)
  rho <- 0.4
  s0 <- exp(a0[[1L]] + a0[[2L]] * z0)
  s1 <- exp(a1[[1L]] + a1[[2L]] * z1)
  L <- t(chol(A))
  l0 <- drop(L %*% stats::rnorm(m))
  l1 <- rho * l0 + sqrt(1 - rho^2) * drop(L %*% stats::rnorm(m))
  names(l0) <- names(l1) <- rownames(A)
  key <- as.character(id)
  eta <- -0.1 + 0.25 * x + (s0 * l0)[key] + x * (s1 * l1)[key]
  p <- switch(link, logit = stats::plogis(eta), probit = stats::pnorm(eta),
              cloglog = -expm1(-exp(eta)))
  data <- data.frame(y = stats::rbinom(length(eta), 1L, p), x = x,
                     z0 = z0[key], z1 = z1[key], id = id,
                     row.names = NULL)
  list(data = data, A = A, pedigree = an$pedigree)
}

b31ja_q2_oracle <- function(link, data, K, beta, a0, a1, rho,
                            z0 = NULL, z1 = NULL) {
  rn <- rownames(K)
  m <- length(rn)
  idx <- match(as.character(data$id), rn)
  per_level <- function(v) v[match(rn, as.character(data$id))]
  z0m <- if (is.null(z0)) per_level(data$z0) else z0
  z1m <- if (is.null(z1)) per_level(data$z1) else z1
  s0 <- exp(a0[[1L]] + a0[[2L]] * z0m)
  s1 <- exp(a1[[1L]] + a1[[2L]] * z1m)
  C <- rbind(
    cbind(outer(s0, s0) * K, rho * outer(s0, s1) * K),
    cbind(rho * outer(s1, s0) * K, outer(s1, s1) * K)
  )
  n <- nrow(data)
  M <- matrix(0, n, 2L * m)
  M[cbind(seq_len(n), idx)] <- 1
  M[cbind(seq_len(n), m + idx)] <- data$x
  eta_fixed <- beta[[1L]] + beta[[2L]] * data$x
  b31ja_laplace(link, data$y, eta_fixed, M, solve(C))
}

b31ja_q2_check <- function(fit, fx, link, tag, K = fx$A, agreement_tol = 1e-3,
                           check_max = FALSE) {
  data <- fx$data
  expect_identical(fit$opt$convergence, 0L, info = tag)
  beta <- unname(coef(fit, dpar = "mu"))
  k0 <- b31ja_target_key(fit, "|mu|intercept|")
  k1 <- b31ja_target_key(fit, "|mu|x|")
  a0 <- unname(coef(fit, dpar = k0))
  a1 <- unname(coef(fit, dpar = k1))
  expect_identical(names(coef(fit, dpar = k0)), c("(Intercept)", "z0"))
  expect_identical(names(coef(fit, dpar = k1)), c("(Intercept)", "z1"))
  cors <- fit$corpars$mu
  expect_named(cors, "cor((Intercept),x | id)")
  rho <- unname(cors[[1L]])
  ll <- as.numeric(logLik(fit))
  oracle <- function(...) {
    args <- list(link = link, data = data, K = K, beta = beta, a0 = a0,
                 a1 = a1, rho = rho)
    over <- list(...)
    args[names(over)] <- over
    do.call(b31ja_q2_oracle, args)
  }
  base <- oracle()
  expect_lt(abs(ll - base), agreement_tol, label = paste(tag, "agreement"))

  rn <- rownames(K)
  z0m <- data$z0[match(rn, as.character(data$id))]
  z1m <- data$z1[match(rn, as.character(data$id))]
  K_pos <- K
  dimnames(K_pos) <- list(sort(rn), sort(rn))
  K_rev <- K
  dimnames(K_rev) <- list(rev(rn), rev(rn))
  expect_gt(diff(range(diag(K))), 0.3)
  gaps <- c(
    swapped_coef_sets = oracle(a0 = a1, a1 = a0),
    reversed_sd_vector_intercept = oracle(z0 = rev(z0m)),
    reversed_sd_vector_x = oracle(z1 = rev(z1m)),
    A_scale_2 = oracle(K = 2 * K),
    A_scale_1.3 = oracle(K = 1.3 * K),
    cov2cor_A = oracle(K = stats::cov2cor(K)),
    A_read_by_position = oracle(K = K_pos),
    A_dimnames_reversed = oracle(K = K_rev),
    flipped_rho = oracle(rho = -rho)
  ) - base
  b31ja_expect_gaps(gaps, agreement_tol, tag)
  if (check_max) {
    for (k in 1:2) {
      for (sgn in c(-0.1, 0.1)) {
        b <- beta; b[[k]] <- b[[k]] + sgn
        p0 <- a0; p0[[k]] <- p0[[k]] + sgn
        p1 <- a1; p1[[k]] <- p1[[k]] + sgn
        expect_lt(oracle(beta = b), base + agreement_tol)
        expect_lt(oracle(a0 = p0), base + agreement_tol)
        expect_lt(oracle(a1 = p1), base + agreement_tol)
      }
    }
  }
  b31ja_report(tag, ll, base, gaps)
  invisible(list(ll = ll, base = base, min_gap = min(abs(gaps))))
}

test_that("Julia Binomial animal q2 block (A, Ainv, pedigree; logit, probit, cloglog) matches a dense Laplace oracle and every emulated bug moves it far", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path),
          "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  b31ja_expect_link_terms()
  links <- c("logit", "probit", "cloglog")
  sd_terms <- list(
    quote(sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ z0),
    quote(sd(id, level = "animal", dpar = "mu", coef = "x") ~ z1)
  )
  fit_route <- function(provider, fx, link) {
    A <- fx$A
    Ainv <- solve(A)
    pedigree <- fx$pedigree
    main <- switch(
      provider,
      A = quote(y ~ x + animal(1 + x | id, A = A)),
      Ainv = quote(y ~ x + animal(1 + x | id, Ainv = Ainv)),
      pedigree = quote(y ~ x + animal(1 + x | id, pedigree = pedigree))
    )
    fml <- eval(as.call(c(list(quote(bf), main), sd_terms)))
    drmTMB(fml, family = stats::binomial(link = link), data = fx$data,
           engine = "julia")
  }

  for (i in seq_along(links)) {
    link <- links[[i]]
    fx <- b31ja_q2_fixture(link, seed = 20261102L + i)
    for (provider in c("A", if (link == "logit") "Ainv", "pedigree")) {
      fit <- fit_route(provider, fx, link)
      b31ja_q2_check(fit, fx, link, tag = paste(provider, link),
                     check_max = identical(c(provider, link), c("A", "logit")))
    }
  }
})
