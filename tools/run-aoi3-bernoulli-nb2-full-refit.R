#!/usr/bin/env Rscript

# Private AOI-3 full-refit runner. It is not a package API or a public
# uncertainty method. Each inner draw refits both margins and association.

args <- commandArgs(trailingOnly = TRUE)
arg_value <- function(name, default = NULL) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (!length(hit) && !is.null(default)) return(default)
  if (length(hit) != 1L) stop("Supply exactly one --", name, "=VALUE.", call. = FALSE)
  sub(paste0("^--", name, "="), "", hit)
}
arg_optional <- function(name) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (!length(hit)) return(NULL)
  if (length(hit) != 1L) stop("Supply at most one --", name, "=VALUE.", call. = FALSE)
  sub(paste0("^--", name, "="), "", hit)
}

out_dir <- arg_value("out-dir")
mode <- arg_value("mode")
seed_manifest_path <- arg_optional("seed-manifest")
formula_id <- arg_value("formula-id")
n <- suppressWarnings(as.integer(arg_value("n")))
strength <- arg_value("strength", "interior")
outer_start <- suppressWarnings(as.integer(arg_value("outer-start")))
outer_end <- suppressWarnings(as.integer(arg_value("outer-end")))
inner_n <- suppressWarnings(as.integer(arg_value("inner-n")))
if (!mode %in% c("smoke", "campaign", "diagnostic") || !is.finite(n) || n < 20L ||
    !strength %in% c("interior", "near_boundary") || !is.finite(outer_start) ||
    !is.finite(outer_end) || outer_start < 1L || outer_end < outer_start ||
    !is.finite(inner_n) || inner_n < 1L) {
  stop("Invalid AOI-3 runner arguments.", call. = FALSE)
}
seed_manifest <- NULL
if (identical(mode, "diagnostic")) {
  if (is.null(seed_manifest_path) || !file.exists(seed_manifest_path)) {
    stop("Diagnostic mode requires an existing --seed-manifest=FILE.", call. = FALSE)
  }
  seed_manifest <- utils::read.csv(seed_manifest_path, stringsAsFactors = FALSE)
  required_manifest <- c("attempt_type", "formula_id", "n", "outer_id", "inner_id", "seed", "source_sha")
  if (!all(required_manifest %in% names(seed_manifest))) stop("Invalid AOI-3R seed manifest schema.", call. = FALSE)
  seed_manifest <- seed_manifest[seed_manifest$formula_id == formula_id & seed_manifest$n == n, , drop = FALSE]
  if (!nrow(seed_manifest) || anyDuplicated(seed_manifest$seed)) stop("AOI-3R seed manifest is empty or duplicates a seed.", call. = FALSE)
}
if (dir.exists(out_dir) || file.exists(out_dir)) stop("Refusing to overwrite immutable AOI-3 result directory.", call. = FALSE)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
if (requireNamespace("devtools", quietly = TRUE)) devtools::load_all(quiet = TRUE) else library(drmTMB)

specifications <- list(
  additive = list(~ x1 + x2, c("(Intercept)" = -0.15, x1 = 0.40, x2 = -0.25)),
  mixed = list(~ x1 + habitat, c("(Intercept)" = -0.10, x1 = 0.35, habitatforest = 0.20)),
  factor_interaction = list(~ x1 + habitat + x1:habitat, c("(Intercept)" = -0.10, x1 = 0.30, habitatforest = 0.15, "x1:habitatforest" = 0.20)),
  numeric_interaction = list(~ x1 + x2 + x1:x2, c("(Intercept)" = -0.10, x1 = 0.30, x2 = -0.20, "x1:x2" = 0.20)),
  transformation = list(~ x1 + I(x2^2), c("(Intercept)" = -0.10, x1 = 0.30, "I(x2^2)" = 0.20))
)
if (!formula_id %in% names(specifications)) stop("Unknown --formula-id.", call. = FALSE)
association_formula <- specifications[[formula_id]][[1L]]
truth <- specifications[[formula_id]][[2L]]
if (identical(strength, "near_boundary")) truth[["(Intercept)"]] <- 2.0
source_sha <- Sys.getenv("AOI3_SOURCE_SHA", unset = system("git rev-parse HEAD", intern = TRUE))
if (length(source_sha) != 1L || !grepl("^[0-9a-f]{40}$", source_sha)) stop("AOI-3 requires a 40-character source SHA.", call. = FALSE)

