## sweep-oct16 / t4: edge-case grid -- data generator (base R only).
## Both engines fit byte-identical CSVs written here.
## Nominal seed for cell k (1-based), rep r (1..50):
##   seed = 20261016400 + 100 * (k - 1) + (r - 1)
## R's set.seed() rejects seeds above .Machine$integer.max, so R is seeded with
##   seed %% 2^31   (same convention as lane t2, drmTMB PR #1549); injective here.
## RNGkind: R defaults (Mersenne-Twister / Inversion / Rejection), R >= 3.6.0.

t4_cells <- data.frame(
  k = 1:15,
  cell = c("gauss_n8", "gauss_n12", "gauss_n20",
           "pois_n8", "pois_n12", "pois_n20",
           "bin_complete", "bin_quasi",
           "nb2_poisdata", "beta_phi1e4", "student_gaussdata",
           "re_sd1e-4", "collin_sigma_exact", "collin_sigma_near",
           "pois_n8_lowmean"),
  stringsAsFactors = FALSE
)
t4_nominal_seed <- function(k, r) 20261016400 + 100 * (k - 1) + (r - 1)
t4_r_seed <- function(k, r) as.integer(t4_nominal_seed(k, r) %% 2^31)

t4_gen <- function(k, r) {
  RNGkind("Mersenne-Twister", "Inversion", "Rejection")
  set.seed(t4_r_seed(k, r))
  cell <- t4_cells$cell[k]
  gls <- function(n) {
    x <- rnorm(n)
    data.frame(y = 1 + 0.5 * x + exp(-0.4 + 0.3 * x) * rnorm(n), x = x)
  }
  pois <- function(n) {
    x <- rnorm(n)
    data.frame(y = rpois(n, exp(0.5 + 0.5 * x)), x = x)
  }
  switch(cell,
    gauss_n8  = gls(8), gauss_n12 = gls(12), gauss_n20 = gls(20),
    pois_n8   = pois(8), pois_n12 = pois(12), pois_n20 = pois(20),
    bin_complete = {
      x <- rnorm(50)
      data.frame(y = as.integer(x > 0), x = x)
    },
    bin_quasi = {
      x <- rnorm(50)
      y <- as.integer(x > 0)
      x[1:10] <- 0
      y[1:10] <- c(0L, 1L, rbinom(8, 1, 0.5))
      data.frame(y = y, x = x)
    },
    nb2_poisdata = {
      x <- rnorm(100)
      data.frame(y = rpois(100, exp(1 + 0.5 * x)), x = x)
    },
    beta_phi1e4 = {
      x <- rnorm(100); mu <- plogis(0.5 * x); phi <- 1e4
      data.frame(y = rbeta(100, mu * phi, (1 - mu) * phi), x = x)
    },
    student_gaussdata = {
      x <- rnorm(100)
      data.frame(y = 1 + 0.5 * x + rnorm(100), x = x)
    },
    "re_sd1e-4" = {
      G <- 20; m <- 5; g <- rep(seq_len(G), each = m); x <- rnorm(G * m)
      b <- rnorm(G, 0, 1e-4)
      data.frame(y = 1 + 0.5 * x + b[g] + rnorm(G * m), x = x, g = g)
    },
    collin_sigma_exact = {
      x <- rnorm(100)
      data.frame(y = 1 + 0.5 * x + exp(-0.4 + 0.3 * x) * rnorm(100),
                 x = x, z = 2 * x + 1)
    },
    pois_n8_lowmean = {
      x <- rnorm(8)
      data.frame(y = rpois(8, exp(-1.5 + 0.5 * x)), x = x)
    },
    collin_sigma_near = {
      x <- rnorm(100)
      y <- 1 + 0.5 * x + exp(-0.4 + 0.3 * x) * rnorm(100)
      data.frame(y = y, x = x, z = x + 1e-6 * rnorm(100))
    }
  )
}

if (sys.nframe() == 0L) {
  out <- commandArgs(trailingOnly = TRUE)[1]
  if (is.na(out)) out <- "sweep-oct16/t4/data"
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  idx <- list()
  for (k in t4_cells$k) for (r in 1:50) {
    d <- t4_gen(k, r)
    f <- sprintf("%s_r%02d.csv", t4_cells$cell[k], r)
    write.csv(d, file.path(out, f), row.names = FALSE)
    idx[[length(idx) + 1]] <- data.frame(
      k = k, cell = t4_cells$cell[k], rep = r,
      nominal_seed = sprintf("%.0f", t4_nominal_seed(k, r)),
      r_seed = t4_r_seed(k, r),
      file = f, n = nrow(d), stringsAsFactors = FALSE
    )
  }
  idx <- do.call(rbind, idx)
  write.csv(idx, file.path(out, "index.csv"), row.names = FALSE)
  cat("wrote", nrow(idx), "datasets to", out, "\n")
}
