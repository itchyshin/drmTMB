test_that('prior tables match the independent dense Gaussian oracle', {
  skip_if_not_installed('jsonlite')
  skip_if_not_installed('numDeriv')
  x <- jsonlite::fromJSON(testthat::test_path('fixtures','two-ri-sd-prior-oracle','frozen.json'), simplifyVector=FALSE)
  asym <- jsonlite::fromJSON(testthat::test_path('fixtures','two-ri-sd-prior-oracle','asymmetric-frozen.json'), simplifyVector=FALSE)
  datasets <- c(x$response,asym$datasets); records <- c(x$records,asym$points)
  site <- list(prior='gamma(0.6666666666666666,2)',class='ranef_sd',coef='site',dpar='mu')
  observer <- list(prior='gamma(2.0588235294117645,3.5)',class='ranef_sd',coef='observer',dpar='mu')
  meanprior <- list(prior='normal(0.25,1.4)',class='fixef',coef='(Intercept)',dpar='mu')
  scaleprior <- list(prior='normal(-0.1,0.7)',class='fixef',coef='x',dpar='sigma')
  cases <- list(none=list(),site=list(site),observer=list(observer),both=list(site,observer),mixed=list(meanprior,scaleprior,site,observer))
  count <- 0L
  for (dataset in names(datasets)) for (case in names(cases)) {
    d <- data.frame(y=unlist(datasets[[dataset]]),x=unlist(x$x),site=factor(unlist(x$site)),observer=factor(unlist(x$observer)))
    form <- bf(mu=y~x+(1|site)+(1|observer),sigma=~x)
    table <- if (case == 'none') NULL else do.call(rbind,lapply(cases[[case]],as.data.frame,stringsAsFactors=FALSE))
    fit <- suppressWarnings(drmTMB(form,data=d,priors=table))
    pos <- c(which(names(fit$obj$par)=='beta_mu'),which(names(fit$obj$par)=='beta_sigma'),which(names(fit$obj$par)=='log_sd_mu'))
    expect_length(pos,6L)
    pts <- Filter(function(r) identical(r$dataset,dataset) && identical(r$case,case),records)
    for (r in pts) {
      q <- unlist(r$theta); base <- fit$obj$par
      fn <- function(v){z <- base; z[pos] <- v; fit$obj$fn(z)}
      gr <- function(v){z <- base; z[pos] <- v; fit$obj$gr(z)[pos]}
      h <- numDeriv::jacobian(gr,q)
      reference <- do.call(rbind,lapply(r$hessian,function(a) as.numeric(unlist(a))))
      expect_lte(abs(fn(q)-r$objective),1e-8*max(1,abs(r$objective)))
      expect_lte(max(abs(gr(q)-unlist(r$gradient))),1e-6)
      expect_lte(max(abs(h-reference)/pmax(1,abs(reference))),1e-5)
      count <- count+1L
    }
  }
  expect_identical(count,150L)
  d <- data.frame(y=unlist(x$response[['0.6']]),x=unlist(x$x),site=factor(unlist(x$site)),observer=factor(unlist(x$observer)))
  form <- bf(mu=y~x+(1|site)+(1|observer),sigma=~x)
  table <- do.call(rbind,lapply(cases[['mixed']],as.data.frame,stringsAsFactors=FALSE))
  wrongtarget <- table; wrongtarget$coef[3:4] <- rev(wrongtarget$coef[3:4])
  wrongrate <- table; wrongrate$prior[3] <- 'gamma(1.5,3)'
  fit <- suppressWarnings(drmTMB(form,data=d,priors=table))
  plain <- suppressWarnings(drmTMB(form,data=d))
  swap <- suppressWarnings(drmTMB(form,data=d,priors=wrongtarget))
  rate <- suppressWarnings(drmTMB(form,data=d,priors=wrongrate))
  row <- Filter(function(r) identical(r$dataset,'0.6') && identical(r$case,'mixed'),x$records)[[1L]]
  q <- unlist(row$theta)
  point <- function(fit) {
    v <- fit$obj$par
    pos <- c(which(names(v)=='beta_mu'),which(names(v)=='beta_sigma'),which(names(v)=='log_sd_mu'))
    v[pos] <- q; fit$obj$fn(v)
  }
  value <- point(fit); base <- point(plain); penalty <- value-base
  normalizers <- log(1.4)+log(.7)+log(2*pi)-2*log(3)+lgamma(2)-3.5*log(1.7)+lgamma(3.5)
  fixed <- .5*((q[1]-.25)/1.4)^2+log(1.4)+.5*log(2*pi)+.5*((q[4]+.1)/.7)^2+log(.7)+.5*log(2*pi)
  sitepen <- 3*exp(q[5])-q[5]-2*log(3)+lgamma(2)
  obspen <- 1.7*exp(q[6])-2.5*q[6]-3.5*log(1.7)+lgamma(3.5)
  wrong <- c(point(swap),point(rate),value-normalizers,base,value+penalty,
             base+fixed+3*sitepen+3*obspen,value-q[5]-q[6])
  for (candidate in wrong) expect_gt(abs(candidate-row$objective),1e-6)
})

test_that('prior-table fitted optima agree with the independent oracle', {
  skip_if_not_installed('jsonlite')
  x <- jsonlite::fromJSON(testthat::test_path('fixtures','two-ri-sd-prior-oracle','frozen.json'), simplifyVector=FALSE)
  rows <- data.frame(prior=c('normal(0.25,1.4)','normal(-0.1,0.7)','gamma(0.6666666666666666,2)','gamma(2.0588235294117645,3.5)'),class=c('fixef','fixef','ranef_sd','ranef_sd'),coef=c('(Intercept)','x','site','observer'),dpar=c('mu','sigma','mu','mu'))
  choices <- list(site=3L,observer=4L,both=3:4,mixed=1:4)
  expect_length(x$fits, 12L)
  for (r in x$fits) {
   expect_false(r$floor_contact)
   d <- data.frame(y=unlist(x$response[[r$dataset]]),x=unlist(x$x),site=factor(unlist(x$site)),observer=factor(unlist(x$observer)))
   f <- bf(mu=y~x+(1|site)+(1|observer),sigma=~x)
   fit <- suppressWarnings(drmTMB(f,data=d,priors=rows[choices[[r$case]],,drop=FALSE]))
   pos <- c(which(names(fit$obj$par)=='beta_mu'),which(names(fit$obj$par)=='beta_sigma'),which(names(fit$obj$par)=='log_sd_mu'))
   q <- fit$opt$par[pos]; score <- max(abs(fit$obj$gr(fit$opt$par)[pos])); diff <- abs(fit$opt$objective-r$objective); delta <- max(abs(q-unlist(r$theta)))
   selected <- switch(r$case,site=5L,observer=6L,both=5:6,mixed=5:6)
   expect_true(all(is.finite(q[selected]) & q[selected] > -17.99))
   expect_lt(diff,1e-6); expect_lt(score,1e-4)
   if (r$hessian_min_eigenvalue>1e-4) expect_lt(delta,1e-5)
  }
})
