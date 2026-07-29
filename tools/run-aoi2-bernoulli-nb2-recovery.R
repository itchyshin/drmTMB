#!/usr/bin/env Rscript

# AOI-2 point-recovery runner.  It runs one immutable local/cluster shard;
# scheduling is intentionally outside this file and remains owner-gated.

args <- commandArgs(trailingOnly = TRUE)
arg_value <- function(name) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit) != 1L) {
    stop(sprintf("Supply exactly one --%s=VALUE.", name), call. = FALSE)
  }
  sub(paste0("^--", name, "="), "", hit)
}

out_dir <- arg_value("out-dir")
formula_id <- arg_value("formula-id")
n <- suppressWarnings(as.integer(arg_value("n")))
replicate_start <- suppressWarnings(as.integer(arg_value("replicate-start")))
replicate_end <- suppressWarnings(as.integer(arg_value("replicate-end")))
if (!is.finite(n) || n < 20L || !is.finite(replicate_start) ||
    !is.finite(replicate_end) || replicate_start < 1L || replicate_end < replicate_start) {
  stop("`n` and the inclusive replicate range must be valid positive integers.", call. = FALSE)
}
if (file.exists(out_dir)) {
  stop("Refusing to overwrite an immutable AOI-2 result directory.", call. = FALSE)
}
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

devtools::load_all(quiet = TRUE)

specifications <- list(
  additive = list(~x1 + x2, c("(Intercept)" = -0.15, x1 = 0.40, x2 = -0.25)),
  mixed = list(~x1 + habitat, c("(Intercept)" = -0.10, x1 = 0.35, habitatforest = 0.20)),
  factor_interaction = list(~x1 + habitat + x1:habitat, c("(Intercept)" = -0.10, x1 = 0.30, habitatforest = 0.15, "x1:habitatforest" = 0.20)),
  numeric_interaction = list(~x1 + x2 + x1:x2, c("(Intercept)" = -0.10, x1 = 0.30, x2 = -0.20, "x1:x2" = 0.20)),
  transformation = list(~x1 + I(x2^2), c("(Intercept)" = -0.10, x1 = 0.30, "I(x2^2)" = 0.20))
)
if (!formula_id %in% names(specifications)) {
  stop("Unknown `formula-id`.", call. = FALSE)
}
specification <- specifications[[formula_id]]
association_formula <- specification[[1L]]
truth <- specification[[2L]]
estimate_columns <- paste0("estimate_", make.names(names(truth)))
truth_columns <- paste0("truth_", make.names(names(truth)))
eta_columns <- paste0("eta_newdata_", seq_len(5L))
eta_truth_columns <- paste0("eta_truth_newdata_", seq_len(5L))
source_sha <- system("git rev-parse HEAD", intern = TRUE)

make_data <- function(seed) {
  set.seed(seed)
  habitat <- factor(rep(c("field", "forest"), length.out = n), levels = c("field", "forest"))
  data <- data.frame(
    x1 = stats::rnorm(n),
    x2 = stats::rnorm(n),
    habitat = sample(habitat, size = n, replace = FALSE)
  )
  association_matrix <- stats::model.matrix(association_formula, data)
  if (!identical(colnames(association_matrix), names(truth)) ||
      qr(association_matrix)$rank != ncol(association_matrix)) {
    stop("dgp_design_error: frozen association design is aliased or misencoded.", call. = FALSE)
  }
  eta <- 0.999999 * tanh(as.vector(association_matrix %*% truth))
  z_binary <- stats::rnorm(n)
  z_count <- eta * z_binary + sqrt(1 - eta^2) * stats::rnorm(n)
  probability <- stats::plogis(-0.2 + 0.25 * data$x1 - 0.10 * data$x2)
  data$binary <- as.integer(z_binary > stats::qnorm(probability, lower.tail = FALSE))
  data$count <- drmTMB:::drm_pair_nbinom2_quantile_from_normal(
    z_count, exp(0.5 + 0.15 * data$x1 - 0.10 * data$x2), rep(0.6, n)
  )
  list(data = data, eta = eta, design = association_matrix)
}

run_one <- function(replicate) {
  seed <- 2026072900L + match(formula_id, names(specifications)) * 100000L +
    n * 100L + replicate
  started <- Sys.time()
  base <- c(
    list(
      formula_id = formula_id, n = n, replicate = replicate, seed = seed,
      source_sha = source_sha, fingerprint = NA_character_, stage = "dgp",
      status = "unavailable", message = "", pdHess_binary = NA,
      pdHess_count = NA
    ),
    as.list(stats::setNames(rep(NA_real_, length(estimate_columns)), estimate_columns)),
    as.list(stats::setNames(unname(truth), truth_columns)),
    as.list(stats::setNames(rep(NA_real_, length(eta_columns)), eta_columns)),
    as.list(stats::setNames(rep(NA_real_, length(eta_truth_columns)), eta_truth_columns))
  )
  tryCatch({
    generated <- make_data(seed)
    fingerprint <- paste(colnames(generated$design), collapse = "|")
    binary_fit <- drmTMB(bf(mu = binary ~x1 + x2), binomial(), generated$data)
    count_fit <- drmTMB(bf(mu = count ~x1 + x2, sigma = ~1), nbinom2(), generated$data)
    fit <- associate_pairs(binary_fit, count_fit, kernel = latent_normal(), association = association_formula)
    prediction_data <- generated$data[seq_len(5L), c("x1", "x2", "habitat"), drop = FALSE]
    prediction <- predict(fit, newdata = prediction_data, type = "link")
    estimates <- fit$association_coefficients
    if (!identical(names(estimates), names(truth)) || length(prediction) != 5L) {
      stop("association_output_error: coefficient order or prediction length changed.", call. = FALSE)
    }
    base$fingerprint <- fingerprint
    base$stage <- "association"
    base$status <- fit$status
    base$pdHess_binary <- binary_fit$sdr$pdHess
    base$pdHess_count <- count_fit$sdr$pdHess
    base[estimate_columns] <- as.list(unname(estimates))
    base[eta_columns] <- as.list(unname(prediction))
    base[eta_truth_columns] <- as.list(unname(generated$design[seq_len(5L), , drop = FALSE] %*% truth))
    base$elapsed_seconds <- as.numeric(difftime(Sys.time(), started, units = "secs"))
    as.data.frame(base, check.names = FALSE, stringsAsFactors = FALSE)
  }, error = function(e) {
    base$message <- conditionMessage(e)
    base$elapsed_seconds <- as.numeric(difftime(Sys.time(), started, units = "secs"))
    as.data.frame(base, check.names = FALSE, stringsAsFactors = FALSE)
  })
}

results <- lapply(seq.int(replicate_start, replicate_end), run_one)
attempts <- do.call(rbind, results)
utils::write.csv(attempts, file.path(out_dir, "raw-attempts.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
writeLines(system("git rev-parse HEAD", intern = TRUE), file.path(out_dir, "git-sha.txt"))
