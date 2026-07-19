# Arc 4c contract: pure, sourceable helpers for the three-family mu slope
# profile-coverage campaign.  This file deliberately has no drmTMB dependency.

arc4c_cells <- data.frame(
  cell_id = c("mc-0464", "mc-0539", "mc-0575"),
  family = c("skew_normal", "tweedie", "zero_one_beta"),
  n_each = c(12L, 12L, 15L),
  stringsAsFactors = FALSE
)
arc4c_M <- c(8L, 16L, 32L, 64L)
arc4c_true_sd <- 0.50
arc4c_seed_base <- 202607190L
arc4c_replicates_per_shard <- 10L
arc4c_full_replicates <- 1200L
arc4c_dgp_spec <- data.frame(
  cell_id = arc4c_cells$cell_id,
  sigma_formula = c("sigma ~ z", "sigma ~ 1", "sigma ~ 1"),
  n_each = arc4c_cells$n_each,
  mu_formula = c("0.2 + 0.6*x + u[id]*x", "0.2 + 0.5*x + u[id]*x", "logit(mu) = 0.3 + 0.7*x + u[id]*x"),
  sigma_intercept = c(-0.3, NA_real_, NA_real_), sigma_z = c(0.15, NA_real_, NA_real_), nu = c(1.6, NA_real_, NA_real_),
  phi = c(NA_real_, 1.4, 6.25), power = c(NA_real_, 1.5, NA_real_),
  boundary_zero = c(NA_real_, NA_real_, 0.075), boundary_one = c(NA_real_, NA_real_, 0.075),
  stringsAsFactors = FALSE
)

arc4c_raw_schema <- c(
  "cell_id", "family", "M", "shard", "replicate", "seed", "mode",
  "fit_status", "fit_error", "convergence", "pdHess", "sd_hat",
  "wald_lower", "wald_upper", "wald_covered", "profile_lower",
  "profile_upper", "profile_conf_status", "profile_error", "profile_finite",
  "profile_covered", "truth_below_interval", "truth_above_interval",
  "nu_hat", "near_zero_slant", "zero_count", "all_zero_cluster_count",
  "interior_count", "one_count", "invalid_interior", "invalid_interior_count",
  "elapsed_seconds"
)

arc4c_stop <- function(...) stop(..., call. = FALSE)

arc4c_cell <- function(cell_id) {
  hit <- arc4c_cells[arc4c_cells$cell_id == cell_id, , drop = FALSE]
  if (nrow(hit) != 1L) arc4c_stop("Unknown Arc 4c cell: ", cell_id)
  hit
}

arc4c_validate_M <- function(M) {
  M <- as.integer(M)
  if (length(M) != 1L || is.na(M) || !M %in% arc4c_M) {
    arc4c_stop("M must be one of ", paste(arc4c_M, collapse = ", "), ".")
  }
  M
}

arc4c_seed <- function(replicate) {
  replicate <- as.integer(replicate)
  if (length(replicate) != 1L || is.na(replicate) || replicate < 1L) {
    arc4c_stop("replicate must be a positive integer.")
  }
  arc4c_seed_base + replicate
}

arc4c_shard_replicates <- function(shard) {
  shard <- as.integer(shard)
  if (length(shard) != 1L || is.na(shard) || shard < 1L || shard > 120L) {
    arc4c_stop("shard must be an integer in 1:120.")
  }
  seq.int(10L * (shard - 1L) + 1L, 10L * shard)
}

arc4c_task <- function(cell_id, M, shard, mode = c("smoke", "full")) {
  mode <- match.arg(mode)
  cell <- arc4c_cell(cell_id)
  M <- arc4c_validate_M(M)
  reps <- if (identical(mode, "smoke")) 1L else arc4c_shard_replicates(shard)
  data.frame(
    cell_id = cell$cell_id, family = cell$family, M = M,
    shard = if (identical(mode, "smoke")) NA_integer_ else as.integer(shard),
    replicate = reps, seed = vapply(reps, arc4c_seed, integer(1L)), mode = mode,
    stringsAsFactors = FALSE
  )
}

