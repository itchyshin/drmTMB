# sweep-oct16 / t5 -- engine = "julia" leg (drmTMB -> JuliaCall -> DRModels.jl).
# One R session (Julia starts once). Per dataset: weights omitted / NULL /
# all-ones / integer / random positive, explicit miss_control(), and the
# integer-duplicated data with weights omitted.
#
# R 4.3.3 lacks base `%||%` and drmTMB at ca3ddefa neither defines nor imports
# it (drmTMB #1550; fixed in open PRs #1502 / #1504). The shim below supplies
# base R 4.4's definition from the global environment, which the package
# namespace reaches after base. No package code is modified.
`%||%` <- function(x, y) if (is.null(x)) y else x
#
# Usage: Rscript R/run_bridge.R <datadir> <outfile>
args <- commandArgs(trailingOnly = TRUE)
datadir <- args[[1]]; outfile <- args[[2]]
suppressMessages(library(drmTMB))
source(file.path(dirname(sub("--file=", "", grep("--file=", commandArgs(FALSE), value = TRUE))), "oracle.R"))
stopifnot(nzchar(Sys.getenv("DRMODELS_JL_PATH")))

fam_obj <- function(f) switch(f, gaussian = gaussian(), poisson = poisson(link = "log"),
                              gamma = Gamma(link = "log"))
fam_form <- function(f) if (f == "poisson") bf(y ~ x + (1 | g)) else bf(y ~ x + (1 | g), sigma ~ 1)
oneline <- function(s) gsub("[\r\n]+", " | ", s)

run_fit <- function(expr, env = parent.frame()) {
  ex <- substitute(expr)
  t0 <- proc.time()[["elapsed"]]
  warns <- character()
  out <- withCallingHandlers(
    tryCatch(list(fit = eval(ex, env), err = NA_character_,
                  errclass = NA_character_),
             error = function(e) list(fit = NULL, err = oneline(conditionMessage(e)),
                                      errclass = class(e)[[1]])),
    warning = function(w) { warns <<- c(warns, oneline(conditionMessage(w))); invokeRestart("muffleWarning") })
  out$secs <- proc.time()[["elapsed"]] - t0
  out$warns <- warns
  out
}

man <- read.csv(file.path(datadir, "manifest.csv"), colClasses = c(seed_nominal = "character"))
rows <- list()
for (r in seq_len(nrow(man))) {
  id <- man$id[r]; fam <- man$family[r]
  d <- read.csv(file.path(datadir, paste0(id, ".csv")), stringsAsFactors = FALSE)
  d$one <- 1
  cc <- complete.cases(d[, c("y", "x", "g")]); dcc <- d[cc, ]
  ddup <- d[rep(seq_len(nrow(d)), d$w_int), ]
  F <- fam_form(fam); FO <- fam_obj(fam)
  fits <- list(
    J0_omitted     = run_fit(drmTMB(F, family = FO, data = d, engine = "julia")),
    J1_null        = run_fit(drmTMB(F, family = FO, data = d, weights = NULL, engine = "julia")),
    J2_ones        = run_fit(drmTMB(F, family = FO, data = d, weights = one, engine = "julia")),
    J3_int         = run_fit(drmTMB(F, family = FO, data = d, weights = w_int, engine = "julia")),
    J4_pos         = run_fit(drmTMB(F, family = FO, data = d, weights = w_pos, engine = "julia")),
    J6_misscontrol = run_fit(drmTMB(F, family = FO, data = d, missing = miss_control(), engine = "julia")),
    J7_dup         = run_fit(drmTMB(F, family = FO, data = ddup, engine = "julia"))
  )
  for (nm in names(fits)) {
    f <- fits[[nm]]
    base <- data.frame(id = id, family = fam, na_y = man$na_y[r], na_x = man$na_x[r],
                       n_complete_harness = sum(cc), fit = nm, secs = f$secs,
                       status = if (is.null(f$fit)) "error" else "ok",
                       errclass = f$errclass, error = f$err,
                       nwarn = length(f$warns), warn1 = if (length(f$warns)) f$warns[[1]] else NA_character_,
                       stringsAsFactors = FALSE)
    if (!is.null(f$fit)) {
      fit <- f$fit; cf <- coef(fit)
      sdg <- fit$sdpars$mu
      sd_g <- unname(if (!is.null(sdg[["g"]])) sdg[["g"]] else if (!is.null(sdg[["(1 | g)"]])) sdg[["(1 | g)"]] else NA_real_)
      s <- list(logLik = as.numeric(logLik(fit)), b_mu0 = unname(cf$mu[[1]]), b_mu1 = unname(cf$mu[[2]]),
                b_sigma0 = if (fam == "poisson") NA_real_ else unname(cf$sigma[[1]]),
                sd_g = sd_g, sd_names = paste(names(sdg), collapse = ";"),
                nobs = nobs(fit), class = paste(class(fit), collapse = ";"),
                marginal = paste(fit$bridge[["marginal"]] %||% NA, collapse = ";"),
                estim_method = paste(fit$bridge[["estim_method"]] %||% NA, collapse = ";"),
                converged = tryCatch(isTRUE(is_converged(fit)), error = function(e) NA))
      base <- cbind(base, as.data.frame(s, stringsAsFactors = FALSE))
      od <- if (nm == "J7_dup") ddup[complete.cases(ddup[, c("y", "x", "g")]), ] else dcc
      base$oracle_ll <- if (is.finite(sd_g))
        laplace_oracle(fam, od$y, od$x, od$g, rep(1, nrow(od)), s$b_mu0, s$b_mu1, s$b_sigma0, sd_g) else NA_real_
    }
    rows[[length(rows) + 1L]] <- base
    cat(sprintf("[%s] %-15s %-5s %s\n", id, nm, base$status, substr(ifelse(is.na(base$error), "", base$error), 1, 120)))
    flush.console()
  }
}
cols <- c("id","family","na_y","na_x","n_complete_harness","fit","secs","status","errclass","error",
          "nwarn","warn1","logLik","b_mu0","b_mu1","b_sigma0","sd_g","sd_names","nobs","class",
          "marginal","estim_method","converged","oracle_ll")
res <- do.call(rbind, lapply(rows, function(x) { for (cn in setdiff(cols, names(x))) x[[cn]] <- NA; x[, cols] }))
write.csv(res, outfile, row.names = FALSE)
cat("wrote", outfile, "\n")
