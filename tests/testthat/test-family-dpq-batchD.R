# DO-T3 batch D tests for R/family-dpq.R: biv_gaussian's MARGINAL {d,p,q},
# promoted to `status = "reference"`. Gaussian and the other 17 model types
# are covered elsewhere (test-family-dpq.R, test-family-dpq-batchA/B/C.R) and
# not repeated here. See docs/design/85-distributional-output-adequacy-do-t3-batch-d.md.
#
# DESIGN (marginal-only): the marginal of a bivariate normal for response k
# is EXACTLY N(mu_k, sigma_k), independent of rho12 -- so biv_gaussian's
# {d,p,q} reuse drm_family_dpq_gaussian()'s closures verbatim on the SELECTED
# response (fitted_distribution()'s `response` argument, REQUIRED for
# biv_gaussian: 1 selects (mu1, sigma1), 2 selects (mu2, sigma2)).
#
# DG2 per response k = 1, 2 (verification-spec.md):
#   1. marginal d/p/q equal N(mu_k, sigma_k) (predict()-ed dpars).
#   2. agreement with the compiled joint density's marginal at fixed theta:
#      the compiled kernel's per-row joint covariance is
#      Sigma_i = [[sigma1_i^2, rho12_i*sigma1_i*sigma2_i],
#                 [rho12_i*sigma1_i*sigma2_i, sigma2_i^2]]
#      (src/drmTMB.cpp model_type == 2); marginalizing a bivariate normal
#      over the OTHER response leaves EXACTLY the diagonal element -- a
#      standard MVN identity, verified here numerically (not just asserted)
#      by integrating an INDEPENDENT mvtnorm::dmvnorm() joint density over
#      the other response and comparing to fd$d() (so a bug in fd$d() cannot
#      cancel against the assertion).
#   3. p(q(a)) inverse identity.
#   4. rho12-invariance: two fits sharing the SAME response-1 draw but
#      different fitted rho12 give numerically indistinguishable response-1
#      marginal {d,p,q}; structurally confirmed by drm_family_dpq()'s
#      biv_gaussian entry not even listing "rho12"/"mu1"/"mu2" in `dpars`.
#
# The V_known bug DO-T2 flagged (known_v_diag() for biv returns the fit's
# full row-paired 2n-length known-variance vector; reusing it directly for a
# single response's n-row params table throws a length mismatch) is fixed by
# drm_biv_response_v_known() (R/family-dpq.R); one test below exercises it on
# a meta_V() biv fit.
#
# DG3: one fixed-seed known-DGP smoke test -- residuals(fit, type =
# "quantile", response = k) should pass a KS test against N(0,1), for k = 1
# and k = 2 both, under one correctly specified fit. LOCAL SMOKE ONLY (n in
# the low hundreds, one seed), not the gated multi-seed power-arm campaign.

fast_control <- drm_control(se = FALSE)

new_biv_gaussian_dg_data <- function(n = 300, rho12 = 0.35, seed = 20260722) {
  set.seed(seed)
  x <- stats::rnorm(n)
  mu1 <- 0.4 + 0.6 * x
  mu2 <- -0.2 + 0.3 * x
  sigma1 <- 0.8
  sigma2 <- 1.1
  e1 <- stats::rnorm(n)
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)
  data.frame(y1 = mu1 + sigma1 * e1, y2 = mu2 + sigma2 * e2, x = x)
}

new_biv_gaussian_dg_fit <- function(dat) {
  drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
    family = biv_gaussian(),
    data = dat,
    control = fast_control
  )
}

# ---- response argument: required for biv_gaussian, forbidden otherwise ----

