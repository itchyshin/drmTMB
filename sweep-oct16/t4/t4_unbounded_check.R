## sweep-oct16 / t4: is the Gaussian location-scale likelihood (mu = b0 + b1 x, log sigma = g0 + g1 x) bounded?
## Analytic criterion (derivation in RECEIPT_t4.md): a likelihood spike needs sigma -> 0 at an observation
## the mean fits exactly; with log sigma linear in x this is only possible at an extreme x (x_min or x_max).
## Put the spike at extreme point k, let the mean line also pass exactly through point j, and set
## log sigma(x) = -c + s * d(x), d = |x - x_k|. For large c the binding constraint is the nearest
## non-interpolated point (distance D), so s ~ c / D and the log-likelihood grows like slope * c with
##   slope = 1 + (1 - d_j / D) + sum_{i not in {k, j}} (1 - d_i / D)
## (each non-interpolated point pays -log sigma_i = c (1 - d_i / D) <= 0; its residual term stays bounded).
## The likelihood is unbounded (MLE does not exist) iff max over k in {argmin x, argmax x} and j of slope > 0.
## A numerical ray check confirms each verdict: logLik along the constructed ray at c = 10, 20, 40.
args <- commandArgs(trailingOnly = TRUE)
ddir <- if (length(args) >= 1) args[1] else "sweep-oct16/t4/data"
out  <- if (length(args) >= 2) args[2] else "sweep-oct16/t4/results/gauss_unbounded.csv"
idx <- read.csv(file.path(ddir, "index.csv"), stringsAsFactors = FALSE)
idx <- idx[startsWith(idx$cell, "gauss_"), ]
ll_ray <- function(d, k, j, D, cval) {
  x <- d$x; y <- d$y; dk <- abs(x - x[k])
  b1 <- (y[j] - y[k]) / (x[j] - x[k]); b0 <- y[k] - b1 * x[k]
  ## offset keeps the non-interpolated residual terms bounded: s = (c + log(max|r|) + 1) / D
  r <- y - b0 - b1 * x; s <- (cval + log(max(abs(r))) + 1) / D
  ls <- -cval + s * dk
  sum(dnorm(y, b0 + b1 * x, exp(ls), log = TRUE))
}
res <- list()
for (i in seq_len(nrow(idx))) {
  d <- read.csv(file.path(ddir, idx$file[i])); x <- d$x; n <- length(x)
  best <- list(slope = -Inf)
  for (k in unique(c(which.min(x), which.max(x)))) {
    dk <- abs(x - x[k])
    for (j in setdiff(seq_len(n), k)) {
      others <- setdiff(seq_len(n), c(k, j)); D <- min(dk[others])
      slope <- 1 + (1 - dk[j] / D) + sum(1 - dk[others] / D)
      if (slope > best$slope) best <- list(slope = slope, k = k, j = j, D = D)
    }
  }
  ray <- sapply(c(10, 20, 40), function(cv) ll_ray(d, best$k, best$j, best$D, cv))
  res[[i]] <- data.frame(file = idx$file[i], spike_k = best$k, partner_j = best$j, slope = best$slope,
                         ray_ll_c10 = ray[1], ray_ll_c20 = ray[2], ray_ll_c40 = ray[3],
                         unbounded = best$slope > 0,
                         ray_agrees = (best$slope > 0) == (ray[3] - ray[2] > 1 && ray[2] - ray[1] > 1))
}
res <- do.call(rbind, res)
write.csv(res, out, row.names = FALSE)
print(table(cell = sub("_r[0-9]+\\.csv", "", res$file), unbounded = res$unbounded))
cat("ray check agrees with the analytic verdict on", sum(res$ray_agrees), "of", nrow(res), "datasets\n")
print(res[res$unbounded, c("file", "slope", "ray_ll_c10", "ray_ll_c20", "ray_ll_c40")], row.names = FALSE)
