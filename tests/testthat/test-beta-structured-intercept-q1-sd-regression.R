# Native Beta q1 SD regression on independent structured intercepts.
beta_structured_q1_fixture <- function(provider = c("relmat", "spatial"), seed) {
  provider <- match.arg(provider)
  set.seed(seed)
  groups <- 64L
  ids <- sprintf("site%03d", seq_len(groups))
  diagonal <- seq(0.8, 1.3, length.out = groups)
  if (provider == "relmat") {
    K <- 0.25^abs(outer(seq_len(groups), seq_len(groups), "-")) *
      outer(sqrt(diagonal), sqrt(diagonal))
    coords <- NULL
  } else {
    coords <- cbind(x = rep(seq_len(8L), each = 8L), y = rep(seq_len(8L), 8L))
    rownames(coords) <- ids
    distance <- as.matrix(stats::dist(coords))
    range <- stats::median(distance[upper.tri(distance) & distance > 0])
    K <- exp(-distance / range) + diag(1e-6, groups)
  }
  dimnames(K) <- list(ids, ids)
  Q <- solve(K)
  z <- stats::setNames(rep(c(-1, 1), each = groups / 2L), ids)
  u <- stats::setNames(drop(t(chol(K)) %*% stats::rnorm(groups)), ids)
  alpha <- c(`(Intercept)` = log(0.5), z = 0.5)
  x <- rep(seq(-1.2, 1.2, length.out = 20L), groups)
  group <- rep(ids, each = 20L)
  eta <- 0.2 + 0.3 * x + exp(alpha[[1L]] + alpha[[2L]] * z[group]) * u[group]
  mu <- 1e-12 + (1 - 2e-12) * stats::plogis(eta)
  phi <- exp(-2 * log(0.35))
  shape1 <- mu * phi
  shape2 <- (1 - mu) * phi
  stopifnot(all(is.finite(eta)), all(is.finite(mu)), all(mu > 0 & mu < 1),
    min(shape1, shape2) > 1e-8)
  y <- stats::rbeta(length(group), shape1, shape2)
  stopifnot(all(is.finite(y)), all(y > 0 & y < 1))
  data <- data.frame(y = y, x = x, id = factor(group, levels = rev(ids)),
    z = unname(z[group]))
  list(data = data, K = K, Q = Q, coords = coords, z = z, truth = alpha)
}

beta_structured_q1_form <- function(provider, K, Q = NULL, coords = NULL, constant = FALSE) {
  if (provider == "relmat") {
    mu <- if (is.null(Q)) y ~ x + relmat(1 | id, K = K) else
      y ~ x + relmat(1 | id, Q = Q)
    sd <- if (constant) sd(id, level = "relmat") ~ 1 else
      sd(id, level = "relmat") ~ z
  } else {
    mu <- y ~ x + spatial(1 | id, coords = coords)
    sd <- if (constant) sd(id, level = "spatial") ~ 1 else
      sd(id, level = "spatial") ~ z
  }
  environment(mu) <- environment()
  environment(sd) <- environment()
  bf(mu, sigma ~ 1, sd)
}

