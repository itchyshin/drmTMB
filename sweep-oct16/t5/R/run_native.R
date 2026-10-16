# sweep-oct16 / t5 -- native (engine = "tmb") leg.
# For each dataset: weights omitted / NULL / all-ones / integer / integer
# row-duplicated / random positive / random positive on pre-dropped data,
# plus an explicit miss_control() probe. Records fit summaries, fixed-p
# objective identities, and the independent Laplace oracle.
# Usage: Rscript R/run_native.R <datadir> <outfile>
args <- commandArgs(trailingOnly = TRUE)
datadir <- args[[1]]; outfile <- args[[2]]
suppressMessages(library(drmTMB))
source(file.path(dirname(sub("--file=", "", grep("--file=", commandArgs(FALSE), value = TRUE))), "oracle.R"))

fam_obj <- function(f) switch(f, gaussian = gaussian(), poisson = poisson(link = "log"),
                              gamma = Gamma(link = "log"))
fam_form <- function(f) if (f == "poisson") bf(y ~ x + (1 | g)) else bf(y ~ x + (1 | g), sigma ~ 1)

summ <- function(fit, fam) {
  cf <- coef(fit)
  list(logLik = as.numeric(logLik(fit)), b_mu0 = cf$mu[[1]], b_mu1 = cf$mu[[2]],
       b_sigma0 = if (fam == "poisson") NA_real_ else cf$sigma[[1]],
       sd_g = unname(fit$sdpars$mu[["(1 | g)"]]), nobs = nobs(fit),
       n_groups = nlevels(factor(fit$data$g)),
       conv = fit$opt$convergence, opt_msg = fit$opt$message,
       maxgrad = max(abs(fit$obj$gr(fit$opt$par))))
}

# Hard timeout so a hang is a finding. Default 180s; override with FIT_TIMEOUT.
FIT_TIMEOUT <- as.numeric(Sys.getenv("FIT_TIMEOUT", "180"))
run_fit <- function(expr) {
  t0 <- proc.time()[["elapsed"]]
  out <- tryCatch({
    setTimeLimit(elapsed = FIT_TIMEOUT, transient = TRUE)
    on.exit(setTimeLimit(elapsed = Inf), add = TRUE)
    list(fit = eval.parent(substitute(expr)), err = NA_character_)
  }, error = function(e) {
    setTimeLimit(elapsed = Inf)
    msg <- conditionMessage(e)
    if (grepl("reached elapsed time limit", msg, fixed = TRUE))
      msg <- sprintf("TIMEOUT after %.0fs", FIT_TIMEOUT)
    list(fit = NULL, err = msg)
  })
  out$secs <- proc.time()[["elapsed"]] - t0
  out
}

man <- read.csv(file.path(datadir, "manifest.csv"), colClasses = c(seed_nominal = "character"))
rows <- list(); checks <- list()
for (r in seq_len(nrow(man))) {
  id <- man$id[r]; fam <- man$family[r]
  d <- read.csv(file.path(datadir, paste0(id, ".csv")), stringsAsFactors = FALSE)
  d$one <- 1
  cc <- complete.cases(d[, c("y", "x", "g")])
  dcc <- d[cc, ]
  ddup <- d[rep(seq_len(nrow(d)), d$w_int), ]
  F <- fam_form(fam); FO <- fam_obj(fam)
  fits <- list(
    N0_omitted   = run_fit(drmTMB(F, family = FO, data = d)),
    N1_null      = run_fit(drmTMB(F, family = FO, data = d, weights = NULL)),
    N2_ones      = run_fit(drmTMB(F, family = FO, data = d, weights = one)),
    N3_int       = run_fit(drmTMB(F, family = FO, data = d, weights = w_int)),
    D3_dup       = run_fit(drmTMB(F, family = FO, data = ddup)),
    N4_pos       = run_fit(drmTMB(F, family = FO, data = d, weights = w_pos)),
    N5_pos_cc    = run_fit(drmTMB(F, family = FO, data = dcc, weights = w_pos)),
    N6_misscontrol = run_fit(drmTMB(F, family = FO, data = d, missing = miss_control()))
  )
  oracle_w <- list(N0_omitted = rep(1, nrow(dcc)), N1_null = rep(1, nrow(dcc)),
                   N2_ones = rep(1, nrow(dcc)), N3_int = dcc$w_int, N4_pos = dcc$w_pos,
                   N5_pos_cc = dcc$w_pos, N6_misscontrol = rep(1, nrow(dcc)))
  for (nm in names(fits)) {
    f <- fits[[nm]]
    base <- data.frame(id = id, family = fam, na_y = man$na_y[r], na_x = man$na_x[r],
                       n_complete_harness = sum(cc), fit = nm, secs = f$secs,
                       status = if (is.null(f$fit)) "error" else "ok",
                       error = f$err, stringsAsFactors = FALSE)
    if (!is.null(f$fit)) {
      s <- summ(f$fit, fam)
      base <- cbind(base, as.data.frame(s, stringsAsFactors = FALSE))
      if (nm == "D3_dup") {
        ddc <- ddup[complete.cases(ddup[, c("y", "x", "g")]), ]
        base$oracle_ll <- laplace_oracle(fam, ddc$y, ddc$x, ddc$g, rep(1, nrow(ddc)),
                                         s$b_mu0, s$b_mu1, s$b_sigma0, s$sd_g)
      } else {
        base$oracle_ll <- laplace_oracle(fam, dcc$y, dcc$x, dcc$g, oracle_w[[nm]],
                                         s$b_mu0, s$b_mu1, s$b_sigma0, s$sd_g)
      }
    }
    rows[[length(rows) + 1L]] <- base
  }
  # Fixed-parameter objective identities (independent of optimizer stopping).
  fx <- function(a, b) {
    if (is.null(fits[[a]]$fit) || is.null(fits[[b]]$fit)) return(c(NA, NA))
    p <- fits[[a]]$fit$opt$par
    c(fits[[a]]$fit$obj$fn(p) - fits[[b]]$fit$obj$fn(p),
      max(abs(fits[[a]]$fit$obj$gr(p) - fits[[b]]$fit$obj$gr(p))))
  }
  i3 <- fx("N3_int", "D3_dup"); i0 <- fx("N0_omitted", "N2_ones"); i5 <- fx("N4_pos", "N5_pos_cc")
  checks[[length(checks) + 1L]] <- data.frame(
    id = id, fn_int_minus_dup = i3[1], gr_int_minus_dup = i3[2],
    fn_omit_minus_ones = i0[1], gr_omit_minus_ones = i0[2],
    fn_pos_minus_poscc = i5[1], gr_pos_minus_poscc = i5[2])
  cat(sprintf("[%s] done\n", id)); flush.console()
}
res <- do.call(rbind, lapply(rows, function(x) {
  cols <- c("id","family","na_y","na_x","n_complete_harness","fit","secs","status","error",
            "logLik","b_mu0","b_mu1","b_sigma0","sd_g","nobs","n_groups","conv","opt_msg","maxgrad","oracle_ll")
  for (cn in setdiff(cols, names(x))) x[[cn]] <- NA
  x[, cols]
}))
write.csv(res, outfile, row.names = FALSE)
write.csv(do.call(rbind, checks), sub("\\.csv$", "_fixedp.csv", outfile), row.names = FALSE)
cat("wrote", outfile, "\n")
