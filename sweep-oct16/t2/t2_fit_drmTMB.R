# Fit every t2 dataset with drmTMB (native TMB engine) and record estimates,
# Wald intervals and convergence diagnostics.
#
# Usage: Rscript t2_fit_drmTMB.R <datadir> <outdir> <cell> [rep_from rep_to]
# Writes <outdir>/drmTMB_<cell>_<from>-<to>.csv (long format: one row per
# parameter per rep). Run under `R_LIBS=/opt/Rlib` (drmTMB installed from a
# clean worktree at the pinned commit).

suppressPackageStartupMessages(library(drmTMB))
args <- commandArgs(trailingOnly = TRUE)
here <- dirname(normalizePath(sub("--file=", "",
  grep("--file=", commandArgs(FALSE), value = TRUE)[1])))
source(file.path(here, "t2_config.R"))
datadir <- args[[1]]
outdir <- args[[2]]
cell <- args[[3]]
rep_from <- if (length(args) >= 4L) as.integer(args[[4]]) else 1L
rep_to <- if (length(args) >= 5L) as.integer(args[[5]]) else T2_REPS
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

cells <- t2_cells()
cl <- cells[cells$cell == cell, ]
stopifnot(nrow(cl) == 1L)
dat_all <- utils::read.csv(file.path(datadir, paste0(cell, ".csv")))

form <- if (cl$G > 0L) {
  bf(y ~ x + (1 | g), sigma ~ z)
} else {
  bf(y ~ x, sigma ~ z)
}

# drmTMB target name -> t2 parameter name. Matched by the target names that
# confint(method = "wald") reports for this model (checked in the pilot).
map_param <- function(parm) {
  out <- rep(NA_character_, length(parm))
  out[parm %in% c("mu:(Intercept)", "fixef:mu:(Intercept)")] <- "mu_intercept"
  out[parm %in% c("mu:x", "fixef:mu:x")] <- "mu_x"
  out[parm %in% c("sigma:(Intercept)", "fixef:sigma:(Intercept)")] <- "sigma_intercept"
  out[parm %in% c("sigma:z", "fixef:sigma:z")] <- "sigma_z"
  out[grepl("^sd:mu:", parm)] <- "sd_g"
  out
}

one_fit <- function(r) {
  d <- dat_all[dat_all$rep == r, ]
  if (cl$G > 0L) d$g <- factor(d$g)
  warns <- character()
  t0 <- proc.time()[["elapsed"]]
  fit <- withCallingHandlers(
    tryCatch(drmTMB(form, data = d), error = function(e) e),
    warning = function(w) {
      warns <<- c(warns, paste(class(w)[1], conditionMessage(w)))
      invokeRestart("muffleWarning")
    }
  )
  elapsed <- proc.time()[["elapsed"]] - t0
  base <- data.frame(engine = "drmTMB", cell = cell, n = cl$n, re = cl$re,
                     G = cl$G, rep = r, seed_r = t2_seed_r(r),
                     time_s = elapsed, stringsAsFactors = FALSE)
  if (inherits(fit, "error")) {
    return(cbind(base, param = NA_character_, true = NA_real_, est = NA_real_,
                 est_link = NA_real_, se_link = NA_real_, lower = NA_real_,
                 upper = NA_real_, conf_status = NA_character_,
                 converged = FALSE, conv_status = "error", opt_code = NA_integer_,
                 opt_message = conditionMessage(fit), pdHess = NA,
                 max_grad = NA_real_, loglik = NA_real_,
                 warnings = paste(warns, collapse = " | "),
                 stringsAsFactors = FALSE))
  }
  ci_warns <- character()
  ci <- withCallingHandlers(
    tryCatch(confint(fit, method = "wald"), error = function(e) e),
    warning = function(w) {
      ci_warns <<- c(ci_warns, paste(class(w)[1], conditionMessage(w)))
      invokeRestart("muffleWarning")
    }
  )
  conv <- tryCatch(is_converged(fit), error = function(e) NA)
  status <- tryCatch(convergence_status(fit), error = function(e) NA_character_)
  targets <- drmTMB:::drm_profile_targets(fit)
  cov_fixed <- tryCatch(drmTMB:::drm_sdreport_cov_fixed(fit), error = function(e) NULL)
  pos <- drmTMB:::profile_target_opt_positions(fit, targets)
  se_link <- if (is.null(cov_fixed)) rep(NA_real_, nrow(targets)) else
    sqrt(diag(cov_fixed))[pos]
  tab <- data.frame(parm = targets$parm, est_link = targets$link_estimate,
                    se_link = se_link, stringsAsFactors = FALSE)
  if (!inherits(ci, "error")) {
    tab <- merge(tab, data.frame(parm = ci$parm, lower = ci$lower,
                                 upper = ci$upper, conf_status = ci$conf.status,
                                 stringsAsFactors = FALSE),
                 by = "parm", all.x = TRUE)
  } else {
    tab$lower <- NA_real_; tab$upper <- NA_real_
    tab$conf_status <- paste("confint_error:", conditionMessage(ci))
  }
  tab$param <- map_param(tab$parm)
  tab <- tab[!is.na(tab$param), ]
  # Natural-scale estimate: SD on the SD scale, everything else on its link
  # (= regression-coefficient) scale.
  tab$est <- ifelse(tab$param == "sd_g", exp(tab$est_link), tab$est_link)
  tab$true <- unname(T2_TRUTH[tab$param])
  grad <- tryCatch(max(abs(fit$sdr$gradient.fixed)), error = function(e) NA_real_)
  cbind(base, tab[, c("param", "true", "est", "est_link", "se_link", "lower",
                      "upper", "conf_status")],
        converged = conv, conv_status = status,
        opt_code = as.integer(fit$opt$convergence),
        opt_message = as.character(fit$opt$message),
        pdHess = isTRUE(fit$sdr$pdHess), max_grad = grad,
        loglik = as.numeric(logLik(fit)),
        warnings = paste(c(warns, ci_warns), collapse = " | "),
        stringsAsFactors = FALSE)
}

res <- do.call(rbind, lapply(seq.int(rep_from, rep_to), one_fit))
out <- file.path(outdir, sprintf("drmTMB_%s_%03d-%03d.csv", cell, rep_from, rep_to))
utils::write.csv(format(res, digits = 15), out, row.names = FALSE)
message(sprintf("%s reps %d-%d: %d rows -> %s", cell, rep_from, rep_to, nrow(res), out))
