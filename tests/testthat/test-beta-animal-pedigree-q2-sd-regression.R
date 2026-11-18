# Independent pedigree covariance; no package pedigree builder in the DGP.
beta_pedigree_q2_sd_fixture <- function() {
  set.seed(2026102707L)
  nf <- 16L; no <- 4L; nr <- 20L
  sire <- sprintf("sire%02d", seq_len(nf)); dam <- sprintf("dam%02d", seq_len(nf))
  offspring <- sprintf("offspring%03d", seq_len(nf * no))
  pedigree <- data.frame(id = c(sire, dam, offspring),
    sire = c(rep(NA_character_, 2L * nf), rep(sire, each = no)),
    dam = c(rep(NA_character_, 2L * nf), rep(dam, each = no)))
  ids <- pedigree$id; n <- length(ids)
  A <- matrix(0, n, n, dimnames = list(ids, ids))
  for (i in seq_len(n)) {
    s <- match(pedigree$sire[i], ids); d <- match(pedigree$dam[i], ids)
    if (i > 1L) for (j in seq_len(i - 1L)) {
      A[i, j] <- A[j, i] <- ((if (is.na(s)) 0 else A[s, j]) +
                            (if (is.na(d)) 0 else A[d, j])) / 2
    }
    A[i, i] <- 1 + if (is.na(s) || is.na(d)) 0 else A[s, d] / 2
  }
  z0 <- setNames(rep(c(-1, 1), length.out = length(offspring)), offspring)
  z1 <- setNames(rep(c(-1, 1), each = length(offspring) / 2L), offspring)
  u0 <- setNames(drop(t(chol(A)) %*% rnorm(n)), ids)
  u1 <- setNames(drop(t(chol(A)) %*% rnorm(n)), ids)
  b0 <- exp(log(.5) + .5 * z0) * u0[offspring]
  b1 <- exp(log(.4) - .5 * z1) * u1[offspring]
  ii <- rep(seq_along(offspring), each = nr)
  x <- rep(seq(-1.2, 1.2, length.out = nr), length(offspring))
  mu <- 1e-12 + (1 - 2e-12) * plogis(.2 + .3*x + b0[ii] + x*b1[ii])
  phi <- .35^-2
  dat <- data.frame(y = rbeta(length(ii), mu*phi, (1-mu)*phi), x = x,
    id = factor(offspring[ii], levels = rev(ids)), z0 = unname(z0[ii]), z1 = unname(z1[ii]))
  stopifnot(all(dat$y > 0 & dat$y < 1), min(mu*phi,(1-mu)*phi) > 1e-8)
  list(data = dat, pedigree = pedigree, A_full = A,
    A = A[rev(offspring), rev(offspring)], z0 = z0, z1 = z1,
    ancestors = c(sire, dam), offspring = offspring)
}

beta_pedigree_q2_sd_form <- function(pedigree = NULL, A = NULL, Ainv = NULL) {
  mu <- if (!is.null(pedigree)) y ~ x + animal(1 + x | id, pedigree = pedigree) else
    if (!is.null(Ainv)) y ~ x + animal(1 + x | id, Ainv = Ainv) else
      y ~ x + animal(1 + x | id, A = A)
  environment(mu) <- environment()
  bf(mu, sigma ~ 1,
    sd(id, level = "animal", coef = "(Intercept)") ~ z0,
    sd(id, level = "animal", coef = "x") ~ z1)
}

