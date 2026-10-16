# t10 R 500-rep sweep. One row per seed, appended immediately.
# Usage: T10_CELL=gauss|nb2|re T10_NREP=500 Rscript sweep_r.R
#
# Hard timeout per fit via setTimeLimit. se = FALSE.

.libPaths(c("/tmp/t10-lib", .libPaths()))
suppressPackageStartupMessages(library(drmTMB))

cell <- Sys.getenv("T10_CELL", "gauss")
nrep <- as.integer(Sys.getenv("T10_NREP", "500"))
seed0 <- 20261017000
data_dir <- Sys.getenv("T10_DATA", "/tmp/t10-data")
log_dir <- "/workspace/sweep-oct16/t10/logs"
dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)

ctrl <- drm_control(se = FALSE, keep_tmb_object = FALSE, keep_model_frame = FALSE)

timeout_for <- function(which_cell) {
  switch(which_cell, gauss = 30, nb2 = 60, re = 90, 60)
}

fit_timed <- function(expr, seconds) {
  t0 <- proc.time()[["elapsed"]]
  setTimeLimit(elapsed = seconds, transient = TRUE)
  on.exit(setTimeLimit(elapsed = Inf, transient = TRUE), add = TRUE)
  out <- tryCatch(
    list(ok = TRUE, value = expr, error = NA_character_),
    error = function(e) list(ok = FALSE, value = NULL, error = conditionMessage(e))
  )
  out$elapsed <- proc.time()[["elapsed"]] - t0
  out$timeout <- !out$ok && grepl("time.?limit|reached elapsed", out$error, ignore.case = TRUE)
  out
}

csv_path <- file.path(log_dir, sprintf("r_%s.csv", cell))
header <- paste(
  "engine", "cell", "seed", "status",
  "elapsed_reduced", "elapsed_full",
  "loglik_reduced", "loglik_full",
  "aic_reduced", "aic_full", "aicc_reduced", "aicc_full",
  "statistic", "df", "pvalue", "p_method",
  "chibar_p", "naive_p",
  "converged_reduced", "converged_full",
  "error",
  sep = ","
)
if (!file.exists(csv_path)) {
  writeLines(header, csv_path)
}
done <- if (file.exists(csv_path) && file.size(csv_path) > nchar(header)) {
  d <- utils::read.csv(csv_path, stringsAsFactors = FALSE)
  unique(d$seed)
} else {
  integer()
}

append_row <- function(...) {
  dots <- list(...)
  vals <- vapply(dots, function(v) {
    if (is.null(v) || (length(v) == 1L && is.na(v))) ""
    else if (is.character(v)) {
      v <- gsub(",", ";", v)
      v <- gsub("\n", " ", v)
      v
    } else {
      format(v, digits = 16, scientific = TRUE)
    }
  }, character(1))
  cat(paste(vals, collapse = ","), "\n", file = csv_path, append = TRUE, sep = "")
}

CELL_DF <- NULL
read_seed <- function(path, seed) {
  if (is.null(CELL_DF)) {
    CELL_DF <<- utils::read.csv(path, stringsAsFactors = FALSE)
  }
  CELL_DF[CELL_DF$seed == seed, , drop = FALSE]
}

is_conv <- function(fit) {
  isTRUE(tryCatch(is_converged(fit), error = function(e) NA))
}

run_one <- function(seed, dat, reduced_fn, full_fn, seconds, use_chibar) {
  if (seed %in% done) return(invisible(NULL))
  red <- fit_timed(reduced_fn(dat), seconds)
  ful <- if (red$ok) fit_timed(full_fn(dat), seconds) else list(ok = FALSE, value = NULL, error = "skipped: reduced failed", elapsed = 0, timeout = FALSE)
  if (!red$ok || !ful$ok) {
    append_row(
      "r", cell, seed,
      if (isTRUE(red$timeout) || isTRUE(ful$timeout)) "TIMEOUT" else "ERROR",
      red$elapsed, ful$elapsed,
      NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,
      NA, NA,
      paste(red$error, ful$error, sep = " | ")
    )
    return(invisible(NULL))
  }
  warn <- character()
  a <- withCallingHandlers(
    anova(red$value, ful$value),
    warning = function(w) {
      warn <<- c(warn, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  lb_p <- NA_real_
  naive_p <- NA_real_
  if (isTRUE(use_chibar)) {
    lb <- tryCatch(lrt_boundary(ful$value, red$value, q = 1), error = function(e) NULL)
    if (!is.null(lb)) {
      lb_p <- lb$pvalue
      naive_p <- lb$pvalue_naive
    }
  } else {
    naive_p <- a$`Pr(>Chisq)`[[2]]
    lb_p <- tryCatch(chibar_pvalue(a$Chisq[[2]], 1), error = function(e) NA_real_)
  }
  append_row(
    "r", cell, seed, "OK",
    red$elapsed, ful$elapsed,
    as.numeric(logLik(red$value)), as.numeric(logLik(ful$value)),
    AIC(red$value), AIC(ful$value),
    aicc(red$value), aicc(ful$value),
    a$Chisq[[2]], a$Df[[2]], a$`Pr(>Chisq)`[[2]],
    attr(a, "p.method")[[2]],
    lb_p, naive_p,
    is_conv(red$value), is_conv(ful$value),
    if (length(warn)) paste(warn, collapse = " || ") else ""
  )
  invisible(NULL)
}

seconds <- timeout_for(cell)
cat("T10 R sweep cell=", cell, " nrep=", nrep, " timeout=", seconds, "s\n", sep = "")

if (cell == "gauss") {
  path <- file.path(data_dir, "gauss_sigma.csv")
  for (i in seq_len(nrep) - 1L) {
    seed <- seed0 + i
    dat <- read_seed(path, seed)
    run_one(
      seed, dat,
      function(d) drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = d, control = ctrl),
      function(d) drmTMB(bf(y ~ x, sigma ~ z), family = gaussian(), data = d, control = ctrl),
      seconds, use_chibar = FALSE
    )
    if ((i + 1L) %% 25L == 0L) cat("  gauss", i + 1L, "/", nrep, "\n")
  }
} else if (cell == "nb2") {
  path <- file.path(data_dir, "nb2_pois.csv")
  for (i in seq_len(nrep) - 1L) {
    seed <- seed0 + i
    dat <- read_seed(path, seed)
    run_one(
      seed, dat,
      function(d) drmTMB(bf(y ~ x), family = poisson(), data = d, control = ctrl),
      function(d) drmTMB(bf(y ~ x, sigma ~ 1), family = nbinom2(), data = d, control = ctrl),
      seconds, use_chibar = TRUE
    )
    if ((i + 1L) %% 25L == 0L) cat("  nb2", i + 1L, "/", nrep, "\n")
  }
} else if (cell == "re") {
  path <- file.path(data_dir, "re_ri.csv")
  for (i in seq_len(nrep) - 1L) {
    seed <- seed0 + i
    dat <- read_seed(path, seed)
    dat$g <- factor(dat$g)
    run_one(
      seed, dat,
      function(d) drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = d, control = ctrl),
      function(d) drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(), data = d, control = ctrl),
      seconds, use_chibar = TRUE
    )
    if ((i + 1L) %% 10L == 0L) cat("  re", i + 1L, "/", nrep, "\n")
  }
} else {
  stop("unknown T10_CELL: ", cell)
}

cat("T10_R_DONE cell=", cell, "\n", sep = "")
