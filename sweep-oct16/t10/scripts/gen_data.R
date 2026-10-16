# Generate shared null datasets for t10 (same files used by R and Julia).
# Seeds: 20261017000 + 0..nrep-1

nrep <- as.integer(Sys.getenv("T10_NREP", "500"))
# Official campaign seeds 20261017000+ overflow R's signed 32-bit set.seed
# (max 2147483647) and UInt32. Keep the official id in the `seed` column
# (exact in double) and feed set.seed the mapped rng_seed = official - 1.9e10.
seed0 <- 20261017000
rng_from_official <- function(official) as.integer(official - 1.9e10)
out_dir <- Sys.getenv("T10_DATA", "/tmp/t10-data")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Cell A: Gaussian, constant sigma. z is unused under the null.
# n = 200; y = 0.3 + 0.5 x + N(0, 1)
gauss_path <- file.path(out_dir, "gauss_sigma.csv")
con <- file(gauss_path, "w")
writeLines("seed,row,y,x,z", con)
for (i in seq_len(nrep) - 1L) {
  seed <- seed0 + i
  set.seed(rng_from_official(seed))
  n <- 200L
  x <- rnorm(n)
  z <- rnorm(n)
  y <- 0.3 + 0.5 * x + rnorm(n)
  write.table(
    data.frame(seed = seed, row = seq_len(n), y = y, x = x, z = z),
    con, sep = ",", row.names = FALSE, col.names = FALSE
  )
}
close(con)
cat("wrote", gauss_path, "\n")

# Cell B: Poisson null (NB2 extra dispersion is on the boundary).
# n = 250; y ~ Poisson(exp(0.4 + 0.3 x))
nb_path <- file.path(out_dir, "nb2_pois.csv")
con <- file(nb_path, "w")
writeLines("seed,row,y,x", con)
for (i in seq_len(nrep) - 1L) {
  seed <- seed0 + i
  set.seed(rng_from_official(seed))
  n <- 250L
  x <- rnorm(n)
  mu <- exp(0.4 + 0.3 * x)
  y <- rpois(n, lambda = mu)
  write.table(
    data.frame(seed = seed, row = seq_len(n), y = y, x = x),
    con, sep = ",", row.names = FALSE, col.names = FALSE
  )
}
close(con)
cat("wrote", nb_path, "\n")

# Cell C: Gaussian, no random intercept (sd_b = 0).
# G = 25 groups, m = 12; y = 0.4 - 0.5 x + N(0, 0.7^2)
re_path <- file.path(out_dir, "re_ri.csv")
con <- file(re_path, "w")
writeLines("seed,row,y,x,g", con)
for (i in seq_len(nrep) - 1L) {
  seed <- seed0 + i
  set.seed(rng_from_official(seed))
  G <- 25L
  m <- 12L
  n <- G * m
  g <- rep(seq_len(G), each = m)
  x <- rnorm(n)
  y <- 0.4 - 0.5 * x + 0.7 * rnorm(n)
  write.table(
    data.frame(seed = seed, row = seq_len(n), y = y, x = x, g = g),
    con, sep = ",", row.names = FALSE, col.names = FALSE
  )
}
close(con)
cat("wrote", re_path, "\n")
cat("T10_DATA_OK nrep=", nrep, " seed0=", seed0, "\n", sep = "")
