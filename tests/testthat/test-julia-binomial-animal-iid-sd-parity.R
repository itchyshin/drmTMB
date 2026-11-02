binomial_animal_iid_sd_parity_data <- function(seed = 20261024L) {
  set.seed(seed)
  n_animal <- 36L
  n_site <- 30L
  repeats <- 4L
  animal_index <- rep(seq_len(n_animal), each = n_site * repeats)
  site_index <- rep(rep(seq_len(n_site), each = repeats), times = n_animal)
  z_levels <- seq(-1, 1, length.out = n_animal)
  w_levels <- seq(-1, 1, length.out = n_site)
  z <- z_levels[animal_index]
  w <- w_levels[site_index]
  x <- stats::rnorm(length(animal_index))

  correlation <- outer(seq_len(n_animal), seq_len(n_animal),
                       function(i, j) 0.45^abs(i - j))
  animal_scale <- sample(seq_len(n_animal)) / n_animal + 0.5
  A <- tcrossprod(animal_scale) * correlation
  animal_effect <- as.vector(t(chol(A)) %*% stats::rnorm(n_animal))
  site_effect <- stats::rnorm(n_site)
  eta <- -0.2 + 0.3 * x +
    exp(-0.75 + 0.50 * z_levels)[animal_index] * animal_effect[animal_index] +
    exp(-0.35 - 0.60 * w_levels)[site_index] * site_effect[site_index]
  y <- stats::rbinom(length(eta), size = 1L, prob = stats::plogis(eta))

  data <- data.frame(
    y = y,
    x = x,
    z = z,
    w = w,
    animal_id = factor(paste0("animal_", animal_index),
                       levels = paste0("animal_", seq_len(n_animal))),
    site = factor(paste0("site_", site_index),
                  levels = paste0("site_", seq_len(n_site)))
  )
  dimnames(A) <- list(levels(data$animal_id), levels(data$animal_id))
  list(data = data, A = A)
}

binomial_animal_iid_laplace_oracle <- function(data, A, beta,
                                                animal_alpha, site_alpha) {
  animal_levels <- rownames(A)
  site_levels <- levels(data$site)
  animal_index <- match(as.character(data$animal_id), animal_levels)
  site_index <- match(as.character(data$site), site_levels)
  animal_z <- data$z[match(animal_levels, as.character(data$animal_id))]
  site_w <- data$w[match(site_levels, as.character(data$site))]
  animal_sd <- exp(animal_alpha[[1L]] + animal_alpha[[2L]] * animal_z)
  site_sd <- exp(site_alpha[[1L]] + site_alpha[[2L]] * site_w)
  n <- nrow(data)
  n_animal <- length(animal_levels)
  n_site <- length(site_levels)
  M <- matrix(0, nrow = n, ncol = n_animal + n_site)
  M[cbind(seq_len(n), animal_index)] <- animal_sd[animal_index]
  M[cbind(seq_len(n), n_animal + site_index)] <- site_sd[site_index]
  Q <- matrix(0, nrow = n_animal + n_site, ncol = n_animal + n_site)
  Q[seq_len(n_animal), seq_len(n_animal)] <- solve(A)
  diag(Q)[n_animal + seq_len(n_site)] <- 1
  X <- stats::model.matrix(~ x, data = data)
  eta_fixed <- drop(X %*% beta)
  y <- data$y

  joint_nll <- function(u) {
    eta <- eta_fixed + drop(M %*% u)
    0.5 * sum(u * drop(Q %*% u)) +
      sum(pmax(eta, 0) + log1p(exp(-abs(eta))) - y * eta)
  }
  u <- numeric(n_animal + n_site)
  converged <- FALSE
  for (iteration in seq_len(100L)) {
    eta <- eta_fixed + drop(M %*% u)
    probability <- stats::plogis(eta)
    gradient <- drop(Q %*% u) + drop(crossprod(M, probability - y))
    hessian <- Q + crossprod(M, M * (probability * (1 - probability)))
    step <- drop(solve(hessian, gradient))
    if (max(abs(step)) < 1e-9) {
      converged <- TRUE
      break
    }
    old_value <- joint_nll(u)
    rate <- 1
    while (rate > 1e-8) {
      candidate <- u - rate * step
      if (joint_nll(candidate) <= old_value) {
        u <- candidate
        break
      }
      rate <- rate / 2
    }
    if (rate <= 1e-8) {
      stop("independent animal-plus-IID Laplace mode did not converge",
           call. = FALSE)
    }
  }
  if (!converged) {
    stop("independent animal-plus-IID Laplace mode exceeded 100 iterations",
         call. = FALSE)
  }
  eta <- eta_fixed + drop(M %*% u)
  probability <- stats::plogis(eta)
  hessian <- Q + crossprod(M, M * (probability * (1 - probability)))
  logdet_q <- as.numeric(determinant(Q, logarithm = TRUE)$modulus)
  logdet_h_half <- sum(log(diag(chol(hessian))))
  -joint_nll(u) + 0.5 * logdet_q - logdet_h_half
}

