args <- commandArgs(trailingOnly = TRUE)
if (!length(args) %in% 1:2) stop("Supply a fresh output directory and optional manifest rows")
out <- args[[1L]]
if (dir.exists(out)) stop("Refusing to overwrite a pilot directory")
library_path <- Sys.getenv("DRMTMB_SD_TEST_LIBRARY")
if (!nzchar(library_path)) stop("Set DRMTMB_SD_TEST_LIBRARY")
.libPaths(c(library_path, .libPaths()))
library(drmTMB)
if (!requireNamespace("digest", quietly = TRUE)) stop("Install digest for source binding")
stopifnot(identical(normalizePath(find.package("drmTMB")),
                    normalizePath(file.path(library_path, "drmTMB"))))
source("tests/testthat/helper-binomial-sd-regression.R")
dir.create(out, recursive = TRUE)
writeLines(capture.output(sessionInfo()), file.path(out, "sessionInfo.txt"))
files <- c("R/drmTMB.R", "R/methods.R", "R/profile.R", "src/drmTMB.cpp",
           "tests/testthat/helper-binomial-sd-regression.R",
           "tools/general-sd-regression/run-bernoulli-pilot.R",
           "docs/dev-log/general-sd-regression/bernoulli-pilot-design.md",
           getLoadedDLLs()[["drmTMB"]][["path"]],
           file.path(find.package("drmTMB"), "R", c("drmTMB.rdb", "drmTMB.rdx")))
hashes <- vapply(files, function(file) digest::digest(file = file, algo = "sha256"),
                  character(1L))
write.csv(data.frame(file = files, sha256 = unname(hashes)),
           file.path(out, "source-hashes.csv"), row.names = FALSE)
