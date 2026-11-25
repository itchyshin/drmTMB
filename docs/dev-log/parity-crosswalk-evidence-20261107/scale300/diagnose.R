# Diagnosis of disagreeing / flagged seeds, R-side oracle (the likelihood is the same function in both packages, so R's TMB
# objective can be evaluated at Julia's estimate and re-optimised from several starts).
# usage: SC_OUT=<out> DRMTMB_LIB=<lib> Rscript diagnose.R <route> <seed> [<seed> ...]  -> appends to $SC_OUT/diagnosis.csv
args <- commandArgs(TRUE); route <- args[1]; seeds <- as.integer(args[-1]); O <- Sys.getenv("SC_OUT", ".")
.libPaths(c(Sys.getenv("DRMTMB_LIB"), .libPaths())); suppressPackageStartupMessages(library(drmTMB))
tree <- ape::read.tree("tree.nwk"); cc <- read.csv("coords.csv"); coords <- as.matrix(cc[, 2:3]); rownames(coords) <- cc$id
lord <- route %in% c("lord_poisson", "lord_nb2")
sdform <- function(lev, coef, z) as.formula(if (lord) sprintf('sd(id, dpar = "mu", coef = "%s") ~ %s', coef, z) else if (is.null(lev)) sprintf('sd(id, coef = "%s") ~ %s', coef, z) else sprintf('sd(id, level = "%s", coef = "%s") ~ %s', lev, coef, z))
cfg <- list(poisson_animal = list("animal(1 + x | id, A = K)", "animal", FALSE, stats::poisson()),
  poisson_labelled = list("animal(1 + x | p | id, A = K)", "animal", FALSE, stats::poisson()),
  nb2_relmat = list("relmat(1 + x | id, K = K)", "relmat", TRUE, nbinom2()),
  gauss_animal = list("animal(1 + x | id, A = K)", "animal", TRUE, gaussian()),
  gauss_ord = list("(1 + x | id)", NULL, TRUE, gaussian()),
  lord_poisson = list("(1 + x | id)", NULL, FALSE, stats::poisson()), lord_nb2 = list("(1 + x | id)", NULL, TRUE, nbinom2()),
  poisson_phylo = list("phylo(1 + x | id, tree = tree)", "phylogenetic", FALSE, stats::poisson()),
  poisson_spatial = list("spatial(1 + x | id, coords = coords)", "spatial", FALSE, stats::poisson()))[[route]]
has_sigma <- cfg[[3]]; o <- 2L + as.integer(has_sigma)
out <- list()
for (s in seeds) {
  tag <- sprintf("%s_s%03d", route, s); d <- read.csv(file.path(O, "data", paste0(tag, ".csv"))); ids <- unique(d$g); d$id <- factor(d$g, levels = ids)
  kf <- file.path(O, "data", paste0(tag, "_K.csv"))
  if (file.exists(kf)) { K <- as.matrix(read.csv(kf, header = FALSE)); kid <- read.csv(file.path(O, "data", paste0(tag, "_ids.csv")))$id; dimnames(K) <- list(kid, kid) }
  if (route %in% c("poisson_phylo", "poisson_spatial")) d$id <- factor(d$g)
  f <- as.formula(paste("y ~ x +", cfg[[1]])); environment(f) <- environment()
  s0 <- sdform(cfg[[2]], "(Intercept)", "z0"); s1 <- sdform(cfg[[2]], "x", "z1")
  fm <- if (has_sigma) bf(f, sigma ~ 1, s0, s1) else bf(f, s0, s1)
  fit <- drmTMB(fm, family = cfg[[4]], data = d); obj <- fit$obj; pr <- fit$opt$par
  jv <- read.csv(file.path(O, "julia", paste0(tag, ".csv"))); jpar <- jv$est; jll <- as.numeric(read.csv(file.path(O, "julia", paste0(tag, "_ll.csv")), colClasses = c(ll = "character"))$ll)
  stopifnot(length(jpar) == length(pr))
  nll <- function(p) tryCatch(obj$fn(p), error = function(e) NA_real_)
  ll_R <- -nll(pr); ll_Robj_at_J <- -nll(jpar)
  polish <- function(p0) tryCatch(nlminb(p0, obj$fn, obj$gr, control = list(iter.max = 1000, eval.max = 2000)), error = function(e) NULL)
  pj <- polish(jpar); pr2 <- polish(pr)
  set.seed(100 + s); starts <- lapply(1:40, function(k) pr + rnorm(length(pr), sd = 0.7)); res <- lapply(starts, polish)
  lls <- sapply(res, function(r) if (is.null(r)) NA_real_ else -r$objective); lls <- c(lls, if (!is.null(pj)) -pj$objective, if (!is.null(pr2)) -pr2$objective, ll_R, ll_Robj_at_J)
  lls <- lls[is.finite(lls)]; best <- max(lls)
  sdv <- function(b) cbind(exp(b[o + 1] + b[o + 2] * d$z0), exp(b[o + 3] + b[o + 4] * d$z1))
  sdr <- sdv(pr); sdj <- sdv(jpar)
  jp_polish_move <- if (!is.null(pj)) max(abs(pj$par - jpar)) else NA
  out[[tag]] <- data.frame(route = route, seed = s, ll_R_default = ll_R, ll_Julia_reported = jll, ll_Robj_at_Julia_par = ll_Robj_at_J,
    ll_R_polish_from_Julia = if (!is.null(pj)) -pj$objective else NA, max_par_move_Julia_polish = jp_polish_move,
    ll_R_polish_from_R = if (!is.null(pr2)) -pr2$objective else NA, ll_best_over_41_starts = best,
    n_starts_within_1e6_of_best = sum(lls > best - 1e-6) , n_distinct_optima_1e4 = length(unique(round(lls[lls > best - 50], 4))),
    n_starts_below_best_1e4 = sum(lls < best - 1e-4),
    R_min_sd_int = min(sdr[, 1]), R_max_sd_int = max(sdr[, 1]), R_min_sd_slope = min(sdr[, 2]), R_max_sd_slope = max(sdr[, 2]),
    J_min_sd_int = min(sdj[, 1]), J_max_sd_int = max(sdj[, 1]), J_min_sd_slope = min(sdj[, 2]), J_max_sd_slope = max(sdj[, 2]),
    R_pdHess = isTRUE(fit$sdr$pdHess), R_grad_max = max(abs(obj$gr(pr))), J_grad_max_in_Robj = max(abs(obj$gr(jpar))))
  cat(tag, "done\n")
}
res <- do.call(rbind, out); f <- file.path(O, "diagnosis.csv"); write.table(res, f, sep = ",", row.names = FALSE, col.names = !file.exists(f), append = file.exists(f))
