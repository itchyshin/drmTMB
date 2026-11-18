# Independent-oracle companion to
# test-julia-binomial-animal-iid-nonlogit-sd-bridge.R, which compares Julia
# with TMB only. Same fixture (seeds and construction copied), live Julia fits
# for probit and cloglog, and a base-R dense joint-Newton Laplace oracle with
# hand-derived observed second derivatives of the Bernoulli link likelihood
# (checked below against central differences and dbinom). Asserts the Julia
# logLik agrees with the oracle at the Julia estimates to 1e-3 absolute and
# that each emulated bug moves the oracle by more than 20 times that.
# Claim scope: one fixture per link; no calibration, coverage or broad parity.

binomial_nonlogit_b29_data <- function(link) {
  n_animal <- 36L
  n_site <- 30L
  repeats <- 6L
  animal_index <- rep(seq_len(n_animal), each = n_site * repeats)
  site_index <- rep(rep(seq_len(n_site), each = repeats), times = n_animal)
  set.seed(202610300L)
  animal_levels <- paste0("animal_", seq_len(n_animal))
  site_levels <- paste0("site_", seq_len(n_site))
  z_levels <- sample(rep(c(-1, 1), each = n_animal / 2L))
  w_levels <- sample(rep(c(-1, 1), each = n_site / 2L))
  z <- z_levels[animal_index]
  w <- w_levels[site_index]
  x <- stats::rnorm(length(animal_index))
  A <- outer(seq_len(n_animal), seq_len(n_animal),
             function(i, j) 0.45^abs(i - j))
  dimnames(A) <- list(animal_levels, animal_levels)
  animal_alpha <- c(`(Intercept)` = -0.75, z = 0.5)
  site_alpha <- c(`(Intercept)` = -0.35, w = -0.5)
  animal_sd <- exp(animal_alpha[[1L]] + animal_alpha[[2L]] * z_levels)
  site_sd <- exp(site_alpha[[1L]] + site_alpha[[2L]] * w_levels)
  animal_cov <- tcrossprod(animal_sd) * A
  animal_effect <- drop(t(chol(animal_cov)) %*% stats::rnorm(n_animal))
  site_effect <- site_sd * stats::rnorm(n_site)
  eta <- -0.2 + 0.3 * x + animal_effect[animal_index] + site_effect[site_index]
  data <- data.frame(
    x = x, z = z, w = w,
    animal_id = factor(animal_levels[animal_index], levels = animal_levels),
    site = factor(site_levels[site_index], levels = site_levels)
  )
  set.seed(if (link == "probit") 202610301L else 202610302L)
  data$y <- stats::rbinom(nrow(data), size = 1L,
                          prob = stats::binomial(link = link)$linkinv(eta))
  list(data = data, A = A)
}

# Per-observation negative log-likelihood f(eta; y) with first and second
# derivatives in eta, written by hand for each link.
binomial_link_terms <- function(link, eta, y) {
  if (identical(link, "probit")) {
    sgn <- ifelse(y == 1, 1, -1)
    q <- sgn * eta
    lam <- exp(stats::dnorm(q, log = TRUE) - stats::pnorm(q, log.p = TRUE))
    list(f = -stats::pnorm(q, log.p = TRUE),
         d1 = -sgn * lam,
         d2 = lam * (lam + q))
  } else if (identical(link, "cloglog")) {
    t <- exp(eta)
    f1 <- -log(-expm1(-t))
    d1_1 <- -t / expm1(t)
    d2_1 <- t * (t * exp(t) - expm1(t)) / expm1(t)^2
    one <- y == 1
    list(f = ifelse(one, f1, t),
         d1 = ifelse(one, d1_1, t),
         d2 = ifelse(one, d2_1, t))
  } else {
    stop("unsupported link", call. = FALSE)
  }
}

binomial_nonlogit_b29_oracle <- function(data, A, beta, animal_alpha,
                                         site_alpha, link) {
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
  eta_fixed <- drop(stats::model.matrix(~ x, data = data) %*% beta)
  y <- data$y

  joint_nll <- function(u) {
    eta <- eta_fixed + drop(M %*% u)
    0.5 * sum(u * drop(Q %*% u)) + sum(binomial_link_terms(link, eta, y)$f)
  }
  u <- numeric(n_animal + n_site)
  converged <- FALSE
  for (iteration in seq_len(200L)) {
    tm <- binomial_link_terms(link, eta_fixed + drop(M %*% u), y)
    gradient <- drop(Q %*% u) + drop(crossprod(M, tm$d1))
    hessian <- Q + crossprod(M, M * tm$d2)
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
      # Roundoff can stall the line search once the Newton step is tiny; the
      # Laplace value is stationary in u, so the error is of order 1e-12.
      if (max(abs(step)) < 1e-6) {
        converged <- TRUE
        break
      }
      stop("oracle mode did not converge", call. = FALSE)
    }
  }
  if (!converged) stop("oracle mode exceeded iteration limit", call. = FALSE)
  tm <- binomial_link_terms(link, eta_fixed + drop(M %*% u), y)
  hessian <- Q + crossprod(M, M * tm$d2)
  logdet_q <- as.numeric(determinant(Q, logarithm = TRUE)$modulus)
  -joint_nll(u) + 0.5 * logdet_q - sum(log(diag(chol(hessian))))
}

