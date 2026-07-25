# Score-consistency (Bartlett identity) audit -- Arc B slice S2b.
#
# `simulate.drmTMB()` (R/methods.R) is a from-scratch R implementation
# (rnorm/rpois/rbeta/rnbinom/... draws) -- there are zero `SIMULATE` blocks in
# src/drmTMB.cpp and zero calls to `obj$simulate`/`object$obj$simulate`
# anywhere in R/. It is therefore a genuine oracle, independent of the
# compiled likelihood: unlike a finite-difference check on the taped density,
# a wrong normalizing constant in the C++ density can make the score
# identities below fail even though the density differentiates perfectly.
#
# For each route we: (1) fit at some parameter vector theta0 (fixed, printed
# in this file); (2) simulate `nsim` replicate response vectors from the
# fitted model at theta0 via simulate(); (3) rebuild a fresh TMB::MakeADFun
# object per replicate with only the response swapped in, and evaluate the
# score `obj$gr(theta0)`; (4) test First Bartlett (E[score] = 0, via a
# per-component z-statistic using the Monte Carlo SE) and Second Bartlett
# (Var(score) ~= E[Hessian(nll)] -- the sign is *not* flipped, since
# nll = -loglik already carries the minus sign the classical
# Var(score) = -E[Hessian(loglik)] identity needs).

score_consistency <- function(fit, nsim, seed, response_field = "y",
                               tight_inner = FALSE) {
  theta0 <- fit$opt$par
  par_list0 <- fit$obj$env$parList(theta0)
  tmb_data0 <- fit$model$tmb_data
  sims <- simulate(fit, nsim = nsim, seed = seed)

  p <- length(theta0)
  scores <- matrix(NA_real_, nrow = nsim, ncol = p)
  hess_sum <- matrix(0, p, p)
  n_he_ok <- 0

  for (j in seq_len(nsim)) {
    d <- tmb_data0
    d[[response_field]] <- sims[[j]]
    obj_j <- TMB::MakeADFun(
      data = d,
      parameters = par_list0,
      map = fit$model$map,
      random = fit$model$tmb_random_names,
      DLL = "drmTMB",
      silent = TRUE
    )
    if (tight_inner && length(fit$model$tmb_random_names) > 0L) {
      # Pin the inner solve: warm-start from the current random-effect slot
      # rather than TMB's default, so replicate-to-replicate inner-solve
      # drift cannot contaminate the score (per Arc B brief).
      obj_j$env$random.start <- expression(par[random])
    }
    scores[j, ] <- obj_j$gr(theta0)

    he_j <- try(obj_j$he(theta0), silent = TRUE)
    if (inherits(he_j, "try-error")) {
      # obj$he() is not implemented for models with random effects (TMB
      # error: "Hessian not yet implemented for models with random
      # effects."). Fall back to an FD Hessian of the analytic gradient.
      he_j <- try(
        numDeriv::jacobian(function(th) obj_j$gr(th), theta0),
        silent = TRUE
      )
      if (!inherits(he_j, "try-error")) {
        he_j <- (he_j + t(he_j)) / 2
      }
    }
    if (!inherits(he_j, "try-error")) {
      hess_sum <- hess_sum + he_j
      n_he_ok <- n_he_ok + 1L
    }
  }

  mean_score <- colMeans(scores)
  se_score <- apply(scores, 2, stats::sd) / sqrt(nsim)
  z <- mean_score / se_score

  mean_hess <- hess_sum / n_he_ok
  emp_cov <- stats::cov(scores)
  rel_frob <- norm(emp_cov - mean_hess, type = "F") / norm(mean_hess, type = "F")
  eig_emp <- eigen(emp_cov, symmetric = TRUE, only.values = TRUE)$values
  eig_hess <- eigen(mean_hess, symmetric = TRUE, only.values = TRUE)$values

  list(
    theta0 = theta0,
    z = z,
    rel_frob = rel_frob,
    eig_ratio = sort(eig_emp) / sort(eig_hess),
    n_he_ok = n_he_ok
  )
}

test_that("Bartlett identities hold for Gaussian location-scale (sanity anchor)", {
  # This route MUST pass. If it does not, the harness is wrong, not the
  # package -- gaussian() is the simplest density in drmTMB.
  set.seed(20260722)
  n <- 80
  x <- stats::rnorm(n)
  mu <- 0.5 + 0.8 * x
  y <- stats::rnorm(n, mu, sd = 1.2)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  res <- score_consistency(fit, nsim = 80, seed = 1)

  expect_equal(res$n_he_ok, 80L)
  expect_true(all(abs(res$z) < 4))
  expect_lt(res$rel_frob, 0.5)
  expect_true(all(res$eig_ratio > 0.4 & res$eig_ratio < 2))
})

test_that("Bartlett identities hold for nbinom2 (count family)", {
  set.seed(20260723)
  n <- 100
  x <- stats::rnorm(n)
  mu <- exp(0.6 + 0.4 * x)
  sigma <- 0.5
  y <- MASS::rnegbin(n, mu = mu, theta = 1 / sigma^2)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(bf(y ~ x), family = nbinom2(), data = dat)

  res <- score_consistency(fit, nsim = 80, seed = 2)

  expect_equal(res$n_he_ok, 80L)
  expect_true(all(abs(res$z) < 4))
  expect_lt(res$rel_frob, 0.5)
  expect_true(all(res$eig_ratio > 0.4 & res$eig_ratio < 2))
})