arc4c_task_from_range <- function(cell_id, family, M, replicate_start, replicate_end,
                                  mode = c("smoke", "full"), shard = NA_integer_) {
  mode <- match.arg(mode)
  cell <- arc4c_cell(cell_id)
  if (!identical(as.character(family), cell$family[[1L]])) {
    arc4c_stop("family does not match the frozen cell specification.")
  }
  M <- arc4c_validate_M(M)
  replicate_start <- as.integer(replicate_start); replicate_end <- as.integer(replicate_end)
  if (anyNA(c(replicate_start, replicate_end)) || replicate_start < 1L || replicate_end < replicate_start) {
    arc4c_stop("replicate_start and replicate_end must be an ordered positive range.")
  }
  reps <- seq.int(replicate_start, replicate_end)
  if (identical(mode, "smoke") && !identical(reps, 1L)) arc4c_stop("A smoke task must be exactly replicate 1.")
  if (identical(mode, "full")) {
    inferred <- ((replicate_start - 1L) %/% arc4c_replicates_per_shard) + 1L
    if (!identical(reps, arc4c_shard_replicates(inferred)) || (!is.na(shard) && as.integer(shard) != inferred)) {
      arc4c_stop("A full task must own exactly one canonical ten-replicate shard.")
    }
    shard <- inferred
  }
  data.frame(cell_id = cell$cell_id, family = cell$family, M = M, shard = as.integer(shard),
    replicate = reps, seed = vapply(reps, arc4c_seed, integer(1L)), mode = mode,
    stringsAsFactors = FALSE)
}

arc4c_task_manifest <- function(mode = c("smoke", "full"), cells = arc4c_cells$cell_id,
                                Ms = arc4c_M) {
  mode <- match.arg(mode)
  do.call(rbind, unlist(lapply(cells, function(cell_id) {
    unlist(lapply(Ms, function(M) {
      if (identical(mode, "smoke")) list(arc4c_task(cell_id, M, 1L, mode)) else {
        lapply(seq_len(120L), function(k) arc4c_task(cell_id, M, k, mode))
      }
    }), recursive = FALSE)
  }), recursive = FALSE))
}

# DGP specifications are recorded as data plus simulators.  Every simulator resets
# the common-random-number seed immediately before generating that replicate.
arc4c_dgp <- function(cell_id, M, replicate) {
  cell <- arc4c_cell(cell_id); M <- arc4c_validate_M(M)
  set.seed(arc4c_seed(replicate))
  n_each <- cell$n_each[[1L]]
  id <- factor(rep(seq_len(M), each = n_each)); n <- length(id)
  x <- stats::rnorm(n); z <- stats::rnorm(n)
  u <- stats::rnorm(M, sd = arc4c_true_sd)
  if (identical(cell_id, "mc-0464")) {
    # skew-normal: sigma ~ z, in the package's mean/SD/skew parameterization.
    mu <- 0.2 + 0.6 * x + u[id] * x
    sigma <- exp(-0.3 + 0.15 * z)
    nu <- 1.6; delta <- nu / sqrt(1 + nu^2); shift <- delta * sqrt(2 / pi)
    omega <- sigma / sqrt(1 - shift^2); xi <- mu - omega * shift
    y <- xi + omega * (delta * abs(stats::rnorm(n)) + sqrt(1 - delta^2) * stats::rnorm(n))
    return(data.frame(y, x, z, id, eta = mu, slope_re = u[id], sigma, nu = rep(nu, n)))
  }
  if (identical(cell_id, "mc-0539")) {
    # Compound Poisson-Gamma Tweedie: phi=1.4 and p=1.5.
    eta <- 0.2 + 0.5 * x + u[id] * x
    mu_response <- exp(eta); phi <- 1.4; power <- 1.5
    lambda <- mu_response^(2 - power) / (phi * (2 - power))
    count <- stats::rpois(n, lambda)
    y <- numeric(n); positive <- count > 0L
    y[positive] <- stats::rgamma(sum(positive), shape = ((2 - power) / (power - 1)) * count[positive],
      scale = phi * (power - 1) * mu_response[positive]^(power - 1))
    return(data.frame(y, x, z, id, eta, slope_re = u[id], mu = mu_response, phi = phi, power = power))
  }
  # zero-one beta: exactly 15% total structural boundaries, balanced zero/one.
  eta <- 0.3 + 0.7 * x + u[id] * x
  n_boundary <- 0.15 * n
  if (n_boundary != as.integer(n_boundary) || as.integer(n_boundary) %% 2L != 0L) {
    arc4c_stop("The frozen zero-one beta design requires an even integer 15% boundary count.")
  }
  n_zero <- as.integer(n_boundary / 2L); n_one <- n_zero
  boundary <- sample(c(rep("zero", n_zero), rep("one", n_one),
                       rep("beta", n - n_zero - n_one)), n, replace = FALSE)
  p <- stats::plogis(eta)
  y <- ifelse(boundary == "zero", 0, ifelse(boundary == "one", 1,
    stats::rbeta(n, shape1 = p * 6.25, shape2 = (1 - p) * 6.25)))
  data.frame(y, x, z, id, eta, slope_re = u[id], boundary, phi = 6.25)
}

