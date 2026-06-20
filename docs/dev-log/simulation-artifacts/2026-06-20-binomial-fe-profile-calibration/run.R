# Binomial fixed-effect profile-interval coverage calibration (native R/TMB).
#
# Mirrors the design spirit of the 2026-06-17 Wald interval-calibration artifact
# (stats::binomial(logit), 0/1 and cbind encodings, fixed-effect mu only) but
# measures PROFILE (tmbprofile) interval coverage for the mu coefficients.
# Boundary: native R/TMB, fixed-effect mu only; no random/structured/bivariate
# routes, no Julia bridge, no headline coverage claim beyond these cells.
#
# Usage: Rscript --vanilla run.R [n_rep]
suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
n_rep <- if (length(args) >= 1L) as.integer(args[[1L]]) else 100L
out_dir <- "docs/dev-log/simulation-artifacts/2026-06-20-binomial-fe-profile-calibration"
dir.create(file.path(out_dir, "tables"), recursive = TRUE, showWarnings = FALSE)

b0 <- -0.3
b1 <- 0.8
targets <- c("mu:(Intercept)", "mu:x")
truth <- c("fixef:mu:(Intercept)" = b0, "fixef:mu:x" = b1)
cells <- expand.grid(
  encoding = c("binary", "cbind"),
  n = c(240L, 480L),
  stringsAsFactors = FALSE
)
master_seed <- 20260620L

rows <- list()
add <- function(...) rows[[length(rows) + 1L]] <<- data.frame(..., stringsAsFactors = FALSE)

t0 <- Sys.time()
for (ci in seq_len(nrow(cells))) {
  enc <- cells$encoding[[ci]]
  n <- cells$n[[ci]]
  for (r in seq_len(n_rep)) {
    set.seed(master_seed + ci * 100000L + r)
    x <- rnorm(n)
    p <- plogis(b0 + b1 * x)
    if (enc == "binary") {
      dat <- data.frame(y = rbinom(n, 1L, p), x = x)
      form <- bf(y ~ x)
    } else {
      k <- sample(10:30, n, replace = TRUE)
      s <- rbinom(n, k, p)
      dat <- data.frame(successes = s, failures = k - s, x = x)
      form <- bf(cbind(successes, failures) ~ x)
    }
    fit <- tryCatch(drmTMB(form, family = binomial(), data = dat), error = function(e) e)
    if (inherits(fit, "error")) {
      add(cell = ci, encoding = enc, n = n, rep = r, target = "NA",
          covered = NA, width = NA_real_, status = "fit_error")
      next
    }
    cip <- tryCatch(
      confint(fit, parm = targets, method = "profile"),
      error = function(e) e
    )
    if (inherits(cip, "error")) {
      add(cell = ci, encoding = enc, n = n, rep = r, target = "NA",
          covered = NA, width = NA_real_, status = "profile_error")
      next
    }
    for (tg in unique(cip$parm)) {
      row <- cip[cip$parm == tg, , drop = FALSE][1L, ]
      tv <- truth[[row$parm]]
      cov <- is.finite(row$lower) && is.finite(row$upper) &&
        tv >= row$lower && tv <= row$upper
      add(cell = ci, encoding = enc, n = n, rep = r, target = row$parm,
          covered = cov, width = row$upper - row$lower,
          status = as.character(row$profile.message))
    }
  }
}
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
fits <- do.call(rbind, rows)
write.csv(fits, file.path(out_dir, "tables", "profile-fits.csv"), row.names = FALSE)

ok <- fits[!is.na(fits$covered), , drop = FALSE]
key <- paste(ok$encoding, ok$n, ok$target, sep = "|")
agg <- do.call(rbind, lapply(split(ok, key), function(d) {
  pr <- mean(d$covered)
  m <- nrow(d)
  data.frame(
    encoding = d$encoding[[1L]], n = d$n[[1L]], target = d$target[[1L]],
    coverage = round(pr, 4), n_ok = m, mcse = round(sqrt(pr * (1 - pr) / m), 4),
    mean_width = round(mean(d$width), 4), stringsAsFactors = FALSE
  )
}))
write.csv(agg, file.path(out_dir, "tables", "profile-coverage-summary.csv"), row.names = FALSE)

cat("=== binomial FE profile coverage (n_rep=", n_rep, " per cell) ===\n", sep = "")
print(agg)
cat("profile_ok_rate:", round(mean(fits$status == "ok", na.rm = TRUE), 4),
    "| fit/profile errors:", sum(is.na(fits$covered)), "/", nrow(fits),
    "| elapsed:", round(elapsed, 1), "s\n")
writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
cat("DONE\n")
