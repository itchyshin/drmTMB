# G4 save/refit semantics for predictor-dependent random-effect SDs.
#
# One representative fit per family, mixing ordinary and structured routes and
# including one intercept-plus-slope (q2) route:
#   Gaussian  ordinary  (1 | id),                        sd(id) ~ w
#   Poisson   ordinary  (1 | id),                        sd(id) ~ w
#   Binomial  relmat(1 | id, K),   shuffled non-unit K,  sd(id, level = "relmat") ~ w
#   NB2       animal(1 | id, A),   shuffled non-unit A,  sd(id, level = "animal") ~ w
#   Gamma     phylo(1 + x | id),   q2, one SD per coef   sd(id, level = "phylogenetic", coef = .) ~ s_k
#
# Checks per fit, each stated before the first run:
#   (a) saveRDS()/readRDS() round trip: coef(), logLik(), predict(dpar = SD),
#       predict(dpar = SD, newdata = group-level rows) are identical, and the
#       newdata prediction equals exp(a0 + a1 * covariate) from the coefficients
#       (an independent formula); a reversed-sign formula must differ.
#   (b) update(fit, data = same data) returns the same estimates (relative
#       tolerance 1e-6); update() on data with the group-level SD covariate
#       reversed must NOT, so the check is sensitive.
#   (c) refit on one seeded simulate(fit, re.form = NA) draw converges and has
#       the same coefficient and SD target names.
#   (d) confint() on an SD coefficient: Wald works (finite, brackets the
#       estimate); profile is finite and brackets the estimate, or carries an
#       explicit conf.status and message (never a silent NA).
#   (e) the fitted object stores the SD design (X_list / design matrix with
#       the covariate column and one row per group) and, for structured routes,
#       the provider kernel needed to predict.
# Tolerances are fixed and were not loosened. Not covered: calibration,
# coverage, the Julia engine, and constant-SD equivalence (covered by the
# per-family files).

g4_kernel <- function(ids, seed_offset = 0L) {
  G <- length(ids)
  d <- seq(0.8, 1.5, length.out = G)[sample.int(G)]
  C <- 0.4^abs(outer(seq_len(G), seq_len(G), `-`))
  K <- diag(d) %*% C %*% diag(d)  # non-unit diagonal
  dimnames(K) <- list(ids, ids)
  perm <- sample.int(G)           # handed over in shuffled order
  K[perm, perm]
}

# Returns an environment holding the data and the objects the fit call refers
# to, so that update() can be evaluated in it after a save or in a later test.
g4_env <- function(route, groups = 24L, repeats = 10L, seed = 20261101L) {
  set.seed(seed)
  ids <- sprintf("g%02d", seq_len(groups))
  gi <- rep(seq_len(groups), each = repeats)
  w_g <- stats::setNames(rep(c(-1, 1), length.out = groups)[sample.int(groups)], ids)
  x <- rep(seq(-1, 1, length.out = repeats), groups)
  env <- new.env(parent = topenv(environment(drmTMB)))
  sd_g <- exp(log(0.7) + 0.5 * w_g)
  if (route %in% c("gaussian", "poisson")) {
    b <- stats::rnorm(groups, 0, sd_g)
    eta <- 0.2 + 0.4 * x + b[gi]
    y <- if (route == "gaussian") eta + 0.4 * stats::rnorm(length(eta)) else
      stats::rpois(length(eta), exp(eta))
  } else if (route %in% c("binomial", "nbinom2")) {
    K <- g4_kernel(ids)
    b <- drop(t(chol(K[ids, ids])) %*% stats::rnorm(groups)) * sd_g
    names(b) <- ids
    eta <- (if (route == "binomial") 0 else 1) + 0.4 * x + b[gi]
    y <- if (route == "binomial") stats::rbinom(length(eta), 1L, stats::plogis(eta)) else
      stats::rnbinom(length(eta), size = 1 / 0.5^2, mu = exp(eta))
    env$K <- K
  } else if (route == "gamma") {
    tree <- ape::rcoal(groups)
    tree$tip.label <- sample(ids)
    K <- ape::vcv(tree)
    K <- (K / max(diag(K)))[ids, ids]
    L <- t(chol(K))
    s1 <- stats::setNames(rep(c(-1, 1), each = groups / 2L), ids)
    b0 <- drop(L %*% stats::rnorm(groups)) * exp(log(0.5) + 0.3 * w_g)
    b1 <- drop(L %*% stats::rnorm(groups)) * exp(log(0.4) - 0.3 * s1)
    eta <- 0.3 + 0.2 * x + b0[gi] + x * b1[gi]
    y <- stats::rgamma(length(eta), shape = 0.4^-2, rate = 0.4^-2 / exp(eta))
    env$tree <- tree
    env$K_true <- K
  }
  dat <- data.frame(y = y, x = x, id = factor(ids[gi], levels = ids),
                    w = unname(w_g[gi]))
  if (route == "gamma") dat$s1 <- unname(s1[gi])
  env$dat <- dat
  env$ids <- ids
  env$route <- route
  env
}

