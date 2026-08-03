ce_targets <- function() {
  data.frame(
    target = c(
      "sd:mu:mu1:spatial(1 | p | site)",
      "sd:mu:mu2:spatial(1 | p | site)",
      "cor:spatial:cor(mu1:(Intercept),mu2:(Intercept) | p | site)"
    ),
    truth = c(0.55, 0.55, 0.45),
    tmb_parameter = c("log_sd_phylo", "log_sd_phylo", "eta_cor_phylo"),
    index = c(1L, 2L, 1L),
    scale = "response",
    transformation = c("exp", "exp", "tanh"),
    stringsAsFactors = FALSE
  )
}

ce_rungs <- function() {
  data.frame(
    rung = c("L", "M", "H"),
    rung_index = 1:3,
    n_site = c(12L, 36L, 36L),
    n_each = c(3L, 3L, 8L),
    stringsAsFactors = FALSE
  )
}

ce_design <- function(stage = c("smoke", "full")) {
  stage <- match.arg(stage)
  n_rep <- if (stage == "smoke") 20L else 500L
  seed_base <- if (stage == "smoke") 260803000L else 260900000L
  rungs <- ce_rungs()
  out <- do.call(rbind, lapply(seq_len(nrow(rungs)), function(i) {
    data.frame(
      stage = stage,
      rung = rungs$rung[[i]],
      rung_index = rungs$rung_index[[i]],
      n_site = rungs$n_site[[i]],
      n_each = rungs$n_each[[i]],
      replicate = seq_len(n_rep),
      seed = seed_base + 1000L * rungs$rung_index[[i]] + seq_len(n_rep),
      stringsAsFactors = FALSE
    )
  }))
  row.names(out) <- NULL
  out$task_id <- seq_len(nrow(out))
  out
}

ce_parse_args <- function(args) {
  out <- list()
  i <- 1L
  while (i <= length(args)) {
    key <- args[[i]]
    if (!startsWith(key, "--") || i == length(args)) {
      stop("Arguments must be supplied as --name value pairs.", call. = FALSE)
    }
    out[[substring(key, 3L)]] <- args[[i + 1L]]
    i <- i + 2L
  }
  out
}

ce_clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  trimws(gsub(" +", " ", x))
}

ce_sha256_file <- function(path) {
  path <- normalizePath(path, mustWork = TRUE)
  commands <- list(
    c("sha256sum", path),
    c("shasum", "-a", "256", path)
  )
  for (command in commands) {
    value <- tryCatch(
      system2(command[[1L]], command[-1L], stdout = TRUE, stderr = FALSE),
      error = function(e) character()
    )
    if (length(value) && nzchar(value[[1L]])) {
      return(strsplit(trimws(value[[1L]]), "[[:space:]]+")[[1L]][[1L]])
    }
  }
  stop("Neither sha256sum nor shasum is available.", call. = FALSE)
}

ce_sha256_text <- function(text) {
  path <- tempfile("ce-sha256-")
  on.exit(unlink(path), add = TRUE)
  con <- file(path, open = "wb")
  on.exit(close(con), add = TRUE)
  writeBin(charToRaw(enc2utf8(paste0(text, collapse = ""))), con)
  close(con)
  on.exit(NULL, add = FALSE)
  hash <- ce_sha256_file(path)
  unlink(path)
  hash
}

ce_atomic_write_tsv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- paste0(path, ".tmp-", Sys.getpid())
  on.exit(unlink(temporary), add = TRUE)
  char_cols <- vapply(x, is.character, logical(1L))
  x[char_cols] <- lapply(x[char_cols], ce_clean_text)
  utils::write.table(
    x,
    temporary,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA"
  )
  if (!file.rename(temporary, path)) {
    stop("Could not atomically publish ", path, call. = FALSE)
  }
  invisible(path)
}

ce_read_metadata <- function(path) {
  values <- utils::read.delim(path, stringsAsFactors = FALSE, check.names = FALSE)
  if (!identical(names(values), c("key", "value")) || anyDuplicated(values$key)) {
    stop("Malformed packet metadata.", call. = FALSE)
  }
  stats::setNames(as.character(values$value), values$key)
}

