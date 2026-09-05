# Ordinary random effects through the DRM.jl bridge: the estim_method census
# (parity leaf A5, gate G1/G4).
#
# Three formula shapes have no parity row: Gaussian (1 | g) on mu, a correlated
# random slope (1 + x | g) on mu, and a random intercept on sigma. Each is
# fitted through `drmTMB(..., engine = "julia")` twice (REML = FALSE, then
# REML = TRUE) and, for every fit that returns, the ENGINE's own report is read
# back: `fit$bridge$estim_method`, `fit$bridge$ml_loglik`,
# `fit$bridge$reml_loglik` (DRM.jl #625). The engine, not drmTMB's gate, is the
# authority on which estimator ran.
#
# Two layers per cell, because a refusal can come from two places:
#   layer = "shipped"        the bridge exactly as a user gets it (gate + R-side
#                            pre-checks in force). What the user sees.
#   layer = "engine-direct"  drmTMB's REML gate forced to TRUE and its R-side
#                            sigma-RE pre-check disabled, so `method = "REML"`
#                            reaches DRM.jl as written and the ENGINE's own
#                            message (or fit) is what comes back. What the
#                            engine actually does. The #1152 engine-authority
#                            cross-check in new_drmTMB_julia() stays live, so a
#                            requested-REML/got-ML cell ABORTS here rather than
#                            being labelled REML.
#
# Verdict per (shape, method, layer):
#   FITS         engine returned and estim_method == requested method
#   DOWNGRADED   engine returned but estim_method != requested (fail-safe: this
#                is UNSUPPORTED for the ledger, never "supported")
#   REFUSED      an error was raised (R-side or engine); message recorded verbatim
#
# Usage (from the worktree root):
#   OPENBLAS_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true DRM_JL_PATH=<pin> \
#     Rscript docs/dev-log/evidence/julia-r-parity/ordinary-re-census/census.R <outdir>

suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
outdir <- if (length(args) >= 1L) args[[1]] else dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

drmjl_path <- Sys.getenv("DRM_JL_PATH", "")
stopifnot(nzchar(drmjl_path), dir.exists(drmjl_path))
drmjl_ref <- tryCatch(
  system2("git", c("-C", shQuote(drmjl_path), "rev-parse", "HEAD"), stdout = TRUE),
  error = function(e) NA_character_
)

ns <- asNamespace("drmTMB")
gate_shipped <- get("drm_julia_reml_supported", envir = ns)
precheck_shipped <- get("drm_julia_check_ordinary_sigma_ranef_route_limits", envir = ns)

set_layer <- function(layer) {
  unlockBinding("drm_julia_reml_supported", ns)
  unlockBinding("drm_julia_check_ordinary_sigma_ranef_route_limits", ns)
  if (identical(layer, "engine-direct")) {
    assign("drm_julia_reml_supported", function(formula, family_type) TRUE, envir = ns)
    assign("drm_julia_check_ordinary_sigma_ranef_route_limits",
           function(formula, family_type, REML) invisible(NULL), envir = ns)
  } else {
    assign("drm_julia_reml_supported", gate_shipped, envir = ns)
    assign("drm_julia_check_ordinary_sigma_ranef_route_limits", precheck_shipped, envir = ns)
  }
  lockBinding("drm_julia_reml_supported", ns)
  lockBinding("drm_julia_check_ordinary_sigma_ranef_route_limits", ns)
  invisible(layer)
}

# ---------------------------------------------------------------------------
# Data: one draw per shape, variance components well away from any floor.
# ---------------------------------------------------------------------------
source(file.path(outdir, "make_data.R"))

shapes <- list(
  list(shape = "gaussian_random_intercept", text = "bf(y ~ x + (1 | g), sigma ~ 1)",
       formula = bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian()),
  list(shape = "gaussian_random_slope", text = "bf(y ~ x + (1 + x | g), sigma ~ 1)",
       formula = bf(y ~ x + (1 + x | g), sigma ~ 1), family = gaussian()),
  list(shape = "gaussian_sigma_random_intercept", text = "bf(y ~ x, sigma ~ (1 | g))",
       formula = bf(y ~ x, sigma ~ (1 | g)), family = gaussian())
)