test_that("hand-derived probit and cloglog terms match dbinom and central differences", {
  eta <- c(-3, -1, -0.2, 0.4, 1.5)
  for (link in c("probit", "cloglog")) {
    p <- stats::binomial(link = link)$linkinv(eta)
    for (y in 0:1) {
      yy <- rep(y, length(eta))
      tm <- binomial_link_terms(link, eta, yy)
      expect_equal(tm$f, -stats::dbinom(yy, 1, p, log = TRUE),
                   tolerance = 1e-10)
      h <- 1e-5
      f_plus <- binomial_link_terms(link, eta + h, yy)
      f_minus <- binomial_link_terms(link, eta - h, yy)
      expect_equal(tm$d1, (f_plus$f - f_minus$f) / (2 * h), tolerance = 1e-6)
      expect_equal(tm$d2, (f_plus$d1 - f_minus$d1) / (2 * h), tolerance = 1e-6)
    }
  }
})

test_that("Julia Binomial probit and cloglog animal plus IID logLik matches a dense Laplace oracle tightly and every emulated bug moves it far", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path),
          "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  agreement_tol <- 1e-3
  gap_min <- 20 * agreement_tol
  animal_key <- "sd_animal(animal_id)"
  site_key <- "sd(site)"

  for (link in c("probit", "cloglog")) {
    sim <- binomial_nonlogit_b29_data(link)
    data <- sim$data
    A <- sim$A
    fit <- drmTMB(
      bf(y ~ x + animal(1 | animal_id, A = A) + (1 | site),
         sd(animal_id, level = "animal") ~ z, sd(site) ~ w),
      family = stats::binomial(link), data = data, engine = "julia"
    )
    beta <- coef(fit, dpar = "mu")
    alpha_animal <- coef(fit, dpar = animal_key)
    alpha_site <- coef(fit, dpar = site_key)
    ll <- as.numeric(logLik(fit))
    other <- setdiff(c("probit", "cloglog"), link)
    oracle <- function(d = data, K = A, b = beta, aa = alpha_animal,
                       ss = alpha_site, lk = link) {
      binomial_nonlogit_b29_oracle(d, K, b, aa, ss, lk)
    }
    base <- oracle()
    info <- paste(link, "Julia fit")
    expect_lt(abs(ll - base), agreement_tol, label = paste(info, "agreement"))

    flip_slope <- function(v) c(v[[1L]], -v[[2L]])
    # z and w are per-group values; reverse them across group positions.
    animal_pos <- as.integer(sub("animal_", "", data$animal_id))
    site_pos <- as.integer(sub("site_", "", data$site))
    z_by_animal <- data$z[match(rownames(A), as.character(data$animal_id))]
    w_by_site <- data$w[match(levels(data$site), as.character(data$site))]
    d_rev_animal <- data
    d_rev_animal$z <- rev(z_by_animal)[animal_pos]
    d_rev_site <- data
    d_rev_site$w <- rev(w_by_site)[site_pos]
    # A has unit diagonal and is Toeplitz here, so cov2cor(A) and reversed
    # dimnames are no-ops; use a genuinely wrong kernel instead.
    A_wrong_decay <- outer(seq_len(nrow(A)), seq_len(nrow(A)),
                           function(i, j) 0.3^abs(i - j))
    dimnames(A_wrong_decay) <- dimnames(A)
    gaps <- c(
      selector_swap = oracle(aa = alpha_site, ss = alpha_animal),
      animal_slope_sign = oracle(aa = flip_slope(alpha_animal)),
      site_slope_sign = oracle(ss = flip_slope(alpha_site)),
      reversed_animal_sd_vector = oracle(d = d_rev_animal),
      reversed_site_sd_vector = oracle(d = d_rev_site),
      A_scale_2 = oracle(K = 2 * A),
      A_scale_1.1 = oracle(K = 1.1 * A),
      A_wrong_decay = oracle(K = A_wrong_decay),
      wrong_link = oracle(lk = other)
    ) - base
    for (nm in names(gaps)) {
      expect_gt(abs(gaps[[nm]]), gap_min,
                label = paste(info, nm, "oracle gap"))
    }
    message(sprintf("b29 %s: ll=%.6f oracle=%.6f agreement=%.2e rel=%.2e; gaps: %s",
                    link, ll, base, abs(ll - base), abs(ll - base) / abs(ll),
                    paste(sprintf("%s=%.4f", names(gaps), gaps), collapse = ", ")))
  }
})
