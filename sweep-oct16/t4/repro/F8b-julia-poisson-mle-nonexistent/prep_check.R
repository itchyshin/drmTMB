## Check that the one-line generator in the issue body reproduces the t4 CSVs byte-for-value.
RNGkind("Mersenne-Twister", "Inversion", "Rejection")
gen <- function(rep) {
  set.seed(as.integer((20261016400 + 100 * 14 + (rep - 1)) %% 2^31))
  x <- rnorm(8); data.frame(y = rpois(8, exp(-1.5 + 0.5 * x)), x = x)
}
for (r in c(3L, 27L)) {
  a <- gen(r); b <- read.csv(file.path("..", "..", "data", sprintf("pois_n8_lowmean_r%02d.csv", r)))
  cat("rep", r, "seed", as.integer((20261016400 + 100 * 14 + (r - 1)) %% 2^31),
      "identical y:", identical(as.numeric(a$y), as.numeric(b$y)), " max|dx|:", max(abs(a$x - b$x)), "\n")
  dput(b)
}
cat(R.version.string, "\n")