arc4c_empty_row <- function(task) {
  stopifnot(nrow(task) == 1L)
  out <- as.list(rep(NA, length(arc4c_raw_schema))); names(out) <- arc4c_raw_schema
  for (nm in intersect(names(task), names(out))) out[[nm]] <- task[[nm]][[1L]]
  out$fit_status <- "not_attempted"
  as.data.frame(out, stringsAsFactors = FALSE)
}

arc4c_profile_flags <- function(row, truth = arc4c_true_sd) {
  finite <- identical(row$fit_status[[1L]], "eligible") && isTRUE(row$pdHess[[1L]]) &&
    is.finite(row$profile_lower[[1L]]) && is.finite(row$profile_upper[[1L]]) &&
    identical(row$profile_conf_status[[1L]], "profile")
  row$profile_finite <- finite
  if (finite) {
    row$profile_covered <- truth >= row$profile_lower && truth <= row$profile_upper
    row$truth_below_interval <- truth < row$profile_lower
    row$truth_above_interval <- truth > row$profile_upper
  }
  row
}

arc4c_exact_binomial_ci <- function(hits, total) {
  if (length(hits) != 1L || length(total) != 1L || total < 1L || hits < 0L || hits > total) {
    return(c(low = NA_real_, high = NA_real_))
  }
  stats::setNames(stats::binom.test(hits, total)$conf.int, c("low", "high"))
}

arc4c_mean_or_na <- function(x) if (all(is.na(x))) NA_real_ else mean(x, na.rm = TRUE)

