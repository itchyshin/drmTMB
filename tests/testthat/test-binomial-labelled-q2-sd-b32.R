# Batch 32 (native Binomial): labelled intercept-plus-slope structured q2 SD
# blocks, `animal(1 + x | p | g, A = A)` (logit, probit, cloglog) and
# `phylo(1 + x | p | g, tree = tree)` (logit), one coefficient-specific SD
# formula per coefficient. The labelled block estimates ONE cross-coefficient
# correlation, rho = 0.999999 tanh(eta_cor); the unit-scale fields are
# N(0, R (x) K) and the SDs scale them multiplicatively (the NB2/Gamma prior).
#
# Oracle: base-R dense Laplace (helper-sb26-oracle.R, no drmTMB code) at the
# FITTED parameters including the fitted rho, with a hand Henderson A from an
# inbred pedigree (animal) or cov2cor(ape::vcv(tree)) (phylo, compared with the
# package tip-covariance helper). Kernel rows are in the reverse of the data
# level order, and the two SD predictors are non-palindromic shuffled
# selectors. Each emulated bug must move the oracle by > 0.1 against a 1e-4
# logLik tolerance. Scope: likelihood assembly, alignment and the estimated
# correlation at fixed seeds; no calibration, coverage or parity claim.

b32bn_fixture <- function(kind, link, seed, rho = 0.7, repeats = 30L,
                          n_tip = 40L) {
  set.seed(seed)
  f <- b31nb_kernel(kind, n_tip = n_tip)
  lev <- f$levels
  Ks <- f$K[lev, lev]
  m <- b31nb_mult(link)
  a0 <- c(log(1.1 * m), 0.7)
  a1 <- c(log(0.9 * m), -0.7)
  z0 <- b31nb_selector(lev)
  z1 <- b31nb_selector(lev)
  L <- t(chol(Ks))
  e0 <- drop(L %*% stats::rnorm(f$n))
  e1 <- drop(L %*% stats::rnorm(f$n))
  u0 <- e0 * exp(a0[[1L]] + a0[[2L]] * z0)
  u1 <- (rho * e0 + sqrt(1 - rho^2) * e1) * exp(a1[[1L]] + a1[[2L]] * z1)
  chr <- rep(lev, each = repeats)
  x <- rep(seq(-1.2, 1.2, length.out = repeats), times = f$n)
  eta <- -0.1 + 0.3 * x + u0[match(chr, lev)] + x * u1[match(chr, lev)]
  dat <- data.frame(
    x = x, g = factor(chr, levels = lev), z0 = unname(z0[chr]),
    z1 = unname(z1[chr]),
    y = stats::rbinom(length(chr), 1L, stats::make.link(link)$linkinv(eta))
  )
  c(f, list(data = dat, z0 = z0, z1 = z1, link = link, rho_true = rho))
}

b32bn_fit <- function(fx, label = "p", provider = "A") {
  A <- fx$K
  Ainv <- if (fx$kind == "animal") solve(fx$K) else NULL
  pedigree <- fx$pedigree
  tree <- fx$tree
  lab <- if (is.null(label)) "" else paste0(label, " | ")
  term <- if (fx$kind == "animal") {
    switch(provider,
      A = sprintf("animal(1 + x | %sg, A = A)", lab),
      Ainv = sprintf("animal(1 + x | %sg, Ainv = Ainv)", lab),
      pedigree = sprintf("animal(1 + x | %sg, pedigree = pedigree)", lab))
  } else {
    sprintf("phylo(1 + x | %sg, tree = tree)", lab)
  }
  level <- if (fx$kind == "animal") "animal" else "phylogenetic"
  fml <- eval(parse(text = sprintf(paste0(
    "bf(y ~ x + %s, sd(g, level = \"%s\", dpar = \"mu\", coef = \"(Intercept)\") ~ z0, ",
    "sd(g, level = \"%s\", dpar = \"mu\", coef = \"x\") ~ z1)"
  ), term, level, level)))
  drmTMB(fml, family = stats::binomial(link = fx$link), data = fx$data,
         control = drm_control(se = FALSE))
}

b32bn_rho <- function(fit, kind, label = "p") {
  key <- sprintf("cor(mu:(Intercept),mu:x | %s | g)", label)
  provider <- if (kind == "animal") "animal" else "phylo"
  expect_named(fit$corpars[[provider]], key)
  unname(fit$corpars[[provider]][[key]])
}

