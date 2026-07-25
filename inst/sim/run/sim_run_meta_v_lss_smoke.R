# Local smoke runner for the Arc 7B/Arc 8 known-V heterogeneity ladder. This
# is evidence plumbing, not a status promoter. The caller must
# preserve every result object and use `phase18_meta_v_lss_all_attempt_summary()`
# rather than filtering to converged fits.

phase18_meta_v_lss_smoke_conditions <- function() {
  data.frame(
    layer = c("LS", "LSS", "LSS", "LSSS", "LSS", "DH"),
    design_role = c(
      "one_effect_per_study", "weak_boundary", "interior_control",
      "nested_effect_control", "dense_known_v_control", "dh_sensitivity"
    ),
    n_study = c(36L, 12L, 48L, 36L, 12L, 36L),
    n_effect_per_study = c(1L, 3L, 4L, 3L, 2L, 4L),
    n_rep_per_effect = c(1L, 2L, 2L, 2L, 2L, 2L),
    known_v_type = c("vector", "vector", "vector", "vector", "dense", "vector"),
    sampling_rho = c(0, 0, 0, 0, 0.25, 0),
    stringsAsFactors = FALSE
  )
}

phase18_meta_v_lss_arc8_conditions <- function() {
  data.frame(
    layer = "LSS",
    design_role = c(
      "dense_k12_historical_failure_control",
      "dense_k12_engineering_control",
      "dense_k36_interior",
      "dense_k72_interior"
    ),
    n_study = c(12L, 12L, 36L, 72L),
    n_effect_per_study = 2L,
    n_rep_per_effect = 2L,
    known_v_type = "dense",
    sampling_rho = c(0.25, 0.20, 0.20, 0.20),
    source_seed = c(1592943833L, NA_integer_, NA_integer_, NA_integer_),
    stringsAsFactors = FALSE
  )
}

phase18_dgp_meta_v_lss_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "layer", "n_study", "n_effect_per_study", "n_rep_per_effect", "known_v_type", "sampling_rho"
  )
  missing <- setdiff(required, names(cell))
  if (length(missing) > 0L) {
    stop("`cell` must contain ", paste(missing, collapse = ", "), ".", call. = FALSE)
  }
  phase18_dgp_meta_v_lss(
    n_study = cell$n_study[[1L]],
    n_effect_per_study = cell$n_effect_per_study[[1L]],
    n_rep_per_effect = cell$n_rep_per_effect[[1L]],
    layer = cell$layer[[1L]],
    known_v_type = cell$known_v_type[[1L]],
    sampling_rho = cell$sampling_rho[[1L]],
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_meta_v_lss <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  V <- attr(data, "V", exact = TRUE)
  if (is.null(V)) stop("`data` must carry known sampling covariance `V`.", call. = FALSE)
  layer <- cell$layer[[1L]]
  formula <- switch(
    layer,
    L = bf(yi ~ x + meta_V(V = V), sigma ~ 1),
    LS = bf(yi ~ x + meta_V(V = V), sigma ~ z),
    LSS = bf(
      yi ~ x + (1 | study) + meta_V(V = V), sigma ~ z,
      sd(study) ~ z_study
    ),
    LSSS = bf(
      yi ~ x + (1 | study) + (1 | effect) + meta_V(V = V), sigma ~ z,
      sd(study) ~ z_study, sd(effect) ~ z_effect
    ),
    DH = bf(
      yi ~ x + (1 | study) + meta_V(V = V), sigma ~ z + (1 | study)
    ),
    stop("Unsupported Arc 7B layer: ", layer, call. = FALSE)
  )
  drmTMB(formula, family = gaussian(), data = data)
}

phase18_meta_v_lss_layer_estimates <- function(fit, layer) {
  out <- numeric()
  if (layer %in% c("LSS", "LSSS")) {
    study <- tryCatch(stats::coef(fit, dpar = "sd(study)"), error = function(e) NULL)
    if (!is.null(study)) out[paste0("sd:study:", names(study))] <- study
  }
  if (identical(layer, "LSSS")) {
    effect <- tryCatch(stats::coef(fit, dpar = "sd(effect)"), error = function(e) NULL)
    if (!is.null(effect)) out[paste0("sd:effect:", names(effect))] <- effect
  }
  if (identical(layer, "DH")) {
    parameters <- tryCatch(summary(fit)$parameters, error = function(e) NULL)
    valid <- !is.null(parameters) && is.data.frame(parameters) &&
      all(c("component", "dpar", "estimate") %in% names(parameters))
    if (valid) {
      dh_row <- parameters$component == "random-effect-sd" & parameters$dpar == "sigma"
      if (any(dh_row)) {
        out[["sd:sigma_study"]] <- parameters$estimate[which(dh_row)[[1L]]]
      }
    }
  }
  out
}

