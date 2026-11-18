pkgload::load_all(compile=FALSE, quiet=TRUE)
exprs <- c(parse('tests/testthat/helper-b34-julia-oracles.R'), parse('tests/testthat/test-julia-b34-iid-quadrature-oracle.R'))
for (e in exprs) if (is.call(e) && identical(e[[1]], as.name('<-')) && as.character(e[[2]]) %in% c('b34q_fixture','b34_sd')) eval(e)
results <- list()
for (seed in c(20261409L,20261412L)) {
  dat <- b34q_fixture('zob_slope',seed,boundary_heavy=TRUE)$data
  cat('START',seed,'min interior',min(dat$y[dat$y>0 & dat$y<1]),format(Sys.time()),'\n'); flush.console()
  outcome <- tryCatch({
    fit <- drmTMB(bf(y~x+(0+x|id),sigma~1,zoi~1,coi~1,sd(id,coef='x')~z),family=zero_one_beta(),data=dat,engine='julia')
    list(seed=seed,status='returned',logLik=as.numeric(logLik(fit)),convergence=fit$opt$convergence,coefficients=coef(fit))
  },error=function(e) list(seed=seed,status='error',message=conditionMessage(e)))
  print(outcome); flush.console(); results[[as.character(seed)]] <- outcome
}
saveRDS(results,'/Users/z3437171/Documents/Codex/2026-11-04-sd-article-plan/execution/frozen-verification-final/zeroonebeta-results.rds')
cat('S3_ZOB_ATTEMPTS_RECORDED\n')