g4_fit_expr <- function(route) {
  switch(
    route,
    gaussian = quote(drmTMB(bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ w),
                            data = dat)),
    poisson = quote(drmTMB(bf(y ~ x + (1 | id), sd(id) ~ w), poisson(),
                           data = dat)),
    binomial = quote(drmTMB(
      bf(y ~ x + relmat(1 | id, K = K), sd(id, level = "relmat") ~ w),
      binomial(), data = dat)),
    nbinom2 = quote(drmTMB(
      bf(y ~ x + animal(1 | id, A = K), sigma ~ 1,
         sd(id, level = "animal") ~ w), nbinom2(), data = dat)),
    gamma = quote(drmTMB(
      bf(y ~ x + phylo(1 + x | id, tree = tree), sigma ~ 1,
         sd(id, level = "phylogenetic", coef = "(Intercept)") ~ w,
         sd(id, level = "phylogenetic", coef = "x") ~ s1),
      Gamma(link = "log"), data = dat))
  )
}

# SD target keys and the group-level covariate each uses.
g4_keys <- function(route) {
  switch(
    route,
    gaussian = list("sd(id)" = "w"),
    poisson = list("sd(id)" = "w"),
    binomial = list("sd_relmat(id)" = "w"),
    nbinom2 = list("sd_animal(id)" = "w"),
    gamma = list(
      'sd_phylo(id, dpar = "mu", coef = "(Intercept)")' = "w",
      'sd_phylo(id, dpar = "mu", coef = "x")' = "s1"
    )
  )
}

g4_fit <- function(env) eval(g4_fit_expr(env$route), env)

g4_update <- function(fit, env, data, ...) {
  newdat <- data
  env$newdat <- data
  cl <- stats::update(fit, data = newdat, ..., evaluate = FALSE)
  eval(cl, env)
}

g4_rds <- function(fit) {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(fit, path)
  readRDS(path)
}

g4_routes <- c("gaussian", "poisson", "binomial", "nbinom2", "gamma")

g4_cache <- new.env()
g4_get <- function(route) {
  if (is.null(g4_cache[[route]])) {
    env <- g4_env(route)
    fit <- g4_fit(env)
    stopifnot(fit$opt$convergence == 0L)
    g4_cache[[route]] <- list(env = env, fit = fit)
  }
  g4_cache[[route]]
}

test_that("G4 (a): saveRDS/readRDS preserves estimates and SD predictions", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (route in g4_routes) {
    obj <- g4_get(route)
    fit <- obj$fit
    back <- g4_rds(fit)
    info <- paste("route", route)
    expect_identical(coef(back), coef(fit), info = info)
    expect_identical(as.numeric(logLik(back)), as.numeric(logLik(fit)),
                     info = info)
    grid <- data.frame(w = c(-1, 0, 0.5, 1), s1 = c(1, -1, 0.25, 0))
    for (key in names(g4_keys(route))) {
      covariate <- g4_keys(route)[[key]]
      expect_identical(predict(back, dpar = key), predict(fit, dpar = key),
                       info = info)
      p_new <- predict(fit, dpar = key, newdata = grid)
      expect_identical(predict(back, dpar = key, newdata = grid), p_new,
                       info = info)
      a <- coef(fit, key)
      expected <- exp(a[[1L]] + a[[2L]] * grid[[covariate]])
      expect_equal(unname(p_new), expected, tolerance = 1e-7, info = info)
      wrong <- exp(a[[1L]] - a[[2L]] * grid[[covariate]])
      expect_gt(max(abs(unname(p_new) - wrong)), 1e-3)
    }
  }
})

test_that("G4 (b): update() on the same data refits to the same estimates", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (route in g4_routes) {
    obj <- g4_get(route)
    fit <- obj$fit
    same <- g4_update(fit, obj$env, obj$env$dat)
    info <- paste("route", route)
    expect_equal(same$opt$convergence, 0L, info = info)
    expect_identical(names(coef(same)), names(coef(fit)), info = info)
    expect_equal(unname(coef(same)), unname(coef(fit)), tolerance = 1e-6,
                 info = info)
    expect_equal(as.numeric(logLik(same)), as.numeric(logLik(fit)),
                 tolerance = 1e-6, info = info)
    # Sensitivity: the same call on data with the covariate reversed differs.
    flipped <- obj$env$dat
    flipped$w <- -flipped$w
    other <- g4_update(fit, obj$env, flipped)
    key <- names(g4_keys(route))[[1L]]
    expect_gt(abs(coef(other, key)[[2L]] - coef(fit, key)[[2L]]), 0.05)
  }
})