phase18_summarise_meta_v_lss_smoke_fit <- function(
  fit, truth, cell_id, replicate, elapsed, warnings
) {
  layer <- attr(truth, "truth", exact = TRUE)$layer
  out <- phase18_summarise_meta_v_lss_fit(
    fit = fit, truth = truth, cell_id = cell_id, replicate = replicate,
    elapsed = elapsed, warnings = warnings,
    layer_estimates = phase18_meta_v_lss_layer_estimates(fit, layer)
  )
  phase18_meta_v_lss_add_profile_intervals(out, fit)
}

phase18_meta_v_lss_add_profile_intervals <- function(summary, fit) {
  profile_target <- c(
    "mu:(Intercept)" = "fixef:mu:(Intercept)",
    "mu:x" = "fixef:mu:x",
    "sigma:(Intercept)" = "fixef:sigma:(Intercept)",
    "sigma:z" = "fixef:sigma:z",
    "sd:study:(Intercept)" = "fixef:sd(study):(Intercept)",
    "sd:study:z_study" = "fixef:sd(study):z_study",
    "sd:effect:(Intercept)" = "fixef:sd(effect):(Intercept)",
    "sd:effect:z_effect" = "fixef:sd(effect):z_effect"
  )
  matched <- intersect(summary$parameter, names(profile_target))
  for (parameter in matched) {
    row <- which(summary$parameter == parameter)
    ci <- tryCatch(
      stats::confint(
        fit, parm = profile_target[[parameter]], method = "profile",
        profile_engine = "tmbprofile", profile_precision = "fast"
      ),
      error = function(e) e
    )
    summary$interval_method[row] <- "profile_lr"
    if (inherits(ci, "error") || !is.data.frame(ci) || nrow(ci) != 1L) {
      summary$interval_status[row] <- "failed"
      summary$interval_message[row] <- if (inherits(ci, "error")) conditionMessage(ci) else {
        "profile did not return exactly one target row"
      }
      next
    }
    summary$conf.low[row] <- ci$lower[[1L]]
    summary$conf.high[row] <- ci$upper[[1L]]
    summary$conf.status[row] <- ci$conf.status[[1L]]
    summary$interval_status[row] <- if (
      identical(ci$conf.status[[1L]], "profile") &&
        is.finite(ci$lower[[1L]]) && is.finite(ci$upper[[1L]])
    ) "ok" else "incomplete"
    summary$interval_message[row] <- ci$profile.message[[1L]]
  }
  dh <- summary$parameter == "sd:sigma_study"
  summary$interval_status[dh] <- "not_requested_random_sigma"
  summary$interval_message[dh] <- "random sigma SD has no pre-registered profile target"
  summary
}

