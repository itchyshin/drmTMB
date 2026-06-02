# Phase 18 power helpers.
#
# These functions turn the Phase 18 recovery harness into a power engine. They
# are surface-agnostic and reuse the uncertainty helpers in sim_uncertainty.R
# (phase18_mcse_proportion, phase18_default_summary_groups, the assertion
# helpers), so they must be sourced after sim_uncertainty.R. The design contract
# is docs/design/154-phase-18-power-simulation-plan.md.

# Build an effect-size sweep from an existing condition grid. Each value in
# `effect_values` produces a copy of `base` with column `effect_name` set to that
# value, plus bookkeeping columns `effect_name`, `effect_size`, `null_value`, and
# `is_null`. The `null_value` cell (where the swept effect equals the null) is the
# Type I error cell; the others are power cells.
phase18_power_grid_conditions <- function(
  base,
  effect_name,
  effect_values,
  null_value = 0
) {
  if (!is.data.frame(base) || nrow(base) == 0L) {
    stop("`base` must be a non-empty condition data frame.", call. = FALSE)
  }
  if (
    !is.character(effect_name) ||
      length(effect_name) != 1L ||
      !nzchar(effect_name)
  ) {
    stop("`effect_name` must be one non-empty string.", call. = FALSE)
  }
  if (!effect_name %in% names(base)) {
    stop(
      sprintf("`effect_name` '%s' is not a column of `base`.", effect_name),
      call. = FALSE
    )
  }
  effect_values <- phase18_finite_numeric_vector(effect_values, "effect_values")
  if (
    !is.numeric(null_value) ||
      length(null_value) != 1L ||
      !is.finite(null_value)
  ) {
    stop("`null_value` must be one finite number.", call. = FALSE)
  }

  pieces <- lapply(effect_values, function(value) {
    block <- base
    block[[effect_name]] <- value
    block$effect_name <- effect_name
    block$effect_size <- value
    block$null_value <- null_value
    block$is_null <- isTRUE(all.equal(value, null_value))
    block
  })
  out <- do.call(rbind, pieces)
  row.names(out) <- NULL
  out
}