test_that("biv_gaussian: fitted_distribution() requires response and validates it", {
  dat <- new_biv_gaussian_dg_data(n = 40)
  fit <- new_biv_gaussian_dg_fit(dat)

  expect_error(
    fitted_distribution(fit),
    "biv_gaussian.*is bivariate.*response = 1.*response = 2"
  )
  expect_error(fitted_distribution(fit, response = 3), "must be.*1.*or.*2")
  expect_error(fitted_distribution(fit, response = c(1, 2)), "must be.*1.*or.*2")

  fd1 <- fitted_distribution(fit, response = 1)
  fd2 <- fitted_distribution(fit, response = 2)
  expect_s3_class(fd1, "drm_fitted_distribution")
  expect_identical(fd1$model_type, "biv_gaussian")
  expect_identical(fd1$status, "reference")
  expect_false(fd1$discrete)
  expect_false(fd1$has_atom)
  expect_identical(fd1$atoms, numeric(0))
  expect_identical(fd2$status, "reference")

  # A univariate fit must NOT accept `response` (validated, not ignored).
  fitu <- drmTMB(bf(y1 ~ x, sigma ~ 1), data = dat, control = fast_control)
  expect_error(
    fitted_distribution(fitu, response = 1),
    "response.*only used for bivariate"
  )
})

test_that("biv_gaussian: drm_family_dpq() reuses the gaussian entry -- dpars, status, atoms", {
  dat <- new_biv_gaussian_dg_data(n = 30)
  fit <- new_biv_gaussian_dg_fit(dat)
  entry <- drm_family_dpq(fit)
  # rho12/mu1/mu2 are NOT in dpars -- structural proof the closures cannot
  # read rho12 at all, independent of any particular fit's numbers.
  expect_identical(entry$dpars, c("mu", "sigma"))
  expect_identical(entry$status, "reference")
  expect_false(entry$discrete)
  expect_false(entry$has_atom)
  expect_identical(entry$atoms, numeric(0))
})

# ---- DG2.1: marginal d/p/q equal N(mu_k, sigma_k) --------------------------

test_that("biv_gaussian: DG2 marginal d/p/q equal N(mu_k, sigma_k) for both responses", {
  dat <- new_biv_gaussian_dg_data(n = 300)
  fit <- new_biv_gaussian_dg_fit(dat)

  for (k in 1:2) {
    fd <- fitted_distribution(fit, response = k)
    mu_hat <- predict(fit, dpar = paste0("mu", k))
    sigma_hat <- predict(fit, dpar = paste0("sigma", k))
    y <- dat[[paste0("y", k)]]

    expect_equal(fd$params$mu, mu_hat)
    expect_equal(fd$params$sigma, sigma_hat)
    # non-meta biv: V_known is 0 for both responses (no known sampling
    # covariance was supplied).
    expect_equal(fd$params$V_known, rep(0, nrow(dat)))

    expect_equal(fd$d(y), stats::dnorm(y, mean = mu_hat, sd = sigma_hat))
    expect_equal(fd$p(y), stats::pnorm(y, mean = mu_hat, sd = sigma_hat))
    for (uu in c(0.05, 0.25, 0.5, 0.75, 0.95)) {
      expect_equal(
        fd$q(rep(uu, length(mu_hat))),
        stats::qnorm(uu, mean = mu_hat, sd = sigma_hat)
      )
    }
  }
})

# ---- DG2.2: p(q(u)) inverse identity ----------------------------------------

test_that("biv_gaussian: DG2 p(q(u)) inverse identity holds for both responses", {
  dat <- new_biv_gaussian_dg_data(n = 150)
  fit <- new_biv_gaussian_dg_fit(dat)

  u <- c(0.01, 0.1, 0.25, 0.5, 0.75, 0.9, 0.99)
  for (k in 1:2) {
    fd <- fitted_distribution(fit, response = k)
    n <- nrow(fd$params)
    for (uu in u) {
      q_val <- fd$q(rep(uu, n))
      expect_equal(fd$p(q_val), rep(uu, n), tolerance = 1e-8)
    }
  }
})

# ---- DG2.3: agreement with the compiled joint density's marginal -----------

