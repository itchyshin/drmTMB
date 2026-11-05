binomial_animal_q2_pedigree_fixture <- function(groups = 72L, repeats = 32L,
                                                 seed = 20261030L,
                                                 link = "logit") {
  set.seed(seed)
  n_families <- groups %/% 6L
  stopifnot(groups %% 6L == 0L)
  sires <- sprintf("sire-%02d", seq_len(n_families))
  dams <- sprintf("dam-%02d", seq_len(n_families))
  offspring <- sprintf("offspring-%03d", seq_len(groups))
  pedigree <- data.frame(
    id = c(sires, dams, offspring),
    dam = c(rep(NA_character_, 2L * n_families),
            rep(dams, each = 6L)),
    sire = c(rep(NA_character_, 2L * n_families),
             rep(sires, each = 6L)),
    stringsAsFactors = FALSE
  )
  full_A <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  A <- full_A[offspring, offspring, drop = FALSE]
  group_levels <- sample(offspring)
  index <- rep(seq_len(groups), each = repeats)
  id <- factor(group_levels[index], levels = group_levels)
  z0_group <- sample(rep(c(-1, 1), length.out = groups))
  z1_group <- sample(rep(c(-1, 1), length.out = groups))
  z0 <- z0_group[match(as.character(id), group_levels)]
  z1 <- z1_group[match(as.character(id), group_levels)]
  x <- rep(seq(-1.2, 1.2, length.out = repeats), groups)

  alpha0 <- c(`(Intercept)` = -0.6, z0 = 0.5)
  alpha1 <- c(`(Intercept)` = -0.75, z1 = 0.6)
  rho <- 0.4
  tau0 <- exp(alpha0[[1L]] + alpha0[[2L]] * z0_group)
  tau1 <- exp(alpha1[[1L]] + alpha1[[2L]] * z1_group)
  L <- t(chol(A[group_levels, group_levels, drop = FALSE]))
  latent0 <- drop(L %*% stats::rnorm(groups))
  latent1_independent <- drop(L %*% stats::rnorm(groups))
  latent1 <- rho * latent0 + sqrt(1 - rho^2) * latent1_independent
  eta <- -0.1 + 0.25 * x + tau0[index] * latent0[index] +
    x * tau1[index] * latent1[index]
  probability <- switch(
    link,
    logit = stats::plogis(eta),
    probit = stats::pnorm(eta),
    cloglog = -expm1(-exp(eta))
  )
  data <- data.frame(y = stats::rbinom(length(id), 1L, probability),
                     x, z0, z1, id)
  list(data = data, pedigree = pedigree, A = A,
       alpha0 = alpha0, alpha1 = alpha1)
}

test_that("Julia Binomial animal q2 SD accepts pedigree input", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path),
          "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  for (link in c("logit", "probit", "cloglog")) {
    fx <- binomial_animal_q2_pedigree_fixture(
      seed = 20261030L + match(link, c("logit", "probit", "cloglog")),
      link = link
    )
    pedigree <- fx$pedigree
    formula <- bf(
      y ~ x + animal(1 + x | id, pedigree = pedigree),
      sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ z0,
      sd(id, level = "animal", dpar = "mu", coef = "x") ~ z1
    )
    family <- stats::binomial(link = link)
    payload <- drm_julia_structured_payload(
      formula, "binomial", fx$data, environment()
    )
    expected_A <- fx$A[unique(as.character(fx$data$id)),
                       unique(as.character(fx$data$id)), drop = FALSE]
    expect_identical(payload$kwarg, "A", info = link)
    expect_equal(unname(payload$matrix), unname(expected_A),
                 tolerance = 0, info = link)

    native <- drmTMB(formula, family = family, data = fx$data,
                     engine = "tmb")
    julia <- drmTMB(formula, family = family, data = fx$data,
                    engine = "julia")
    expect_equal(native$opt$convergence, 0L, info = link)
    expect_true(is_converged(julia), info = link)
    expect_equal(as.numeric(logLik(julia)), as.numeric(logLik(native)),
                 tolerance = 0.2, info = link)

    targets <- lapply(formula$entries[-1L], function(entry) {
      parse_sd_lhs(entry$lhs)
    })
    dpars <- vapply(targets, drm_julia_sd_public_dpar, character(1L))
    for (i in seq_along(dpars)) {
      dpar <- dpars[[i]]
      native_coef <- coef(native, dpar = dpar)
      julia_coef <- coef(julia, dpar = dpar)
      truth <- if (targets[[i]]$target_coef %in% c("intercept", "(Intercept)")) {
        fx$alpha0
      } else {
        fx$alpha1
      }
      expect_named(julia_coef, names(native_coef), info = link)
      expect_equal(unname(julia_coef), unname(native_coef),
                   tolerance = 0.5, info = link)
      expect_true(all(abs(unname(julia_coef) - truth[names(julia_coef)]) < 0.8),
                  info = link)
      native_sd <- predict(native, dpar = dpar)
      julia_sd <- predict(julia, dpar = dpar)
      expect_true(setequal(names(julia_sd), names(native_sd)), info = link)
      expect_equal(
        unname(julia_sd[match(names(native_sd), names(julia_sd))]),
        unname(native_sd), tolerance = 0.2, info = link
      )
    }
    draws <- simulate(julia, nsim = 1L, seed = 20261033L)
    expect_equal(nrow(draws), nrow(fx$data), info = link)
    expect_true(all(draws[[1L]] %in% c(0L, 1L)), info = link)
  }
})
