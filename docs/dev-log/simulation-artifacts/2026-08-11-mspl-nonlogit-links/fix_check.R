# Does the intercept start fix the 33 cloglog-standard failures WITHOUT
# disturbing anything that already worked?
#
# Two arms, both required:
#   (a) REPAIR  -- the exact 33 failing (cell, rep) pairs from the G1 run.
#   (b) NO-REGRESSION -- a sample of fits that already PASSED, across all four
#       link/orientations, re-fitted and compared to their recorded estimates.
#       A start value must not move the optimum; if beta shifts materially,
#       the change is altering the estimator, not just where it starts.
#
# Usage: Rscript --no-init-file fix_check.R --src <pkg dir> [--nreg 150]

args <- commandArgs(trailingOnly = TRUE)
getarg <- function(k, d = NULL) { i <- match(k, args); if (is.na(i)) d else args[i + 1L] }
SRC  <- getarg("--src", ".")
NREG <- as.integer(getarg("--nreg", "150"))

suppressMessages(pkgload::load_all(SRC, quiet = TRUE))
options(drmTMB.mspl_evidence_unsafe = TRUE)

d <- read.delim(gzfile("data/g1_raw.tsv.gz"), stringsAsFactors = FALSE)
m <- d[d$estimator == "mspl", ]
m$ok <- !is.na(m$fi_finite_pos) & m$fi_finite_pos &
  is.finite(m$logdet_fi) & is.finite(m$beta)

ETA_D <- list(
  logit            = c(0, -2, -4, -6, -10),
  probit           = c(0, -1.2, -2.1, -3, -4.2),
  cloglog_standard = c(0, -2, -3.5, -5, -7),
  cloglog_mirrored = c(0, -2.4, -4.2, -6, -8.4)
)
link_of  <- function(cond) if (cond %in% c("cloglog_standard","cloglog_mirrored")) "cloglog" else cond
mirrored <- function(cond) identical(cond, "cloglog_mirrored")

simulate_cell <- function(cond, q, eta_d, G, n_per, seed) {
  set.seed(seed)
  inv <- stats::binomial(link = link_of(cond))$linkinv
  block <- factor(rep(seq_len(G), each = n_per)); N <- length(block)
  if (q == "q1") {
    trt <- rep(c(0, 1), length.out = N); u <- rnorm(G, sd = 0.7)
    y <- rbinom(N, 1, inv(eta_d + 1.0 * trt + u[block]))
    if (mirrored(cond)) y <- 1L - y
    list(d = data.frame(y = y, trt = trt, block = block), target = "trt")
  } else {
    x <- rnorm(N); u0 <- rnorm(G, sd = 0.7); u1 <- rnorm(G, sd = 0.4)
    y <- rbinom(N, 1, inv(eta_d + 1.0 * x + u0[block] + u1[block] * x))
    if (mirrored(cond)) y <- 1L - y
    list(d = data.frame(y = y, x = x, block = block), target = "x")
  }
}
fit_one <- function(sim, q, lk) {
  tryCatch({
    f <- if (q == "q1")
      drmTMB(bf(y ~ trt + (1 | block)), family = binomial(link = lk), data = sim$d, estimator = "mspl")
    else
      drmTMB(bf(y ~ x + (1 + x | block)), family = binomial(link = lk), data = sim$d, estimator = "mspl")
    mm <- f$mspl
    list(ok = isTRUE(mm$fixed_information_finite_positive) &&
           is.finite(mm$final_logdet_fixed_information) &&
           is.finite(coef(f, "mu")[[sim$target]]),
         beta = coef(f, "mu")[[sim$target]],
         logdet = mm$final_logdet_fixed_information)
  }, error = function(e) list(ok = FALSE, beta = NA_real_, logdet = NA_real_))
}
row_of <- function(r) {
  cc <- if (r$corner) list(G = 400L, n_per = 10L) else list(G = r$G, n_per = 10L)
  sim <- simulate_cell(r$cond, r$q, r$eta_d, cc$G, cc$n_per, r$seed)
  fit_one(sim, r$q, link_of(r$cond))
}

cat("=== ARM (a) REPAIR: the 33 recorded failures ===\n")
bad <- m[!m$ok, ]
cat("failures on record:", nrow(bad), "\n")
rep_ok <- 0L
for (i in seq_len(nrow(bad))) {
  r <- bad[i, ]
  o <- row_of(r)
  rep_ok <- rep_ok + isTRUE(o$ok)
}
cat(sprintf("now finite: %d / %d\n", rep_ok, nrow(bad)))

cat("\n=== ARM (b) NO-REGRESSION: previously-passing fits ===\n")
set.seed(1)
good <- m[m$ok, ]
idx <- unlist(lapply(split(seq_len(nrow(good)), good$cond), function(ix)
  sample(ix, min(length(ix), ceiling(NREG / 4)))))
chk <- good[idx, ]
res <- do.call(rbind, lapply(seq_len(nrow(chk)), function(i) {
  r <- chk[i, ]; o <- row_of(r)
  data.frame(cond = r$cond, still_ok = isTRUE(o$ok),
             d_beta = abs(o$beta - r$beta),
             r_beta = abs(o$beta - r$beta) / pmax(abs(r$beta), 1e-8))
}))
agg <- do.call(rbind, lapply(split(res, res$cond), function(s)
  data.frame(cond = s$cond[1], n = nrow(s), still_ok = sum(s$still_ok),
             max_abs_dbeta = max(s$d_beta, na.rm = TRUE),
             median_abs_dbeta = median(s$d_beta, na.rm = TRUE))))
print(agg, row.names = FALSE, digits = 6)
cat("\nany previously-passing fit now failing:", any(!res$still_ok), "\n")
