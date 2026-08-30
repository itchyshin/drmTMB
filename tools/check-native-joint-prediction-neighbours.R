#!/usr/bin/env Rscript
# Three small native fits and independent Gaussian conditional-mean oracles.
native_prediction_delta <- function(actual, expected) {
  if (!is.numeric(expected) || !is.null(dim(expected)) || length(expected) == 0L || any(!is.finite(expected))) stop('invalid expected prediction vector')
  if (!is.numeric(actual) || !is.null(dim(actual)) || length(actual) != length(expected) || any(!is.finite(actual))) stop('invalid actual prediction vector')
  max(abs(actual - expected))
}
args <- commandArgs(TRUE)
if(length(args)!=1L) stop('usage: check-native-joint-prediction-neighbours.R NEW_PREFIX')
prefix <- args[[1L]]
if(any(file.exists(paste0(prefix,c('.json','.rds'))))) stop('refusing stale outputs')
pkgload::load_all(quiet=TRUE,recompile=FALSE)
sha <- function(p) digest::digest(file=p,algo='sha256')
paths <- sort(list.files('R',pattern='[.]R$',full.names=TRUE))
before <- as.list(setNames(vapply(paths,sha,''),paths))
helpers <- c('tests/testthat/test-missing-predictor-ordered.R','tests/testthat/test-missing-predictor-categorical.R','tests/testthat/test-missing-predictor-two-gaussian.R')
# Import only named function definitions; do not execute test_that blocks.
for(p in helpers) for(e in parse(p)) if(is.call(e) && identical(e[[1L]],as.name('<-')) && is.call(e[[3L]]) && identical(e[[3L]][[1L]],as.name('function'))) eval(e)
out <- list(scope='Three Gaussian-response native prediction neighbours; no Julia admission or parameter recovery claim',
  source_before=before,runner_sha256=sha('tools/check-native-joint-prediction-neighbours.R'),
  helper_sha256=as.list(setNames(vapply(helpers,sha,''),helpers)),tolerance=4e-6,cases=list())
fits <- list();start<-proc.time()[['elapsed']]
for(kind in c('ordinal','categorical','two_gaussian')) {
 out$cases[[kind]] <- tryCatch({
  if(kind=='ordinal') {
   d<-missing_predictor_ordered_data();d$y<-d$y+0.8*sin(seq_len(nrow(d))*1.47)
   f<-fit_missing_predictor_ordered(d);variable<-'score'
  } else if(kind=='categorical') {
   d<-missing_predictor_categorical_data();d$y<-d$y+0.8*sin(seq_len(nrow(d))*1.47)
   f<-fit_missing_predictor_categorical(d);variable<-'habitat'
  } else {
   d<-two_independent_gaussian_mi_data(n=160,missingness='mcar');f<-fit_two_independent_gaussian_mi(d)
  }
  fits[[kind]]<-f
  beta<-coef(f,'mu');sigma<-exp(coef(f,'sigma')[[1L]])
  stopifnot(all(f$model$weights==1),all(f$model$V_known_diag==0))
  if(kind!='two_gaussian') {
   lev<-levels(d[[variable]]);k<-length(lev);n<-nrow(d)
   state_mu<-matrix(NA_real_,n,k)
   for(s in seq_len(k)) {
    state_data<-d;state_data[[variable]]<-factor(rep(lev[[s]],n),levels=lev,ordered=is.ordered(d[[variable]]))
    X<-model.matrix(delete.response(f$model$terms$mu),state_data)
    stopifnot(identical(colnames(X),names(beta)))
    state_mu[,s]<-as.vector(X%*%beta)
   }
   alpha<-coef(f,paste0('mi_',variable))
   if(kind=='ordinal') {
    eta<-as.vector(f$model$missing_predictor$X%*%alpha)
    cut<-f$missing_data$predictors[[variable]]$cutpoints
    prior<-t(vapply(eta,function(a) diff(c(0,plogis(cut-a),1)),numeric(k)))
   } else {
    xp<-model.matrix(~z,d);linear<-matrix(0,n,k)
    for(s in 2:k) linear[,s]<-xp%*%alpha[paste(lev[[s]],colnames(xp),sep=':')]
    prior<-exp(linear-apply(linear,1,max));prior<-prior/rowSums(prior)
   }
   miss<-which(is.na(d[[variable]]));post<-prior[miss,,drop=FALSE]
   for(i in seq_along(miss)) {
    row<-miss[[i]];lp<-log(post[i,])+dnorm(d$y[[row]],state_mu[row,],sigma,log=TRUE)
    post[i,]<-exp(lp-max(lp));post[i,]<-post[i,]/sum(post[i,])
   }
   expected<-numeric(n);observed<-which(!is.na(d[[variable]]))
   expected[observed]<-state_mu[cbind(observed,as.integer(d[[variable]][observed]))]
   expected[miss]<-rowSums(post*state_mu[miss,,drop=FALSE])
   nondegenerate<-any(apply(post,1,max)<0.95)
   stopifnot(nondegenerate)
  } else {
   means<-sapply(c('m1','m2'),function(v) {a<-coef(f,paste0('mi_',v));a[[1L]]+a[[2L]]*d$x})
   tau<-vapply(c('m1','m2'),function(v) coef(f,paste0('sigma_mi_',v))[[1L]],0.0)
   slopes<-beta[c('mi(m1)','mi(m2)')];expected<-beta[['(Intercept)']]+beta[['x']]*d$x
   for(i in seq_len(nrow(d))) {
    actual<-as.numeric(d[i,c('m1','m2')]);missing<-is.na(actual);m<-means[i,];m[!missing]<-actual[!missing]
    residual<-d$y[[i]]-expected[[i]]-sum(slopes*m)
    m[missing]<-m[missing]+tau[missing]^2*slopes[missing]*residual/(sigma^2+sum(tau[missing]^2*slopes[missing]^2))
    expected[[i]]<-expected[[i]]+sum(slopes*m)
   }
   nondegenerate<-TRUE
  }
  actual<-predict(f);fitted_value<-fitted(f)
  delta<-native_prediction_delta(actual,expected);fdelta<-native_prediction_delta(fitted_value,expected)
  list(status=if(max(delta,fdelta)<=out$tolerance)'PASS' else 'FAIL',rows=nrow(d),max_abs_error=delta,fitted_error=fdelta,nondegenerate=nondegenerate,convergence=f$opt$convergence)
 },error=function(e) list(status='ERROR',message=conditionMessage(e)))
 saveRDS(fits,paste0(prefix,'.rds'))
}
out$source_after<-as.list(setNames(vapply(paths,sha,''),paths));out$source_unchanged<-identical(out$source_before,out$source_after)
out$elapsed<-proc.time()[['elapsed']]-start
out$status<-if(out$source_unchanged && all(vapply(out$cases,function(x)identical(x$status,'PASS'),TRUE)))'PASS' else 'FAIL'
jsonlite::write_json(out,paste0(prefix,'.json'),pretty=TRUE,auto_unbox=TRUE,digits=17)
print(out$cases);cat('NATIVE_PREDICTION_NEIGHBOURS_',out$status,'\n',sep='')
if(out$status!='PASS')quit(status=1L)
