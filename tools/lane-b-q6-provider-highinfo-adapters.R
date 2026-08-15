# Exact high-information q6 bivariate location fixtures.  Each named ledger
# cell owns only the mu1 intercept-SD target; all slope and mu2 components stay
# outside this targetwise receipt.
lane_b_q6_stop <- function(...) stop(..., call. = FALSE)
lane_b_q6_contracts <- function() {
  provider <- c("phylo", "spatial", "animal", "relmat"); cell_id <- c("mc-0101", "mc-0123", "mc-0145", "mc-0167"); group <- c("species", "site", "id", "id")
  data.frame(cell_id, provider, group, seed=rep(20260731L,4L), n_level=rep(80L,4L), n_each=rep(12L,4L), rung=rep("high_information",4L), dgp_id=paste0("lane_b_",provider,"_q6_mu1_intercept_highinfo_v1"), target_truth=rep(.55,4L), stringsAsFactors=FALSE)
}
lane_b_q6_row <- function(cell, seed, rung) { x<-lane_b_q6_contracts(); r<-x[x$cell_id==cell,,drop=FALSE]; if(nrow(r)!=1L||!identical(as.integer(seed),r$seed[[1L]])||!identical(as.character(rung),r$rung[[1L]])) lane_b_q6_stop("Exact q6 fixture requires its registered cell, seed, and rung."); r }
lane_b_q6_fixture <- function(cell, seed, rung) {
  r<-lane_b_q6_row(cell,seed,rung); set.seed(r$seed[[1L]]); n<-r$n_level[[1L]]; m<-r$n_each[[1L]]; labels<-paste0(if(r$provider[[1L]]=="phylo")"species" else if(r$provider[[1L]]=="spatial")"site" else "id",seq_len(n)); K<-outer(seq_len(n),seq_len(n),function(i,j).32^abs(i-j)); diag(K)<-diag(K)+.25; dimnames(K)<-list(labels,labels); Q<-solve(K); sdv<-c(.55,.38,.32,.50,.35,.30); eff<-t(chol(K))%*%matrix(stats::rnorm(n*6L),n,6L)%*%diag(sdv); ix<-rep(seq_len(n),each=m); x<-stats::rnorm(n*m); z<-stats::rnorm(n*m); y1<-0.15+.25*x-.15*z+eff[ix,1]+eff[ix,2]*x+eff[ix,3]*z+stats::rnorm(n*m,0,.65); y2<--.1+.2*x+.1*z+eff[ix,4]+eff[ix,5]*x+eff[ix,6]*z+stats::rnorm(n*m,0,.70); data<-data.frame(y1,y2,x,z)
  if(r$provider[[1L]]=="phylo") { data$species<-labels[ix]; tree<-structure(list(edge=cbind(rep.int(n+1L,n),seq_len(n)),edge.length=rep(1,n),tip.label=labels,Nnode=1L),class="phylo"); f<-drmTMB::bf(mu1=y1~x+z+drmTMB::phylo(1+x+z|p|species,tree=tree),mu2=y2~x+z+drmTMB::phylo(1+x+z|p|species,tree=tree),sigma1=~1,sigma2=~1,rho12=~1) }
  else if(r$provider[[1L]]=="spatial") { data$site<-labels[ix]; coords<-data.frame(x=cos(seq_len(n)),y=sin(seq_len(n)));rownames(coords)<-labels; f<-drmTMB::bf(mu1=y1~x+z+drmTMB::spatial(1+x+z|p|site,coords=coords),mu2=y2~x+z+drmTMB::spatial(1+x+z|p|site,coords=coords),sigma1=~1,sigma2=~1,rho12=~1) }
  else { data$id<-labels[ix]; f<-if(r$provider[[1L]]=="animal") drmTMB::bf(mu1=y1~x+z+drmTMB::animal(1+x+z|p|id,Ainv=Q),mu2=y2~x+z+drmTMB::animal(1+x+z|p|id,Ainv=Q),sigma1=~1,sigma2=~1,rho12=~1) else drmTMB::bf(mu1=y1~x+z+drmTMB::relmat(1+x+z|p|id,Q=Q),mu2=y2~x+z+drmTMB::relmat(1+x+z|p|id,Q=Q),sigma1=~1,sigma2=~1,rho12=~1) }
  target<-paste0("sd:mu:mu1:",r$provider[[1L]],"(1 | p | ",r$group[[1L]],")"); list(data=data,row=r,target=target,fit=function()drmTMB::drmTMB(f, family=drmTMB::biv_gaussian(),data=data,control=drmTMB::drm_control(optimizer=list(eval.max=5000,iter.max=5000))))
}
