# G2 — does the logit-calibrated c_n matter for probit and cloglog?
# Grid, seeds, endpoints and decision rule frozen in PREREGISTRATION-G2-CN.md.
#
# Three arms on the SAME simulated dataset: shipped c_n (factor 2), per-link c_n
# (omega(0)^-1/2), and unpenalized ML as the anchor. logit is a NULL CONTROL --
# its per-link factor IS 2, so its two arms must come back bit-identical.
#
# Usage: Rscript g2_runner.R --lib <lib> --out <tsv> [--cell N] [--rfrom A] [--rto B]

args <- commandArgs(trailingOnly = TRUE)
getarg <- function(k, d = NULL) { i <- match(k, args); if (is.na(i)) d else args[i + 1L] }
SRC   <- getarg("--src", ".")
LIB   <- getarg("--lib", "")
OUT   <- getarg("--out", "g2_raw.tsv")
ONLY  <- getarg("--cell", NA)
RFROM <- as.integer(getarg("--rfrom", "1"))
RTO   <- as.integer(getarg("--rto", "1000"))

if (nzchar(LIB)) {
  .libPaths(c(LIB, .libPaths())); suppressMessages(library(drmTMB))
} else {
  suppressMessages(devtools::load_all(SRC, quiet = TRUE))
}
if (!"estimator" %in% names(formals(drmTMB::drmTMB))) stop("STALE BUILD: no `estimator` formal.")
options(drmTMB.mspl_evidence_unsafe = TRUE)
# Guard against a build predating the c_n override: without it both MSPL arms
# would be the SHIPPED constant and every cell would report a spurious zero
# difference -- a silent all-null campaign.
local({
  probe <- getOption("drmTMB.mspl_cn_factor_unsafe", NULL)
  options(drmTMB.mspl_cn_factor_unsafe = 1.0)
  d <- data.frame(y = c(0,1,0,1,1,0,1,0), trt = c(0,0,1,1,0,1,1,0),
                  block = factor(c(1,1,2,2,3,3,4,4)))
  f <- try(drmTMB(bf(y ~ trt + (1 | block)), family = binomial(link = "logit"),
                  data = d, estimator = "mspl"), silent = TRUE)
  options(drmTMB.mspl_cn_factor_unsafe = probe)
  if (inherits(f, "try-error")) stop("probe fit failed: ", conditionMessage(attr(f, "condition")))
  expect <- 1.0 * sqrt(2 / sum(rep(1L, nrow(d))))
  if (!isTRUE(all.equal(f$mspl$c_n, expect, tolerance = 1e-8))) {
    stop("STALE BUILD: drmTMB.mspl_cn_factor_unsafe has no effect (c_n = ",
         f$mspl$c_n, ", expected ", expect, "). Rebuild from the campaign SHA.")
  }
})

# omega(0)^(-1/2): logit 1/4 -> 2; probit 2/pi -> 1.2533; cloglog 1/(e-1) -> 1.3108
CN_FACTOR <- c(logit = 2, probit = 1 / sqrt(2 / pi), cloglog = 1 / sqrt(1 / (exp(1) - 1)))
ETA_D <- list(logit = c(0, -2, -4), probit = c(0, -1.2, -2.1), cloglog = c(0, -2, -3.5))
LINKS <- c("logit", "probit", "cloglog")

grid <- do.call(rbind, lapply(LINKS, function(lk)
  do.call(rbind, lapply(ETA_D[[lk]], function(e)
    data.frame(link = lk, eta_d = e, G = c(12L, 30L, 60L, 120L),
               n_per = 10L, stringsAsFactors = FALSE)))))
grid$cell <- seq_len(nrow(grid))
stopifnot(nrow(grid) == 36L)
if (!is.na(ONLY)) grid <- grid[grid$cell == as.integer(ONLY), , drop = FALSE]

simulate_cell <- function(lk, eta_d, G, n_per, seed) {
  set.seed(seed)
  inv <- stats::binomial(link = lk)$linkinv
  block <- factor(rep(seq_len(G), each = n_per)); N <- length(block)
  trt <- rep(c(0, 1), length.out = N); u <- rnorm(G, sd = 0.7)
  data.frame(y = rbinom(N, 1, inv(eta_d + 1.0 * trt + u[block])), trt = trt, block = block)
}
na1 <- function(x, f = NA_real_) if (is.null(x) || length(x) != 1L) f else x
flat <- function(s) if (is.null(s) || length(s) != 1L || is.na(s)) "" else
  gsub("[[:space:]]+", " ", trimws(substr(as.character(s), 1, 160)))

fit_arm <- function(d, lk, arm, factor_value) {
  if (identical(arm, "ml")) {
    options(drmTMB.mspl_cn_factor_unsafe = NULL)
    est <- "ml"
  } else {
    options(drmTMB.mspl_cn_factor_unsafe = if (identical(arm, "shipped")) NULL else factor_value)
    est <- "mspl"
  }
  out <- tryCatch({
    f <- drmTMB(bf(y ~ trt + (1 | block)), family = binomial(link = lk), data = d, estimator = est)
    v <- suppressWarnings(sqrt(diag(vcov(f))))
    list(ok = TRUE, beta = na1(coef(f, "mu")[["trt"]]),
         se = if ("mu:trt" %in% names(v)) v[["mu:trt"]] else NA_real_,
         c_n = if (is.null(f$mspl)) NA_real_ else na1(f$mspl$c_n),
         conv = as.integer(na1(f$opt$convergence, NA_integer_)), err = NA_character_)
  }, error = function(e) list(ok = FALSE, beta = NA_real_, se = NA_real_,
                              c_n = NA_real_, conv = NA_integer_, err = conditionMessage(e)))
  options(drmTMB.mspl_cn_factor_unsafe = NULL)
  out
}

rows <- list()
for (i in seq_len(nrow(grid))) {
  g <- grid[i, ]
  fac <- unname(CN_FACTOR[[g$link]])
  for (r in RFROM:RTO) {
    seed <- 20260814 + 100000 * g$cell + r          # prereg §2, frozen
    d <- simulate_cell(g$link, g$eta_d, g$G, g$n_per, seed)
    ev <- mean(d$y)
    for (arm in c("shipped", "perlink", "ml")) {
      f <- fit_arm(d, g$link, arm, fac)
      rows[[length(rows) + 1L]] <- data.frame(
        cell = g$cell, link = g$link, eta_d = g$eta_d, G = g$G,
        n_eff = g$G * g$n_per, rep = r, seed = seed, arm = arm,
        cn_factor = if (arm == "ml") NA_real_ else if (arm == "shipped") 2 else fac,
        event_rate = ev, ok = f$ok, beta = f$beta, se = f$se, c_n = f$c_n,
        conv = f$conv, err = flat(f$err), stringsAsFactors = FALSE)
    }
  }
}
out <- do.call(rbind, rows)
write.table(out, OUT, sep = "\t", row.names = FALSE, quote = FALSE)
cat("wrote", nrow(out), "rows to", OUT, "\n")
