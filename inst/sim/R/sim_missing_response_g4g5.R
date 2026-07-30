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
    stringsAsFactors = FALSE
  )
}

mr_g4g5_validate_manifest <- function(manifest = mr_g4g5_route_manifest()) {
  required <- c("route_id", "tranche", "g3_evidence_id", "mask_design")
  if (!is.data.frame(manifest) || !all(required %in% names(manifest))) {
    stop("Missing-response manifest must contain the required route fields.", call. = FALSE)
  }
  if (nrow(manifest) != 18L || anyDuplicated(manifest$route_id) ||
      any(!nzchar(manifest$route_id)) || any(!grepl("^ev-mr-.*-g3$", manifest$g3_evidence_id))) {
    stop("Missing-response manifest must contain exactly 18 unique G3 routes.", call. = FALSE)
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
  profile_ok <- identical(as.character(record$conf.status), "profile") &&
    identical(as.logical(record$profile.boundary), FALSE)
  record$g4_interval_usable <- finite_two_sided && profile_ok
  record$g4_truth_contained <- record$g4_interval_usable &&
    record$conf.low <= record$truth && record$truth <= record$conf.high
  record$g4_pass <- record$g4_interval_usable && record$g4_truth_contained
  record
}
