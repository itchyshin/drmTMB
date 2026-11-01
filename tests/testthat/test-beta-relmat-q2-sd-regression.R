# Independent fields b_k = diag(exp(Z_k alpha_k)) u_k, u_k ~ N(0,K).
# Beta mean = eps + (1-2*eps)*plogis(X beta+b0+x*b1), phi=sigma^-2.
beta_relmat_q2_sd_fixture <- function(groups = 64L, repeats = 20L) {
  set.seed(2026102709L)
  ids <- sprintf("group%03d", seq_len(groups))
  diagonal <- seq(0.8, 1.3, length.out = groups)
  K <- 0.25^abs(outer(seq_len(groups), seq_len(groups), "-")) *
    outer(sqrt(diagonal), sqrt(diagonal))
  dimnames(K) <- list(ids, ids)
  z0 <- stats::setNames(rep(c(-1, 1), groups / 2L), ids)
  z1 <- stats::setNames(rep(c(-1, 1), each = groups / 2L), ids)
  truth <- list(a0 = c(log(0.5), z0 = 0.5), a1 = c(log(0.4), z1 = -0.5))
  b0 <- exp(truth$a0[1L] + truth$a0[2L] * z0) *
    drop(t(chol(K)) %*% stats::rnorm(groups))
  b1 <- exp(truth$a1[1L] + truth$a1[2L] * z1) *
    drop(t(chol(K)) %*% stats::rnorm(groups))
  ii <- rep(seq_len(groups), each = repeats)
  x <- rep(seq(-1.2, 1.2, length.out = repeats), groups)
  mu <- 1e-12 + (1 - 2e-12) * stats::plogis(0.2 + 0.3 * x + b0[ii] + x * b1[ii])
  phi <- 0.35^-2
  dat <- data.frame(y = stats::rbeta(length(ii), mu * phi, (1 - mu) * phi),
    x = x, id = factor(ids[ii], levels = rev(ids)),
    z0 = unname(z0[ii]), z1 = unname(z1[ii]))
  stopifnot(all(dat$y > 0 & dat$y < 1), min(mu * phi, (1 - mu) * phi) > 1e-8)
  order <- c(seq(2L, groups, 2L), seq(1L, groups, 2L))
  list(data = dat, K = K[order, order], truth = truth, z0 = z0, z1 = z1)
}

beta_relmat_q2_sd_form <- function(K, Q = NULL, constant = FALSE, reverse_sd = FALSE) {
  f0 <- stats::as.formula(paste(
    'sd(id, level = "relmat", coef = "(Intercept)") ~',
    if (constant) "1" else "z0"), env = environment())
  f1 <- stats::as.formula(paste(
    'sd(id, level = "relmat", coef = "x") ~',
    if (constant) "1" else "z1"), env = environment())
  mu <- if (is.null(Q)) y ~ x + relmat(1 + x | id, K = K) else
    y ~ x + relmat(1 + x | id, Q = Q)
  environment(mu) <- environment()
  if (reverse_sd) bf(mu, sigma ~ 1, f1, f0) else bf(mu, sigma ~ 1, f0, f1)
}

