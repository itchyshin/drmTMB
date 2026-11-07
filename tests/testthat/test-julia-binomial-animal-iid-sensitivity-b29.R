# Sensitivity companion to test-julia-binomial-animal-iid-sd-parity.R
# (evidence id binomial-animal-iid-julia-independent-laplace-20261024-m26).
#
# The parity test compares Julia with a base-R dense Laplace oracle at
# tolerance 2e-4 relative (about 0.5 absolute on a log-likelihood near -2563),
# which only the selector swap exceeds. This file keeps the same fixture and
# oracle but (i) asserts agreement of the live Julia logLik with the oracle
# evaluated at the Julia estimates to 1e-3 absolute (about 4e-7 relative), and
# (ii) shows that each emulated bug moves the oracle by more than 20 times
# that tolerance. The oracle uses no drmTMB code: dense joint Newton mode,
# Laplace logLik, hand-built A and design matrices.
# Claim scope: Julia and the independent oracle agree on this one fixture;
# no calibration, coverage or broad parity claim.


binomial_animal_iid_b29_data <- function(seed = 20261024L) {
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

binomial_animal_iid_b29_oracle <- function(data, A, beta,
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
      # Roundoff in the joint objective can stall the line search once the
      # Newton step is already tiny; the Laplace value is stationary in u,
      # so a step below 1e-6 leaves an error of order 1e-12.
      if (max(abs(step)) < 1e-6) {
        converged <- TRUE
        break
      }
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

test_that("Julia Binomial animal plus IID logLik matches a dense Laplace oracle tightly and every emulated bug moves it far", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path),
          "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  agreement_tol <- 1e-3  # absolute, logLik about -2563; achieved ~4e-5
  gap_min <- 20 * agreement_tol

  sim <- binomial_animal_iid_b29_data()
  data <- sim$data
  A <- sim$A
  Ainv <- solve(A)
  animal_key <- "sd_animal(animal_id)"
  site_key <- "sd(site)"

  fit_A <- drmTMB(
    bf(y ~ x + animal(1 | animal_id, A = A) + (1 | site),
       sd(animal_id, level = "animal") ~ z, sd(site) ~ w),
    family = stats::binomial(), data = data, engine = "julia"
  )
  fit_Ainv <- drmTMB(
    bf(y ~ x + animal(1 | animal_id, Ainv = Ainv) + (1 | site),
       sd(animal_id, level = "animal") ~ z, sd(site) ~ w),
    family = stats::binomial(), data = data, engine = "julia"
  )

  for (case in list(list(name = "A", fit = fit_A),
                    list(name = "Ainv", fit = fit_Ainv))) {
    fit <- case$fit
    beta <- coef(fit, dpar = "mu")
    alpha_animal <- coef(fit, dpar = animal_key)
    alpha_site <- coef(fit, dpar = site_key)
    ll <- as.numeric(logLik(fit))
    oracle <- function(d = data, K = A, b = beta, aa = alpha_animal,
                       ss = alpha_site) {
      binomial_animal_iid_b29_oracle(d, K, b, aa, ss)
    }
    base <- oracle()
    info <- paste("Julia fit via", case$name)

    # Tight agreement at the Julia estimates.
    expect_lt(abs(ll - base), agreement_tol, label = paste(info, "agreement"))

    # Emulated bugs: each must move the oracle far beyond the tolerance.
    flip_slope <- function(v) c(v[[1L]], -v[[2L]])
    d_rev_animal <- data
    animal_pos <- as.integer(sub("animal_", "", data$animal_id))
    d_rev_animal$z <- rev(seq(-1, 1, length.out = nlevels(data$animal_id)))[
      animal_pos]
    d_rev_site <- data
    site_pos <- as.integer(sub("site_", "", data$site))
    d_rev_site$w <- rev(seq(-1, 1, length.out = nlevels(data$site)))[site_pos]
    A_misaligned <- A
    dimnames(A_misaligned) <- list(rev(rownames(A)), rev(colnames(A)))
    gaps <- c(
      selector_swap = oracle(aa = alpha_site, ss = alpha_animal),
      animal_slope_sign = oracle(aa = flip_slope(alpha_animal)),
      site_slope_sign = oracle(ss = flip_slope(alpha_site)),
      reversed_animal_sd_vector = oracle(d = d_rev_animal),
      reversed_site_sd_vector = oracle(d = d_rev_site),
      A_scale_2 = oracle(K = 2 * A),
      A_scale_1.1 = oracle(K = 1.1 * A),
      cov2cor_A = oracle(K = stats::cov2cor(A)),
      A_dimnames_reversed = oracle(K = A_misaligned)
    ) - base
    for (nm in names(gaps)) {
      expect_gt(abs(gaps[[nm]]), gap_min,
                label = paste(info, nm, "oracle gap"))
    }
    expect_gt(min(abs(gaps)) / agreement_tol, 20)

    # Julia estimates sit at the maximum of the independent Laplace
    # likelihood: shifting any coefficient lowers it.
    if (identical(case$name, "A")) {
      for (k in 1:2) {
        for (sgn in c(-0.1, 0.1)) {
          b2 <- beta; b2[[k]] <- b2[[k]] + sgn
          a2 <- alpha_animal; a2[[k]] <- a2[[k]] + sgn
          s2 <- alpha_site; s2[[k]] <- s2[[k]] + sgn
          expect_lt(oracle(b = b2), base + agreement_tol)
          expect_lt(oracle(aa = a2), base + agreement_tol)
          expect_lt(oracle(ss = s2), base + agreement_tol)
        }
      }
    }
    message(sprintf("b29 %s: ll=%.6f oracle=%.6f agreement=%.2e rel=%.2e; gaps: %s",
                    case$name, ll, base, abs(ll - base), abs(ll - base) / abs(ll),
                    paste(sprintf("%s=%.4f", names(gaps), gaps), collapse = ", ")))
  }
  expect_equal(as.numeric(logLik(fit_Ainv)), as.numeric(logLik(fit_A)),
               tolerance = 1e-4)
})
