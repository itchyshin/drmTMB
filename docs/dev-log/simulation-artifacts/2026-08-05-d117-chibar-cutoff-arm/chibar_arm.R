# Does the Self-Liang chi-bar-square cutoff move D-117's conditional coverage
# toward nominal?
#
# KEY IDENTITY (no package edit needed): the endpoint solver's interval is the
# level set {theta : nll(theta) - nll_hat <= cutoff} with
# cutoff = qchisq(level, 1)/2  (R/profile.R:3117, root fn at :3356).
# The chi-bar-square 50:50 mixture correction replaces qchisq(level,1) with
# qchisq(2*level-1, 1). At level = 0.95 that is qchisq(0.90,1).
# Therefore the CHI-BAR-CORRECTED 95% interval IS the ordinary 90% interval.
# So we get both arms by calling confint() at level 0.95 and level 0.90.
#
# DGP, seeds and target copied verbatim from
# docs/dev-log/simulation-artifacts/2026-08-04-d117-10group-profile-gate/d117_profile_gate.R

suppressMessages(library(drmTMB))
suppressMessages(library(parallel))

arg_of <- function(k) {
  a <- grep(paste0("^--", k, "="), commandArgs(TRUE), value = TRUE)
  if (length(a) == 0L) return(NA_character_)
  sub(paste0("^--", k, "="), "", a[[1L]])
}
cell_i <- as.integer(arg_of("cell"))
nrep   <- as.integer(arg_of("nrep"))
cores  <- as.integer(arg_of("cores"))
outf   <- arg_of("out")
if (is.na(cores)) cores <- 1L

TRUE_BETA  <- 0.5
TRUE_SIGMA <- 0.7
TARGET     <- "sd:mu:(1 | g)"

GRID <- data.frame(
  cell_i   = c(1L, 4L, 5L, 6L),
  n_groups = c(10L, 10L, 10L, 10L),
  n_per    = c(10L, 4L, 4L, 10L),
  sd_mu    = c(0.5, 0.5, 1.0, 1.0),
  cell_id  = c("g10_n10_sd05", "g10_n04_sd05", "g10_n04_sd10", "g10_n10_sd10"),
  stringsAsFactors = FALSE
)
cell <- GRID[GRID$cell_i == cell_i, , drop = FALSE]
stopifnot(nrow(cell) == 1L)

pick <- function(ci, level_label) {
  if (inherits(ci, "try-error") || is.null(ci)) {
    return(list(lower = NA_real_, upper = NA_real_, boundary = NA,
                status = NA_character_))
  }
  hit <- ci[ci$parm == TARGET, , drop = FALSE]
  if (nrow(hit) != 1L) {
    return(list(lower = NA_real_, upper = NA_real_, boundary = NA,
                status = NA_character_))
  }
  list(
    lower    = as.numeric(hit$lower[[1L]]),
    upper    = as.numeric(hit$upper[[1L]]),
    boundary = as.logical(hit$profile.boundary[[1L]]),
    status   = as.character(hit$conf.status[[1L]])
  )
}

