# Fixture for wave-2 phylo/spatial q2 parity: one balanced 64-tip ultrametric
# tree with height 2 (so a raw-versus-correlation kernel mix-up would show),
# and the same 64 ids laid on an 8 x 8 grid for the coordinate-spatial kernel.
O <- "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/w2ps"
set.seed(2026110701L)
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
draw <- function(C, a0, a1) {
  L <- t(chol(C))
  list(b0 = exp(a0[1] + a0[2] * z0) * drop(L %*% rnorm(n)),
       b1 = exp(a1[1] + a1[2] * z1) * drop(L %*% rnorm(n)))
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
dphy <- mk(Cphy); dsp <- mk(Csp)
write.csv(dphy, file.path(O, "data_phylo.csv"), row.names = FALSE)
write.csv(dsp, file.path(O, "data_spatial.csv"), row.names = FALSE)
writeLines(nwk, file.path(O, "tree.nwk"))
write.csv(data.frame(id = ids, easting = coords[, 1], northing = coords[, 2]),
          file.path(O, "coords.csv"), row.names = FALSE)
cat("height", max(ape::node.depth.edgelength(tree)), "range", rg, "\n")