ce_validate_packet <- function(packet_dir) {
  packet_dir <- normalizePath(packet_dir, mustWork = TRUE)
  manifest_path <- file.path(packet_dir, "manifest.tsv")
  metadata_path <- file.path(packet_dir, "metadata.tsv")
  manifest <- utils::read.delim(
    manifest_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  if (!identical(names(manifest), c("path", "sha256")) || anyDuplicated(manifest$path)) {
    stop("Malformed packet manifest.", call. = FALSE)
  }
  metadata <- ce_read_metadata(metadata_path)
  required <- c("source_sha", "packet_sha256")
  if (!all(required %in% names(metadata))) {
    stop("Packet metadata is incomplete.", call. = FALSE)
  }
  if (!identical(unname(metadata[["packet_sha256"]]), ce_sha256_file(manifest_path))) {
    stop("Packet manifest digest mismatch.", call. = FALSE)
  }
  for (i in seq_len(nrow(manifest))) {
    path <- file.path(packet_dir, manifest$path[[i]])
    if (!file.exists(path) || !identical(ce_sha256_file(path), manifest$sha256[[i]])) {
      stop("Packet member digest mismatch: ", manifest$path[[i]], call. = FALSE)
    }
  }
  list(
    packet_dir = packet_dir,
    source_sha = unname(metadata[["source_sha"]]),
    packet_sha256 = unname(metadata[["packet_sha256"]]),
    manifest = manifest
  )
}

ce_coords <- function(site_levels) {
  n_site <- length(site_levels)
  index <- seq_len(n_site)
  theta <- seq(0, 1.5 * pi, length.out = n_site)
  coords <- data.frame(
    coord_x = cos(theta) + index / (3 * n_site),
    coord_y = sin(theta),
    row.names = site_levels
  )
  coords
}

ce_canonical_matrix <- function(x) {
  values <- apply(x, 1L, function(row) paste(sprintf("%.17g", row), collapse = ","))
  paste(paste(row.names(x), values, sep = "\t"), collapse = "\n")
}

ce_make_dgp <- function(design_row) {
  n_site <- as.integer(design_row$n_site[[1L]])
  n_each <- as.integer(design_row$n_each[[1L]])
  seed <- as.integer(design_row$seed[[1L]])
  set.seed(seed)
  site_levels <- paste0("site_", seq_len(n_site))
  coords <- ce_coords(site_levels)
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords,
    site = site_levels,
    group = "site"
  )
  covariance <- solve(as.matrix(precision$precision))

  distances <- as.matrix(stats::dist(as.matrix(coords[, 1:2, drop = FALSE])))
  positive <- distances[upper.tri(distances) & distances > 0]
  range <- stats::median(positive)
  if (!is.finite(range) || range <= 0) {
    range <- max(positive)
  }
  expected <- exp(-distances / range)
  diag(expected) <- diag(expected) + 1e-6
  fallback_fired <- max(abs(covariance - expected)) > 1e-8

  z1 <- stats::rnorm(n_site)
  z2 <- 0.45 * z1 + sqrt(1 - 0.45^2) * stats::rnorm(n_site)
  spatial1 <- as.vector(t(chol(covariance)) %*% z1) * 0.55
  spatial2 <- as.vector(t(chol(covariance)) %*% z2) * 0.55
  names(spatial1) <- names(spatial2) <- site_levels

  site <- rep(site_levels, each = n_each)
  n <- length(site)
  x1 <- stats::rnorm(n)
  x2 <- stats::rnorm(n)
  e1 <- stats::rnorm(n)
  e2 <- -0.10 * e1 + sqrt(1 - 0.10^2) * stats::rnorm(n)
  mu1 <- 0.35 + 0.25 * x1 + spatial1[site]
  mu2 <- -0.20 - 0.30 * x2 + spatial2[site]
  dat <- data.frame(
    y1 = unname(mu1 + 0.18 * e1),
    y2 = unname(mu2 + 0.20 * e2),
    x1 = x1,
    x2 = x2,
    site = factor(site, levels = site_levels),
    stringsAsFactors = FALSE
  )
  list(
    data = dat,
    coords = coords,
    covariance = covariance,
    coords_sha256 = ce_sha256_text(ce_canonical_matrix(as.matrix(coords))),
    K_sp_sha256 = ce_sha256_text(ce_canonical_matrix(covariance)),
    site_order = paste(site_levels, collapse = ","),
    kernel_condition = kappa(covariance),
    jitter = 1e-6,
    fallback_fired = fallback_fired
  )
}

ce_capture <- function(expr) {
  warnings <- character()
  value <- tryCatch(
    withCallingHandlers(
      expr,
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) e
  )
  list(
    value = value,
    error = if (inherits(value, "error")) conditionMessage(value) else "",
    warnings = unique(warnings)
  )
}

