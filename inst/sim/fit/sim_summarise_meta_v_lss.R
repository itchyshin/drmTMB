phase18_summarise_meta_v_lss_fit <- function(
  fit,
  truth,
  cell_id = NA_character_,
  replicate = NA_integer_,
  elapsed = NA_real_,
  warnings = character(),
  layer_estimates = numeric()
) {
  if (is.data.frame(truth)) truth <- attr(truth, "truth", exact = TRUE)
  if (!is.list(truth) || !identical(truth$surface, "meta_v_lss")) {
    stop("`truth` must be a meta_V L/LS/LSS/LSSS/DH truth object.", call. = FALSE)
  }
  if (!is.numeric(layer_estimates) ||
      (length(layer_estimates) > 0L && is.null(names(layer_estimates)))) {
    stop("`layer_estimates` must be a named numeric vector.", call. = FALSE)
  }
  target <- phase18_meta_v_lss_targets(truth)
  estimate <- rep(NA_real_, nrow(target))
  names(estimate) <- target$parameter
  estimate[names(layer_estimates)] <- layer_estimates
  estimate <- phase18_meta_v_lss_fill_fixed_estimates(estimate, fit)
  out <- cbind(
    data.frame(
      surface = "meta_v_lss", layer = truth$layer,
      known_v_type = truth$known_v_type, cell_id = cell_id, replicate = replicate,
      parameter = target$parameter, component = target$component,
      estimable_by_formula = target$estimable_by_formula,
      truth = target$truth, estimate = unname(estimate),
      std.error = NA_real_, error = unname(estimate) - target$truth,
      converged = isTRUE(fit$opt$convergence == 0),
      pdHess = isTRUE(fit$sdr$pdHess), nobs = stats::nobs(fit), elapsed = elapsed,
      warning_count = length(warnings), warnings = paste(warnings, collapse = " | "),
      stringsAsFactors = FALSE
    ),
    data.frame(
      conf.low = NA_real_, conf.high = NA_real_, interval_method = NA_character_,
      interval_status = "not_requested", conf.status = NA_character_,
      interval_message = NA_character_, stringsAsFactors = FALSE
    )
  )
  out
}

phase18_meta_v_lss_targets <- function(truth) {
  add <- function(parameter, component, value, estimable) {
    data.frame(parameter = parameter, component = component, truth = unname(value),
      estimable_by_formula = estimable, stringsAsFactors = FALSE)
  }
  out <- rbind(
    add("mu:(Intercept)", "location_fixed", truth$beta_mu[["(Intercept)"]], TRUE),
    add("mu:x", "location_fixed", truth$beta_mu[["x"]], TRUE),
    add("sigma:(Intercept)", "residual_scale", truth$beta_sigma[["(Intercept)"]], TRUE)
  )
  if (truth$layer != "L") out <- rbind(out, add("sigma:z", "residual_scale", truth$beta_sigma[["z"]], TRUE))
  if (truth$layer %in% c("LSS", "LSSS")) out <- rbind(out,
    add("sd:study:(Intercept)", "study_location_sd", truth$beta_sd_study[["(Intercept)"]], TRUE),
    add("sd:study:z_study", "study_location_sd", truth$beta_sd_study[["z_study"]], TRUE)
  )
  if (truth$layer == "LSSS") out <- rbind(out,
    add("sd:effect:(Intercept)", "effect_location_sd", truth$beta_sd_effect[["(Intercept)"]], TRUE),
    add("sd:effect:z_effect", "effect_location_sd", truth$beta_sd_effect[["z_effect"]], TRUE)
  )
  if (truth$layer == "DH") out <- rbind(out,
    add("sd:sigma_study", "study_scale_sd", truth$sd_sigma_study, TRUE)
  )
  rbind(out, add("known_V:sampling_sd", "known_sampling", truth$sampling_sd, FALSE))
}

phase18_meta_v_lss_fill_fixed_estimates <- function(estimate, fit) {
  for (dpar in c("mu", "sigma")) {
    co <- tryCatch(stats::coef(fit, dpar = dpar), error = function(e) NULL)
    if (is.null(co)) next
    keys <- paste0(dpar, ":", names(co))
    matched <- intersect(names(estimate), keys)
    estimate[matched] <- unname(co[sub(paste0("^", dpar, ":"), "", matched)])
  }
  estimate
}
