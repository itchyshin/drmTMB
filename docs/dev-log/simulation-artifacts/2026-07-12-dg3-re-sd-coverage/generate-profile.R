# Arc 4a: DG3 RE-SD coverage, PROFILE interval vs Wald(log-SD). The DG3 finding was
# that the Wald interval degenerates at small M (Inf upper limit). drmTMB's featured
# interval is the profile (D-12); the endpoint engine is bounded where Wald-on-log is
# not. This records BOTH intervals per replicate + denominator columns so the
# "Inf-artifact removed" claim is auditable in the TSV itself.
if (dir.exists(path.expand("~/Rlib"))) .libPaths("~/Rlib")
suppressWarnings(suppressMessages({library(drmTMB); library(parallel)}))
Sys.setenv(OPENBLAS_NUM_THREADS = "1")

NSIM   <- as.integer(Sys.getenv("NSIM", "600"))
NCORES <- as.integer(Sys.getenv("NCORES", "80"))
MS     <- as.integer(strsplit(Sys.getenv("MS", "8,16,32,64"), ",")[[1]])
NEACH  <- as.integer(Sys.getenv("NEACH", "12"))
Z <- stats::qnorm(0.975)

specs <- list(
  gaussian_slope = list(true_sd = 0.6, sdrow = "log_sd_mu", sd_parm = "sd:mu:(0 + x | id)",
    fit = function(d) drmTMB(bf(y ~ x + (0 + x | id)), family = gaussian(), data = d),
    sim = function(M, ne, s) { set.seed(s); id <- factor(rep(seq_len(M), each = ne)); n <- length(id)
      x <- rnorm(n); u <- rnorm(M, sd = 0.6); u <- u - mean(u)
      data.frame(y = 0.2 + 0.7 * x + u[id] * x + rnorm(n), x = x, id = id) }),
  binomial_slope = list(true_sd = 0.6, sdrow = "log_sd_mu", sd_parm = "sd:mu:(0 + x | id)",
    fit = function(d) drmTMB(bf(cbind(succ, fail) ~ x + (0 + x | id)), family = binomial(), data = d),
    sim = function(M, ne, s) { set.seed(s); id <- factor(rep(seq_len(M), each = ne)); n <- length(id)
      x <- rnorm(n); u <- rnorm(M, sd = 0.6); u <- u - mean(u)
      p <- plogis(-0.2 + 0.7 * x + u[id] * x); succ <- rbinom(n, 12, p)
      data.frame(succ = succ, fail = 12 - succ, x = x, id = id) }),
  lognormal_sigma = list(true_sd = 0.4, sdrow = "log_sd_sigma", sd_parm = "sd:sigma:(1 | id)",
    fit = function(d) drmTMB(bf(y ~ x, sigma ~ (1 | id)), family = lognormal(), data = d),
    sim = function(M, ne, s) { set.seed(s); id <- factor(rep(seq_len(M), each = ne)); n <- length(id)
      x <- rnorm(n); u <- rnorm(M, sd = 0.4); u <- u - mean(u)
      sdlog <- exp(-0.5 + u[id]); data.frame(y = rlnorm(n, meanlog = 0.2 + 0.5 * x, sdlog = sdlog), x = x, id = id) })
)

one <- function(spec, M, ne, s) {
  d <- spec$sim(M, ne, s)
  fit <- tryCatch(spec$fit(d), error = function(e) NULL)
  na <- c(ok = 0, wcov = NA, whiinf = NA, wwidth = NA, pcov = NA, pfin = NA, pfail = NA, pwidth = NA)
  if (is.null(fit) || !isTRUE(fit$opt$convergence == 0) || !isTRUE(fit$sdr$pdHess)) return(na)
  # Wald(log-SD)
  sm <- summary(fit$sdr); r <- which(rownames(sm) == spec$sdrow)
  if (!length(r)) return(na)
  est <- sm[r[1], "Estimate"]; se <- sm[r[1], "Std. Error"]
  wlo <- exp(est - Z * se); whi <- exp(est + Z * se)
  wcov <- as.numeric(spec$true_sd >= wlo && spec$true_sd <= whi)
  whiinf <- as.numeric(!is.finite(whi))
  wwidth <- if (is.finite(whi)) whi - wlo else NA
  # Profile
  ci <- tryCatch(confint(fit, parm = spec$sd_parm, method = "profile"), error = function(e) NULL)
  pcov <- NA; pfin <- 0; pfail <- 1; pwidth <- NA
  if (!is.null(ci) && nrow(ci) >= 1) {
    plo <- suppressWarnings(as.numeric(ci$lower[1])); phi <- suppressWarnings(as.numeric(ci$upper[1]))
    pstat <- as.character(ci$conf.status[1])
    ok_prof <- identical(pstat, "profile") && is.finite(plo) && is.finite(phi)
    pfail <- as.numeric(!ok_prof)
    pfin <- as.numeric(is.finite(phi))
    if (ok_prof) { pcov <- as.numeric(spec$true_sd >= plo && spec$true_sd <= phi); pwidth <- phi - plo }
  }
  c(ok = 1, wcov = wcov, whiinf = whiinf, wwidth = wwidth, pcov = pcov, pfin = pfin, pfail = pfail, pwidth = pwidth)
}

rows <- list()
for (nm in names(specs)) {
  sp <- specs[[nm]]
  for (M in MS) {
    seeds <- 20260900L + seq_len(NSIM)
    res <- do.call(rbind, mclapply(seeds, function(s) one(sp, M, NEACH, s), mc.cores = NCORES))
    ok <- res[, "ok"] == 1; nok <- sum(ok)
    m <- function(col, mask = ok) mean(res[mask, col], na.rm = TRUE)
    rows[[length(rows) + 1L]] <- data.frame(
      spec = nm, M = M, n_ok = nok, nsim = NSIM, sd_true = sp$true_sd,
      wald_coverage = round(m("wcov"), 3), wald_hi_inf_rate = round(m("whiinf"), 3),
      profile_coverage = round(m("pcov"), 3), profile_finite_rate = round(m("pfin"), 3),
      profile_failed_rate = round(m("pfail"), 3),
      profile_width = round(m("pwidth"), 3), wald_width = round(m("wwidth"), 3))
    cat(sprintf("%-16s M=%-3d n_ok=%d  WALD cov=%.3f hiInf=%.3f | PROF cov=%.3f finite=%.3f fail=%.3f\n",
                nm, M, nok, m("wcov"), m("whiinf"), m("pcov"), m("pfin"), m("pfail")))
  }
}
tab <- do.call(rbind, rows)
write.table(tab, "~/drmTMB_work/dg3-profile-coverage-results.tsv", sep = "\t", row.names = FALSE, quote = FALSE)
cat("\nWROTE ~/drmTMB_work/dg3-profile-coverage-results.tsv\nDG3-PROFILE DONE\n")