test_that("Binomial animal plus IID SD regression agrees across engines", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path),
          "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  sim <- binomial_animal_iid_sd_parity_data()
  A <- sim$A
  Ainv <- solve(A)
  formula <- bf(
    y ~ x + animal(1 | animal_id, A = A) + (1 | site),
    sd(animal_id, level = "animal") ~ z,
    sd(site) ~ w
  )
  formula_Ainv <- bf(
    y ~ x + animal(1 | animal_id, Ainv = Ainv) + (1 | site),
    sd(animal_id, level = "animal") ~ z,
    sd(site) ~ w
  )

  expect_identical(drm_julia_structured_family_tag("binomial", formula),
                   "binomial")
  expect_identical(drm_julia_structured_family_tag("binomial", formula_Ainv),
                   "binomial")

  fit_tmb <- drmTMB(
    formula, family = stats::binomial(), data = sim$data, engine = "tmb"
  )
  fit_julia <- drmTMB(
    formula, family = stats::binomial(), data = sim$data, engine = "julia"
  )
  fit_tmb_Ainv <- drmTMB(
    formula_Ainv, family = stats::binomial(), data = sim$data, engine = "tmb"
  )
  fit_julia_Ainv <- drmTMB(
    formula_Ainv, family = stats::binomial(), data = sim$data, engine = "julia"
  )

  animal_key <- "sd_animal(animal_id)"
  site_key <- "sd(site)"
  animal_tmb <- coef(fit_tmb, dpar = animal_key)
  animal_julia <- coef(fit_julia, dpar = animal_key)
  site_tmb <- coef(fit_tmb, dpar = site_key)
  site_julia <- coef(fit_julia, dpar = site_key)
  animal_tmb_Ainv <- coef(fit_tmb_Ainv, dpar = animal_key)
  animal_julia_Ainv <- coef(fit_julia_Ainv, dpar = animal_key)
  site_tmb_Ainv <- coef(fit_tmb_Ainv, dpar = site_key)
  site_julia_Ainv <- coef(fit_julia_Ainv, dpar = site_key)

  oracle_tmb <- binomial_animal_iid_laplace_oracle(
    sim$data, A, coef(fit_tmb, dpar = "mu"), animal_tmb, site_tmb
  )
  oracle_julia <- binomial_animal_iid_laplace_oracle(
    sim$data, A, coef(fit_julia, dpar = "mu"), animal_julia, site_julia
  )

  expect_equal(fit_tmb$opt$convergence, 0L)
  expect_equal(fit_tmb_Ainv$opt$convergence, 0L)
  expect_true(all(is.finite(c(animal_julia, site_julia,
                              animal_julia_Ainv, site_julia_Ainv,
                              as.numeric(logLik(fit_julia))))))
  expect_named(animal_julia, names(animal_tmb))
  expect_named(site_julia, names(site_tmb))
  expect_named(animal_julia_Ainv, names(animal_tmb_Ainv))
  expect_named(site_julia_Ainv, names(site_tmb_Ainv))
  expect_equal(unname(animal_julia), unname(animal_tmb), tolerance = 0.05)
  expect_equal(unname(site_julia), unname(site_tmb), tolerance = 0.05)
  expect_equal(unname(animal_julia_Ainv), unname(animal_tmb_Ainv),
               tolerance = 0.05)
  expect_equal(unname(site_julia_Ainv), unname(site_tmb_Ainv),
               tolerance = 0.05)
  expect_equal(as.numeric(logLik(fit_julia)), as.numeric(logLik(fit_tmb)),
               tolerance = 0.02)
  expect_equal(as.numeric(logLik(fit_julia_Ainv)),
               as.numeric(logLik(fit_tmb_Ainv)), tolerance = 0.02)
  expect_equal(as.numeric(logLik(fit_tmb)), oracle_tmb, tolerance = 2e-4)
  expect_equal(as.numeric(logLik(fit_julia)), oracle_julia, tolerance = 2e-4)
  expect_equal(unname(animal_julia_Ainv), unname(animal_julia),
               tolerance = 0.02)
  expect_equal(unname(site_julia_Ainv), unname(site_julia), tolerance = 0.02)
  expect_equal(as.numeric(logLik(fit_julia_Ainv)),
               as.numeric(logLik(fit_julia)), tolerance = 0.02)
  expect_equal(
    unname(predict(fit_julia, dpar = animal_key)),
    unname(predict(fit_tmb, dpar = animal_key)),
    tolerance = 0.02
  )
  expect_equal(
    unname(predict(fit_julia_Ainv, dpar = animal_key)),
    unname(predict(fit_tmb_Ainv, dpar = animal_key)),
    tolerance = 0.02
  )
  expect_equal(
    unname(predict(fit_julia, dpar = site_key)),
    unname(predict(fit_tmb, dpar = site_key)),
    tolerance = 0.02
  )
  expect_equal(
    unname(predict(fit_julia_Ainv, dpar = site_key)),
    unname(predict(fit_tmb_Ainv, dpar = site_key)),
    tolerance = 0.02
  )

  simulation_spec <- drm_julia_binomial_sd_simulation_spec(fit_julia_Ainv)
  expect_equal(simulation_spec$components[[1L]]$covariance, A,
               tolerance = 1e-10)
  expect_identical(
    vapply(simulation_spec$components, `[[`, character(1L), "group"),
    c("animal_id", "site")
  )
  expect_true(isTRUE(simulation_spec$components[[1L]]$structured))
  expect_false(isTRUE(simulation_spec$components[[2L]]$structured))

  draws_A <- simulate(fit_julia, nsim = 1L, seed = 20261024L)
  draws_Ainv <- simulate(fit_julia_Ainv, nsim = 1L, seed = 20261024L)
  for (draws in list(draws_A, draws_Ainv)) {
    expect_named(draws, "sim_1")
    expect_equal(nrow(draws), nrow(sim$data))
    expect_true(all(draws$sim_1 %in% c(0L, 1L)))
  }
  expect_equal(
    draws_A,
    simulate(fit_julia, nsim = 1L, seed = 20261024L)
  )
  expect_equal(
    draws_Ainv,
    simulate(fit_julia_Ainv, nsim = 1L, seed = 20261024L)
  )
})

test_that("Binomial animal plus IID bridge gate rejects wider structures", {
  sim <- binomial_animal_iid_sd_parity_data()
  A <- sim$A
  ordinary_slope <- bf(
    y ~ x + animal(1 | animal_id, A = A) + (0 + x | site),
    sd(animal_id, level = "animal") ~ z,
    sd(site) ~ w
  )
  extra_iid <- bf(
    y ~ x + animal(1 | animal_id, A = A) + (1 | site) + (1 | extra),
    sd(animal_id, level = "animal") ~ z,
    sd(site) ~ w
  )
  varying_sigma <- bf(
    y ~ x + animal(1 | animal_id, A = A) + (1 | site),
    sd(animal_id, level = "animal") ~ z,
    sd(site) ~ w,
    sigma ~ w
  )

  expect_false(drm_julia_binomial_animal_iid_sd_route_admitted(ordinary_slope))
  expect_false(drm_julia_binomial_animal_iid_sd_route_admitted(extra_iid))
  expect_false(drm_julia_binomial_animal_iid_sd_route_admitted(varying_sigma))
})
