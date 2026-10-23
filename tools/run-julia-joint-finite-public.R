#!/usr/bin/env Rscript
# Frozen generated native inputs, default fits, and actual public Julia bridge.
a <- commandArgs(TRUE)
if(length(a)!=3L) stop("usage: run-julia-joint-finite-public.R JULIA_ROOT NATIVE_JSON NEW_PREFIX")
jroot <- normalizePath(a[1],mustWork=TRUE);fixture <- normalizePath(a[2],mustWork=TRUE);prefix <- a[3]
if(any(file.exists(paste0(prefix,c(".json",".rds"))))) stop("refusing stale outputs")
Sys.setenv(DRM_JL_PATH=jroot,DRMTMB_JULIA_TESTS="true",JULIA_NUM_THREADS="1",OPENBLAS_NUM_THREADS="1")
sha <- function(p) digest::digest(file=p,algo="sha256")
manifest <- function() {
  p <- normalizePath(c(sort(list.files("R",pattern="[.]R$",full.names=TRUE)),"NAMESPACE",
    sort(list.files(file.path(jroot,"src"),pattern="[.]jl$",full.names=TRUE,recursive=TRUE))),mustWork=TRUE)
  as.list(setNames(vapply(p,sha,""),p))
}
before <- manifest();pkgload::load_all(quiet=TRUE,recompile=FALSE)
ref <- jsonlite::read_json(fixture,simplifyVector=TRUE)
out <- list(scope="One fixed-effect ordinal/categorical missing predictor with Gaussian response; two frozen cases, not programme completion",
  source_before=before,fixture_sha256=sha(fixture),runner_sha256=sha("tools/run-julia-joint-finite-public.R"),
  native_tolerance=4e-6,adapter_tolerance=1e-10,cases=list())
fits <- list();tick <- proc.time()[["elapsed"]]
for(kind in c("ordinal","categorical")) {
  out$cases[[kind]] <- tryCatch({
    f <- ref$cases[[kind]];y <- as.numeric(f$y);y[!f$observed_y] <- NA_real_
    x <- factor(f$levels[replace(as.integer(f$x),!f$observed_x,NA_integer_)],levels=f$levels,ordered=kind=="ordinal")
    d <- data.frame(y=y,x=x,z=f$z);form <- bf(y~z+mi(x),sigma~1)
    fit <- drmTMB(form,gaussian(),data=d,impute=list(x=impute_model(x~z,
      family=if(kind=="ordinal") cumulative_logit() else categorical())),
      missing=miss_control(response="include",predictor="model"),engine="julia")
    fits[[kind]] <- fit
    out$runtime <- JuliaCall::julia_eval('Dict("julia"=>string(VERSION),"threads"=>Threads.nthreads(),"blas"=>LinearAlgebra.BLAS.get_num_threads(),"source"=>pathof(DRM))')
    raw <- unname(fit$joint$raw_theta);V <- unname(fit$joint$raw_vcov)
    keep <- if(kind=="ordinal") c(1:5,8L) else seq_along(raw)
    tab <- imputed(fit,"x",rows="all");ids <- which(!f$observed_x)
    probs <- fit$joint$conditional_probabilities;info <- fit$missing_data$predictors$x
    state <- matrix(as.numeric(f$state_design %*% raw[1:4]),nrow=f$n,byrow=TRUE)
    expected <- rowSums(probs*state)
    fresh <- d[which(complete.cases(d))[1:6],,drop=FALSE]
    X <- model.matrix(~z+x,fresh)
    errs <- c(theta=max(abs(raw-f$theta)),prediction=max(abs(predict(fit)-f$prediction)),
      loglik=abs(as.numeric(logLik(fit))-f$loglik),imputation=max(abs(tab$estimate-f$imputation$estimate)),
      posterior=max(abs(info$conditional_probabilities-f$conditional_probabilities)))
    if(kind=="ordinal") errs <- c(errs,imputation_sd=max(abs(tab$std_error[ids]-f$imputation$std_error[ids])))
    adapter <- c(coef=max(abs(unname(unlist(coef(fit)))-raw[keep])),
      covariance=max(abs(vcov(fit)-V[keep,keep])),training=max(abs(predict(fit)-expected)),
      newdata=max(abs(predict(fit,newdata=fresh)-as.numeric(X%*%raw[1:4]))))
    flags <- c(converged=is_converged(fit),nobs=nobs(fit)==f$nobs,
      rows=identical(tab$original_row,as.integer(f$original_row)),masks=identical(tab$observed,as.logical(f$observed_x)),
      residuals=identical(is.na(residuals(fit)),is.na(y)),coefficient_blocks=identical(names(coef(fit)),c("mu","sigma","mi_x")),
      no_ordinal_response=is.null(fit$ordinal),summary=nrow(summary(fit)$coefficients)==length(keep),
      wald=nrow(confint(fit))==length(keep),level_names=identical(colnames(info$conditional_probabilities),f$levels),
      no_se=all(is.na(imputed(fit,"x",se=FALSE)$std_error)))
    if(kind=="ordinal") flags <- c(flags,cutpoints=length(info$cutpoints)==2L,
      expected_score=identical(info$conditional_expected_score,as.numeric(tab$estimate[ids]))) else
      flags <- c(flags,modal_category=identical(info$conditional_modal_category,as.numeric(tab$estimate[ids])),
        unavailable=all(is.na(tab$std_error)))
    list(status=if(all(flags)&&all(is.finite(adapter)&adapter<=1e-10)) "PASS" else "FAIL",
      native_status=if(all(is.finite(errs)&errs<=4e-6)) "PASS" else "FAIL",
      native_errors=as.list(errs),adapter_errors=as.list(adapter),flags=as.list(flags),
      raw_theta=raw,raw_covariance=V,public_covariance=vcov(fit),coefficients=coef(fit),
      coefficient_terms=lapply(coef(fit),names),newdata=fresh,
      newdata_rows=which(complete.cases(d))[1:6],newdata_prediction=predict(fit,newdata=fresh),
      imputation=tab,prediction=predict(fit),predictor_info=info,loglik=as.numeric(logLik(fit)))
  },error=function(e) list(status="ERROR",native_status="UNMEASURED",message=conditionMessage(e)))
}
out$elapsed <- proc.time()[["elapsed"]]-tick;out$source_after <- manifest()
out$source_unchanged <- identical(before,out$source_after)
out$status <- if(out$source_unchanged&&all(vapply(out$cases,function(x) identical(x$status,"PASS"),TRUE))) "PASS" else "FAIL"
jsonlite::write_json(out,paste0(prefix,".json"),pretty=TRUE,auto_unbox=TRUE,digits=17,na="string",null="null")
saveRDS(fits,paste0(prefix,".rds"))
cat("FINITE_PUBLIC_",out$status,"; elapsed=",out$elapsed,"\n",sep="")
if(out$status!="PASS") quit(status=1L)
