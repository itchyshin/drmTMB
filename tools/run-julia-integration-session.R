args<-commandArgs(TRUE);stopifnot(length(args)==2L)
jroot<-normalizePath(args[1],mustWork=TRUE);output<-args[2];stopifnot(!file.exists(output))
Sys.setenv(DRM_JL_PATH=jroot,JULIA_NUM_THREADS="1",OPENBLAS_NUM_THREADS="1")
pkgload::load_all(quiet=TRUE,recompile=FALSE);Sys.unsetenv(c("NOT_CRAN","DRMTMB_JULIA_TESTS"))
base<-"docs/dev-log/evidence/julia-r-parity"
paths<-c(single=file.path(jroot,base,"missing-predictor-oracle/native-mi-oracle-003.json"),two=file.path(base,"two-gaussian/two-gaussian-native-001.json"),finite=file.path(base,"finite-state/finite-native-003.json"))
refs<-lapply(paths,jsonlite::read_json,simplifyVector=TRUE)
checks<-list();objects<-list();start<-proc.time()[["elapsed"]]
capture<-function(name,body){tick<-proc.time()[["elapsed"]];checks[[name]]<<-tryCatch({value<-body();list(status="PASS",elapsed=proc.time()[["elapsed"]]-tick,value=value)},error=function(e)list(status="FAIL",elapsed=proc.time()[["elapsed"]]-tick,message=conditionMessage(e)))}
set.seed(290831);ordinary<-data.frame(x=rnorm(80),g=factor(rep(c("plain","a: b","a & b","last"),20)))
ordinary$y<-.4+.7*ordinary$x+rnorm(80,sd=.7)
ordinary_run<-function(){fit<-drmTMB(bf(y~x*g,sigma~1),data=ordinary,engine="julia");X<-model.matrix(~x*g,ordinary);b<-solve(crossprod(X),crossprod(X,ordinary$y));stopifnot(is_converged(fit),max(abs(coef(fit)$mu[colnames(X)]-b))<1e-8,max(abs(predict(fit,newdata=ordinary)-X%*%b))<1e-8);list(coef=coef(fit),loglik=as.numeric(logLik(fit)))}
capture("ordinary_before",ordinary_run)
models<-list()
for(kind in c("gaussian","bernoulli")){
 f<-refs$single$cases[[kind]]$fixture;decode<-function(x)suppressWarnings(as.numeric(x))
 d<-data.frame(y=decode(f$y),x=decode(f$x),z=decode(f$z));if(kind=="bernoulli")d$x<-factor(d$x,levels=c(0,1))
 models[[kind]]<-list(d=d,formula=bf(y~z+mi(x),sigma~1),impute=if(kind=="gaussian")list(x=x~z) else list(x=impute_model(x~z,family=binomial())),variables="x",rhs=~z+x,sigma=~1)
}
f<-refs$two$fixture;dec<-function(x,o){x<-as.numeric(x);x[!o]<-NA_real_;x}
models$two<-list(d=data.frame(y=dec(f$y,f$y_observed),x1=dec(f$x1,f$x1_observed),x2=dec(f$x2,f$x2_observed),z=f$z),formula=bf(y~mi(x1)+mi(x2)+z,sigma~1),impute=list(x1=x1~z,x2=x2~z),variables=c("x1","x2"),rhs=~x1+x2+z,sigma=~1)
for(kind in c("ordinal","categorical")){
 f<-refs$finite$cases[[kind]];y<-as.numeric(f$y);y[!f$observed_y]<-NA_real_;x<-factor(f$levels[replace(as.integer(f$x),!f$observed_x,NA_integer_)],levels=f$levels,ordered=kind=="ordinal")
 models[[kind]]<-list(d=data.frame(y=y,x=x,z=f$z),formula=bf(y~z+mi(x),sigma~1),impute=list(x=impute_model(x~z,family=if(kind=="ordinal")cumulative_logit()else categorical())),variables="x",rhs=~z+x,sigma=~1)
}
p<-models$gaussian;p$d$g<-factor(rep(c("plain","a: b","a & b","last"),length.out=nrow(p$d)));p$formula<-bf(y~mi(x)+g+z:g,sigma~g+z:g);p$rhs<-~x+g+z:g;p$sigma<-~g+z:g;models$punctuated_joint<-p
for(kind in names(models))local({k<-kind;m<-models[[k]];capture(k,function(){
 fit<-drmTMB(m$formula,gaussian(),data=m$d,impute=m$impute,missing=miss_control(response="include",predictor="model"),engine="julia");objects[[k]]<<-fit
 stopifnot(inherits(fit,"drmTMB_julia_joint"),is_converged(fit),nobs(fit)==sum(!is.na(m$d$y)),identical(is.na(residuals(fit)),is.na(m$d$y)))
 tabs<-setNames(lapply(m$variables,function(v)imputed(fit,variable=v,rows="all")),m$variables)
 for(v in m$variables)stopifnot(identical(tabs[[v]]$original_row,seq_len(nrow(m$d))),identical(tabs[[v]]$observed,!is.na(m$d[[v]])))
 fresh<-m$d[which(complete.cases(m$d))[1:8],,drop=FALSE];design<-fresh
 if(k=="bernoulli")design$x<-as.numeric(as.character(design$x))
 X<-model.matrix(m$rhs,design);Z<-model.matrix(m$sigma,design)
 for(v in m$variables){
 term_id<-match(v,attr(terms(m$rhs),"term.labels"));ids<-which(attr(X,"assign")==term_id)
 stopifnot(length(ids)>0L,all(startsWith(colnames(X)[ids],v)))
 colnames(X)[ids]<-paste0("mi(",v,")",substring(colnames(X)[ids],nchar(v)+1L))
 }
 bm<-coef(fit)$mu;bs<-coef(fit)$sigma
 stopifnot(identical(colnames(X),names(bm)),identical(colnames(Z),names(bs)))
 error_mu<-max(abs(predict(fit,newdata=fresh)-drop(X%*%bm)));error_sigma<-max(abs(predict(fit,newdata=fresh,dpar="sigma")-exp(drop(Z%*%bs))))
 stopifnot(error_mu<1e-10,error_sigma<1e-10,identical(rownames(vcov(fit)),names(fit$coef_vector)),nrow(summary(fit)$coefficients)==length(fit$coef_vector),nrow(confint(fit))==length(fit$coef_vector))
 refusals<-setNames(lapply(c("profile","bootstrap"),function(method)tryCatch({confint(fit,method=method);"ACCEPTED"},error=function(e)conditionMessage(e))),c("profile","bootstrap"))
 stopifnot(all(vapply(refusals,function(x)grepl("not implemented",x,fixed=TRUE),TRUE)))
 list(mu_error=error_mu,sigma_error=error_sigma,coef=coef(fit),covariance=vcov(fit),imputation=tabs,refusals=refusals,loglik=as.numeric(logLik(fit)),newdata=fresh,newdata_mu=predict(fit,newdata=fresh))
})})
capture("ordinary_after",ordinary_run)
expected<-c("ordinary_before","gaussian","bernoulli","two","ordinal","categorical","punctuated_joint","ordinary_after")
passed<-identical(names(checks),expected)&&all(vapply(checks,function(x)identical(x$status,"PASS"),TRUE))
repeat_equal<-identical(checks$ordinary_before$value,checks$ordinary_after$value)
runtime<-JuliaCall::julia_eval('Dict("source"=>pathof(DRM),"julia"=>string(VERSION),"threads"=>Threads.nthreads(),"blas"=>LinearAlgebra.BLAS.get_num_threads())')
out<-list(status=if(passed&&repeat_equal)"PASS"else"FAIL",checks=checks,repeat_equal=repeat_equal,runtime=runtime,fixtures=as.list(setNames(vapply(paths,function(p)digest::digest(file=p,algo="sha256"),""),paths)),elapsed=proc.time()[["elapsed"]]-start,scope="One-session dispatch/metadata/prediction regression; not frozen native numerical-parity clearance, coverage, or performance")
jsonlite::write_json(out,output,pretty=TRUE,auto_unbox=TRUE,digits=17,na="string",null="null");saveRDS(objects,sub("[.]json$",".rds",output))
cat("ONE_SESSION_",out$status," elapsed=",out$elapsed,"\n",sep="");if(out$status!="PASS")quit(status=1L)