b32bn_keys <- function(kind) {
  level <- if (kind == "animal") "sd_animal" else "sd_phylo"
  c(sprintf("%s(g, dpar = \"mu\", coef = \"(Intercept)\")", level),
    sprintf("%s(g, dpar = \"mu\", coef = \"x\")", level))
}

b32bn_check <- function(fx, info, gap = 0.1) {
  fit <- b32bn_fit(fx)
  expect_identical(fit$opt$convergence, 0L, info = info)
  keys <- b32bn_keys(fx$kind)
  c0 <- coef(fit, keys[[1L]])
  c1 <- coef(fit, keys[[2L]])
  expect_identical(names(c0), c("(Intercept)", "z0"), info = info)
  expect_identical(names(c1), c("(Intercept)", "z1"), info = info)
  rho <- b32bn_rho(fit, fx$kind)
  expect_true(is.finite(rho) && abs(rho) < 1, info = info)
  # The report agrees with the corpars value (rho = 0.999999 tanh(eta)).
  rep_rho <- fit$obj$report(fit$obj$env$last.par.best)$rho_phylo
  expect_equal(rep_rho, rho, tolerance = 1e-8)
  dat <- fx$data
  lev <- fx$levels
  n <- fx$n
  idx <- as.integer(dat$g)
  mu <- coef(fit, "mu")
  eta_fixed <- mu[[1L]] + mu[[2L]] * dat$x
  deriv <- b29b_deriv_binomial(dat$y, fx$link)
  curve <- function(co, z) {
    stats::setNames(unname(exp(co[[1L]] + co[[2L]] * z[lev])), lev)
  }
  s0 <- curve(c0, fx$z0)
  s1 <- curve(c1, fx$z1)
  K0 <- fx$K[lev, lev]
  oracle <- function(a = s0, b = s1, Ks = K0, r = rho) {
    Z <- cbind(sb26_Z(idx, n, a), sb26_Z(idx, n, b, dat$x))
    sb26_laplace(deriv, eta_fixed, Z,
                 kronecker(matrix(c(1, r, r, 1), 2L), Ks))
  }
  ref <- oracle()
  ll <- as.numeric(logLik(fit))
  agree <- abs(ll - ref)
  expect_lt(agree, 1e-4, label = info)
  for (s in list(s0, s1)) {
    expect_gt(stats::sd(log(s)), 0.05, label = paste(info, "SD varies"))
    expect_gt(max(s) / min(s), 1.3, label = paste(info, "SD range"))
    expect_gt(stats::median(s), 0.15, label = paste(info, "median SD"))
  }
  # Fixture validity: the fitted correlation is far from 0, so dropping or
  # flipping it is a real change.
  expect_gt(abs(rho), 0.3, label = paste(info, "fitted |rho|"))
  Kp <- fx$K
  dimnames(Kp) <- list(lev, lev)
  gaps <- c(
    swapped_selector_coefs = abs(oracle(a = curve(c1, fx$z0),
                                        b = curve(c0, fx$z1)) - ref),
    reversed_sd_intercept = abs(oracle(a = sb26_reverse(s0)) - ref),
    reversed_sd_slope = abs(oracle(b = sb26_reverse(s1)) - ref),
    swapped_intercept_slope_sd = abs(oracle(a = s1, b = s0) - ref),
    K_read_by_position = abs(oracle(Ks = Kp) - ref),
    K_times_2 = abs(oracle(Ks = 2 * K0) - ref),
    rho_dropped_to_0 = abs(oracle(r = 0) - ref),
    rho_sign_flipped = abs(oracle(r = -rho) - ref)
  )
  if (fx$kind == "animal") {
    gaps[["cov2cor_K"]] <- abs(oracle(Ks = stats::cov2cor(K0)) - ref)
  } else {
    gaps[["raw_vcv_K"]] <- abs(oracle(Ks = fx$K_raw[lev, lev]) - ref)
  }
  for (nm in names(gaps)) {
    expect_gt(gaps[[nm]], gap, label = paste(info, nm))
  }
  cat(sprintf("B32BN %s | rho_hat %.3f (true %.2f) | agree %.2e | min gap %.3f (%s) | n gaps %d\n",
              info, rho, fx$rho_true, agree, min(gaps),
              names(gaps)[[which.min(gaps)]], length(gaps)))
  # The unlabelled block is nested in the labelled one (rho = 0).
  fit0 <- b32bn_fit(fx, label = NULL)
  expect_length(fit0$corpars, 0L)
  expect_gte(ll, as.numeric(logLik(fit0)) - 1e-6)
  # predict(dpar = ...) returns the fitted per-level SD curves.
  for (j in 1:2) {
    p <- predict(fit, dpar = keys[[j]])
    expect_setequal(names(p), lev)
    expect_equal(unname(p[lev]), unname(list(s0, s1)[[j]]), tolerance = 1e-8,
                 label = paste(info, "predict", keys[[j]]))
  }
  invisible(list(fit = fit, ref = ref, ll = ll, agree = agree, gaps = gaps,
                 rho = rho, s0 = s0, s1 = s1))
}

