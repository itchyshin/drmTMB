#!/usr/bin/env Rscript
write_tsv <- function(x, path) utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE)
one <- function(seed, sha, md5) {
  set.seed(seed); ng <- 32L; ne <- 50L; id <- factor(rep(seq_len(ng), each = ne)); x <- rnorm(ng * ne); x <- x - ave(x, id, FUN = mean); x <- x / sd(x)
  b <- rnorm(ng, sd = .45); names(b) <- levels(id); mu <- plogis(-.15 + .35*x); sigma <- exp(-1 + b[id]*x); zoi <- plogis(-.7); coi <- plogis(.1); boundary <- rbinom(length(x), 1L, zoi)
  y <- rbeta(length(x), mu/sigma^2, (1-mu)/sigma^2); y[boundary == 1L] <- rbinom(sum(boundary), 1L, coi)
  fit <- tryCatch(drmTMB::drmTMB(drmTMB::bf(y ~ x, sigma ~ x + (0 + x | id), zoi ~ 1, coi ~ 1), data = data.frame(y,x,id), family = drmTMB::zero_one_beta(), control = drmTMB::drm_control(se=TRUE, optimizer=list(eval.max=2000L,iter.max=2000L))), error=identity)
  if (inherits(fit,"error")) return(data.frame(seed,source_sha=sha,runner_md5=md5,status="fit_error",error=conditionMessage(fit)))
  tau <- unname(fit$sdpars$sigma[["(0 + x | id)"]]); uh <- ranef(fit,"sigma")$terms[["(0 + x | id)"]]
  data.frame(seed,source_sha=sha,runner_md5=md5,status="fit_ok",convergence=fit$opt$convergence,pdHess=isTRUE(fit$sdr$pdHess),max_gradient=max(abs(fit$obj$gr(fit$opt$par))),tau_truth=.45,tau_hat=tau,mode_correlation=cor(uh[names(b)],b),boundary_hit=!is.finite(tau)||tau<=.05||tau>=2.5)
}
script <- sub("^--file=","",grep("^--file=",commandArgs(FALSE),value=TRUE)[1]); root <- normalizePath(file.path(dirname(script),"..")); setwd(root); pkgload::load_all(root,quiet=TRUE,export_all=FALSE)
out <- file.path(root,"docs/dev-log/implementation-recovery/2026-07-30-lane-c-z5-zob-sigma-slope-local-run-1"); dir.create(out,recursive=TRUE,showWarnings=FALSE); sha <- trimws(system2("git",c("rev-parse","HEAD"),stdout=TRUE)); md5 <- unname(tools::md5sum(script))
a <- do.call(rbind,lapply(2026073701:2026073704,one,sha=sha,md5=md5)); write_tsv(a,file.path(out,"raw-attempts.tsv")); ok <- with(a,status=="fit_ok"&convergence==0L&pdHess&max_gradient<=.01&!boundary_hit&mode_correlation>.45); err <- if(any(ok))mean(abs(a$tau_hat[ok]/.45-1))else NA_real_; decision <- if(all(ok)&&is.finite(err)&&err<=.4)"PASS_POINT_RECOVERY_LOCAL"else"BLOCKED_LOCAL_FIXTURE"; write_tsv(data.frame(planned_attempts=4L,attempted_attempts=nrow(a),passed_attempts=sum(ok),mean_tau_relative_error=err,decision),file.path(out,"summary.tsv"))
