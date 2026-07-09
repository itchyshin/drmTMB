# C1: scale-side (sigma ~ spatial/animal/relmat) structured effects under REML.
# Admitted 2026-07-08 after a recovery + coverage campaign (Totoro): REML debiases
# the scale-side intercept SD 400/400 across the three providers with bias -> 0 as g
# grows, and REML profile-CI coverage clears the small-g inference_ready floor
# (>= 0.926 vs 0.91). The relaxation is bounded: mean-side non-phylo structured
# effects and the bivariate path stay rejected until separately validated.

scale_structured_data <- function(provider, g = 8L, n_each = 20L, seed = 1L) {
  set.seed(seed)
  labels <- paste0("id", seq_len(g))
  if (provider == "spatial") {
    theta <- seq(0, 1.5 * pi, length.out = g)
    coords <- data.frame(x = cos(theta) + seq_len(g) / (3 * g), y = sin(theta))
    rownames(coords) <- labels
    p <- drmTMB:::drm_spatial_coords_precision(coords, site = labels, group = "id")
    K <- solve(as.matrix(p$precision)); aux <- coords
  } else if (provider == "relmat") {
    K <- outer(seq_len(g), seq_len(g), function(i, j) 0.35^abs(i - j))
    diag(K) <- diag(K) + 0.15
    dimnames(K) <- list(labels, labels); aux <- K
  } else {
    ped <- data.frame(id = labels,
                      dam = c(NA, NA, NA, NA, "id1", "id3", "id5", "id1"),
                      sire = c(NA, NA, NA, NA, "id2", "id4", "id6", "id3"),
                      stringsAsFactors = FALSE)
    K <- drmTMB:::drm_pedigree_additive_relationship(ped); aux <- K
  }
  eff <- as.vector(t(chol(K)) %*% stats::rnorm(g)) * 0.5
  names(eff) <- labels
  ep <- rep(labels, each = n_each)
  x <- rep(seq(-1.2, 1.2, length.out = n_each), times = g)
  y <- 0.4 + 0.25 * x + exp(-0.9 + eff[ep]) * stats::rnorm(g * n_each)
  list(data = data.frame(y = y, x = x, id = ep, stringsAsFactors = FALSE), aux = aux)
}

test_that("REML admits scale-side spatial/animal/relmat structured effects (C1)", {
  skip_on_cran()
  for (provider in c("spatial", "relmat", "animal")) {
    sim <- scale_structured_data(provider)
    dat <- sim$data
    form <- switch(provider,
      spatial = { coords <- sim$aux; bf(y ~ x, sigma ~ spatial(1 + x | id, coords = coords)) },
      relmat  = { K <- sim$aux;      bf(y ~ x, sigma ~ relmat(1 + x | id, K = K)) },
      animal  = { A <- sim$aux;      bf(y ~ x, sigma ~ animal(1 + x | id, A = A)) })
    fit <- suppressWarnings(drmTMB(
      form, family = gaussian(), data = dat, REML = TRUE,
      control = drm_control(optimizer = list(eval.max = 800, iter.max = 800))
    ))
    expect_identical(fit$estimator, "REML")
    expect_equal(fit$opt$convergence, 0, info = provider)
    # The scale-side intercept SD is fitted, finite, and positive.
    pars <- summary(fit)$parameters
    int_sd <- pars$estimate[grepl("^sd:sigma:.*\\(1 \\|", pars$parm)][1]
    expect_true(is.finite(int_sd) && int_sd > 0, info = provider)
  }
})

test_that("REML admits an intercept-only scale-side structured effect (C1)", {
  skip_on_cran()
  sim <- scale_structured_data("spatial")
  coords <- sim$aux
  fit <- suppressWarnings(drmTMB(
    bf(y ~ x, sigma ~ spatial(1 | id, coords = coords)),
    family = gaussian(), data = sim$data, REML = TRUE,
    control = drm_control(optimizer = list(eval.max = 800, iter.max = 800))
  ))
  expect_identical(fit$estimator, "REML")
  expect_equal(fit$opt$convergence, 0)
})

test_that("the C1 relaxation stays bounded: mean-side non-phylo stays rejected", {
  skip_on_cran()
  sim <- scale_structured_data("spatial")
  coords <- sim$aux
  dat <- sim$data
  # MEAN-side non-phylo structured effect under REML: unvalidated, still rejected.
  expect_error(
    drmTMB(bf(y ~ x + spatial(1 + x | id, coords = coords), sigma ~ 1),
           family = gaussian(), data = dat, REML = TRUE),
    "Mean-side spatial, animal, and relatedness"
  )
  # A mean+scale-spanning non-phylo structured effect is also still rejected
  # (only pure scale-side is validated).
  expect_error(
    drmTMB(bf(y ~ x + spatial(1 | p | id, coords = coords),
              sigma ~ spatial(1 | p | id, coords = coords)),
           family = gaussian(), data = dat, REML = TRUE),
    "Mean-side spatial, animal, and relatedness"
  )
})
