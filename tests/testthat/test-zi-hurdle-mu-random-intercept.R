# Owner decision 1(a), issue #1451: zero-inflated and hurdle count models
# accept ONE Gaussian random intercept on mu, with an intercept-only zi/hu
# part. Covers ZIP, ZINB, and hurdle NB2 (truncated_nbinom2() + hu ~ 1).

simulate_zi_count_ri <- function(
  family = c("poisson", "nbinom2", "hurdle"),
  n_group = 40L,
  n_per_group = 12L,
  beta_mu = c(0.6, 0.5),
  sigma = 0.6,
  p0 = 0.3,
  sd_id = 0.6,
  seed = 1451L
) {
  family <- match.arg(family)
  set.seed(seed)
  id <- factor(rep(seq_len(n_group), each = n_per_group))
  x <- stats::rnorm(n_group * n_per_group)
  u_id <- stats::rnorm(n_group, sd = sd_id)
  mu <- exp(beta_mu[[1L]] + beta_mu[[2L]] * x + u_id[as.integer(id)])
  n <- length(mu)
  count <- switch(
    family,
    poisson = stats::rpois(n, mu),
    nbinom2 = stats::rnbinom(n, size = 1 / sigma^2, mu = mu),
    hurdle = {
      out <- integer(n)
      for (i in seq_len(n)) {
        repeat {
          draw <- stats::rnbinom(1L, size = 1 / sigma^2, mu = mu[[i]])
          if (draw > 0L) break
        }
        out[[i]] <- draw
      }
      out
    }
  )
  structural <- stats::rbinom(n, 1L, p0) == 1L
  count[structural] <- 0L
  list(
    data = data.frame(count = count, x = x, id = id),
    beta_mu = beta_mu,
    sigma = sigma,
    p0 = p0,
    sd_id = sd_id,
    u_id = u_id
  )
}

fit_zi_count_ri <- function(sim, family) {
  switch(
    family,
    poisson = drmTMB(
      bf(count ~ x + (1 | id), zi ~ 1),
      family = stats::poisson(),
      data = sim$data
    ),
    nbinom2 = drmTMB(
      bf(count ~ x + (1 | id), sigma ~ 1, zi ~ 1),
      family = nbinom2(),
      data = sim$data
    ),
    hurdle = drmTMB(
      bf(count ~ x + (1 | id), sigma ~ 1, hu ~ 1),
      family = truncated_nbinom2(),
      data = sim$data
    )
  )
}

test_that("zero-inflated and hurdle count models fit one mu random intercept", {
  cases <- list(
    poisson = "zi_poisson",
    nbinom2 = "zi_nbinom2",
    hurdle = "hurdle_nbinom2"
  )
  for (family in names(cases)) {
    sim <- simulate_zi_count_ri(family, n_group = 15L, n_per_group = 8L)
    fit <- fit_zi_count_ri(sim, family)
    expect_s3_class(fit, "drmTMB")
    expect_equal(fit$model$model_type, cases[[family]])
    expect_equal(fit$opt$convergence, 0)
    expect_equal(fit$model$random$mu$labels, "(1 | id)")
    expect_named(fit$sdpars$mu, "(1 | id)")
    expect_true(is.finite(as.numeric(logLik(fit))))
    expect_length(fit$random_effects$mu$terms[["(1 | id)"]], 15L)
    # The fitted conditional mean includes the group intercepts.
    mu_hat <- predict(fit, dpar = "mu")
    expect_equal(
      unname(mu_hat),
      as.numeric(fit$obj$report(fit$obj$env$last.par.best)$mu),
      tolerance = 1e-8
    )
    u_hat <- unname(fit$random_effects$mu$terms[["(1 | id)"]])
    eta_fixed <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
    expect_equal(
      unname(log(mu_hat)),
      eta_fixed + u_hat[as.integer(sim$data$id)],
      tolerance = 1e-6
    )
  }
})

test_that("zero-inflated and hurdle mu random intercepts recover simulated truth", {
  skip_on_cran()
  for (family in c("poisson", "nbinom2", "hurdle")) {
    sim <- simulate_zi_count_ri(family, seed = 20261011L)
    fit <- fit_zi_count_ri(sim, family)
    expect_equal(fit$opt$convergence, 0)
    expect_true(fit$sdr$pdHess)
    expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.2)
    expect_lt(abs(unname(fit$sdpars$mu) - sim$sd_id), 0.2)
    expect_gt(
      stats::cor(fit$random_effects$mu$terms[["(1 | id)"]], sim$u_id),
      0.8
    )
    zero_dpar <- if (identical(family, "hurdle")) "hu" else "zi"
    p0_hat <- stats::plogis(unname(coef(fit, zero_dpar)))
    if (identical(family, "hurdle")) {
      # The hurdle probability is the observed zero share.
      expect_equal(p0_hat, mean(sim$data$count == 0), tolerance = 1e-4)
    } else {
      expect_lt(abs(p0_hat - sim$p0), 0.08)
    }
    if (!identical(family, "poisson")) {
      expect_lt(abs(exp(unname(coef(fit, "sigma"))) - sim$sigma), 0.2)
    }
  }
})