phase18_summarise_meta_v_lss_arc8_fit <- function(
  fit, truth, cell_id, replicate, elapsed, warnings,
  bootstrap_R = 199L, bootstrap_seed = NULL,
  bootstrap_parallel = "none", bootstrap_workers = NULL
) {
  layer <- attr(truth, "truth", exact = TRUE)$layer
  out <- phase18_summarise_meta_v_lss_fit(
    fit, truth, cell_id, replicate, elapsed, warnings,
    layer_estimates = phase18_meta_v_lss_layer_estimates(fit, layer)
  )
  out$bootstrap_requested <- NA_integer_
  out$bootstrap_finite_success <- NA_integer_
  out$bootstrap_completion_rate <- NA_real_
  out$bootstrap_status <- NA_character_
  out$bootstrap_complete <- NA
  targets <- c(
    "fixef:sd(study):(Intercept)", "fixef:sd(study):z_study"
  )
  rows <- match(c("sd:study:(Intercept)", "sd:study:z_study"), out$parameter)
  for (i in seq_along(targets)) {
    profile <- tryCatch(
      stats::confint(
        fit, parm = targets[[i]], method = "profile",
        profile_engine = "tmbprofile", profile_precision = "fast"
      ), error = function(e) e
    )
    out$interval_method[rows[[i]]] <- "profile_lr"
    if (inherits(profile, "error") || nrow(profile) != 1L) {
      out$interval_status[rows[[i]]] <- "failed"
      next
    }
    out$conf.low[rows[[i]]] <- profile$lower[[1L]]
    out$conf.high[rows[[i]]] <- profile$upper[[1L]]
    out$conf.status[rows[[i]]] <- profile$conf.status[[1L]]
    contains_estimate <- is.finite(out$estimate[rows[[i]]]) &&
      profile$lower[[1L]] <= out$estimate[rows[[i]]] &&
      out$estimate[rows[[i]]] <= profile$upper[[1L]]
    out$interval_status[rows[[i]]] <- if (
      identical(profile$conf.status[[1L]], "profile") &&
      is.finite(profile$lower[[1L]]) && is.finite(profile$upper[[1L]]) &&
      contains_estimate) "ok" else "incomplete"
  }
  # bootstrap_re_form = NA requests CONDITIONAL simulation: this LSS layer has
  # a modelled (heteroscedastic) `(1|study)` random-effect SD, which marginal
  # simulation does not yet support, so the default would abort. Conditional
  # bootstrap intervals are ANTICONSERVATIVE (between-group variability is not
  # resampled) -- acceptable here ONLY because this runner is smoke-tested for
  # bootstrap accounting/plumbing (requested/finite-success counts, diagnostic
  # columns), not interval coverage. Revisit once marginal draws support a
  # modelled random-effect scale.
  interval <- tryCatch(
    stats::confint(
      fit, parm = targets, method = "bootstrap", R = bootstrap_R,
      seed = bootstrap_seed, parallel = bootstrap_parallel,
      workers = bootstrap_workers, bootstrap_re_form = NA
    ),
    error = function(e) e
  )
  if (inherits(interval, "error")) {
    out$bootstrap_status[rows] <- "bootstrap_error"
    return(out)
  }
  completion <- phase18_meta_v_lss_bootstrap_completion(interval)
  matched <- match(targets, completion$parm)
  out$bootstrap_requested[rows] <- completion$bootstrap_requested[matched]
  out$bootstrap_finite_success[rows] <- completion$bootstrap_finite_success[matched]
  out$bootstrap_completion_rate[rows] <- completion$bootstrap_completion_rate[matched]
  out$bootstrap_status[rows] <- completion$bootstrap_status[matched]
  out$bootstrap_complete[rows] <- completion$bootstrap_complete[matched]
  attr(out, "arc8_bootstrap_diagnostics") <- attr(
    interval, "bootstrap.diagnostics", exact = TRUE
  )
  out
}

phase18_meta_v_lss_bootstrap_completion <- function(
  interval,
  minimum_rate = 0.95
) {
  required <- c("parm", "bootstrap.n", "bootstrap.failed", "conf.status")
  if (!is.data.frame(interval) || !all(required %in% names(interval))) {
    stop("`interval` must be a bootstrap interval table.", call. = FALSE)
  }
  if (!is.numeric(minimum_rate) || length(minimum_rate) != 1L ||
      !is.finite(minimum_rate) || minimum_rate <= 0 || minimum_rate > 1) {
    stop("`minimum_rate` must lie in (0, 1].", call. = FALSE)
  }
  requested <- interval$bootstrap.n + interval$bootstrap.failed
  finite_success <- interval$bootstrap.n
  rate <- ifelse(requested > 0L, finite_success / requested, NA_real_)
  data.frame(
    parm = interval$parm,
    bootstrap_requested = requested,
    bootstrap_finite_success = finite_success,
    bootstrap_completion_rate = rate,
    bootstrap_status = as.character(interval$conf.status),
    bootstrap_complete = is.finite(rate) & rate >= minimum_rate &
      interval$conf.status == "bootstrap",
    stringsAsFactors = FALSE
  )
}

phase18_run_meta_v_lss_smoke <- function(
  conditions = phase18_meta_v_lss_smoke_conditions(),
  n_rep = 1L,
  master_seed = 20260724L,
  result_dir = NULL,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  assert_positive_whole_number(n_rep, "n_rep")
  registry <- phase18_cell_registry(
    surface = "meta_v_lss", conditions = conditions, n_rep = n_rep,
    master_seed = master_seed
  )
  results <- phase18_run_replicates(
    cells = registry$cells, seeds = registry$seeds,
    dgp_fun = phase18_dgp_meta_v_lss_cell,
    fit_fun = phase18_fit_meta_v_lss,
    summarise_fun = phase18_summarise_meta_v_lss_smoke_fit,
    result_dir = result_dir, overwrite = overwrite,
    cores = cores, backend = backend
  )
  summaries <- phase18_result_summaries(results)
  all_attempt <- phase18_meta_v_lss_all_attempt_summary(
    results, registry$cells, summaries, surface = "meta_v_lss"
  )
  list(
    surface = "meta_v_lss", registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results, manifest = phase18_result_manifest(results),
    summary = all_attempt,
    profile_reduction = phase18_meta_v_lss_all_attempt_profile_reduction(all_attempt)
  )
}