# Independent scalar q1 reference: the provider covariance comes from the
# fixture, and neither its precision nor its Laplace calculation uses package helpers.
beta_structured_q1_oracle <- function(fit, fx, provider) {
  d <- fx$data
  ids <- rownames(fx$K)
  n <- length(ids)
  P <- solve(fx$K)
  ii <- match(as.character(d$id), ids)
  key <- sprintf('sd_%s(id)', provider)
  a <- coef(fit, key)
  scale <- exp(a[[1L]] + a[[2L]] * fx$z[ids])
  B <- matrix(0, nrow(d), n)
  B[cbind(seq_len(nrow(d)), ii)] <- scale[ii]
  fixed <- drop(stats::model.matrix(~ x, d) %*% coef(fit, "mu"))
  phi <- exp(-2 * coef(fit, "sigma")[[1L]])
  moments <- function(u) {
    eta <- fixed + drop(B %*% u)
    p <- stats::plogis(eta)
    mu <- 1e-12 + (1 - 2e-12) * p
    shape1 <- phi * mu
    shape2 <- phi * (1 - mu)
    if (min(shape1, shape2) <= 1e-8) stop("Oracle reached its frozen shape floor.")
    first <- (1 - 2e-12) * p * (1 - p)
    second <- first * (1 - 2 * p)
    t <- log(d$y) - log1p(-d$y) - digamma(shape1) + digamma(shape2)
    list(eta = eta, shape1 = shape1, shape2 = shape2,
      score = -phi * t * first,
      curvature = phi^2 * (trigamma(shape1) + trigamma(shape2)) * first^2 -
        phi * t * second)
  }
  joint <- function(u) {
    m <- moments(u)
    -sum(stats::dbeta(d$y, m$shape1, m$shape2, log = TRUE)) +
      drop(crossprod(u, P %*% u)) / 2 + n * log(2 * pi) / 2 +
      as.numeric(determinant(fx$K, logarithm = TRUE)$modulus) / 2
  }
  gradient <- function(u) drop(P %*% u + crossprod(B, moments(u)$score))
  hessian <- function(u) P + crossprod(B, moments(u)$curvature * B)
  starts <- list(rep(0, n), seq(-0.05, 0.05, length.out = n))
  modes <- lapply(starts, function(start) stats::nlminb(start, joint, gradient,
    hessian, control = list(iter.max = 150L, eval.max = 300L, rel.tol = 1e-13)))
  objectives <- vapply(modes, `[[`, numeric(1L), "objective")
  mode <- modes[[which.min(objectives)]]
  H <- hessian(mode$par)
  chol(H)
  probe <- starts[[2L]]
  step <- 1e-5
  cols <- unique(c(1L, n %/% 2L, n))
  fd_score <- vapply(cols, function(j) {
    delta <- numeric(n); delta[[j]] <- step
    (joint(probe + delta) - joint(probe - delta)) / (2 * step)
  }, numeric(1L))
  fd_hessian <- vapply(cols, function(j) {
    delta <- numeric(n); delta[[j]] <- step
    (gradient(probe + delta) - gradient(probe - delta)) / (2 * step)
  }, numeric(n))
  list(nll = joint(mode$par) +
      as.numeric(determinant(H, logarithm = TRUE)$modulus) / 2 -
      n * log(2 * pi) / 2,
    eta = moments(mode$par)$eta,
    gradient = max(vapply(modes, function(m) max(abs(gradient(m$par))), numeric(1L))),
    mode_difference = diff(range(objectives)),
    derivative_error = max(abs(fd_score - gradient(probe)[cols])),
    hessian_error = max(abs(fd_hessian - hessian(probe)[, cols, drop = FALSE])))
}

test_that("Beta q1 structured-intercept SD specs admit only complete independent routes", {
  fx <- beta_structured_q1_fixture("relmat", seed = 2026102810L)
  K <- fx$K
  Q <- fx$Q
  form <- beta_structured_q1_form("relmat", K)
  spec <- drmTMB:::drm_build_beta_ls_spec(form, fx$data)
  expect_identical(spec$structured$phylo_mu$q, 1L)
  expect_true(isTRUE(spec$random_scale$phylo$n_models == 1L))
  expect_identical(spec$tmb_data$has_sd_phylo_coef_model, 0L)
  expect_true("sd_relmat(id)" %in% spec$dpars)

  qspec <- drmTMB:::drm_build_beta_ls_spec(
    beta_structured_q1_form("relmat", K, Q = Q), fx$data)
  expect_equal(as.matrix(qspec$structured$phylo_mu$precision$precision),
    as.matrix(spec$structured$phylo_mu$precision$precision), tolerance = 1e-10)

  spatial <- beta_structured_q1_fixture("spatial", seed = 2026102811L)
  coords <- spatial$coords
  sspec <- drmTMB:::drm_build_beta_ls_spec(
    beta_structured_q1_form("spatial", spatial$K, coords = coords), spatial$data)
  expect_identical(sspec$structured$phylo_mu$q, 1L)
  expect_true("sd_spatial(id)" %in% sspec$dpars)
  expect_equal(unname(solve(as.matrix(sspec$structured$phylo_mu$precision$precision))),
    unname(spatial$K), tolerance = 1e-8)

  expect_error(drmTMB:::drm_build_beta_ls_spec(
    bf(y ~ x + relmat(0 + x | id, K = K), sigma ~ 1), fx$data),
    "intercept-only or intercept-plus-one-slope")
  expect_error(drmTMB:::drm_build_beta_ls_spec(
    bf(y ~ x + spatial(1 | id, coords = coords) + (1 | id), sigma ~ 1,
       sd(id, level = "spatial") ~ z), spatial$data), "cannot yet be combined with an ordinary")
  expect_error(drmTMB:::drm_build_beta_ls_spec(
    bf(y ~ x + spatial(1 | p | id, coords = coords), sigma ~ 1,
       sd(id, level = "spatial") ~ z), spatial$data), "unlabelled")
  expect_error(drmTMB:::drm_build_beta_ls_spec(
    bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1 + (1 | id),
       sd(id, level = "relmat") ~ z), fx$data), "sigma.*random effects")
  expect_error(drmTMB:::drm_build_beta_ls_spec(
    form, fx$data, missing = miss_control(response = "include")), "complete responses")
})

