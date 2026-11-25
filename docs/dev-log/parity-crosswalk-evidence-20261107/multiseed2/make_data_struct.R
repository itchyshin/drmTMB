# Per-seed Gaussian data for the phylo/spatial routes. Same generators as
# ../wave2-phylo-spatial-q2/make_data.R (independent fields, rho = 0; routes gauss_phylo, gauss_spatial)
# and ../wave3-labelled-phylo-spatial/make_data.R (correlated fields, rho = 0.5; routes gauss_lphylo, gauss_lspatial),
# Gaussian response only, fixed 64-tip tree and 8 x 8 grid, new seed per dataset.
# usage: Rscript make_data_struct.R <seed_from> <seed_to>   (run from this directory)
args <- as.integer(commandArgs(TRUE)); O <- "."
tree <- ape::read.tree(file.path(O, "tree.nwk")); n <- 64L; nr <- 16L; ids <- sprintf("tip%03d", seq_len(n))
Cphy <- ape::vcv(tree, corr = TRUE)[ids, ids]
cc <- read.csv(file.path(O, "coords.csv")); coords <- as.matrix(cc[, 2:3]); rownames(coords) <- cc$id
dd <- as.matrix(dist(coords)); rg <- median(dd[upper.tri(dd)])
Csp <- exp(-dd / rg); diag(Csp) <- diag(Csp) + 1e-6
for (s in args[1]:args[2]) for (lab in c(FALSE, TRUE)) {
  set.seed((if (lab) 2026110900L else 2026110950L) + s)
  rho <- if (lab) 0.5 else 0
  z0 <- setNames(rep(c(-1, 1), n / 2L), ids)
  z1 <- setNames(round(seq(-1, 1, length.out = n), 6)[sample.int(n)], ids)
  ii <- rep(seq_len(n), each = nr); x <- rep(seq(-1.2, 1.2, length.out = nr), n)
  draw <- function(C, a0, a1) { L <- t(chol(C)); n0 <- rnorm(n); n1 <- rnorm(n)
    u0 <- drop(L %*% n0); u1 <- drop(L %*% (rho * n0 + sqrt(1 - rho^2) * n1))
    list(b0 = exp(a0[1] + a0[2] * z0) * u0, b1 = exp(a1[1] + a1[2] * z1) * u1) }
  for (k in c("phylo", "spatial")) {
    g <- draw(if (k == "phylo") Cphy else Csp, c(log(0.6), 0.4), c(log(0.35), -0.4))
    eta <- 0.3 + 0.4 * x + g$b0[ii] + x * g$b1[ii]
    write.csv(data.frame(y = eta + rnorm(length(ii), sd = 0.5), x = x, z0 = unname(z0[ii]), z1 = unname(z1[ii]), id = ids[ii]),
              file.path(O, "data", sprintf("gauss_%s%s_s%02d.csv", if (lab) "l" else "", k, s)), row.names = FALSE)
  }
}
