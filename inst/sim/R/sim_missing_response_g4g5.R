# Missing-response G4/G5 foundation.
#
# This file deliberately records gate-specific evidence separately from the
# capability ledger.  A G5 result is evidence for one frozen response-mask
# target, not a promotion of the model-wide inference tier.

mr_g4g5_route_manifest <- function() {
  data.frame(
    route_id = c(
      "gaussian", "biv_gaussian", "poisson", "nbinom2", "beta",
      "binomial", "student", "lognormal", "gamma", "skew_normal",
      "zero_one_beta", "tweedie", "cumulative_logit", "beta_binomial",
      "truncated_nbinom2", "zi_poisson", "zi_nbinom2", "hurdle_nbinom2"
    ),
    tranche = c(rep("T1", 6), rep("T2", 4), rep("T3", 2), rep("T4", 2), "T5", rep("T6", 3)),
    g3_evidence_id = paste0("ev-mr-", c(
      "gaussian", "biv-gaussian", "poisson", "nbinom2", "beta",
      "binomial", "student", "lognormal", "gamma", "skew-normal",
      "zero-one-beta", "tweedie", "cumulative-logit", "beta-binomial",
      "truncated-nbinom2", "zi-poisson", "zi-nbinom2", "hurdle-nbinom2"
    ), "-g3"),
    mask_design = c(
      "within_group", "paired_within_group", "within_group", "within_group", "within_group",
      "global", "global", "global", "global", "global", "global", "global",
      "global", "global", "within_group", "global", "global", "global"
    ),
    g3_source = c(
      "test-missing-response-recovery.R", "test-missing-response-recovery.R",
      "test-missing-response-recovery.R", "test-missing-response-recovery.R",
      "test-missing-response-recovery.R", "test-missing-response-binomial.R",
      "test-missing-response-continuous.R", "test-missing-response-continuous.R",
      "test-missing-response-continuous.R", "test-missing-response-continuous.R",
      "test-missing-response-boundary.R", "test-missing-response-boundary.R",
      "test-missing-response-encoded.R", "test-missing-response-encoded.R",
      "test-missing-response-truncated-nbinom2.R", "test-missing-response-count-mixtures.R",
      "test-missing-response-count-mixtures.R", "test-missing-response-count-mixtures.R"
    ),
    base_information = c(
      "36_id_x_12", "60_id_x_8", "48_id_x_12", "48_id_x_12", "48_id_x_12",
      "4000", "40_id_x_10", "36_id_x_9", "42_id_x_10", "360", "1600", "500",
      "900", "52_id_x_10", "34_id_x_8", "1800", "1800", "1800"
    ),
    g3_mask_seed = c(
      2026071102L, 2026071104L, 2026071107L, 2026071109L, 2026071111L, 202L,
      2026071221L, 2026071222L, 2026071223L, 2026071231L, 2026071322L, 2026071321L,
      2026071422L, 2026071421L, 2026071506L, 2026071609L, 2026071627L, 2026071650L
    ),
    stringsAsFactors = FALSE
  )
}

mr_g4g5_validate_manifest <- function(manifest = mr_g4g5_route_manifest()) {
  required <- c("route_id", "tranche", "g3_evidence_id", "mask_design", "g3_source",
    "base_information", "g3_mask_seed")
  if (!is.data.frame(manifest) || !all(required %in% names(manifest))) {
    stop("Missing-response manifest must contain the required route fields.", call. = FALSE)
  }
  if (nrow(manifest) != 18L || anyDuplicated(manifest$route_id) ||
      any(!nzchar(manifest$route_id)) || any(!grepl("^ev-mr-.*-g3$", manifest$g3_evidence_id))) {
    stop("Missing-response manifest must contain exactly 18 unique G3 routes.", call. = FALSE)
  }
  if (any(!grepl("^test-missing-response-.*\\.R$", manifest$g3_source)) ||
      any(!nzchar(manifest$base_information)) || any(!is.finite(manifest$g3_mask_seed))) {
    stop("Missing-response manifest must retain a G3 source, size, and mask seed.", call. = FALSE)
  }
  invisible(manifest)
}