test_that("Beta relmat q1 K and Q recover SD regression and match scalar Laplace oracle", {
  skip_on_cran()
  fx <- beta_structured_q1_fixture("relmat", seed = 2026102810L)
  K <- fx$K; Q <- fx$Q
  fit <- drmTMB(beta_structured_q1_form("relmat", K), family = beta_family(),
    data = fx$data, control = drm_control(se = FALSE))
  expect_equal(fit$opt$convergence, 0L)
  key <- 'sd_relmat(id)'
  expect_lt(abs(coef(fit, key)[["z"]] - 0.5), 0.4)
  oracle <- beta_structured_q1_oracle(fit, fx, "relmat")
  expect_lt(oracle$gradient, 1e-5)
  expect_lt(oracle$mode_difference, 1e-6)
  expect_lt(oracle$derivative_error, 1e-4)
  expect_lt(oracle$hessian_error, 2e-4)
  expect_lt(abs(-as.numeric(logLik(fit)) - oracle$nll), 1e-4)
  eta <- as.numeric(predict(fit, type = "link", re.form = NULL))
  expect_lt(max(abs(eta - oracle$eta)), 1e-4)
  predicted_sd <- predict(fit, dpar = key)
  expect_setequal(names(predicted_sd), rownames(K))
  expect_equal(unname(predicted_sd),
    unname(exp(coef(fit, key)[[1L]] + coef(fit, key)[[2L]] * fx$z[names(predicted_sd)])),
    tolerance = 1e-10)
  expect_equal(nrow(predict_parameters(fit, dpar = key, conf.int = FALSE)), nrow(K))
  report <- fit$obj$report(fit$tmb_state$last.par.best)
  expect_lt(max(abs(as.numeric(fitted(fit)) - as.numeric(report$mu))), 1e-8)
  qids <- rev(rownames(Q))
  Q <- Q[qids, qids]
  qfit <- drmTMB(beta_structured_q1_form("relmat", K, Q = Q), family = beta_family(),
    data = fx$data, control = drm_control(se = FALSE))
  expect_equal(qfit$opt$convergence, 0L)
  expect_lt(abs(as.numeric(logLik(qfit)) - as.numeric(logLik(fit))), 1e-4)
  expect_lt(max(abs(coef(qfit, "mu") - coef(fit, "mu"))), 1e-4)
  expect_lt(max(abs(coef(qfit, key) - coef(fit, key))), 1e-4)
  expect_lt(max(abs(as.numeric(predict(qfit, type = "link", re.form = NULL)) - eta)), 1e-4)
  constant <- drmTMB(beta_structured_q1_form("relmat", K, constant = TRUE),
    family = beta_family(), data = fx$data, control = drm_control(se = FALSE))
  base <- drmTMB(bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1),
    family = beta_family(), data = fx$data, control = drm_control(se = FALSE))
  expect_equal(constant$opt$convergence, 0L)
  expect_equal(base$opt$convergence, 0L)
  expect_lt(abs(as.numeric(logLik(constant)) - as.numeric(logLik(base))), 1e-4)
  saved <- tempfile(fileext = ".rds"); on.exit(unlink(saved), add = TRUE)
  saveRDS(fit, saved)
  expect_equal(predict(readRDS(saved), dpar = key), predicted_sd)
  simulated <- simulate(fit, nsim = 1L, seed = 2026102812L, re.form = NULL)$sim_1
  set.seed(2026102812L); phi <- exp(-2 * coef(fit, "sigma")[[1L]])
  expect_equal(simulated,
    stats::rbeta(nrow(fx$data), report$mu * phi, (1 - report$mu) * phi), tolerance = 1e-8)
})