beta_pedigree_q2_sd_oracle <- function(fit, fx) {
  d <- fx$data; ids <- rownames(fx$A); n <- length(ids)
  P <- kronecker(diag(2L), solve(fx$A))
  ii <- match(as.character(d$id), ids)
  keys <- c('sd_animal(id, dpar = "mu", coef = "(Intercept)")',
            'sd_animal(id, dpar = "mu", coef = "x")')
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
      as.numeric(determinant(fx$A, logarithm = TRUE)$modulus)
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

test_that("Beta pedigree two-field SDs preserve ancestors and observed covariance", {
  fx <- beta_pedigree_q2_sd_fixture(); pedigree <- fx$pedigree
  spec <- drmTMB:::drm_build_beta_ls_spec(beta_pedigree_q2_sd_form(pedigree), fx$data)
  expect_identical(spec$tmb_data$has_sd_phylo_coef_model, 1L)
  expect_identical(spec$structured$phylo_mu$structure, "pedigree")
  n <- spec$structured$phylo_mu$n_re; nodes <- spec$structured$phylo_mu$node_labels
  expect_setequal(nodes, fx$pedigree$id)
  par <- spec$start; par$u_phylo <- seq_len(2L*n)/n
  par$beta_sd_mu <- c(log(.5), .5, log(.4), -.5)
  re <- drmTMB:::split_tmb_random_effects(par, spec)$animal_mu
  expect_equal(unname(re$latent), par$u_phylo)
  for (k in 1:2) expect_true(all(is.na(re$terms[[k]][fx$ancestors])))
  expect_equal(unname(re$terms[[1L]][fx$offspring]),
    unname(par$u_phylo[match(fx$offspring,nodes)]*exp(log(.5)+.5*fx$z0)))
  expect_equal(unname(re$terms[[2L]][fx$offspring]),
    unname(par$u_phylo[n+match(fx$offspring,nodes)]*exp(log(.4)-.5*fx$z1)))
})

test_that("Beta pedigree two-field SD fit integrates unobserved ancestors", {
  skip_on_cran()
  fx <- beta_pedigree_q2_sd_fixture()
  fit <- drmTMB(beta_pedigree_q2_sd_form(fx$pedigree), family = beta_family(),
    data = fx$data, control = drm_control(se = FALSE))
  expect_equal(fit$opt$convergence, 0L)
  keys <- c('sd_animal(id, dpar = "mu", coef = "(Intercept)")',
            'sd_animal(id, dpar = "mu", coef = "x")')
  expect_lt(abs(coef(fit, keys[1])[["z0"]]-.5), .4)
  expect_lt(abs(coef(fit, keys[2])[["z1"]]+.5), .4)
  for (k in 1:2) {
    z <- if (k == 1) fx$z0 else fx$z1
    a <- coef(fit, keys[k]); predicted <- predict(fit, dpar = keys[k])
    expect_setequal(names(predicted), fx$offspring)
    expect_equal(unname(predicted), unname(exp(a[1]+a[2]*z[names(predicted)])), tolerance=1e-10)
  }
  oracle <- beta_pedigree_q2_sd_oracle(fit, fx)
  expect_lt(oracle$gradient, 1e-5)
  expect_lt(oracle$mode_difference, 1e-6)
  expect_lt(oracle$derivative_error, 1e-4)
  expect_lt(oracle$hessian_error, 2e-4)
  expect_lt(abs(-as.numeric(logLik(fit))-oracle$nll), 1e-4)
  eta <- as.numeric(predict(fit,type="link",re.form=NULL))
  expect_lt(max(abs(eta-oracle$eta)), 1e-4)
  A <- fx$A_full[rev(rownames(fx$A_full)),rev(rownames(fx$A_full))]
  Ainv <- solve(A); Ainv <- Ainv[rev(rownames(Ainv)),rev(rownames(Ainv))]
  for (form in list(beta_pedigree_q2_sd_form(A=A),beta_pedigree_q2_sd_form(Ainv=Ainv))) {
    other <- drmTMB(form,family=beta_family(),data=fx$data,control=drm_control(se=FALSE))
    expect_equal(other$opt$convergence,0L)
    expect_lt(abs(as.numeric(logLik(other))-as.numeric(logLik(fit))),1e-4)
    for (key in keys) expect_lt(max(abs(coef(other,key)-coef(fit,key))),1e-4)
    expect_lt(max(abs(as.numeric(predict(other,type="link",re.form=NULL))-eta)),1e-4)
  }
  saved <- tempfile(fileext=".rds"); on.exit(unlink(saved),add=TRUE)
  saveRDS(fit,saved)
  expect_equal(predict(readRDS(saved),dpar=keys[1]),predict(fit,dpar=keys[1]))
})
