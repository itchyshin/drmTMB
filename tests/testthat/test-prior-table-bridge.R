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
