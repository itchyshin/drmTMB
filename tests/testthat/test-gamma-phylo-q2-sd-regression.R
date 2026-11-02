# Independent shared-ancestry correlation, not a package tree covariance helper.
gamma_phylo_q2_sd_fixture <- function() {
  set.seed(2026102713L)
  n <- 64L; nr <- 20L; ids <- sprintf("tip%03d",seq_len(n))
  newick <- function(index,root=FALSE) {
    if(length(index)==1L) return(paste0(ids[index],":1.5"))
    half <- length(index)/2L
    paste0("(",newick(index[seq_len(half)]),",",newick(index[half+seq_len(half)]),")",if(root) ";" else ":0.1")
  }
  tree <- ape::read.tree(text=newick(seq_len(n),TRUE))
  bits <- lapply(0:(n-1L),function(i) rev(as.integer(intToBits(i))[seq_len(6L)]))
  K <- matrix(0,n,n,dimnames=list(ids,ids))
  for(i in seq_len(n)) for(j in seq_len(n)) {
    mismatch <- which(bits[[i]] != bits[[j]])
    K[i,j] <- if(i==j) 1 else (mismatch[1L]-1L)*.1/2
  }
  z0 <- setNames(rep(c(-1,1),n/2L),ids)
  z1 <- setNames(rep(c(-1,1),each=n/2L),ids)
  b0 <- exp(log(.5)+.5*z0)*drop(t(chol(K))%*%rnorm(n))
  b1 <- exp(log(.4)-.5*z1)*drop(t(chol(K))%*%rnorm(n))
  ii <- rep(seq_len(n),each=nr);x <- rep(seq(-1.2,1.2,length.out=nr),n)
  mu <- exp(.2+.3*x+b0[ii]+x*b1[ii]);phi <- .35^-2
  data <- data.frame(y=rgamma(length(ii),shape=phi,rate=phi/mu),x=x,
    id=factor(ids[ii],levels=rev(ids)),z0=unname(z0[ii]),z1=unname(z1[ii]))
  stopifnot(all(is.finite(data$y)),all(data$y>0))
  list(data=data,tree=tree,K=K,z0=z0,z1=z1)
}

gamma_phylo_q2_sd_form <- function(tree,constant=FALSE,reverse_sd=FALSE) {
  f0 <- as.formula(paste('sd(id, level="phylogenetic", coef="(Intercept)") ~',if(constant) "1" else "z0"),env=environment())
  f1 <- as.formula(paste('sd(id, level="phylogenetic", coef="x") ~',if(constant) "1" else "z1"),env=environment())
  mu <- y ~ x + phylo(1+x|id,tree=tree)
  if(reverse_sd) bf(mu,sigma~1,f1,f0) else bf(mu,sigma~1,f0,f1)
}

gamma_phylo_q2_sd_oracle <- function(fit, fx) {
  d <- fx$data; ids <- rownames(fx$K); n <- length(ids)
  P <- kronecker(diag(2L), solve(fx$K))
  ii <- match(as.character(d$id), ids)
  keys <- c('sd_phylo(id, dpar = "mu", coef = "(Intercept)")',
            'sd_phylo(id, dpar = "mu", coef = "x")')
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
    list(eta=eta, score=phi*(1-d$y*exp(-eta)), curvature=phi*d$y*exp(-eta))
  }
  joint <- function(u) {
    eta <- moments(u)$eta
    -sum(stats::dgamma(d$y,shape=phi,rate=phi/exp(eta),log=TRUE)) +
      drop(crossprod(u,P%*%u))/2+n*log(2*pi)+
      as.numeric(determinant(fx$K,logarithm=TRUE)$modulus)
  }
  gradient <- function(u) drop(P%*%u+crossprod(B,moments(u)$score))
  hessian <- function(u) P+crossprod(B,moments(u)$curvature*B)
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

