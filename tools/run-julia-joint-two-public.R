#!/usr/bin/env Rscript
# Full R -> JuliaCall -> prepared kernel -> R public methods on a frozen fixture.
args <- commandArgs(TRUE)
if(length(args)!=3L) stop("usage: run-julia-joint-two-public.R JULIA_ROOT NATIVE_JSON NEW_PREFIX")
julia_root<-normalizePath(args[1],mustWork=TRUE);fixture<-normalizePath(args[2],mustWork=TRUE);prefix<-args[3]
if(any(file.exists(paste0(prefix,c(".json",".rds"))))) stop("refusing stale output")
Sys.setenv(DRM_JL_PATH=julia_root,DRMTMB_JULIA_TESTS="true",JULIA_NUM_THREADS="1",OPENBLAS_NUM_THREADS="1")
sha<-function(p) digest::digest(file=p,algo="sha256")
manifest<-function() {
 p<-c(sort(list.files("R",pattern="[.]R$",full.names=TRUE)),"NAMESPACE",
 sort(list.files(file.path(julia_root,"src"),pattern="[.]jl$",recursive=TRUE,full.names=TRUE)))
 p<-normalizePath(p,mustWork=TRUE);as.list(setNames(vapply(p,sha,""),p))
}
before<-manifest();pkgload::load_all(".",quiet=TRUE,recompile=FALSE)
ref<-jsonlite::read_json(fixture,simplifyVector=TRUE)
f<-ref$fixture;decode<-function(v,o) {v<-as.numeric(v);v[!o]<-NA_real_;v}
d<-data.frame(y=decode(f$y,f$y_observed),x1=decode(f$x1,f$x1_observed),x2=decode(f$x2,f$x2_observed),z=as.numeric(f$z))
form<-bf(y~mi(x1)+mi(x2)+z,sigma~1)
out<-list(scope="Two independent Gaussian missing predictors, one frozen fixture; not full programme parity or warm performance",
 source_before=before,fixture_sha256=sha(fixture),runner_sha256=sha("tools/run-julia-joint-two-public.R"),native_tolerance=4e-6)
save_receipt<-function() jsonlite::write_json(out,paste0(prefix,".json"),pretty=TRUE,auto_unbox=TRUE,digits=17,na="string",null="null")
tick<-proc.time()[["elapsed"]]
fit<-NULL
out$result<-tryCatch({
 fit<-drmTMB(form,gaussian(),data=d,impute=list(x2=x2~z,x1=x1~z),
 missing=miss_control(response="include",predictor="model"),engine="julia")
 out$runtime<-JuliaCall::julia_eval('Dict("julia"=>string(VERSION),"threads"=>Threads.nthreads(),"blas"=>LinearAlgebra.BLAS.get_num_threads(),"source"=>pathof(DRM))')
 raw<-unname(fit$joint$raw_theta);common<-raw[c(1,4,2,3,5:11)]
 V<-unname(fit$joint$raw_vcov);sdids<-which(fit$joint$natural_sd)
 J<-rep(1,length(raw));J[sdids]<-exp(raw[sdids])
 expected<-raw;expected[sdids]<-J[sdids]
 tables<-lapply(c("x1","x2"),function(v) imputed(fit,variable=v,rows="all"));names(tables)<-c("x1","x2")
 mu_expected<-raw[1]+raw[2]*tables$x1$estimate+raw[3]*tables$x2$estimate+raw[4]*d$z
 fresh<-d[which(complete.cases(d))[1:6],,drop=FALSE]
 errs<-c(theta=max(abs(common-ref$theta)),loglik=abs(as.numeric(logLik(fit))-ref$loglik),
 training=max(abs(predict(fit)-ref$prediction)))
 for(j in 1:2) {
   ntab<-ref[[paste0("imputed",j)]];tab<-tables[[j]]
   errs[paste0("imputed",j)]<-max(abs(tab$estimate-ntab$estimate))
   ids<-which(!tab$observed)
   errs[paste0("imputed",j,"_se")]<-max(abs(tab$std_error[ids]-ntab$std_error[ids]))
 }
 adapter_errors<-c(public_theta=max(abs(unname(unlist(coef(fit)))-expected)),
   public_vcov=max(abs(vcov(fit)-V*outer(J,J))),training=max(abs(predict(fit)-mu_expected)),
   newdata=max(abs(predict(fit,newdata=fresh)-as.numeric(cbind(1,fresh$x1,fresh$x2,fresh$z)%*%raw[1:4]))))
 flags<-c(converged=is_converged(fit),nobs=nobs(fit)==156L,
 rows1=identical(tables$x1$original_row,seq_len(160)),rows2=identical(tables$x2$original_row,seq_len(160)),
 masks1=identical(tables$x1$observed,!is.na(d$x1)),masks2=identical(tables$x2$observed,!is.na(d$x2)),
 residuals=identical(is.na(residuals(fit)),is.na(d$y)),summary=nrow(summary(fit)$coefficients)==11L,
 wald=nrow(confint(fit))==11L,no_se=all(is.na(imputed(fit,variable="x2",se=FALSE)$std_error)))
 native_pass<-all(is.finite(errs)&errs<=4e-6);adapter_pass<-all(flags)&&all(is.finite(adapter_errors)&adapter_errors<=1e-10)
 list(status=if(adapter_pass) "PASS" else "FAIL",native_status=if(native_pass) "PASS" else "FAIL",
 native_errors=as.list(errs),adapter_errors=as.list(adapter_errors),flags=as.list(flags),
 raw_theta=raw,raw_covariance=V,public_covariance=vcov(fit),coef=coef(fit),imputation=tables,
 prediction=predict(fit),newdata=fresh,newdata_prediction=predict(fit,newdata=fresh),
 conditional_covariance=fit$joint$conditional_covariance,loglik=as.numeric(logLik(fit)))
},error=function(e) list(status="ERROR",message=conditionMessage(e)))
out$elapsed<-proc.time()[["elapsed"]]-tick
out$source_after<-manifest();out$source_unchanged<-identical(before,out$source_after)
out$status<-if(out$source_unchanged&&identical(out$result$status,"PASS")) "PASS" else "FAIL"
save_receipt();saveRDS(fit,paste0(prefix,".rds"))
cat("TWO_PUBLIC_",out$status,"; NATIVE_",out$result$native_status,"; elapsed=",out$elapsed,"\n",sep="")
if(out$status!="PASS") quit(status=1L)