# Freeze the actual, canonical targets for one route after constructing its
# frozen G3 DGP. `truth` is a named numeric vector on the reporting scale.
# Requiring an exact name match prevents a runner-local alias (especially for
# ordinal cutpoints and random-effect SDs) from silently shrinking the target
# set.
mr_g4_target_manifest <- function(route_id, targets, truth) {
  required <- c("parm", "target_class", "dpar", "scale", "profile_ready")
  if (!is.data.frame(targets) || !all(required %in% names(targets))) {
    stop("`targets` must be the canonical `profile_targets()` table.", call. = FALSE)
  }
  if (!is.numeric(truth) || is.null(names(truth)) || any(!nzchar(names(truth)))) {
    stop("`truth` must be a named numeric vector keyed by canonical `parm`.", call. = FALSE)
  }
  if (anyDuplicated(targets$parm) || anyDuplicated(names(truth)) ||
      !setequal(targets$parm, names(truth))) {
    stop("Frozen truths must name every canonical target exactly once.", call. = FALSE)
  }
  out <- targets[, required, drop = FALSE]
  out$route_id <- route_id
  out$truth <- unname(truth[out$parm])
  out$interval_method <- ifelse(out$profile_ready, "profile", "wald")
  out$conf.level <- 0.95
  out <- out[c("route_id", "parm", "truth", "target_class", "dpar", "scale",
    "profile_ready", "interval_method", "conf.level")]
  row.names(out) <- NULL
  out
}

mr_g4_validate_target_manifest <- function(manifest) {
  required <- c("route_id", "parm", "truth", "profile_ready", "interval_method", "conf.level")
  if (!is.data.frame(manifest) || !all(required %in% names(manifest)) ||
      anyDuplicated(manifest[c("route_id", "parm")])) {
    stop("A target manifest must have one canonical target per route.", call. = FALSE)
  }
  if (any(!is.finite(manifest$truth)) || any(manifest$conf.level != 0.95) ||
      any(!manifest$interval_method %in% c("profile", "wald")) ||
      any(manifest$profile_ready != (manifest$interval_method == "profile"))) {
    stop("Target manifest has an invalid truth, interval method, or confidence level.", call. = FALSE)
  }
  invisible(manifest)
}

# Convert one profile attempt into an immutable G4 record.  The caller supplies
# the frozen truth on the reporting scale for the canonical `profile_targets()`
# parameter name.  Failed fits and unusable intervals remain records.
mr_g4_profile_record <- function(fit, route_id, parm, truth, replicate = 1L,
                                 level = 0.95, trace = TRUE) {
  targets <- profile_targets(fit)
  target <- targets[targets$parm == parm, , drop = FALSE]
  if (nrow(target) != 1L) {
    stop("`parm` must identify exactly one canonical profile target.", call. = FALSE)
  }
  ci <- tryCatch(
    confint(fit, parm = parm, level = level, method = "profile", trace = trace),
    error = function(e) e
  )
  out <- data.frame(
    route_id = route_id, replicate = as.integer(replicate), parm = parm,
    truth = as.numeric(truth), conf.level = level, target_scale = target$scale,
    target_class = target$target_class, profile_ready = target$profile_ready,
    conf.low = NA_real_, conf.high = NA_real_, conf.status = "profile_failed",
    profile.boundary = NA, profile.message = NA_character_,
    stringsAsFactors = FALSE
  )
  if (inherits(ci, "error")) {
    out$profile.message <- conditionMessage(ci)
    return(mr_g4_validate_record(out))
  }
  row <- ci[ci$parm == parm, , drop = FALSE]
  if (nrow(row) != 1L) {
    out$profile.message <- "profile output did not contain the requested target"
    return(mr_g4_validate_record(out))
  }
  out$conf.low <- row$lower
  out$conf.high <- row$upper
  out$conf.status <- row$conf.status
  out$profile.boundary <- row$profile.boundary
  out$profile.message <- row$profile.message
  mr_g4_validate_record(out)
}