arc4c_summarize_cell <- function(raw) {
  arc4c_validate_raw(raw, allow_partial = TRUE)
  n_attempted <- nrow(raw)
  eligible <- raw$fit_status == "eligible"
  n_simulation_error <- sum(raw$fit_status == "simulation_error")
  n_fit_error <- sum(raw$fit_status == "fit_error")
  n_nonconverged <- sum(raw$fit_status == "nonconverged")
  n_pdhess_bad <- sum(raw$fit_status == "pdHess_bad")
  stopifnot(n_attempted == n_simulation_error + n_fit_error + n_nonconverged + n_pdhess_bad + sum(eligible))
  finite <- eligible & raw$profile_finite %in% TRUE
  hits <- sum(raw$profile_covered[finite] %in% TRUE)
  below <- sum(raw$truth_below_interval[finite] %in% TRUE)
  above <- sum(raw$truth_above_interval[finite] %in% TRUE)
  n_finite <- sum(finite)
  in_range <- finite & raw$profile_lower > 0 & raw$profile_upper > raw$profile_lower
  stopifnot(n_finite == hits + below + above)
  primary_ci <- arc4c_exact_binomial_ci(hits, n_attempted)
  conditional_ci <- arc4c_exact_binomial_ci(hits, n_finite)
  data.frame(
    cell_id = raw$cell_id[[1L]], family = raw$family[[1L]], M = raw$M[[1L]],
    n_attempted = n_attempted, n_simulation_error = n_simulation_error, n_fit_error = n_fit_error,
    n_nonconverged = n_nonconverged, n_pdHess_bad = n_pdhess_bad, n_eligible = sum(eligible),
    n_profile_finite = n_finite, n_profile_in_range = sum(in_range), n_profile_failed = sum(eligible) - n_finite,
    n_hits = hits, n_truth_below = below, n_truth_above = above,
    primary_coverage = hits / n_attempted,
    conditional_coverage = if (n_finite) hits / n_finite else NA_real_,
    availability = n_finite / n_attempted,
    primary_mcse = sqrt((hits / n_attempted) * (1 - hits / n_attempted) / n_attempted),
    conditional_mcse = if (n_finite) sqrt((hits / n_finite) * (1 - hits / n_finite) / n_finite) else NA_real_,
    primary_ci_low = primary_ci[["low"]], primary_ci_high = primary_ci[["high"]],
    conditional_ci_low = conditional_ci[["low"]], conditional_ci_high = conditional_ci[["high"]],
    sd_hat_mean = arc4c_mean_or_na(raw$sd_hat),
    relative_sd_bias_mean = (arc4c_mean_or_na(raw$sd_hat) - arc4c_true_sd) / arc4c_true_sd,
    wald_coverage = arc4c_mean_or_na(raw$wald_covered[eligible]),
    profile_width_mean = arc4c_mean_or_na(raw$profile_upper[finite] - raw$profile_lower[finite]),
    nu_hat_mean = arc4c_mean_or_na(raw$nu_hat), near_zero_slant_rate = arc4c_mean_or_na(raw$near_zero_slant),
    zero_count_mean = arc4c_mean_or_na(raw$zero_count), all_zero_cluster_count_mean = arc4c_mean_or_na(raw$all_zero_cluster_count),
    interior_count_mean = arc4c_mean_or_na(raw$interior_count), one_count_mean = arc4c_mean_or_na(raw$one_count),
    invalid_interior_rate = arc4c_mean_or_na(raw$invalid_interior), invalid_interior_count_total = sum(raw$invalid_interior_count, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
}

arc4c_calibration <- function(summary_row) {
  if (summary_row$availability[[1L]] < 0.99) return("withhold_unavailable")
  lo <- summary_row$primary_ci_low[[1L]]; hi <- summary_row$primary_ci_high[[1L]]
  if (is.na(lo) || is.na(hi)) return("withhold_no_interval")
  if (hi < 0.925) return("withhold_undercoverage")
  if (lo > 0.975) return("pass_conservative")
  if (lo >= 0.925 && hi <= 0.975) return("pass_firmly_nominal")
  if (lo <= 0.975 && hi >= 0.925) return("pass_caveated")
  "withhold"
}

arc4c_family_verdict <- function(summary_table) {
  summary_table <- summary_table[order(summary_table$M), , drop = FALSE]
  good <- vapply(seq_len(nrow(summary_table)), function(i) {
    arc4c_calibration(summary_table[i, , drop = FALSE]) %in%
      c("pass_firmly_nominal", "pass_caveated", "pass_conservative")
  }, logical(1L))
  names(good) <- summary_table$M
  required <- c("16", "32", "64")
  if (!all(required %in% names(good)) || !isTRUE(good[["64"]])) {
    return(list(promote = FALSE, floor = NA_integer_, acceptable = as.integer(names(good)[good]), reason = "M64_not_acceptable"))
  }
  suffix <- rev(cumprod(as.integer(rev(good[required]))) == 1L)
  accepted <- as.integer(required[suffix])
  actual <- as.integer(required[good[required]])
  if (!identical(actual, accepted)) {
    return(list(promote = FALSE, floor = NA_integer_, acceptable = as.integer(names(good)[good]), reason = "noncontiguous_hole"))
  }
  list(promote = length(accepted) > 0L, floor = min(accepted), acceptable = as.integer(names(good)[good]),
       reason = "contiguous_suffix")
}

arc4c_smoke_selection <- function(smoke_summary) {
  smoke_summary <- smoke_summary[order(smoke_summary$cell_id, smoke_summary$M), , drop = FALSE]
  out <- lapply(split(smoke_summary, smoke_summary$cell_id), function(x) {
    ok <- x$n_attempted == 1L & x$n_eligible == 1L & x$n_profile_in_range == 1L
    names(ok) <- x$M
    nonexploratory <- c("16", "32", "64")
    data.frame(cell_id = x$cell_id[[1L]], run_full = all(ok[nonexploratory]),
      include_M8 = isTRUE(ok[["8"]]), reason = if (all(ok[nonexploratory])) "approved" else "nonexploratory_smoke_failure")
  })
  do.call(rbind, out)
}

arc4c_clean_text <- function(x) { x <- as.character(x); x <- gsub("[[:cntrl:]]+", " ", x); trimws(x) }
arc4c_write_tsv <- function(x, path) {
  x[] <- lapply(x, function(z) if (is.character(z)) arc4c_clean_text(z) else z)
  utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "NA")
}
arc4c_checksum <- function(path) unname(tools::md5sum(path)[[1L]])
arc4c_atomic_write_tsv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(paste0(basename(path), "."), tmpdir = dirname(path))
  on.exit(unlink(temporary), add = TRUE)
  arc4c_write_tsv(x, temporary)
  if (!file.rename(temporary, path)) arc4c_stop("Could not atomically install: ", path)
  checksum_path <- paste0(path, ".md5")
  writeLines(arc4c_checksum(path), checksum_path, useBytes = TRUE)
  invisible(path)
}
arc4c_read_tsv <- function(path) utils::read.delim(path, sep = "\t", quote = "", check.names = FALSE,
  stringsAsFactors = FALSE, na.strings = "NA")
