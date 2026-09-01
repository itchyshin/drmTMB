#!/usr/bin/env Rscript
# Bounded public startup + generated inference wrapper regression; no opt-in.
args <- commandArgs(TRUE)
if (length(args) != 2L) stop("usage: run-julia-ayumi-batch.R JULIA_ROOT NEW_JSON")
jroot <- normalizePath(args[1L], mustWork=TRUE); output <- args[2L]
if (file.exists(output)) stop("refusing to overwrite receipt")
if (interactive()) stop("must run as ordinary Rscript")
if (nzchar(Sys.getenv("_R_CHECK_PACKAGE_NAME_"))) stop("do not run this pilot in R CMD check")
Sys.unsetenv(c("DRMTMB_JULIA_TESTS", "NOT_CRAN"))
Sys.setenv(DRM_JL_PATH=jroot, JULIA_NUM_THREADS="4", OPENBLAS_NUM_THREADS="1")
sha <- function(p) digest::digest(file=p,algo="sha256")
files <- c(sort(list.files("R",full.names=TRUE,pattern="[.]R$")),
           sort(list.files(file.path(jroot,"src"),recursive=TRUE,full.names=TRUE,pattern="[.]jl$")))
manifest <- function() as.list(setNames(vapply(files,sha,""),files))
out <- list(source_before=manifest(), runner_sha256=sha("tools/run-julia-ayumi-batch.R"),
            scope="Ordinary batch startup and one-coefficient Gaussian profile; not large-tree timing")
start <- proc.time()[["elapsed"]]
out$result <- tryCatch({
  pkgload::load_all(quiet=TRUE,recompile=FALSE)
  set.seed(29); n <- 80L
  d <- data.frame(x=rnorm(n),z=rnorm(n)); d$y <- 0.4+0.7*d$x-0.2*d$z+0.6*rnorm(n)
  fit <- drmTMB(bf(y~x+z,sigma~1),gaussian(),data=d,engine="julia")
  X <- model.matrix(~x+z,d); b <- solve(crossprod(X),crossprod(X,d$y))
  sse <- sum((d$y-X%*%b)^2)
  half <- sqrt(expm1(qchisq(.90,1)/n)*sse*solve(crossprod(X))[2,2])
  targets <- drm_julia_wald_targets(fit)
  target <- targets[targets$parm=="fixef:mu:x",,drop=FALSE]
  stopifnot(nrow(target)==1L)
  raw <- drm_julia_call_fixef_inference(fit,target,"profile",.90,199L,1L,TRUE)
  ci <- confint(fit,parm="fixef:mu:x",method="profile",level=.90,threads=TRUE)
  runtime <- JuliaCall::julia_eval('Dict("version"=>string(VERSION),"threads"=>Threads.nthreads(),"blas"=>LinearAlgebra.BLAS.get_num_threads(),"source"=>pathof(DRM))')
  checks <- c(converged=is_converged(fit), one_target=raw$attempted==1,
    one_used=raw$used==1, no_failure=raw$failed==0,
    lower_oracle=abs(raw$lower-(b[2]-half))<1e-5,
    upper_oracle=abs(raw$upper-(b[2]+half))<1e-5,
    public_lower=abs(ci$lower-raw$lower)<1e-8,
    public_upper=abs(ci$upper-raw$upper)<1e-8,
    source=normalizePath(runtime$source)==file.path(jroot,"src","DRM.jl"),
    threads=runtime$threads==4, blas=runtime$blas==1,
    no_opt_in=!nzchar(Sys.getenv("NOT_CRAN"))&&!nzchar(Sys.getenv("DRMTMB_JULIA_TESTS")))
  list(checks=as.list(checks),raw=raw,ci=ci,runtime=runtime,
       oracle=c(estimate=b[2],lower=b[2]-half,upper=b[2]+half),
       status=if(all(checks)) "PASS" else "FAIL")
},error=function(e) list(status="ERROR",message=conditionMessage(e)))
out$source_after <- manifest();out$source_unchanged <- identical(out$source_before,out$source_after)
out$elapsed <- proc.time()[["elapsed"]]-start
out$status <- if(out$source_unchanged&&identical(out$result$status,"PASS")) "PASS" else "FAIL"
jsonlite::write_json(out,output,pretty=TRUE,auto_unbox=TRUE,digits=17,na="string",null="null")
cat("AYUMI_BATCH_",out$status," elapsed=",out$elapsed,"\n",sep="")
if(out$status!="PASS") quit(status=1L)
