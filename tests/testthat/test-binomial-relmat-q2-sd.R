test_that("Binomial logit relmat q2 assembles two selected SD fields", {
  ids <- paste0("id", seq_len(8L))
  K <- outer(seq_along(ids), seq_along(ids), function(i, j) 0.25^abs(i - j))
  variance <- seq(0.8, 1.3, length.out = length(ids))
  K <- K * outer(sqrt(variance), sqrt(variance))
  dimnames(K) <- list(ids, ids)
  dat <- expand.grid(id = ids, rep = seq_len(6L))
  dat$id <- factor(dat$id, levels = ids)
  dat$x <- rep(seq(-1, 1, length.out = 6L), each = length(ids))
  dat$z0 <- rep(rep(c(-1, 1), each = 4L), 6L)
  dat$z1 <- rep(rep(c(-1, 1), times = 4L), 6L)
  dat$y <- rep(c(0, 1), length.out = nrow(dat))
  for (provider in c("K", "Q")) {
    matrix_arg <- if (identical(provider, "K")) K else solve(K)
    form <- if (identical(provider, "K")) {
      bf(y ~ x + relmat(1 + x | id, K = matrix_arg),
         sd(id, level = "relmat", coef = "(Intercept)") ~ z0,
         sd(id, level = "relmat", coef = "x") ~ z1)
    } else {
      bf(y ~ x + relmat(1 + x | id, Q = matrix_arg),
         sd(id, level = "relmat", coef = "(Intercept)") ~ z0,
         sd(id, level = "relmat", coef = "x") ~ z1)
    }
    spec <- drmTMB:::drm_build_binomial_spec(form, dat)
    expect_identical(spec$tmb_data$has_sd_phylo_coef_model, 1L)
    expect_length(unique(spec$random_scale$phylo$dpars), 2L)
    expect_match(spec$random_scale$phylo$dpars[[1L]], 'coef = "\\(Intercept\\)"')
    expect_match(spec$random_scale$phylo$dpars[[2L]], 'coef = "x"')
    expect_true(all(colSums(spec$tmb_data$phylo_mu_sd_row_coef >= 0L) > 0L))
    expect_true(all(spec$tmb_data$phylo_mu_sd_row_coef >= 0L))
    expect_true(all(is.na(spec$map$log_sd_phylo)))
    expect_true(all(is.na(spec$map$eta_cor_phylo)))
    base <- if (identical(provider, "K")) {
      bf(y ~ x + relmat(1 + x | id, K = matrix_arg))
    } else {
      bf(y ~ x + relmat(1 + x | id, Q = matrix_arg))
    }
    base_spec <- drmTMB:::drm_build_binomial_spec(base, dat)
    expect_identical(base_spec$structured$phylo_mu$q, 2L)
    expect_identical(base_spec$tmb_data$has_sd_phylo_coef_model, 0L)
    expect_null(base_spec$map$log_sd_phylo)
    expect_true(all(is.na(base_spec$map$eta_cor_phylo)))
    bad_spec <- spec
    bad_spec$random_scale$phylo$observation_sd_row0_by_coef[1L, 1L] <- -1L
    expect_error(drmTMB:::make_tmb_data(bad_spec), "map every observation")
    bad_spec <- spec
    bad_spec$random_scale$phylo$observation_sd_row0_by_coef <-
      matrix(0L, nrow = 1L, ncol = 2L)
    expect_error(drmTMB:::make_tmb_data(bad_spec), "map every observation")
  }
})

