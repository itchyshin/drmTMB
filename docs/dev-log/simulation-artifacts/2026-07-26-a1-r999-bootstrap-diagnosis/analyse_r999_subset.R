# Compare the A1 R = 199 and diagnostic R = 999 percentile intervals on the
# same outer DGP seeds. Run on Totoro after launch_r999_subset.sh completes:
#   cd ~/drm_work && Rscript analyse_r999_subset.R

read_rows <- function(path, pattern) {
  files <- list.files(path, pattern = pattern, full.names = TRUE)
  if (length(files) == 0L) {
    stop("No files matched ", shQuote(pattern), " under ", path, call. = FALSE)
  }
  do.call(rbind, lapply(files, read.csv, stringsAsFactors = FALSE))
}

root <- file.path(Sys.getenv("HOME"), "drm_work")
old <- read_rows(file.path(root, "results"), "^c0[13]_s[0-9]+\\.csv$")
new <- read_rows(file.path(root, "results_r999_subset"), "^c0[13]_r999_o[0-9]+\\.csv$")

keep <- function(x) {
  x[
    x$re_form == "marginal" &
      x$parm == "sd:mu:(1 | g)",
    c("cell_id", "seed", "covered", "width", "lo", "hi", "R_boot")
  ]
}
old <- keep(old)
new <- keep(new)
names(old)[names(old) %in% c("covered", "width", "lo", "hi", "R_boot")] <-
  paste0(names(old)[names(old) %in% c("covered", "width", "lo", "hi", "R_boot")], "_199")
names(new)[names(new) %in% c("covered", "width", "lo", "hi", "R_boot")] <-
  paste0(names(new)[names(new) %in% c("covered", "width", "lo", "hi", "R_boot")], "_999")

d <- merge(old, new, by = c("cell_id", "seed"), all = TRUE, sort = TRUE)
if (nrow(d) != 2000L || any(!complete.cases(d))) {
  stop("Expected exactly 2,000 complete paired outer fits; got ", nrow(d),
       " rows with ", sum(!complete.cases(d)), " incomplete.", call. = FALSE)
}

summary_one <- function(x, suffix) {
  covered <- x[[paste0("covered_", suffix)]]
  width <- x[[paste0("width_", suffix)]]
  data.frame(
    cell_id = unique(x$cell_id),
    R_boot = unique(x[[paste0("R_boot_", suffix)]]),
    n = nrow(x),
    coverage = mean(covered),
    coverage_lo = binom.test(sum(covered), nrow(x))$conf.int[[1L]],
    coverage_hi = binom.test(sum(covered), nrow(x))$conf.int[[2L]],
    median_width = median(width),
    stringsAsFactors = FALSE
  )
}

for (cell in sort(unique(d$cell_id))) {
  x <- d[d$cell_id == cell, , drop = FALSE]
  old_s <- summary_one(x, "199")
  new_s <- summary_one(x, "999")
  paired <- table(
    R199 = x$covered_199,
    R999 = x$covered_999,
    dnn = c("R199 covered", "R999 covered")
  )
  cat("\n", cell, "\n", sep = "")
  print(rbind(old_s, new_s), row.names = FALSE)
  cat("paired coverage changes (same outer seeds):\n")
  print(paired)
  cat(sprintf("coverage difference R999 - R199: %+0.4f\n",
              mean(x$covered_999) - mean(x$covered_199)))
  cat(sprintf("median width difference R999 - R199: %+0.4f\n",
              median(x$width_999) - median(x$width_199)))
}