# Per-cell power: the share of usable intervals that exclude the null. Reuses the
# interval_status == "ok" filter from the coverage helper and the binomial MCSE.
# `null_value` is one number applied to every row, or a named numeric vector keyed
# by `parameter` (unmatched parameters are dropped from the power count).
phase18_summarise_power <- function(
  summary,
  by = NULL,
  null_value = 0,
  lower = "conf.low",
  upper = "conf.high"
) {
  phase18_assert_summary_columns(summary, c("parameter", lower, upper))
  if (is.null(by)) {
    by <- phase18_default_summary_groups(summary)
  }
  phase18_assert_group_columns(summary, by)
  null_for_row <- phase18_power_null_for_rows(summary$parameter, null_value)

  split_key <- interaction(summary[by], drop = TRUE, lex.order = TRUE)
  pieces <- split(summary, split_key)
  null_pieces <- split(null_for_row, split_key)
  rows <- Map(
    function(x, null) {
      lower_value <- as.numeric(x[[lower]])
      upper_value <- as.numeric(x[[upper]])
      usable <- is.finite(lower_value) & is.finite(upper_value) & is.finite(null)
      if ("interval_status" %in% names(x)) {
        usable <- usable & as.character(x$interval_status) == "ok"
      }
      reject <- usable & (null < lower_value | null > upper_value)
      reject_usable <- reject[usable]
      n_usable <- sum(usable)

      data.frame(
        x[1L, by, drop = FALSE],
        null_value = null[1L],
        inference = phase18_power_inference_label(x, null, usable),
        n_replicate = nrow(x),
        n_interval = n_usable,
        n_reject = sum(reject),
        power = if (n_usable == 0L) NA_real_ else mean(reject_usable),
        power_mcse = if (n_usable == 0L) {
          NA_real_
        } else {
          phase18_mcse_proportion(reject_usable)
        },
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
    },
    pieces,
    null_pieces
  )
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

# Read a target sample size off the simulated power curve. This interpolates the
# observed (sample_size, power) points within each effect-size group; it is not a
# closed-form power calculation. Status is one of "interpolated", "achieved_at_min",
# "below_grid", or "no_data".
phase18_power_target_sample_size <- function(
  power_table,
  target_power = 0.8,
  sample_size = "n",
  power_col = "power",
  by = NULL
) {
  phase18_assert_summary_columns(power_table, c(sample_size, power_col))
  if (
    !is.numeric(target_power) ||
      length(target_power) != 1L ||
      !is.finite(target_power) ||
      target_power <= 0 ||
      target_power >= 1
  ) {
    stop("`target_power` must be one number between 0 and 1.", call. = FALSE)
  }
  if (is.null(by)) {
    by <- intersect(
      c("surface", "parameter", "effect_size"),
      names(power_table)
    )
  }
  added_group <- FALSE
  if (length(by) == 0L) {
    power_table$.power_group <- "all"
    by <- ".power_group"
    added_group <- TRUE
  }
  phase18_assert_group_columns(power_table, by)

  split_key <- interaction(power_table[by], drop = TRUE, lex.order = TRUE)
  pieces <- split(power_table, split_key)
  report_by <- setdiff(by, ".power_group")
  rows <- lapply(pieces, function(x) {
    n <- as.numeric(x[[sample_size]])
    power <- as.numeric(x[[power_col]])
    keep <- is.finite(n) & is.finite(power)
    res <- phase18_interpolate_threshold(n[keep], power[keep], target_power)
    base_cols <- if (length(report_by) == 0L) {
      x[1L, character(0), drop = FALSE]
    } else {
      x[1L, report_by, drop = FALSE]
    }
    data.frame(
      base_cols,
      target_power = target_power,
      n_target = res$n_target,
      status = res$status,
      n_grid_min = res$n_grid_min,
      n_grid_max = res$n_grid_max,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  if (added_group) {
    out$.power_group <- NULL
  }
  out
}

# --- internal helpers -------------------------------------------------------

phase18_power_null_for_rows <- function(parameter, null_value) {
  if (!is.numeric(null_value) || length(null_value) == 0L) {
    stop(
      "`null_value` must be one number or a named numeric vector keyed by parameter.",
      call. = FALSE
    )
  }
  # A named vector is a per-parameter map, even when it has a single entry;
  # check names before treating a length-1 value as a scalar applied to all.
  if (!is.null(names(null_value))) {
    return(unname(null_value[as.character(parameter)]))
  }
  if (length(null_value) == 1L && is.finite(null_value)) {
    return(rep(null_value, length(parameter)))
  }
  stop(
    "`null_value` must be one number or a named numeric vector keyed by parameter.",
    call. = FALSE
  )
}

phase18_power_inference_label <- function(x, null, usable) {
  if (!any(usable)) {
    return(NA_character_)
  }
  if ("is_null" %in% names(x)) {
    flag <- as.logical(x$is_null)[usable]
    if (all(flag %in% TRUE)) {
      return("type_i_error")
    }
    if (all(flag %in% FALSE)) {
      return("power")
    }
    return("mixed")
  }
  if ("truth" %in% names(x)) {
    truth <- as.numeric(x$truth)[usable]
    near_null <- abs(truth - null[usable]) < 1e-8
    if (all(near_null)) {
      return("type_i_error")
    }
    if (all(!near_null)) {
      return("power")
    }
    return("mixed")
  }
  NA_character_
}

phase18_interpolate_threshold <- function(n, power, target) {
  empty <- list(
    n_target = NA_real_,
    status = "no_data",
    n_grid_min = NA_real_,
    n_grid_max = NA_real_
  )
  if (length(n) == 0L) {
    return(empty)
  }
  ord <- order(n)
  n <- n[ord]
  power <- power[ord]
  grid_min <- min(n)
  grid_max <- max(n)

  if (power[1L] >= target) {
    return(list(
      n_target = n[1L],
      status = "achieved_at_min",
      n_grid_min = grid_min,
      n_grid_max = grid_max
    ))
  }
  if (max(power) < target) {
    return(list(
      n_target = NA_real_,
      status = "below_grid",
      n_grid_min = grid_min,
      n_grid_max = grid_max
    ))
  }

  cross <- which(power >= target)[1L]
  lo_n <- n[cross - 1L]
  hi_n <- n[cross]
  lo_p <- power[cross - 1L]
  hi_p <- power[cross]
  n_target <- if (isTRUE(all.equal(hi_p, lo_p))) {
    hi_n
  } else {
    lo_n + (target - lo_p) / (hi_p - lo_p) * (hi_n - lo_n)
  }
  list(
    n_target = n_target,
    status = "interpolated",
    n_grid_min = grid_min,
    n_grid_max = grid_max
  )
}
