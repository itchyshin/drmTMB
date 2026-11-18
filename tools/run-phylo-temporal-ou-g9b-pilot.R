#!/usr/bin/env Rscript
# Approved bounded G9b pilot: new frozen seeds only; not a G9 replacement.
if (length(commandArgs(trailingOnly = TRUE))) stop('This runner takes no arguments.', call.=FALSE)
root <- normalizePath('.', mustWork=TRUE); pkgload::load_all(root, quiet=TRUE)
out <- Sys.getenv('DRMTMB_PHYLO_TEMPORAL_OU_G9B_PILOT_OUT', unset=file.path(root,'docs/dev-log/simulation-artifacts/2026-09-09-phylo-temporal-ou-g9b-pilot'))
need <- c('estimates.csv','attempts.csv','criteria.csv','provenance.csv','session-info.txt','RESULTS.md')
dir.create(out, recursive=TRUE, showWarnings=FALSE)
if (any(file.exists(file.path(out,need)))) stop('G9b pilot artifacts already exist; do not overwrite.',call.=FALSE)
truth <- c(intercept=0,between=.5,within=.5,sd_temporal=.8,sigma=.4)
cells <- data.frame(id=paste0('P',1:5), seed=2026091301:2026091305,
                    sd_phylo=c(.3,.3,.6,.6,1), decay=c(.15,.7,.4,.15,.7),
                    layout=c('balanced','unbalanced','balanced','unbalanced','balanced'))
times <- function(n, layout) if(layout=='balanced') rep(list(c(0,1,3,5,9,12)),n) else lapply(seq_len(n),function(i) switch(as.character((i-1)%%3+1),'1'=c(0,.5,2,6,11),'2'=c(0,1,4,7),'3'=c(0,2,3,8,12,15)))
run_cell <- function(z) {
  set.seed(z$seed); n <- 50L; tree <- ape::rcoal(n); tree$tip.label <- sprintf('sp_%03d',seq_len(n)); sch <- times(n,z$layout)
  d <- do.call(rbind,Map(function(sp,t) data.frame(species=sp,elapsed=t),tree$tip.label,sch)); d$species <- factor(d$species,levels=tree$tip.label)
  d$between <- rep(sample(rep(c(-.5,.5),each=n/2)),lengths(sch)); d$within <- unlist(lapply(sch,function(t) sample(rep(c(-.5,.5),length.out=length(t)))) )
  A <- ape::vcv(tree,corr=TRUE)[tree$tip.label,tree$tip.label]; stable <- drop(t(chol(A))%*%rnorm(n,sd=z$sd_phylo)); names(stable)<-tree$tip.label
  ou <- unlist(lapply(sch,function(t){R<-exp(-z$decay*abs(outer(t,t,'-')));drop(t(chol(R))%*%rnorm(length(t),sd=truth[['sd_temporal']]))}))
  d$y <- truth[['intercept']]+truth[['between']]*d$between+truth[['within']]*d$within+stable[as.character(d$species)]+ou+rnorm(nrow(d),sd=truth[['sigma']]); d<-d[sample.int(nrow(d)),]
  t0<-proc.time()[['elapsed']]; fit <- tryCatch(drmTMB(bf(y~between+within+phylo(1|species,tree=tree)+temporal(1|species,time=elapsed,structure='ou'),sigma~1),data=d,family=gaussian(),REML=FALSE),error=identity); elapsed<-proc.time()[['elapsed']]-t0
  base<-data.frame(id=z$id,seed=z$seed,layout=z$layout,sd_phylo_truth=z$sd_phylo,decay_truth=z$decay,elapsed_sec=elapsed)
  if(inherits(fit,'error')) return(list(est=transform(base,error=conditionMessage(fit),beta_between=NA,beta_within=NA,beta_intercept=NA,decay=NA),att=data.frame(id=z$id,status='error')))
  tm<-fit$model$structured$temporal_mu; est<-transform(base,error=NA_character_,beta_between=unname(fit$coefficients$mu[['between']]),beta_within=unname(fit$coefficients$mu[['within']]),beta_intercept=unname(fit$coefficients$mu[['(Intercept)']]),decay=unname(fit$decaypars$temporal[[temporal_mu_decay_label(tm)]]))
  a<-fit$temporal_start_attempts; a$id<-z$id; list(est=est,att=a)
}
res<-lapply(seq_len(nrow(cells)),function(i) run_cell(cells[i,,drop=FALSE])); est<-do.call(rbind,lapply(res,`[[`,'est')); att<-do.call(rbind,lapply(res,`[[`,'att'))
criteria<-data.frame(criterion=c('five selected fixtures','two starts per finite fixture','finite contrast estimates','finite decay estimates'),observed=c(nrow(est),sum(table(att$id)==2),sum(is.finite(est$beta_between)&is.finite(est$beta_within)),sum(is.finite(est$decay))),threshold=c('5','5','5','5'));criteria$pass<-criteria$observed==5
write.csv(est,file.path(out,'estimates.csv'),row.names=FALSE);write.csv(att,file.path(out,'attempts.csv'),row.names=FALSE);write.csv(criteria,file.path(out,'criteria.csv'),row.names=FALSE)
write.csv(data.frame(key=c('source_commit','runner_md5','run_utc','seeds'),value=c(system2('git',c('rev-parse','HEAD'),stdout=TRUE),unname(tools::md5sum(sub('^--file=', '', commandArgs(FALSE)[grep('^--file=', commandArgs(FALSE))]))),format(Sys.time(),tz='UTC',usetz=TRUE),paste(cells$seed,collapse=','))),file.path(out,'provenance.csv'),row.names=FALSE);capture.output(sessionInfo(),file=file.path(out,'session-info.txt'))
writeLines(c('# G9b bounded pilot','',sprintf('Fixtures: %d; starts: %d.',nrow(est),nrow(att)),sprintf('Elapsed seconds: %.3f.',sum(est$elapsed_sec)),'Not recovery or interval-calibration evidence.'),file.path(out,'RESULTS.md'))
if(!all(criteria$pass)) stop('G9b pilot incomplete; artifacts retained.',call.=FALSE);cat('PHYLO_TEMPORAL_OU_G9B_PILOT_PASS\n')
