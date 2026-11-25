set.seed(20261108)
suppressPackageStartupMessages(library(ape))
tree <- read.tree("tree.nwk"); ids <- sprintf("tip%03d", 1:64)
Cphy <- vcv(tree, corr=TRUE)[ids,ids]
cc <- read.csv("coords.csv"); m <- as.matrix(cc[,2:3]); rownames(m) <- cc$id
D <- as.matrix(dist(m)); rg <- median(D[upper.tri(D)]); Csp <- exp(-D/rg); diag(Csp) <- diag(Csp)+1e-6
n <- 64L; nr <- 30L
z0 <- setNames(rep(c(-1,1), n/2), ids); z1 <- setNames(round(seq(-1,1,length.out=n),6)[sample.int(n)], ids)
ii <- rep(seq_len(n), each=nr); x <- rep(seq(-1.2,1.2,length.out=nr), n)
mk <- function(C){ L <- t(chol(C))
 b0 <- exp(log(0.9)+0.4*z0)*drop(L%*%rnorm(n)); b1 <- exp(log(0.8)-0.4*z1)*drop(L%*%rnorm(n))
 eta <- 0.3+0.5*x+b0[ii]+x*b1[ii]
 data.frame(id=ids[ii], x=x, z0=unname(z0[ii]), z1=unname(z1[ii]),
   y01=rbinom(n*nr,1,plogis(eta)), k=rbinom(n*nr,6,plogis(eta)), trials=6L)}
write.csv(mk(Cphy),"data_phylo.csv",row.names=FALSE); write.csv(mk(Csp),"data_spatial.csv",row.names=FALSE)
