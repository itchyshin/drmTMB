#!/usr/bin/env Rscript

# Recovery-grade successor to run-mesh-spde-recovery.R.  It is interruption
# safe: every attempt is appended before the next begins.  Do not overwrite an
# existing output directory.
script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L])
root <- normalizePath(file.path(dirname(script), ".."))
setwd(root)
pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
out <- Sys.getenv("DRMTMB_MESH_RECOVERY_OUT", unset = file.path(
  root, "docs/dev-log/simulation-artifacts/2026-08-02-mesh-spde-field-scale-recovery-v2"
))
n_rep <- as.integer(Sys.getenv("DRMTMB_MESH_RECOVERY_REPS", "50"))
n_sites <- as.integer(strsplit(Sys.getenv("DRMTMB_MESH_RECOVERY_SITES", "64,128,256"), ",")[[1L]])
stopifnot(n_rep >= 1L, all(n_sites >= 16L))
dir.create(out, recursive = TRUE, showWarnings = FALSE)
raw <- file.path(out, "raw-attempts.tsv")
if (file.exists(raw)) stop("Output directory already has raw-attempts.tsv; do not overwrite a receipt.")
kappa <- 1 / 20000; field_scale <- 1e-4; residual_sd <- 0.25; base_seed <- 2026080300L
gate <- list(min_rate = 1, max_abs_bias = .15, max_rmse_log = .30)
sha <- trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE))
md5 <- unname(tools::md5sum(normalizePath(script)))
meta <- function(status, finish = "", raw_md5 = "") {
  writeLines(c(
    paste("run_status", status, sep="\t"), paste("source_sha", sha, sep="\t"),
    paste("runner_md5", md5, sep="\t"), paste("host", Sys.info()[["nodename"]], sep="\t"),
    paste("platform", R.version$platform, sep="\t"), paste("r_version", R.version.string, sep="\t"),
    paste("kappa_fixed", kappa, sep="\t"), paste("field_scale_truth", field_scale, sep="\t"),
    paste("residual_sd_truth", residual_sd, sep="\t"), paste("n_sites", paste(n_sites,collapse=","),sep="\t"),
    paste("replicates_per_rung", n_rep, sep="\t"), paste("attempts_expected", length(n_sites)*n_rep,sep="\t"),
    paste("attempt_policy", "append_each_attempt", sep="\t"),
    paste("gate_min_convergence_and_pdHess_rate", gate$min_rate, sep="\t"),
    paste("gate_max_abs_relative_bias", gate$max_abs_bias, sep="\t"),
    paste("gate_max_rmse_log_scale", gate$max_rmse_log, sep="\t"),
    paste("finished_utc", finish,sep="\t"), paste("raw_attempts_md5", raw_md5,sep="\t")
  ), file.path(out,"metadata.tsv"))
}
meta("RUNNING")
one <- function(n_site, seed) {
  warn <- character(); nv <- NA_integer_
  tryCatch({
    set.seed(seed); xy <- cbind(runif(n_site,0,100000),runif(n_site,0,100000))
    rownames(xy) <- as.character(seq_len(n_site)); attr(xy,"crs") <- sf::st_crs(3857)
    class(xy) <- c("drmTMB_coords",class(xy))
    mesh <- make_mesh(xy,kappa=kappa,max.edge=c(12000,25000),offset=c(10000,20000),cutoff=100,max.n=max(160L,2L*n_site))
    nv <- ncol(mesh$A_st); Q <- as.matrix(kappa^4*mesh$spde$c0+2*kappa^2*mesh$spde$g1+mesh$spde$g2)
    omega <- field_scale*as.vector(backsolve(chol(Q),rnorm(nv)))
    dat <- data.frame(y=1.2+as.vector(mesh$A_st%*%omega)+rnorm(n_site,sd=residual_sd),site=paste0("o",seq_len(n_site)))
    fit <- withCallingHandlers(drmTMB(bf(y~spatial(1|site,mesh=mesh),sigma~1),gaussian(),dat),warning=function(w){warn<<-c(warn,conditionMessage(w));invokeRestart("muffleWarning")})
    est <- unname(fit$sdpars$mu[["spatial(1 | site)"]])
    data.frame(n_site,seed,n_vertex=nv,fit_ok=TRUE,convergence=fit$opt$convergence,pdHess=isTRUE(fit$sdr$pdHess),estimate=est,relative_error=est/field_scale-1,warning=paste(warn,collapse=" | "),error="")
  },error=function(e) data.frame(n_site,seed,n_vertex=nv,fit_ok=FALSE,convergence=NA_integer_,pdHess=NA,estimate=NA_real_,relative_error=NA_real_,warning=paste(warn,collapse=" | "),error=conditionMessage(e)))
}
rows <- list()
for (n in n_sites) for (i in seq_len(n_rep)) {
  x <- one(n,base_seed+match(n,n_sites)*100000L+i)
  fresh <- !file.exists(raw); utils::write.table(x,raw,sep="\t",row.names=FALSE,quote=FALSE,na="",append=!fresh,col.names=fresh)
  rows[[length(rows)+1L]] <- x
}
rows <- do.call(rbind,rows)
summary <- do.call(rbind,lapply(split(rows,rows$n_site),function(x){
  good <- x$fit_ok & x$convergence==0L & x$pdHess & is.finite(x$estimate)
  bias <- mean(x$estimate[good]/field_scale-1); rmse <- sqrt(mean((log(x$estimate[good])-log(field_scale))^2))
  data.frame(n_site=x$n_site[[1]],attempts=nrow(x),usable=sum(good),convergence_rate=mean(x$fit_ok&x$convergence==0L,na.rm=TRUE),pdHess_rate=mean(x$pdHess,na.rm=TRUE),relative_bias=bias,rmse_log_scale=rmse,gate_pass=sum(good)==nrow(x)&&abs(bias)<=gate$max_abs_bias&&rmse<=gate$max_rmse_log)
}))
utils::write.table(summary,file.path(out,"summary.tsv"),sep="\t",row.names=FALSE,quote=FALSE)
utils::write.table(data.frame(expected_attempts=length(n_sites)*n_rep,observed_attempts=nrow(rows),all_rungs_pass=all(summary$gate_pass),decision=if(all(summary$gate_pass))"PASS_POINT_RECOVERY_GATE"else"BLOCKED_POINT_RECOVERY_GATE"),file.path(out,"gate.tsv"),sep="\t",row.names=FALSE,quote=FALSE)
meta("COMPLETE",format(Sys.time(),tz="UTC",usetz=TRUE),unname(tools::md5sum(raw)))
print(summary)