arc4c_validate_raw <- function(raw, allow_partial = FALSE, expected_task = NULL) {
  if (!identical(names(raw), arc4c_raw_schema)) arc4c_stop("Raw schema mismatch.")
  if (!nrow(raw)) arc4c_stop("Raw shard is empty.")
  if (anyNA(raw[, c("cell_id", "family", "M", "replicate", "seed", "mode")])) arc4c_stop("Raw shard has missing task identity.")
  allowed_status <- c("simulation_error", "fit_error", "nonconverged", "pdHess_bad", "eligible")
  if (anyNA(raw$fit_status) || any(!raw$fit_status %in% allowed_status)) arc4c_stop("Raw shard has an invalid fit_status.")
  if (anyDuplicated(raw[, c("cell_id", "M", "replicate"), drop = FALSE])) arc4c_stop("Duplicate raw replicate.")
  if (length(unique(raw$cell_id)) != 1L || length(unique(raw$family)) != 1L || length(unique(raw$M)) != 1L) arc4c_stop("Raw shard contains more than one cell.")
  if (!is.null(expected_task)) {
    wanted <- expected_task[, c("cell_id", "family", "M", "shard", "replicate", "seed", "mode")]
    got <- raw[, names(wanted), drop = FALSE]
    if (!identical(lapply(got, as.character), lapply(wanted, as.character))) arc4c_stop("Raw shard task mapping mismatch.")
  }
  invisible(TRUE)
}
arc4c_validate_shard_file <- function(path, expected_task) {
  checksum_path <- paste0(path, ".md5")
  if (!file.exists(path) || !file.exists(checksum_path)) arc4c_stop("Missing shard or checksum: ", path)
  stored <- readLines(checksum_path, warn = FALSE)
  if (length(stored) != 1L || !identical(stored, arc4c_checksum(path))) arc4c_stop("Checksum mismatch: ", path)
  raw <- arc4c_read_tsv(path); arc4c_validate_raw(raw, expected_task = expected_task); raw
}
arc4c_aggregate_shards <- function(paths, expected_tasks) {
  if (length(paths) != length(expected_tasks)) arc4c_stop("One expected task is required per shard path.")
  raw <- do.call(rbind, Map(arc4c_validate_shard_file, paths, expected_tasks))
  if (anyDuplicated(raw[, c("cell_id", "M", "replicate"), drop = FALSE])) arc4c_stop("Duplicate replicate across shards.")
  expected <- do.call(rbind, expected_tasks)
  key <- function(x) paste(x$cell_id, x$M, x$replicate, sep = "/")
  if (!setequal(key(raw), key(expected))) arc4c_stop("Aggregate has replicate gaps or wrong cell mappings.")
  raw
}

arc4c_validate_complete_full_cells <- function(raw) {
  by_cell <- split(raw, interaction(raw$cell_id, raw$M, drop = TRUE))
  for (x in by_cell) {
    if (!identical(sort(as.integer(x$replicate)), seq_len(arc4c_full_replicates))) {
      arc4c_stop("Aggregate is incomplete: every full cell must contain replicates 1:1200 exactly.")
    }
  }
  invisible(TRUE)
}