binomial_relmat_q2_fixture <- function(groups = 160L, repeats = 32L) {
  set.seed(2026102817L)
  ids <- sprintf("group%03d", seq_len(groups))
  variance <- seq(0.8, 1.3, length.out = groups)
  full_K <- 0.25^abs(outer(seq_len(groups), seq_len(groups), "-")) *
    outer(sqrt(variance), sqrt(variance))
  dimnames(full_K) <- list(ids, ids)
  z0 <- stats::setNames(rep(c(-1, 1), length.out = groups), ids)
  z1 <- stats::setNames(rep(c(-1, 1), each = groups / 2L), ids)
  truth <- list(mu = c(0.2, x = 0.3),
                sd0 = c(log(0.8), z0 = 0.6),
                sd1 = c(log(0.6), z1 = -0.5))
  u0 <- drop(t(chol(full_K)) %*% stats::rnorm(groups))
  u1 <- drop(t(chol(full_K)) %*% stats::rnorm(groups))
  b0 <- exp(truth$sd0[[1L]] + truth$sd0[[2L]] * z0) * u0
  b1 <- exp(truth$sd1[[1L]] + truth$sd1[[2L]] * z1) * u1
  ii <- rep(seq_len(groups), each = repeats)
  x <- rep(seq(-1.2, 1.2, length.out = repeats), groups)
  eta <- truth$mu[[1L]] + truth$mu[[2L]] * x + b0[ii] + x * b1[ii]
  dat <- data.frame(y = stats::rbinom(length(ii), 1L, stats::plogis(eta)),
                    x = x, id = factor(ids[ii], levels = rev(ids)),
                    z0 = unname(z0[ii]), z1 = unname(z1[ii]))
  k_order <- c(seq(2L, groups, 2L), seq(1L, groups, 2L))
  q_order <- c(seq(3L, groups, 3L), setdiff(seq_len(groups), seq(3L, groups, 3L)))
  list(data = dat, K = full_K[k_order, k_order],
       Q = solve(full_K)[q_order, q_order], full_K = full_K,
       z0 = z0, z1 = z1, truth = truth)
}

binomial_relmat_q2_form <- function(K = NULL, Q = NULL, reverse = FALSE,
                                    constant = FALSE) {
  layer <- if (is.null(Q)) quote(relmat(1 + x | id, K = K)) else
    quote(relmat(1 + x | id, Q = Q))
  mu <- stats::as.formula(call("~", quote(y), call("+", quote(x), layer)))
  environment(mu) <- environment()
  f0 <- stats::as.formula(sprintf(
    'sd(id, level = "relmat", coef = "(Intercept)") ~ %s',
    if (constant) "1" else "z0"), env = environment())
  f1 <- stats::as.formula(sprintf(
    'sd(id, level = "relmat", coef = "x") ~ %s',
    if (constant) "1" else "z1"), env = environment())
  if (reverse) bf(mu, f1, f0) else bf(mu, f0, f1)
}

