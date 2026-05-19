phase18_correlation_target_inventory <- function(fit) {
  if (!inherits(fit, "drmTMB")) {
    stop("`fit` must be a drmTMB object.", call. = FALSE)
  }

  pairs <- corpairs(fit)
  if (nrow(pairs) == 0L) {
    return(phase18_empty_correlation_target_inventory())
  }
  targets <- profile_targets(fit)
  target_index <- phase18_match_correlation_profile_targets(pairs, targets)

  profile_target <- rep(NA_character_, nrow(pairs))
  profile_ready <- rep(FALSE, nrow(pairs))
  target_type <- rep(NA_character_, nrow(pairs))
  profile_note <- rep(NA_character_, nrow(pairs))
  matched <- !is.na(target_index)
  profile_target[matched] <- targets$parm[target_index[matched]]
  profile_ready[matched] <- targets$profile_ready[target_index[matched]]
  target_type[matched] <- targets$target_type[target_index[matched]]
  profile_note[matched] <- targets$profile_note[target_index[matched]]

  interval_status <- vapply(
    seq_len(nrow(pairs)),
    function(i) {
      phase18_correlation_interval_status(
        pair = pairs[i, , drop = FALSE],
        matched = matched[[i]],
        profile_ready = profile_ready[[i]],
        target_type = target_type[[i]]
      )
    },
    character(1L)
  )
  interval_route <- vapply(
    seq_len(nrow(pairs)),
    function(i) {
      phase18_correlation_interval_route(
        pair = pairs[i, , drop = FALSE],
        interval_status = interval_status[[i]]
      )
    },
    character(1L)
  )

  out <- data.frame(
    artifact_grain = "inventory",
    level = pairs$level,
    group = pairs$group,
    block = pairs$block,
    from_dpar = pairs$from_dpar,
    to_dpar = pairs$to_dpar,
    class = pairs$class,
    parameter = pairs$parameter,
    estimate = pairs$estimate,
    min = pairs$min,
    max = pairs$max,
    n_values = pairs$n_values,
    modelled = pairs$modelled,
    profile_target = profile_target,
    target_type = target_type,
    profile_ready = profile_ready,
    profile_note = profile_note,
    interval_route = interval_route,
    interval_status = interval_status,
    stringsAsFactors = FALSE
  )
  row.names(out) <- NULL
  out
}

phase18_match_correlation_profile_targets <- function(pairs, targets) {
  if (nrow(pairs) == 0L) {
    return(integer())
  }
  if (nrow(targets) == 0L) {
    return(rep(NA_integer_, nrow(pairs)))
  }

  vapply(
    seq_len(nrow(pairs)),
    function(i) {
      pair <- pairs[i, , drop = FALSE]
      if (
        identical(pair$level[[1L]], "residual") &&
          identical(pair$parameter[[1L]], "rho12") &&
          !isTRUE(pair$modelled[[1L]])
      ) {
        hit <- which(targets$parm == "rho12")
        return(if (length(hit) == 1L) hit[[1L]] else NA_integer_)
      }
      if (
        identical(pair$level[[1L]], "residual") &&
          identical(pair$parameter[[1L]], "rho12")
      ) {
        return(NA_integer_)
      }

      hit <- which(
        targets$target_class == "random-effect-correlation" &
          targets$term == pair$parameter[[1L]]
      )
      if (identical(pair$level[[1L]], "phylogenetic")) {
        hit <- hit[startsWith(targets$parm[hit], "cor:phylo:")]
      } else if (identical(pair$level[[1L]], "group")) {
        hit <- hit[!startsWith(targets$parm[hit], "cor:phylo:")]
      }
      if (length(hit) == 1L) {
        return(hit[[1L]])
      }
      NA_integer_
    },
    integer(1L)
  )
}

phase18_correlation_interval_status <- function(
  pair,
  matched,
  profile_ready,
  target_type
) {
  if (!isTRUE(matched)) {
    if (isTRUE(pair$modelled[[1L]])) {
      return("newdata_required")
    }
    return("target_unavailable")
  }
  if (isTRUE(profile_ready)) {
    return("profile_ready")
  }
  if (identical(target_type, "derived")) {
    return("derived_interval_unavailable")
  }
  "profile_unavailable"
}

phase18_correlation_interval_route <- function(pair, interval_status) {
  if (identical(interval_status, "profile_ready")) {
    return("direct_profile")
  }
  if (identical(interval_status, "newdata_required")) {
    if (identical(pair$level[[1L]], "residual")) {
      return("response_scale_profile_newdata")
    }
    return("corpair_profile_newdata")
  }
  "not_available"
}

phase18_empty_correlation_target_inventory <- function() {
  data.frame(
    artifact_grain = character(),
    level = character(),
    group = character(),
    block = character(),
    from_dpar = character(),
    to_dpar = character(),
    class = character(),
    parameter = character(),
    estimate = numeric(),
    min = numeric(),
    max = numeric(),
    n_values = integer(),
    modelled = logical(),
    profile_target = character(),
    target_type = character(),
    profile_ready = logical(),
    profile_note = character(),
    interval_route = character(),
    interval_status = character(),
    stringsAsFactors = FALSE
  )
}
