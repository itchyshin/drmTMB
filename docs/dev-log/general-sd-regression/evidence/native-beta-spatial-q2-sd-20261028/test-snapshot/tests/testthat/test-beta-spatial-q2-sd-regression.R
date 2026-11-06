# Independently generated fixed exponential coordinate covariance.
beta_spatial_q2_sd_fixture <- function() {
  set.seed(2026102803L)
  n <- 64L; nr <- 20L; ids <- sprintf("site%03d",seq_len(n))
  coords <- as.matrix(expand.grid(easting=0:7,northing=0:7))
  rownames(coords) <- ids
  dx <- outer(coords[,1],coords[,1],"-");dy <- outer(coords[,2],coords[,2],"-")
  distance <- sqrt(dx^2+dy^2)
  range <- median(distance[upper.tri(distance) & distance>0])
  K <- exp(-distance/range);diag(K) <- diag(K)+1e-6
  dimnames(K) <- list(ids,ids)
  z0 <- setNames(rep(c(-1,1),n/2L),ids)
  z1 <- setNames(rep(c(-1,1),each=n/2L),ids)
  b0 <- exp(log(.5)+.5*z0)*drop(t(chol(K))%*%rnorm(n))
  b1 <- exp(log(.4)-.5*z1)*drop(t(chol(K))%*%rnorm(n))
  ii <- rep(seq_len(n),each=nr);x <- rep(seq(-1.2,1.2,length.out=nr),n)
  mu <- 1e-12+(1-2e-12)*plogis(.2+.3*x+b0[ii]+x*b1[ii]);phi <- .35^-2
  data <- data.frame(y=rbeta(length(ii),mu*phi,(1-mu)*phi),x=x,
    id=factor(ids[ii],levels=rev(ids)),z0=unname(z0[ii]),z1=unname(z1[ii]))
  stopifnot(all(is.finite(data$y)),all(data$y>0 & data$y<1),min(mu*phi,(1-mu)*phi)>1e-8)
  list(data=data,coords=coords[rev(ids),,drop=FALSE],K=K,range=range,z0=z0,z1=z1)
}

beta_spatial_q2_sd_form <- function(coords,constant=FALSE,reverse_sd=FALSE) {
  f0 <- as.formula(paste('sd(id, level="spatial", coef="(Intercept)") ~',if(constant) "1" else "z0"),env=environment())
  f1 <- as.formula(paste('sd(id, level="spatial", coef="x") ~',if(constant) "1" else "z1"),env=environment())
  mu <- y ~ x + spatial(1+x|id,coords=coords)
  if(reverse_sd) bf(mu,sigma~1,f1,f0) else bf(mu,sigma~1,f0,f1)
}