binomial_relmat_q2_oracle <- function(fit, fx) {
  d <- fx$data
  ids <- rownames(fx$full_K)
  n <- length(ids)
  P <- kronecker(diag(2L), solve(fx$full_K))
  ii <- match(as.character(d$id), ids)
  keys <- c('sd_relmat(id, dpar = "mu", coef = "(Intercept)")',
            'sd_relmat(id, dpar = "mu", coef = "x")')
  a0 <- stats::coef(fit, keys[[1L]])
  a1 <- stats::coef(fit, keys[[2L]])
  s0 <- exp(a0[[1L]] + a0[[2L]] * fx$z0[ids])
  s1 <- exp(a1[[1L]] + a1[[2L]] * fx$z1[ids])
  B <- matrix(0, nrow(d), 2L * n)
  B[cbind(seq_len(nrow(d)), ii)] <- s0[ii]
  B[cbind(seq_len(nrow(d)), n + ii)] <- d$x * s1[ii]
  eta_fixed <- drop(stats::model.matrix(~ x, d) %*% stats::coef(fit, "mu"))
  joint <- function(u) {
    eta <- eta_fixed + drop(B %*% u)
    -sum(stats::dbinom(d$y, 1L, stats::plogis(eta), log = TRUE)) +
      drop(crossprod(u, P %*% u)) / 2 + n * log(2 * pi) +
      as.numeric(determinant(fx$full_K, logarithm = TRUE)$modulus)
  }
  score <- function(u) {
    p <- stats::plogis(eta_fixed + drop(B %*% u))
    drop(P %*% u + crossprod(B, p - d$y))
  }
  hessian <- function(u) {
    p <- stats::plogis(eta_fixed + drop(B %*% u))
    P + crossprod(B, (p * (1 - p)) * B)
  }
  away <- rep(0.02, 2L * n)
  checked <- unique(c(1L, n, n + 1L, 2L * n))
  step <- 1e-5
  fd_score <- vapply(checked, function(j) {
    plus <- away; minus <- away
    plus[[j]] <- plus[[j]] + step
    minus[[j]] <- minus[[j]] - step
    (joint(plus) - joint(minus)) / (2 * step)
  }, numeric(1L))
  fd_hessian <- sapply(checked, function(j) {
    plus <- away; minus <- away
    plus[[j]] <- plus[[j]] + step
    minus[[j]] <- minus[[j]] - step
    (score(plus)[checked] - score(minus)[checked]) / (2 * step)
  })
  starts <- list(rep(0, 2L * n), 0.01 * sin(seq_len(2L * n)))
  modes <- lapply(starts, function(start) stats::nlminb(
    start, joint, score, hessian,
    control = list(iter.max = 150L, eval.max = 250L, rel.tol = 1e-12)))
  mode <- modes[[which.min(vapply(modes, `[[`, numeric(1L), "objective"))]]
  H <- hessian(mode$par)
  list(nll = joint(mode$par) +
         as.numeric(determinant(H, logarithm = TRUE)$modulus) / 2 -
         n * log(2 * pi),
       eta = eta_fixed + drop(B %*% mode$par),
       gradient = max(abs(score(mode$par))),
       score_error = max(abs(score(away)[checked] - fd_score)),
       hessian_error = max(abs(hessian(away)[checked, checked] - fd_hessian)),
       mode_objectives = vapply(modes, `[[`, numeric(1L), "objective"),
       mode_convergence = vapply(modes, `[[`, integer(1L), "convergence"))
}

test_that("Binomial relmat q2 rejects unidentified or unsupported SD targets", {
  fx <- binomial_relmat_q2_fixture(groups = 12L, repeats = 8L)
  K <- fx$K
  dat <- fx$data
  expect_error(drmTMB:::drm_build_binomial_spec(
    bf(y ~ x + relmat(1 + x | id, K = K),
       sd(id, level = "relmat", coef = "x") ~ z1), dat),
    "one SD formula for each coefficient")
  expect_error(drmTMB:::drm_build_binomial_spec(
    bf(y ~ x + relmat(1 + x | id, K = K),
       sd(id, level = "relmat", coef = "x") ~ z0,
       sd(id, level = "relmat", coef = "x") ~ z1), dat),
    "one SD formula for each coefficient")
  expect_error(drmTMB:::drm_build_binomial_spec(
    bf(y ~ x + relmat(1 + x | id, K = K),
       sd(id, level = "relmat", coef = "z0") ~ z0,
       sd(id, level = "relmat", coef = "x") ~ z1), dat),
    "coefficient selector")
  bad <- dat; bad$x <- 0
  expect_error(drmTMB:::drm_build_binomial_spec(
    binomial_relmat_q2_form(K), bad), "unidentified slope scale")
  bad$x <- 1
  expect_error(drmTMB:::drm_build_binomial_spec(
    binomial_relmat_q2_form(K, constant = TRUE), bad),
    "not separately identifiable")
  bad <- dat; bad$z0[[1L]] <- -bad$z0[[1L]]
  expect_error(drmTMB:::drm_build_binomial_spec(
    binomial_relmat_q2_form(K), bad), "constant within")
  bad <- dat; bad$y[[1L]] <- 2
  expect_error(drmTMB:::drm_build_binomial_spec(
    binomial_relmat_q2_form(K), bad), "0/1")
  expect_error(drmTMB:::drm_build_binomial_spec(
    binomial_relmat_q2_form(K), dat, weights = rep(1, nrow(dat))),
    "unweighted 0/1")
  expect_error(drmTMB:::drm_build_binomial_spec(
    binomial_relmat_q2_form(K), dat, link = "probit"),
    "intercept-only q1")
  animal_q2 <- drmTMB:::drm_build_binomial_spec(
    bf(y ~ x + animal(1 + x | id, A = K),
       sd(id, level = "animal", coef = "(Intercept)") ~ z0,
       sd(id, level = "animal", coef = "x") ~ z1), dat)
  expect_identical(animal_q2$structured$phylo_mu$type, "animal")
  expect_identical(animal_q2$structured$phylo_mu$q, 2L)
  dat$p <- "block"
  expect_error(drmTMB:::drm_build_binomial_spec(
    bf(y ~ x + relmat(1 + x | p | id, K = K),
       sd(id, level = "relmat", coef = "(Intercept)") ~ z0,
       sd(id, level = "relmat", coef = "x") ~ z1), dat),
    "unlabelled q1")
  dat$failure <- 2 - dat$y
  expect_error(drmTMB:::drm_build_binomial_spec(
    bf(cbind(y, failure) ~ x + relmat(1 + x | id, K = K),
       sd(id, level = "relmat", coef = "(Intercept)") ~ z0,
       sd(id, level = "relmat", coef = "x") ~ z1), dat),
    "unweighted 0/1")
})

