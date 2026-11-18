test_that("non-logit Binomial guard defers only supported structured SD routes", {
  A <- outer(seq_len(4L), seq_len(4L), function(i, j) 0.4^abs(i - j))
  Ainv <- solve(A)
  unsupported_animal_block <- bf(
    y ~ x + animal(1 + x | id, A = A),
    sd(id, level = "animal") ~ z
  )
  unsupported_animal_precision_slope <- bf(
    y ~ x + animal(0 + x | id, Ainv = Ainv),
    sd(id, level = "animal") ~ z
  )
  # A pedigree animal SD route is now admitted on probit and cloglog (see
  # test-julia-binomial-animal-pedigree-sd-bridge.R), so the still-refused
  # precision-matrix slot of the same kind is pinned here: relmat Q has no
  # Julia route (docs/dev-log/after-task/2026-10-27-julia-binomial-nonlogit-animal-sd.md).
  Q <- Ainv
  unsupported_relmat_precision <- bf(
    y ~ x + relmat(1 | id, Q = Q),
    sd(id, level = "relmat") ~ z
  )

  for (link in c("probit", "cloglog")) {
    for (formula in list(
      unsupported_animal_block,
      unsupported_relmat_precision
    )) {
      expect_error(
        drm_julia_refuse_binomial_nonlogit_sd(
          formula, stats::binomial(link = link)
        ),
        "requested formula does not match"
      )
    }
    expect_no_error(
      drm_julia_refuse_binomial_nonlogit_sd(
        unsupported_animal_precision_slope,
        stats::binomial(link = link)
      )
    )
    expect_identical(
      drm_julia_structured_family_tag(
        "binomial", unsupported_animal_precision_slope, link = link
      ),
      paste0("binomial_", link),
      info = link
    )
  }

  dat <- data.frame(
    y = c(0L, 1L, 0L, 1L), x = c(-1, 1, -1, 1), z = c(-1, -1, 1, 1),
    id = factor(c("a", "a", "b", "b"), levels = c("a", "b"))
  )
  payload <- drm_julia_structured_payload(
    unsupported_animal_precision_slope, "binomial", dat, environment()
  )
  expect_identical(payload$kwarg, "Ainv")
  expect_equal(payload$matrix, Ainv)
})

test_that("probit and cloglog animal-slope SD regression runs through the Julia bridge", {
  skip_if_not(identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true"),
              "Julia bridge tests are opt-in")
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  groups <- 80L
  repeats <- 32L
  set.seed(202610270L)
  id_levels <- paste0("id", seq_len(groups))
  A <- outer(seq_len(groups), seq_len(groups), function(i, j) 0.35^abs(i - j))
  dimnames(A) <- list(id_levels, id_levels)
  Ainv <- solve(A)
  # Randomize SD-predictor allocation over the correlated groups. A contiguous
  # split would align z with the smooth AR(1) eigenvectors and weaken separation
  # of the SD trend from the structured latent field.
  z_group <- sample(rep(c(-1, 1), each = groups / 2L))
  alpha <- c(`(Intercept)` = -0.7, z = 0.4)
  slope_sd <- exp(alpha[[1L]] + alpha[[2L]] * z_group)
  covariance <- tcrossprod(slope_sd) * A
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_levels[id_index], levels = id_levels)
  x <- stats::rnorm(groups * repeats)
  z <- z_group[id_index]
  formula <- bf(
    y ~ x + animal(0 + x | id, Ainv = Ainv),
    sd(id, level = "animal") ~ z
  )

  for (link in c("probit", "cloglog")) {
    expect_identical(
      drm_julia_structured_family_tag("binomial", formula, link = link),
      paste0("binomial_", link),
      info = link
    )
    set.seed(if (link == "probit") 202610271L else 202610272L)
    latent_slope <- as.vector(t(chol(covariance)) %*% stats::rnorm(groups))
    eta <- -0.1 + 0.35 * x + x * latent_slope[id_index]
    probability <- stats::binomial(link = link)$linkinv(eta)
    dat <- data.frame(
      y = stats::rbinom(length(id), 1L, probability), x = x, z = z, id = id
    )
    fit_tmb <- drmTMB(
      formula, family = stats::binomial(link), data = dat, engine = "tmb",
      control = drm_control(se = FALSE)
    )
    fit_julia <- drmTMB(
      formula, family = stats::binomial(link), data = dat, engine = "julia"
    )

    target <- "sd_animal(id)"
    beta_tmb <- coef(fit_tmb, dpar = target)
    beta_julia <- coef(fit_julia, dpar = target)
    expect_true(is_converged(fit_tmb), info = link)
    expect_true(is_converged(fit_julia), info = link)
    expect_named(beta_julia, names(alpha), info = link)
    expect_true(all(is.finite(beta_tmb)), info = link)
    expect_true(all(is.finite(beta_julia)), info = link)
    expect_true(
      abs(unname(beta_tmb[["z"]] - alpha[["z"]])) < 0.5,
      info = paste(link, "TMB recovery")
    )
    expect_true(
      abs(unname(beta_julia[["z"]] - alpha[["z"]])) < 0.5,
      info = paste(link, "Julia recovery")
    )
    expect_equal(
      as.numeric(logLik(fit_julia)), as.numeric(logLik(fit_tmb)),
      tolerance = 0.1, info = link
    )

    group_data <- data.frame(
      id = factor(id_levels, levels = id_levels), z = z_group
    )
    sd_tmb <- predict(fit_tmb, newdata = group_data, dpar = target)
    sd_julia <- predict(fit_julia, newdata = group_data, dpar = target)
    expect_equal(
      as.numeric(sd_julia),
      exp(unname(beta_julia[["(Intercept)"]] + beta_julia[["z"]] * z_group)),
      tolerance = 1e-8,
      info = link
    )
    expect_equal(as.numeric(sd_julia), as.numeric(sd_tmb), tolerance = 0.2,
                 info = link)
  }
})

