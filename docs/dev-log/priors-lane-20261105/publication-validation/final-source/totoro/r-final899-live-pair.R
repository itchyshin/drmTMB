.libPaths(c('/home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b/r-final899-lib',.libPaths()))
library(drmTMB,lib.loc='/home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b/r-final899-lib')
Sys.setenv(DRMODELS_JL_PATH='/home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b/julia-final727-src',JULIA_HOME='/home/snakagaw/hsq_work/julia-1.10.10/bin',JULIA_NUM_THREADS='4',JULIA_DEPOT_PATH='/home/snakagaw/hsq_work/julia-depot:/home/snakagaw/.julia',NOT_CRAN='true')
d<-data.frame(x=c(-2,-1,0,1,2,3,4), y=c(-1.2,-0.3,0.3,0.8,0.7,2.1,1.9),b=c(0,1,0,1,0,1,1))
cases<-list(
 list(id='gaussian-mu-sigma',f=bf(mu=y~x,sigma=~x),fam=gaussian(),p=drm_priors(drm_prior_normal('mu','x',mean=0.3,sd=2),drm_prior_normal('sigma','x',mean=-0.1,sd=0.8))),
 list(id='binomial-partial',f=bf(mu=b~x),fam=binomial(),p=drm_priors(drm_prior_normal('mu','x',mean=0.3,sd=2))),
 list(id='gaussian-zero-ridge',f=bf(mu=y~x,sigma=~1),fam=gaussian(),p=drm_priors(drm_prior_ridge('mu','x',lambda=0))))
fd<-data.frame(f=factor(rep(c("a","b","c"),each=4)),x=rep(c(-1,0,1,2),3))
fd$y<-rep(c(0.2,0.8,1.1),each=4)+0.4*fd$x+rep(c(-0.1,0.2,-0.2,0.1),3)
cases[[4]]<-list(id='gaussian-factor-interaction',data=fd,f=bf(mu=y~f*x,sigma=~1),fam=gaussian(),p=drm_priors(drm_prior_normal('mu','fb:x',sd=2)))
cases[[5]]<-list(id='gaussian-no-intercept-factor',data=fd,f=bf(mu=y~0+f+x,sigma=~1),fam=gaussian(),p=drm_priors(drm_prior_ridge('mu','all',lambda=0.2,intercept='exclude')))
rows<-list()
for(ca in cases){
 dd<-if(is.null(ca$data))d else ca$data
 a<-drmTMB(ca$f,ca$fam,data=dd,priors=ca$p)
 b<-drmTMB(ca$f,ca$fam,data=dd,priors=ca$p,engine='julia')
 aa<-unlist(coef(a));bb<-unlist(coef(b))
 stopifnot(identical(names(aa),names(bb)))
 delta<-max(abs(aa-bb));dll<-abs(as.numeric(logLik(a))-as.numeric(logLik(b)));dp<-abs(a$fixed_prior_penalty-b$fixed_prior_penalty)
 dq<-abs(a$penalized_objective-b$penalized_objective);dg<-max(abs(a$prior_gradient-b$prior_gradient))
 stopifnot(dq<=1e-8,dg<=1e-6)
 cat(ca$id,' COEF_MAX_ABS ',delta,' LOGLIK_ABS ',dll,' PRIOR_ABS ',dp,' ESTIMATORS ',a$estimator,b$estimator,'\n')
 stopifnot(delta<=1e-6,dll<=1e-8,dp<=1e-8,identical(a$estimator,b$estimator))
 stopifnot(isTRUE(all.equal(a$resolved_priors,b$resolved_priors)))
 if(ca$id!='gaussian-zero-ridge'){
  stopifnot(inherits(try(confint(b),silent=TRUE),'try-error'),inherits(try(summary(b,conf.int=TRUE),silent=TRUE),'try-error'),inherits(try(AIC(b),silent=TRUE),'try-error'))
  sm<-summary(b)$coefficients;stopifnot(all(is.na(sm$p.value)))
 }
 rows[[ca$id]]<-data.frame(case=ca$id,coef_max_abs=delta,loglik_abs=dll,prior_abs=dp,objective_abs=dq,prior_gradient_abs=dg,estimator=a$estimator)
}
write.csv(do.call(rbind,rows),'/home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b/evidence/r-final899-live-pair.csv',row.names=FALSE)
cat('LIVE_PRIOR_PAIR_PASS\n')