`%||%` <- function(a, b) if (is.null(a)) b else a
num_or_na <- function(v) if (is.null(v) || length(v) == 0L) NA_real_ else as.numeric(v)[1L]
chr_or_na <- function(v) if (is.null(v) || length(v) == 0L) NA_character_ else as.character(v)[1L]

fit_cell <- function(sh, reml, layer) {
  set_layer(layer)
  dat <- make_data(sh$shape)
  t0 <- Sys.time()
  requested <- if (isTRUE(reml)) "REML" else "ML"
  res <- tryCatch(
    {
      fit <- suppressWarnings(drmTMB(sh$formula, family = sh$family, data = dat,
                                     engine = "julia", REML = reml))
      b <- fit$bridge
      list(
        outcome = "returned",
        estim_method = chr_or_na(b$estim_method),
        ml_loglik = num_or_na(b$ml_loglik),
        reml_loglik = num_or_na(b$reml_loglik),
        bridge_loglik = num_or_na(b$loglik),
        logLik = as.numeric(stats::logLik(fit)),
        estimator = chr_or_na(fit$estimator),
        effective_REML = isTRUE(fit$effective_REML),
        requested_REML = isTRUE(fit$requested_REML),
        converged = isTRUE(b$converged),
        bridge_keys = paste(sort(names(b)), collapse = ","),
        message = NA_character_
      )
    },
    error = function(e) list(
      outcome = "error", estim_method = NA_character_, ml_loglik = NA_real_,
      reml_loglik = NA_real_, bridge_loglik = NA_real_, logLik = NA_real_,
      estimator = NA_character_, effective_REML = NA, requested_REML = NA,
      converged = NA, bridge_keys = NA_character_,
      message = gsub("[\r\n]+", " | ", conditionMessage(e))
    )
  )
  secs <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  verdict <- if (identical(res$outcome, "error")) {
    "REFUSED"
  } else if (is.na(res$estim_method)) {
    "NO_ESTIM_METHOD_REPORTED"
  } else if (identical(toupper(res$estim_method), requested)) {
    "FITS"
  } else {
    "DOWNGRADED"
  }
  # G4 fail-safe: only FITS is a supported cell. Anything else is UNSUPPORTED.
  ledger <- if (identical(verdict, "FITS")) "SUPPORTED" else "UNSUPPORTED"
  cat(sprintf("[%-13s] %-32s %-4s -> %-24s estim=%s ml=%s reml=%s (%.1fs)\n",
              layer, sh$shape, requested, verdict,
              res$estim_method, format(res$ml_loglik, digits = 15),
              format(res$reml_loglik, digits = 15), secs))
  if (identical(res$outcome, "error")) cat("      msg: ", substr(res$message, 1, 400), "\n", sep = "")
  data.frame(
    drmjl_ref = drmjl_ref, layer = layer, shape = sh$shape,
    formula = sh$text,
    requested = requested, verdict = verdict, ledger = ledger,
    estim_method = res$estim_method,
    ml_loglik = res$ml_loglik, reml_loglik = res$reml_loglik,
    bridge_loglik = res$bridge_loglik, logLik = res$logLik,
    estimator = res$estimator, effective_REML = res$effective_REML,
    requested_REML = res$requested_REML, converged = res$converged,
    bridge_keys = res$bridge_keys, secs = round(secs, 2), message = res$message,
    stringsAsFactors = FALSE
  )
}

rows <- list()
for (layer in c("shipped", "engine-direct")) {
  for (sh in shapes) {
    for (reml in c(FALSE, TRUE)) {
      rows[[length(rows) + 1L]] <- fit_cell(sh, reml, layer)
    }
  }
}
set_layer("shipped")
tab <- do.call(rbind, rows)
out <- file.path(outdir, "census.tsv")
write.table(tab, out, sep = "\t", row.names = FALSE, quote = FALSE)
cat("\nwrote ", out, "\nDRM.jl ref: ", drmjl_ref, "\n", sep = "")
print(tab[, c("layer", "shape", "requested", "verdict", "ledger", "estim_method", "ml_loglik", "reml_loglik")])
