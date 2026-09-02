# Tests for heritability()/icc()/repeatability(), ported term-for-term from
# DRM.jl's src/heritability.jl (design doc
# docs/design/259-heritability-icc-repeatability.md).

# n_groups = 300 rather than an originally sketched 60: at n_groups = 60,
# n_per = 10 the ML point estimate's sampling SD across 20 pilot seeds was
# ~0.039 (max |diff| 0.092), so a strict per-seed 0.05 tolerance failed 2/5
# of seeds 1:5 on a first run (real ML sampling noise, not an estimator bug --
# the same 20-seed pilot at n_groups = 60 had mean bias -0.02, the expected ML
# downward shrinkage). n_groups = 300 keeps the same DGP and 0.05 tolerance
# but with a reliable margin (max |diff| 0.039 across a 10-seed pilot at this
# size); fits remain sub-second.
heritability_recovery_fits <- function() {
  n_groups <- 300
  n_per <- 10
  sd_g <- 1
  sd_e <- 0.6
  truth <- sd_g^2 / (sd_g^2 + sd_e^2)
  fits <- lapply(1:5, function(seed) {
    set.seed(seed)
    grp <- factor(rep(seq_len(n_groups), each = n_per))
    b_g <- rnorm(n_groups, sd = sd_g)
    dat <- data.frame(
      y = 2 + b_g[grp] + rnorm(n_groups * n_per, sd = sd_e),
      grp = grp
    )
    drmTMB(bf(y ~ 1 + (1 | grp), sigma ~ 1), data = dat)
  })
  list(fits = fits, truth = truth)
}

test_that("icc() and repeatability() recover the known sigma_g^2/(sigma_g^2+sigma_e^2) DGP", {
  sim <- heritability_recovery_fits()
  for (fit in sim$fits) {
    r_icc <- icc(fit)
    r_rep <- repeatability(fit)
    expect_lt(abs(r_icc$estimate - sim$truth), 0.05)
    expect_equal(r_rep$estimate, r_icc$estimate)
  }
})

test_that("heritability() recovers the same DGP and equals icc() for a single component", {
  sim <- heritability_recovery_fits()
  for (fit in sim$fits) {
    r_icc <- icc(fit)
    r_h2 <- heritability(fit)
    expect_lt(abs(r_h2$estimate - sim$truth), 0.05)
    # Single structured component: heritability() and icc() coincide.
    expect_equal(r_h2$estimate, r_icc$estimate)
  }
})

test_that("two component fits: heritability() uses the total denominator, icc(component=) the focal-vs-residual one", {
  # Two nested iid groups (parser-simple stand-in for a phylo/relmat second
  # component per the task's "or two nested groups if the parser allows").
  set.seed(3)
  n_groups <- 15
  n_per <- 8
  n_groups2 <- 6
  grp <- factor(rep(seq_len(n_groups), each = n_per))
  grp2 <- factor(sample(seq_len(n_groups2), n_groups * n_per, replace = TRUE))
  sd_g <- 1
  sd_g2 <- 0.5
  sd_e <- 0.6
  b_g <- rnorm(n_groups, sd = sd_g)
  b_g2 <- rnorm(n_groups2, sd = sd_g2)
  dat <- data.frame(
    y = 2 + b_g[grp] + b_g2[grp2] + rnorm(n_groups * n_per, sd = sd_e),
    grp = grp,
    grp2 = grp2
  )
  fit <- drmTMB(bf(y ~ 1 + (1 | grp) + (1 | grp2), sigma ~ 1), data = dat)

  h <- heritability(fit, component = "(1 | grp)")
  i <- icc(fit, component = "(1 | grp)")

  # heritability's denominator includes the second component too, so it must
  # be strictly smaller than the focal-vs-residual icc().
  expect_lt(h$estimate, i$estimate)

  # component = NULL is ambiguous with two components and must name the choices.
  expect_error(icc(fit), "structured component")
})

test_that("refuse: heteroscedastic residual sigma (sigma ~ x)", {
  set.seed(11)
  n <- 200
  x <- rnorm(n)
  grp <- factor(rep(1:20, each = 10))
  dat_het <- data.frame(
    y = 1 + rnorm(20, sd = 1)[grp] + rnorm(n, sd = exp(0.2 * x)),
    x = x,
    grp = grp
  )
  fit_het <- drmTMB(bf(y ~ 1 + (1 | grp), sigma ~ x), data = dat_het)
  expect_error(icc(fit_het), "constant residual scale")
  expect_error(heritability(fit_het), "constant residual scale")
  expect_error(repeatability(fit_het), "constant residual scale")
})

test_that("refuse: no random/structured component", {
  set.seed(12)
  dat_fixed <- data.frame(y = rnorm(50), x = rnorm(50))
  fit_fixed <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat_fixed)
  expect_error(icc(fit_fixed), "structured mean random-effect component")
})

test_that("refuse: non-Gaussian family", {
  set.seed(13)
  dat_pois <- data.frame(y = rpois(50, 3), grp = factor(rep(1:10, each = 5)))
  fit_pois <- drmTMB(bf(y ~ 1 + (1 | grp)), data = dat_pois, family = poisson())
  expect_error(icc(fit_pois), "Gaussian")
})

test_that("delta-method se is finite and positive; Wald interval is a sanity check (not a coverage claim)", {
  n_groups <- 300
  n_per <- 10
  sd_g <- 1
  sd_e <- 0.6
  truth <- sd_g^2 / (sd_g^2 + sd_e^2)
  hits <- 0L

  for (seed in 1:5) {
    set.seed(100 + seed)
    grp <- factor(rep(seq_len(n_groups), each = n_per))
    b_g <- rnorm(n_groups, sd = sd_g)
    dat <- data.frame(
      y = 2 + b_g[grp] + rnorm(n_groups * n_per, sd = sd_e),
      grp = grp
    )
    fit <- drmTMB(bf(y ~ 1 + (1 | grp), sigma ~ 1), data = dat)
    r <- icc(fit)

    expect_true(is.finite(r$se))
    expect_gt(r$se, 0)

    if (r$lower <= truth && truth <= r$upper) {
      hits <- hits + 1L
    }
  }

  # Sanity check only, not a coverage claim: expect the Wald interval to
  # contain the truth in most (>= 3 of 5) seeds.
  expect_gte(hits, 3L)
})
