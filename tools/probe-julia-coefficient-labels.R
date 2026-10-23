args <- commandArgs(trailingOnly=TRUE)
stopifnot(length(args)==2L)
Sys.setenv(DRM_JL_PATH=normalizePath(args[1]),JULIA_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1')
Sys.unsetenv(c('DRMTMB_JULIA_TESTS','NOT_CRAN'))
options(drmTMB.DRM.jl.path=normalizePath(args[1]))
pkgload::load_all('.',quiet=TRUE)
Sys.unsetenv(c('DRMTMB_JULIA_TESTS','NOT_CRAN'))
set.seed(563302); n<-96; x<-rnorm(n);g<-factor(rep(c('a','b','c'),length.out=n))
y<-.4+.7*x+.2*x^2+ifelse(g=='b',.3,ifelse(g=='c',-.2,0))+.1*x*(g=='b')+rnorm(n,sd=.6)
dat<-data.frame(y,x,g); f<-drmTMB::bf(y~x+I(x^2)+g+x:g,sigma~1)
X<-model.matrix(~x+I(x^2)+g+x:g,dat); beta<-drop(solve(crossprod(X),crossprod(X,y)))
started<-proc.time()[['elapsed']]
fit<-drmTMB::drmTMB(f,data=dat,engine='julia')
native_names<-colnames(X)
results<-lapply(c('I(x^2)','gb','x:gb'),function(term)tryCatch({
 out<-confint(fit,parm=paste0('fixef:mu:',term),method='profile',level=.9)
 list(term=term,status='returned',result=out)
},error=function(e)list(term=term,status='error',message=conditionMessage(e))))
out<-list(data=dat,native_names=native_names,oracle_beta=beta,
 public_coefficients=coef(fit),bridge_names=fit$bridge_coef_name_map,
 selectors=results,elapsed=proc.time()[['elapsed']]-started,
 julia_source=JuliaCall::julia_eval('pathof(DRM)'),
 source_sha256=list(R=digest::digest(file='R/julia-bridge.R',algo='sha256'),
 Julia=digest::digest(file=file.path(args[1],'src/bridge.jl'),algo='sha256')))
saveRDS(out,paste0(args[2],'.rds'));jsonlite::write_json(out,paste0(args[2],'.json'),pretty=TRUE,auto_unbox=TRUE,digits=17)
print(out[c('native_names','public_coefficients','bridge_names','selectors','elapsed')])