beta_relmat_q2_sd_oracle <- function(fit, fx) {
  d <- fx$data; ids <- rownames(fx$K); n <- length(ids)
  P <- kronecker(diag(2L), solve(fx$K))
  ii <- match(as.character(d$id), ids)
  keys <- c('sd_relmat(id, dpar = "mu", coef = "(Intercept)")',
            'sd_relmat(id, dpar = "mu", coef = "x")')
  a0 <- coef(fit, keys[1L]); a1 <- coef(fit, keys[2L])
  scale0 <- exp(a0[1L] + a0[2L] * fx$z0[ids])
  scale1 <- exp(a1[1L] + a1[2L] * fx$z1[ids])
  B <- matrix(0, nrow(d), 2L * n)
  B[cbind(seq_len(nrow(d)), ii)] <- scale0[ii]
  B[cbind(seq_len(nrow(d)), n + ii)] <- d$x * scale1[ii]
  fixed <- drop(stats::model.matrix(~ x, d) %*% coef(fit, "mu"))
  phi <- exp(-2 * coef(fit, "sigma")[[1L]])
  moments <- function(u) {
    eta <- fixed + drop(B %*% u)
    p <- stats::plogis(eta)
    mu <- 1e-12 + (1 - 2e-12) * p
    alpha <- phi * mu; beta <- phi * (1 - mu)
    if (min(alpha, beta) <= 1e-8) stop("Oracle fixture reached a shape floor.")
    first <- (1 - 2e-12) * p * (1 - p)
    second <- first * (1 - 2 * p)
    t <- log(d$y) - log1p(-d$y) - digamma(alpha) + digamma(beta)
    list(eta = eta, alpha = alpha, beta = beta,
      score = -phi * t * first,
      curvature = phi^2 * (trigamma(alpha) + trigamma(beta)) * first^2 -
        phi * t * second)
  }
  joint <- function(u) {
    z <- moments(u)
    -sum(stats::dbeta(d$y, z$alpha, z$beta, log = TRUE)) +
      drop(crossprod(u, P %*% u)) / 2 + n * log(2 * pi) +
      as.numeric(determinant(fx$K, logarithm = TRUE)$modulus)
  }
  gradient <- function(u) drop(P %*% u + crossprod(B, moments(u)$score))
  hessian <- function(u) P + crossprod(B, moments(u)$curvature * B)
  starts <- list(rep(0, 2L * n), rep(c(-0.05, 0.05), length.out = 2L * n))
  modes <- lapply(starts, function(start) stats::nlminb(start, joint, gradient,
    hessian, control = list(iter.max = 150L, eval.max = 300L, rel.tol = 1e-13)))
  objectives <- vapply(modes, `[[`, numeric(1L), "objective")
  mode <- modes[[which.min(objectives)]]
  H <- hessian(mode$par)
  chol(H)
  # Check the analytic score away from the optimum, where it is not nearly zero.
  probe <- starts[[2L]]; step <- 1e-5
  cols <- unique(c(1L, n, n + 1L, 2L * n))
  fd <- vapply(cols, function(j) {
    delta <- numeric(2L * n); delta[j] <- step
    (joint(probe + delta) - joint(probe - delta)) / (2 * step)
  }, numeric(1L))
  fd_hessian <- vapply(cols, function(j) {
    delta <- numeric(2L * n); delta[j] <- step
    (gradient(probe + delta) - gradient(probe - delta)) / (2 * step)
  }, numeric(2L * n))
  list(nll = joint(mode$par) +
      as.numeric(determinant(H, logarithm = TRUE)$modulus) / 2 - n * log(2 * pi),
    eta = moments(mode$par)$eta,
    gradient = max(vapply(modes, function(m) max(abs(gradient(m$par))), numeric(1L))),
    mode_difference = diff(range(objectives)),
    derivative_error = max(abs(fd - gradient(probe)[cols])),
    hessian_error = max(abs(fd_hessian - hessian(probe)[, cols, drop = FALSE])))
}

