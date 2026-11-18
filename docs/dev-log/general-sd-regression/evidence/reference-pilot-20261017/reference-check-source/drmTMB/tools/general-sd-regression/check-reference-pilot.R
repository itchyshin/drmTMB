# Supplement the original sensitivity run without refitting or overwriting it.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Supply a completed reference-pilot directory")
out <- normalizePath(args[[1L]], mustWork = TRUE)
path <- file.path(out, "cluster-reference-checks.csv")
if (file.exists(path)) stop("Refusing to overwrite reference diagnostics")
source("tools/general-sd-regression/scalar-binomial-reference.R")
source("tests/testthat/helper-binomial-sd-regression.R")
native <- readRDS(file.path(out, "native-point.rds"))
required <- c("optimizer_convergence", "hessian_positive_definite",
              "fixed_gradient", "logsigma_clamp_active")
health <- native$health
stopifnot(all(required %in% health$check),
          all(health$status[match(required, health$check)] == "ok"))
parameters <- read.csv(file.path(out, "parameter-comparison.csv"))
dat <- binomial_sd_fixture(seed = 1120801948L)$data
groups <- split(seq_len(nrow(dat)), dat$id)
points <- list(native_mle = parameters$laplace, adaptive_mle = parameters$adaptive,
               generating_truth = c(-0.3, 0.6, log(0.8), 0.5))
rows <- do.call(rbind, lapply(names(points), function(point) {
  par <- points[[point]]
  do.call(rbind, lapply(seq_along(groups), function(g) {
    i <- groups[[g]]
    sd <- exp(par[[3L]] + par[[4L]]*dat$w[i[[1L]]])
    eta <- par[[1L]] + par[[2L]]*dat$x[i]
    a <- scalar_binomial_log_marginal(dat$y[i], rep(1, length(i)), eta, sd)
    b <- scalar_binomial_log_marginal(dat$y[i], rep(1, length(i)), eta, sd,
                                      rel.tol = 1e-10)
    data.frame(point = point, group = g, log_marginal = a$log_marginal,
                tighter_log_marginal = b$log_marginal,
                absolute_difference = abs(a$log_marginal-b$log_marginal),
                relative_error = a$relative_error,
                tighter_relative_error = b$relative_error,
                subdivisions = a$subdivisions,
                tighter_subdivisions = b$subdivisions)
  }))
}))
write.csv(rows, path, row.names = FALSE)
files <- c("tools/general-sd-regression/check-reference-pilot.R",
           "tools/general-sd-regression/scalar-binomial-reference.R",
           "tests/testthat/helper-binomial-sd-regression.R", path,
           file.path(out, "native-point.rds"),
           file.path(out, "parameter-comparison.csv"))
write.csv(data.frame(file = files, sha256 = vapply(files, function(p) {
  digest::digest(file = p, algo = "sha256")
}, character(1))), file.path(out, "cluster-check-source-hashes.csv"), row.names = FALSE)
stopifnot(all(is.finite(as.matrix(rows[, 3:7]))),
          max(rows$absolute_difference) < 1e-7,
          max(rows$relative_error) <= 1e-8,
          max(rows$tighter_relative_error) <= 1e-10)
print(aggregate(rows[, 5:9], list(point = rows$point), max))
cat("CLUSTER_REFERENCE_CHECKS_PASS\n")
