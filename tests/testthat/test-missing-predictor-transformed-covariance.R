# Natural-scale public summaries must not expose raw log/logit covariance.
mi_transform_check <- function(fit, blocks, raw_names, transforms) {
  Vraw <- fit$sdr$cov.fixed
  V <- vcov(fit)
  values <- unlist(coef(fit), use.names = FALSE)
  labels <- drmTMB:::coefficient_labels(fit)
  alltargets <- profile_targets(fit)
  target <- alltargets[match(paste0("fixef:", labels), alltargets$parm), ]
  rawpos <- integer(); publicpos <- integer(); derivative <- numeric()
  for (j in seq_along(blocks)) {
    block <- blocks[[j]]; fun <- transforms[[j]]
    take <- which(target$dpar == block)
    pos <- which(names(fit$opt$par) == raw_names[[j]])
    eta <- unname(fit$opt$par[pos])
    jac <- switch(fun, exp=exp(eta), plogis=plogis(eta)*(1-plogis(eta)), rep(1,length(pos)))
    expect_equal(target$tmb_parameter[take], rep(raw_names[[j]],length(pos)))
    expect_equal(target$transformation[take],rep(fun,length(pos)))
    expect_equal(target$link_estimate[take],eta,tolerance=1e-12)
    expect_equal(target$scale[take],rep(if(fun=='linear_predictor') 'link' else 'response',length(pos)))
    expect_true(all(target$profile_ready[take]))
    ci <- confint(fit, parm=target$parm[take],method='wald',bias_correct='none',small_sample_df='none')
    rad <- qnorm(.975)*sqrt(diag(Vraw)[pos])
    forward <- switch(fun,exp=exp,plogis=plogis,identity)
    expect_equal(ci$lower,unname(forward(eta-rad)),tolerance=1e-10)
    expect_equal(ci$upper,unname(forward(eta+rad)),tolerance=1e-10)
    rawpos <- c(rawpos,pos); publicpos <- c(publicpos,take); derivative <- c(derivative,jac)
  }
  expected <- Vraw[rawpos,rawpos,drop=FALSE]*outer(derivative,derivative)
  expect_true(all(is.finite(V[publicpos,publicpos])))
  expect_equal(unname(V[publicpos,publicpos,drop=FALSE]),unname(expected),tolerance=1e-10)
  expect_gt(max(abs(expected[row(expected)!=col(expected)])),1e-8)
  tab <- summary(fit)$coefficients
  expect_equal(tab$std_error[match(labels[publicpos],rownames(tab))],
    unname(sqrt(diag(expected))),tolerance=1e-10)
}

test_that('two Gaussian predictor scales transform both covariance axes and log-Wald intervals', {
  set.seed(56383)
  n <- 120L; z <- rnorm(n); x <- .2+.3*z+rnorm(n,sd=.6); w <- -.1+.4*z+rnorm(n,sd=.5)
  d <- data.frame(y=.4+.7*x-.3*w+.2*z+rnorm(n,sd=.7),z=z,body_mass=x,temperature=w)
  d$body_mass[seq(5L,n,by=11L)] <- NA
  d$temperature[seq(7L,n,by=13L)] <- NA
  fit <- drmTMB(bf(y~mi(body_mass)+mi(temperature)+z,sigma~1),data=d,
    impute=list(body_mass=impute_model(body_mass~z,family=gaussian()),
      temperature=impute_model(temperature~z,family=gaussian())),missing=miss_control(predictor='model'))
  mi_transform_check(fit,c('mu','sigma','mi_body_mass','sigma_mi_body_mass','mi_temperature','sigma_mi_temperature'),
    c('beta_mu','beta_sigma','beta_mi','log_sigma_mi','beta_mi2','log_sigma_mi2'),
    c('linear_predictor','linear_predictor','linear_predictor','exp','linear_predictor','exp'))
  # Covariance-source plumbing sentinel, not admission/evidence for joint REML.
  # If raw and natural ADREPORT names coexist, select raw and transform once.
  sentinel <- fit; sentinel$REML <- TRUE
  m <- length(fit$opt$par)
  sentinel$sdr$cov <- matrix(0,m+1L,m+1L)
  sentinel$sdr$cov[seq_len(m),seq_len(m)] <- fit$sdr$cov.fixed
  sentinel$sdr$cov[m+1L,m+1L] <- 999
  sentinel$sdr$value <- c(fit$opt$par,sigma_mi=999)
  expect_equal(vcov(sentinel),vcov(fit),tolerance=1e-12)
  # An absent raw scale in the primary source falls back to cov.fixed.
  names(sentinel$sdr$value)[names(sentinel$sdr$value)=='log_sigma_mi'] <- 'unrelated_report'
  expect_equal(vcov(sentinel),vcov(fit),tolerance=1e-12)
})

