#!/usr/bin/env Rscript

# Fixed-kappa mesh/SPDE Gaussian field-scale recovery ladder.  This runner is
# intentionally outside the package test suite: multi-seed recovery belongs on
# Totoro or DRAC, never GitHub Actions.  It retains every attempt, including
# optimizer and Hessian failures, so a recovery summary cannot silently select
# successful fits.

args <- commandArgs(trailingOnly = TRUE)
root <- normalizePath(file.path(dirname(sub("^--file=", "", grep(
  "^--file=", commandArgs(FALSE), value = TRUE
)[1L])), ".."))
setwd(root)
pkgload::load_all(root, quiet = TRUE, export_all = FALSE)

out_dir <- Sys.getenv(
  "DRMTMB_MESH_RECOVERY_OUT",
  unset = file.path(root, "docs/dev-log/simulation-artifacts/2026-08-02-mesh-spde-field-scale-recovery")
)
n_rep <- as.integer(Sys.getenv("DRMTMB_MESH_RECOVERY_REPS", unset = "50"))
n_sites <- as.integer(strsplit(
  Sys.getenv("DRMTMB_MESH_RECOVERY_SITES", unset = "64,128,256"), ","
)[[1L]])
if (!is.finite(n_rep) || n_rep < 1L || any(!is.finite(n_sites)) || any(n_sites < 16L)) {
  stop("Use positive DRMTMB_MESH_RECOVERY_REPS and comma-separated site counts >= 16.")
}
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

kappa <- 1 / 20000
field_scale <- 1e-4
residual_sd <- 0.25
intercept <- 1.2
base_seed <- 2026080200L
sha <- trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE))
script_md5 <- unname(tools::md5sum(normalizePath(sub(
  "^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L]
))))

one_attempt <- function(n_site, seed) {
  set.seed(seed)
  coords <- cbind(runif(n_site, 0, 100000), runif(n_site, 0, 100000))
  rownames(coords) <- as.character(seq_len(n_site))
  attr(coords, "crs") <- sf::st_crs(3857)
  class(coords) <- c("drmTMB_coords", class(coords))
  mesh <- make_mesh(
    coords, kappa = kappa,
    max.edge = c(12000, 25000), offset = c(10000, 20000),
    cutoff = 100, max.n = max(160L, 2L * n_site)
  )
  Q <- as.matrix(
    kappa^4 * mesh$spde$c0 + 2 * kappa^2 * mesh$spde$g1 + mesh$spde$g2
  )
  omega <- field_scale * as.vector(backsolve(chol(Q), rnorm(ncol(Q))))
  dat <- data.frame(
    y = intercept + as.vector(mesh$A_st %*% omega) + rnorm(n_site, sd = residual_sd),
    site = paste0("obs", seq_len(n_site))
  )
  warning_text <- character()
  fit <- tryCatch(
    withCallingHandlers(
      drmTMB(
        bf(y ~ spatial(1 | site, mesh = mesh), sigma ~ 1),
        family = gaussian(), data = dat
      ),
      warning = function(w) {
        warning_text <<- c(warning_text, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) e
  )
  if (inherits(fit, "error")) {
    return(data.frame(
      n_site = n_site, seed = seed, n_vertex = ncol(mesh$A_st),
      fit_ok = FALSE, convergence = NA_integer_, pdHess = NA,
      estimate = NA_real_, residual_estimate = NA_real_,
      relative_error = NA_real_, warning = paste(warning_text, collapse = " | "),
      error = conditionMessage(fit), stringsAsFactors = FALSE
    ))
  }
  estimate <- unname(fit$sdpars$mu[["spatial(1 | site)"]])
  data.frame(
    n_site = n_site, seed = seed, n_vertex = ncol(mesh$A_st),
    fit_ok = TRUE, convergence = fit$opt$convergence,
    pdHess = isTRUE(fit$sdr$pdHess), estimate = estimate,
    residual_estimate = exp(unname(fit$coefficients$sigma[[1L]])),
    relative_error = estimate / field_scale - 1,
    warning = paste(warning_text, collapse = " | "), error = "",
    stringsAsFactors = FALSE
  )
}

attempts <- do.call(rbind, lapply(n_sites, function(n_site) {
  do.call(rbind, lapply(seq_len(n_rep), function(i) {
    one_attempt(n_site, base_seed + 100000L * match(n_site, n_sites) + i)
  }))
}))
utils::write.table(
  attempts, file.path(out_dir, "raw-attempts.tsv"), sep = "\t", row.names = FALSE,
  quote = FALSE, na = ""
)
summary <- do.call(rbind, lapply(split(attempts, attempts$n_site), function(x) {
  usable <- x$fit_ok & x$convergence == 0L & x$pdHess & is.finite(x$estimate)
  data.frame(
    n_site = x$n_site[[1L]], attempts = nrow(x), usable = sum(usable),
    convergence_rate = mean(x$fit_ok & x$convergence == 0L, na.rm = TRUE),
    pdHess_rate = mean(x$pdHess, na.rm = TRUE),
    mean_estimate = mean(x$estimate[usable]),
    relative_bias = mean(x$estimate[usable] / field_scale - 1),
    rmse_log_scale = sqrt(mean((log(x$estimate[usable]) - log(field_scale))^2)),
    stringsAsFactors = FALSE
  )
}))
utils::write.table(
  summary, file.path(out_dir, "summary.tsv"), sep = "\t", row.names = FALSE,
  quote = FALSE, na = ""
)
writeLines(c(
  paste("source_sha", sha, sep = "\t"),
  paste("runner_md5", script_md5, sep = "\t"),
  paste("kappa_fixed", kappa, sep = "\t"),
  paste("field_scale_truth", field_scale, sep = "\t"),
  paste("residual_sd_truth", residual_sd, sep = "\t"),
  paste("attempt_policy", "retain_all_attempts", sep = "\t")
), file.path(out_dir, "metadata.tsv"))
print(summary)