ce_base_rows <- function(design_row, packet, dgp = NULL) {
  targets <- ce_targets()
  data.frame(
    source_sha = packet$source_sha,
    packet_sha256 = packet$packet_sha256,
    stage = as.character(design_row$stage[[1L]]),
    rung = as.character(design_row$rung[[1L]]),
    replicate = as.integer(design_row$replicate[[1L]]),
    seed = as.integer(design_row$seed[[1L]]),
    n_site = as.integer(design_row$n_site[[1L]]),
    n_each = as.integer(design_row$n_each[[1L]]),
    target = targets$target,
    truth = targets$truth,
    estimate = NA_real_,
    lower = NA_real_,
    upper = NA_real_,
    covered = FALSE,
    finite_interval = FALSE,
    tmb_parameter = targets$tmb_parameter,
    index = targets$index,
    scale = targets$scale,
    transformation = targets$transformation,
    objective = NA_real_,
    fit_convergence = NA_integer_,
    pdHess = FALSE,
    point_fit_valid = FALSE,
    fit_warning = "",
    profile_status = "not_run",
    profile_boundary = NA,
    profile_clamp_limited = NA,
    profile_warning = "",
    elapsed_seconds = NA_real_,
    failure_class = "",
    failure_detail = "",
    failure_message = "",
    coords_sha256 = if (is.null(dgp)) "" else dgp$coords_sha256,
    K_sp_sha256 = if (is.null(dgp)) "" else dgp$K_sp_sha256,
    site_order = if (is.null(dgp)) "" else dgp$site_order,
    kernel_condition = if (is.null(dgp)) NA_real_ else dgp$kernel_condition,
    jitter = if (is.null(dgp)) NA_real_ else dgp$jitter,
    fallback_fired = if (is.null(dgp)) NA else dgp$fallback_fired,
    wald_lower = NA_real_,
    wald_upper = NA_real_,
    wald_covered = FALSE,
    wald_status = "not_run",
    stringsAsFactors = FALSE
  )
}

ce_fit <- function(dgp) {
  coords <- dgp$coords
  drmTMB::drmTMB(
    drmTMB::bf(
      mu1 = y1 ~ x1 + spatial(1 | p | site, coords = coords),
      mu2 = y2 ~ x2 + spatial(1 | p | site, coords = coords),
      sigma1 = ~ 1,
      sigma2 = ~ 1,
      rho12 = ~ 1
    ),
    family = drmTMB::biv_gaussian(),
    data = dgp$data,
    REML = TRUE,
    control = drmTMB::drm_control(
      keep_tmb_object = TRUE,
      optimizer = list(eval.max = 1000, iter.max = 1000)
    )
  )
}

ce_fit_failure_detail <- function(convergence, pdHess, objective, estimates, interior) {
  if (!is.finite(convergence) || convergence != 0L) return("fit_nonconvergence")
  if (!isTRUE(pdHess)) return("fit_pdhess_false")
  if (!is.finite(objective) || any(!is.finite(estimates))) return("fit_nonfinite")
  if (!isTRUE(interior)) return("fit_target_boundary")
  ""
}

