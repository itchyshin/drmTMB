test_that("Poisson ordinary scalar SD uses group rows and no free sigma", {
  sim <- poisson_sd_fixture(groups = 12L, repeats = 4L)
  spec <- drm_build_poisson_spec(bf(y ~ x + (1 | id), sd(id) ~ w), sim$data)
  expect_identical(spec$model_type, "poisson")
  expect_identical(spec$dpars, c("mu", "sd(id)"))
  expect_identical(spec$random_scale$mu$n_models, 1L)
  expect_equal(unname(spec$random_scale$mu$X_list[["sd(id)"]][, "w"]),
               sim$w_group)
  expect_identical(spec$random_scale$mu$re_sd_row0,
                   seq_len(nlevels(sim$data$id)) - 1L)
  expect_identical(spec$tmb_data$has_sd_mu_model, 1L)
  expect_equal(spec$tmb_data$X_sd_mu, spec$random_scale$mu$X,
               ignore_attr = TRUE)
  expect_length(spec$start$beta_sd_mu, 2L)
  expect_true(all(is.na(spec$map$log_sd_mu)))
  expect_true(all(is.na(spec$map$beta_sigma)))
})

test_that("Poisson scalar selectors and two independent groups retain identity", {
  sim <- poisson_sd_fixture(groups = 12L, repeats = 4L)
  dat <- sim$data
  dat$site <- factor(rep(seq_len(6L), length.out = nrow(dat)))
  dat$v <- seq(-1, 1, length.out = 6L)[as.integer(dat$site)]
  key <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
  spec <- drm_build_poisson_spec(bf(
    y ~ x + (1 | id) + (1 | site),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w,
    sd(site) ~ v
  ), dat)
  expect_identical(spec$random_scale$mu$dpars, c(key, "sd(site)"))
  expect_identical(spec$random_scale$mu$target_identity[[key]]$dpar, "mu")
  expect_identical(spec$random_scale$mu$target_identity[["sd(site)"]]$group,
                   "site")
  expect_identical(spec$random_scale$mu$re_sd_row0,
                   seq_len(spec$random$mu$n_re) - 1L)
})

test_that("Poisson parameter split retains selected SD coefficient slices", {
  dat <- poisson_sd_fixture(groups = 12L, repeats = 4L)$data
  dat$site <- factor(rep(seq_len(6L), length.out = nrow(dat)))
  dat$v <- seq(-1, 1, length.out = 6L)[as.integer(dat$site)]
  key <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
  spec <- drm_build_poisson_spec(bf(
    y ~ x + (1 | id) + (1 | site),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w,
    sd(site) ~ v
  ), dat)
  sd_mu <- spec$random_scale$mu
  expect_identical(sd_mu$dpars, c(key, "sd(site)"))
  expect_false(identical(sd_mu$coef_index[[key]],
                         sd_mu$coef_index[["sd(site)"]]))
  beta_sd_mu <- seq_len(ncol(sd_mu$X)) / 10
  par <- list(beta_mu = seq_len(ncol(spec$X$mu)) / 20,
              beta_sd_mu = beta_sd_mu)
  split <- split_tmb_parameters(par, spec)
  expect_identical(names(split), c("mu", key, "sd(site)"))
  for (target in sd_mu$dpars) {
    expected <- beta_sd_mu[sd_mu$coef_index[[target]]]
    names(expected) <- sd_mu$coef_names_list[[target]]
    expect_identical(split[[target]], expected)
  }
})

test_that("Poisson parameter split exposes phylogenetic SD coefficients", {
  target <- "sd_phylo(species)"
  X_sd_phylo <- matrix(
    c(1, 1, -1, 1),
    ncol = 2L,
    dimnames = list(NULL, c("(Intercept)", "w"))
  )
  spec <- list(
    model_type = "poisson",
    X = list(mu = matrix(1, nrow = 1L, dimnames = list(NULL, "(Intercept)"))),
    random_scale = list(
      mu = list(n_models = 0L),
      phylo = list(
        n_models = 1L,
        X = X_sd_phylo,
        dpars = target,
        coef_index = stats::setNames(list(seq_len(ncol(X_sd_phylo))), target),
        coef_names_list = stats::setNames(list(colnames(X_sd_phylo)), target)
      )
    ),
    missing_predictor = NULL
  )
  par <- list(beta_mu = 0.2, beta_sd_mu = c(-0.4, 0.7))

  split <- split_tmb_parameters(par, spec)

  expect_identical(names(split), c("mu", target))
  expect_identical(split[[target]], c("(Intercept)" = -0.4, w = 0.7))
})