test_that("biv_gaussian: DG2 marginal agrees with the compiled joint density's marginal at fixed theta", {
  testthat::skip_if_not_installed("mvtnorm")
  dat <- new_biv_gaussian_dg_data(n = 200, rho12 = 0.5)
  fit <- new_biv_gaussian_dg_fit(dat)

  mu1 <- predict(fit, dpar = "mu1")
  mu2 <- predict(fit, dpar = "mu2")
  sigma1 <- predict(fit, dpar = "sigma1")
  sigma2 <- predict(fit, dpar = "sigma2")
  rho12 <- predict(fit, dpar = "rho12")

  fd1 <- fitted_distribution(fit, response = 1)
  fd2 <- fitted_distribution(fit, response = 2)

  # SAME per-row joint covariance the compiled kernel builds
  # (src/drmTMB.cpp model_type == 2): cov12 = rho12(i) * sigma1(i) *
  # sigma2(i). Built directly here from predict()-ed dpars, independent of
  # fd1$d()/fd2$d(), so a bug there cannot cancel against the assertion.
  joint_density <- function(y1, y2, i) {
    cov12 <- rho12[i] * sigma1[i] * sigma2[i]
    Sigma <- matrix(c(sigma1[i]^2, cov12, cov12, sigma2[i]^2), nrow = 2)
    mvtnorm::dmvnorm(cbind(y1, y2), mean = c(mu1[i], mu2[i]), sigma = Sigma)
  }

  # fd1$d()/fd2$d() are per-row closures bound to the FULL params table
  # (frozen (y_or_u, params) signature): called ONCE on the full length-n
  # response vector, then subsetted at the probe row AFTER the call --
  # calling with a single scalar would recycle it against every row's
  # (mu, sigma) instead of evaluating just that one row (the same constraint
  # batch A/B/C's helpers document).
  d1_at_y1 <- fd1$d(dat$y1)
  d2_at_y2 <- fd2$d(dat$y2)

  probe_rows <- round(seq(1, nrow(dat), length.out = 6))
  for (i in probe_rows) {
    marg1_numeric <- stats::integrate(
      function(y2) joint_density(dat$y1[i], y2, i),
      lower = mu2[i] - 15 * sigma2[i],
      upper = mu2[i] + 15 * sigma2[i],
      rel.tol = 1e-8
    )$value
    expect_equal(marg1_numeric, d1_at_y1[i], tolerance = 1e-6)

    marg2_numeric <- stats::integrate(
      function(y1) joint_density(y1, dat$y2[i], i),
      lower = mu1[i] - 15 * sigma1[i],
      upper = mu1[i] + 15 * sigma1[i],
      rel.tol = 1e-8
    )$value
    expect_equal(marg2_numeric, d2_at_y2[i], tolerance = 1e-6)
  }
})

# ---- DG2.4: rho12-invariance ------------------------------------------------

test_that("biv_gaussian: marginal {d,p,q} is invariant to rho12", {
  # Two fits sharing the SAME response-1 draw (identical e1 draw) but
  # different rho12 (a different e2 draw): the fitted marginal (mu1_hat,
  # sigma1_hat) -- and therefore fd1$d/p/q -- should be numerically
  # indistinguishable, since the marginal of a bivariate normal does not
  # depend on rho12 at all.
  n <- 300
  set.seed(20260723)
  x <- stats::rnorm(n)
  mu1_true <- 0.3 + 0.5 * x
  mu2_true <- -0.1 + 0.2 * x
  sigma1_true <- 0.6
  sigma2_true <- 0.9

  make_data <- function(rho12, seed) {
    set.seed(seed)
    e1 <- stats::rnorm(n)
    e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)
    data.frame(
      y1 = mu1_true + sigma1_true * e1,
      y2 = mu2_true + sigma2_true * e2,
      x = x
    )
  }
  dat_low <- make_data(0.1, seed = 1)
  dat_high <- make_data(0.85, seed = 1)
  expect_identical(dat_low$y1, dat_high$y1)

  fit_low <- new_biv_gaussian_dg_fit(dat_low)
  fit_high <- new_biv_gaussian_dg_fit(dat_high)
  expect_gt(
    abs(predict(fit_high, dpar = "rho12")[1] - predict(fit_low, dpar = "rho12")[1]),
    0.3
  )

  fd_low <- fitted_distribution(fit_low, response = 1)
  fd_high <- fitted_distribution(fit_high, response = 1)
  expect_equal(fd_low$params$mu, fd_high$params$mu, tolerance = 1e-4)
  expect_equal(fd_low$params$sigma, fd_high$params$sigma, tolerance = 1e-4)
  expect_equal(fd_low$d(dat_low$y1), fd_high$d(dat_low$y1), tolerance = 1e-4)
})

