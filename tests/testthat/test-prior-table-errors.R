test_that('prior tables reject malformed inputs and unsupported targets', {
  d <- data.frame(y=seq_len(12),x=rep(c(-1,0,1),4),site=rep(letters[1:4],each=3),observer=rep(letters[5:7],4),third=rep(c('u','v'),6))
  f <- bf(mu=y~x+(1|site)+(1|observer),sigma=~1)
  one <- function(prior,class='fixef',coef='x',...) data.frame(prior=prior,class=class,coef=coef,...,stringsAsFactors=FALSE)
  bad <- list(
    one("normal(0,2);system('x')"),one('normal(1+1,2)'),one('normal(0,Inf)'),
    one('normal(0,1e-999)'),one('normal(1e-999,2)'),one('normal(0,1e200)'),
    one('normal(0,1e-200)'),one('normal(0,0)'),one('ridge(-1)'),
    one('gamma(1,1)','ranef_sd','site'),one('gamma(1e-320,2)','ranef_sd','site'),
    one('normal(0,2)','ranef_cor','x'),one('normal(0,2)','fixef_disp','x'),
    one('gamma(1,2)','fixef','x'),one('normal(0,2)','fixef','all'),
    one('normal(0,2)','fixef','x',group='site'),one('gamma(1,2)','ranef_sd','missing'),
    one('gamma(1,2)','ranef_sd','x',group='site'),
    data.frame(prior='normal(0,2)',class='fixef'),
    data.frame(prior=character(),class=character(),coef=character()),
    one('normal(0,2)','fixef',NA_character_))
  for (table in bad) expect_error(drm_resolve_priors(f,gaussian(),d,table))
  duplicated <- data.frame(prior='ridge(1)',class='fixef',coef='x',extra='x'); names(duplicated)[4] <- 'coef'
  expect_error(drm_resolve_priors(f,gaussian(),d,duplicated))
  overlap <- data.frame(prior=c('gamma(1,2)','gamma(1,2)'),class=c('ranef_sd','ranef_sd'),coef=c('','site'))
  expect_error(drm_resolve_priors(f,gaussian(),d,overlap))
  fixed_overlap <- data.frame(prior=c('normal(0,2)','normal(0,2)'),class=c('fixef','fixef'),coef=c('','x'))
  expect_error(drm_resolve_priors(f,gaussian(),d,fixed_overlap))
  p <- one('gamma(1,2)','ranef_sd','')
  expect_error(drm_resolve_priors(bf(mu=y~x+(1|site)+(1|observer)+(1|third),sigma=~1),gaussian(),d,p))
  expect_error(drm_resolve_priors(bf(mu=y~x+(1+x|site),sigma=~1),gaussian(),d,p))
  expect_error(drm_resolve_priors(f,binomial(),d,p))
  missing <- d; missing$y[1] <- NA_real_
  expect_error(drmTMB(f,data=missing,priors=p))
})
