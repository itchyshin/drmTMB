# Freeze additional seeds before the first confirmatory look. No fits run here.
native_sd_stage_two_manifest <- function() {
  stream <- function(seed, n) {
    set.seed(seed)
    sample.int(.Machine$integer.max, n)
  }
  excluded <- c(stream(2026101702L, 6L), stream(2026101703L, 3000L),
                stream(2026101704L, 3000L))
  candidates <- stream(2026101705L, 10000L)
  seeds <- head(candidates[!candidates %in% excluded], 9000L)
  stopifnot(length(seeds) == 9000L, !anyDuplicated(seeds),
            !length(intersect(seeds, excluded)))
  data.frame(index = seq_len(9000L), a = rep(c(-0.5, 0, 0.5), each = 3000L),
             replicate = rep(1001:4000, 3L), seed = seeds,
             groups = 160L, repeats = 16L, beta0 = -0.3, beta1 = 0.6,
             alpha0 = log(0.8), design_mode = "stage_two_not_authorized",
             master_seed = 2026101705L, stringsAsFactors = FALSE)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 1L || file.exists(args[[1L]]))
    stop("Supply one new manifest path; refusing overwrite")
  write.csv(native_sd_stage_two_manifest(), args[[1L]], row.names = FALSE)
  cat("STAGE_TWO_SEEDS_FROZEN 9000 additional seeds; no fits authorized or launched\n")
}
