# Tests for heritability()/icc()/repeatability(), ported term-for-term from
# DRM.jl's src/heritability.jl (design doc
# docs/design/259-heritability-icc-repeatability.md).

# n_groups = 300 rather than an originally sketched 60: at n_groups = 60,
# n_per = 10 the ML point estimate's sampling SD across 20 pilot seeds was
# ~0.039 (max |diff| 0.092), so a strict per-seed 0.05 tolerance failed 2/5
# of seeds 1:5 on a first run -- real ML sampling noise, not an estimator bug
# and not a claim about bias: a fresh 150-replicate Monte Carlo at n_groups =
# 60 (Rose, 2026-09-03 verdict) put the mean estimation error at -0.002 (MC SE
# ~0.0032), an order of magnitude smaller than the earlier 20-seed pilot's
# -0.02 and within one MC SE of zero, so that pilot number was noise, not a
# known downward-shrinkage effect. n_groups = 300 was raised only to keep the
# per-seed 0.05 tolerance clear of sampling noise (max |diff| 0.039 across a
# 10-seed pilot at this size, ~22% headroom against 0.05); fits remain
# sub-second. No bias claim is made either way.
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

test_that("refuse slope: correlated random slope (1 + x | g) on mu", {
  set.seed(21)
  n_blk <- 20
  blk <- factor(rep(seq_len(n_blk), each = 10))
  x <- rnorm(length(blk))
  dat <- data.frame(
    y = 1 + x + rnorm(n_blk)[blk] + rnorm(length(blk)),
    x = x,
    blk = blk
  )
  fit <- drmTMB(bf(y ~ 1 + x + (1 + x | blk), sigma ~ 1), data = dat)
  # Sanity: this fit does carry a correlated random-slope term (the case
  # heritability()/icc()/repeatability() must refuse).
  expect_true("eta_cor_mu" %in% names(fit$opt$par))
  expect_error(icc(fit), "random slope|correlated random effect")
  expect_error(heritability(fit), "random slope|correlated random effect")
  expect_error(repeatability(fit), "random slope|correlated random effect")
})

test_that("refuse slope: uncorrelated slope-only random effect (0 + x | g) on mu", {
  set.seed(22)
  n_blk <- 20
  blk <- factor(rep(seq_len(n_blk), each = 10))
  x <- rnorm(length(blk))
  dat <- data.frame(
    y = 1 + (rnorm(n_blk)[blk]) * x + rnorm(length(blk)),
    x = x,
    blk = blk
  )
  fit <- drmTMB(bf(y ~ 1 + x + (0 + x | blk), sigma ~ 1), data = dat)
  # Sanity: no eta_cor_mu here (only one column, nothing to correlate), so
  # this exercises the coef_names-based check independent of the eta_cor_mu
  # safety net.
  expect_false("eta_cor_mu" %in% names(fit$opt$par))
  expect_error(icc(fit), "random slope")
})

test_that("documented label: the roxygen @examples phylo component label matches a real fit", {
  skip_if_not_installed("ape")

  # Read the literal component = "..." string out of the roxygen @examples
  # in R/heritability.R itself, rather than hard-coding a second copy here,
  # so this test fails if the documented example label ever drifts from the
  # code again (Rose 2026-09-03 verdict, Attack 3 documentation finding).
  src <- readLines(testthat::test_path("..", "..", "R", "heritability.R"), warn = FALSE)
  example_line <- grep('icc\\(phylo_fit, component = "', src, value = TRUE, fixed = FALSE)
  expect_length(example_line, 1L)
  documented_label <- sub('.*component = "([^"]+)".*', "\\1", example_line)
  expect_equal(documented_label, "phylo(1 | species)")

  set.seed(20260601)
  n_tip <- 20
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("sp_", seq_len(n_tip))
  A <- ape::vcv(tree, corr = TRUE)
  u <- as.vector(t(chol(A)) %*% rnorm(n_tip)) * 0.9
  species <- factor(rep(tree$tip.label, each = 4), levels = tree$tip.label)
  phylo_dat <- data.frame(
    y = 2 + u[rep(seq_len(n_tip), each = 4)] + rnorm(length(species), sd = 0.6),
    species = species
  )
  phylo_fit <- drmTMB(
    bf(y ~ 1 + phylo(1 | species, tree = tree), sigma ~ 1),
    data = phylo_dat
  )

  expect_equal(names(phylo_fit$sdpars$mu), documented_label)
  r <- icc(phylo_fit, component = documented_label)
  expect_true(is.finite(r$estimate))
})
