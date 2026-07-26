# A1 marginal-bootstrap coverage campaign (Totoro).
#
# AIM. PR #843 made `re.form = NULL` (marginal) the default for simulate(), and
# `confint(method = "bootstrap")` inherits it. That fix has CORRECTNESS evidence
# (Bartlett identities, covariance recovery) but ZERO coverage evidence.
#
# PRE-REGISTERED FALSIFIABLE PREDICTION (written before the run):
#   * marginal (bootstrap_re_form = NULL, the new default) attains ~0.95 for the
#     RE SD `sd:mu:(1 | g)`.
#   * conditional (bootstrap_re_form = NA, the OLD behaviour) UNDER-covers the
#     RE SD, because holding u-hat fixed removes the between-group variability
#     the RE SD interval must reflect. The gap should WIDEN as n_groups shrinks.
#   * The fixed effect `mu:x` is the CONTROL: the defect is about between-group
#     variance, so the two should be much closer there. If the RE SD gap is
#     absent, or the fixed effect shows an equal gap, the mechanism claimed in
#     PR #843 is wrong and that is the finding.
#
# ALL ATTEMPTS ARE RETAINED. Filtering to converged fits is how a coverage study
# lies; `status` carries the reason and the summary must use the full denominator.
#
# Usage: Rscript a1_coverage.R <cell_index> <n_rep> <R_boot> <out_dir>

args <- commandArgs(trailingOnly = TRUE)
cell_i  <- as.integer(args[[1]])
n_rep   <- as.integer(args[[2]])
R_boot  <- as.integer(args[[3]])
out_dir <- args[[4]]
rep_off <- if (length(args) >= 5L) as.integer(args[[5]]) else 0L
shard   <- if (length(args) >= 6L) args[[6]] else "s00"

.libPaths(c(file.path(Sys.getenv("HOME"), "drm_work/lib"), .libPaths()))
suppressPackageStartupMessages(library(drmTMB))
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

GRID <- expand.grid(
  n_groups = c(10L, 25L, 50L),
  n_per    = c(4L, 10L),
  sd_mu    = c(0.5, 1.0),
  KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
)
GRID$cell_id <- sprintf("c%02d", seq_len(nrow(GRID)))
stopifnot(cell_i >= 1L, cell_i <= nrow(GRID))
cell <- GRID[cell_i, ]

TRUE_BETA  <- 0.5
TRUE_SIGMA <- 0.7

emit <- function(...) data.frame(..., stringsAsFactors = FALSE)

rows <- list()
add <- function(...) rows[[length(rows) + 1L]] <<- emit(...)

for (r in seq_len(n_rep)) {
  seed <- 20260726L + 100000L * cell_i + rep_off + r
  set.seed(seed)
  n_g <- cell$n_groups; n_p <- cell$n_per
  g <- factor(rep(seq_len(n_g), each = n_p))
  x <- rnorm(n_g * n_p)
  u <- rnorm(n_g, 0, cell$sd_mu)
  y <- 1 + TRUE_BETA * x + u[as.integer(g)] + rnorm(n_g * n_p, 0, TRUE_SIGMA)
  dat <- data.frame(y = y, x = x, g = g)

  fit <- try(drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(), data = dat),
             silent = TRUE)
  if (inherits(fit, "try-error")) {
    add(cell_id = cell$cell_id, rep = r, seed = seed, re_form = NA_character_,
        parm = NA_character_, truth = NA_real_, lo = NA_real_, hi = NA_real_,
        covered = NA, width = NA_real_, status = "outer_fit_failed",
        boot_n = NA_integer_, boot_failed = NA_integer_)
    next
  }
  conv <- isTRUE(fit$opt$convergence == 0)
  base_status <- if (conv) "ok" else "outer_not_converged"

  for (rf in list(list(tag = "marginal", val = NULL),
                  list(tag = "conditional", val = NA))) {
    for (target in c("variance_components", "fixef:mu:x")) {
      ci <- try(stats::confint(
        fit, parm = target, method = "bootstrap", R = R_boot,
        seed = seed + 7L, bootstrap_re_form = rf$val,
        refit_control = drm_control(se = FALSE)
      ), silent = TRUE)

      if (inherits(ci, "try-error") || !is.data.frame(ci) || nrow(ci) < 1L) {
        add(cell_id = cell$cell_id, rep = r, seed = seed, re_form = rf$tag,
            parm = target, truth = NA_real_, lo = NA_real_, hi = NA_real_,
            covered = NA, width = NA_real_,
            status = if (inherits(ci, "try-error")) "boot_error" else "boot_empty",
            boot_n = NA_integer_, boot_failed = NA_integer_)
        next
      }
      for (k in seq_len(nrow(ci))) {
        pname <- as.character(ci$parm[[k]])
        truth <- if (grepl("^sd:mu", pname)) cell$sd_mu
                 else if (identical(pname, "sigma")) TRUE_SIGMA
                 else if (grepl("x$", pname)) TRUE_BETA else NA_real_
        lo <- ci$lower[[k]]; hi <- ci$upper[[k]]
        add(cell_id = cell$cell_id, rep = r, seed = seed, re_form = rf$tag,
            parm = pname, truth = truth, lo = lo, hi = hi,
            covered = if (is.na(truth)) NA else
              (is.finite(lo) && is.finite(hi) && lo <= truth && truth <= hi),
            width = if (is.finite(lo) && is.finite(hi)) hi - lo else NA_real_,
            status = base_status,
            boot_n = if (!is.null(ci$bootstrap.n)) ci$bootstrap.n[[k]] else NA_integer_,
            boot_failed = if (!is.null(ci$bootstrap.failed)) ci$bootstrap.failed[[k]] else NA_integer_)
      }
    }
  }
}

out <- do.call(rbind, rows)
out$n_groups <- cell$n_groups; out$n_per <- cell$n_per
out$sd_mu <- cell$sd_mu; out$R_boot <- R_boot
f <- file.path(out_dir, sprintf("%s_%s.csv", cell$cell_id, shard))
write.csv(out, f, row.names = FALSE)
cat("WROTE", f, "rows", nrow(out), "\n")
