# Profile-engine speed benchmark: endpoint solver vs TMB::tmbprofile.
#
# drmTMB's confint(method="profile") has profile_engine = c("auto","endpoint",
# "tmbprofile"). The "endpoint" engine root-finds directly for the two CI endpoints
# of DIRECT scale/SD/correlation targets; "tmbprofile" evaluates a full grid. This
# benchmarks per-call wall-clock time (block-timed to beat clock resolution) and
# confirms the two engines agree on the CI endpoints. Boundary: native R/TMB timing
# diagnostic (machine-specific; reported as a ratio), not a coverage claim.
#
# Usage: Rscript --vanilla run.R [k_calls]
suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
k <- if (length(args) >= 1L) as.integer(args[[1L]]) else 10L
out_dir <- "docs/dev-log/simulation-artifacts/2026-06-20-profile-engine-speed-benchmark"
dir.create(file.path(out_dir, "tables"), recursive = TRUE, showWarnings = FALSE)

per_call <- function(fit, parm, engine, k) {
  el <- system.time(for (i in seq_len(k)) {
    suppressWarnings(confint(fit, parm = parm, method = "profile",
                             profile_engine = engine))
  })[["elapsed"]]
  el / k
}
bench_one <- function(label, fit, parm) {
  e <- suppressWarnings(confint(fit, parm = parm, method = "profile", profile_engine = "endpoint"))
  t <- suppressWarnings(confint(fit, parm = parm, method = "profile", profile_engine = "tmbprofile"))
  te <- per_call(fit, parm, "endpoint", k)
  tt <- per_call(fit, parm, "tmbprofile", k)
  data.frame(target = label, parm = parm,
             endpoint_ms = round(1000 * te, 1), tmbprofile_ms = round(1000 * tt, 1),
             speedup = round(tt / te, 2),
             endpoint_engine = e$profile.engine[[1L]], tmbprofile_engine = t$profile.engine[[1L]],
             max_endpoint_diff = signif(max(abs(c(e$lower - t$lower, e$upper - t$upper)), na.rm = TRUE), 3),
             stringsAsFactors = FALSE)
}

rows <- list(); ri <- 0L
addrow <- function(x) { ri <<- ri + 1L; rows[[ri]] <<- x }

## 1. Gaussian residual scale (sigma), n=2000 -- fast direct scale target.
set.seed(101); n <- 2000L; x <- rnorm(n)
dG <- data.frame(y = 0.3 + 0.5 * x + rnorm(n, 0, 0.8), x = x)
fG <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dG)
addrow(bench_one("gaussian sigma (scale), n=2000", fG, "sigma"))

## 2. relmat random-intercept SD (n_id=80) -- structured SD target.
set.seed(202); n_id <- 80L; n_each <- 8L
K <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.5^abs(i - j))
idl <- paste0("id", seq_len(n_id)); dimnames(K) <- list(idl, idl)
cK <- t(chol(K)); u <- 0.6 * as.vector(cK %*% rnorm(n_id)); names(u) <- idl
id <- rep(idl, each = n_each); xr <- rep(seq(-1, 1, length.out = n_each), n_id)
dR <- data.frame(y = 0.25 + 0.45 * xr + u[id] + rnorm(length(id), 0, 0.4), x = xr, id = id)
Qmat <- solve(K)
fR <- drmTMB(bf(y ~ x + relmat(1 | id, Q = Qmat), sigma ~ 1), family = gaussian(), data = dR)
addrow(bench_one("relmat SD, n_id=80", fR, "sd:mu:relmat(1 | id)"))

## 3. phylo random-intercept SD (120 species) -- structured SD target.
set.seed(303); n_sp <- 120L
tree <- ape::rcoal(n_sp); tree$tip.label <- paste0("sp", seq_len(n_sp))
Cc <- stats::cov2cor(ape::vcv(tree)); cC <- t(chol(Cc)); tips <- tree$tip.label
up <- 0.7 * as.vector(cC %*% rnorm(n_sp)); names(up) <- tips
xp <- rnorm(n_sp); dP <- data.frame(y = 0.3 + 0.5 * xp + up[tips] + rnorm(n_sp, 0, 0.4), x = xp, species = tips)
fP <- drmTMB(bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1), family = gaussian(), data = dP)
addrow(bench_one("phylo SD, 120 species", fP, "sd:mu:phylo(1 | species)"))

tab <- do.call(rbind, rows)
write.csv(tab, file.path(out_dir, "tables", "profile-engine-benchmark.csv"), row.names = FALSE)
cat("=== Profile engine speed benchmark (per-call mean of", k, "calls) ===\n")
print(tab, row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
cat("DONE\n")
