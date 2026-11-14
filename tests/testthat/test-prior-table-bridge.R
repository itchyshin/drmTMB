testthat::test_that('table priors agree across native and Julia bridge routes', {
  testthat::skip_if_not(identical(Sys.getenv('DRM_TABLE_PRIOR_LIVE'), '1'))
  testthat::skip_if_not_installed('jsonlite')
  if (exists('drm_julia_bridge_summary_record_live', mode='function')) drm_julia_bridge_summary_record_live()
  x <- jsonlite::fromJSON(testthat::test_path('fixtures','two-ri-sd-prior-oracle','frozen.json'),simplifyVector=FALSE)
  d <- data.frame(y=unlist(x$response[['0.6']]),x=unlist(x$x),site=unlist(x$site),observer=unlist(x$observer))
  f <- drmTMB::bf(mu=y~x+(1|site)+(1|observer),sigma=~x)
  cases <- list(
    fixed=data.frame(prior='normal(0,2)',class='fixef',coef='x'),
    one=data.frame(prior='gamma(0.6666666666666666,2)',class='ranef_sd',coef='site'),
    mixed=data.frame(prior=c('normal(0.25,1.4)','normal(-0.1,0.7)','gamma(0.6666666666666666,2)','gamma(2.0588235294117645,3.5)'),class=c('fixef','fixef','ranef_sd','ranef_sd'),coef=c('(Intercept)','x','site','observer'),dpar=c('mu','sigma','mu','mu')))
  for (p in cases) {
    j <- suppressWarnings(drmTMB::drmTMB(f,data=d,priors=p,engine='julia'))
    r <- suppressWarnings(drmTMB::drmTMB(f,data=d,priors=p,engine='tmb'))
    testthat::expect_equal(j$penalized_objective,r$penalized_objective,tolerance=1e-7)
    testthat::expect_equal(j$logLik,r$logLik,tolerance=1e-6)
    testthat::expect_identical(attr(j$priors,'input_table'),p)
    if (!is.null(r$resolved_priors) && nrow(r$resolved_priors)) {
      for (key in c('dpar','coefficient')) testthat::expect_equal(j$resolved_priors[[key]],r$resolved_priors[[key]])
    } else testthat::expect_true(is.null(j$resolved_priors) || nrow(j$resolved_priors)==0L)
    if (!is.null(r$resolved_sd_prior) && nrow(r$resolved_sd_prior)) {
      for (key in c('dpar','group','block','coefficient','scale','shape','rate')) testthat::expect_equal(j$resolved_sd_prior[[key]],r$resolved_sd_prior[[key]],tolerance=1e-12)
    } else testthat::expect_true(is.null(j$resolved_sd_prior) || nrow(j$resolved_sd_prior)==0L)
    repeat_j <- suppressWarnings(update(j,data=d))
    testthat::expect_equal(repeat_j$penalized_objective,j$penalized_objective,tolerance=1e-7)
  }
  one_group <- drmTMB::bf(mu=y~x+(1|site),sigma=~x)
  p <- cases$one
  j <- suppressWarnings(drmTMB::drmTMB(one_group,data=d,priors=p,engine='julia'))
  r <- suppressWarnings(drmTMB::drmTMB(one_group,data=d,priors=p,engine='tmb'))
  testthat::expect_equal(j$penalized_objective,r$penalized_objective,tolerance=1e-7)
  testthat::expect_equal(j$resolved_sd_prior$group,'site')
  testthat::expect_equal(j$sd_prior_penalty,r$sd_prior_penalty,tolerance=1e-5)
})

test_that('table-derived bridge targets reject incorrect backend identities', {
  d <- data.frame(y=seq_len(12),site=rep(1:3,each=4),observer=rep(c(1,2,3),4))
  f <- bf(mu=y~1+(1|site)+(1|observer),sigma=~1)
  table <- data.frame(prior=c('gamma(2.0588235294117645,3.5)','gamma(0.6666666666666666,2)'),class=c('ranef_sd','ranef_sd'),coef=c('observer','site'))
  specs <- drmTMB:::drm_normalize_prior_table(table,f,gaussian(),d)
  resolved <- drm_resolve_priors(f,gaussian(),d,specs)
  expected <- drmTMB:::drm_julia_prior_v2_options(specs,resolved)$prior_expected_v2
  coords <- c('mu_(Intercept)','sigma_(Intercept)','eta_sd[mu|site|(Intercept)]','eta_sd[mu|observer|(Intercept)]')
  p1 <- -dgamma(.8,2,rate=3,log=TRUE); p2 <- -dgamma(.4,3.5,rate=1.7,log=TRUE)
  contribution <- function(group,p) list(dpar='mu',group=group,coef='(Intercept)',penalty=p)
  good <- list(prior_contract='parameter_priors_v3',resolved_priors_v3=expected,
    working_coordinates=coords,working_values=c(0,0,log(.8),log(.4)),coefficients=c(0,0,log(.8),log(.4)),
    data_nll=4,data_logLik=-4,loglik=-4,fixed_prior_penalty=0,sd_prior_penalty=p1+p2,
    sd_prior_contributions=list(contribution('observer',p2),contribution('site',p1)),
    penalized_objective=4+p1+p2,data_gradient=c(0,0,1,2),fixed_prior_gradient=c(0,0,0,0),
    sd_prior_gradient=c(0,0,1.4,1.7*.4-2.5),penalized_gradient=c(0,0,2.4,2+1.7*.4-2.5),
    estim_method='MAP',infocrit_basis='unavailable')
  validate <- function(result) drmTMB:::drm_julia_validate_prior_v2_result(result,expected,coords,version='v3')
  expect_silent(validate(good))
  wrong <- good; wrong$resolved_priors_v3[[1]]$group <- 'site'
  expect_error(validate(wrong),'prior records')
  missing <- good; missing$resolved_priors_v3 <- missing$resolved_priors_v3[-1L]
  expect_error(validate(missing),'record count')
})