test_that("Gamma phylo q2 maps coefficient SDs and integrates tree nodes", {
  skip_if_not_installed("ape")
  fx <- gamma_phylo_q2_sd_fixture();tree <- fx$tree
  spec <- drmTMB:::drm_build_gamma_ls_spec(gamma_phylo_q2_sd_form(tree),fx$data)
  expect_identical(spec$tmb_data$has_sd_phylo_coef_model,1L)
  expect_identical(spec$structured$phylo_mu$q,2L)
  pr <- spec$structured$phylo_mu$precision
  covariance <- solve(as.matrix(pr$precision))
  tip <- unname(pr$tip_node_index[rownames(fx$K)])
  expect_equal(unname(covariance[tip,tip]),unname(fx$K),tolerance=1e-10)
  expect_equal(pr$height,2)
  expect_true(all(spec$tmb_data$phylo_mu_sd_row_coef>=0L))
  expect_true(all(spec$tmb_data$phylo_mu_sd_row_coef[,1]!=spec$tmb_data$phylo_mu_sd_row_coef[,2]))
  bad <- fx$data;bad$z0[1] <- bad$z0[1]+.1
  expect_error(drmTMB:::drm_build_gamma_ls_spec(gamma_phylo_q2_sd_form(tree),bad),"constant within")
  expect_error(drmTMB:::drm_build_gamma_ls_spec(bf(y~x+phylo(1+x|id,tree=tree),sigma~1,sd(id,level="phylogenetic")~z0),fx$data),"select a coefficient")
  expect_error(drmTMB:::drm_build_gamma_ls_spec(bf(y~x+phylo(1+x|id,tree=tree),sigma~1,sd(id,level="phylogenetic",coef="x")~z1),fx$data),"one SD formula")
  expect_error(drmTMB:::drm_build_gamma_ls_spec(bf(y~x+phylo(1+x|p|id,tree=tree),sigma~1),fx$data),"unlabelled")
  expect_error(drmTMB:::drm_build_gamma_ls_spec(bf(y~x+phylo(0+x+z0|id,tree=tree),sigma~1),fx$data),"intercept")
  expect_error(drmTMB:::drm_build_gamma_ls_spec(bf(y~x+phylo(1+x+z0|id,tree=tree),sigma~1),fx$data),"intercept")
  expect_error(drmTMB:::drm_build_gamma_ls_spec(bf(y~x+phylo(1+x|id,tree=tree)+(1|id),sigma~1),fx$data),"cannot be combined")
  expect_error(drmTMB:::drm_build_gamma_ls_spec(bf(y~x+phylo(1+x|id,tree=tree),sigma~1+(1|id)),fx$data),"scale random effects|sigma.*random|cannot be combined")
  expect_error(drmTMB:::drm_build_gamma_ls_spec(bf(y~x+phylo(1+x|id,tree=tree),sigma~1),fx$data,missing=miss_control(response="include")),"complete")
  expect_error(drmTMB:::drm_build_lognormal_ls_spec(
    bf(y~x+phylo(1+x|id,tree=tree),sigma~1),fx$data),"intercept-only")
  # Exercise the shared validator directly with default flags as a cross-family guard.
  parsed <- drmTMB:::extract_gaussian_mu_phylo_term(gamma_phylo_q2_sd_form(tree)$entries[[1]])$term
  expect_error(drmTMB:::validate_positive_continuous_mu_structured_term(parsed,"Tweedie"),"intercept-only")
  absent <- tree$tip.label[1];dat <- fx$data[as.character(fx$data$id)!=absent,,drop=FALSE]
  reduced <- suppressMessages(drmTMB:::drm_build_gamma_ls_spec(gamma_phylo_q2_sd_form(tree),dat))
  n <- reduced$structured$phylo_mu$n_re;nodes <- reduced$structured$phylo_mu$node_labels
  par <- reduced$start;par$u_phylo <- seq_len(2*n)/n;par$beta_sd_mu <- c(log(.5),.5,log(.4),-.5)
  re <- drmTMB:::split_tmb_random_effects(par,reduced)$phylo_mu
  expect_equal(unname(re$latent),par$u_phylo)
  missing <- setdiff(nodes,as.character(dat$id))
  for(k in 1:2) expect_true(all(is.na(re$terms[[k]][missing])))
  seen <- setdiff(rownames(fx$K),absent)
  expect_equal(unname(re$terms[[1]][seen]),unname(par$u_phylo[match(seen,nodes)]*exp(log(.5)+.5*fx$z0[seen])))
  expect_equal(unname(re$terms[[2]][seen]),unname(par$u_phylo[n+match(seen,nodes)]*exp(log(.4)-.5*fx$z1[seen])))
})