one <- function(r) {
  seed <- 20260727L + 100000L * cell$cell_i + r
  set.seed(seed)
  g <- factor(rep(seq_len(cell$n_groups), each = cell$n_per))
  x <- rnorm(length(g))
  u <- rnorm(cell$n_groups, 0, cell$sd_mu)
  y <- 1 + TRUE_BETA * x + u[as.integer(g)] + rnorm(length(g), 0, TRUE_SIGMA)
  dat <- data.frame(y = y, x = x, g = g)

  na <- data.frame(
    rep = r, seed = seed, cell_id = cell$cell_id, truth = cell$sd_mu,
    ok = FALSE,
    lo95 = NA_real_, hi95 = NA_real_, bnd95 = NA, st95 = NA_character_,
    lo90 = NA_real_, hi90 = NA_real_, bnd90 = NA, st90 = NA_character_,
    stringsAsFactors = FALSE
  )

  fit <- try(drmTMB(bf(y ~ x + (1 | g), sigma ~ 1),
                    family = gaussian(), data = dat), silent = TRUE)
  if (inherits(fit, "try-error")) return(na)

  ci95 <- suppressWarnings(try(stats::confint(
    fit, parm = "variance_components", method = "profile",
    profile_engine = "auto", level = 0.95), silent = TRUE))
  ci90 <- suppressWarnings(try(stats::confint(
    fit, parm = "variance_components", method = "profile",
    profile_engine = "auto", level = 0.90), silent = TRUE))

  a <- pick(ci95); b <- pick(ci90)
  data.frame(
    rep = r, seed = seed, cell_id = cell$cell_id, truth = cell$sd_mu,
    ok = TRUE,
    lo95 = a$lower, hi95 = a$upper, bnd95 = a$boundary, st95 = a$status,
    lo90 = b$lower, hi90 = b$upper, bnd90 = b$boundary, st90 = b$status,
    stringsAsFactors = FALSE
  )
}

res <- if (cores > 1L) {
  mclapply(seq_len(nrep), one, mc.cores = cores)
} else {
  lapply(seq_len(nrep), one)
}
bad <- vapply(res, function(z) !is.data.frame(z), logical(1))
if (any(bad)) stop(sprintf("%d replicate(s) failed", sum(bad)), call. = FALSE)
out <- do.call(rbind, res)

truth <- cell$sd_mu
out$cov95 <- is.finite(out$lo95) & is.finite(out$hi95) &
  out$lo95 <= truth & truth <= out$hi95
out$cov90 <- is.finite(out$lo90) & is.finite(out$hi90) &
  out$lo90 <= truth & truth <= out$hi90
out$w95 <- out$hi95 - out$lo95
out$w90 <- out$hi90 - out$lo90
# Nesting check: the chi-bar (level-0.90 cutoff) interval must sit INSIDE the
# chi2_1 (level-0.95) interval for every replicate. If it ever does not, the
# level-set assumption is wrong and the whole argument fails.
out$nested <- is.finite(out$lo95) & is.finite(out$lo90) &
  out$lo90 >= out$lo95 - 1e-8 & out$hi90 <= out$hi95 + 1e-8

if (!is.na(outf) && nzchar(outf)) {
  write.csv(out, outf, row.names = FALSE)
}

usable <- out$ok & is.finite(out$lo95) & is.finite(out$lo90)
bset <- usable & !is.na(out$bnd95) & out$bnd95
cat(sprintf("\n=== cell %s (truth sd = %.2f), n = %d ===\n",
            cell$cell_id, truth, nrow(out)))
cat(sprintf("usable replicates      : %d\n", sum(usable)))
cat(sprintf("nesting holds          : %d / %d\n", sum(out$nested[usable]), sum(usable)))
cat(sprintf("at boundary (level .95): %d (%.1f%%)\n", sum(bset), 100 * mean(bset[usable])))
cat(sprintf("\nOVERALL   coverage  chi2_1 (shipped, 95%%) : %.4f\n", mean(out$cov95[usable])))
cat(sprintf("OVERALL   coverage  chi-bar   (corrected) : %.4f\n", mean(out$cov90[usable])))
if (sum(bset) > 0) {
  cat(sprintf("\nCONDITIONAL on boundary, chi2_1  : %.4f  (n = %d)\n",
              mean(out$cov95[bset]), sum(bset)))
  cat(sprintf("CONDITIONAL on boundary, chi-bar : %.4f  (n = %d)\n",
              mean(out$cov90[bset]), sum(bset)))
}
cat(sprintf("\nmean width chi2_1  : %.4f\nmean width chi-bar : %.4f\n",
            mean(out$w95[usable]), mean(out$w90[usable])))
cat("=== END ===\n")
