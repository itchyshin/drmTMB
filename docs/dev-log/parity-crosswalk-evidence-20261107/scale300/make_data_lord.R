# Data for the labelled-ordinary q2 routes (Poisson and NB2). Same generator as
# ../wave3-labelled-ordinary/make_data.R (80 groups x 16 rows, rho = 0.5); seed = 2026110800 + s,
# so s = 1..10 reproduce wave3's ten datasets. Writes data/lord_poisson_sNNN.csv and
# data/lord_nb2_sNNN.csv (columns y,x,z0,z1,g).
# usage: SC_OUT=<out> Rscript make_data_lord.R <seed_from> <seed_to>
args <- as.integer(commandArgs(TRUE)); O <- Sys.getenv("SC_OUT", ".")
dir.create(file.path(O, "data"), showWarnings = FALSE, recursive = TRUE)
for (s in args[1]:args[2]) {
  set.seed(2026110800L + s)
  G <- 80L; m <- 16L; rho <- 0.5
  ids <- sprintf("site%03d", seq_len(G))
  z0 <- setNames(rep(c(-1, 1), G / 2L), ids)[sample.int(G)]
  z1 <- round(seq(-1, 1, length.out = G), 6)[sample.int(G)]
  n0 <- rnorm(G); n1 <- rnorm(G)
  u0 <- n0; u1 <- rho * n0 + sqrt(1 - rho^2) * n1
  b0 <- exp(log(0.5) + 0.3 * z0) * u0
  b1 <- exp(log(0.3) - 0.3 * z1) * u1
  gi <- rep(seq_len(G), each = m); x <- rep(seq(-1.2, 1.2, length.out = m), G)
  eta <- 0.3 + 0.4 * x + b0[gi] + x * b1[gi]
  d <- data.frame(g = ids[gi], x = x, z0 = unname(z0[gi]), z1 = z1[gi],
                  yp = rpois(G * m, exp(eta)), yn = rnbinom(G * m, mu = exp(eta), size = 1 / 0.6^2))
  write.csv(data.frame(y = d$yp, x = d$x, z0 = d$z0, z1 = d$z1, g = d$g), file.path(O, "data", sprintf("lord_poisson_s%03d.csv", s)), row.names = FALSE)
  write.csv(data.frame(y = d$yn, x = d$x, z0 = d$z0, z1 = d$z1, g = d$g), file.path(O, "data", sprintf("lord_nb2_s%03d.csv", s)), row.names = FALSE)
}