test_that("probit and cloglog animal-intercept SD regression runs through the Julia bridge", {
  skip_if_not(identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true"),
              "Julia bridge tests are opt-in")
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  groups <- 80L
  repeats <- 32L
  set.seed(202610290L)
  id_levels <- paste0("animal_id", seq_len(groups))
  A <- outer(seq_len(groups), seq_len(groups), function(i, j) 0.35^abs(i - j))
  dimnames(A) <- list(id_levels, id_levels)
  z_group <- sample(rep(c(-1, 1), each = groups / 2L))
  alpha <- c(`(Intercept)` = -0.7, z = 0.4)
  group_sd <- exp(alpha[[1L]] + alpha[[2L]] * z_group)
  covariance <- tcrossprod(group_sd) * A
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_levels[id_index], levels = id_levels)
  x <- stats::rnorm(groups * repeats)
  z <- z_group[id_index]
  formula <- bf(
    y ~ x + animal(1 | id, A = A),
    sd(id, level = "animal") ~ z
  )

  for (link in c("probit", "cloglog")) {
    expect_identical(
      drm_julia_structured_family_tag("binomial", formula, link = link),
      paste0("binomial_", link),
      info = link
    )
    set.seed(if (link == "probit") 202610291L else 202610292L)
    latent <- drop(t(chol(covariance)) %*% stats::rnorm(groups))
    eta <- -0.1 + 0.35 * x + latent[id_index]
    probability <- stats::binomial(link = link)$linkinv(eta)
    dat <- data.frame(
      y = stats::rbinom(length(id), 1L, probability), x = x, z = z, id = id
    )
    fit_tmb <- drmTMB(
      formula, family = stats::binomial(link), data = dat, engine = "tmb",
      control = drm_control(se = FALSE)
    )
    fit_julia <- drmTMB(
      formula, family = stats::binomial(link), data = dat, engine = "julia"
    )

    target <- "sd_animal(id)"
    beta_tmb <- coef(fit_tmb, dpar = target)
    beta_julia <- coef(fit_julia, dpar = target)
    expect_true(is_converged(fit_tmb), info = link)
    expect_true(is_converged(fit_julia), info = link)
    expect_named(beta_julia, names(alpha), info = link)
    expect_true(all(is.finite(beta_tmb)), info = link)
    expect_true(all(is.finite(beta_julia)), info = link)
    expect_true(abs(unname(beta_tmb[["z"]] - alpha[["z"]])) < 0.5,
                info = paste(link, "TMB recovery"))
    expect_true(abs(unname(beta_julia[["z"]] - alpha[["z"]])) < 0.5,
                info = paste(link, "Julia recovery"))
    expect_equal(
      as.numeric(logLik(fit_julia)), as.numeric(logLik(fit_tmb)),
      tolerance = 0.1, info = link
    )

    group_data <- data.frame(
      id = factor(id_levels, levels = id_levels), z = z_group
    )
    sd_tmb <- predict(fit_tmb, newdata = group_data, dpar = target)
    sd_julia <- predict(fit_julia, newdata = group_data, dpar = target)
    expect_equal(
      as.numeric(sd_julia),
      exp(unname(beta_julia[["(Intercept)"]] + beta_julia[["z"]] * z_group)),
      tolerance = 1e-8,
      info = link
    )
    expect_equal(as.numeric(sd_julia), as.numeric(sd_tmb), tolerance = 0.2,
                 info = link)
  }
})

