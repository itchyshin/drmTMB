# Weak-probe family for the Binomial phylo / spatial (1 + x | g) q2 route: 64 tips x 16 Bernoulli rows,
# slope SD 0.33-0.49 (sd1 = exp(log 0.4 - 0.2 z1)), intercept SD 0.9 exp(0.4 z0), beta (0.3, 0.5).
# usage: Rscript make_data.R <seed_from> <seed_to>   (tree.nwk and coords.csv in the working directory)
suppressPackageStartupMessages(library(ape))
args <- as.integer(commandArgs(TRUE)); tree <- read.tree("tree.nwk"); ids <- sprintf("tip%03d", 1:64)
Cphy <- vcv(tree, corr = TRUE)[ids, ids]
cc <- read.csv("coords.csv"); m <- as.matrix(cc[, 2:3]); rownames(m) <- cc$id
D <- as.matrix(dist(m[ids, ])); rg <- median(D[upper.tri(D)]); Csp <- exp(-D / rg); diag(Csp) <- diag(Csp) + 1e-6
n <- 64L; nr <- 16L
for (s in args[1]:args[2]) {
  set.seed(20261200L + s)
  z0 <- setNames(rep(c(-1, 1), n / 2), ids); z1 <- setNames(round(seq(-1, 1, length.out = n), 6)[sample.int(n)], ids)
  ii <- rep(seq_len(n), each = nr); x <- rep(seq(-1.2, 1.2, length.out = nr), n)
  for (kind in c("phylo", "spatial")) {
    C <- if (kind == "phylo") Cphy else Csp; L <- t(chol(C))
    b0 <- exp(log(0.9) + 0.4 * z0) * drop(L %*% rnorm(n)); b1 <- exp(log(0.4) - 0.2 * z1) * drop(L %*% rnorm(n))
    eta <- 0.3 + 0.5 * x + b0[ii] + x * b1[ii]
    write.csv(data.frame(id = ids[ii], x = x, z0 = unname(z0[ii]), z1 = unname(z1[ii]), y = rbinom(n * nr, 1, plogis(eta))),
              file.path("data", sprintf("%s_%d.csv", kind, s)), row.names = FALSE)
  }
}
