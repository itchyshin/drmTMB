#!/usr/bin/env Rscript
if (!requireNamespace("ape", quietly = TRUE) || !requireNamespace("pkgload", quietly = TRUE) || !requireNamespace("statmod", quietly = TRUE)) stop("needs ape/pkgload/statmod")
mode <- commandArgs(trailingOnly = TRUE)
preflight <- identical(mode, "--preflight")
convergence <- identical(mode, "--convergence")
out <- "docs/dev-log/evidence/ou-v1-r32"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
pkgload::load_all(".", compile = TRUE, quiet = TRUE)

set.seed(2026091401)
tree <- ape::rcoal(3)
tree$tip.label <- paste0("sp", 1:3)
tree$edge.length <- tree$edge.length / max(ape::node.depth.edgelength(tree)[1:3])
d <- ape::cophenetic.phylo(tree)
u <- drop(t(chol(.45^2 * exp(-.7 * d))) %*% rnorm(3))
v <- drop(t(chol(.25^2 * exp(-1.3 * d))) %*% rnorm(3))
species <- rep(tree$tip.label, each = 3)
ii <- match(species, tree$tip.label)
dat <- data.frame(y = u[ii] + rnorm(9, sd = exp(-1 + v[ii])), species = species)

fit_point <- function(a, s) {
  f <- bf(y ~ phylo(1 | species, tree = tree, model = "ou"), sigma ~ phylo(1 | species, tree = tree, model = "ou"))
  ctl <- drmTMB:::drm_parse_control(drm_control())
  z <- drmTMB:::drm_build_gaussian_ls_spec(f, dat, env = environment(), weights = NULL, control = ctl, impute = NULL, missing = drmTMB:::drm_parse_missing_control(miss_control()))
  z$map$log_decay_phylo <- factor(c(NA, NA)); z$start$log_decay_phylo <- log(a)
  z$map$log_sd_phylo <- factor(c(NA, NA)); z$start$log_sd_phylo <- log(s)
  drmTMB:::drm_fit_spec(z, f, gaussian(), ctl, REML = FALSE, penalty = NULL, estimator = "ml")
}

quad <- function(mu, ls, s, a, n) {
  q <- statmod::gauss.quad.prob(n, "normal")
  g <- as.matrix(expand.grid(rep(list(q$nodes), 6)))
  lw <- rowSums(log(as.matrix(expand.grid(rep(list(q$weights), 6)))))
  x <- g[, 1:3] %*% t(chol(s[[1]]^2 * exp(-a[[1]] * d)))
  z <- g[, 4:6] %*% t(chol(s[[2]]^2 * exp(-a[[2]] * d)))
  for (j in seq_len(nrow(dat))) lw <- lw + dnorm(dat$y[j], mu + x[, ii[j]], exp(ls + z[, ii[j]]), log = TRUE)
  m <- max(lw); -(m + log(sum(exp(lw - m))))
}

rate <- list(interior = c(.7, 1.3), ridge = c(8, 8))
amp <- list(interior = c(.45, .25), ridge = c(.19, .057))
one <- function(rate_id, amp_id, anchors = FALSE) {
  fit <- suppressWarnings(fit_point(rate[[rate_id]], amp[[amp_id]]))
  mu <- unname(fit$par$mu[[1]]); ls <- unname(fit$par$sigma[[1]])
  q5 <- quad(mu, ls, amp[[amp_id]], rate[[rate_id]], 5)
  q7 <- quad(mu, ls, amp[[amp_id]], rate[[rate_id]], 7)
  q9 <- quad(mu, ls, amp[[amp_id]], rate[[rate_id]], 9)
  data.frame(rate_id = rate_id, amplitude_id = amp_id, alpha_mu = rate[[rate_id]][1], alpha_sigma = rate[[rate_id]][2], sd_mu = amp[[amp_id]][1], sd_sigma = amp[[amp_id]][2], mu = mu, logsigma = ls, laplace = fit$opt$objective, quadrature5 = q5, quadrature7 = q7, quadrature9 = q9, laplace_minus_q9 = fit$opt$objective - q9, refinement_7_9 = abs(q9 - q7))
}

if (preflight) {
  t0 <- proc.time()[["elapsed"]]; x <- one("interior", "interior", TRUE); elapsed <- proc.time()[["elapsed"]] - t0
  utils::write.csv(data.frame(cell = "interior-interior", elapsed_seconds = elapsed, projected_grid_seconds = elapsed * 4, within_three_hours = elapsed * 4 < 10800), file.path(out, "preflight.csv"), row.names = FALSE)
  cat("OU_V1_R32_PREFLIGHT_PASS\n")
} else if (convergence) {
  fit <- suppressWarnings(fit_point(rate[["ridge"]], amp[["interior"]]))
  mu <- unname(fit$par$mu[[1]]); ls <- unname(fit$par$sigma[[1]])
  q9 <- quad(mu, ls, amp[["interior"]], rate[["ridge"]], 9)
  q11 <- quad(mu, ls, amp[["interior"]], rate[["ridge"]], 11)
  q13 <- quad(mu, ls, amp[["interior"]], rate[["ridge"]], 13)
  utils::write.csv(data.frame(rate_id = "ridge", amplitude_id = "interior", quadrature9 = q9, quadrature11 = q11, quadrature13 = q13, refinement_9_11 = abs(q11 - q9), refinement_11_13 = abs(q13 - q11)), file.path(out, "convergence.csv"), row.names = FALSE)
  cat("OU_V1_R32_CONVERGENCE_PASS\n")
} else {
  ans <- do.call(rbind, unlist(lapply(names(rate), function(r) lapply(names(amp), function(a) one(r, a, TRUE))), recursive = FALSE))
  ans$laplace_rank <- rank(ans$laplace, ties.method = "min")
  ans$quadrature_rank <- rank(ans$quadrature9, ties.method = "min")
  utils::write.csv(ans, file.path(out, "comparison.csv"), row.names = FALSE)
  ape::write.tree(tree, file.path(out, "tree.nwk")); utils::write.csv(dat, file.path(out, "data.csv"), row.names = FALSE)
  cat("OU_V1_R32_RUN_PASS\n")
}