writeLines(as.character(packageVersion("drmTMB")), file.path(out, "package-version.txt"))
set.seed(2026101702L)
manifest <- expand.grid(a = c(-0.5, 0, 0.5), pilot = 1:2)
manifest$seed <- sample.int(.Machine$integer.max, nrow(manifest))
manifest$manifest_row <- seq_len(nrow(manifest))
if (length(args) == 2L) {
  selected <- suppressWarnings(as.integer(strsplit(args[[2L]], ",", fixed = TRUE)[[1L]]))
  if (!length(selected) || anyNA(selected) || anyDuplicated(selected) ||
      any(!selected %in% seq_len(nrow(manifest)))) stop("Invalid pilot manifest rows")
  manifest <- manifest[selected, , drop = FALSE]
}
write.csv(manifest, file.path(out, "manifest.csv"), row.names = FALSE)
rows <- vector("list", nrow(manifest))
write_attempts <- function(upto) {
  temp <- tempfile("attempts-", tmpdir = out, fileext = ".csv")
  write.csv(do.call(rbind, rows[seq_len(upto)]), temp, row.names = FALSE)
  if (!file.rename(temp, file.path(out, "attempts.csv"))) {
    stop("Could not replace the attempt journal")
  }
}
for (i in seq_len(nrow(manifest))) {
  scenario <- manifest[i, ]
  # Independent generator: no fitting or package simulation functions.
  set.seed(scenario$seed)
  groups <- 160L; repeats <- 16L
  group <- rep(seq_len(groups), each = repeats)
  w <- rep(seq(-1, 1, length.out = groups), each = repeats)
  x <- rnorm(length(group)); u <- rnorm(groups)
  s <- exp(log(0.8) + scenario$a * w)
  y <- rbinom(length(group), 1, plogis(-0.3 + 0.6*x + s*u[group]))
  dat <- data.frame(y, failure = 1-y, x, w, id = factor(group))
  row <- data.frame(scenario, estimate = NA_real_, se = NA_real_,
    convergence = NA_integer_, pdHess = FALSE, max_abs_gradient = NA_real_,
    clamp_at_optimum = "not_checked", lower = NA_real_,
    upper = NA_real_, interval_status = "not_attempted", profile_boundary = NA,
    profile_message = "", laplace_oracle_error = NA_real_, valid_interval = FALSE,
    warnings = "", error = "", elapsed = NA_real_, attempt_state = "started")
  rows[[i]] <- row
  write_attempts(i)
  warnings <- character()
  start <- proc.time()[["elapsed"]]
  tryCatch(withCallingHandlers({
    fit <- drmTMB(bf(y ~ x + (1 | id), sd(id) ~ w), binomial(), dat)
    row$estimate <- coef(fit, "sd(id)")[["w"]]
    row$se <- sqrt(vcov(fit)["sd(id):w", "sd(id):w"])
    row$convergence <- fit$opt$convergence
    row$pdHess <- isTRUE(fit$sdr$pdHess)
    row$max_abs_gradient <- max(abs(fit$obj$gr(fit$opt$par)))
    health <- check_drm(fit)
    saveRDS(health, file.path(out, sprintf("health-%02d.rds", i)))
    row$clamp_at_optimum <- health$status[health$check == "logsigma_clamp_active"][[1L]]
    row$laplace_oracle_error <- -as.numeric(logLik(fit)) -
      binomial_sd_laplace_oracle(dat, coef(fit, "mu"), coef(fit, "sd(id)"))
    row$interval_status <- "profile_error"
    row$attempt_state <- "profiling"
    rows[[i]] <- row
    write_attempts(i)
    ci <- confint(fit, parm = "fixef:sd(id):w", method = "profile", level = 0.95)
    saveRDS(ci, file.path(out, sprintf("interval-%02d.rds", i)))
    row$lower <- ci$lower[[1L]]; row$upper <- ci$upper[[1L]]
    row$interval_status <- ci$conf.status[[1L]]
    row$profile_boundary <- ci$profile.boundary[[1L]]
    row$profile_message <- ci$profile.message[[1L]]
    row$valid_interval <- isTRUE(row$convergence == 0L) && isTRUE(row$pdHess) &&
      isTRUE(row$max_abs_gradient < 1e-3) && row$clamp_at_optimum == "ok" &&
      identical(row$interval_status, "profile") &&
      identical(row$profile_boundary, FALSE) &&
      all(is.finite(c(row$lower, row$upper))) && row$lower < row$upper
  }, warning = function(wrn) {
    warnings <<- c(warnings, conditionMessage(wrn)); invokeRestart("muffleWarning")
  }), error = function(err) row$error <<- conditionMessage(err))
  row$warnings <- paste(unique(warnings), collapse = " | ")
  row$elapsed <- proc.time()[["elapsed"]] - start
  row$attempt_state <- "completed"
  rows[[i]] <- row
  write_attempts(i)
  print(row)
}
attempts <- do.call(rbind, rows)
denominators <- do.call(rbind, lapply(split(attempts, attempts$a), function(z) {
  data.frame(a = z$a[[1L]], attempts = nrow(z), fit_results = sum(is.finite(z$estimate)),
    healthy_fits = sum(z$convergence == 0L & z$pdHess &
                        z$max_abs_gradient < 1e-3 & z$clamp_at_optimum == "ok",
                      na.rm = TRUE),
    valid_intervals = sum(z$valid_interval),
    boundary_or_clamp = sum(z$profile_boundary %in% TRUE |
                             z$interval_status == "clamp_limited"),
    profile_failures = sum(!z$interval_status %in% c("profile", "not_attempted")),
    errors = sum(nzchar(z$error)), max_seconds = max(z$elapsed))
}))
write.csv(denominators, file.path(out, "denominators.csv"), row.names = FALSE)
print(denominators)
oracle_pass <- all(is.finite(attempts$laplace_oracle_error)) &&
  max(abs(attempts$laplace_oracle_error)) < 1e-6
if (!oracle_pass) stop("Independent scalar Laplace calculation failed the 1e-6 tolerance")
cat("BERNOULLI_PILOT_RECORDED\n")
