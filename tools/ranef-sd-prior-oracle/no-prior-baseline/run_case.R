args <- commandArgs(trailingOnly=TRUE)
stopifnot(length(args)==2L, args[[1]] %in% c('base','candidate'))
label <- args[[1]]; root <- normalizePath(args[[2]], mustWork=TRUE)
snapshot <- file.path(root,label)
stopifnot(requireNamespace('devtools',quietly=TRUE),requireNamespace('TMB',quietly=TRUE),requireNamespace('numDeriv',quietly=TRUE))
cat('label=',label,'\n',sep=''); print(R.version.string); print(packageVersion('TMB'))
devtools::load_all(snapshot,quiet=TRUE)
dll <- getLoadedDLLs()[["drmTMB"]]; stopifnot(!is.null(dll)); dll_path <- normalizePath(dll[["path"]], mustWork=TRUE); cat("DLL_PATH=",dll_path,"\n",sep=""); sha <- function(path) strsplit(system2("shasum",c("-a","256",shQuote(path)),stdout=TRUE)," +")[[1]][1]; loaded_sha <- sha(dll_path); source_sha <- sha(file.path(snapshot,"src","drmTMB.so")); stopifnot(identical(loaded_sha,source_sha)); cat("DLL_SHA256=",loaded_sha,"\n",sep="")
d <- read.csv(file.path(root,'data.csv')); d$g <- factor(d$g)
f <- bf(mu = y ~ x + (1 | g), sigma = ~ x)
p <- drm_priors(drm_prior_normal('mu','x',mean=0.2,sd=1.4))
fits <- list(none=drmTMB(f,data=d,control=drm_control(se=FALSE,logsigma_clamp=NULL)),
             normal=drmTMB(f,data=d,priors=p,control=drm_control(se=FALSE,logsigma_clamp=NULL)))
points <- rbind(c(0.8,0.45,-0.2,0.15,log(0.6)),c(0.5,0.2,-0.4,0.1,log(1.0)),c(1.0,0.7,0.1,-0.1,log(0.3)))
result <- lapply(names(fits), function(nm) {
  z <- fits[[nm]]; op <- z$opt$par
  positions <- c(which(names(z$obj$par)=='beta_mu'),which(names(z$obj$par)=='beta_sigma'),which(names(z$obj$par)=='log_sd_mu'))
  stopifnot(length(positions)==5L,length(op)==5L,all(is.finite(op)))
  at <- lapply(seq_len(nrow(points)),function(i) {
    q <- op; q[positions] <- points[i,]
    H <- numDeriv::jacobian(z$obj$gr,q)
    list(objective=unname(z$obj$fn(q)),gradient=unname(z$obj$gr(q)),hessian=unname(H))
  })
  H <- numDeriv::jacobian(z$obj$gr,op)
  list(kind=nm, names=names(op),positions=positions,theta=unname(op),
       objective=unname(z$opt$objective),data_logLik=as.numeric(logLik(z)),
       gradient=unname(z$obj$gr(op)),hessian=unname(H),
       convergence=as.integer(z$opt$convergence),estimator=as.character(z$estimator),
       penalty=if(is.null(z$fixed_prior_penalty)) NULL else unname(z$fixed_prior_penalty),
       points=at)
})
names(result) <- names(fits)
for(nm in names(result)) {
  q <- result[[nm]]; cat(nm,'objective=',format(q$objective,digits=17),'logLik=',format(q$data_logLik,digits=17),'convergence=',q$convergence,'score=',format(max(abs(q$gradient)),digits=8),'min_eigen=',format(min(eigen((q$hessian+t(q$hessian))/2,symmetric=TRUE,only.values=TRUE)$values),digits=8),'\n')
}
saveRDS(result,file.path(root,paste0(label,'-results.rds')),version=3)
cat('FIT_CASE_PASS\n')