# ---- V_known bug fix (DO-T2 flagged; fixed in this batch) ------------------

test_that("biv_gaussian: V_known is response k's own n-row slice for a meta_V() fit (the flagged bug fix)", {
  n <- 60
  set.seed(20260725)
  x <- stats::rnorm(n)
  v1 <- stats::runif(n, 0.05, 0.3)
  v2 <- stats::runif(n, 0.02, 0.1)
  V <- meta_vcov_bivariate(v1 = v1, v2 = v2, cor12 = 0.3)
  mu1_true <- 0.4 + 0.6 * x
  mu2_true <- -0.2 + 0.3 * x
  sigma1_true <- 0.5
  sigma2_true <- 0.7
  rho12_true <- 0.2
  y_stack <- numeric(2 * n)
  for (i in seq_len(n)) {
    S_i <- matrix(
      c(
        v1[i] + sigma1_true^2,
        0.3 * sqrt(v1[i] * v2[i]) + rho12_true * sigma1_true * sigma2_true,
        0.3 * sqrt(v1[i] * v2[i]) + rho12_true * sigma1_true * sigma2_true,
        v2[i] + sigma2_true^2
      ),
      nrow = 2
    )
    y_stack[(2 * i - 1):(2 * i)] <- as.vector(
      c(mu1_true[i], mu2_true[i]) + t(chol(S_i)) %*% stats::rnorm(2)
    )
  }
  dat <- data.frame(
    x = x,
    y1 = y_stack[seq.int(1L, by = 2L, length.out = n)],
    y2 = y_stack[seq.int(2L, by = 2L, length.out = n)]
  )
  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + meta_V(V = V),
      mu2 = y2 ~ x,
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = c(gaussian(), gaussian()),
    data = dat,
    control = fast_control
  )
  expect_identical(fit$model$V_known_type, "matrix")

  # Before this batch's fix, calling known_v_diag() directly for a single
  # response's n-row params table would either throw a length mismatch (2n
  # vs n) or silently misalign response 1's and response 2's known
  # variances; both are checked here.
  fd1 <- fitted_distribution(fit, response = 1)
  fd2 <- fitted_distribution(fit, response = 2)
  expect_length(fd1$params$V_known, n)
  expect_length(fd2$params$V_known, n)
  expect_equal(fd1$params$V_known, v1)
  expect_equal(fd2$params$V_known, v2)

  d1_direct <- stats::dnorm(
    dat$y1,
    mean = predict(fit, dpar = "mu1"),
    sd = sqrt(v1 + predict(fit, dpar = "sigma1")^2)
  )
  expect_equal(fd1$d(dat$y1), d1_direct)
  d2_direct <- stats::dnorm(
    dat$y2,
    mean = predict(fit, dpar = "mu2"),
    sd = sqrt(v2 + predict(fit, dpar = "sigma2")^2)
  )
  expect_equal(fd2$d(dat$y2), d2_direct)

  # newdata rows: no per-row known bivariate sampling covariance is
  # available (marginal-only scope, matching DO-T2's original
  # predict(type = "quantile") documentation) -- V_known is 0 there,
  # regardless of the fit's meta status.
  fd1_new <- fitted_distribution(
    fit,
    newdata = data.frame(x = c(-1, 0, 1)),
    response = 1
  )
  expect_equal(fd1_new$params$V_known, rep(0, 3))
})

# ---- DG3: local KS smoke, both responses ------------------------------------

