test_that("phylo covariance model defaults to Brownian motion and accepts OU", {
  bm <- drmTMB:::parse_structured_marker_call(
    quote(phylo(1 | species, tree = tree)), "phylo", "mu"
  )
  ou <- drmTMB:::parse_structured_marker_call(
    quote(phylo(1 | species, tree = tree, model = "ou")), "phylo", "mu"
  )
  expect_identical(bm$model, "bm")
  expect_identical(ou$model, "ou")
  expect_identical(ou$tree, "tree")
})

test_that("phylo covariance model rejects malformed choices before fitting", {
  expect_error(
    drmTMB:::parse_structured_marker_call(
      quote(phylo(1 | species, tree = tree, model = "ar1")), "phylo", "mu"
    ),
    "bm.*ou"
  )
  expect_error(
    drmTMB:::parse_structured_marker_call(
      quote(phylo(1 | species, tree = tree, model = model_name)), "phylo", "mu"
    ),
    "must be"
  )
})

test_that("phylogenetic OU rejects unsupported model combinations before fitting", {
  skip_if_not_installed("ape")
  set.seed(2026091101)
  tree <- ape::rcoal(3)
  tree$tip.label <- paste0("sp", seq_len(3))
  dat <- data.frame(
    y = stats::rnorm(9),
    species = rep(tree$tip.label, each = 3)
  )
  expect_error(
    drmTMB(
      bf(y ~ (1 | species) + phylo(1 | species, tree = tree, model = "ou"), sigma ~ 1),
      data = dat, family = gaussian()
    ),
    "univariate Gaussian location intercept"
  )
})

test_that("joint independent OU location and sigma intercepts have separate rates", {
  skip_if_not_installed("ape")
  set.seed(2026091206)
  tree <- ape::rcoal(6)
  tree$tip.label <- paste0("sp", seq_len(6))
  species <- rep(tree$tip.label, each = 7)
  temperature <- rep(seq(-1, 1, length.out = 7), times = length(tree$tip.label))
  precipitation <- stats::rnorm(length(species))
  dat <- data.frame(
    y = 0.3 + 0.2 * temperature + stats::rnorm(
      length(species), sd = exp(-1 + 0.15 * precipitation)
    ),
    temperature, precipitation, species
  )

  fit <- drmTMB(
    bf(
      y ~ temperature + phylo(1 | species, tree = tree, model = "ou"),
      sigma ~ precipitation + phylo(1 | species, tree = tree, model = "ou")
    ),
    data = dat, family = gaussian(),
    control = drm_control(optimizer = list(eval.max = 1000, iter.max = 1000))
  )

  phylo <- fit$model$structured$phylo_mu
  expect_identical(phylo$dpars, c("mu", "sigma"))
  expect_identical(unname(vapply(
    drmTMB:::phylo_ou_provider_fields(phylo), `[[`, character(1L), "dpar"
  )), c("mu", "sigma"))
  expect_named(fit$decaypars$phylo, c("decay_phylo", "decay_phylo:sigma"))
  expect_true(all(is.finite(fit$decaypars$phylo)))
  expect_true(all(is.na(fit$model$map$eta_cor_phylo)))
  expect_null(fit$corpars$phylo)
  expect_equal(nrow(corpairs(fit)), 0L)
  marginal <- simulate(fit, nsim = 2, seed = 2026091206)
  conditional <- simulate(fit, nsim = 2, seed = 2026091206, re.form = NA)
  expect_identical(dim(marginal), c(nrow(dat), 2L))
  expect_true(all(is.finite(as.matrix(marginal))))
  expect_false(isTRUE(all.equal(marginal, conditional)))
})

test_that("joint OU scale field is ML-only and excludes unmatched OU fields", {
  skip_if_not_installed("ape")
  set.seed(2026091207)
  tree <- ape::rcoal(5)
  tree$tip.label <- paste0("sp", seq_len(5))
  dat <- data.frame(
    y = stats::rnorm(30),
    species = rep(tree$tip.label, each = 6)
  )
  V <- diag(nrow(dat))
  joint <- bf(
    y ~ phylo(1 | species, tree = tree, model = "ou"),
    sigma ~ phylo(1 | species, tree = tree, model = "ou")
  )
  expect_error(
    drmTMB(joint, data = dat, family = gaussian(), REML = TRUE),
    "ML only"
  )
  expect_error(
    drmTMB(
      bf(y ~ 1, sigma ~ phylo(1 | species, tree = tree, model = "ou")),
      data = dat, family = gaussian()
    ),
    "joint location and residual-scale intercepts"
  )
  expect_error(
    drmTMB(joint, data = dat, family = gaussian(), weights = rep(2, nrow(dat))),
    "non-unit weights"
  )
  expect_error(
    drmTMB(
      bf(
        y ~ meta_V(V = V) + phylo(1 | species, tree = tree, model = "ou"),
        sigma ~ phylo(1 | species, tree = tree, model = "ou")
      ),
      data = dat, family = gaussian()
    ),
    "known sampling covariance"
  )
  expect_error(
    drmTMB(
      bf(
        y ~ phylo(1 | p | species, tree = tree, model = "ou"),
        sigma ~ phylo(1 | p | species, tree = tree, model = "ou")
      ),
      data = dat, family = gaussian()
    ),
    "labels/coupled covariance blocks"
  )
  expect_error(
    drmTMB(joint, data = dat, family = gaussian(), engine = "julia"),
    "native TMB"
  )
})

test_that("explicit Brownian model reproduces the omitted-model fit", {
  skip_if_not_installed("ape")
  set.seed(2026091102)
  tree <- ape::rcoal(4)
  tree$tip.label <- paste0("sp", seq_len(4))
  dat <- data.frame(
    y = stats::rnorm(16),
    x = rep(c(-0.5, 0.5), length.out = 16),
    species = rep(tree$tip.label, each = 4)
  )
  implicit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
    data = dat, family = gaussian()
  )
  explicit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree, model = "bm"), sigma ~ 1),
    data = dat, family = gaussian()
  )
  expect_equal(as.numeric(logLik(explicit)), as.numeric(logLik(implicit)), tolerance = 1e-8)
  expect_equal(coef(explicit, "mu"), coef(implicit, "mu"), tolerance = 1e-8)
})