mr_g4_validate_record <- function(record) {
  required <- c("conf.low", "conf.high", "conf.status", "profile.boundary", "truth")
  if (!is.data.frame(record) || nrow(record) != 1L || !all(required %in% names(record))) {
    stop("A G4 record must be one row with interval and truth fields.", call. = FALSE)
  }
  finite_two_sided <- is.finite(record$conf.low) && is.finite(record$conf.high) &&
    record$conf.low < record$conf.high
  method <- if ("interval_method" %in% names(record)) record$interval_method else "profile"
  profile_ok <- identical(method, "profile") && identical(as.character(record$conf.status), "profile") &&
    identical(as.logical(record$profile.boundary), FALSE)
  wald_ok <- identical(method, "wald") && identical(as.character(record$conf.status), "wald")
  record$g4_interval_usable <- finite_two_sided && (profile_ok || wald_ok)
  record$g4_truth_contained <- record$g4_interval_usable &&
    record$conf.low <= record$truth && record$truth <= record$conf.high
  record$g4_pass <- record$g4_interval_usable && record$g4_truth_contained
  record
}

# Run the frozen target manifest without dropping an unavailable profile or a
# failed fit. This is the route-level unit consumed by the future DGP runners.
mr_g4_run_target_manifest <- function(fit, target_manifest, replicate = 1L, trace = TRUE) {
  mr_g4_validate_target_manifest(target_manifest)
  rows <- lapply(seq_len(nrow(target_manifest)), function(i) {
    target <- target_manifest[i, , drop = FALSE]
    ci <- tryCatch(
      confint(fit, parm = target$parm, level = target$conf.level,
        method = target$interval_method, trace = trace),
      error = function(e) e
    )
    out <- data.frame(
      route_id = target$route_id, replicate = as.integer(replicate), parm = target$parm,
      truth = target$truth, conf.level = target$conf.level, target_scale = target$scale,
      target_class = target$target_class, profile_ready = target$profile_ready,
      interval_method = target$interval_method, conf.low = NA_real_, conf.high = NA_real_,
      conf.status = paste0(target$interval_method, "_failed"), profile.boundary = NA,
      profile.message = NA_character_, stringsAsFactors = FALSE
    )
    if (inherits(ci, "error")) {
      out$profile.message <- conditionMessage(ci)
      return(mr_g4_validate_record(out))
    }
    row <- ci[ci$parm == target$parm, , drop = FALSE]
    if (nrow(row) != 1L) {
      out$profile.message <- "interval output did not contain the requested target"
      return(mr_g4_validate_record(out))
    }
    out$conf.low <- row$lower
    out$conf.high <- row$upper
    out$conf.status <- row$conf.status
    out$profile.boundary <- row$profile.boundary
    out$profile.message <- row$profile.message
    mr_g4_validate_record(out)
  })
  do.call(rbind, rows)
}

# Coverage is intentionally unconditional on fit and interval success. Every
# planned replicate stays in the denominator; unusable intervals therefore
# contribute `covered = FALSE` rather than being silently dropped.
mr_g5_summarise_attempts <- function(records, by = c("route_id", "parm", "information_rung"),
                                     planned = 1200L) {
  required <- c(by, "g4_interval_usable", "g4_truth_contained")
  if (!is.data.frame(records) || !all(required %in% names(records))) {
    stop("G5 records must include grouping and G4 interval fields.", call. = FALSE)
  }
  if (!is.numeric(planned) || length(planned) != 1L || planned < 1L) {
    stop("`planned` must be one positive number of planned attempts.", call. = FALSE)
  }
  key <- interaction(records[by], drop = TRUE, lex.order = TRUE)
  pieces <- split(records, key)
  out <- lapply(pieces, function(x) {
    if (nrow(x) != planned) {
      stop("Each G5 cell must retain exactly its planned number of attempts.", call. = FALSE)
    }
    covered <- as.logical(x$g4_truth_contained)
    covered[is.na(covered)] <- FALSE
    data.frame(x[1L, by, drop = FALSE], n_planned = planned,
      n_attempt = nrow(x), n_interval_usable = sum(x$g4_interval_usable %in% TRUE),
      n_covered = sum(covered), coverage = mean(covered),
      coverage_mcse = sqrt(mean(covered) * (1 - mean(covered)) / planned),
      stringsAsFactors = FALSE, check.names = FALSE)
  })
  out <- do.call(rbind, out)
  row.names(out) <- NULL
  out
}