test_that("phylo tip covariance equals cov2cor(ape::vcv) on the b32 tree", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- b32bn_fixture("phylo", "logit", 32421L, rho = 0.6, repeats = 40L,
                      n_tip = 80L)
  b26sa_check_phylo_cov(fx$tree)
})

test_that("labelled Binomial animal q2 (A): dense Laplace oracle at the fitted rho", {
  skip_on_cran()
  for (link in b31nb_links) {
    fx <- b32bn_fixture("animal", link, 32430L + match(link, b31nb_links))
    b32bn_check(fx, paste("animal q2", link))
  }
})

test_that("labelled Binomial phylo q2 (logit): dense Laplace oracle at the fitted rho", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- b32bn_fixture("phylo", "logit", 32421L, rho = 0.6, repeats = 40L,
                      n_tip = 80L)
  b32bn_check(fx, "phylo q2 logit")
})

test_that("labelled Binomial q2 correlation moves with the data", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (case in list(
    list(kind = "animal", seed = 32431L, n_tip = 40L, repeats = 30L),
    list(kind = "phylo", seed = 32421L, n_tip = 80L, repeats = 40L)
  )) {
    est <- vapply(c(0.6, -0.6), function(rho) {
      fx <- b32bn_fixture(case$kind, "logit", case$seed, rho = rho,
                          repeats = case$repeats, n_tip = case$n_tip)
      fit <- b32bn_fit(fx)
      expect_identical(fit$opt$convergence, 0L, info = case$kind)
      b32bn_rho(fit, case$kind)
    }, numeric(1L))
    cat(sprintf("B32BN rho moves %s | rho_hat(+0.6 data) %.3f | rho_hat(-0.6 data) %.3f\n",
                case$kind, est[[1L]], est[[2L]]))
    expect_gt(est[[1L]], 0.3, label = paste(case$kind, "positive data"))
    expect_lt(est[[2L]], -0.3, label = paste(case$kind, "negative data"))
    expect_gt(est[[1L]] - est[[2L]], 0.8, label = paste(case$kind, "spread"))
  }
})

test_that("labelled Binomial animal q2 gives the same fit from A, Ainv and pedigree", {
  skip_on_cran()
  fx <- b32bn_fixture("animal", "logit", 32431L)
  fit_a <- b32bn_fit(fx, provider = "A")
  for (provider in c("Ainv", "pedigree")) {
    fit_p <- b32bn_fit(fx, provider = provider)
    expect_identical(fit_p$opt$convergence, 0L, info = provider)
    expect_equal(as.numeric(logLik(fit_p)), as.numeric(logLik(fit_a)),
                 tolerance = 1e-6, info = provider)
    expect_equal(b32bn_rho(fit_p, "animal"), b32bn_rho(fit_a, "animal"),
                 tolerance = 1e-4, info = provider)
  }
})