ce_run_attempt <- function(design_row, packet) {
  started <- proc.time()[["elapsed"]]
  dgp_result <- ce_capture(ce_make_dgp(design_row))
  if (nzchar(dgp_result$error)) {
    rows <- ce_base_rows(design_row, packet)
    rows$failure_class <- "dgp_failure"
    rows$failure_detail <- "dgp_failure"
    rows$failure_message <- dgp_result$error
    rows$elapsed_seconds <- proc.time()[["elapsed"]] - started
    return(rows)
  }
  dgp <- dgp_result$value
  rows <- ce_base_rows(design_row, packet, dgp)
  if (isTRUE(dgp$fallback_fired) || !is.finite(dgp$kernel_condition)) {
    rows$failure_class <- "provenance_failure"
    rows$failure_detail <- "kernel_contract_mismatch"
    rows$failure_message <- "Kernel fallback or non-finite condition number."
    rows$elapsed_seconds <- proc.time()[["elapsed"]] - started
    return(rows)
  }

  fit_result <- ce_capture(ce_fit(dgp))
  rows$fit_warning <- paste(fit_result$warnings, collapse = " | ")
  if (nzchar(fit_result$error)) {
    rows$failure_class <- "fit_error"
    rows$failure_detail <- "fit_error"
    rows$failure_message <- fit_result$error
    rows$elapsed_seconds <- proc.time()[["elapsed"]] - started
    return(rows)
  }
  fit <- fit_result$value
  target_table <- drmTMB::profile_targets(fit)
  target_table <- target_table[match(rows$target, target_table$parm), , drop = FALSE]
  target_table_valid <- nrow(target_table) == 3L &&
    !anyNA(target_table$parm) &&
    identical(as.character(target_table$parm), rows$target) &&
    all(target_table$profile_ready) &&
    identical(as.character(target_table$tmb_parameter), rows$tmb_parameter) &&
    identical(as.integer(target_table$index), rows$index) &&
    identical(as.character(target_table$transformation), rows$transformation)
  if (!target_table_valid) {
    rows$failure_class <- "provenance_failure"
    rows$failure_detail <- "profile_target_identity_mismatch"
    rows$failure_message <- "The fitted profile target registry differs from the frozen contract."
    rows$elapsed_seconds <- proc.time()[["elapsed"]] - started
    return(rows)
  }

  estimates <- as.numeric(target_table$estimate)
  rows$estimate <- estimates
  rows$objective <- as.numeric(fit$opt$objective)
  rows$fit_convergence <- as.integer(fit$opt$convergence)
  rows$pdHess <- isTRUE(fit$sdr$pdHess)
  interior <- all(estimates[1:2] > 1e-8) && abs(estimates[[3L]]) < 0.999998
  detail <- ce_fit_failure_detail(
    rows$fit_convergence[[1L]],
    rows$pdHess[[1L]],
    rows$objective[[1L]],
    estimates,
    interior
  )
  if (nzchar(detail)) {
    rows$failure_class <- "profile_not_run_pointfit_invalid"
    rows$failure_detail <- detail
    rows$failure_message <- "Profile not run because the frozen point-fit gate failed."
    rows$elapsed_seconds <- proc.time()[["elapsed"]] - started
    return(rows)
  }
  rows$point_fit_valid <- TRUE

  profile_result <- ce_capture(stats::confint(
    fit,
    parm = rows$target,
    level = 0.95,
    method = "profile",
    profile_engine = "endpoint",
    profile_endpoint_max_eval = 96,
    parallel = "none"
  ))
  rows$profile_warning <- paste(profile_result$warnings, collapse = " | ")
  if (nzchar(profile_result$error)) {
    rows$failure_class <- "profile_error"
    rows$failure_detail <- "profile_error"
    rows$failure_message <- profile_result$error
    rows$elapsed_seconds <- proc.time()[["elapsed"]] - started
    return(rows)
  }
  ci <- profile_result$value
  ci <- ci[match(rows$target, ci$parm), , drop = FALSE]
  if (nrow(ci) != 3L || anyNA(ci$parm)) {
    rows$failure_class <- "provenance_failure"
    rows$failure_detail <- "profile_output_identity_mismatch"
    rows$failure_message <- "Profile output does not contain exactly the frozen target set."
    rows$elapsed_seconds <- proc.time()[["elapsed"]] - started
    return(rows)
  }
  rows$lower <- as.numeric(ci$lower)
  rows$upper <- as.numeric(ci$upper)
  rows$profile_status <- as.character(ci$conf.status)
  rows$profile_boundary <- as.logical(ci$profile.boundary)
  profile_message <- ce_clean_text(ci$profile.message)
  rows$profile_clamp_limited <- grepl("clamp", profile_message, ignore.case = TRUE)
  finite <- rows$profile_status == "profile" &
    is.finite(rows$lower) & is.finite(rows$upper) & rows$lower < rows$upper &
    rows$lower <= rows$estimate & rows$estimate <= rows$upper &
    !(rows$profile_boundary %in% TRUE) & !rows$profile_clamp_limited
  rows$finite_interval <- finite
  rows$covered <- finite & rows$lower <= rows$truth & rows$truth <= rows$upper
  failed <- !finite
  rows$failure_class[failed] <- ifelse(
    rows$profile_clamp_limited[failed],
    "profile_clamp_limited",
    ifelse(
      !is.na(rows$profile_boundary[failed]) & rows$profile_boundary[failed],
      "profile_boundary",
      ifelse(
        rows$profile_status[failed] == "profile_failed",
        "profile_error",
        "profile_nonfinite"
      )
    )
  )
  rows$failure_detail[failed] <- rows$profile_status[failed]
  rows$failure_message[failed] <- profile_message[failed]

  wald_result <- ce_capture(stats::confint(
    fit,
    parm = rows$target,
    level = 0.95,
    method = "wald"
  ))
  if (!nzchar(wald_result$error)) {
    wald <- wald_result$value
    wald <- wald[match(rows$target, wald$parm), , drop = FALSE]
    if (nrow(wald) == 3L && !anyNA(wald$parm)) {
      rows$wald_lower <- as.numeric(wald$lower)
      rows$wald_upper <- as.numeric(wald$upper)
      rows$wald_status <- as.character(wald$conf.status)
      rows$wald_covered <- is.finite(rows$wald_lower) & is.finite(rows$wald_upper) &
        rows$wald_lower <= rows$truth & rows$truth <= rows$wald_upper
    }
  } else {
    rows$wald_status <- "wald_error"
  }
  rows$elapsed_seconds <- proc.time()[["elapsed"]] - started
  rows
}