test_that("biv_gaussian: DG3 residuals(type = 'quantile', response = k) pass a KS test against N(0,1), both responses", {
  dat <- new_biv_gaussian_dg_data(n = 400, seed = 20260724)
  fit <- new_biv_gaussian_dg_fit(dat)

  for (k in 1:2) {
    r <- residuals(fit, type = "quantile", response = k)
    expect_length(r, nrow(dat))
    ks <- stats::ks.test(r, "pnorm")
    expect_gt(ks$p.value, 0.05)
  }

  # residuals(type = "quantile") matches drm_quantile_residuals() directly,
  # mirroring the univariate contract test in test-adequacy.R.
  expect_identical(
    residuals(fit, type = "quantile", response = 1),
    drm_quantile_residuals(fit, response = 1)
  )

  # response is REQUIRED for a biv_gaussian fit -- omitting it errors,
  # rather than silently defaulting to a response.
  expect_error(
    residuals(fit, type = "quantile"),
    "biv_gaussian.*is bivariate.*response = 1.*response = 2"
  )
})

test_that("biv_gaussian: worm_plot()/qq_plot() accept response and return ggplot objects", {
  testthat::skip_if_not_installed("ggplot2")
  dat <- new_biv_gaussian_dg_data(n = 150, seed = 20260726)
  fit <- new_biv_gaussian_dg_fit(dat)

  p_worm <- worm_plot(fit, response = 1)
  p_qq <- qq_plot(fit, response = 2)
  expect_s3_class(p_worm, "ggplot")
  expect_s3_class(p_qq, "ggplot")
  expect_error(worm_plot(fit), "biv_gaussian.*is bivariate.*response = 1.*response = 2")
})

# ---- exceedance()/centile_chart(): route through the SAME registry entry --

test_that("biv_gaussian: exceedance() computes a per-response marginal exceedance matching simulate() MC", {
  testthat::skip_on_cran()
  dat <- new_biv_gaussian_dg_data(n = 8, seed = 20260727)
  fit <- new_biv_gaussian_dg_fit(dat)

  N <- 2e4
  threshold <- 0.2
  exc1 <- exceedance(fit, threshold = threshold, response = 1)
  expect_identical(attr(exc1, "calibrated"), FALSE)

  sims <- as.matrix(simulate(fit, nsim = N, seed = 11))
  mc_exc1 <- rowMeans(sims[, grepl("_y1$", colnames(sims)), drop = FALSE] > threshold)
  mcse <- sqrt(exc1 * (1 - exc1) / N)
  expect_true(all(abs(as.numeric(exc1) - mc_exc1) <= 3 * mcse))

  expect_error(
    exceedance(fit, threshold = threshold),
    "biv_gaussian.*is bivariate.*response = 1.*response = 2"
  )
})

test_that("biv_gaussian: centile_chart() still works via the existing dpar selector after the registry refactor", {
  testthat::skip_if_not_installed("ggplot2")
  dat <- new_biv_gaussian_dg_data(n = 100, seed = 20260728)
  fit <- new_biv_gaussian_dg_fit(dat)

  p1 <- centile_chart(fit, covariate = "x", dpar = "mu1")
  p2 <- centile_chart(fit, covariate = "x", dpar = "mu2")
  expect_s3_class(p1, "ggplot")
  expect_s3_class(p2, "ggplot")
})

test_that("biv_gaussian: predict(type = 'quantile') matches simulate() MC within 3*MCSE for both responses", {
  testthat::skip_on_cran()
  dat <- new_biv_gaussian_dg_data(n = 8, seed = 20260729)
  fit <- new_biv_gaussian_dg_fit(dat)

  prob <- c(0.1, 0.5, 0.9)
  N <- 2e4
  sims <- as.matrix(simulate(fit, nsim = N, seed = 22))

  for (k in 1:2) {
    dpar_mu <- paste0("mu", k)
    dpar_sigma <- paste0("sigma", k)
    qhat <- predict(fit, dpar = dpar_mu, type = "quantile", prob = prob)
    fd <- fitted_distribution(fit, response = k)
    sim_col <- sims[, grepl(paste0("_y", k, "$"), colnames(sims)), drop = FALSE]
    for (j in seq_along(prob)) {
      p <- prob[[j]]
      mc_q <- apply(sim_col, 1L, stats::quantile, probs = p, names = FALSE)
      dens_at_q <- fd$d(qhat[, j])
      mcse <- sqrt(p * (1 - p) / N) / dens_at_q
      diff <- abs(qhat[, j] - mc_q)
      expect_true(all(diff <= 3 * mcse))
    }
  }
})
