#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
self_test <- "--self-test" %in% args
positional <- args[!args %in% "--self-test"]
out_dir <- if (length(positional)) positional[[1L]] else NA_character_
pilot_library <- Sys.getenv("PILOT_R_LIBRARY", "")
pilot_dependency_library <- Sys.getenv("PILOT_R_DEPENDENCY_LIBRARY", "")
pilot_libraries <- c(pilot_library, pilot_dependency_library)
pilot_libraries <- pilot_libraries[nzchar(pilot_libraries)]
if (length(pilot_libraries)) .libPaths(c(pilot_libraries, .libPaths()))

if (identical(Sys.getenv("DRMTMB_PILOT_DEVTOOLS"), "true")) {
  devtools::load_all(quiet = TRUE)
} else {
  suppressPackageStartupMessages(library(drmTMB))
}

pilot_master_seed <- 2026102301L
pilot_n_replicates <- 3L
pilot_n_tip <- 60L
pilot_n_each <- 100L
pilot_conditions <- expand.grid(
  n_tip = c(16L, 60L),
  n_each = c(12L, 100L),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
pilot_conditions$cell <- sprintf("tips-%02d_reps-%03d", pilot_conditions$n_tip,
                                  pilot_conditions$n_each)

pilot_generate_replicate <- function(seed) {
  set.seed(seed)
  tree <- ape::rcoal(pilot_n_tip)
  tree$tip.label <- paste0("sp", seq_len(pilot_n_tip))
  K <- drmTMB:::drm_phylo_tip_covariance(tree, correlation = TRUE)
  z <- as.numeric(scale(stats::rnorm(pilot_n_tip)))
  names(z) <- tree$tip.label
  alpha <- c(log(0.35), 0.45)
  tau <- exp(alpha[[1L]] + alpha[[2L]] * z)
  u <- as.vector(t(chol(K)) %*% stats::rnorm(pilot_n_tip))
  index <- rep(seq_len(pilot_n_tip), each = pilot_n_each)
  data <- data.frame(
    y = stats::rbinom(length(index), 1L,
                      stats::plogis(0.2 + tau[index] * u[index])),
    species = factor(tree$tip.label[index], levels = tree$tip.label),
    z = unname(z[index])
  )
  root <- setdiff(tree$edge[, 1L], tree$edge[, 2L])
  root_children <- tree$edge[tree$edge[, 1L] == root, 2L]
  root_clades <- lapply(root_children, function(node) {
    ape::extract.clade(tree, node)$tip.label
  })
  root_representatives <- vapply(root_clades, `[[`, character(1), 1L)
  subset16_labels <- c(
    root_representatives,
    sample(setdiff(tree$tip.label, root_representatives), 14L)
  )
  list(tree = tree, K = K, data = data, z = z, alpha = alpha,
       subset16_labels = subset16_labels)
}

pilot_condition_data <- function(replicate, n_tip, n_each) {
  labels <- if (n_tip == 16L) replicate$subset16_labels else
    replicate$tree$tip.label
  tree <- ape::keep.tip(replicate$tree, labels)
  K <- drmTMB:::drm_phylo_tip_covariance(tree, correlation = TRUE)
  expected <- replicate$K[rownames(K), rownames(K), drop = FALSE]
  delta <- max(abs(K - expected))
  if (!is.finite(delta) || delta > 1e-8) {
    stop("Pruned tree covariance differs from the matching DGP submatrix")
  }
  selected <- as.character(replicate$data$species) %in% labels
  data <- replicate$data[selected, , drop = FALSE]
  keep <- ave(seq_len(nrow(data)), data$species, FUN = seq_along) <= n_each
  data <- droplevels(data[keep, , drop = FALSE])
  list(data = data, tree = tree, covariance_delta = delta)
}

pilot_fit_one <- function(seed, condition) {
  started <- proc.time()[["elapsed"]]
  result <- data.frame(
    seed = as.integer(seed), cell = condition$cell,
    n_tip = condition$n_tip, n_each = condition$n_each,
    alpha0_true = log(0.35), alpha1_true = 0.45,
    alpha0_hat = NA_real_, alpha1_hat = NA_real_,
    ci_lower = NA_real_, ci_upper = NA_real_,
    interval_contains_truth = NA, profile_status = NA_character_,
    profile_boundary = NA, clamp_limited = NA,
    fit_convergence = NA_integer_, gradient_max = NA_real_,
    hessian_pd = NA, covariance_delta = NA_real_,
    elapsed_seconds = NA_real_, error = NA_character_,
    stringsAsFactors = FALSE
  )
  result <- tryCatch({
    generated <- pilot_generate_replicate(seed)
    subset <- pilot_condition_data(generated, condition$n_tip,
                                   condition$n_each)
    result$covariance_delta <- subset$covariance_delta
    tree <- subset$tree
    fit <- drmTMB::drmTMB(
      drmTMB::bf(
        y ~ phylo(1 | species, tree = tree),
        sd(species, level = "phylogenetic") ~ z
      ),
      family = stats::binomial(), data = subset$data,
      control = drmTMB::drm_control(se = FALSE)
    )
    estimates <- stats::coef(fit, "sd_phylo(species)")
    if (length(estimates) != 2L) stop("Expected SD intercept and slope")
    result$alpha0_hat <- unname(estimates[[1L]])
    result$alpha1_hat <- unname(estimates[[2L]])
    convergence <- fit$opt$convergence
    result$fit_convergence <- if (is.null(convergence)) NA_integer_ else
      as.integer(convergence)
    gradient <- fit$opt$gradient
    if (!is.null(gradient) && length(gradient)) {
      result$gradient_max <- max(abs(gradient), na.rm = TRUE)
    }
    result$hessian_pd <- if (!is.null(fit$sdr$pdHess)) {
      isTRUE(fit$sdr$pdHess)
    } else NA
    targets <- drmTMB::profile_targets(fit)
    target <- targets$parm[
      grepl("sd_phylo\\(species\\)", targets$parm) &
        endsWith(targets$parm, ":z")
    ]
    if (length(target) != 1L) stop("Expected one phylogenetic SD slope target")
    interval <- stats::confint(
      fit, parm = target, method = "profile", profile_precision = "fast"
    )
    lower_name <- if ("lower" %in% names(interval)) "lower" else "conf.low"
    upper_name <- if ("upper" %in% names(interval)) "upper" else "conf.high"
    result$ci_lower <- if (lower_name %in% names(interval)) {
      as.numeric(interval[[lower_name]][[1L]])
    } else NA_real_
    result$ci_upper <- if (upper_name %in% names(interval)) {
      as.numeric(interval[[upper_name]][[1L]])
    } else NA_real_
    result$profile_status <- if ("conf.status" %in% names(interval)) {
      as.character(interval$conf.status[[1L]])
    } else NA_character_
    result$profile_boundary <- if ("profile.boundary" %in% names(interval)) {
      as.logical(interval$profile.boundary[[1L]])
    } else NA
    result$clamp_limited <- identical(result$profile_status, "clamp_limited")
    result$interval_contains_truth <- is.finite(result$ci_lower) &&
      is.finite(result$ci_upper) &&
      result$ci_lower <= result$alpha1_true &&
      result$alpha1_true <= result$ci_upper
    result
  }, error = function(e) {
    result$error <- conditionMessage(e)
    result
  })
  result$elapsed_seconds <- proc.time()[["elapsed"]] - started
  result
}

if (self_test) {
  example <- pilot_generate_replicate(2026102301L)
  small <- pilot_condition_data(example, 16L, 12L)
  stopifnot(
    nrow(small$data) == 16L * 12L,
    nlevels(small$data$species) == 16L,
    small$covariance_delta < 1e-8,
    isTRUE(all.equal(mean(example$z), 0, tolerance = 1e-12)),
    isTRUE(all.equal(stats::sd(example$z), 1, tolerance = 1e-12)),
    nrow(pilot_conditions) == 4L,
    pilot_n_replicates == 3L
  )
  cat("Bernoulli phylogenetic calibration pilot DGP self-test passed.\n")
  quit(save = "no", status = 0L)
}

if (is.na(out_dir) || !nzchar(out_dir)) {
  stop("Usage: bernoulli-phylo-calibration-pilot.R [--self-test] OUTPUT_DIR")
}
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
if (length(list.files(out_dir, all.files = TRUE, no.. = TRUE))) {
  stop("Output directory must be empty so prior attempts are not overwritten")
}
set.seed(pilot_master_seed)
seeds <- sample.int(.Machine$integer.max, pilot_n_replicates)
manifest <- list(
  design = "bernoulli-phylogenetic-sd-timing-smoke-v1",
  master_seed = pilot_master_seed,
  replicate_seeds = seeds,
  conditions = pilot_conditions,
  workers = as.integer(Sys.getenv("PILOT_WORKERS", "4")),
  calibration_claim = FALSE,
  session = utils::sessionInfo()
)
saveRDS(manifest, file.path(out_dir, "manifest.rds"))
writeLines(capture.output(utils::sessionInfo()),
           file.path(out_dir, "sessionInfo.txt"))
jobs <- expand.grid(
  replicate = seq_along(seeds), condition = seq_len(nrow(pilot_conditions))
)
run_job <- function(i) {
  j <- jobs[i, ]
  pilot_fit_one(seeds[[j$replicate]], pilot_conditions[j$condition, ])
}
workers <- max(1L, min(4L, manifest$workers))
if (.Platform$OS.type == "unix" && workers > 1L) {
  attempts <- parallel::mclapply(seq_len(nrow(jobs)), run_job,
                                 mc.cores = workers, mc.preschedule = FALSE)
} else {
  attempts <- lapply(seq_len(nrow(jobs)), run_job)
}
attempts <- do.call(rbind, attempts)
saveRDS(attempts, file.path(out_dir, "attempts.rds"))
utils::write.csv(attempts, file.path(out_dir, "attempts.csv"), row.names = FALSE)
summary <- do.call(rbind, lapply(split(attempts, attempts$cell), function(x) {
  data.frame(
    cell = x$cell[[1L]], n_attempted = nrow(x),
    n_completed = sum(is.na(x$error)),
    n_profile_available = sum(is.finite(x$ci_lower) & is.finite(x$ci_upper)),
    n_truth_inside = sum(x$interval_contains_truth %in% TRUE),
    median_elapsed_seconds = stats::median(x$elapsed_seconds, na.rm = TRUE),
    max_covariance_delta = max(x$covariance_delta, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
}))
utils::write.csv(summary, file.path(out_dir, "pilot-summary.csv"),
                  row.names = FALSE)
cat("Pilot complete; calibration_claim=false. Attempts retained:",
    nrow(attempts), "\n")
print(summary, row.names = FALSE)
