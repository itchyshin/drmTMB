#!/usr/bin/env Rscript
# Recheck retained transport/oracle values and exact current inputs; never refit.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) %in% c(1L, 2L))
x <- readRDS(args[[1L]])
scalar <- function(x, finite=TRUE) {
  stopifnot(is.numeric(x),length(x)==1L,!is.na(x))
  if(finite) stopifnot(is.finite(x))
  invisible(TRUE)
}
wrapper_hash <- function() {
  candidates <- list()
  walk <- function(z) {
    if(!is.call(z) && !is.expression(z)) return(invisible(NULL))
    if(is.call(z) && identical(z[[1]],quote(paste)) &&
       any(vapply(as.list(z)[-1L],function(v) is.character(v) &&
           any(startsWith(v,'function drmTMB_drm_bridge_fixef_inference(')),TRUE)))
      candidates[[length(candidates)+1L]] <<- eval(z,baseenv())
    for(v in as.list(z)) if(is.call(v) || is.expression(v)) walk(v)
  }
  definitions <- Filter(function(z) is.call(z) && identical(z[[1]],quote(`<-`)) &&
    identical(z[[2]],quote(drm_julia_setup)),as.list(parse('R/julia-bridge.R')))
  stopifnot(length(definitions)==1L,identical(definitions[[1]][[3]][[1]],quote(`function`)))
  walk(definitions[[1]][[3]][[3]])
  stopifnot(length(candidates)==1L)
  digest::digest(candidates[[1L]],algo='sha256',serialize=FALSE)
}
validate <- function(x) {
  scalar(x$elapsed); scalar(x$loglik); scalar(x$level); scalar(x$tolerance)
  scalar(x$runtime$threads); scalar(x$runtime$blas)
  stopifnot(is.numeric(x$oracle),length(x$oracle)==2L,all(is.finite(x$oracle)))
  stopifnot(is.data.frame(x$injected_sd),nrow(x$injected_sd)==1L)
  scalar(x$injected_sd$lower); scalar(x$injected_sd$upper)
  stopifnot(is.data.frame(x$success),nrow(x$success)==1L)
  scalar(x$success$lower); scalar(x$success$upper)
  stopifnot(identical(x$success$parm,'fixef:mu:x'),identical(x$success$method,'profile'),
            identical(x$success$level,.9),identical(x$success$profile.engine,'julia_profile_result'))
  stopifnot(is.numeric(x$coefficients$mu),length(x$coefficients$mu)==2L,all(is.finite(x$coefficients$mu)))
  scalar(x$coefficients$sigma)
  stopifnot(identical(x$status,'PASS'),isTRUE(x$ordinary_batch),
            is.finite(x$elapsed),x$elapsed >= 0,x$elapsed < 180)
  stopifnot(identical(x$batch_environment$DRMTMB_JULIA_TESTS,''), identical(x$batch_environment$NOT_CRAN,''))
  stopifnot(is.list(x$source_before),is.list(x$source_after),
            identical(x$source_before,x$source_after),!anyDuplicated(names(x$source_before)))
  jl_root <- normalizePath('../DRM.jl',mustWork=TRUE)
  expected_paths <- sort(unique(normalizePath(c(
    list.files('R',recursive=TRUE,full.names=TRUE,pattern='[.]R$'),
    list.files(file.path(jl_root,'src'),recursive=TRUE,full.names=TRUE,pattern='[.]jl$'),
    'tools/run-julia-profile-status-public.R','tools/check-julia-profile-status-receipt.R',
    'tests/testthat/test-julia-inference.R',file.path(jl_root,c('Project.toml','Manifest.toml'))),mustWork=TRUE)))
  stopifnot(identical(sort(names(x$source_before)),expected_paths))
  for (path in names(x$source_before)) {
    stopifnot(file.exists(path),identical(digest::digest(file=path,algo='sha256'),x$source_before[[path]]))
  }
  loaded <- grep('/src/DRM[.]jl$',names(x$source_before),value=TRUE)
  stopifnot(length(loaded)==1L,is.character(x$runtime$source),length(x$runtime$source)==1L,
            identical(normalizePath(x$runtime$source,mustWork=TRUE),normalizePath(loaded,mustWork=TRUE)),
            identical(x$wrapper_sha256,wrapper_hash()))
  stopifnot(is.data.frame(x$data),nrow(x$data)==80L,isTRUE(x$fit_converged),
            identical(x$level,.9), identical(x$tolerance,1e-5))
  X <- cbind(1,x$data$x); y <- x$data$y; beta <- solve(crossprod(X),crossprod(X,y))
  stopifnot(max(abs(unname(x$coefficients$mu)-as.vector(beta))) < x$tolerance)
  rss <- sum((y-X%*%beta)^2)
  stopifnot(abs(unname(x$coefficients$sigma)-log(sqrt(rss/length(y)))) < x$tolerance)
  halfwidth <- sqrt(expm1(qchisq(x$level,1)/length(y))*rss*solve(crossprod(X))[2,2])
  recomputed <- c(beta[2]-halfwidth,beta[2]+halfwidth)
  stopifnot(max(abs(x$oracle-recomputed))<1e-12,
            abs(x$loglik - sum(dnorm(y,as.vector(X%*%beta),sqrt(rss/length(y)),log=TRUE))) < 1e-5)
  stopifnot(x$runtime$threads == 1,x$runtime$blas == 1,
            identical(x$success$conf.status,'profile'),
            length(x$oracle)==2L, all(is.finite(x$oracle)),
            max(abs(c(x$success$lower,x$success$upper)-x$oracle))<1e-5)
  expected <- as.vector(outer(c('FALSE','TRUE'),c('lower','upper','both','other','searched','empty','good'),paste,sep=':'))
  stopifnot(setequal(names(x$injected_fixed),expected),length(x$injected_fixed)==14L)
  for (key in names(x$injected_fixed)) {
    parts <- strsplit(key,':',fixed=TRUE)[[1L]]; old <- parts[1]=='TRUE'; scenario <- parts[2]
    row <- x$injected_fixed[[key]]
    stopifnot(is.data.frame(row),nrow(row)==1L,is.character(row$profile.message),
              length(row$profile.message)==1L,!is.na(row$profile.message))
    failed <- scenario %in% c('lower','upper','both','empty') || (old && scenario=='other')
    stopifnot(identical(row$parm,'fixef:mu:x'),identical(row$conf.status,if(failed) 'profile_failed' else 'profile'))
    stopifnot(identical(row$lower,if(scenario %in% c('lower','both','searched','empty')) -Inf else .2),
              identical(row$upper,if(scenario %in% c('upper','both')) Inf else .7))
    if(failed) stopifnot(grepl('failed',row$profile.message,fixed=TRUE))
    if(!old && scenario=='searched') stopifnot(grepl('searched range',row$profile.message,fixed=TRUE))
  }
  stopifnot(x$injected_sd$lower==0,abs(x$injected_sd$upper-2*sqrt(2))<1e-12,
            identical(x$injected_sd$parm,'sd:mu:phylo(1 | species)'),
            identical(x$injected_sd$conf.status,'profile_failed'))
  TRUE
}
stopifnot(validate(x))
cat('PROFILE_STATUS_RECEIPT_PASS: actual-success oracle and15 injected transport cases; current source hashes match\n')
if(length(args)==2L) {
  stopifnot(args[[2L]]=='--self-test')
  bad <- x; bad$injected_fixed[['FALSE:lower']]$conf.status <- 'profile'
  bad2 <- x; bad2$injected_sd$conf.status <- 'profile'
  bad3 <- x; bad3$success$lower <- bad3$success$lower + .1
  bad4 <- x; key <- names(bad4$source_before)[[1L]]
  bad4$source_before[[key]] <- bad4$source_after[[key]] <- paste(rep('0',64),collapse='')
  bad5 <- x; bad5$success$lower <- bad5$success$upper <- NULL
  bad6 <- x; bad6$coefficients$mu <- NULL
  bad7 <- x; bad7$loglik <- NULL
  bad8 <- x; bad8$runtime$source <- '/tmp/not-the-loaded-engine.jl'
  bad9 <- x; bad9$wrapper_sha256 <- paste(rep('0',64),collapse='')
  bad10 <- x; bad10$runtime$threads <- NULL
  bad11 <- x; bad11$injected_sd$lower <- NULL
  bad12 <- x; critical <- grep('/src/inference[.]jl$',names(bad12$source_before),value=TRUE)
  bad12$source_before[critical] <- bad12$source_after[critical] <- NULL
  for(damaged in list(bad,bad2,bad3,bad4,bad5,bad6,bad7,bad8,bad9,bad10,bad11,bad12)) {
    rejected <- tryCatch({validate(damaged);FALSE},error=function(e)TRUE)
    stopifnot(rejected)
  }
  cat('PROFILE_STATUS_SELFTEST_PASS:12 damaged receipts rejected\n')
}