test_that("zero-inflated mu random intercept keeps the first-slice boundary", {
  sim <- simulate_zi_count_ri("nbinom2", n_group = 10L, n_per_group = 6L)
  dat <- sim$data
  dat$w <- stats::rnorm(nrow(dat))
  expect_error(
    drmTMB(
      bf(count ~ x + (1 | id), zi ~ w),
      family = stats::poisson(),
      data = dat
    ),
    "intercept-only"
  )
  expect_error(
    drmTMB(
      bf(count ~ x + (1 | id), sigma ~ 1, zi ~ w),
      family = nbinom2(),
      data = dat
    ),
    "intercept-only"
  )
  expect_error(
    drmTMB(
      bf(count ~ x + (1 | id), sigma ~ 1, hu ~ w),
      family = truncated_nbinom2(),
      data = dat
    ),
    "intercept-only"
  )
  dat$site <- factor(rep(1:3, length.out = nrow(dat)))
  expect_error(
    drmTMB(
      bf(count ~ x + (1 | id) + (1 | site), zi ~ 1),
      family = stats::poisson(),
      data = dat
    ),
    "one .*random intercept"
  )
  expect_error(
    drmTMB(
      bf(count ~ x + (0 + x | id), sigma ~ 1, zi ~ 1),
      family = nbinom2(),
      data = dat
    ),
    "Zero-inflated NB2 random effects"
  )
  expect_error(
    drmTMB(
      bf(count ~ x + (1 + x | id), sigma ~ 1, hu ~ 1),
      family = truncated_nbinom2(),
      data = dat
    ),
    "Hurdle NB2 random effects"
  )
})

test_that("Salamanders ZINB, ZIP, and hurdle NB2 with (1 | site) match glmmTMB", {
  skip_on_cran()
  skip_if_not_installed("glmmTMB")
  data("Salamanders", package = "glmmTMB", envir = environment())
  dat <- Salamanders
  dat$site <- factor(as.character(dat$site))

  compare <- function(fit, ref, sigma_from_theta = TRUE) {
    expect_equal(fit$opt$convergence, 0)
    expect_equal(
      as.numeric(logLik(fit)),
      as.numeric(stats::logLik(ref)),
      tolerance = 1e-5
    )
    ref_fixed <- glmmTMB::fixef(ref)
    expect_equal(
      unname(coef(fit, "mu")),
      unname(ref_fixed$cond),
      tolerance = 1e-3
    )
    zero_dpar <- intersect(c("zi", "hu"), fit$model$dpars)
    # Compare on the probability scale: on Salamanders the ZINB zero-inflation
    # intercept runs to the boundary (zi -> 0) on both engines.
    expect_lt(
      abs(
        stats::plogis(unname(coef(fit, zero_dpar))) -
          stats::plogis(unname(ref_fixed$zi))
      ),
      1e-4
    )
    ref_sd <- attr(glmmTMB::VarCorr(ref)$cond$site, "stddev")
    expect_equal(unname(fit$sdpars$mu), unname(ref_sd), tolerance = 1e-3)
    if (isTRUE(sigma_from_theta)) {
      # glmmTMB reports the NB2 size theta; drmTMB uses sigma = 1 / sqrt(theta).
      expect_equal(
        exp(unname(coef(fit, "sigma"))),
        1 / sqrt(stats::sigma(ref)),
        tolerance = 1e-3
      )
    }
  }

  zinb <- drmTMB(
    bf(count ~ spp + mined + (1 | site), sigma ~ 1, zi ~ 1),
    family = nbinom2(),
    data = dat
  )
  zinb_ref <- glmmTMB::glmmTMB(
    count ~ spp + mined + (1 | site),
    zi = ~1,
    family = glmmTMB::nbinom2(),
    data = dat
  )
  compare(zinb, zinb_ref)

  zip <- drmTMB(
    bf(count ~ spp + mined + (1 | site), zi ~ 1),
    family = stats::poisson(),
    data = dat
  )
  zip_ref <- glmmTMB::glmmTMB(
    count ~ spp + mined + (1 | site),
    zi = ~1,
    family = stats::poisson(),
    data = dat
  )
  compare(zip, zip_ref, sigma_from_theta = FALSE)

  hnb <- drmTMB(
    bf(count ~ spp + mined + (1 | site), sigma ~ 1, hu ~ 1),
    family = truncated_nbinom2(),
    data = dat
  )
  hnb_ref <- glmmTMB::glmmTMB(
    count ~ spp + mined + (1 | site),
    zi = ~1,
    family = glmmTMB::truncated_nbinom2(),
    data = dat
  )
  compare(hnb, hnb_ref)
})