test_that("labelled Binomial q2 marginal and conditional simulation use the fitted rho", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (case in list(
    list(kind = "animal", seed = 32431L, n_tip = 40L, repeats = 30L),
    list(kind = "phylo", seed = 32421L, n_tip = 80L, repeats = 40L)
  )) {
    fx <- b32bn_fixture(case$kind, "logit", case$seed, rho = 0.6,
                        repeats = case$repeats, n_tip = case$n_tip)
    fit <- b32bn_fit(fx)
    rho <- b32bn_rho(fit, case$kind)
    keys <- b32bn_keys(case$kind)
    lev <- fx$levels
    curve <- function(co, z) {
      stats::setNames(unname(exp(co[[1L]] + co[[2L]] * z[lev])), lev)
    }
    s0 <- curve(coef(fit, keys[[1L]]), fx$z0)
    s1 <- curve(coef(fit, keys[[2L]]), fx$z1)
    dat <- fx$data
    # Marginal draws: one fresh structured field per replicate. Per group, the
    # variance of the linear-predictor contribution at the largest x is
    # K_gg (s0^2 + 2 rho s0 s1 x + x^2 s1^2). Pooled over groups the ratio of
    # the sampled to the oracle variance must be within 0.06 of 1 (about four
    # Monte Carlo SE at 3000 draws); each emulated bug must leave that band by
    # more than 0.10. Tolerances fixed before the first run.
    set.seed(32490L)
    rows <- which(dat$x == max(dat$x))
    expect_identical(as.character(dat$g[rows]), lev)
    draws <- vapply(seq_len(3000L), function(i) {
      drmTMB:::drm_ordinary_random_effect_draws(fit)$mu[rows]
    }, numeric(length(rows)))
    emp <- apply(draws, 1L, stats::var)
    xm <- max(dat$x)
    Kd <- diag(fx$K[lev, lev])
    ratio <- function(r = rho, a = s0, b = s1, kd = Kd) {
      sum(emp) / sum(kd * (a^2 + 2 * r * a * b * xm + xm^2 * b^2))
    }
    cat(sprintf("B32BN simulate %s | pooled variance ratio %.3f | rho0 %.3f | flipped %.3f\n",
                case$kind, ratio(), ratio(r = 0), ratio(r = -rho)))
    expect_lt(abs(ratio() - 1), 0.06, label = paste(case$kind, "variance ratio"))
    expect_gt(abs(ratio(r = 0) - 1), 0.10, label = paste(case$kind, "rho 0"))
    expect_gt(abs(ratio(r = -rho) - 1), 0.10, label = paste(case$kind, "rho flipped"))
    if (identical(case$kind, "animal")) {
      expect_gt(abs(ratio(kd = rep(1, length(Kd))) - 1), 0.10,
                label = "cov2cor(K) diagonal")
    }
    marginal1 <- simulate(fit, nsim = 2L, seed = 32491L)
    marginal2 <- simulate(fit, nsim = 2L, seed = 32491L)
    expect_identical(marginal1, marginal2)
    expect_true(all(unlist(marginal1) %in% c(0, 1)))
    conditional <- simulate(fit, nsim = 1L, seed = 32492L, re.form = NULL)
    expect_true(all(conditional[[1L]] %in% c(0, 1)))
  }
})

test_that("labelled Binomial q2 keeps neighbouring routes refused", {
  skip_if_not_installed("ape")
  fx <- b32bn_fixture("animal", "logit", 32431L)
  A <- fx$K
  dat <- fx$data
  ft <- b32bn_fixture("phylo", "logit", 32421L, rho = 0.6, repeats = 4L,
                      n_tip = 20L)
  tree <- ft$tree
  datp <- ft$data
  sdf <- function(level, coef, rhs) {
    sprintf('sd(g, level = "%s", dpar = "mu", coef = "%s") ~ %s', level, coef,
            rhs)
  }
  build <- function(mu, level, data, link = "logit", n_sd = 2L) {
    terms <- c(list(stats::as.formula(mu)),
               lapply(c(sdf(level, "(Intercept)", "z0"),
                        sdf(level, "x", "z1"))[seq_len(n_sd)],
                      stats::as.formula))
    for (k in seq_along(terms)) environment(terms[[k]]) <- environment()
    drmTMB:::drm_build_binomial_spec(do.call(bf, terms), data, link = link)
  }
  # Admitted: the spec builds and carries the labelled correlation parameter.
  spec <- build("y ~ x + animal(1 + x | p | g, A = A)", "animal", dat)
  expect_identical(spec$tmb_data$has_phylo_mu_q2_covariance, 1L)
  spec <- build("y ~ x + phylo(1 + x | p | g, tree = tree)", "phylogenetic",
                datp)
  expect_identical(spec$tmb_data$has_phylo_mu_q2_covariance, 1L)
  # Unlabelled blocks keep the independent-field prior.
  spec <- build("y ~ x + animal(1 + x | g, A = A)", "animal", dat)
  expect_identical(spec$tmb_data$has_phylo_mu_q2_covariance, 0L)
  # Still refused: one SD formula only, non-logit labelled phylo, labelled
  # relmat and spatial.
  expect_error(build("y ~ x + animal(1 + x | p | g, A = A)", "animal", dat,
                     n_sd = 1L), "unlabelled q1")
  for (link in c("probit", "cloglog")) {
    expect_error(build("y ~ x + phylo(1 + x | p | g, tree = tree)",
                       "phylogenetic", datp, link = link), "unlabelled q1")
  }
  K <- fx$K
  expect_error(build("y ~ x + relmat(1 + x | p | g, K = K)", "relmat", dat),
               "unlabelled q1")
})
