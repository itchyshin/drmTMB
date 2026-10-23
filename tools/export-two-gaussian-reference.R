#!/usr/bin/env Rscript
# Generated native numbers for the shared two-predictor contract. No defaults changed.
args <- commandArgs(TRUE)
if (length(args) != 1L) stop('usage: export-two-gaussian-reference.R NEW_PREFIX')
prefix <- args[[1L]]
if (any(file.exists(paste0(prefix,c('.json','.rds'))))) stop('refusing stale output')
pkgload::load_all(quiet=TRUE,recompile=FALSE)
sha <- function(p) digest::digest(file=p,algo='sha256')
manifest <- function() {
 p <- c(sort(list.files('R',pattern='[.]R$',full.names=TRUE)), 'NAMESPACE',
        sort(list.files('src',pattern='[.](cpp|h|hpp)$',recursive=TRUE,full.names=TRUE)))
 as.list(setNames(vapply(p,sha,''),p))
}
before <- manifest()
# Independent small nondegenerate fixture, every response/predictor mask retained.
set.seed(96302); n <- 160L; z <- rnorm(n)
x1 <- 0.2 + 0.7*z + rnorm(n,sd=0.45)
x2 <- -0.1 + 0.55*z + rnorm(n,sd=0.4)
y <- 0.3 + 0.8*x1 + 0.6*x2 + 0.25*z + rnorm(n,sd=0.5)
x1[seq_len(n) %% 5L == 0L] <- NA_real_
x2[seq_len(n) %% 7L == 0L] <- NA_real_
y[c(4L,5L,7L,35L)] <- NA_real_
d <- data.frame(y=y,x1=x1,x2=x2,z=z)
mask <- paste0(as.integer(!is.na(y)),as.integer(!is.na(x1)),as.integer(!is.na(x2)))
stopifnot(length(unique(mask))==8L)
tick <- proc.time()[['elapsed']]
f <- drmTMB(bf(y ~ mi(x1) + mi(x2) + z, sigma ~ 1),data=d,
 impute=list(x1=x1~z,x2=x2~z),missing=miss_control(response='include',predictor='model'))
# Require exact named block layout before applying a positional common-order map.
expected_names <- c(rep('beta_mu',4),'beta_sigma',rep('beta_mi',2),'log_sigma_mi',rep('beta_mi2',2),'log_sigma_mi2')
stopifnot(identical(names(f$opt$par),expected_names),
 identical(names(coef(f,'mu')),c('(Intercept)','mi(x1)','mi(x2)','z')),
 identical(names(coef(f,'mi_x1')),c('(Intercept)','z')),
 identical(names(coef(f,'mi_x2')),c('(Intercept)','z')))
idx <- c(1L,4L,2L,3L,5L,6L,7L,8L,9L,10L,11L)
theta <- unname(f$opt$par[idx]); V <- unname(f$sdr$cov.fixed[idx,idx,drop=FALSE])
imputed1 <- imputed(f,'x1',rows='all'); imputed2 <- imputed(f,'x2',rows='all')
# Fixed off-optimum coordinates test likelihood identity, not only fitted agreement.
shift <- c(.05,-.04,.03,-.06,.025,-.035,.045,.055,-.025,.015,-.045)
points <- lapply(list(theta,theta+shift,theta-2*shift),function(t) {
 par <- f$opt$par; par[idx] <- t
 list(theta=t,nll=f$obj$fn(par),gradient=unname(f$obj$gr(par)[idx]))
})
f$obj$fn(f$opt$par)
encode <- function(x) replace(x,is.na(x),0)
out <- list(scope='Frozen default native two independent Gaussian predictors, all eight masks; no performance/coverage claim',
 schema='two_gaussian_reference_v1',raw_order=c('beta0','beta_z','b1','b2','logsigma','alpha10','alpha1z','logtau1','alpha20','alpha2z','logtau2'),
 source_before=before,source_after=manifest(),source_unchanged=identical(before,manifest()),
 runner_sha256=sha('tools/export-two-gaussian-reference.R'),
 R_version=R.version.string,TMB_version=as.character(packageVersion('TMB')),
 loaded_native_DLL_sha256=sha(getLoadedDLLs()[['drmTMB']][['path']]),
 fixture=list(y=encode(y),x1=encode(x1),x2=encode(x2),z=z,
  y_observed=!is.na(y),x1_observed=!is.na(x1),x2_observed=!is.na(x2),original_row=seq_len(n)),
 mask_counts=as.list(table(mask)),theta=theta,covariance=V,points=points,
 imputed1=imputed1,imputed2=imputed2,prediction=predict(f),
 native_convergence=f$opt$convergence,native_message=f$opt$message,
 optimizer_control=f$control$optimizer,loglik=as.numeric(logLik(f)),nobs=nobs(f),
 elapsed=proc.time()[['elapsed']]-tick)
stopifnot(out$source_unchanged)
jsonlite::write_json(out,paste0(prefix,'.json'),pretty=TRUE,auto_unbox=TRUE,digits=17,na='string',null='null')
saveRDS(f,paste0(prefix,'.rds'))
cat('TWO_GAUSSIAN_NATIVE_EXPORTED rows=160 masks=8\n')