fixed_newdata <- data.frame(
  x1 = c(-1, -0.5, 0, 0.5, 1), x2 = c(-0.7, -0.2, 0, 0.3, 0.8),
  habitat = factor(c("field", "forest", "field", "forest", "field"), levels = c("field", "forest"))
)
as_row <- function(x) as.data.frame(x, check.names = FALSE, stringsAsFactors = FALSE)
err_text <- function(e) paste(conditionMessage(e), collapse = " ")
add_payload <- function(row, fitted, sandwich = NULL) {
  payload <- drmTMB:::drm_pair_aoi2_diagnostic_payload(fitted$association)
  row[names(payload)] <- payload
  row$diagnostic_margin_binary_pdHess <- isTRUE(fitted$binary$sdr$pdHess)
  row$diagnostic_margin_count_pdHess <- isTRUE(fitted$count$sdr$pdHess)
  row$diagnostic_design_fingerprint <- fitted$association$association_design$fingerprint
  row$diagnostic_sandwich_status <- if (is.null(sandwich)) "not_attempted" else sandwich$status
  row$diagnostic_sandwich_reason <- if (!is.null(sandwich) && identical(sandwich$status, "unavailable")) sandwich$reason else NA_character_
  if (!is.null(sandwich) && !is.null(sandwich$derivative_diagnostics)) {
    diagnostics <- sandwich$derivative_diagnostics
    row$diagnostic_derivative_rows <- length(diagnostics)
    row$diagnostic_derivative_max_step_difference <- max(vapply(diagnostics, `[[`, numeric(1L), "max_step_difference"))
    row$diagnostic_derivative_max_scale <- max(vapply(diagnostics, `[[`, numeric(1L), "scale"))
  } else {
    row$diagnostic_derivative_rows <- NA_integer_
    row$diagnostic_derivative_max_step_difference <- NA_real_
    row$diagnostic_derivative_max_scale <- NA_real_
  }
  row
}
has_diagnostic_payload <- function(row) {
  required <- c("diagnostic_version", "diagnostic_status", "diagnostic_sandwich_status")
  all(required %in% names(row)) && all(!is.na(unlist(row[required], use.names = FALSE)))
}
inherit_outer_payload <- function(row, outer) {
  # An ineligible inner attempt must retain the diagnostic state that made it
  # ineligible.  Do not invent a payload when the outer attempt failed first.
  if (!has_diagnostic_payload(outer)) return(row)
  fields <- grep("^diagnostic_", names(outer), value = TRUE)
  row[fields] <- outer[fields]
  row$diagnostic_payload_origin <- "outer"
  reason <- c(
    paste0("outer_status=", outer$outer_status),
    paste0("outer_sandwich_status=", outer$sandwich_status)
  )
  if (!is.null(outer$sandwich_reason) && !is.na(outer$sandwich_reason) && nzchar(outer$sandwich_reason)) {
    reason <- c(reason, paste0("outer_sandwich_reason=", outer$sandwich_reason))
  }
  if (!is.null(outer$outer_message) && !is.na(outer$outer_message) && nzchar(outer$outer_message)) {
    reason <- c(reason, paste0("outer_message=", outer$outer_message))
  }
  row$diagnostic_eligibility_reason <- paste(reason, collapse = ";")
  row
}
manifest_seed <- function(attempt_type, outer_id, inner_id = NA_integer_) {
  if (is.null(seed_manifest)) return(NULL)
  hit <- seed_manifest[
    seed_manifest$attempt_type == attempt_type & seed_manifest$outer_id == outer_id &
      (if (is.na(inner_id)) is.na(seed_manifest$inner_id) else seed_manifest$inner_id == inner_id),
    , drop = FALSE
  ]
  if (nrow(hit) != 1L) stop("AOI-3R seed manifest does not define exactly one requested attempt.", call. = FALSE)
  as.integer(hit$seed[[1L]])
}

make_outer <- function(seed) {
  set.seed(seed)
  habitat <- factor(rep(c("field", "forest"), length.out = n), levels = c("field", "forest"))
  dat <- data.frame(x1 = stats::rnorm(n), x2 = stats::rnorm(n), habitat = sample(habitat, n, replace = FALSE))
  x_a <- stats::model.matrix(association_formula, dat)
  if (!identical(colnames(x_a), names(truth)) || qr(x_a)$rank != ncol(x_a)) stop("dgp_design_error", call. = FALSE)
  eta <- 0.999999 * tanh(as.vector(x_a %*% truth))
  z_b <- stats::rnorm(n)
  z_n <- eta * z_b + sqrt(1 - eta^2) * stats::rnorm(n)
  p <- stats::plogis(-0.2 + 0.25 * dat$x1 - 0.10 * dat$x2)
  dat$binary <- as.integer(z_b > stats::qnorm(p, lower.tail = FALSE))
  dat$count <- drmTMB:::drm_pair_nbinom2_quantile_from_normal(z_n, exp(0.5 + 0.15 * dat$x1 - 0.10 * dat$x2), rep(0.6, n))
  dat
}

