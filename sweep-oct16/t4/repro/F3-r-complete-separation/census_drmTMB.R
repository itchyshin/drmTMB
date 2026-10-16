## F3-r-complete-separation: census over all 50 seeds of cells bin_complete (k = 7)
## and bin_quasi (k = 8), drmTMB at the pinned main, plus the PR #1442 screen
## (R/separation.R from branch claude/separation-1268 @ a8af9ab4, sourced
## standalone; the screen function only, not the full PR).
## Run from this directory:  Rscript census_drmTMB.R > census_drmTMB.out 2>&1
suppressPackageStartupMessages(library(drmTMB))
cat("drmTMB", as.character(packageVersion("drmTMB")), "\n")

pr_env <- new.env()
src <- tryCatch(system2("git", c("show", "a8af9ab4079ed4033c7eb37a0b6eb0a38372de30:R/separation.R"),
                        stdout = TRUE, stderr = FALSE), error = function(e) character())
have_pr <- length(src) > 100
if (have_pr) {
  pr_env$drm_is_mspl <- function(...) FALSE
  eval(parse(text = src), envir = pr_env)
  cat("PR #1442 screen sourced:", length(src), "lines\n")
} else cat("PR #1442 screen NOT available (git object a8af9ab4 missing); column pr_screen = NA\n")

rows <- list()
for (cell in c("bin_complete", "bin_quasi")) for (r in 1:50) {
  d <- read.csv(sprintf("../../data/%s_r%02d.csv", cell, r))
  warns <- character()
  fit <- withCallingHandlers(drmTMB(bf(y ~ x), family = binomial(), data = d),
    warning = function(w) { warns <<- c(warns, conditionMessage(w)); invokeRestart("muffleWarning") })
  se <- sqrt(diag(vcov(fit)))
  chk <- check_drm(fit)
  scr <- if (have_pr) {
    X <- cbind(`(Intercept)` = 1, x = d$x)
    s <- pr_env$drm_detect_separation(X, d$y, 1 - d$y)
    paste0(if (s$separated) "separated" else "none", if (!s$conclusive) "(inconclusive)" else "",
           ":", paste(colnames(X)[s$flagged], collapse = "+"))
  } else NA_character_
  rows[[length(rows) + 1]] <- data.frame(cell = cell, rep = r,
    n_warn = length(warns), converged = is_converged(fit), status = convergence_status(fit),
    check_ok = isTRUE(attr(chk, "ok")), n_not_ok = sum(chk$status != "ok"),
    weakly_id = any(chk$check == "weakly_identified_fixed_effects"),
    logLik = as.numeric(logLik(fit)), b_x = fixef(fit)$mu[["x"]],
    min_se = min(se), max_se = max(se), se_ratio = max(se) / min(se),
    pr1442_screen = scr, stringsAsFactors = FALSE)
}
res <- do.call(rbind, rows)
write.csv(res, "census_drmTMB.csv", row.names = FALSE)
for (cell in unique(res$cell)) {
  s <- res[res$cell == cell, ]
  cat("\n==", cell, "(50 seeds) ==\n")
  cat("fit-time warnings > 0:", sum(s$n_warn > 0), "\n")
  cat("is_converged TRUE:", sum(s$converged), "; status:", paste(names(table(s$status)), table(s$status), collapse = ", "), "\n")
  cat("check_drm ok TRUE:", sum(s$check_ok), "; weakly_identified_fixed_effects row:", sum(s$weakly_id), "\n")
  cat("min SE across seeds: [", format(range(s$min_se), digits = 4), "]; all SEs >= 50 in", sum(s$min_se >= 50), "seeds\n")
  cat("max/min SE ratio: [", format(range(s$se_ratio), digits = 4), "] (guard needs >= 1000 when all SEs >= 50)\n")
  cat("logLik range: [", format(range(s$logLik), digits = 4), "]\n")
  cat("PR #1442 screen verdicts:\n"); print(table(s$pr1442_screen, useNA = "ifany"))
}
cat("\n"); sessionInfo()
