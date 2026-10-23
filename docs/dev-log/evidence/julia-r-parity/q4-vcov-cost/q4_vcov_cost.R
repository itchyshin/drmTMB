worktree <- normalizePath(Sys.getenv("DRMTMB_WORKTREE", getwd()))
suppressPackageStartupMessages({library(devtools); library(ape)})
load_all(worktree, quiet = TRUE)

jl_path <- Sys.getenv("DRM_JL_PATH")

# --- Fixture A: committed biv-q4-phylo-reml fixture (16 tips, 128 rows), REML ---
fixture <- file.path(jl_path, "test/parity/q4-reml/biv-q4-phylo-reml")
dat <- read.csv(file.path(fixture, "data.csv"), stringsAsFactors = FALSE)
tree <- read.tree(file.path(fixture, "tree.newick"))
dat$species <- factor(dat$species, levels = tree$tip.label)
formA <- bf(
  mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
  mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
  sigma1 = ~ 1 + phylo(1 | p | species, tree = tree),
  sigma2 = ~ 1 + phylo(1 | p | species, tree = tree),
  rho12 = ~1
)

# --- Fixture B: bigger simulated q4 phylo fit (60 tips, m=3 -> 180 rows), ML ---
set.seed(42)
N <- 60L; m <- 3L
treeB <- ape::rcoal(N)
sp <- treeB$tip.label
C <- ape::vcv(treeB, corr = TRUE)
LC <- t(chol(C))
Sa <- diag(c(0.8, 0.7, 0.3, 0.3))
Cor <- diag(4); Cor[1,2] <- Cor[2,1] <- 0.6
Sigma_a <- Sa %*% Cor %*% Sa
LSig <- t(chol(Sigma_a))
A <- LC %*% matrix(rnorm(N*4), N, 4) %*% t(LSig)
rows <- rep(seq_len(N), each = m)
x <- rnorm(N*m)
mean1 <- 2.0 + 0.5*x + A[rows,1]; mean2 <- -1.0 + 0.3*x + A[rows,2]
sig1 <- exp(log(0.5) + A[rows,3]); sig2 <- exp(log(0.6) + A[rows,4])
datB <- data.frame(species = sp[rows], x = x,
  y1 = rnorm(N*m, mean1, sig1), y2 = rnorm(N*m, mean2, sig2), stringsAsFactors = FALSE)
formB <- bf(
  mu1 = y1 ~ x + phylo(1 | p | species, tree = treeB),
  mu2 = y2 ~ x + phylo(1 | p | species, tree = treeB),
  sigma1 = ~ 1 + phylo(1 | p | species, tree = treeB),
  sigma2 = ~ 1 + phylo(1 | p | species, tree = treeB),
  rho12 = ~1
)

time_fit <- function(form, dat, reml, q4_vcov) {
  ctl <- drm_control(optimizer = list(q4_vcov = q4_vcov))
  t0 <- proc.time()[["elapsed"]]
  fit <- drmTMB(form, biv_gaussian(), dat, engine = "julia", REML = reml, control = ctl)
  el <- proc.time()[["elapsed"]] - t0
  list(elapsed = el, converged = is_converged(fit), finite_vcov = all(is.finite(vcov(fit))))
}

cat("Warming Julia (throwaway fit, not timed)...\n")
invisible(time_fit(formA, dat, TRUE, FALSE))

cat("\n=== Fixture A: 16 tips / 128 rows, REML ===\n")
a_false <- time_fit(formA, dat, TRUE, FALSE)
a_true  <- time_fit(formA, dat, TRUE, TRUE)
cat(sprintf("q4_vcov=FALSE: %.3fs converged=%s finite_vcov=%s\n", a_false$elapsed, a_false$converged, a_false$finite_vcov))
cat(sprintf("q4_vcov=TRUE:  %.3fs converged=%s finite_vcov=%s\n", a_true$elapsed, a_true$converged, a_true$finite_vcov))
cat(sprintf("delta: +%.3fs (+%.1f%%)\n", a_true$elapsed - a_false$elapsed, 100*(a_true$elapsed/a_false$elapsed - 1)))

cat("\n=== Fixture B: 60 tips / 180 rows, ML ===\n")
b_false <- time_fit(formB, datB, FALSE, FALSE)
b_true  <- time_fit(formB, datB, FALSE, TRUE)
cat(sprintf("q4_vcov=FALSE: %.3fs converged=%s finite_vcov=%s\n", b_false$elapsed, b_false$converged, b_false$finite_vcov))
cat(sprintf("q4_vcov=TRUE:  %.3fs converged=%s finite_vcov=%s\n", b_true$elapsed, b_true$converged, b_true$finite_vcov))
cat(sprintf("delta: +%.3fs (+%.1f%%)\n", b_true$elapsed - b_false$elapsed, 100*(b_true$elapsed/b_false$elapsed - 1)))
