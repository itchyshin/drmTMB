O <- "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/w2ps"
tree <- ape::read.tree(file.path(O,"tree.nwk"))
for (k in c("phy","sp")) {
d <- read.csv(file.path(O, if (k=="phy") "data_phylo.csv" else "data_spatial.csv"))
ct <- read.csv(file.path(O, paste0("r_g",k,".csv"))); e <- ct$estimate
ids <- sort(unique(d$id))
C <- if (k=="phy") ape::vcv(tree, corr=TRUE)[ids,ids] else { cc <- read.csv(file.path(O,"coords.csv")); m<-as.matrix(cc[,2:3]); rownames(m)<-cc$id; m<-m[ids,]; D<-as.matrix(dist(m)); r<-median(D[upper.tri(D)]); K<-exp(-D/r); diag(K)<-diag(K)+1e-6; K}
gi <- match(d$id, ids); z0 <- tapply(d$z0, d$id, `[`, 1)[ids]; z1 <- tapply(d$z1, d$id, `[`, 1)[ids]
s0 <- exp(e[4]+e[5]*z0); s1 <- exp(e[6]+e[7]*z1)
S0 <- outer(s0,s0)*C; S1 <- outer(s1,s1)*C
V <- S0[gi,gi] + outer(d$x,d$x)*S1[gi,gi] + diag(exp(2*e[3]), nrow(d))
r <- d$yg - e[1] - e[2]*d$x
ll <- mvtnorm::dmvnorm(r, sigma=V, log=TRUE)
cat(k, sprintf("dense ll %.8f  R ll %s\n", ll, readLines(file.path(O,paste0("r_g",k,"_ll.txt")))))
}
