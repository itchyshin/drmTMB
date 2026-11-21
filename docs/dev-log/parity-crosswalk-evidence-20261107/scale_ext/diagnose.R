# Diagnosis of flagged seeds, R-side oracle: R's TMB objective evaluated at Julia's estimate (same likelihood function),
# re-optimised from Julia's estimate and from R's, and from 40 jittered R starts.
# usage: SC_OUT=<out> DRMTMB_LIB=<lib> Rscript diagnose.R <route> <seed> [<seed> ...]  -> appends to $SC_OUT/summary/diagnosis.csv
args <- commandArgs(TRUE); route <- args[1]; seeds <- as.integer(args[-1]); O <- Sys.getenv("SC_OUT", ".")
.libPaths(c(Sys.getenv("DRMTMB_LIB"), .libPaths())); suppressPackageStartupMessages(library(drmTMB)); source("routes.R")
tree <- if (route == "nb2_phylo") ape::read.tree("tree.nwk") else NULL
rt <- ROUTES[[route]]; o <- rt$nmu + as.integer(rt$sigma)
out <- list()
for (s in seeds) {
  tag <- sprintf("%s_s%03d", route, s); ds <- read_dataset(O, tag, route); d <- ds$d; K <- ds$K
  m <- build_model(route, d, K, tree)
  fit <- drmTMB(m$bf, family = m$family, data = d); obj <- fit$obj; pr <- fit$opt$par
  jv <- read.csv(file.path(O, "julia", paste0(tag, ".csv"))); jpar <- jv$est
  jl <- read.csv(file.path(O, "julia", paste0(tag, "_ll.csv")), colClasses = c(ll = "character", msg = "character"))
  jll <- suppressWarnings(as.numeric(jl$ll)); jerr <- jl$converged == "error"
  if (rt$rho == "q2") jpar[length(jpar)] <- asinh(jpar[length(jpar)])      # Julia theta = rho/sqrt(1-rho^2); R eta = atanh(rho) = asinh(theta)
  have_j <- !jerr && length(jpar) == length(pr)
  nll <- function(p) tryCatch(obj$fn(p), error = function(e) NA_real_)
  ll_R <- -nll(pr); ll_Robj_at_J <- if (have_j) -nll(jpar) else NA_real_
  polish <- function(p0) tryCatch(nlminb(p0, obj$fn, obj$gr, control = list(iter.max = 1000, eval.max = 2000)), error = function(e) NULL)
  pj <- if (have_j) polish(jpar) else NULL; pr2 <- polish(pr)
  set.seed(100 + s); res <- lapply(1:40, function(k) polish(pr + rnorm(length(pr), sd = 0.7)))
  lls <- sapply(res, function(r) if (is.null(r)) NA_real_ else -r$objective)
  lls <- c(lls, if (!is.null(pj)) -pj$objective, if (!is.null(pr2)) -pr2$objective, ll_R, ll_Robj_at_J); lls <- lls[is.finite(lls)]; best <- max(lls)
  sdv <- function(b) sapply(seq_along(rt$coefs), function(f) exp(b[o + 2 * f - 1] + b[o + 2 * f] * d[[rt$sdz[f]]]))
  sdr <- sdv(pr); sdj <- if (have_j) sdv(jpar) else matrix(NA_real_, 1, length(rt$coefs))
  out[[tag]] <- data.frame(route = route, seed = s, julia_error = jerr, ll_R_default = ll_R, ll_Julia_reported = jll, ll_Robj_at_Julia_par = ll_Robj_at_J,
    ll_R_polish_from_Julia = if (!is.null(pj)) -pj$objective else NA, max_par_move_Julia_polish = if (!is.null(pj)) max(abs(pj$par - jpar)) else NA,
    ll_R_polish_from_R = if (!is.null(pr2)) -pr2$objective else NA, ll_best_over_start_set = best,
    n_starts_within_1e6_of_best = sum(lls > best - 1e-6), n_distinct_optima_1e4 = length(unique(round(lls[lls > best - 50], 4))),
    R_min_sd = min(sdr), R_max_sd = max(sdr), J_min_sd = min(sdj), J_max_sd = max(sdj),
    R_pdHess = isTRUE(fit$sdr$pdHess), R_grad_max = max(abs(obj$gr(pr))), J_grad_max_in_Robj = if (have_j) max(abs(obj$gr(jpar))) else NA)
  cat(tag, "done\n")
}
res <- do.call(rbind, out); f <- file.path(O, "summary", "diagnosis.csv"); write.table(res, f, sep = ",", row.names = FALSE, col.names = !file.exists(f), append = file.exists(f))
