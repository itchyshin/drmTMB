# Fixture for wave-3 labelled phylo/spatial q2 parity (run from this directory).
# One balanced 64-tip ultrametric tree (tip edges 1.5, internal 0.1, height 2),
# the same 64 ids on an 8 x 8 grid, 16 rows per id (1024 rows). Latent unit
# fields (u0, u1) ~ N(0, R (x) C) with rho = 0.5; b0 = s0[g] u0, b1 = s1[g] u1.
seed <- as.integer(Sys.getenv("SEED", "2026110801"))
set.seed(seed)
n <- 64L; nr <- 16L; ids <- sprintf("tip%03d", seq_len(n))
newick <- function(index, root = FALSE) {
  if (length(index) == 1L) return(paste0(ids[index], ":1.5"))
  half <- length(index) / 2L
  paste0("(", newick(index[seq_len(half)]), ",", newick(index[half + seq_len(half)]), ")",
         if (root) ";" else ":0.1")
}
nwk <- newick(seq_len(n), TRUE)
tree <- ape::read.tree(text = nwk)
Cphy <- ape::vcv(tree, corr = TRUE)[ids, ids]
coords <- as.matrix(expand.grid(easting = 0:7, northing = 0:7)); rownames(coords) <- ids
dd <- as.matrix(dist(coords)); rg <- median(dd[upper.tri(dd)])
Csp <- exp(-dd / rg); diag(Csp) <- diag(Csp) + 1e-6
z0 <- setNames(rep(c(-1, 1), n / 2L), ids)
z1 <- setNames(round(seq(-1, 1, length.out = n), 6)[sample.int(n)], ids)
ii <- rep(seq_len(n), each = nr); x <- rep(seq(-1.2, 1.2, length.out = nr), n)
rho <- 0.5
draw <- function(C, a0, a1) {
  L <- t(chol(C)); n0 <- rnorm(n); n1 <- rnorm(n)
  u0 <- drop(L %*% n0); u1 <- drop(L %*% (rho * n0 + sqrt(1 - rho^2) * n1))
  list(b0 = exp(a0[1] + a0[2] * z0) * u0, b1 = exp(a1[1] + a1[2] * z1) * u1)
}
mk <- function(C) {
  g <- draw(C, c(log(0.6), 0.4), c(log(0.35), -0.4))
  eta <- 0.3 + 0.4 * x + g$b0[ii] + x * g$b1[ii]
  p <- draw(C, c(log(0.4), 0.3), c(log(0.25), -0.3))
  etac <- 0.4 + 0.3 * x + p$b0[ii] + x * p$b1[ii]
  data.frame(id = ids[ii], x = x, z0 = unname(z0[ii]), z1 = unname(z1[ii]),
             yg = eta + rnorm(length(ii), sd = 0.5),
             yp = rpois(length(ii), exp(etac)),
             yn = rnbinom(length(ii), mu = exp(etac), size = 1 / 0.6^2))
}
write.csv(mk(Cphy), "data_phylo.csv", row.names = FALSE)
write.csv(mk(Csp), "data_spatial.csv", row.names = FALSE)
writeLines(nwk, "tree.nwk")
write.csv(data.frame(id = ids, easting = coords[, 1], northing = coords[, 2]), "coords.csv", row.names = FALSE)
cat("seed", seed, "height", max(ape::node.depth.edgelength(tree)), "range", rg, "\n")
