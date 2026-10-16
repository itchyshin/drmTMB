# sweep-oct16 / t5 -- data generator (missing data x weights sweep).
# Writes one CSV per (family, NA fraction in y, NA fraction in x) cell.
# Doubles are written with %.17g so R and Julia parse bit-identical values.
#
# Seeds: the lane specifies nominal seeds 20261016500 + k. They exceed R's
# 32-bit set.seed() range, so the effective R seed is
#   nominal %% .Machine$integer.max
# and both values are recorded in data/manifest.csv.
#
# Usage: Rscript R/gen_data.R <outdir>
args <- commandArgs(trailingOnly = TRUE)
outdir <- if (length(args)) args[[1]] else "data"
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

families <- c("gaussian", "poisson", "gamma")
na_fracs <- c(0, 0.05, 0.20)
n_groups <- 25L
n_per <- 8L
n <- n_groups * n_per
seed_base <- 20261016500

fmt <- function(v) ifelse(is.na(v), "NA", sprintf("%.17g", v))

manifest <- list()
k <- 0L
for (fam in families) {
  for (py in na_fracs) {
    for (px in na_fracs) {
      nominal <- seed_base + k
      eff <- as.integer(nominal %% .Machine$integer.max)
      set.seed(eff)
      g <- sprintf("g%02d", rep(seq_len(n_groups), each = n_per))
      x <- rnorm(n)
      u <- rnorm(n_groups)[rep(seq_len(n_groups), each = n_per)]
      y <- switch(fam,
        gaussian = 1 + 0.5 * x + 0.7 * u + rnorm(n, sd = 1),
        poisson  = rpois(n, exp(0.5 + 0.4 * x + 0.5 * u)),
        gamma    = {
          mu <- exp(1 + 0.3 * x + 0.5 * u); cv <- 0.5
          rgamma(n, shape = 1 / cv^2, scale = mu * cv^2)
        }
      )
      w_int <- sample(1:3, n, replace = TRUE)
      w_pos <- exp(rnorm(n, 0, 0.75))
      # MCAR masks: exact counts, independent for y and x.
      miss_y <- sample.int(n, round(py * n))
      miss_x <- sample.int(n, round(px * n))
      y[miss_y] <- NA
      x[miss_x] <- NA
      id <- sprintf("%s_y%02d_x%02d", fam, round(100 * py), round(100 * px))
      d <- data.frame(row = seq_len(n), g = g, x = fmt(x), y = fmt(y),
                      w_int = w_int, w_pos = fmt(w_pos), stringsAsFactors = FALSE)
      write.csv(d, file.path(outdir, paste0(id, ".csv")), row.names = FALSE, quote = FALSE)
      manifest[[length(manifest) + 1L]] <- data.frame(
        id = id, family = fam, na_y = py, na_x = px, n = n,
        n_na_y = length(miss_y), n_na_x = length(miss_x),
        n_complete = sum(!is.na(y) & !is.na(x)),
        seed_nominal = sprintf("%.0f", nominal), seed_effective = eff)
      k <- k + 1L
    }
  }
}
manifest <- do.call(rbind, manifest)
write.csv(manifest, file.path(outdir, "manifest.csv"), row.names = FALSE, quote = FALSE)
print(manifest)
