# Binomial (logit, Bernoulli) phylo(1 + x | id) and spatial(1 + x | id) with
# one predictor-dependent SD formula per coefficient. Native TMB route.
# Oracles are written here and do not call drmTMB covariance helpers:
# a hand-built tree covariance and a hand-built exponential kernel.

bpsq2_fixture <- function(provider, groups = 64L, repeats = 30L) {
  set.seed(if (identical(provider, "phylo")) 2026110101L else 2026110102L)
  ids <- sprintf("site%03d", seq_len(groups))
  z0 <- stats::setNames(rep(c(-1, 1), length.out = groups), ids)
  z1 <- stats::setNames(rep(c(-1, 1), each = groups / 2L), ids)
  tree <- coords <- NULL
  if (identical(provider, "phylo")) {
    # Balanced ultrametric tree with level-specific internal edges. The
    # package scales a tree to a correlation matrix, so the diagonal is 1.
    levels_n <- as.integer(round(log2(groups)))
    edge <- c(0.3, 0.2, 0.15, 0.1, 0.05)[seq_len(levels_n - 1L)]
    level_of <- function(n) as.integer(round(log2(groups / n)))
    tip_len <- rep(1.5, groups)
    newick <- function(index, root = FALSE) {
      if (length(index) == 1L) {
        return(paste0(ids[index], ":", format(tip_len[index], digits = 10)))
      }
      half <- length(index) / 2L
      paste0("(", newick(index[seq_len(half)]), ",",
             newick(index[half + seq_len(half)]), ")",
             if (root) ";" else paste0(":", edge[level_of(length(index))]))
    }
    tree <- ape::read.tree(text = newick(seq_len(groups), TRUE))
    bits <- lapply(0:(groups - 1L), function(i)
      rev(as.integer(intToBits(i))[seq_len(levels_n)]))
    internal <- sum(edge)
    height <- internal + max(tip_len)
    K <- matrix(0, groups, groups, dimnames = list(ids, ids))
    for (i in seq_len(groups)) for (j in seq_len(groups)) {
      shared <- if (i == j) internal + tip_len[i] else
        sum(edge[seq_len(which(bits[[i]] != bits[[j]])[1L] - 1L)])
      K[i, j] <- shared / height
    }
  } else {
    coords <- as.matrix(expand.grid(easting = 0:7, northing = 0:7))[
      seq_len(groups), , drop = FALSE]
    rownames(coords) <- ids
    d <- sqrt(outer(coords[, 1], coords[, 1], "-")^2 +
                outer(coords[, 2], coords[, 2], "-")^2)
    range <- stats::median(d[upper.tri(d) & d > 0])
    K <- exp(-d / range)
    diag(K) <- diag(K) + 1e-6
    dimnames(K) <- list(ids, ids)
  }
  b0 <- exp(log(0.7) + 0.5 * z0) * drop(t(chol(K)) %*% stats::rnorm(groups))
  b1 <- exp(log(0.6) - 0.5 * z1) * drop(t(chol(K)) %*% stats::rnorm(groups))
  ii <- rep(seq_len(groups), each = repeats)
  x <- rep(seq(-1.2, 1.2, length.out = repeats), groups)
  eta <- 0.2 + 0.3 * x + b0[ii] + x * b1[ii]
  dat <- data.frame(y = stats::rbinom(length(ii), 1L, stats::plogis(eta)),
                    x = x, id = factor(ids[ii], levels = rev(ids)),
                    z0 = unname(z0[ii]), z1 = unname(z1[ii]))
  list(provider = provider, data = dat, tree = tree,
       coords = if (is.null(coords)) NULL else coords[rev(ids), , drop = FALSE],
       K = K, z0 = z0, z1 = z1)
}

bpsq2_level <- function(provider) {
  if (identical(provider, "phylo")) "phylogenetic" else "spatial"
}

bpsq2_keys <- function(provider) {
  fun <- paste0("sd_", provider)
  c(sprintf('%s(id, dpar = "mu", coef = "(Intercept)")', fun),
    sprintf('%s(id, dpar = "mu", coef = "x")', fun))
}