phase18_run_meta_v_lss_arc8 <- function(
  conditions = phase18_meta_v_lss_arc8_conditions(), n_rep = 1L,
  master_seed = 2026072508L, bootstrap_R = 199L,
  bootstrap_parallel = "none", bootstrap_workers = NULL,
  result_dir = NULL, overwrite = FALSE, cores = 1L, backend = "none"
) {
  assert_positive_whole_number(n_rep, "n_rep")
  assert_positive_whole_number(bootstrap_R, "bootstrap_R")
  registry <- phase18_cell_registry(
    surface = "meta_v_lss_arc8", conditions = conditions, n_rep = n_rep,
    master_seed = master_seed
  )
  registry <- phase18_meta_v_lss_apply_source_seed(registry, n_rep)
  results <- phase18_run_replicates(
    cells = registry$cells, seeds = registry$seeds,
    dgp_fun = phase18_dgp_meta_v_lss_cell, fit_fun = phase18_fit_meta_v_lss,
    summarise_fun_factory = function(cell, seed_row) {
      function(fit, truth, cell_id, replicate, elapsed, warnings) {
        phase18_summarise_meta_v_lss_arc8_fit(
          fit, truth, cell_id, replicate, elapsed, warnings,
          bootstrap_R = bootstrap_R,
          bootstrap_seed = seed_row$seed[[1L]] + 100000L,
          bootstrap_parallel = bootstrap_parallel,
          bootstrap_workers = bootstrap_workers
        )
      }
    },
    result_dir = result_dir, overwrite = overwrite, cores = cores, backend = backend
  )
  summaries <- phase18_result_summaries(results)
  all_attempt <- phase18_meta_v_lss_all_attempt_summary(
    results, registry$cells, summaries, surface = "meta_v_lss_arc8"
  )
  gate <- phase18_meta_v_lss_arc8_gate(all_attempt)
  list(surface = "meta_v_lss_arc8", registry = registry, results = results,
    manifest = phase18_result_manifest(results), summary = all_attempt,
    profile_reduction = phase18_meta_v_lss_all_attempt_profile_reduction(all_attempt),
    bootstrap_diagnostics = phase18_meta_v_lss_arc8_bootstrap_diagnostics(results),
    gate = gate)
}

phase18_meta_v_lss_apply_source_seed <- function(registry, n_rep) {
  if ("source_seed" %in% names(registry$cells)) {
    if (n_rep != 1L && any(!is.na(registry$cells$source_seed))) {
      stop("A source-pinned Arc 8 control requires `n_rep = 1`.", call. = FALSE)
    }
    source_seed <- registry$cells$source_seed[registry$seeds$cell_index]
    replace <- !is.na(source_seed)
    registry$seeds$seed[replace] <- source_seed[replace]
  }
  registry
}