ce_mcse <- function(count, denominator) {
  if (!is.finite(denominator) || denominator <= 0) return(NA_real_)
  rate <- count / denominator
  sqrt(rate * (1 - rate) / denominator)
}

ce_wilson <- function(count, denominator, level = 0.95) {
  if (!is.finite(denominator) || denominator <= 0) return(c(NA_real_, NA_real_))
  z <- stats::qnorm(1 - (1 - level) / 2)
  p <- count / denominator
  divisor <- 1 + z^2 / denominator
  centre <- (p + z^2 / (2 * denominator)) / divisor
  half <- z * sqrt(p * (1 - p) / denominator + z^2 / (4 * denominator^2)) / divisor
  c(centre - half, centre + half)
}

ce_target_summary <- function(rows, expected_n) {
  attempts <- nrow(rows)
  coverage_count <- sum(rows$covered %in% TRUE)
  finite_count <- sum(rows$finite_interval %in% TRUE)
  valid_fit_count <- sum(rows$point_fit_valid %in% TRUE)
  warning_count <- sum(nzchar(rows$fit_warning) | nzchar(rows$profile_warning))
  conditional_count <- sum(rows$covered[rows$finite_interval %in% TRUE] %in% TRUE)
  coverage_wilson <- ce_wilson(coverage_count, attempts)
  finite_wilson <- ce_wilson(finite_count, attempts)
  conditional_wilson <- ce_wilson(conditional_count, finite_count)
  coverage <- if (attempts) coverage_count / attempts else NA_real_
  finite_rate <- if (attempts) finite_count / attempts else NA_real_
  data.frame(
    rung = rows$rung[[1L]],
    target = rows$target[[1L]],
    attempts = attempts,
    expected_attempts = expected_n,
    unique_seeds = length(unique(rows$seed)),
    coverage_count = coverage_count,
    coverage = coverage,
    coverage_mcse = ce_mcse(coverage_count, attempts),
    coverage_wilson_lower = coverage_wilson[[1L]],
    coverage_wilson_upper = coverage_wilson[[2L]],
    finite_count = finite_count,
    finite_rate = finite_rate,
    finite_mcse = ce_mcse(finite_count, attempts),
    finite_wilson_lower = finite_wilson[[1L]],
    finite_wilson_upper = finite_wilson[[2L]],
    conditional_coverage_count = conditional_count,
    conditional_coverage = if (finite_count) conditional_count / finite_count else NA_real_,
    conditional_coverage_mcse = ce_mcse(conditional_count, finite_count),
    conditional_coverage_wilson_lower = conditional_wilson[[1L]],
    conditional_coverage_wilson_upper = conditional_wilson[[2L]],
    valid_fit_count = valid_fit_count,
    valid_fit_rate = if (attempts) valid_fit_count / attempts else NA_real_,
    valid_fit_mcse = ce_mcse(valid_fit_count, attempts),
    warning_count = warning_count,
    warning_rate = if (attempts) warning_count / attempts else NA_real_,
    warning_mcse = ce_mcse(warning_count, attempts),
    median_elapsed_seconds = stats::median(rows$elapsed_seconds, na.rm = TRUE),
    p90_elapsed_seconds = unname(stats::quantile(rows$elapsed_seconds, 0.90, na.rm = TRUE)),
    max_elapsed_seconds = max(rows$elapsed_seconds, na.rm = TRUE),
    failure_counts = paste(
      names(table(rows$failure_class[nzchar(rows$failure_class)])),
      as.integer(table(rows$failure_class[nzchar(rows$failure_class)])),
      sep = "=",
      collapse = ";"
    ),
    target_pass = attempts == expected_n &&
      length(unique(rows$seed)) == expected_n &&
      is.finite(coverage) && coverage >= 0.925 && coverage <= 0.975 &&
      is.finite(finite_rate) && finite_rate >= 0.95,
    stringsAsFactors = FALSE
  )
}

