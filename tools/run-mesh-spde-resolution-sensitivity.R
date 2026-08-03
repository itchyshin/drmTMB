#!/usr/bin/env Rscript

# Fixed-domain mesh-resolution sensitivity control for the fixed-kappa field
# scale.  Each seed uses one observation design and one fine-mesh DGP; the same
# data are then fitted through fine and coarser meshes.  Retain all attempts.
script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value=TRUE)[1L])
root <- normalizePath(file.path(dirname(script), "..")); setwd(root)
pkgload::load_all(root, quiet=TRUE, export_all=FALSE)
out <- Sys.getenv("DRMTMB_MESH_SENSITIVITY_OUT", unset=file.path(root,"docs/dev-log/simulation-artifacts/2026-08-02-mesh-spde-resolution-sensitivity"))
n_rep <- as.integer(Sys.getenv("DRMTMB_MESH_SENSITIVITY_REPS","50")); n_site <- 128L
dir.create(out,recursive=TRUE,showWarnings=FALSE); raw <- file.path(out,"raw-attempts.tsv")
if(file.exists(raw)) stop("Do not overwrite an existing recovery receipt.")
kappa <- 1/20000; s_truth <- 1e-4; residual_sd <- .25; sha <- trimws(system2("git",c("rev-parse","HEAD"),stdout=TRUE))
md5 <- unname(tools::md5sum(normalizePath(script)))
writeLines(c(paste("source_sha",sha,sep="\t"),paste("runner_md5",md5,sep="\t"),paste("host",Sys.info()[["nodename"]],sep="\t"),paste("n_site",n_site,sep="\t"),paste("replicates",n_rep,sep="\t"),paste("kappa_fixed",kappa,sep="\t"),paste("field_scale_truth",s_truth,sep="\t"),paste("design","same_observations_and_DGP_per_seed;fine_vs_coarse_fit",sep="\t")),file.path(out,"metadata.tsv"))
one_mesh <- function(xy,max_n) make_mesh(xy,kappa=kappa,max.edge=c(12000,25000),offset=c(10000,20000),cutoff=100,max.n=max_n)
one <- function(seed) {
  set.seed(seed); xy <- cbind(runif(n_site,0,100000),runif(n_site,0,100000)); rownames(xy)<-as.character(seq_len(n_site)); attr(xy,"crs")<-sf::st_crs(3857); class(xy)<-c("drmTMB_coords",class(xy))
  fine <- one_mesh(xy,4L*n_site); Q <- as.matrix(kappa^4*fine$spde$c0+2*kappa^2*fine$spde$g1+fine$spde$g2)
  omega <- s_truth*as.vector(backsolve(chol(Q),rnorm(ncol(Q)))); dat <- data.frame(y=1.2+as.vector(fine$A_st%*%omega)+rnorm(n_site,sd=residual_sd),site=paste0("o",seq_len(n_site)))
  regimes <- c(coarse=2L*n_site,fine=4L*n_site)
  do.call(rbind,lapply(names(regimes),function(regime){ max_n <- regimes[[regime]]
    mesh_fit <- one_mesh(xy,max_n)
    warn<-character(); fit<-tryCatch(withCallingHandlers(drmTMB(bf(y~spatial(1|site,mesh=mesh_fit),sigma~1),gaussian(),dat),warning=function(w){warn<<-c(warn,conditionMessage(w));invokeRestart("muffleWarning")}),error=identity)
    if(inherits(fit,"error")) return(data.frame(seed,regime,max_n,fit_ok=FALSE,convergence=NA,pdHess=NA,estimate=NA,relative_error=NA,warning=paste(warn,collapse=" | "),error=conditionMessage(fit)))
    est<-unname(fit$sdpars$mu[["spatial(1 | site)"]]); data.frame(seed,regime,max_n,fit_ok=TRUE,convergence=fit$opt$convergence,pdHess=isTRUE(fit$sdr$pdHess),estimate=est,relative_error=est/s_truth-1,warning=paste(warn,collapse=" | "),error="")
  }))
}
rows<-list(); for(i in seq_len(n_rep)){x<-one(2026080400L+i); fresh<-!file.exists(raw);utils::write.table(x,raw,sep="\t",row.names=FALSE,quote=FALSE,na="",append=!fresh,col.names=fresh);rows[[i]]<-x}; rows<-do.call(rbind,rows)
summary<-aggregate(cbind(fit_ok=as.integer(rows$fit_ok),pdHess=as.integer(rows$pdHess),relative_error=rows$relative_error)~regime,rows,mean,na.rm=TRUE);utils::write.table(summary,file.path(out,"summary.tsv"),sep="\t",row.names=FALSE,quote=FALSE);print(summary)
