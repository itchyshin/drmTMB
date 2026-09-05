## Shared-x fixture for leaf-biv-animal-reml G1/G3: mu1 and mu2 use the SAME
## fixed-effect design matrix (a single `x`), as DRM.jl's own bivariate q2
## structured route requires ("drm: bivariate q=2 structured Julia route
## currently requires mu1 and mu2 to use the same fixed-effect design",
## src/gaussian_bivariate.jl:498). Writes data.csv and K.csv so a plain
## Julia script (no JuliaCall/R bridge) can read them with readdlm, matching
## the pattern in docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-01
## -matched-q4/warmstart_575.jl.

arc1b_s2r_K <- function(g) {
  level <- sprintf("id_%03d", seq_len(g))
  K <- outer(seq_len(g), seq_len(g), function(i, j) 0.4^abs(i - j))
  dimnames(K) <- list(level, level)
  K
}

fixture_shared_x <- function(seed = 2026090501L, g = 14L, m = 4L) {
  set.seed(seed)
  K <- arc1b_s2r_K(g)
  level <- rownames(K)
  L <- t(chol(K))
  truth <- c(
    tau1 = 0.80, tau2 = 0.65, rho_K = 0.35,
    sigma1 = 0.30, sigma2 = 0.35, rho12 = -0.20
  )
  z1 <- stats::rnorm(g)
  z2 <- stats::rnorm(g)
  u1 <- truth[["tau1"]] * as.vector(L %*% z1)
  u2 <- truth[["tau2"]] * as.vector(
    L %*% (truth[["rho_K"]] * z1 + sqrt(1 - truth[["rho_K"]]^2) * z2)
  )
  names(u1) <- names(u2) <- level
  id <- factor(rep(level, each = m), levels = level)
  x <- stats::rnorm(length(id))
  e1 <- stats::rnorm(length(id))
  e2 <- truth[["rho12"]] * e1 + sqrt(1 - truth[["rho12"]]^2) * stats::rnorm(length(id))
  data <- data.frame(
    y1 = 0.30 + 0.50 * x + u1[as.character(id)] + truth[["sigma1"]] * e1,
    y2 = -0.20 - 0.25 * x + u2[as.character(id)] + truth[["sigma2"]] * e2,
    x = x, id = id
  )
  list(data = data, K = K, truth = truth)
}

if (sys.nframe() == 0L) {
  fx <- fixture_shared_x()
  out_dir <- dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())]))
  if (length(out_dir) != 1L || !nzchar(out_dir)) out_dir <- "."
  write.csv(fx$data, file.path(out_dir, "data.csv"), row.names = FALSE)
  K <- fx$K
  write.csv(
    data.frame(id = rownames(K), K, check.names = FALSE),
    file.path(out_dir, "K.csv"), row.names = FALSE
  )
  saveRDS(fx, file.path(out_dir, "fixture.rds"))
  cat("wrote data.csv, K.csv, fixture.rds to", out_dir, "\n")
}