test_that("Binomial relmat q2 matches an independent dense Laplace oracle", {
  skip_if(identical(Sys.getenv("DRMTMB_Q2_ASSEMBLY_ONLY"), "1"))
  skip_if(identical(Sys.getenv("DRMTMB_Q2_SKIP_MAIN"), "1"))
  skip_on_cran()
  fx <- binomial_relmat_q2_fixture()
  K <- fx$K
  fit <- drmTMB(binomial_relmat_q2_form(K), family = binomial(),
                data = fx$data, control = drm_control(se = FALSE))
  expect_equal(fit$opt$convergence, 0L)
  keys <- c('sd_relmat(id, dpar = "mu", coef = "(Intercept)")',
            'sd_relmat(id, dpar = "mu", coef = "x")')
  expect_lt(abs(stats::coef(fit, keys[[1L]])[["z0"]] -
                  fx$truth$sd0[["z0"]]), 0.4)
  expect_lt(abs(stats::coef(fit, keys[[2L]])[["z1"]] -
                  fx$truth$sd1[["z1"]]), 0.4)
  expect_lt(max(abs(fit$obj$gr(fit$opt$par))), 1e-2)
  oracle <- binomial_relmat_q2_oracle(fit, fx)
  metrics_dir <- Sys.getenv("DRMTMB_Q2_METRICS_DIR")
  if (nzchar(metrics_dir)) {
    dir.create(metrics_dir, recursive = TRUE, showWarnings = FALSE)
    saveRDS(list(seed = 2026102817L, groups = 160L, repeats = 32L,
                 loaded_dll_path = getLoadedDLLs()[["drmTMB"]][["path"]],
                 truth = fx$truth, estimated_mu = stats::coef(fit, "mu"),
                 estimated_sd0 = stats::coef(fit, keys[[1L]]),
                 estimated_sd1 = stats::coef(fit, keys[[2L]]),
                 convergence = fit$opt$convergence,
                 pdHess = fit$sdr$pdHess,
                 fixed_gradient = max(abs(fit$obj$gr(fit$opt$par))),
                 native_nll = -as.numeric(logLik(fit)), oracle = oracle,
                 eta_error = max(abs(as.numeric(fit$obj$report(
                   fit$tmb_state$last.par.best)$eta_mu) - oracle$eta))),
            file.path(metrics_dir, "main-fit.rds"))
  }
  expect_true(all(oracle$mode_convergence == 0L))
  expect_lt(diff(range(oracle$mode_objectives)), 1e-7)
  expect_lt(oracle$gradient, 1e-5)
  expect_lt(oracle$score_error, 1e-5)
  expect_lt(oracle$hessian_error, 1e-5)
  expect_lte(abs(-as.numeric(logLik(fit)) - oracle$nll), 1e-4)
  expect_lte(max(abs(as.numeric(fit$obj$report(
    fit$tmb_state$last.par.best)$eta_mu) - as.numeric(oracle$eta))), 1e-4)
  for (j in seq_along(keys)) {
    alpha <- stats::coef(fit, keys[[j]])
    z <- if (j == 1L) fx$z0 else fx$z1
    predicted <- predict(fit, dpar = keys[[j]])
    expect_setequal(names(predicted), levels(fx$data$id))
    expect_equal(unname(predicted),
                 unname(exp(alpha[[1L]] + alpha[[2L]] * z[names(predicted)])),
                 tolerance = 1e-8)
  }
  simulated_sd <- drmTMB:::drm_binomial_q2_structured_sd_by_node(
    fit, fit$model$structured$phylo_mu
  )
  expect_identical(colnames(simulated_sd), fit$model$structured$phylo_mu$coef_names)
  expect_identical(rownames(simulated_sd), names(
    predict(fit, dpar = keys[[1L]])
  ))
  for (j in seq_along(keys)) {
    expect_equal(unname(simulated_sd[, j]),
                 unname(predict(fit, dpar = keys[[j]])[
                   rownames(simulated_sd)
                 ]), tolerance = 1e-8)
  }
  expect_lte(max(abs(as.numeric(predict(fit, type = "link", re.form = NULL)) -
                      as.numeric(oracle$eta))), 1e-4)
  saved <- tempfile(fileext = ".rds")
  on.exit(unlink(saved), add = TRUE)
  saveRDS(fit, saved)
  expect_equal(predict(readRDS(saved), type = "link", re.form = NULL),
               predict(fit, type = "link", re.form = NULL))
  conditional <- simulate(fit, nsim = 1L, seed = 2026102819L,
                          re.form = NULL)
  expect_true(all(conditional[[1L]] %in% c(0, 1)))
  marginal1 <- simulate(fit, nsim = 2L, seed = 2026102819L)
  marginal2 <- simulate(fit, nsim = 2L, seed = 2026102819L)
  marginal_zero <- simulate(fit, nsim = 2L, seed = 2026102819L,
                            re.form = ~0)
  expect_identical(marginal1, marginal2)
  expect_identical(marginal1, marginal_zero)
  expect_true(all(vapply(marginal1, function(x) all(x %in% c(0, 1)),
                         logical(1L))))
  expect_false(identical(marginal1[[1L]], conditional[[1L]]))
  target <- paste0("fixef:", keys[[2L]], ":z1")
  target_table <- profile_targets(fit)
  selected <- target_table[target_table$parm == target, , drop = FALSE]
  expect_equal(nrow(selected), 1L)
  expect_equal(selected$tmb_parameter, "beta_sd_mu")
  bootstrap <- suppressMessages(confint(
    fit, parm = paste0(keys[[2L]], ":z1"), method = "bootstrap", R = 2L,
    seed = 2026102821L
  ))
  diagnostics <- attr(bootstrap, "bootstrap.diagnostics", exact = TRUE)
  expect_equal(nrow(diagnostics), 2L)
  expect_equal(bootstrap$parm, target)
  expect_true(any(diagnostics$refit_status == "ok"))
})

