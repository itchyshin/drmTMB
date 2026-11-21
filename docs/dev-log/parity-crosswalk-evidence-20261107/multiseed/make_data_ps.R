# Per-seed Poisson data for the phylo and spatial q2 routes. Same generator as
# ../wave2-phylo-spatial-q2/make_data.R (Poisson part only), fixed tree and grid,
# new seed per dataset (z1 permutation, latent draws and counts all change).
# usage: Rscript make_data_ps.R <seed_from> <seed_to>   (run from this directory)
args <- as.integer(commandArgs(TRUE)); O <- "."
tree <- ape::read.tree(file.path(O, "tree.nwk")); n <- 64L; nr <- 16L; ids <- sprintf("tip%03d", seq_len(n))
Cphy <- ape::vcv(tree, corr = TRUE)[ids, ids]
cc <- read.csv(file.path(O, "coords.csv")); coords <- as.matrix(cc[, 2:3]); rownames(coords) <- cc$id
dd <- as.matrix(dist(coords)); rg <- median(dd[upper.tri(dd)])
Csp <- exp(-dd / rg); diag(Csp) <- diag(Csp) + 1e-6
for (s in args[1]:args[2]) {
  set.seed(2026110800L + s)
  z0 <- setNames(rep(c(-1, 1), n / 2L), ids)
  z1 <- setNames(round(seq(-1, 1, length.out = n), 6)[sample.int(n)], ids)
  ii <- rep(seq_len(n), each = nr); x <- rep(seq(-1.2, 1.2, length.out = nr), n)
  draw <- function(C, a0, a1) { L <- t(chol(C))
    list(b0 = exp(a0[1] + a0[2] * z0) * drop(L %*% rnorm(n)), b1 = exp(a1[1] + a1[2] * z1) * drop(L %*% rnorm(n))) }
  for (k in c("phylo", "spatial")) {
    p <- draw(if (k == "phylo") Cphy else Csp, c(log(0.4), 0.3), c(log(0.25), -0.3))
    etac <- 0.4 + 0.3 * x + p$b0[ii] + x * p$b1[ii]
    write.csv(data.frame(y = rpois(length(ii), exp(etac)), x = x, z0 = unname(z0[ii]), z1 = unname(z1[ii]), g = ids[ii]),
              file.path(O, "data", sprintf("%s_s%02d.csv", if (k == "phylo") "poisson_phylo" else "poisson_spatial", s)), row.names = FALSE)
  }
}
