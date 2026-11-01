# Independent latent fields: b_k = diag(exp(Z_k alpha_k)) u_k,
# u_k ~ N(0, K), eta = X beta + b_0[id] + x b_1[id].
gamma_relmat_q2_sd_fixture <- function(groups = 64L, repeats = 20L) {
  set.seed(2026102703L)
  ids <- sprintf("group%03d", seq_len(groups))
  diagonal <- seq(0.8, 1.3, length.out = groups)
  K <- 0.25^abs(outer(seq_len(groups), seq_len(groups), "-")) *
    outer(sqrt(diagonal), sqrt(diagonal))
  dimnames(K) <- list(ids, ids)
  w0 <- stats::setNames(rep(c(-1, 1), groups / 2L), ids)
  w1 <- stats::setNames(rep(c(-1, 1), each = groups / 2L), ids)
  truth <- list(a0 = c(log(0.5), w0 = 0.5), a1 = c(log(0.4), w1 = -0.5))
  b0 <- exp(truth$a0[1L] + truth$a0[2L] * w0) *
    drop(t(chol(K)) %*% stats::rnorm(groups))
  b1 <- exp(truth$a1[1L] + truth$a1[2L] * w1) *
    drop(t(chol(K)) %*% stats::rnorm(groups))
  ii <- rep(seq_len(groups), each = repeats)
  x <- rep(seq(-1.2, 1.2, length.out = repeats), groups)
  mu <- exp(0.2 + 0.3 * x + b0[ii] + x * b1[ii])
  dat <- data.frame(
    y = stats::rgamma(length(ii), shape = 0.35^-2, scale = mu * 0.35^2),
    x = x, id = factor(ids[ii], levels = rev(ids)),
    w0 = unname(w0[ii]), w1 = unname(w1[ii])
  )
  # Kernel and factor orders differ from the simulation and from one another.
  order <- c(seq(2L, groups, 2L), seq(1L, groups, 2L))
  list(data = dat, K = K[order, order], truth = truth, w0 = w0, w1 = w1)
}

gamma_relmat_q2_sd_form <- function(K, Q = NULL, constant = FALSE,
                                      reverse_sd = FALSE, animal = FALSE) {
  layer <- if (animal) quote(animal(1 + x | id, A = K)) else if (is.null(Q)) {
    quote(relmat(1 + x | id, K = K))
  } else quote(relmat(1 + x | id, Q = Q))
  level <- if (animal) "animal" else "relmat"
  mu <- stats::as.formula(call("~", quote(y), call("+", quote(x), layer)))
  environment(mu) <- environment()
  f0 <- stats::as.formula(sprintf(
    'sd(id, level = "%s", coef = "(Intercept)") ~ %s',
    level, if (constant) "1" else "w0"
  ), env = environment())
  f1 <- stats::as.formula(sprintf(
    'sd(id, level = "%s", coef = "x") ~ %s',
    level, if (constant) "1" else "w1"
  ), env = environment())
  if (reverse_sd) bf(mu, sigma ~ 1, f1, f0) else bf(mu, sigma ~ 1, f0, f1)
}

# Dense oracle with an independently optimized latent mode and analytic Hessian.
gamma_relmat_q2_sd_oracle <- function(fit, fx) {
  d <- fx$data
  ids <- rownames(fx$K)
  n <- length(ids)
  Q <- solve(fx$K)
  P <- kronecker(diag(2L), Q)
  ii <- match(as.character(d$id), ids)
  keys <- c('sd_relmat(id, dpar = "mu", coef = "(Intercept)")',
            'sd_relmat(id, dpar = "mu", coef = "x")')
  a0 <- coef(fit, keys[1L]); a1 <- coef(fit, keys[2L])
  tau0 <- exp(a0[1L] + a0[2L] * fx$w0[ids])
  tau1 <- exp(a1[1L] + a1[2L] * fx$w1[ids])
  B <- matrix(0, nrow(d), 2L * n)
  B[cbind(seq_len(nrow(d)), ii)] <- tau0[ii]
  B[cbind(seq_len(nrow(d)), n + ii)] <- d$x * tau1[ii]
  eta_fixed <- drop(stats::model.matrix(~ x, d) %*% coef(fit, "mu"))
  shape <- exp(-2 * coef(fit, "sigma")[[1L]])
  joint <- function(u) {
    eta <- eta_fixed + drop(B %*% u)
    -sum(stats::dgamma(d$y, shape = shape, rate = shape / exp(eta), log = TRUE)) +
      drop(crossprod(u, P %*% u)) / 2 + n * log(2 * pi) +
      as.numeric(determinant(fx$K, logarithm = TRUE)$modulus)
  }
  gradient <- function(u) {
    eta <- eta_fixed + drop(B %*% u)
    drop(P %*% u + crossprod(B, shape * (1 - d$y * exp(-eta))))
  }
  hessian <- function(u) {
    eta <- eta_fixed + drop(B %*% u)
    P + crossprod(B, (shape * d$y * exp(-eta)) * B)
  }
  mode <- stats::nlminb(rep(0, 2L * n), joint, gradient, hessian,
    control = list(iter.max = 100L, eval.max = 200L, rel.tol = 1e-12))
  list(nll = joint(mode$par) +
         as.numeric(determinant(hessian(mode$par), logarithm = TRUE)$modulus) / 2 -
         n * log(2 * pi),
       gradient = max(abs(gradient(mode$par))),
       eta = eta_fixed + drop(B %*% mode$par))
}

