#!/usr/bin/env Rscript
# Native generated outputs, retained defaults and all four response/predictor masks.
a<-commandArgs(TRUE);if(length(a)!=1L)stop('usage: export-finite-joint-reference.R NEW_PREFIX')
prefix<-a[1];if(any(file.exists(paste0(prefix,c('.json','.rds')))))stop('refusing stale output')
pkgload::load_all(quiet=TRUE,recompile=FALSE)
sha<-function(p)digest::digest(file=p,algo='sha256')
manifest<-function(){p<-c(sort(list.files('R',pattern='[.]R$',full.names=TRUE)),'NAMESPACE',sort(list.files('src',pattern='[.](cpp|h|hpp)$',full.names=TRUE,recursive=TRUE)));as.list(setNames(vapply(p,sha,''),p))}
before<-manifest();out<-list(schema='finite_joint_native_v1',source_before=before,
 runner_sha256=sha('tools/export-finite-joint-reference.R'),R_version=R.version.string,
 TMB_version=as.character(packageVersion('TMB')),loaded_native_DLL_sha256=sha(getLoadedDLLs()[['drmTMB']][['path']]),cases=list())
fits<-list();tick<-proc.time()[['elapsed']]
for(kind in c('ordinal','categorical')){
 set.seed(if(kind=='ordinal') 96403L else 96404L);n<-180L;z<-rnorm(n)
 if(kind=='ordinal'){
   latent<-.6*z+rlogis(n);code<-as.integer(cut(latent,breaks=c(-Inf,-.6,.8,Inf)))
   x<-ordered(c('low','medium','high')[code],levels=c('low','medium','high'))
   family<-cumulative_logit()
 }else{
   logits<-cbind(0,.2+.5*z,-.1-.4*z);prob<-exp(logits);prob<-prob/rowSums(prob)
   code<-vapply(seq_len(n),function(i)sample.int(3,1,prob=prob[i,]),integer(1))
   x<-factor(c('forest','grass','wetland')[code],levels=c('forest','grass','wetland'))
   family<-categorical()
 }
 y<-.3+.25*z+c(-.5,.1,.65)[code]+rnorm(n,sd=.55)
 x[seq_len(n)%%7==0]<-NA;y[c(5L,7L,21L,42L)]<-NA_real_
 d<-data.frame(y=y,x=x,z=z)
 fit<-drmTMB(bf(y~z+mi(x),sigma~1),data=d,impute=list(x=impute_model(x~z,family=family)),
   missing=miss_control(response='include',predictor='model'))
 fits[[kind]]<-fit;m<-fit$model$missing_predictor;K<-length(m$levels)
 theta<-unname(fit$opt$par);names_raw<-names(fit$opt$par)
 stopifnot(sum(names_raw=='beta_mu')==ncol(fit$model$X$mu),sum(names_raw=='beta_sigma')==1L)
 observed_x<-!is.na(d$x);observed_y<-!is.na(d$y)
 state_design<-unname(as.matrix(m$X_mu_state));obsrows<-which(observed_x)
 stopifnot(nrow(state_design)==n*K,
   max(abs(state_design[(obsrows-1L)*K+as.integer(d$x[obsrows]),,drop=FALSE]-fit$model$X$mu[obsrows,,drop=FALSE]))<1e-12)
 step<-rep(c(.035,-.025,.045,-.03),length.out=length(theta))
 points<-lapply(list(theta,theta+step,theta-2*step),function(t)list(theta=t,nll=fit$obj$fn(t),gradient=as.numeric(fit$obj$gr(t))))
 fit$obj$fn(fit$opt$par)
 im<-imputed(fit,'x',rows='all')
 info<-fit$missing_data$predictors$x
 enc<-function(v)replace(v,is.na(v),0)
 out$cases[[kind]]<-list(kind=kind,levels=unname(m$levels),n=n,K=K,
   y=enc(as.numeric(d$y)),x=enc(as.integer(d$x)),z=z,observed_y=observed_y,observed_x=observed_x,
   original_row=seq_len(n),state_design=state_design,state_layout='row_then_state',
   X_mu=unname(fit$model$X$mu),X_sigma=unname(fit$model$X$sigma),X_predictor=unname(m$X),
   mu_names=unname(colnames(fit$model$X$mu)),sigma_names=unname(colnames(fit$model$X$sigma)),
   predictor_names=unname(colnames(m$X)),raw_names=names_raw,theta=theta,
   covariance=unname(fit$sdr$cov.fixed),cutpoints=info$cutpoints,
   coefficient_blocks=coef(fit),conditional_probabilities=unname(info$conditional_probabilities),
   conditional_model_rows=info$model_row,imputation=im,prediction=unname(predict(fit)),
   points=points,loglik=as.numeric(logLik(fit)),nobs=nobs(fit),native_convergence=fit$opt$convergence,
   native_message=fit$opt$message,optimizer_control=fit$control$optimizer,
   fit_control=unclass(fit$control),control_argument='omitted_defaults')
 cat(kind,'native convergence',fit$opt$convergence,'raw:',paste(names_raw,collapse=','),'\n')
}
out$elapsed<-proc.time()[['elapsed']]-tick;out$source_after<-manifest();out$source_unchanged<-identical(before,out$source_after)
jsonlite::write_json(out,paste0(prefix,'.json'),pretty=TRUE,auto_unbox=TRUE,digits=17,na='string',null='null');saveRDS(fits,paste0(prefix,'.rds'))
stopifnot(out$source_unchanged)
cat('FINITE_NATIVE_EXPORT_PASS seconds=',out$elapsed,'\n')
