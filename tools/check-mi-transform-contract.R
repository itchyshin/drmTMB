#!/usr/bin/env Rscript
# Bounded uncertainty contract; no coverage or warm-speed claim.
args <- commandArgs(TRUE)
if(length(args)!=1L) stop('usage: check-mi-transform-contract.R NEW_JSON')
output <- args[[1]]
if(file.exists(output)) stop('refusing existing receipt')
source_paths <- c(sort(list.files('R',pattern='[.]R$',full.names=TRUE)),
  'NAMESPACE','tools/check-mi-transform-contract.R',
  'tests/testthat/test-missing-predictor-transformed-covariance.R',
  'tests/testthat/test-missing-predictor-public-covariance.R',
  'tests/testthat/test-julia-joint-methods.R','tests/testthat/test-profile-targets.R')
manifest <- function() as.list(setNames(vapply(source_paths,function(p) digest::digest(file=p,algo='sha256'),''),source_paths))
before <- manifest(); tick <- proc.time()[['elapsed']]
pkgload::load_all(quiet=TRUE,recompile=FALSE)
selected <- c('profile target inventory lists fixed effects',
  'profile_targets exposes available confidence-interval targets',
  'profile_targets marks dropped TMB objects as unavailable',
  'confint returns Wald fixed-effect intervals',
  'confint marks invalid Wald standard errors unavailable by row',
  'confint marks non-positive Hessian Wald intervals unavailable',
  'confint returns bootstrap intervals for direct targets')
receipt <- list(scope='Native predictor transformed covariance and Wald; bridge interval adapters; ordinary neighbours. No joint bootstrap or coverage claim.',
  source_before=before,R_version=R.version.string,selected_profile_tests=selected,
  native_DLL_sha256=digest::digest(file=getLoadedDLLs()[['drmTMB']][['path']],algo='sha256'))
error <- tryCatch({
  for(file in c('test-missing-predictor-transformed-covariance.R','test-missing-predictor-public-covariance.R','test-julia-joint-methods.R'))
    testthat::test_file(file.path('tests/testthat',file),stop_on_failure=TRUE)
  env <- new.env(parent=globalenv()); env$test_that <- testthat::test_that
  for(n in getNamespaceExports('testthat')) assign(n,getExportedValue('testthat',n),env)
  exprs <- parse('tests/testthat/test-profile-targets.R'); first_test <- FALSE; executed <- character()
  for(expr in exprs) {
    is_test <- is.call(expr)&&identical(expr[[1]],as.name('test_that'))
    if(is_test) {
      first_test <- TRUE
      if(as.character(expr[[2]]) %in% selected) {eval(expr,env); executed <- c(executed,as.character(expr[[2]]))}
    } else if(!first_test) eval(expr,env)
  }
  stopifnot(setequal(executed,selected)); NULL
},error=function(e) conditionMessage(e))
receipt$elapsed_seconds_including_startup <- proc.time()[['elapsed']]-tick
receipt$source_after <- manifest();receipt$source_unchanged <- identical(before,receipt$source_after)
receipt$status <- if(is.null(error)&&receipt$source_unchanged)'PASS' else 'FAIL'
receipt$error <- error
jsonlite::write_json(receipt,output,pretty=TRUE,auto_unbox=TRUE,digits=17,null='null')
if(receipt$status!='PASS') stop(if(is.null(error)) 'source changed' else error)
cat('MI_TRANSFORM_CONTRACT_PASS\n')