test_that("Gamma relmat q2 admits two distinct group SD surfaces", {
  fx <- gamma_relmat_q2_sd_fixture(groups = 12L, repeats = 8L)
  K <- fx$K
  spec <- drmTMB:::drm_build_gamma_ls_spec(gamma_relmat_q2_sd_form(fx$K), fx$data)
  expect_identical(spec$tmb_data$has_sd_phylo_coef_model, 1L)
  expect_equal(ncol(spec$tmb_data$phylo_mu_sd_row_coef), 2L)
  expect_true(all(spec$tmb_data$phylo_mu_sd_row_coef >= 0L))
  expect_length(spec$random_scale$phylo$dpars, 2L)
  expect_true(all(startsWith(spec$random_scale$phylo$dpars, "sd_relmat(")))
  expect_error(drmTMB:::drm_build_gamma_ls_spec(
    bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1,
       sd(id, level = "relmat", coef = "x") ~ w1), fx$data),
    "requires one SD formula for each coefficient")
  expect_error(drmTMB:::drm_build_gamma_ls_spec(
    bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1,
       sd(id, level = "relmat", coef = "z") ~ w0,
       sd(id, level = "relmat", coef = "x") ~ w1), fx$data),
    "coefficient")
  bad <- fx$data; bad$w0[1L] <- bad$w0[1L] + 0.1
  expect_error(drmTMB:::drm_build_gamma_ls_spec(gamma_relmat_q2_sd_form(fx$K), bad),
               "constant within")
  bad <- fx$data; bad$x <- 0
  expect_error(drmTMB:::drm_build_gamma_ls_spec(gamma_relmat_q2_sd_form(fx$K), bad),
               "unidentified slope scale")
  bad$x <- 1
  expect_error(drmTMB:::drm_build_gamma_ls_spec(
    gamma_relmat_q2_sd_form(fx$K, constant = TRUE), bad),
    "not separately identifiable")
})

test_that("Gamma q2 extraction scales each latent field and marks unused nodes", {
  fx <- gamma_relmat_q2_sd_fixture(groups = 12L, repeats = 8L)
  K <- fx$K
  absent <- rownames(K)[1L]
  d <- fx$data[as.character(fx$data$id) != absent, , drop = FALSE]
  spec <- drmTMB:::drm_build_gamma_ls_spec(gamma_relmat_q2_sd_form(K), d)
  par <- spec$start
  n <- spec$structured$phylo_mu$n_re
  par$u_phylo <- seq_len(2L * n) / n
  par$beta_sd_mu <- c(log(0.5), 0.5, log(0.4), -0.5)
  re <- drmTMB:::split_tmb_random_effects(par, spec)$relmat_mu
  expect_equal(unname(re$latent), par$u_phylo)
  nodes <- spec$structured$phylo_mu$node_labels
  expect_equal(unname(re$terms[[1L]][setdiff(nodes, absent)]),
    unname(par$u_phylo[match(setdiff(nodes, absent), nodes)] *
      exp(log(0.5) + 0.5 * fx$w0[setdiff(nodes, absent)])))
  expect_equal(unname(re$terms[[2L]][setdiff(nodes, absent)]),
    unname(par$u_phylo[n + match(setdiff(nodes, absent), nodes)] *
      exp(log(0.4) - 0.5 * fx$w1[setdiff(nodes, absent)])))
  expect_true(is.na(re$terms[[1L]][absent]))
  expect_true(is.na(re$terms[[2L]][absent]))
})