fit_complete <- function(dat) {
  binary <- drmTMB(bf(mu = binary ~ x1 + x2), binomial(), dat)
  count <- drmTMB(bf(mu = count ~ x1 + x2, sigma = ~ 1), nbinom2(), dat)
  association <- associate_pairs(binary, count, kernel = latent_normal(), association = association_formula)
  list(binary = binary, count = count, association = association)
}

simulate_inner <- function(fitted, seed) {
  set.seed(seed)
  p <- stats::predict(fitted$binary, dpar = "mu", type = "response")
  mu <- stats::predict(fitted$count, dpar = "mu", type = "response")
  sigma <- stats::predict(fitted$count, dpar = "sigma", type = "response")
  a <- as.vector(fitted$association$association_design$matrix %*% fitted$association$association_coefficients)
  eta <- 0.999999 * tanh(a)
  z_b <- stats::rnorm(nrow(fitted$binary$data))
  z_n <- eta * z_b + sqrt(1 - eta^2) * stats::rnorm(nrow(fitted$binary$data))
  dat <- fitted$binary$data
  dat$binary <- as.integer(z_b > stats::qnorm(p, lower.tail = FALSE))
  dat$count <- drmTMB:::drm_pair_nbinom2_quantile_from_normal(z_n, mu, sigma)
  dat
}

alpha_values <- function(fitted) {
  alpha <- fitted$association$association_coefficients
  if (!identical(names(alpha), names(truth))) stop("coefficient_order_mismatch", call. = FALSE)
  alpha
}