test_that("Bartlett identities hold for beta (bounded family)", {
  set.seed(20260724)
  n <- 90
  x <- stats::rnorm(n)
  mu <- stats::plogis(0.3 + 0.5 * x)
  sigma <- 0.35
  phi <- 1 / sigma^2
  y <- stats::rbeta(n, shape1 = mu * phi, shape2 = (1 - mu) * phi)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = beta(), data = dat)

  res <- score_consistency(fit, nsim = 80, seed = 3)

  expect_equal(res$n_he_ok, 80L)
  expect_true(all(abs(res$z) < 4))
  expect_lt(res$rel_frob, 0.5)
  expect_true(all(res$eig_ratio > 0.4 & res$eig_ratio < 2))
})

test_that("perturbing theta0 away from truth is detected by the first-Bartlett z-statistic", {
  # Power / fail-injection check: prove the harness is not vacuously passing.
  set.seed(20260722)
  n <- 80
  x <- stats::rnorm(n)
  mu <- 0.5 + 0.8 * x
  y <- stats::rnorm(n, mu, sd = 1.2)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  theta0 <- fit$opt$par
  par_list0 <- fit$obj$env$parList(theta0)
  tmb_data0 <- fit$model$tmb_data
  sims <- simulate(fit, nsim = 80, seed = 1)

  # Simulate at the true theta0 (as in the sanity-anchor test above), but
  # evaluate the score at a *perturbed* theta -- intercept shifted by +0.5,
  # roughly 2-3 estimated SEs for this design.
  theta_perturbed <- theta0
  theta_perturbed[1] <- theta_perturbed[1] + 0.5

  scores <- matrix(NA_real_, nrow = 80, ncol = length(theta0))
  for (j in seq_len(80)) {
    d <- tmb_data0
    d$y <- sims[[j]]
    obj_j <- TMB::MakeADFun(
      data = d, parameters = par_list0,
      map = fit$model$map, random = fit$model$tmb_random_names,
      DLL = "drmTMB", silent = TRUE
    )
    scores[j, ] <- obj_j$gr(theta_perturbed)
  }
  mean_score <- colMeans(scores)
  se_score <- apply(scores, 2, stats::sd) / sqrt(80)
  z_perturbed <- mean_score / se_score

  # The perturbed intercept component must show a large, clearly detectable
  # z -- this calibrates the harness's power to catch a wrong density.
  expect_gt(abs(z_perturbed[[1]]), 15)
})

test_that("Bartlett identities for a Gaussian random-intercept (Laplace) route", {
  # Frontier RE route. obj$gr(theta0) here is the score of the
  # *Laplace-approximated* marginal likelihood, so any deviation from the
  # first-Bartlett identity is a statement about the RE machinery, not
  # necessarily the kernel density -- and for a Gaussian random intercept
  # the Laplace approximation is analytically EXACT (the conditional
  # posterior of u given data and theta is exactly Gaussian), so a deviation
  # here needs a different explanation than "Laplace error".
  #
  # HISTORY: this test used to PIN a known defect. simulate.drmTMB() used to
  # simulate random effects *conditionally* (fixed at the fitted MAP u_hat)
  # for every replicate, which starved the variance-component (log_sd_mu)
  # score of the between-group variability the Bartlett identity needs --
  # z climbed from 5.36 (nsim = 60) to 10.59 (nsim = 200) as evidence
  # accumulated against a fixed u_hat, and the old expectation
  # (`expect_gt(abs(z_re), 3)`) said so explicitly. That defect is now FIXED:
  # simulate.drmTMB() gained `re.form`, and the default (`re.form = NULL`)
  # draws a fresh random effect per replicate (marginal simulation; see
  # R/methods.R). This test now asserts the identity actually HOLDS.
  #
  # Guard: confirm theta0 is at the optimum (a converged fit), not the TMB
  # start vector -- evaluating the score anywhere off the optimum can bias
  # z away from 0 for reasons that have nothing to do with simulate().
  set.seed(20260725)
  n_id <- 10
  n_each <- 6
  n <- n_id * n_each
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n)
  u_id <- stats::rnorm(n_id, sd = 0.6)
  u_id <- u_id - mean(u_id)
  mu <- 0.4 + 0.6 * x + u_id[id]
  y <- stats::rnorm(n, mu, sd = 0.9)
  dat <- data.frame(y = y, x = x, id = id)
  fit <- drmTMB(bf(y ~ x + (1 | id), sigma ~ 1), family = gaussian(), data = dat)

  expect_lt(max(abs(fit$obj$gr(fit$opt$par))), 1e-3)

  # nsim = 150 (larger than the fixed-effect routes above) because the
  # variance-component score is the noisiest component; at this nsim, under
  # marginal simulation, z[log_sd_mu] measured -0.607 in the qualifying run
  # (this run: -0.21, still well inside the Monte Carlo noise band). A fixed
  # |z| < 3 bound is standard first-Bartlett practice and honest about that
  # noise -- it is neither so tight it flags ordinary Monte Carlo variation
  # nor so loose it would have missed the old defect (which registered
  # 5.36-10.59).
  res <- score_consistency(fit, nsim = 150, seed = 44, tight_inner = TRUE)

  # Fixed-effect / residual-scale components: first Bartlett holds.
  fe_idx <- which(names(res$theta0) %in% c("beta_mu", "beta_sigma"))
  expect_true(all(abs(res$z[fe_idx]) < 4))

  # Variance-component score (log_sd_mu): first Bartlett now holds too, now
  # that random effects are properly re-marginalised across replicates.
  re_idx <- which(names(res$theta0) == "log_sd_mu")
  expect_lt(abs(res$z[re_idx]), 3)

  expect_lt(res$rel_frob, 0.6)
})
