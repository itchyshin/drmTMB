# Fixed-parameter AGHQ integrator spot check (issue 934). Run from the package root: Rscript spot.R
# Compares drm_o3_marginal_ll() with brute-force integrate() at fixed (beta, theta, sd). No fitting.
# Pure R, a few seconds. Reproduces the doc 224 s7a integrator figures, which had no retained script.
source("R/aghq-coxreid.R")
set.seed(11L); nid<-28L; ne<-6L; g<-rep(seq_len(nid),each=ne); N<-nid*ne
x<-rnorm(N); u<-rnorm(nid,0,0.8); y<-rbinom(N,1L,plogis(-0.3+0.7*x+u[g]))
X<-cbind(1,x); gi<-split(seq_len(N),g); z<-rep(1,N); tr<-rep(1,N)
beta<-c(-0.3,0.7); sd<-0.8
brute<-function(fam,beta,theta,sd,X,z,y,gi,tr){ s<-0
 for(idx in gi){ f<-function(u) vapply(u,function(uu) exp(drm_o3_cluster_ll(uu,beta,theta,fam,X[idx,,drop=FALSE],z[idx],y[idx],tr[idx])+dnorm(uu,0,sd,log=TRUE)),1)
  s<-s+log(integrate(f,-12*sd,12*sd,rel.tol=1e-12,subdivisions=2000L)$value)}; s}
b<-brute("binomial",beta,NULL,sd,X,z,y,gi,tr)
cat("BINOMIAL fixed-parameter marginal; brute integrate() =",format(b,digits=15),"\n")
for(nq in c(1,3,5,9,15,25,41)){ a<-drm_o3_marginal_ll(beta,NULL,sd,"binomial",X,z,y,gi,tr,drm_o3_gh(nq)); cat(sprintf("  nq=%2d  aghq=%.12f  abs.err=%.2e\n",nq,a,abs(a-b)))}
# ordinal
set.seed(21L);K<-4L;nid<-28L;ne<-8L;N<-nid*ne;g<-rep(seq_len(nid),each=ne);x<-rnorm(N)
ct<-c(-1,0,1.2);u<-rnorm(nid,0,0.8);mu<-0.7*x+u[g];yo<-integer(N)
for(i in seq_len(N)){pk<-diff(c(0,plogis(c(ct-mu[i],Inf))));yo[i]<-sample.int(K,1L,prob=pk)}
Xo<-cbind(x);zo<-rep(1,N);gio<-split(seq_len(N),g);tro<-rep(1,N)
theta<-c(-1,log(1),log(1.2)); bo<-0.7; sdo<-0.8
b2<-brute("cumulative_logit",bo,theta,sdo,Xo,zo,yo,gio,tro)
cat("ORDINAL fixed-parameter marginal; brute integrate() =",format(b2,digits=15),"\n")
for(nq in c(1,3,5,9,15,25,41)){ a<-drm_o3_marginal_ll(bo,theta,sdo,"cumulative_logit",Xo,zo,yo,gio,tro,drm_o3_gh(nq)); cat(sprintf("  nq=%2d  aghq=%.12f  abs.err=%.2e\n",nq,a,abs(a-b2)))}