test_that("Poisson scalar block labels select the existing latent coefficient", {
  dat <- poisson_sd_fixture(groups = 12L, repeats = 4L)$data
  key <- 'sd(id, dpar = "mu", coef = "(Intercept)", block = "p")'
  labelled <- drm_build_poisson_spec(bf(
    y ~ x + (1 | p | id),
    sd(id, dpar = "mu", coef = "(Intercept)", block = "p") ~ w
  ), dat)
  plain <- drm_build_poisson_spec(bf(y ~ x + (1 | id), sd(id) ~ w), dat)
  expect_identical(labelled$random_scale$mu$target_identity[[key]]$block, "p")
  shorthand <- drm_build_poisson_spec(bf(y ~ x + (1 | p | id), sd(id) ~ w), dat)
  expect_identical(shorthand$random_scale$mu$target_identity[["sd(id)"]]$block,
                   "p")
  expect_identical(labelled$random$mu$n_cors, 0L)
  expect_equal(labelled$tmb_data$X_sd_mu, plain$tmb_data$X_sd_mu,
               ignore_attr = TRUE)
  expect_identical(labelled$random_scale$mu$re_sd_row0,
                   plain$random_scale$mu$re_sd_row0)
  expect_error(drm_build_poisson_spec(bf(
    y ~ x + (1 | p | id), sd(id, block = "q") ~ w
  ), dat), "No ordinary random-effect SD target.*matches")
  expect_error(drm_build_poisson_spec(bf(
    y ~ x + (1 | p | id) + (1 | q | id), sd(id, block = "p") ~ w
  ), dat), "Overlapping random-effect terms")
  labelled_terms <- extract_random_mu_terms(quote(x + (1 | p | id)), "mu")$terms
  expect_error(validate_poisson_mu_random_terms(labelled_terms,
                                                family_label = "NB2"),
               "Unsupported random-effect term")
  expect_error(drm_build_poisson_spec(bf(
    y ~ x + (1 + x | p | id), sd(id, block = "p") ~ w
  ), dat), "labelled covariance blocks")
  coords <- cbind(seq_len(nlevels(dat$id)), rep(0, nlevels(dat$id)))
  rownames(coords) <- levels(dat$id)
  expect_error(drm_build_poisson_spec(bf(
    y ~ x + (1 | p | id) + spatial(1 | p | id, coords = coords)
  ), dat), "Unsupported random-effect term")
  expect_error(drm_build_poisson_spec(bf(y ~ x + (1 | p | id)), dat,
    missing = miss_control(response = "include")),
    "Unsupported random-effect term")
})

test_that("Poisson SD keeps zi, correlated-block, structure, and mi fences", {
  dat <- poisson_sd_fixture(groups = 12L, repeats = 4L)$data
  expect_error(drm_build_poisson_spec(bf(y ~ x, sd(id) ~ w), dat),
               "matching Poisson")
  expect_error(drm_build_poisson_spec(bf(y ~ x + (1 + x | id),
                                       sd(id, coef = "x") ~ w), dat),
               "correlated")
  dat$site <- factor(rep(seq_len(6L), length.out = nrow(dat)))
  expect_error(drm_build_poisson_spec(bf(
    y ~ x + (1 | id) + (0 + x | site), sd(id) ~ w
  ), dat), "random slopes")
  zi_spec <- drm_build_poisson_spec(bf(
    y ~ x + (1 | id), zi ~ 1, sd(id) ~ w
  ), dat)
  expect_identical(zi_spec$model_type, "zi_poisson")
  expect_identical(zi_spec$random_scale$mu$dpars, "sd(id)")
  expect_error(drm_build_poisson_spec(
    bf(y ~ x + (1 | id), sd(id) ~ w), dat,
    missing = miss_control(response = "include")
  ), "complete data")
  dat$w[1L] <- dat$w[1L] + 0.2
  expect_error(drm_build_poisson_spec(bf(y ~ x + (1 | id), sd(id) ~ w), dat),
               "constant within")
})

test_that("independent Poisson scalar integral preserves probability and mean", {
  eta <- -0.2; tau <- 0.4
  logp <- vapply(0:18, function(y) {
    poisson_sd_scalar_log_marginal(y, eta, tau, "adaptive")
  }, numeric(1L))
  probabilities <- exp(logp)
  expect_equal(sum(probabilities), 1, tolerance = 1e-6)
  expect_equal(sum((0:18) * probabilities), exp(eta + tau^2 / 2),
               tolerance = 1e-5)
  expect_equal(poisson_sd_scalar_log_marginal(c(1, 0), c(0.2, -0.3),
                                              tau, "adaptive"),
               poisson_sd_scalar_log_marginal(c(0, 1), c(-0.3, 0.2),
                                              tau, "adaptive"),
               tolerance = 1e-9)
})
