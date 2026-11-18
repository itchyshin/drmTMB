test_that("Julia Binomial phylogenetic-slope SD admission stays narrow", {
  tree <- structure(list(), class = "phylo")
  dat <- data.frame(
    y = c(0L, 1L), x = c(-1, 1), z = c(-1, 1),
    species = factor(c("low", "high"))
  )
  form <- bf(
    y ~ x + phylo(0 + x | species, tree = tree),
    sd(species, level = "phylogenetic") ~ z
  )
  for (link in c("logit", "probit", "cloglog")) {
    expect_true(drm_julia_binomial_phylo_sd_slope_route_admitted(
      form, data = dat, link = link
    ), info = link)
  }
  selected_form <- bf(
    y ~ x + phylo(0 + x | species, tree = tree),
    sd(species, level = "phylogenetic", coef = "x") ~ z
  )
  expect_true(drm_julia_binomial_phylo_sd_slope_route_admitted(
    selected_form, data = dat, link = "logit"
  ))
  expect_false(drm_julia_binomial_phylo_sd_slope_route_admitted(
    form, data = dat, link = "cauchit"
  ))

  unsupported_coef <- bf(
    y ~ x + phylo(0 + x | species, tree = tree),
    sd(species, level = "phylogenetic", coef = "other") ~ z
  )
  expect_false(drm_julia_binomial_phylo_sd_slope_route_admitted(
    unsupported_coef, data = dat, link = "logit"
  ))

  unsupported_block <- bf(
    y ~ x + phylo(1 + x | species, tree = tree),
    sd(species, level = "phylogenetic") ~ z
  )
  expect_false(drm_julia_binomial_phylo_sd_slope_route_admitted(
    unsupported_block, data = dat, link = "logit"
  ))
})

test_that("Julia bridge fits slope-only Binomial phylogenetic SD for each link", {
  drm_skip_live_julia()
  skip_if_not_installed("ape")

  set.seed(20261027)
  n_tip <- 80L
  n_each <- 40L
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("slope_species_", seq_len(n_tip))
  height <- max(ape::node.depth.edgelength(tree)[seq_len(n_tip)])
  tree$edge.length <- tree$edge.length / height * 2.5
  K <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_species <- rep(c(-1, 1), each = n_tip / 2L)
  names(z_species) <- tree$tip.label
  tau <- exp(log(0.7) + 0.65 * z_species)
  unit_field <- as.vector(t(chol(K)) %*% stats::rnorm(n_tip))
  group <- rep(seq_len(n_tip), each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), times = n_tip)
  eta <- 0.15 + 0.3 * x + tau[group] * unit_field[group] * x
  dat <- data.frame(
    y = 0L,
    x,
    species = factor(tree$tip.label[group], levels = tree$tip.label),
    z = z_species[group]
  )
  form <- bf(
    y ~ x + phylo(0 + x | species, tree = tree),
    sd(species, level = "phylogenetic") ~ z
  )
  tip_data <- data.frame(
    species = factor(tree$tip.label, levels = tree$tip.label),
    z = unname(z_species[tree$tip.label])
  )

  for (link in c("logit", "probit", "cloglog")) {
    probability <- switch(
      link,
      logit = stats::plogis(eta),
      probit = stats::pnorm(eta),
      cloglog = -expm1(-exp(eta))
    )
    set.seed(20261028L)
    dat$y <- stats::rbinom(length(group), size = 1L, prob = probability)
    family <- stats::binomial(link = link)
    fit_julia <- drmTMB(form, family = family, data = dat, engine = "julia")
    fit_tmb <- drmTMB(
      form,
      family = family,
      data = dat,
      engine = "tmb",
      control = drm_control(se = FALSE)
    )
    coef_julia <- coef(fit_julia, "sd_phylo(species)")
    coef_tmb <- coef(fit_tmb, "sd_phylo(species)")

    expect_true(is_converged(fit_julia), info = link)
    expect_true(is_converged(fit_tmb), info = link)
    expect_equal(coef_julia, coef_tmb, tolerance = 3e-4, info = link)
    expect_lt(abs(coef_julia[["z"]] - 0.65), 0.5)
    expect_equal(
      as.numeric(logLik(fit_julia)),
      as.numeric(logLik(fit_tmb)),
      tolerance = 2e-5,
      info = link
    )
    expected_sd <- exp(
      as.vector(stats::model.matrix(~ z, tip_data) %*% coef_julia)
    )
    expect_equal(
      as.numeric(predict(
        fit_julia,
        newdata = tip_data,
        dpar = "sd_phylo(species)"
      )),
      expected_sd,
      tolerance = 1e-8,
      info = link
    )

    if (identical(link, "logit")) {
      roundtrip_path <- tempfile(fileext = ".rds")
      on.exit(unlink(roundtrip_path), add = TRUE)
      saveRDS(fit_julia, roundtrip_path)
      roundtrip <- readRDS(roundtrip_path)
      expect_equal(
        coef(roundtrip, "sd_phylo(species)"),
        coef_julia,
        tolerance = 1e-12
      )
      expect_equal(
        predict(
          roundtrip,
          newdata = tip_data,
          dpar = "sd_phylo(species)"
        ),
        predict(
          fit_julia,
          newdata = tip_data,
          dpar = "sd_phylo(species)"
        ),
        tolerance = 1e-12
      )
      simulated <- simulate(roundtrip, nsim = 1L, seed = 20261029L)
      expect_named(simulated, "sim_1")
      expect_true(all(simulated[[1L]] %in% c(0L, 1L)))
      expect_equal(
        simulate(fit_julia, nsim = 1L, seed = 20261029L),
        simulated
      )
    }
  }

})