test_that("Beta relmat intercept-slope SDs map both coefficient targets", {
  fx <- beta_relmat_q2_sd_fixture(groups = 12L, repeats = 8L); K <- fx$K
  spec <- drmTMB:::drm_build_beta_ls_spec(beta_relmat_q2_sd_form(K), fx$data)
  expect_identical(spec$tmb_data$has_sd_phylo_coef_model, 1L)
  expect_equal(ncol(spec$tmb_data$phylo_mu_sd_row_coef), 2L)
  expect_true(all(spec$tmb_data$phylo_mu_sd_row_coef >= 0L))
  expect_true(all(spec$tmb_data$phylo_mu_sd_row_coef[, 1L] !=
                  spec$tmb_data$phylo_mu_sd_row_coef[, 2L]))
  expect_length(spec$random_scale$phylo$dpars, 2L)
  expect_error(drmTMB:::drm_build_beta_ls_spec(
    bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1,
       sd(id, level = "relmat") ~ z0), fx$data), "select a coefficient")
  expect_error(drmTMB:::drm_build_beta_ls_spec(
    bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1,
       sd(id, level = "relmat", coef = "x") ~ z1), fx$data),
    "one SD formula for each coefficient")
  expect_error(drmTMB:::drm_build_beta_ls_spec(
    bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1,
       sd(id, level = "relmat", coef = "bad") ~ z0,
       sd(id, level = "relmat", coef = "x") ~ z1), fx$data), "coefficient")
  expect_error(drmTMB:::drm_build_beta_ls_spec(
    bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1,
       sd(id, level = "relmat", coef = "(Intercept)") ~ z0,
       sd(id, level = "relmat", coef = "(Intercept)") ~ z1), fx$data),
    "one SD formula for each coefficient")
  expect_error(drmTMB:::drm_build_beta_ls_spec(
    bf(y ~ x + relmat(1 + x | p | id, K = K), sigma ~ 1,
       sd(id, level = "relmat", coef = "(Intercept)") ~ z0,
       sd(id, level = "relmat", coef = "x") ~ z1), fx$data), "unlabelled")
  expect_error(drmTMB:::drm_build_beta_ls_spec(beta_relmat_q2_sd_form(K),
    fx$data, missing = miss_control(response = "include")),
    "complete responses|not implemented with missing-data routes")
  Q <- solve(K)
  precision_spec <- drmTMB:::drm_build_beta_ls_spec(
    beta_relmat_q2_sd_form(K, Q = Q), fx$data)
  expect_equal(as.matrix(precision_spec$structured$phylo_mu$precision$precision),
    as.matrix(spec$structured$phylo_mu$precision$precision), tolerance = 1e-10)
  expect_equal(precision_spec$structured$phylo_mu$precision$log_det_precision,
    spec$structured$phylo_mu$precision$log_det_precision, tolerance = 1e-10)
  expect_error(drmTMB:::drm_build_beta_ls_spec(
    bf(y ~ x + relmat(0 + x | id, K = K), sigma ~ 1), fx$data), "intercept.*slope")
  expect_error(drmTMB:::drm_build_beta_ls_spec(
    bf(y ~ x + relmat(1 + x | id, K = K) + animal(1 | id, A = K), sigma ~ 1),
    fx$data), "only one structured")
  expect_error(drmTMB:::drm_build_beta_ls_spec(
    bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1 + (1 | id)),
    fx$data), "sigma.*random effects are not implemented")
  expect_error(drmTMB:::drm_build_beta_ls_spec(
    bf(y ~ x + relmat(1 + x + z0 | id, K = K), sigma ~ 1), fx$data),
    "intercept.*slope")
  expect_error(drmTMB:::drm_build_beta_ls_spec(
    bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ animal(1 | id, A = K)),
    fx$data), "one endpoint")
  expect_error(drmTMB:::drm_build_beta_ls_spec(
    bf(y ~ x, sigma ~ relmat(1 + x | id, K = K)), fx$data),
    "not implemented|unsupported|Unsupported")
  expect_error(drmTMB:::drm_build_beta_ls_spec(
    bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1), fx$data,
    missing = miss_control(response = "include")), "complete responses")
  bad <- fx$data; bad$z0[1L] <- bad$z0[1L] + 0.1
  expect_error(drmTMB:::drm_build_beta_ls_spec(beta_relmat_q2_sd_form(K), bad),
    "constant within")
  bad <- fx$data; bad$x <- 0
  expect_error(drmTMB:::drm_build_beta_ls_spec(beta_relmat_q2_sd_form(K), bad),
    "unidentified slope scale")
  bad$x <- 1
  expect_error(drmTMB:::drm_build_beta_ls_spec(
    beta_relmat_q2_sd_form(K, constant = TRUE), bad), "not separately identifiable")
  bad <- fx$data; bad$other <- factor(rep(seq_len(8L), length.out = nrow(bad)))
  expect_error(drmTMB:::drm_build_beta_ls_spec(
    bf(y ~ x + relmat(1 + x | id, K = K) + (1 | other), sigma ~ 1,
       sd(id, level = "relmat", coef = "(Intercept)") ~ z0,
       sd(id, level = "relmat", coef = "x") ~ z1), bad), "no other random")
})

test_that("Beta relmat coefficient SD extraction preserves latent values", {
  fx <- beta_relmat_q2_sd_fixture(groups = 12L, repeats = 8L); K <- fx$K
  absent <- rownames(K)[1L]
  dat <- fx$data[as.character(fx$data$id) != absent, , drop = FALSE]
  spec <- drmTMB:::drm_build_beta_ls_spec(beta_relmat_q2_sd_form(K), dat)
  n <- spec$structured$phylo_mu$n_re; nodes <- spec$structured$phylo_mu$node_labels
  par <- spec$start; par$u_phylo <- seq_len(2L * n) / n
  par$beta_sd_mu <- c(log(0.5), 0.5, log(0.4), -0.5)
  re <- drmTMB:::split_tmb_random_effects(par, spec)$relmat_mu
  expect_equal(unname(re$latent), par$u_phylo)
  seen <- setdiff(nodes, absent)
  expect_equal(unname(re$terms[[1L]][seen]),
    unname(par$u_phylo[match(seen, nodes)] * exp(log(0.5) + 0.5 * fx$z0[seen])))
  expect_equal(unname(re$terms[[2L]][seen]),
    unname(par$u_phylo[n + match(seen, nodes)] * exp(log(0.4) - 0.5 * fx$z1[seen])))
  expect_true(is.na(re$terms[[1L]][absent]))
  expect_true(is.na(re$terms[[2L]][absent]))
})

