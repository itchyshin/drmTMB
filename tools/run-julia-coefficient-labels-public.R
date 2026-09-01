# Exact native model-matrix oracles, then public R and direct bridge selectors.
args <- commandArgs(trailingOnly=TRUE);stopifnot(length(args)==2L)
jlroot<-normalizePath(args[1]);prefix<-args[2]
stopifnot(!any(file.exists(paste0(prefix,c('.json','.rds')))))
Sys.setenv(DRM_JL_PATH=jlroot,JULIA_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1')
Sys.unsetenv(c('DRMTMB_JULIA_TESTS','NOT_CRAN'));options(drmTMB.DRM.jl.path=jlroot)
paths<-sort(unique(normalizePath(c(list.files('R',pattern='[.]R$',full.names=TRUE),
 list.files(file.path(jlroot,'src'),pattern='[.]jl$',full.names=TRUE,recursive=TRUE),
 'tools/run-julia-coefficient-labels-public.R',file.path(jlroot,c('Project.toml','Manifest.toml'))))))
manifest<-function()as.list(setNames(vapply(paths,function(p)digest::digest(file=p,algo='sha256'),''),paths))
before<-manifest();start<-proc.time()[['elapsed']]
pkgload::load_all('.',quiet=TRUE);Sys.unsetenv(c('DRMTMB_JULIA_TESTS','NOT_CRAN'))
set.seed(563303);n<-96L
base<-data.frame(x=rnorm(n),z=rnorm(n),g=factor(rep(c('a','b','c'),length.out=n)),
 gp=factor(rep(c('a','b: space','c & joined'),length.out=n)),
 h=rep(rep(c(2,10,20),each=4L),length.out=n))
base$gn<-factor(as.character(base$g),levels=c('c','a','b'))
forms<-list(quadratic=~x+I(x^2)+g+x:g,
 punctuation=~x+gp+x:gp,
 two_factors=~g*factor(h),
 no_intercept=~0+g+x:g,
 declared_levels=~gn+x:gn,
 transforms=~scale(x)+poly(z,2)+I(x*z),
 reversed_two_factors=~g+factor(h)+factor(h):g,
 unary_plus=~I(+x),grouped_arithmetic=~I(x+(z+2)),decimal_power=~I(x^2.0),
 nested_precedence=~log1p((1+I(x^2))/2),nested_parentheses=~log1p((I(x^2))),
 nested_scale=~exp((1+scale(x))/2),mixed_scalar=~exp((scale(x)+I(z^2))/2),
 scalar_plain=~sin((x+z)/2),conditional_scalar=~ifelse(x>0,x,0),negated_scalar=~ifelse(!(x>0),x,0))
results<-list();savedfits<-list()
for(name in names(forms)) {
 rhs<-forms[[name]];X<-model.matrix(rhs,base)
 truth<-seq_len(ncol(X))/(3*ncol(X));dat<-base;dat$y<-drop(X%*%truth)+rnorm(n,sd=.6)
 f<-do.call(drmTMB::bf,list(as.formula(paste('y',paste(deparse(rhs,width.cutoff=500),collapse=' '))),sigma~1))
 beta<-drop(solve(crossprod(X),crossprod(X,dat$y)));rss<-sum((dat$y-X%*%beta)^2)
 results[[name]]<-tryCatch({
  fit<-drmTMB::drmTMB(f,data=dat,engine='julia');savedfits[[name]]<-fit
  co<-coef(fit)$mu;expected<-colnames(X)
  list(status='returned',data=dat,X=X,formula=paste(deparse(rhs),collapse=' '),
       expected=expected,actual=names(co),beta=co,oracle_beta=beta,
       coefficient_error=if(setequal(names(co),expected))max(abs(co[expected]-beta))else Inf,
       labels=fit$bridge_public_coef_labels,loglik=as.numeric(logLik(fit)),
       full_beta=fit$coef_vector,V=fit$vcov,
       bridge_beta=unlist(fit$bridge$coefficients,use.names=FALSE),
       bridge_names=fit$bridge$coef_names,
       bridge_V=drmTMB:::drm_julia_vcov(fit$bridge$vcov,fit$bridge$coef_names),
       oracle_loglik=sum(dnorm(dat$y,drop(X%*%beta),sqrt(rss/n),log=TRUE)),
       converged=identical(fit$opt$convergence,0L),rss=rss)
 },error=function(e)list(status='error',message=conditionMessage(e),data=dat,X=X,expected=colnames(X)))
}
# Actual inference on a well-conditioned constant-sigma fixture. Keep every
# failure independently: no failed target may disappear from the denominator.
target_terms<-c('I(x^2)','gb','x:gb')
inference<-setNames(lapply(target_terms,function(x)list(status='blocked_fixture',message='quadratic fit unavailable')),target_terms)
if(!is.null(savedfits$quadratic)) {
 fit<-savedfits$quadratic;r<-results$quadratic
 JuliaCall::julia_command('coefficient_labels_direct(formula,family,data,method,level,B,seed,parm) = DRM.drm_bridge_inference(formula=formula,family=family,data=data,method=method,level=level,B=B,seed=seed,threads=false,parm=parm)')
 capture<-function(f)tryCatch(list(status='returned',value=f()),error=function(e)list(status='error',message=conditionMessage(e)))
 for(term in target_terms) {
  k<-match(term,r$expected)
  width<-sqrt(expm1(qchisq(.9,1)/n)*r$rss*solve(crossprod(r$X))[k,k])
  key<-paste0('fixef:mu:',term)
  public<-capture(function()confint(fit,parm=key,method='profile',level=.9))
  direct<-capture(function()JuliaCall::julia_call('coefficient_labels_direct',fit$bridge_payload$formula,
    fit$model$model_type,as.list(fit$bridge_payload$data),'profile',.9,6L,563303L,key))
  boot<-capture(function()confint(fit,parm=key,method='bootstrap',R=6L,seed=563303L,level=.9))
  directboot<-capture(function()JuliaCall::julia_call('coefficient_labels_direct',fit$bridge_payload$formula,
    fit$model$model_type,as.list(fit$bridge_payload$data),'bootstrap',.9,6L,563303L,key))
  operations<-list(public=public,direct=direct,bootstrap=boot,direct_bootstrap=directboot)
  inference[[term]]<-c(list(status=if(all(vapply(operations,function(x)identical(x$status,'returned'),TRUE)))'returned'else'error',
    oracle=c(r$oracle_beta[k]-width,r$oracle_beta[k]+width)),operations)
 }
}

runtime<-tryCatch(JuliaCall::julia_eval('Dict("source"=>pathof(DRM),"version"=>string(VERSION),"threads"=>Threads.nthreads(),"blas"=>DRM.BLAS.get_num_threads())'),
 error=function(e)list(status='error',message=conditionMessage(e)))
out<-list(results=results,inference=inference,source_before=before,source_after=manifest(),
 runtime=runtime,
 git=list(R=system('git rev-parse HEAD',intern=TRUE),Julia=system2('git',c('-C',shQuote(jlroot),'rev-parse','HEAD'),stdout=TRUE)),
 elapsed=proc.time()[['elapsed']]-start,ordinary_batch=!nzchar(Sys.getenv('DRMTMB_JULIA_TESTS'))&&!nzchar(Sys.getenv('NOT_CRAN')))
checks<-c(cases=identical(names(results),names(forms)),targets=identical(names(inference),target_terms),
 runtime=!identical(runtime$status,'error'),
 ordinary_batch=isTRUE(out$ordinary_batch),source_unchanged=identical(out$source_before,out$source_after))
for(name in names(results)) {
 r<-results[[name]]
 checks[paste0(name,':returned')]<-identical(r$status,'returned')
 checks[paste0(name,':names')]<-!anyDuplicated(r$actual)&&setequal(r$actual,r$expected)
 checks[paste0(name,':coefficient')]<-isTRUE(r$coefficient_error<1e-5)
 checks[paste0(name,':loglik')]<-isTRUE(abs(r$loglik-r$oracle_loglik)<1e-7)
  checks[paste0(name,':converged')]<-isTRUE(r$converged)
  if(identical(r$status,'returned')) {
   keys<-c(paste0('mu_',r$expected),'sigma_(Intercept)')
   b<-r$full_beta[keys];res<-r$data$y-drop(r$X%*%b[seq_len(ncol(r$X))])
   checks[paste0(name,':full_parameters')]<-identical(unname(b[seq_len(ncol(r$X))]),unname(r$beta[r$expected]))&&
    isTRUE(abs(sum(dnorm(r$data$y,drop(r$X%*%b[seq_len(ncol(r$X))]),exp(tail(b,1)),log=TRUE))-r$loglik)<1e-7)
   invvar<-exp(-2*tail(b,1));cross<-2*drop(crossprod(r$X,res))*invvar
   H<-rbind(cbind(crossprod(r$X)*invvar,cross),c(cross,2*sum(res^2)*invvar))
   expectedV<-solve(H)
   checks[paste0(name,':covariance')]<-isTRUE(max(abs(r$V[keys,keys]-expectedV))<1e-7)
   checks[paste0(name,':transport')]<-identical(names(r$full_beta),r$bridge_names)&&
    identical(unname(r$full_beta),r$bridge_beta)&&identical(r$V,r$bridge_V)
  } else {
   checks[paste0(name,c(':covariance',':transport',':full_parameters'))]<-FALSE
  }
}
bounds<-function(x)is.numeric(x$lower)&&length(x$lower)==1L&&is.finite(x$lower)&&is.numeric(x$upper)&&length(x$upper)==1L&&is.finite(x$upper)
for(term in target_terms) {
 r<-inference[[term]];checks[paste0(term,':returned')]<-identical(r$status,'returned')
 if(identical(r$status,'returned')) {
  p<-r$public$value;d<-r$direct$value;b<-r$bootstrap$value;db<-r$direct_bootstrap$value
  checks[paste0(term,':profile')]<-bounds(p)&&identical(p$parm,paste0('fixef:mu:',term))&&isTRUE(max(abs(c(p$lower,p$upper)-r$oracle))<1e-5)&&identical(p$conf.status,'profile')
  checks[paste0(term,':direct_profile')]<-bounds(d)&&isTRUE(max(abs(c(d$lower,d$upper)-r$oracle))<1e-5)&&identical(d$status,'profile')&&identical(d$coef,term)&&isTRUE(d$attempted==1)
  checks[paste0(term,':bootstrap')]<-bounds(b)&&bounds(db)&&identical(b$parm,paste0('fixef:mu:',term))&&isTRUE(max(abs(c(b$lower,b$upper)-c(db$lower,db$upper)))<1e-10)&&identical(b$conf.status,'bootstrap')&&identical(db$coef,term)&&isTRUE(b$bootstrap.n==6)&&isTRUE(db$used==6)&&isTRUE(db$failed==0)
 }
}
out$checks<-as.list(checks);out$status<-if(all(checks))'PASS'else'FAIL'
saveRDS(out,paste0(prefix,'.rds'));jsonlite::write_json(out,paste0(prefix,'.json'),pretty=TRUE,auto_unbox=TRUE,digits=17)
for(name in names(results))cat(name,results[[name]]$status,'coeferror',results[[name]]$coefficient_error,results[[name]]$message,'\n')
for(name in names(inference))cat('INFERENCE',name,inference[[name]]$status,inference[[name]]$message,'\n')
print(checks[!checks]);cat('ELAPSED',out$elapsed,'STATUS',out$status,'\n')
if(!all(checks))stop('Coefficient-label parity checks failed; all results retained')