test_that("Gamma phylo q2 SD fit matches independent observed-tip likelihood", {
  skip_on_cran();skip_if_not_installed("ape")
  fx <- gamma_phylo_q2_sd_fixture();tree <- fx$tree
  fit <- drmTMB(gamma_phylo_q2_sd_form(tree),family=Gamma(link="log"),data=fx$data,control=drm_control(se=FALSE))
  expect_equal(fit$opt$convergence,0L)
  keys <- c('sd_phylo(id, dpar = "mu", coef = "(Intercept)")','sd_phylo(id, dpar = "mu", coef = "x")')
  expect_lt(abs(coef(fit,keys[1])[["z0"]]-.5),.4)
  expect_lt(abs(coef(fit,keys[2])[["z1"]]+.5),.4)
  for(k in 1:2) {
    a <- coef(fit,keys[k]);z <- if(k==1) fx$z0 else fx$z1;p <- predict(fit,dpar=keys[k])
    expect_setequal(names(p),rownames(fx$K))
    expect_equal(unname(p),unname(exp(a[1]+a[2]*z[names(p)])),tolerance=1e-10)
  }
  oracle <- gamma_phylo_q2_sd_oracle(fit,fx)
  expect_lt(oracle$gradient,1e-5);expect_lt(oracle$mode_difference,1e-6)
  expect_lt(oracle$derivative_error,1e-4);expect_lt(oracle$hessian_error,2e-4)
  expect_lt(abs(-as.numeric(logLik(fit))-oracle$nll),1e-4)
  eta <- as.numeric(predict(fit,type="link",re.form=NULL))
  expect_lt(max(abs(eta-oracle$eta)),1e-4)
  reordered <- tree;reordered$tip.label <- rev(tree$tip.label)
  is_tip <- reordered$edge[,2]<=length(tree$tip.label)
  reordered$edge[is_tip,2] <- match(tree$tip.label[tree$edge[is_tip,2]],reordered$tip.label)
  reordered <- ape::reorder.phylo(reordered,"postorder")
  other <- drmTMB(gamma_phylo_q2_sd_form(reordered,reverse_sd=TRUE),family=Gamma(link="log"),data=fx$data,control=drm_control(se=FALSE))
  expect_equal(other$opt$convergence,0L)
  expect_lt(abs(as.numeric(logLik(other))-as.numeric(logLik(fit))),1e-4)
  for(key in keys) expect_lt(max(abs(coef(other,key)-coef(fit,key))),1e-4)
  expect_lt(max(abs(as.numeric(predict(other,type="link",re.form=NULL))-eta)),1e-4)
  constant <- drmTMB(gamma_phylo_q2_sd_form(tree,constant=TRUE),family=Gamma(link="log"),data=fx$data,control=drm_control(se=FALSE))
  base <- drmTMB(bf(y~x+phylo(1+x|id,tree=tree),sigma~1),family=Gamma(link="log"),data=fx$data,control=drm_control(se=FALSE))
  expect_equal(constant$opt$convergence,0L);expect_equal(base$opt$convergence,0L)
  expect_lt(abs(as.numeric(logLik(constant))-as.numeric(logLik(base))),1e-4)
  table <- predict_parameters(fit,dpar=keys,conf.int=FALSE)
  expect_setequal(unique(table$dpar),keys)
  report <- fit$obj$report(fit$tmb_state$last.par.best)
  expect_lt(max(abs(as.numeric(fitted(fit))-as.numeric(report$mu))),1e-8)
  saved <- tempfile(fileext=".rds");on.exit(unlink(saved),add=TRUE);saveRDS(fit,saved)
  expect_equal(predict(readRDS(saved),dpar=keys[1]),predict(fit,dpar=keys[1]))
  simulated <- simulate(fit,nsim=1L,seed=2026102714L,re.form=NULL)$sim_1
  set.seed(2026102714L);phi <- exp(-2*coef(fit,"sigma")[[1]])
  expect_equal(simulated,rgamma(nrow(fx$data),shape=phi,rate=phi/report$mu),tolerance=1e-8)
  # Marginal simulation is admitted for this route (see
  # test-q2-sd-marginal-simulate.R); a fitted correlation that is not the
  # structured cross-coefficient one stays refused.
  extra_cor <- fit
  extra_cor$corpars <- list(mu = c(`cor(mu:(Intercept),mu:x | id)` = 0.3))
  expect_error(simulate(extra_cor, nsim = 1L, re.form = NA),
               "Marginal simulation.*does not yet support")
})