test_that("Beta relmat coefficient SD fit matches independent Laplace calculations", {
  skip_on_cran()
  fx <- beta_relmat_q2_sd_fixture(); K <- fx$K
  fit <- drmTMB(beta_relmat_q2_sd_form(K), family = beta_family(),
    data = fx$data, control = drm_control(se = FALSE))
  expect_equal(fit$opt$convergence, 0L)
  keys <- c('sd_relmat(id, dpar = "mu", coef = "(Intercept)")',
            'sd_relmat(id, dpar = "mu", coef = "x")')
  expect_lt(abs(coef(fit, keys[1L])[["z0"]] - 0.5), 0.4)
  expect_lt(abs(coef(fit, keys[2L])[["z1"]] + 0.5), 0.4)
  for (k in seq_along(keys)) {
    a <- coef(fit, keys[k]); z <- if (k == 1L) fx$z0 else fx$z1
    predicted <- predict(fit, dpar = keys[k])
    expect_setequal(names(predicted), levels(fx$data$id))
    expect_equal(unname(predicted), unname(exp(a[1L] + a[2L] * z[names(predicted)])),
      tolerance = 1e-10)
  }
  table <- predict_parameters(fit, dpar = keys, conf.int = FALSE)
  expect_setequal(unique(table$dpar), keys)
  expect_equal(nrow(table), 2L * nrow(K))
  report <- fit$obj$report(fit$tmb_state$last.par.best)
  expect_lt(max(abs(as.numeric(fitted(fit)) - as.numeric(report$mu))), 1e-8)
  expect_lt(max(abs(as.numeric(predict(fit, type = "link", re.form = NULL)) -
                      as.numeric(report$eta_mu))), 1e-7)
  oracle <- beta_relmat_q2_sd_oracle(fit, fx)
  expect_lt(oracle$gradient, 1e-5)
  expect_lt(oracle$mode_difference, 1e-6)
  expect_lt(oracle$derivative_error, 1e-4)
  expect_lt(oracle$hessian_error, 2e-4)
  expect_lt(abs(as.numeric(-logLik(fit)) - oracle$nll), 1e-4)
  expect_lt(max(abs(as.numeric(report$eta_mu) - oracle$eta)), 1e-4)
  reverse_fit <- drmTMB(beta_relmat_q2_sd_form(K, reverse_sd = TRUE),
    family = beta_family(), data = fx$data, control = drm_control(se = FALSE))
  expect_equal(reverse_fit$opt$convergence, 0L)
  expect_lt(abs(as.numeric(logLik(reverse_fit)) - as.numeric(logLik(fit))), 1e-4)
  for (key in keys) expect_lt(max(abs(coef(reverse_fit, key) - coef(fit, key))), 1e-4)
  # Invert the full supplied matrix, then permute precision labels independently.
  Q <- solve(K); reverse_ids <- rev(rownames(Q))
  Q <- Q[reverse_ids, reverse_ids]
  precision_fit <- drmTMB(beta_relmat_q2_sd_form(K, Q = Q),
    family = beta_family(), data = fx$data, control = drm_control(se = FALSE))
  expect_equal(precision_fit$opt$convergence, 0L)
  expect_lt(abs(as.numeric(logLik(precision_fit)) - as.numeric(logLik(fit))), 1e-4)
  for (key in keys) {
    expect_lt(max(abs(coef(precision_fit, key) - coef(fit, key))), 1e-4)
    expected_sd <- predict(fit, dpar = key)
    precision_sd <- predict(precision_fit, dpar = key)[names(expected_sd)]
    expect_lt(max(abs(precision_sd - expected_sd)), 1e-4)
  }
  expect_lt(max(abs(as.numeric(predict(precision_fit, type = "link", re.form = NULL)) -
                    as.numeric(report$eta_mu))), 1e-4)
  constant_fit <- drmTMB(beta_relmat_q2_sd_form(K, constant = TRUE),
    family = beta_family(), data = fx$data, control = drm_control(se = FALSE))
  base_fit <- drmTMB(bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1),
    family = beta_family(), data = fx$data, control = drm_control(se = FALSE))
  expect_equal(constant_fit$opt$convergence, 0L)
  expect_equal(base_fit$opt$convergence, 0L)
  expect_lt(abs(as.numeric(logLik(constant_fit)) - as.numeric(logLik(base_fit))), 1e-4)
  saved <- tempfile(fileext = ".rds"); on.exit(unlink(saved), add = TRUE)
  saveRDS(fit, saved); reloaded <- readRDS(saved)
  expect_equal(predict(reloaded, dpar = keys[1L]), predict(fit, dpar = keys[1L]))
  expect_equal(predict(reloaded, type = "link", re.form = NULL),
    predict(fit, type = "link", re.form = NULL))
  simulated <- simulate(fit, nsim = 1L, seed = 2026102710L, re.form = NULL)$sim_1
  set.seed(2026102710L)
  phi <- exp(-2 * coef(fit, "sigma")[[1L]])
  expected <- stats::rbeta(nrow(fx$data), report$mu * phi, (1 - report$mu) * phi)
  expect_equal(simulated, expected, tolerance = 1e-8)
  expect_error(simulate(fit, nsim = 1L, re.form = NA),
    "Marginal simulation.*does not yet support")
})