beta_spatial_q2_sd_oracle <- function(fit, fx) {
  d <- fx$data; ids <- rownames(fx$K); n <- length(ids)
  P <- kronecker(diag(2L), solve(fx$K))
  ii <- match(as.character(d$id), ids)
  keys <- c('sd_spatial(id, dpar = "mu", coef = "(Intercept)")',
            'sd_spatial(id, dpar = "mu", coef = "x")')
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


test_that("Beta spatial q2 maps coefficient SDs and preserves raw coordinate kernel", {
  fx <- beta_spatial_q2_sd_fixture();coords <- fx$coords
  spec <- drmTMB:::drm_build_beta_ls_spec(beta_spatial_q2_sd_form(coords),fx$data)
  expect_identical(spec$tmb_data$has_sd_phylo_coef_model,1L)
  expect_identical(spec$structured$phylo_mu$q,2L)
  pr <- spec$structured$phylo_mu$precision
  covariance <- solve(as.matrix(pr$precision));ids <- spec$structured$phylo_mu$node_labels
  expect_equal(unname(covariance),unname(fx$K[ids,ids]),tolerance=1e-10)
  expect_equal(diag(covariance),rep(1+1e-6,length(ids)),ignore_attr=TRUE,tolerance=1e-10)
  expect_equal(pr$range,fx$range,tolerance=1e-12)
  expect_true(all(spec$tmb_data$phylo_mu_sd_row_coef>=0L))
  expect_true(all(spec$tmb_data$phylo_mu_sd_row_coef[,1]!=spec$tmb_data$phylo_mu_sd_row_coef[,2]))
  expect_error(drmTMB:::drm_build_beta_ls_spec(bf(y~x+spatial(1+x|id,coords=coords),sigma~1,sd(id,level="spatial",coef="x")~z1),fx$data),"one SD formula")
  expect_error(drmTMB:::drm_build_beta_ls_spec(bf(y~x+spatial(1+x|p|id,coords=coords),sigma~1),fx$data),"unlabelled")
  expect_error(drmTMB:::drm_build_beta_ls_spec(bf(y~x+spatial(0+x|id,coords=coords),sigma~1),fx$data),"intercept.*slope")
  expect_error(drmTMB:::drm_build_beta_ls_spec(bf(y~x+spatial(1+x+z0|id,coords=coords),sigma~1),fx$data),"intercept.*slope")
  expect_error(drmTMB:::drm_build_beta_ls_spec(bf(y~x+spatial(1+x|id,coords=coords)+(1|id),sigma~1),fx$data),"no other random")
  expect_error(drmTMB:::drm_build_beta_ls_spec(bf(y~x+spatial(1+x|id,coords=coords),sigma~1+(1|id)),fx$data),"sigma.*random effects")
  expect_error(drmTMB:::drm_build_beta_ls_spec(bf(y~x+spatial(1+x|id,coords=coords),sigma~1),fx$data,missing=miss_control(response="include")),"complete")
  expect_error(drmTMB:::drm_build_beta_ls_spec(bf(y~x+spatial(1|id,coords=coords),sigma~1),fx$data),"intercept.*slope")
  A <- fx$K
  expect_error(drmTMB:::drm_build_beta_ls_spec(bf(y~x+spatial(1+x|id,coords=coords)+animal(1|id,A=A),sigma~1),fx$data),"only one structured")
  expect_error(drmTMB:::drm_build_beta_ls_spec(bf(y~x,sigma~1+spatial(1+x|id,coords=coords)),fx$data),"spatial|not implemented|unsupported")
  mesh <- list()
  expect_error(drmTMB:::drm_build_beta_ls_spec(bf(y~x+spatial(1+x|id,mesh=mesh),sigma~1),fx$data),"coordinate|mesh")
  n <- spec$structured$phylo_mu$n_re;par <- spec$start
  par$u_phylo <- seq_len(2*n)/n;par$beta_sd_mu <- c(log(.5),.5,log(.4),-.5)
  re <- drmTMB:::split_tmb_random_effects(par,spec)$spatial_mu
  expect_equal(unname(re$latent),par$u_phylo)
  expect_equal(unname(re$terms[[1]][ids]),unname(par$u_phylo[seq_len(n)]*exp(log(.5)+.5*fx$z0[ids])))
  expect_equal(unname(re$terms[[2]][ids]),unname(par$u_phylo[n+seq_len(n)]*exp(log(.4)-.5*fx$z1[ids])))
  bad <- fx$data;bad$z0[1] <- bad$z0[1]+.1
  expect_error(drmTMB:::drm_build_beta_ls_spec(beta_spatial_q2_sd_form(coords),bad),"constant within")
})

test_that("Beta spatial q2 SD fit matches independent coordinate-kernel likelihood", {
  skip_on_cran()
  fx <- beta_spatial_q2_sd_fixture();coords <- fx$coords
  fit <- drmTMB(beta_spatial_q2_sd_form(coords),family=beta_family(),data=fx$data,control=drm_control(se=FALSE))
  expect_equal(fit$opt$convergence,0L)
  keys <- c('sd_spatial(id, dpar = "mu", coef = "(Intercept)")','sd_spatial(id, dpar = "mu", coef = "x")')
  expect_lt(abs(coef(fit,keys[1])[["z0"]]-.5),.4)
  expect_lt(abs(coef(fit,keys[2])[["z1"]]+.5),.4)
  for(k in 1:2) {
    a <- coef(fit,keys[k]);z <- if(k==1) fx$z0 else fx$z1;p <- predict(fit,dpar=keys[k])
    expect_setequal(names(p),rownames(fx$K))
    expect_equal(unname(p),unname(exp(a[1]+a[2]*z[names(p)])),tolerance=1e-10)
  }
  oracle <- beta_spatial_q2_sd_oracle(fit,fx)
  expect_lt(oracle$gradient,1e-5);expect_lt(oracle$mode_difference,1e-6)
  expect_lt(oracle$derivative_error,1e-4);expect_lt(oracle$hessian_error,2e-4)
  expect_lt(abs(-as.numeric(logLik(fit))-oracle$nll),1e-4)
  eta <- as.numeric(predict(fit,type="link",re.form=NULL))
  expect_lt(max(abs(eta-oracle$eta)),1e-4)
  reordered <- coords[rev(rownames(coords)),,drop=FALSE]
  other <- drmTMB(beta_spatial_q2_sd_form(reordered,reverse_sd=TRUE),family=beta_family(),data=fx$data,control=drm_control(se=FALSE))
  expect_equal(other$opt$convergence,0L)
  expect_lt(abs(as.numeric(logLik(other))-as.numeric(logLik(fit))),1e-4)
  for(key in keys) expect_lt(max(abs(coef(other,key)-coef(fit,key))),1e-4)
  expect_lt(max(abs(as.numeric(predict(other,type="link",re.form=NULL))-eta)),1e-4)
  constant <- drmTMB(beta_spatial_q2_sd_form(coords,constant=TRUE),family=beta_family(),data=fx$data,control=drm_control(se=FALSE))
  base <- drmTMB(bf(y~x+spatial(1+x|id,coords=coords),sigma~1),family=beta_family(),data=fx$data,control=drm_control(se=FALSE))
  expect_equal(constant$opt$convergence,0L);expect_equal(base$opt$convergence,0L)
  expect_lt(abs(as.numeric(logLik(constant))-as.numeric(logLik(base))),1e-4)
  table <- predict_parameters(fit,dpar=keys,conf.int=FALSE)
  expect_setequal(unique(table$dpar),keys)
  report <- fit$obj$report(fit$tmb_state$last.par.best)
  expect_lt(max(abs(as.numeric(fitted(fit))-as.numeric(report$mu))),1e-8)
  saved <- tempfile(fileext=".rds");on.exit(unlink(saved),add=TRUE);saveRDS(fit,saved)
  expect_equal(predict(readRDS(saved),dpar=keys[1]),predict(fit,dpar=keys[1]))
  simulated <- simulate(fit,nsim=1L,seed=2026102804L,re.form=NULL)$sim_1
  set.seed(2026102804L);phi <- exp(-2*coef(fit,"sigma")[[1]])
  expect_equal(simulated,rbeta(nrow(fx$data),report$mu*phi,(1-report$mu)*phi),tolerance=1e-8)
  expect_error(simulate(fit,nsim=1L,re.form=NA),"Marginal simulation.*does not yet support")
})
