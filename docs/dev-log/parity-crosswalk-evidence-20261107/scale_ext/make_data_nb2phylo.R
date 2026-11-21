# NB2 phylo q2 datasets (same generator as ../scale300/make_data_ps.R phylo part and wave2 make_data.R NB2 part:
# fixed 64-tip tree, mu = exp(0.4 + 0.3 x + b0 + x b1), NB2 size = 1/0.6^2), new seed per dataset.
# usage: SC_OUT=<out> Rscript make_data_nb2phylo.R <seed_from> <seed_to>  (run from the scripts directory)
args <- as.integer(commandArgs(TRUE)); O <- Sys.getenv("SC_OUT", "."); S <- "."
tree <- ape::read.tree(file.path(S, "tree.nwk")); n <- 64L; nr <- 16L; ids <- sprintf("tip%03d", seq_len(n))
Cphy <- ape::vcv(tree, corr = TRUE)[ids, ids]
for (s in args[1]:args[2]) {
  set.seed(2026111000L + s)
  z0 <- setNames(rep(c(-1, 1), n / 2L), ids)
  z1 <- setNames(round(seq(-1, 1, length.out = n), 6)[sample.int(n)], ids)
  ii <- rep(seq_len(n), each = nr); x <- rep(seq(-1.2, 1.2, length.out = nr), n)
  L <- t(chol(Cphy))
  b0 <- exp(log(0.4) + 0.3 * z0) * drop(L %*% rnorm(n)); b1 <- exp(log(0.25) - 0.3 * z1) * drop(L %*% rnorm(n))
  etac <- 0.4 + 0.3 * x + b0[ii] + x * b1[ii]
  write.csv(data.frame(y = rnbinom(length(ii), mu = exp(etac), size = 1 / 0.6^2), x = x, z0 = unname(z0[ii]), z1 = unname(z1[ii]), g = ids[ii]),
            file.path(O, "data", sprintf("nb2_phylo_s%03d.csv", s)), row.names = FALSE)
}