test_that("G4 (c): a refit on one marginal simulate() draw keeps the SD targets", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (route in g4_routes) {
    obj <- g4_get(route)
    fit <- obj$fit
    sim <- suppressMessages(simulate(fit, nsim = 1L, seed = 2026110121L,
                                     re.form = NA))
    expect_equal(nrow(sim), nrow(obj$env$dat))
    simdat <- obj$env$dat
    simdat$y <- sim$sim_1
    refit <- g4_update(fit, obj$env, simdat)
    info <- paste("route", route)
    expect_equal(refit$opt$convergence, 0L, info = info)
    expect_identical(names(coef(refit)), names(coef(fit)), info = info)
    for (key in names(g4_keys(route))) {
      expect_identical(names(coef(refit, key)), names(coef(fit, key)),
                       info = info)
      expect_true(all(is.finite(coef(refit, key))), info = info)
      expect_identical(names(predict(refit, dpar = key)),
                       names(predict(fit, dpar = key)), info = info)
    }
    expect_true(is.finite(as.numeric(logLik(refit))), info = info)
  }
})

test_that("G4 (d): confint() for an SD coefficient is Wald-finite; profile is explicit", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (route in g4_routes) {
    obj <- g4_get(route)
    fit <- obj$fit
    targets <- profile_targets(fit)
    rows <- targets[grepl("^fixef:sd", targets$parm) &
                      !grepl("\\(Intercept\\)$", targets$parm), , drop = FALSE]
    expect_gte(nrow(rows), 1L)
    parm <- rows$parm[[1L]]
    info <- paste("route", route, parm)
    ci <- stats::confint(fit, parm = parm)
    expect_equal(nrow(ci), 1L, info = info)
    expect_identical(ci$method, "wald", info = info)
    expect_true(is.finite(ci$lower) && is.finite(ci$upper), info = info)
    est <- coef(fit, names(g4_keys(route))[[1L]])[[2L]]
    expect_true(ci$lower < est && est < ci$upper, info = info)
    expect_identical(ci$tmb_parameter, rows$tmb_parameter[[1L]], info = info)
    prof <- stats::confint(fit, parm = parm, method = "profile")
    expect_identical(prof$method, "profile", info = info)
    finite <- is.finite(prof$lower) && is.finite(prof$upper)
    # Either a finite profile interval that brackets the estimate, or an
    # explicit status (observed: "clamp_limited" for Binomial relmat and NB2
    # animal on this fixture); never a silent NA.
    if (finite) {
      expect_true(prof$lower < est && est < prof$upper, info = info)
    } else {
      expect_false(prof$conf.status %in% c("wald", "profile"), info = info)
      expect_false(is.na(prof$profile.message), info = info)
    }
  }
  fit <- g4_get("gaussian")$fit
  expect_error(stats::confint(fit, parm = "sd(nonexistent):w"))
})

test_that("G4 (e): the fit stores the SD design and the provider kernel", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (route in g4_routes) {
    obj <- g4_get(route)
    structured <- !route %in% c("gaussian", "poisson")
    for (fit in list(obj$fit, g4_rds(obj$fit))) {
      info <- paste("route", route)
      scale <- if (structured) fit$model$random_scale$phylo else
        fit$model$random_scale$mu
      expect_false(is.null(scale), info = info)
      expect_identical(names(scale$X_list), names(g4_keys(route)), info = info)
      for (k in seq_along(g4_keys(route))) {
        covariate <- g4_keys(route)[[k]]
        X <- scale$X_list[[k]]
        expect_true(covariate %in% colnames(X), info = info)
        expect_identical(nrow(X), length(obj$env$ids), info = info)
        truth <- c(tapply(obj$env$dat[[covariate]], obj$env$dat$id, `[`, 1L))
        expect_equal(unname(X[, covariate]),
                     unname(truth[scale$group_levels_list[[k]]]), info = info)
      }
      if (structured) {
        pr <- fit$model$structured$phylo_mu$precision
        tip <- if (!is.null(pr$tip_node_index)) pr$tip_node_index else
          pr$species_node_index
        ids <- obj$env$ids
        covariance <- solve(as.matrix(pr$precision))[tip[ids], tip[ids]]
        truth <- if (route == "gamma") obj$env$K_true else obj$env$K
        expect_equal(unname(covariance), unname(truth[ids, ids]),
                     tolerance = 1e-8, info = info)
        if (route != "gamma") {
          # The kernel was non-unit diagonal and shuffled: both must survive.
          expect_gt(diff(range(diag(covariance))), 0.1)
          expect_false(identical(rownames(truth), ids))
        }
      }
    }
  }
})
