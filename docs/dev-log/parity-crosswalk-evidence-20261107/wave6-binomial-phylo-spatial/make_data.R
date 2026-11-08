# Bernoulli data for the Binomial phylo/spatial q2 agreement study.
# 64-tip balanced ultrametric tree (height 2.4) and the same 64 ids on an 8 x 8 grid,
# 30 rows per tip. Fields: u_k = exp(a_k0 + a_k1 z_k) * L z, L L' = C (phylo: ape::vcv corr=TRUE;
# spatial: exp(-d/median d) + 1e-6 I). Truth: beta = (0.3, 0.5), a0 = (log 0.9, 0.4), a1 = (log 0.8, -0.4).
# Usage: Rscript make_data.R <seed> ...   (seeds as integers; 20261108 is the single-dataset case)
suppressPackageStartupMessages(library(ape))
here <- dirname(sub("--file=", "", grep("--file=", commandArgs(FALSE), value = TRUE)))
tree <- read.tree(file.path(here, "tree.nwk")); ids <- sprintf("tip%03d", 1:64)
Cphy <- vcv(tree, corr = TRUE)[ids, ids]
cc <- read.csv(file.path(here, "coords.csv")); m <- as.matrix(cc[, 2:3]); rownames(m) <- cc$id
D <- as.matrix(dist(m)); rg <- median(D[upper.tri(D)]); Csp <- exp(-D / rg); diag(Csp) <- diag(Csp) + 1e-6
n <- 64L; nr <- 30L
for (seed in as.integer(commandArgs(TRUE))) {
  set.seed(seed)
  z0 <- setNames(rep(c(-1, 1), n / 2), ids); z1 <- setNames(round(seq(-1, 1, length.out = n), 6)[sample.int(n)], ids)
  ii <- rep(seq_len(n), each = nr); x <- rep(seq(-1.2, 1.2, length.out = nr), n)
  for (kind in c("phylo", "spatial")) {
    C <- if (kind == "phylo") Cphy else Csp; L <- t(chol(C))
    b0 <- exp(log(0.9) + 0.4 * z0) * drop(L %*% rnorm(n)); b1 <- exp(log(0.8) - 0.4 * z1) * drop(L %*% rnorm(n))
    eta <- 0.3 + 0.5 * x + b0[ii] + x * b1[ii]
    d <- data.frame(id = ids[ii], x = x, z0 = unname(z0[ii]), z1 = unname(z1[ii]), y = rbinom(n * nr, 1, plogis(eta)))
    write.csv(d, file.path(here, "data", sprintf("%s_%d.csv", kind, seed)), row.names = FALSE)
  }
}