# provider_arg is a tree or a coordinate matrix; the formula refers to it as
# `tree` or `coords` in the calling frame.
bpsq2_form <- function(provider, provider_arg, constant = FALSE,
                       reverse = FALSE, none = FALSE) {
  tree <- coords <- provider_arg
  layer <- if (identical(provider, "phylo")) {
    quote(phylo(1 + x | id, tree = tree))
  } else {
    quote(spatial(1 + x | id, coords = coords))
  }
  mu <- stats::as.formula(call("~", quote(y), call("+", quote(x), layer)))
  environment(mu) <- environment()
  if (none) return(bf(mu))
  lvl <- bpsq2_level(provider)
  f0 <- stats::as.formula(sprintf(
    'sd(id, level = "%s", coef = "(Intercept)") ~ %s', lvl,
    if (constant) "1" else "z0"), env = environment())
  f1 <- stats::as.formula(sprintf(
    'sd(id, level = "%s", coef = "x") ~ %s', lvl,
    if (constant) "1" else "z1"), env = environment())
  if (reverse) bf(mu, f1, f0) else bf(mu, f0, f1)
}

bpsq2_arg <- function(fx) if (identical(fx$provider, "phylo")) fx$tree else fx$coords

# Dense Laplace marginal likelihood of the Bernoulli-logit model with the
# latent fields u ~ N(0, I2 (x) K) and eta = X b + s0[i] u0[i] + x s1[i] u1[i].
# scale0 and scale1 are named by site so that bugs can be emulated.
bpsq2_oracle <- function(fit, fx, scale0, scale1) {
  d <- fx$data
  ids <- rownames(fx$K)
  n <- length(ids)
  P <- kronecker(diag(2L), solve(fx$K))
  ii <- match(as.character(d$id), ids)
  B <- matrix(0, nrow(d), 2L * n)
  B[cbind(seq_len(nrow(d)), ii)] <- scale0[ids][ii]
  B[cbind(seq_len(nrow(d)), n + ii)] <- d$x * scale1[ids][ii]
  eta_fixed <- drop(stats::model.matrix(~ x, d) %*% stats::coef(fit, "mu"))
  joint <- function(u) {
    eta <- eta_fixed + drop(B %*% u)
    -sum(stats::dbinom(d$y, 1L, stats::plogis(eta), log = TRUE)) +
      drop(crossprod(u, P %*% u)) / 2 + n * log(2 * pi) +
      as.numeric(determinant(fx$K, logarithm = TRUE)$modulus)
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

bpsq2_fitted_scales <- function(fit, fx) {
  keys <- bpsq2_keys(fx$provider)
  ids <- rownames(fx$K)
  a0 <- stats::coef(fit, keys[[1L]])
  a1 <- stats::coef(fit, keys[[2L]])
  list(s0 = exp(a0[[1L]] + a0[[2L]] * fx$z0[ids]),
       s1 = exp(a1[[1L]] + a1[[2L]] * fx$z1[ids]))
}

test_that("Binomial phylo q2 and spatial q2 map two coefficient SDs", {
  skip_if_not_installed("ape")
  for (provider in c("phylo", "spatial")) {
    fx <- bpsq2_fixture(provider, groups = 32L, repeats = 8L)
    arg <- bpsq2_arg(fx)
    tree <- fx$tree
    coords <- fx$coords
    spec <- drmTMB:::drm_build_binomial_spec(bpsq2_form(provider, arg), fx$data)
    expect_identical(spec$tmb_data$has_sd_phylo_coef_model, 1L)
    expect_identical(spec$structured$phylo_mu$q, 2L)
    expect_identical(drmTMB:::structured_mu_type(spec$structured$phylo_mu),
                     provider)
    expect_length(unique(spec$random_scale$phylo$dpars), 2L)
    expect_match(spec$random_scale$phylo$dpars[[1L]],
                 sprintf("^sd_%s\\(.*coef = \"\\(Intercept\\)\"", provider))
    expect_match(spec$random_scale$phylo$dpars[[2L]], 'coef = "x"')
    expect_true(all(spec$tmb_data$phylo_mu_sd_row_coef >= 0L))
    expect_true(all(spec$tmb_data$phylo_mu_sd_row_coef[, 1L] !=
                      spec$tmb_data$phylo_mu_sd_row_coef[, 2L]))
    expect_true(all(is.na(spec$map$log_sd_phylo)))
    expect_true(all(is.na(spec$map$eta_cor_phylo)))
    # The package precision inverts to the hand-built covariance.
    pr <- spec$structured$phylo_mu$precision
    covariance <- as.matrix(solve(as.matrix(pr$precision)))
    if (identical(provider, "phylo")) {
      tip <- unname(pr$tip_node_index[rownames(fx$K)])
      covariance <- covariance[tip, tip]
    } else {
      ids <- spec$structured$phylo_mu$node_labels
      covariance <- covariance[match(rownames(fx$K), ids),
                               match(rownames(fx$K), ids)]
    }
    expect_equal(unname(covariance), unname(fx$K), tolerance = 1e-8)
    base <- drmTMB:::drm_build_binomial_spec(
      bpsq2_form(provider, arg, none = TRUE), fx$data)
    expect_identical(base$structured$phylo_mu$q, 2L)
    expect_identical(base$tmb_data$has_sd_phylo_coef_model, 0L)
    bad <- spec
    bad$random_scale$phylo$observation_sd_row0_by_coef[1L, 1L] <- -1L
    expect_error(drmTMB:::make_tmb_data(bad), "map every observation")
  }
})

test_that("Binomial phylo q2 and spatial q2 keep neighbouring routes closed", {
  skip_if_not_installed("ape")
  for (provider in c("phylo", "spatial")) {
    fx <- bpsq2_fixture(provider, groups = 16L, repeats = 8L)
    tree <- fx$tree
    coords <- fx$coords
    dat <- fx$data
    lvl <- bpsq2_level(provider)
    layer <- function(lhs = "1 + x", label = NULL) {
      sprintf("%s(%s | %sid, %s)", provider, lhs,
              if (is.null(label)) "" else paste0(label, " | "),
              if (identical(provider, "phylo")) "tree = tree" else
                "coords = coords")
    }
    sdf <- function(coef, rhs) sprintf('sd(id, level = "%s", coef = "%s") ~ %s',
                                       lvl, coef, rhs)
    build <- function(mu, ..., data = dat, link = "logit", weights = NULL) {
      terms <- c(list(stats::as.formula(mu)), list(...))
      terms[-1L] <- lapply(terms[-1L], stats::as.formula)
      environment(terms[[1L]]) <- environment()
      for (k in seq_along(terms)[-1L]) environment(terms[[k]]) <- environment()
      drmTMB:::drm_build_binomial_spec(do.call(bf, terms), data, link = link,
                                       weights = weights)
    }
    s0 <- sdf("(Intercept)", "z0")
    s1 <- sdf("x", "z1")
    mu <- paste("y ~ x +", layer())
    expect_error(build(mu, s1), "one SD formula for each coefficient")
    expect_error(build(mu, sdf("x", "z0"), s1),
                 "one SD formula for each coefficient")
    expect_error(build(mu, sdf("z0", "z0"), s1), "coefficient selector")
    bad <- dat; bad$x <- 0
    expect_error(build(mu, s0, s1, data = bad), "unidentified slope scale")
    bad$x <- 1
    expect_error(build(mu, sdf("(Intercept)", "1"), sdf("x", "1"), data = bad),
                 "not separately identifiable")
    bad <- dat; bad$z0[[1L]] <- -bad$z0[[1L]]
    expect_error(build(mu, s0, s1, data = bad), "constant within")
    bad <- dat; bad$y[[1L]] <- 2
    expect_error(build(mu, s0, s1, data = bad), "0/1")
    expect_error(build(mu, s0, s1, weights = rep(1, nrow(dat))),
                 "unweighted 0/1")
    dat$failure <- 2 - dat$y
    expect_error(build(paste("cbind(y, failure) ~ x +", layer()), s0, s1,
                       data = dat), "unweighted 0/1")
    for (link in c("probit", "cloglog")) {
      expect_error(build(mu, s0, s1, link = link), "intercept-only q1")
    }
    dat$p <- "block"
    # Labelled phylo q2 (logit) is admitted since b32 (see
    # test-binomial-labelled-q2-sd-b32.R); labelled spatial q2 stays refused.
    if (identical(provider, "spatial")) {
      expect_error(build(paste("y ~ x +", layer(label = "p")), s0, s1,
                         data = dat), "unlabelled q1")
    }
    expect_error(build(paste("y ~ x +", layer("1 + x + z0")), s0, s1,
                       data = dat), "only intercept and one-slope")
    expect_error(build(paste("y ~ x + (1 | id) +", layer()), s0, s1,
                       data = dat), "intercept-only q1")
    K <- fx$K
    expect_error(build(paste("y ~ x + relmat(1 | id, K = K) +", layer()), s0,
                       s1, data = dat), "intercept-only q1|structured provider")
    expect_error(
      drmTMB:::drm_build_binomial_spec(
        do.call(bf, c(list(stats::as.formula(mu)), lapply(list(s0, s1),
                                                           stats::as.formula))),
        dat, missing = miss_control(response = "include")),
      "intercept-only q1")
  }
})

test_that("Binomial phylo q2 and spatial q2 match a dense Laplace oracle", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (provider in c("phylo", "spatial")) {
    fx <- bpsq2_fixture(provider)
    arg <- bpsq2_arg(fx)
    keys <- bpsq2_keys(provider)
    control <- drm_control(se = FALSE)
    fit <- drmTMB(bpsq2_form(provider, arg), family = binomial(),
                  data = fx$data, control = control)
    expect_equal(fit$opt$convergence, 0L)
    expect_lt(max(abs(fit$obj$gr(fit$opt$par))), 1e-2)
    sc <- bpsq2_fitted_scales(fit, fx)
    oracle <- bpsq2_oracle(fit, fx, sc$s0, sc$s1)
    expect_true(all(oracle$mode_convergence == 0L))
    expect_lt(diff(range(oracle$mode_objectives)), 1e-7)
    expect_lt(oracle$gradient, 1e-5)
    expect_lt(oracle$score_error, 1e-5)
    expect_lt(oracle$hessian_error, 1e-5)
    expect_lte(abs(-as.numeric(logLik(fit)) - oracle$nll), 1e-4)
    report <- fit$obj$report(fit$tmb_state$last.par.best)
    expect_lte(max(abs(as.numeric(report$eta_mu) - oracle$eta)), 1e-4)
    expect_lte(max(abs(as.numeric(predict(fit, type = "link", re.form = NULL)) -
                         oracle$eta)), 1e-4)
    for (j in 1:2) {
      a <- stats::coef(fit, keys[[j]])
      z <- if (j == 1L) fx$z0 else fx$z1
      p <- predict(fit, dpar = keys[[j]])
      expect_setequal(names(p), rownames(fx$K))
      expect_equal(unname(p), unname(exp(a[[1L]] + a[[2L]] * z[names(p)])),
                   tolerance = 1e-8)
    }
    # Emulated bugs must move the oracle far more than its 1e-4 tolerance.
    ids <- rownames(fx$K)
    swapped <- bpsq2_oracle(fit, fx, sc$s1, sc$s0)
    expect_gt(abs(swapped$nll - oracle$nll), 0.05)
    misaligned <- bpsq2_oracle(fit, fx, stats::setNames(rev(sc$s0), ids), sc$s1)
    expect_gt(abs(misaligned$nll - oracle$nll), 0.05)
    misaligned1 <- bpsq2_oracle(fit, fx, sc$s0, stats::setNames(rev(sc$s1), ids))
    expect_gt(abs(misaligned1$nll - oracle$nll), 0.05)
    # Shuffled structured-provider order and reversed SD formula order.
    if (identical(provider, "phylo")) {
      shuffled <- arg
      shuffled$tip.label <- rev(arg$tip.label)
      is_tip <- shuffled$edge[, 2L] <= length(arg$tip.label)
      shuffled$edge[is_tip, 2L] <- match(
        arg$tip.label[arg$edge[is_tip, 2L]], shuffled$tip.label)
      shuffled <- ape::reorder.phylo(shuffled, "postorder")
    } else {
      set.seed(11L)
      shuffled <- arg[sample(nrow(arg)), , drop = FALSE]
    }
    other <- drmTMB(bpsq2_form(provider, shuffled, reverse = TRUE),
                    family = binomial(), data = fx$data, control = control)
    expect_equal(other$opt$convergence, 0L)
    expect_lte(abs(as.numeric(logLik(other)) - as.numeric(logLik(fit))), 1e-4)
    expect_lte(max(abs(stats::coef(other, "mu") - stats::coef(fit, "mu"))), 1e-3)
    for (key in keys) {
      expect_identical(names(stats::coef(other, key)),
                       names(stats::coef(fit, key)))
      expect_lte(max(abs(stats::coef(other, key) - stats::coef(fit, key))), 1e-3)
    }
    # Constant SD formulas equal the formula-free q2 fit.
    constant <- drmTMB(bpsq2_form(provider, arg, constant = TRUE),
                       family = binomial(), data = fx$data, control = control)
    base <- drmTMB(bpsq2_form(provider, arg, none = TRUE),
                   family = binomial(), data = fx$data, control = control)
    expect_equal(constant$opt$convergence, 0L)
    expect_equal(base$opt$convergence, 0L)
    expect_lte(abs(as.numeric(logLik(constant)) - as.numeric(logLik(base))), 1e-4)
    expect_lte(max(abs(stats::coef(constant, "mu") - stats::coef(base, "mu"))),
               1e-3)
    base_sd <- base$obj$report(base$tmb_state$last.par.best)$sd_phylo
    constant_sd <- exp(vapply(keys, function(key) {
      stats::coef(constant, key)[["(Intercept)"]]
    }, numeric(1L)))
    expect_lte(max(abs(unname(constant_sd) - unname(base_sd))), 1e-3)
    # Round trip and conditional simulation.
    saved <- tempfile(fileext = ".rds")
    saveRDS(fit, saved)
    expect_equal(predict(readRDS(saved), type = "link", re.form = NULL),
                 predict(fit, type = "link", re.form = NULL))
    unlink(saved)
    conditional <- simulate(fit, nsim = 1L, seed = 2026110103L, re.form = NULL)
    expect_true(all(conditional[[1L]] %in% c(0, 1)))
    if (identical(provider, "spatial")) {
      marginal1 <- simulate(fit, nsim = 2L, seed = 2026110104L)
      marginal2 <- simulate(fit, nsim = 2L, seed = 2026110104L)
      expect_identical(marginal1, marginal2)
      sd_by_node <- drmTMB:::drm_binomial_q2_structured_sd_by_node(
        fit, fit$model$structured$phylo_mu)
      expect_identical(colnames(sd_by_node), c("(Intercept)", "x"))
      expect_equal(unname(sd_by_node[ids, 1L]), unname(sc$s0), tolerance = 1e-8)
      expect_equal(unname(sd_by_node[ids, 2L]), unname(sc$s1), tolerance = 1e-8)
    } else {
      # Phylo q2 marginal simulation is admitted (see
      # test-q2-sd-marginal-simulate.R); an unreconstructed correlation stays
      # refused.
      expect_s3_class(simulate(fit, nsim = 1L, seed = 2026110105L),
                      "data.frame")
      extra_cor <- fit
      extra_cor$corpars <- list(mu = c(`cor(mu:(Intercept),mu:x | id)` = 0.3))
      expect_error(simulate(extra_cor, nsim = 1L, re.form = NA),
                   "does not yet support")
    }
  }
})