phase18_meta_v_lss_all_attempt_summary <- function(
  results, cells, summaries, surface = "meta_v_lss"
) {
  if (!is.list(results) || !is.data.frame(cells)) {
    stop("`results` and `cells` must be simulation objects.", call. = FALSE)
  }
  rows <- lapply(results, function(result) {
    cell <- cells[cells$cell_id == result$cell_id, , drop = FALSE]
    truth <- phase18_dgp_meta_v_lss_cell(
      cell, seed = result$seed, cell_id = result$cell_id, replicate = result$replicate
    )
    template <- phase18_meta_v_lss_targets(attr(truth, "truth", exact = TRUE))
    profile_eligible <- template$estimable_by_formula &
      template$parameter != "sd:sigma_study"
    data.frame(
      surface = surface, layer = cell$layer[[1L]],
      known_v_type = cell$known_v_type[[1L]], design_role = cell$design_role[[1L]],
      cell_id = result$cell_id, replicate = result$replicate, seed = result$seed,
      parameter = template$parameter, component = template$component,
      estimable_by_formula = template$estimable_by_formula, truth = template$truth,
      profile_eligible = profile_eligible,
      estimate = NA_real_, std.error = NA_real_, error = NA_real_,
      converged = FALSE, pdHess = FALSE, nobs = NA_real_, elapsed = result$elapsed,
      warning_count = length(result$warnings), warnings = paste(result$warnings, collapse = " | "),
      conf.low = NA_real_, conf.high = NA_real_, interval_method = NA_character_,
      interval_status = ifelse(profile_eligible, "outer_fit_failed", "not_requested"),
      conf.status = NA_character_,
      bootstrap_requested = NA_integer_, bootstrap_finite_success = NA_integer_,
      bootstrap_completion_rate = NA_real_, bootstrap_status = NA_character_,
      bootstrap_complete = NA,
      interval_message = ifelse(
        profile_eligible, "outer fit did not produce a profile interval", NA_character_
      ), result_status = result$status,
      result_error = if (is.null(result$error)) NA_character_ else result$error,
      artifact_grain = "replicate", stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  if (!is.data.frame(summaries) || nrow(summaries) == 0L) return(out)
  key <- paste(out$cell_id, out$replicate, out$parameter, sep = "\r")
  source_key <- paste(summaries$cell_id, summaries$replicate, summaries$parameter, sep = "\r")
  matched <- match(key, source_key)
  replace <- which(!is.na(matched))
  shared <- setdiff(
    intersect(names(out), names(summaries)),
    c("surface", "cell_id", "replicate", "parameter", "seed")
  )
  for (name in shared) out[[name]][replace] <- summaries[[name]][matched[replace]]
  out
}

phase18_meta_v_lss_arc8_bootstrap_diagnostics <- function(results) {
  rows <- lapply(results, function(result) {
    draws <- attr(result$summary, "arc8_bootstrap_diagnostics", exact = TRUE)
    if (!is.data.frame(draws) || nrow(draws) == 0L) return(NULL)
    draws$cell_id <- result$cell_id
    draws$replicate <- result$replicate
    draws$outer_seed <- result$seed
    draws
  })
  rows <- Filter(Negate(is.null), rows)
  if (length(rows) == 0L) return(data.frame())
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_meta_v_lss_arc8_gate <- function(summary) {
  required <- c(
    "surface", "cell_id", "replicate", "parameter", "estimate", "conf.low",
    "conf.high", "interval_status", "bootstrap_complete", "result_status",
    "design_role"
  )
  missing <- setdiff(required, names(summary))
  if (length(missing) > 0L) {
    stop("`summary` is missing ", paste(missing, collapse = ", "), ".", call. = FALSE)
  }
  targets <- c("sd:study:(Intercept)", "sd:study:z_study")
  out <- summary[summary$parameter %in% targets, , drop = FALSE]
  complete_profile <- out$result_status == "ok" & out$interval_status == "ok" &
    is.finite(out$estimate) & is.finite(out$conf.low) & is.finite(out$conf.high) &
    out$conf.low <= out$estimate & out$estimate <= out$conf.high
  out$profile_complete <- complete_profile
  out$target_complete <- complete_profile & !is.na(out$bootstrap_complete) &
    out$bootstrap_complete
  group <- interaction(out$cell_id, out$replicate, drop = TRUE, lex.order = TRUE)
  is_historical_control <- out$design_role == "dense_k12_historical_failure_control"
  out$arc8_complete <- as.logical(ave(
    out$target_complete, group, FUN = function(x) all(x) && length(x) == length(targets)
  ))
  out$expected_control_reproduced <- as.logical(ave(
    out$result_status == "ok" & out$interval_status == "incomplete",
    group, FUN = function(x) all(x) && length(x) == length(targets)
  ))
  out$gate_role <- ifelse(is_historical_control, "negative_control", "interior_feasibility")
  out$gate_pass <- ifelse(
    is_historical_control, out$expected_control_reproduced, out$arc8_complete
  )
  out
}

phase18_meta_v_lss_all_attempt_profile_reduction <- function(summary) {
  required <- c(
    "cell_id", "layer", "design_role", "known_v_type", "parameter", "truth",
    "profile_eligible", "conf.low", "conf.high", "interval_status", "result_status"
  )
  missing <- setdiff(required, names(summary))
  if (length(missing) > 0L) {
    stop("`summary` is missing ", paste(missing, collapse = ", "), ".", call. = FALSE)
  }
  eligible <- summary[summary$profile_eligible, , drop = FALSE]
  if (nrow(eligible) == 0L) return(data.frame())
  key <- interaction(
    eligible$cell_id, eligible$layer, eligible$design_role,
    eligible$known_v_type, eligible$parameter, drop = TRUE, lex.order = TRUE
  )
  rows <- lapply(split(eligible, key), function(x) {
    finite <- is.finite(x$conf.low) & is.finite(x$conf.high)
    complete <- x$interval_status == "ok" & finite
    covering <- complete & x$conf.low <= x$truth & x$truth <= x$conf.high
    data.frame(
      cell_id = x$cell_id[[1L]], layer = x$layer[[1L]],
      design_role = x$design_role[[1L]], known_v_type = x$known_v_type[[1L]],
      parameter = x$parameter[[1L]], attempted = nrow(x),
      outer_fit_ok = sum(x$result_status == "ok"),
      complete_profile = sum(complete), usable_and_covering = sum(covering),
      usable_and_covering_rate = mean(covering), stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}