ce_common_floor <- function(summary) {
  order <- ce_rungs()$rung
  joint <- vapply(order, function(rung) {
    rows <- summary[summary$rung == rung, , drop = FALSE]
    nrow(rows) == 3L && all(rows$target_pass)
  }, logical(1L))
  for (i in seq_along(order)) {
    if (all(joint[i:length(joint)])) return(order[[i]])
  }
  NA_character_
}

ce_reconcile <- function(stage, input_dir, output_dir, packet) {
  design <- ce_design(stage)
  expected <- file.path(
    input_dir,
    sprintf("%s-%s-%03d.tsv", stage, design$rung, design$replicate)
  )
  missing <- expected[!file.exists(expected)]
  if (length(missing)) {
    stop("Missing raw task outputs: ", paste(basename(missing), collapse = ", "), call. = FALSE)
  }
  pieces <- lapply(expected, function(path) {
    utils::read.delim(path, stringsAsFactors = FALSE, check.names = FALSE)
  })
  rows <- do.call(rbind, pieces)
  targets <- ce_targets()$target
  expected_keys <- as.vector(t(outer(
    paste(design$rung, design$replicate, design$seed, sep = "::"),
    targets,
    paste,
    sep = "::"
  )))
  observed_keys <- paste(rows$rung, rows$replicate, rows$seed, rows$target, sep = "::")
  if (nrow(rows) != 3L * nrow(design) || anyDuplicated(observed_keys) ||
      !setequal(observed_keys, expected_keys)) {
    stop("Raw task rows do not match the frozen design exactly.", call. = FALSE)
  }
  if (any(rows$source_sha != packet$source_sha) ||
      any(rows$packet_sha256 != packet$packet_sha256) ||
      any(rows$stage != stage)) {
    stop("Raw task provenance does not match the frozen packet.", call. = FALSE)
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  ce_atomic_write_tsv(rows, file.path(output_dir, "raw-target-outcomes.tsv"))
  expected_n <- if (stage == "smoke") 20L else 500L
  groups <- split(rows, interaction(rows$rung, rows$target, drop = TRUE))
  summary <- do.call(rbind, lapply(groups, ce_target_summary, expected_n = expected_n))
  row.names(summary) <- NULL
  summary$rung <- factor(summary$rung, levels = ce_rungs()$rung)
  summary <- summary[order(summary$rung, summary$target), , drop = FALSE]
  summary$rung <- as.character(summary$rung)
  ce_atomic_write_tsv(summary, file.path(output_dir, "target-summary.tsv"))

  if (stage == "full") {
    floor <- ce_common_floor(summary)
    rung_gate <- do.call(rbind, lapply(ce_rungs()$rung, function(rung) {
      current <- summary[summary$rung == rung, , drop = FALSE]
      data.frame(
        rung = rung,
        all_three_pass = nrow(current) == 3L && all(current$target_pass),
        stringsAsFactors = FALSE
      )
    }))
    ce_atomic_write_tsv(rung_gate, file.path(output_dir, "rung-gate.tsv"))
    decision <- data.frame(
      verdict = if (is.na(floor)) "HOLD" else "PASS",
      common_floor = if (is.na(floor)) "" else floor,
      attempts = nrow(design),
      target_outcomes = nrow(rows),
      coverage_gate_lower = 0.925,
      coverage_gate_upper = 0.975,
      finite_rate_gate = 0.95,
      stringsAsFactors = FALSE
    )
  } else {
    infrastructure_failures <- sum(rows$failure_class %in% c(
      "dgp_failure", "provenance_failure", "fit_error"
    ))
    decision <- data.frame(
      verdict = if (infrastructure_failures == 0L) "SMOKE_COMPLETE" else "SMOKE_STOP",
      common_floor = "",
      attempts = nrow(design),
      target_outcomes = nrow(rows),
      coverage_gate_lower = NA_real_,
      coverage_gate_upper = NA_real_,
      finite_rate_gate = NA_real_,
      stringsAsFactors = FALSE
    )
  }
  ce_atomic_write_tsv(decision, file.path(output_dir, "decision.tsv"))
  invisible(list(rows = rows, summary = summary, decision = decision))
}