test_that('zero-one-beta predictor scale and probabilities have log and logit uncertainty', {
  set.seed(56384)
  n <- 160L; z <- rnorm(n); x <- rbeta(n,4,6)
  u <- runif(n); x[u<.12] <- 0; x[u>.87] <- 1
  d <- data.frame(y=.3+.9*x+.2*z+rnorm(n,sd=.5),z=z,cover=x)
  d$cover[seq(6L,n,by=9L)] <- NA
  fit <- drmTMB(bf(y~z+mi(cover),sigma~1),data=d,
    impute=list(cover=impute_model(cover~z,family=zero_one_beta())),missing=miss_control(predictor='model'))
  mi_transform_check(fit,c('mu','sigma','mi_cover','sigma_mi_cover','zoi_mi_cover','coi_mi_cover'),
    c('beta_mu','beta_sigma','beta_mi','log_sigma_mi','beta_zoi','beta_coi'),
    c('linear_predictor','linear_predictor','linear_predictor','exp','plogis','plogis'))
  extreme <- fit
  extreme$opt$par[names(extreme$opt$par)=='beta_zoi'] <- 40
  extreme$coefficients$zoi_mi_cover[] <- plogis(40)
  target <- profile_targets(extreme)
  target <- target[target$dpar=='zoi_mi_cover',,drop=FALSE]
  expect_identical(target$link_estimate,40)
  expect_true(is.finite(drmTMB:::summary_parameter_delta_derivative(target)))
})

test_that('grouped and structured predictor SD covariance uses its log coordinate', {
  set.seed(56385)
  n <- 120L; group <- factor(rep(letters[1:12],each=10)); z <- rnorm(n)
  shifts <- rnorm(12,sd=.9); x <- .2+.3*z+shifts[as.integer(group)]+rnorm(n,sd=.4)
  d <- data.frame(y=.4+.7*x+.2*z+rnorm(n,sd=.6),z=z,x=x,group=group)
  d$x[seq(5L,n,by=11L)] <- NA
  Q <- diag(12); dimnames(Q) <- list(levels(group),levels(group))
  for (structured in c(FALSE,TRUE)) {
    imp <- if(structured) x~z+relmat(1|group,Q=Q) else x~z+(1|group)
    fit <- drmTMB(bf(y~mi(x)+z,sigma~1),data=d,impute=list(x=imp),missing=miss_control(predictor='model'))
    mi_transform_check(fit,c('mu','sigma','mi_x','sigma_mi_x',if(structured)'sd_mi_relmat_x' else 'sd_mi_group_x'),
      c('beta_mu','beta_sigma','beta_mi','log_sigma_mi',if(structured)'log_sd_mi_struct' else 'log_sd_mi_group'),
      c('linear_predictor','linear_predictor','linear_predictor','exp','exp'))
    expect_error(confint(fit,parm='fixef:mi_x:z',method='bootstrap',R=2),
      'joint predictor simulation',class='drmTMB_joint_bootstrap_unavailable')
  }
})

test_that('predictor SD boundaries remain distinct from regular residual scales', {
  targets <- data.frame(target_class=rep('fixed-effect',3),
    tmb_parameter=c('log_sd_mi_group','log_sd_mi_struct','log_sigma_mi'),
    transformation=rep('exp',3),estimate=rep(1e-7,3))
  expect_identical(drmTMB:::wald_boundary_targets(targets),c(TRUE,TRUE,FALSE))
  for(i in 1:3) expect_identical(drmTMB:::bootstrap_boundary_share_at(rep(1e-7,20),targets[i,,drop=FALSE]),if(i<3)1 else 0)
})

test_that('exact predictor transform metadata and stable logistic tails are enforced', {
  helper <- drmTMB:::profile_missing_predictor_transform
  object <- list(model=list(missing_predictor=list(variable='body.mass',family='gaussian')))
  expect_equal(helper('sigma_mi_body.mass',object),list(internal='log_sigma_mi',transformation='exp'))
  expect_null(helper('sigma_mi_bodyXmass',object))
  for(variable in list(NULL,NA_character_,character(),c('a','b'),1)) {
    bad <- list(model=list(missing_predictor=list(variable=variable,family='gaussian')))
    expect_null(helper('sigma_mi_body.mass',bad))
  }
  expect_null(helper('sigma_mi_body.mass',list(model=list(missing_predictor=list(variable='body.mass')))))
  for(eta in c(-40,40)) {
    target <- data.frame(link_estimate=eta,transformation='plogis')
    expect_equal(drmTMB:::summary_parameter_delta_derivative(target),plogis(eta)*plogis(-eta),tolerance=1e-30)
    expect_gt(drmTMB:::summary_parameter_delta_derivative(target),0)
    expect_equal(drmTMB:::profile_transform_interval(c(eta-1,eta+1),target),plogis(c(eta-1,eta+1)))
  }
})
