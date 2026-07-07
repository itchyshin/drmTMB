#!/usr/bin/env Rscript
# ML-vs-REML profile-coverage + scale runner for the phylo sigma-intercept cell.
# Shardable: args --g= --method=ML|REML --seed_start= --n_rep= --out_dir=
# ML and REML at a given g share seeds (paired). Records per-fit seconds (for the
# Ayumi-scale timing probe). Writes one TSV per invocation; combine by reading all.
args <- commandArgs(TRUE)
ga <- function(k,d){v<-grep(paste0("^--",k,"="),args,value=TRUE); if(length(v)) sub(paste0("^--",k,"="),"",v[1]) else d}
G<-as.integer(ga("g","8")); METHOD<-ga("method","ML"); SEED0<-as.integer(ga("seed_start","1"))
NREP<-as.integer(ga("n_rep","60")); OUT<-ga("out_dir",".")
find_repo_root<-function(s=getwd()){d<-normalizePath(s); while(!file.exists(file.path(d,"DESCRIPTION"))&&dirname(d)!=d) d<-dirname(d); d}
REPO<-find_repo_root()
if(requireNamespace("drmTMB",quietly=TRUE)) suppressPackageStartupMessages(library(drmTMB)) else suppressWarnings(suppressMessages(devtools::load_all(REPO,quiet=TRUE)))
suppressMessages(library(ape))
TRUTH<-0.60; ls0<- -0.90; b0<-0.40; b1<-0.25; n_each<-20L
set.seed(1000L+G); tree<-ape::rcoal(G); labs<-tree$tip.label
K<-drmTMB:::drm_phylo_tip_covariance(tree); cholK<-t(chol(K))
form<-bf(y~x, sigma~phylo(1|species, tree=tree))
parm<-"sd:sigma:phylo(1 | species)"
dir.create(OUT,recursive=TRUE,showWarnings=FALSE)
outfile<-file.path(OUT,sprintf("cov-g%03d-%s-s%d.tsv",G,METHOD,SEED0))
sim<-function(seed){set.seed(seed); u<-as.vector(cholK%*%rnorm(G))*TRUTH; names(u)<-labs
  sp<-rep(labs,each=n_each); x<-rep(seq(-1.2,1.2,length.out=n_each),times=G)
  y<-(b0+b1*x)+exp(ls0+u[sp])*rnorm(G*n_each); data.frame(y=y,x=x,species=sp,stringsAsFactors=FALSE)}
clean<-function(s) gsub("[\t\r\n]+"," ",substr(as.character(s),1,60))
reml<-identical(METHOD,"REML"); rows<-vector("list",NREP)
for(i in seq_len(NREP)){
  seed<-SEED0+i-1L; dat<-sim(seed); t0<-proc.time()[["elapsed"]]
  fit<-tryCatch(drmTMB(form,family=gaussian(),data=dat,engine="tmb",REML=reml,
    control=drm_control(optimizer=list(eval.max=1400,iter.max=1400))),error=function(e) e)
  if(inherits(fit,"error")){rows[[i]]<-data.frame(g=G,method=METHOD,seed=seed,conv=NA_integer_,sd_est=NA_real_,lo=NA_real_,hi=NA_real_,finite=FALSE,covers=NA,secs=round(proc.time()[["elapsed"]]-t0,2),status=clean(conditionMessage(fit))); next}
  conv<-fit$opt$convergence; sd_est<-tryCatch(unname(fit$sdpars$sigma[[1]]),error=function(e) NA_real_)
  ci<-tryCatch(withCallingHandlers(stats::confint(fit,parm=parm,method="profile",level=0.95,profile_engine="tmbprofile",trace=FALSE),warning=function(w) invokeRestart("muffleWarning")),error=function(e) e)
  lo<-if(inherits(ci,"error")) NA_real_ else ci$lower[[1]]; hi<-if(inherits(ci,"error")) NA_real_ else ci$upper[[1]]
  fin<-is.finite(lo)&&is.finite(hi); cov<-if(fin) (TRUTH>=lo&&TRUTH<=hi) else NA
  rows[[i]]<-data.frame(g=G,method=METHOD,seed=seed,conv=conv,sd_est=sd_est,lo=lo,hi=hi,finite=fin,covers=cov,secs=round(proc.time()[["elapsed"]]-t0,2),status="ok")
  if(i%%20L==0L) cat(sprintf("[g%d %s] %d/%d\n",G,METHOD,i,NREP))
}
res<-do.call(rbind,rows)
utils::write.table(res,outfile,sep="\t",quote=FALSE,row.names=FALSE)
cat("wrote",outfile,"n=",nrow(res),"\n")