test_that("Binomial relmat q2 agrees across K, Q, SD order and constant scales", {
  skip_if(identical(Sys.getenv("DRMTMB_Q2_ASSEMBLY_ONLY"), "1"))
  skip_if(identical(Sys.getenv("DRMTMB_Q2_SKIP_COMPARATOR"), "1"))
  skip_on_cran()
  fx <- binomial_relmat_q2_fixture(groups = 32L, repeats = 12L)
  K <- fx$K; Q <- fx$Q
  control <- drm_control(se = FALSE)
  fit <- drmTMB(binomial_relmat_q2_form(K), binomial(), fx$data,
                control = control)
  reverse <- drmTMB(binomial_relmat_q2_form(K, reverse = TRUE),
                    binomial(), fx$data, control = control)
  precision <- drmTMB(binomial_relmat_q2_form(Q = Q),
                      binomial(), fx$data, control = control)
  keys <- c('sd_relmat(id, dpar = "mu", coef = "(Intercept)")',
            'sd_relmat(id, dpar = "mu", coef = "x")')
  for (other in list(reverse, precision)) {
    expect_equal(other$opt$convergence, 0L)
    expect_lte(abs(as.numeric(logLik(other)) - as.numeric(logLik(fit))),
               1e-4)
    expect_identical(names(stats::coef(other, "mu")),
                     names(stats::coef(fit, "mu")))
    expect_lte(max(abs(stats::coef(other, "mu") - stats::coef(fit, "mu"))),
               1e-3)
    for (key in keys) {
      expect_identical(names(stats::coef(other, key)),
                       names(stats::coef(fit, key)))
      expect_lte(max(abs(stats::coef(other, key) - stats::coef(fit, key))),
                 1e-3)
    }
  }
  constant <- drmTMB(binomial_relmat_q2_form(K, constant = TRUE),
                     binomial(), fx$data, control = control)
  base <- drmTMB(bf(y ~ x + relmat(1 + x | id, K = K)),
                 binomial(), fx$data, control = control)
  expect_equal(constant$opt$convergence, 0L)
  expect_equal(base$opt$convergence, 0L)
  expect_lte(abs(as.numeric(logLik(constant)) - as.numeric(logLik(base))),
             1e-4)
  expect_identical(names(stats::coef(constant, "mu")),
                   names(stats::coef(base, "mu")))
  expect_lte(max(abs(stats::coef(constant, "mu") - stats::coef(base, "mu"))),
             1e-3)
  base_sd <- base$obj$report(base$tmb_state$last.par.best)$sd_phylo
  expect_length(base$sdpars$mu, 2L)
  expect_true(all(nzchar(names(base$sdpars$mu))))
  expect_lte(max(abs(unname(base$sdpars$mu) - unname(base_sd))), 1e-8)
  constant_sd <- exp(vapply(keys, function(key) {
    stats::coef(constant, key)[["(Intercept)"]]
  }, numeric(1L)))
  expect_lte(max(abs(unname(constant_sd) - unname(base_sd))), 1e-3)
  reverse_marginal <- simulate(reverse, nsim = 1L, seed = 2026102820L)
  expect_true(all(reverse_marginal[[1L]] %in% c(0, 1)))
  metrics_dir <- Sys.getenv("DRMTMB_Q2_METRICS_DIR")
  if (nzchar(metrics_dir)) {
    dir.create(metrics_dir, recursive = TRUE, showWarnings = FALSE)
    summarize <- function(object) list(
      convergence = object$opt$convergence,
      pdHess = object$sdr$pdHess,
      nll = -as.numeric(logLik(object)),
      fixed_gradient = max(abs(object$obj$gr(object$opt$par))),
      mu = stats::coef(object, "mu"))
    saveRDS(list(K = summarize(fit), reverse = summarize(reverse),
                 Q = summarize(precision), constant = summarize(constant),
                 base = summarize(base),
                 K_sd0 = stats::coef(fit, keys[[1L]]),
                 K_sd1 = stats::coef(fit, keys[[2L]]),
                 reverse_sd0 = stats::coef(reverse, keys[[1L]]),
                 reverse_sd1 = stats::coef(reverse, keys[[2L]]),
                 Q_sd0 = stats::coef(precision, keys[[1L]]),
                 Q_sd1 = stats::coef(precision, keys[[2L]]),
                 constant_sd = constant_sd,
                 base_sd = base_sd,
                 base_public_sd = base$sdpars$mu),
            file.path(metrics_dir, "comparators.rds"))
  }
})

