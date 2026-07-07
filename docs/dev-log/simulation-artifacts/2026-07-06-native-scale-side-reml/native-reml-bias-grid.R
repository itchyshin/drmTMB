#!/usr/bin/env Rscript
# Native (engine="tmb") ML-vs-REML bias grid, phylo sigma-intercept cell.
# Tests the scale-side REML change: does adding beta_sigma to the Laplace block
# debias the downward-biased sigma random-effect SD?
find_repo_root <- function(start=getwd()){d<-normalizePath(start); while(!file.exists(file.path(d,"DESCRIPTION"))&&dirname(d)!=d) d<-dirname(d); d}
REPO<-find_repo_root(); suppressWarnings(suppressMessages(devtools::load_all(REPO,quiet=TRUE)))
suppressMessages(library(ape))
`%||%`<-function(x,y) if(is.null(x)||(length(x)==1&&is.na(x))) y else x
cat("loaded drmTMB from", REPO, "\n")

g<-8L; n_each<-20L; NREP<-30L
sd_sigma_true<-0.60; log_sigma0<- -0.90; b0<-0.40; b1<-0.25
set.seed(7); tree<-ape::rcoal(g); labels<-tree$tip.label
K<-drmTMB:::drm_phylo_tip_covariance(tree); cholK<-t(chol(K))
form<-bf(y~x, sigma~phylo(1|species, tree=tree))
sd_of<-function(fit){s<-tryCatch(fit$sdpars$sigma,error=function(e) NULL); if(is.null(s)||!length(s)) NA_real_ else unname(s[[1L]])}
sim<-function(seed){set.seed(seed)
  u<-as.vector(cholK%*%rnorm(g))*sd_sigma_true; names(u)<-labels
  sp<-rep(labels,each=n_each); x<-rep(seq(-1.2,1.2,length.out=n_each),times=g)
  y<-(b0+b1*x)+exp(log_sigma0+u[sp])*rnorm(g*n_each)
  data.frame(y=y,x=x,species=sp,stringsAsFactors=FALSE)}

# --- first-fit smoke: catch any error from the validator/random-block change ---
cat("\n=== smoke: one native REML fit ===\n")
sm<-tryCatch(drmTMB(form,family=gaussian(),data=sim(2001L),engine="tmb",REML=TRUE),error=function(e) e)
if(inherits(sm,"error")){ cat("REML FIT ERROR:\n", conditionMessage(sm),"\n\nSTOPPING.\n"); quit(status=0) }
cat("  REML fit ran: conv=",sm$opt$convergence,"  sd_sigma=",round(sd_of(sm),3),
    "  estimator=",tryCatch(attr(sm,"REML"),error=function(e) NA) %||% sm$estimator %||% "?","\n")

res<-data.frame()
for(r in seq_len(NREP)){
  dat<-sim(2000L+r)
  fm<-tryCatch(drmTMB(form,family=gaussian(),data=dat,engine="tmb",REML=FALSE),error=function(e) e)
  fr<-tryCatch(drmTMB(form,family=gaussian(),data=dat,engine="tmb",REML=TRUE ),error=function(e) e)
  res<-rbind(res,data.frame(rep=r,
    sd_ml  = if(inherits(fm,"error")) NA_real_ else sd_of(fm),
    sd_reml= if(inherits(fr,"error")) NA_real_ else sd_of(fr),
    conv_reml = if(inherits(fr,"error")) NA else fr$opt$convergence))
  if(r%%5L==0L) cat(sprintf("  rep %d/%d: ml=%.3f reml=%.3f\n",r,NREP,res$sd_ml[r],res$sd_reml[r]))
}
ok<-res[is.finite(res$sd_ml)&is.finite(res$sd_reml),]
cat(sprintf("\nn usable = %d/%d ; truth = %.3f\n",nrow(ok),NREP,sd_sigma_true))
cat(sprintf("mean sd_ml   = %.3f  (bias %+.3f)\n",mean(ok$sd_ml),  mean(ok$sd_ml)-sd_sigma_true))
cat(sprintf("mean sd_reml = %.3f  (bias %+.3f)\n",mean(ok$sd_reml),mean(ok$sd_reml)-sd_sigma_true))
cat(sprintf("REML - ML    = %+.3f  (SE %.3f)\n",mean(ok$sd_reml-ok$sd_ml),sd(ok$sd_reml-ok$sd_ml)/sqrt(nrow(ok))))
cat(sprintf("reps REML > ML: %d/%d\n",sum(ok$sd_reml>ok$sd_ml),nrow(ok)))
d<-mean(ok$sd_reml-ok$sd_ml); se<-sd(ok$sd_reml-ok$sd_ml)/sqrt(nrow(ok))
cat("\nVERDICT: native REML ",
    if(d>2*se) "PULLS THE SD UP (debiases) ***" else if(d< -2*se) "pulls DOWN (wrong)" else "no clear effect","\n")
cat("GRID DONE\n")
