binomial_animal_pedigree_sd_julia_fixture <- function(
  seed = 20261029L,
  link = "logit"
) {
  set.seed(seed)
  n_family <- 16L
  n_offspring <- 8L
  sires <- sprintf("sire-%02d", seq_len(n_family))
  dams <- sprintf("dam-%02d", seq_len(n_family))
  offspring <- sprintf(
    "offspring-%03d", seq_len(n_family * n_offspring)
  )
  pedigree <- data.frame(
    id = c(sires, dams, offspring),
    dam = c(rep(NA_character_, 2L * n_family), rep(dams, each = n_offspring)),
    sire = c(rep(NA_character_, 2L * n_family), rep(sires, each = n_offspring)),
    stringsAsFactors = FALSE
  )
  full_A <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  A <- full_A[offspring, offspring, drop = FALSE]
  z <- rep(c(-0.5, 0.5), length.out = length(offspring))
  names(z) <- offspring
  alpha <- c(`(Intercept)` = log(0.4), z = 0.5)
  group_sd <- exp(alpha[[1L]] + alpha[[2L]] * z)
  covariance <- tcrossprod(group_sd) * A
  latent <- drop(t(chol(covariance)) %*% stats::rnorm(length(offspring)))
  names(latent) <- offspring

  # Reverse first-appearance order relative to the pedigree matrix. Unobserved
  # sires and dams remain in the pedigree and must be integrated out by taking
  # the observed-offspring covariance submatrix.
  observed <- rev(offspring)
    n_each <- 28L
  id <- rep(observed, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), times = length(observed))
  z_row <- unname(z[id])
  eta <- -0.2 + 0.5 * x + latent[id]
  probability <- switch(
    link,
    logit = stats::plogis(eta),
    probit = stats::pnorm(eta),
    cloglog = -expm1(-exp(eta))
  )
  data <- data.frame(
    y = stats::rbinom(length(eta), size = 1L, prob = probability),
    id = factor(id, levels = observed),
    x,
    z = z_row
  )
  list(data = data, pedigree = pedigree, A = A, observed = observed, alpha = alpha)
}

test_that("Julia Binomial animal SD admits pedigree input on non-logit links", {
  sim <- binomial_animal_pedigree_sd_julia_fixture()
  pedigree <- sim$pedigree
  formula <- bf(
    y ~ animal(1 | id, pedigree = pedigree),
    sd(id, level = "animal") ~ z
  )
  expect_true(drm_julia_binomial_animal_sd_intercept_route_admitted(formula))
  payload <- drm_julia_structured_payload(
    formula, "binomial", sim$data, environment()
  )
  expect_identical(payload$kwarg, "A")
  expect_equal(
    unname(payload$matrix),
    unname(sim$A[sim$observed, sim$observed, drop = FALSE]),
    tolerance = 0
  )
  for (link in c("probit", "cloglog")) {
    expect_no_error(drm_julia_refuse_binomial_nonlogit_sd(
      formula, stats::binomial(link = link)
    ))
  }
})

test_that("Julia Binomial animal SD bridge marshals pedigree covariance", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  for (link in c("logit", "probit", "cloglog")) {
    sim <- binomial_animal_pedigree_sd_julia_fixture(
      seed = 20261029L + match(link, c("logit", "probit", "cloglog")),
      link = link
    )
    pedigree <- sim$pedigree
    formula <- bf(
      y ~ x + animal(1 | id, pedigree = pedigree),
      sd(id, level = "animal") ~ z
    )
    family <- stats::binomial(link = link)
    fit_tmb <- drmTMB(
      formula, family = family, data = sim$data, engine = "tmb"
    )
    fit_julia <- drmTMB(
      formula, family = family, data = sim$data, engine = "julia"
    )

    expected_A <- sim$A[sim$observed, sim$observed, drop = FALSE]
    expect_equal(unname(fit_julia$bridge_payload$matrix), unname(expected_A),
                 tolerance = 0)
    expect_identical(fit_julia$bridge_payload$kwarg, "A")
    tmb_sd <- coef(fit_tmb, dpar = "sd_animal(id)")
    julia_sd <- coef(fit_julia, dpar = "sd_animal(id)")
    expect_true(all(is.finite(tmb_sd)))
    expect_true(all(is.finite(julia_sd)))
    expect_named(julia_sd, names(tmb_sd))
    expect_lt(abs(unname(tmb_sd[["z"]] - sim$alpha[["z"]])), 0.3)
    expect_lt(abs(unname(julia_sd[["z"]] - sim$alpha[["z"]])), 0.3)
    expect_lt(abs(unname(julia_sd[["z"]] - tmb_sd[["z"]])), 0.35)
    expect_equal(as.numeric(logLik(fit_julia)), as.numeric(logLik(fit_tmb)),
                 tolerance = 0.02)
    sd_key <- "sd_animal(id)"
    expect_length(fit_julia$sdpars[[sd_key]], length(sim$observed))
    expect_equal(
      unname(predict(fit_julia, dpar = sd_key)),
      unname(fit_julia$sdpars[[sd_key]]),
      tolerance = 1e-10
    )
    draw <- simulate(fit_julia, nsim = 1L, seed = 20261040L)
    expect_equal(nrow(draw), nrow(sim$data))
    expect_true(all(draw[[1L]] %in% c(0L, 1L)))
  }
})