test_that("probit and cloglog relmat-intercept SD regression runs through the Julia bridge", {
  skip_if_not(identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true"),
              "Julia bridge tests are opt-in")
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  groups <- 120L
  repeats <- 30L
  set.seed(202610280L)
  id_levels <- paste0("relmat_id", seq_len(groups))
  K <- outer(seq_len(groups), seq_len(groups), function(i, j) 0.45^abs(i - j))
  dimnames(K) <- list(id_levels, id_levels)
  # Randomize allocation over the correlated groups to avoid confounding the
  # SD predictor with the smooth eigenvectors of the AR(1) relatedness matrix.
  z_group <- sample(rep(c(-1, 1), each = groups / 2L))
  alpha <- c(`(Intercept)` = -0.65, z = 0.4)
  group_sd <- exp(alpha[[1L]] + alpha[[2L]] * z_group)
  covariance <- tcrossprod(group_sd) * K
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_levels[id_index], levels = id_levels)
  x <- stats::rnorm(groups * repeats)
  z <- z_group[id_index]
  formula <- bf(
    y ~ x + relmat(1 | id, K = K),
    sd(id, level = "relmat") ~ z
  )

  for (link in c("probit", "cloglog")) {
    expect_identical(
      drm_julia_structured_family_tag("binomial", formula, link = link),
      paste0("binomial_", link),
      info = link
    )
    set.seed(if (link == "probit") 202610281L else 202610282L)
    latent <- drop(t(chol(covariance)) %*% stats::rnorm(groups))
    eta <- -0.1 + 0.35 * x + latent[id_index]
    probability <- stats::binomial(link = link)$linkinv(eta)
    dat <- data.frame(
      y = stats::rbinom(length(id), 1L, probability), x = x, z = z, id = id
    )
    fit_tmb <- drmTMB(
      formula, family = stats::binomial(link), data = dat, engine = "tmb",
      control = drm_control(se = FALSE)
    )
    fit_julia <- drmTMB(
      formula, family = stats::binomial(link), data = dat, engine = "julia"
    )

    target <- "sd_relmat(id)"
    beta_tmb <- coef(fit_tmb, dpar = target)
    beta_julia <- coef(fit_julia, dpar = target)
    expect_true(is_converged(fit_tmb), info = link)
    expect_true(is_converged(fit_julia), info = link)
    expect_named(beta_julia, names(alpha), info = link)
    expect_true(all(is.finite(beta_tmb)), info = link)
    expect_true(all(is.finite(beta_julia)), info = link)
    expect_true(abs(unname(beta_tmb[["z"]] - alpha[["z"]])) < 0.5,
                info = paste(link, "TMB recovery"))
    expect_true(abs(unname(beta_julia[["z"]] - alpha[["z"]])) < 0.5,
                info = paste(link, "Julia recovery"))
    expect_equal(
      as.numeric(logLik(fit_julia)), as.numeric(logLik(fit_tmb)),
      tolerance = 0.1, info = link
    )

    group_data <- data.frame(
      id = factor(id_levels, levels = id_levels), z = z_group
    )
    sd_tmb <- predict(fit_tmb, newdata = group_data, dpar = target)
    sd_julia <- predict(fit_julia, newdata = group_data, dpar = target)
    expect_equal(
      as.numeric(sd_julia),
      exp(unname(beta_julia[["(Intercept)"]] + beta_julia[["z"]] * z_group)),
      tolerance = 1e-8,
      info = link
    )
    expect_equal(as.numeric(sd_julia), as.numeric(sd_tmb), tolerance = 0.2,
                 info = link)
  }
})