outer_rows <- list()
inner_rows <- list()
covariance_rows <- list()
outer_index <- 0L
inner_index <- 0L
covariance_index <- 0L
for (outer_id in seq.int(outer_start, outer_end)) {
  outer_seed <- manifest_seed("outer", outer_id)
  if (is.null(outer_seed)) outer_seed <- 2026073100L + match(formula_id, names(specifications)) * 100000L + n * 100L + outer_id + if (strength == "near_boundary") 50000000L else 0L
  started <- Sys.time()
  base <- c(
    list(mode = mode, formula_id = formula_id, n = n, strength = strength, outer_id = outer_id, outer_seed = outer_seed, source_sha = source_sha, outer_status = "unavailable", outer_message = "", sandwich_status = "not_attempted", sandwich_reason = "", elapsed_seconds = NA_real_),
    as.list(stats::setNames(rep(NA_real_, length(truth)), paste0("truth_", make.names(names(truth))))),
    as.list(stats::setNames(rep(NA_real_, length(truth)), paste0("estimate_", make.names(names(truth))))),
    as.list(stats::setNames(rep(NA_real_, length(truth)), paste0("sandwich_se_", make.names(names(truth))))),
    as.list(stats::setNames(rep(NA_real_, 5L), paste0("eta_truth_", seq_len(5L)))),
    as.list(stats::setNames(rep(NA_real_, 5L), paste0("eta_estimate_", seq_len(5L)))),
    as.list(stats::setNames(rep(NA_real_, 5L), paste0("eta_delta_se_", seq_len(5L))))
  )
  fitted <- NULL
  tryCatch({
    fitted <- fit_complete(make_outer(outer_seed))
    alpha <- alpha_values(fitted)
    sandwich <- drmTMB:::drm_pair_general_eta_sandwich(fitted$binary, fitted$count, fitted$association)
    base <- add_payload(base, fitted, sandwich)
    base$diagnostic_payload_origin <- "outer"
    base$diagnostic_eligibility_reason <- NA_character_
    base$outer_status <- fitted$association$status
    base$sandwich_status <- sandwich$status
    if (identical(sandwich$status, "unavailable")) base$sandwich_reason <- sandwich$reason
    base[paste0("truth_", make.names(names(truth)))] <- as.list(unname(truth))
    base[paste0("estimate_", make.names(names(truth)))] <- as.list(unname(alpha))
    x_new <- drmTMB:::drm_pair_association_newdata_design(fitted$association, fixed_newdata)
    base[paste0("eta_truth_", seq_len(5L))] <- as.list(unname(x_new %*% truth))
    base[paste0("eta_estimate_", seq_len(5L))] <- as.list(unname(x_new %*% alpha))
    if (identical(sandwich$status, "ok")) {
      alpha_covariance <- sandwich$alpha_covariance
      rownames(alpha_covariance) <- sub("^association:", "", rownames(alpha_covariance))
      colnames(alpha_covariance) <- sub("^association:", "", colnames(alpha_covariance))
      if (!identical(rownames(alpha_covariance), names(truth)) ||
          !identical(colnames(alpha_covariance), names(truth)) ||
          any(!is.finite(alpha_covariance)) ||
          max(abs(alpha_covariance - t(alpha_covariance))) > 1e-8) {
        stop("sandwich_covariance_order_or_finiteness_failure", call. = FALSE)
      }
      base[paste0("sandwich_se_", make.names(names(truth)))] <- as.list(sqrt(diag(alpha_covariance)))
      base[paste0("eta_delta_se_", seq_len(5L))] <- as.list(sqrt(rowSums((x_new %*% alpha_covariance) * x_new)))
      for (row_name in rownames(alpha_covariance)) for (column_name in colnames(alpha_covariance)) {
        covariance_index <- covariance_index + 1L
        covariance_rows[[covariance_index]] <- data.frame(
          mode = mode, formula_id = formula_id, n = n, strength = strength,
          outer_id = outer_id, source_sha = source_sha, row = row_name,
          column = column_name, covariance = alpha_covariance[row_name, column_name],
          stringsAsFactors = FALSE
        )
      }
    }
  }, error = function(e) base$outer_message <<- err_text(e))
  base$elapsed_seconds <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  outer_index <- outer_index + 1L
  outer_rows[[outer_index]] <- as_row(base)
  for (inner_id in seq_len(inner_n)) {
    inner_seed <- manifest_seed("inner", outer_id, inner_id)
    if (is.null(inner_seed)) inner_seed <- 1076073100L + outer_id * 1000L + inner_id + match(formula_id, names(specifications)) * 10000000L + if (strength == "near_boundary") 500000000L else 0L
    row <- c(
      list(mode = mode, formula_id = formula_id, n = n, strength = strength, outer_id = outer_id, inner_id = inner_id, inner_seed = inner_seed, source_sha = source_sha, inner_status = "not_eligible", inner_message = "", sandwich_status = "not_attempted", sandwich_reason = "", elapsed_seconds = NA_real_),
      as.list(stats::setNames(rep(NA_real_, length(truth)), paste0("estimate_", make.names(names(truth)))))
    )
    row <- inherit_outer_payload(row, base)
    started_inner <- Sys.time()
    if (!is.null(fitted) && identical(base$outer_status, "interior") && identical(base$sandwich_status, "ok")) {
      tryCatch({
        refit <- fit_complete(simulate_inner(fitted, inner_seed))
        alpha <- alpha_values(refit)
        inner_sandwich <- drmTMB:::drm_pair_general_eta_sandwich(refit$binary, refit$count, refit$association)
        row <- add_payload(row, refit, inner_sandwich)
        row$diagnostic_payload_origin <- "inner"
        row$diagnostic_eligibility_reason <- NA_character_
        row$inner_status <- refit$association$status
        row$sandwich_status <- inner_sandwich$status
        if (identical(inner_sandwich$status, "unavailable")) row$sandwich_reason <- inner_sandwich$reason
        row[paste0("estimate_", make.names(names(truth)))] <- as.list(unname(alpha))
      }, error = function(e) { row$inner_status <<- "unavailable"; row$inner_message <<- err_text(e) })
    }
    row$elapsed_seconds <- as.numeric(difftime(Sys.time(), started_inner, units = "secs"))
    inner_index <- inner_index + 1L
    inner_rows[[inner_index]] <- as_row(row)
  }
}

utils::write.csv(do.call(rbind, outer_rows), file.path(out_dir, "outer-attempts.csv"), row.names = FALSE)
utils::write.csv(do.call(rbind, inner_rows), file.path(out_dir, "inner-attempts.csv"), row.names = FALSE)
covariance_table <- if (length(covariance_rows)) do.call(rbind, covariance_rows) else data.frame(
  mode = character(), formula_id = character(), n = integer(), strength = character(),
  outer_id = integer(), source_sha = character(), row = character(), column = character(), covariance = numeric()
)
utils::write.csv(covariance_table, file.path(out_dir, "outer-sandwich-covariance.csv"), row.names = FALSE)
utils::write.csv(data.frame(formula_id, n, strength, outer_start, outer_end, inner_n, source_sha, seed_manifest_path = if (is.null(seed_manifest_path)) NA_character_ else normalizePath(seed_manifest_path)), file.path(out_dir, "manifest.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
writeLines(source_sha, file.path(out_dir, "git-sha.txt"))
