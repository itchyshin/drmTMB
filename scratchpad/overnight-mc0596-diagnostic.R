suppressMessages(pkgload::load_all(".", compile = FALSE, quiet = TRUE))
# mc-0596 fixture, verbatim from tools/run-135-trace-campaign.R:480-506, seed 1 of the campaign
dense_zoib_spatial_precision <- function(coords, labels) {
  d <- as.matrix(stats::dist(coords)); rng <- stats::median(d[d > 0])
  cov <- exp(-d / rng); diag(cov) <- diag(cov) + 1e-6
  dimnames(cov) <- list(labels, labels)
  list(Q = solve(cov))
}
run_one <- function(seed) {
  set.seed(seed)
  n <- 16L; labels <- paste0("site", seq_len(n))
  coords <- cbind(seq_len(n), (seq_len(n) %% 5L) / 3); rownames(coords) <- rev(labels)
  precision <- dense_zoib_spatial_precision(coords, labels)
  u <- as.numeric(t(chol(solve(precision$Q))) %*% stats::rnorm(n, sd = 0.45)); names(u) <- labels
  site <- rep(labels, each = 40L); x <- stats::rnorm(length(site))
  mu <- stats::plogis(-0.15 + 0.35 * x); sigma <- exp(-1 + u[site])
  zoi <- stats::plogis(-1.1); coi <- stats::plogis(0.1)
  boundary <- stats::rbinom(length(x), 1L, zoi)
  y <- stats::rbeta(length(x), mu / sigma^2, (1 - mu) / sigma^2)
  y[boundary == 1L] <- stats::rbinom(sum(boundary), 1L, coi)
  fit <- drmTMB::drmTMB(
    drmTMB::bf(y ~ x, sigma ~ spatial(1 | site, coords = coords), zoi ~ 1, coi ~ 1),
    family = drmTMB::zero_one_beta(), data = data.frame(y, x, site),
    control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 900L, iter.max = 900L)))
  obj <- fit$obj; par <- fit$opt$par
  r_def  <- stats::nlminb(par, obj$fn, obj$gr)                                    # helper's raw defaults
  r_budg <- stats::nlminb(par, obj$fn, obj$gr,
                          control = list(eval.max = 900L, iter.max = 900L))       # campaign budget
  cat(sprintf("seed %d | outer conv=%d pdHess=%s | re-opt DEFAULT conv=%d (%s) | re-opt BUDGET conv=%d (%s) | grad-max %.2e\n",
    seed, fit$opt$convergence, isTRUE(fit$sdr$pdHess),
    r_def$convergence, r_def$message, r_budg$convergence, r_budg$message,
    max(abs(obj$gr(par)))))
}
for (s in 1:3) try(run_one(s))
