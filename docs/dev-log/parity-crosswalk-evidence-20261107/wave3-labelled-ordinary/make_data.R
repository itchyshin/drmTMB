# Fixture for wave-3 labelled ordinary q2 parity (run from this directory).
# 80 groups x 16 rows (1280 rows). Unit fields (u0, u1) iid over groups ~ N(0, R),
# rho = 0.5; b0 = s0[g] u0, b1 = s1[g] u1, s_k = exp(a_k1 + a_k2 z_k).
# Usage: SEED=2026110801 Rscript make_data.R   -> data_<seed>.csv
seed <- as.integer(Sys.getenv("SEED", "2026110801"))
set.seed(seed)
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
                yp = rpois(G * m, exp(eta)),
                yn = rnbinom(G * m, mu = exp(eta), size = 1 / 0.6^2))
write.csv(d, sprintf("data_%d.csv", seed), row.names = FALSE)
cat("seed", seed, "rows", nrow(d), "\n")