# Build the deterministic G4/G5 task registry only after all route-specific
# target manifests are frozen.  The registry is a plan, not evidence: G5
# callers must pass only rows whose G4 records pass.
mr_g4g5_task_registry <- function(target_manifests, information_rungs = c(0.5, 1, 2),
                                  n_rep = 1L, master_seed = 2026073001L) {
  routes <- mr_g4g5_route_manifest()
  if (!is.list(target_manifests) || is.null(names(target_manifests)) ||
      !setequal(names(target_manifests), routes$route_id)) {
    stop("`target_manifests` must contain one frozen manifest for every one of the 18 routes.", call. = FALSE)
  }
  if (!is.numeric(information_rungs) || !identical(information_rungs, c(0.5, 1, 2))) {
    stop("Information rungs must be exactly 0.5, 1, and 2 times the G3 design.", call. = FALSE)
  }
  if (!is.numeric(n_rep) || length(n_rep) != 1L || n_rep < 1L || n_rep != as.integer(n_rep)) {
    stop("`n_rep` must be one positive whole number.", call. = FALSE)
  }
  targets <- do.call(rbind, lapply(target_manifests, function(x) {
    mr_g4_validate_target_manifest(x)
    x
  }))
  targets <- merge(targets, routes, by = "route_id", all.x = TRUE, sort = FALSE)
  cells <- do.call(rbind, lapply(information_rungs, function(rung) {
    out <- targets
    out$information_rung <- paste0(rung, "x")
    out$information_multiplier <- rung
    out
  }))
  cells$cell_id <- sprintf("mr_g4g5_%04d", seq_len(nrow(cells)))
  set.seed(master_seed)
  seeds <- data.frame(
    cell_id = rep(cells$cell_id, each = n_rep),
    cell_index = rep(seq_len(nrow(cells)), each = n_rep),
    replicate = rep(seq_len(n_rep), times = nrow(cells)),
    seed = sample.int(.Machine$integer.max, nrow(cells) * n_rep),
    stringsAsFactors = FALSE
  )
  list(cells = cells, seeds = seeds, n_rep = as.integer(n_rep), master_seed = master_seed)
}

mr_g5_registry_from_g4 <- function(target_manifests, g4_records, master_seed = 2026073002L) {
  required <- c("route_id", "parm", "g4_pass")
  if (!is.data.frame(g4_records) || !all(required %in% names(g4_records))) {
    stop("`g4_records` must include route, parameter, and pass fields.", call. = FALSE)
  }
  passed <- g4_records[g4_records$g4_pass %in% TRUE, c("route_id", "parm"), drop = FALSE]
  if (nrow(passed) == 0L) {
    stop("No G4-passing targets are eligible for G5.", call. = FALSE)
  }
  filtered <- lapply(target_manifests, function(x) {
    keep <- paste(x$route_id, x$parm, sep = "\r") %in%
      paste(passed$route_id, passed$parm, sep = "\r")
    x[keep, , drop = FALSE]
  })
  filtered <- filtered[vapply(filtered, nrow, integer(1L)) > 0L]
  # The all-route guard is intentionally bypassed only here: G5 is permitted
  # cohort-by-cohort, but never for a target that failed G4.
  all_targets <- do.call(rbind, filtered)
  all_targets$information_rung <- rep(c("0.5x", "1x", "2x"), each = nrow(all_targets))
  all_targets$information_multiplier <- rep(c(0.5, 1, 2), each = nrow(all_targets))
  all_targets$cell_id <- sprintf("mr_g5_%04d", seq_len(nrow(all_targets)))
  set.seed(master_seed)
  seeds <- data.frame(
    cell_id = rep(all_targets$cell_id, each = 1200L),
    cell_index = rep(seq_len(nrow(all_targets)), each = 1200L),
    replicate = rep(seq_len(1200L), times = nrow(all_targets)),
    seed = sample.int(.Machine$integer.max, nrow(all_targets) * 1200L),
    stringsAsFactors = FALSE
  )
  list(cells = all_targets, seeds = seeds, n_rep = 1200L, master_seed = master_seed)
}