test_that("Gamma relmat q2 SD fitting matches an independent dense oracle", {
  skip_on_cran()
  fx <- gamma_relmat_q2_sd_fixture()
  fit <- drmTMB(gamma_relmat_q2_sd_form(fx$K), family = Gamma(link = "log"),
                data = fx$data, control = drm_control(se = FALSE))
  expect_equal(fit$opt$convergence, 0L)
  keys <- c('sd_relmat(id, dpar = "mu", coef = "(Intercept)")',
            'sd_relmat(id, dpar = "mu", coef = "x")')
  expect_lt(abs(coef(fit, keys[1L])[["w0"]] - fx$truth$a0[["w0"]]), 0.3)
  expect_lt(abs(coef(fit, keys[2L])[["w1"]] - fx$truth$a1[["w1"]]), 0.3)
  for (k in seq_along(keys)) {
    a <- coef(fit, keys[k]); w <- if (k == 1L) fx$w0 else fx$w1
    predicted <- predict(fit, dpar = keys[k])
    expect_setequal(names(predicted), levels(fx$data$id))
    expect_equal(unname(predicted), unname(exp(a[1L] + a[2L] * w[names(predicted)])),
                 tolerance = 1e-10)
  }
  expect_equal(as.numeric(predict(fit, type = "link", re.form = NULL)),
               as.numeric(fit$obj$report(fit$tmb_state$last.par.best)$eta_mu), tolerance = 1e-7)
  oracle <- gamma_relmat_q2_sd_oracle(fit, fx)
  expect_lt(oracle$gradient, 1e-5)
  expect_equal(as.numeric(-logLik(fit)), oracle$nll, tolerance = 1e-5)
  expect_equal(as.numeric(fit$obj$report(fit$tmb_state$last.par.best)$eta_mu), as.numeric(oracle$eta),
               tolerance = 1e-5)
  reverse_fit <- drmTMB(gamma_relmat_q2_sd_form(fx$K, reverse_sd = TRUE),
    family = Gamma(link = "log"), data = fx$data, control = drm_control(se = FALSE))
  precision_fit <- drmTMB(gamma_relmat_q2_sd_form(fx$K, Q = solve(fx$K)),
    family = Gamma(link = "log"), data = fx$data, control = drm_control(se = FALSE))
  for (other in list(reverse_fit, precision_fit)) {
    expect_equal(other$opt$convergence, 0L)
    expect_equal(as.numeric(logLik(other)), as.numeric(logLik(fit)), tolerance = 1e-5)
    for (key in keys) expect_equal(coef(other, key), coef(fit, key), tolerance = 1e-4)
  }
  constant_fit <- drmTMB(gamma_relmat_q2_sd_form(fx$K, constant = TRUE),
    family = Gamma(link = "log"), data = fx$data, control = drm_control(se = FALSE))
  expect_equal(constant_fit$opt$convergence, 0L)
  K <- fx$K
  base_fit <- drmTMB(bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1),
    family = Gamma(link = "log"), data = fx$data, control = drm_control(se = FALSE))
  expect_equal(base_fit$opt$convergence, 0L)
  expect_equal(as.numeric(logLik(constant_fit)), as.numeric(logLik(base_fit)),
               tolerance = 1e-5)
  saved <- tempfile(fileext = ".rds"); on.exit(unlink(saved), add = TRUE)
  saveRDS(fit, saved); reloaded <- readRDS(saved)
  expect_equal(predict(reloaded, type = "link", re.form = NULL),
               predict(fit, type = "link", re.form = NULL))
  expect_true(all(is.finite(simulate(fit, nsim = 1L, seed = 2026102704L,
                                   re.form = NULL)$sim_1)))
  expect_error(simulate(fit, nsim = 1L, re.form = NA),
               "Marginal simulation.*does not yet support")
  # The existing Gamma animal route must apply the same coefficient SD scales
  # in conditional predictions and extraction.
  animal_fit <- drmTMB(gamma_relmat_q2_sd_form(fx$K, animal = TRUE),
    family = Gamma(link = "log"), data = fx$data, control = drm_control(se = FALSE))
  expect_equal(animal_fit$opt$convergence, 0L)
  expect_equal(as.numeric(predict(animal_fit, type = "link", re.form = NULL)),
               as.numeric(animal_fit$obj$report(animal_fit$tmb_state$last.par.best)$eta_mu), tolerance = 1e-7)
})