test_that("Beta coordinate q1 recovers SD regression and matches scalar Laplace oracle", {
  skip_on_cran()
  fx <- beta_structured_q1_fixture("spatial", seed = 2026102811L)
  coords <- fx$coords
  fit <- drmTMB(beta_structured_q1_form("spatial", fx$K, coords = coords),
    family = beta_family(), data = fx$data, control = drm_control(se = FALSE))
  expect_equal(fit$opt$convergence, 0L)
  key <- 'sd_spatial(id)'
  expect_lt(abs(coef(fit, key)[["z"]] - 0.5), 0.4)
  oracle <- beta_structured_q1_oracle(fit, fx, "spatial")
  expect_lt(oracle$gradient, 1e-5)
  expect_lt(oracle$mode_difference, 1e-6)
  expect_lt(oracle$derivative_error, 1e-4)
  expect_lt(oracle$hessian_error, 2e-4)
  expect_lt(abs(-as.numeric(logLik(fit)) - oracle$nll), 1e-4)
  eta <- as.numeric(predict(fit, type = "link", re.form = NULL))
  expect_lt(max(abs(eta - oracle$eta)), 1e-4)
  predicted_sd <- predict(fit, dpar = key)
  expect_setequal(names(predicted_sd), rownames(fx$K))
  expect_equal(unname(predicted_sd),
    unname(exp(coef(fit, key)[[1L]] + coef(fit, key)[[2L]] * fx$z[names(predicted_sd)])),
    tolerance = 1e-10)
  expect_equal(nrow(predict_parameters(fit, dpar = key, conf.int = FALSE)), nrow(fx$K))
  report <- fit$obj$report(fit$tmb_state$last.par.best)
  expect_lt(max(abs(as.numeric(fitted(fit)) - as.numeric(report$mu))), 1e-8)
  saved <- tempfile(fileext = ".rds"); on.exit(unlink(saved), add = TRUE)
  saveRDS(fit, saved)
  expect_equal(predict(readRDS(saved), dpar = key), predicted_sd)
  simulated <- simulate(fit, nsim = 1L, seed = 2026102813L, re.form = NULL)$sim_1
  set.seed(2026102813L); phi <- exp(-2 * coef(fit, "sigma")[[1L]])
  expect_equal(simulated,
    stats::rbeta(nrow(fx$data), report$mu * phi, (1 - report$mu) * phi), tolerance = 1e-8)
  reversed <- coords[rev(rownames(coords)), , drop = FALSE]
  other <- drmTMB(beta_structured_q1_form("spatial", fx$K, coords = reversed),
    family = beta_family(), data = fx$data, control = drm_control(se = FALSE))
  expect_equal(other$opt$convergence, 0L)
  expect_lt(abs(as.numeric(logLik(other)) - as.numeric(logLik(fit))), 1e-4)
  expect_lt(max(abs(coef(other, key) - coef(fit, key))), 1e-4)
  expect_lt(max(abs(as.numeric(predict(other, type = "link", re.form = NULL)) - eta)), 1e-4)
  constant <- drmTMB(beta_structured_q1_form("spatial", fx$K, coords = coords,
      constant = TRUE), family = beta_family(), data = fx$data,
    control = drm_control(se = FALSE))
  base <- drmTMB(bf(y ~ x + spatial(1 | id, coords = coords), sigma ~ 1),
    family = beta_family(), data = fx$data, control = drm_control(se = FALSE))
  expect_equal(constant$opt$convergence, 0L)
  expect_equal(base$opt$convergence, 0L)
  expect_lt(abs(as.numeric(logLik(constant)) - as.numeric(logLik(base))), 1e-4)
})
