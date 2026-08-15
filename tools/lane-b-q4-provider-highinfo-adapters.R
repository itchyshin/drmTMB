# Exact high-information q4 all-four-intercept fixtures for the remaining
# spatial, animal, and relmat diagnostic rows.  Each cell owns one direct SD.

lane_b_q4_provider_stop <- function(...) stop(..., call. = FALSE)
lane_b_q4_provider_contracts <- function() {
  provider <- rep(c("spatial", "animal", "relmat"), each = 4L)
  axis <- rep(c("mu1", "mu2", "sigma1", "sigma2"), 3L)
  cells <- c(sprintf("mc-%04d", 115:118), sprintf("mc-%04d", 137:140), sprintf("mc-%04d", 159:162))
  group <- ifelse(provider == "spatial", "site", "id")
  data.frame(cell_id=cells, provider=provider, axis=axis, group=group, target_truth=rep(c(.55,.50,.40,.35),3L), seed=rep(20260730L,12L), n_level=rep(60L,12L), n_each=rep(10L,12L), rung=rep("high_information",12L), dgp_id=paste0("lane_b_",provider,"_q4_all_four_highinfo_v1"), stringsAsFactors=FALSE)
}
lane_b_q4_provider_row <- function(cell, seed, rung) {
  x <- lane_b_q4_provider_contracts(); r <- x[x$cell_id == cell,,drop=FALSE]
  if (nrow(r)!=1L || !identical(as.integer(seed),r$seed[[1L]]) || !identical(as.character(rung),r$rung[[1L]])) lane_b_q4_provider_stop("Exact q4 provider fixture requires its registered cell, seed, and rung.")
  r
}
lane_b_q4_provider_fixture <- function(cell, seed, rung) {
  r <- lane_b_q4_provider_row(cell,seed,rung); set.seed(r$seed[[1L]]); nlev<-r$n_level[[1L]]; neach<-r$n_each[[1L]]; labels<-if(r$provider[[1L]]=="spatial")paste0("site",seq_len(nlev)) else paste0("id",seq_len(nlev)); K<-outer(seq_len(nlev),seq_len(nlev),function(i,j).25^abs(i-j)); diag(K)<-diag(K)+.35; dimnames(K)<-list(labels,labels); Q<-solve(K); sds<-c(.55,.50,.40,.35); effects<-t(chol(K))%*%matrix(stats::rnorm(nlev*4L),nlev,4L)%*%diag(sds); ix<-rep(seq_len(nlev),each=neach); data<-data.frame(y1=.20+effects[ix,1L]+stats::rnorm(nlev*neach,0,exp(-.8+effects[ix,3L])),y2=-.10+effects[ix,2L]+stats::rnorm(nlev*neach,0,exp(-.7+effects[ix,4L])));
  if(r$provider[[1L]]=="spatial") { data$site<-labels[ix]; coords<-data.frame(x=seq_len(nlev),y=sqrt(seq_len(nlev))); rownames(coords)<-labels; fml<-drmTMB::bf(mu1=y1~1+drmTMB::spatial(1|p|site,coords=coords),mu2=y2~1+drmTMB::spatial(1|p|site,coords=coords),sigma1=~1+drmTMB::spatial(1|p|site,coords=coords),sigma2=~1+drmTMB::spatial(1|p|site,coords=coords),rho12=~1) } else { data$id<-labels[ix]; fml<-if(r$provider[[1L]]=="animal") drmTMB::bf(mu1=y1~1+drmTMB::animal(1|p|id,Ainv=Q),mu2=y2~1+drmTMB::animal(1|p|id,Ainv=Q),sigma1=~1+drmTMB::animal(1|p|id,Ainv=Q),sigma2=~1+drmTMB::animal(1|p|id,Ainv=Q),rho12=~1) else drmTMB::bf(mu1=y1~1+drmTMB::relmat(1|p|id,Q=Q),mu2=y2~1+drmTMB::relmat(1|p|id,Q=Q),sigma1=~1+drmTMB::relmat(1|p|id,Q=Q),sigma2=~1+drmTMB::relmat(1|p|id,Q=Q),rho12=~1) }
  target<-paste0("sd:mu:",r$axis[[1L]],":",r$provider[[1L]],"(1 | p | ",r$group[[1L]],")")
  list(data=data,row=r,profile_parameter=target,fit=function()drmTMB::drmTMB(fml,family=drmTMB::biv_gaussian(),data=data,control=drmTMB::drm_control(optimizer=list(eval.max=3000,iter.max=3000))))
}
