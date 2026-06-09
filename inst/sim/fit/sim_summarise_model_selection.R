phase18_fit_model_selection <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  candidate_set <- cell$candidate_set[[1L]]
  if (identical(candidate_set, "gaussian_student")) {
    return(list(
      phase18_fit_model_selection_candidate(
        candidate = "Gaussian",
        quote(drmTMB(
          bf(y ~ x, sigma ~ 1),
          family = gaussian(),
          data = data
        ))
      ),
      phase18_fit_model_selection_candidate(
        candidate = "Student-t",
        quote(drmTMB(
          bf(y ~ x, sigma ~ 1, nu ~ 1),
          family = student(),
          data = data
        ))
      )
    ))
  }
  if (identical(candidate_set, "nb2_zinb2")) {
    return(list(
      phase18_fit_model_selection_candidate(
        candidate = "NB2",
        quote(drmTMB(
          bf(count ~ x, sigma ~ 1),
          family = nbinom2(),
          data = data
        ))
      ),
      phase18_fit_model_selection_candidate(
        candidate = "ZINB2",
        quote(drmTMB(
          bf(count ~ x, sigma ~ 1, zi ~ 1),
          family = nbinom2(),
          data = data
        ))
      )
    ))
  }
  if (identical(candidate_set, "sigma_formula")) {
    return(list(
      phase18_fit_model_selection_candidate(
        candidate = "sigma ~ 1",
        quote(drmTMB(
          bf(y ~ x, sigma ~ 1),
          family = gaussian(),
          data = data
        ))
      ),
      phase18_fit_model_selection_candidate(
        candidate = "sigma ~ x",
        quote(drmTMB(
          bf(y ~ x, sigma ~ x),
          family = gaussian(),
          data = data
        ))
      )
    ))
  }
  stop("Unknown model-selection candidate set.", call. = FALSE)
}

phase18_fit_model_selection_candidate <- function(candidate, expr) {
  warnings <- character()
  started <- proc.time()[["elapsed"]]
  value <- withCallingHandlers(
    tryCatch(eval(expr, envir = parent.frame()), error = function(e) e),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  elapsed <- proc.time()[["elapsed"]] - started
  if (inherits(value, "error")) {
    return(list(
      candidate = candidate,
      status = "error",
      fit = NULL,
      aic = NA_real_,
      bic = NA_real_,
      logLik = NA_real_,
      df = NA_real_,
      nobs = NA_integer_,
      converged = FALSE,
      pdHess = FALSE,
      elapsed = elapsed,
      warnings = unique(warnings),
      error = conditionMessage(value)
    ))
  }
  ll <- stats::logLik(value)
  list(
    candidate = candidate,
    status = "ok",
    fit = value,
    aic = as.numeric(stats::AIC(value)),
    bic = as.numeric(stats::BIC(value)),
    logLik = as.numeric(ll),
    df = as.numeric(attr(ll, "df")),
    nobs = stats::nobs(value),
    converged = isTRUE(value$opt$convergence == 0),
    pdHess = isTRUE(value$sdr$pdHess),
    elapsed = elapsed,
    warnings = unique(warnings),
    error = NA_character_
  )
}

phase18_summarise_model_selection_fit <- function(
    fit,
    truth,
    cell_id = NA_character_,
    replicate = NA_integer_,
    elapsed = NA_real_,
    warnings = character()) {
  if (is.data.frame(truth)) {
    truth <- attr(truth, "truth", exact = TRUE)
  }
  if (!is.list(truth) || !identical(truth$surface, "model_selection")) {
    stop(
      "`truth` must be a model-selection truth object.",
      call. = FALSE
    )
  }
  rows <- lapply(fit, phase18_model_selection_candidate_row)
  out <- do.call(rbind, rows)
  out$surface <- "model_selection"
  out$artifact_grain <- "replicate"
  out$cell_id <- cell_id
  out$replicate <- replicate
  out$scenario <- truth$scenario
  out$candidate_set <- truth$candidate_set
  out$selection_target <- truth$selection_target
  out$response_family <- truth$response_family
  out$outer_elapsed <- elapsed
  out$outer_warning_count <- length(warnings)
  out$outer_warnings <- paste(warnings, collapse = " | ")
  out <- phase18_model_selection_add_choices(out)
  out[c(
    "surface",
    "artifact_grain",
    "cell_id",
    "replicate",
    "scenario",
    "candidate_set",
    "selection_target",
    "response_family",
    "candidate",
    "status",
    "aic",
    "bic",
    "delta_aic",
    "delta_bic",
    "selected_aic",
    "selected_bic",
    "truth_selected_aic",
    "truth_selected_bic",
    "logLik",
    "df",
    "nobs",
    "converged",
    "pdHess",
    "elapsed",
    "warning_count",
    "warnings",
    "error",
    "outer_elapsed",
    "outer_warning_count",
    "outer_warnings"
  )]
}

phase18_model_selection_candidate_row <- function(record) {
  data.frame(
    candidate = record$candidate,
    status = record$status,
    aic = record$aic,
    bic = record$bic,
    logLik = record$logLik,
    df = record$df,
    nobs = record$nobs,
    converged = record$converged,
    pdHess = record$pdHess,
    elapsed = record$elapsed,
    warning_count = length(record$warnings),
    warnings = paste(record$warnings, collapse = " | "),
    error = record$error,
    stringsAsFactors = FALSE
  )
}

phase18_model_selection_add_choices <- function(rows) {
  rows$delta_aic <- phase18_model_selection_delta(rows$aic)
  rows$delta_bic <- phase18_model_selection_delta(rows$bic)
  rows$selected_aic <- phase18_model_selection_selected(rows$aic)
  rows$selected_bic <- phase18_model_selection_selected(rows$bic)
  rows$truth_selected_aic <- rows$selected_aic &
    rows$candidate == rows$selection_target
  rows$truth_selected_bic <- rows$selected_bic &
    rows$candidate == rows$selection_target
  rows
}

phase18_model_selection_delta <- function(value) {
  out <- rep(NA_real_, length(value))
  ok <- is.finite(value)
  if (any(ok)) {
    out[ok] <- value[ok] - min(value[ok])
  }
  out
}

phase18_model_selection_selected <- function(value) {
  out <- rep(FALSE, length(value))
  ok <- is.finite(value)
  if (any(ok)) {
    out[which(value == min(value[ok]) & ok)[1L]] <- TRUE
  }
  out
}

phase18_summarise_model_selection_choices <- function(replicates) {
  if (!is.data.frame(replicates) || nrow(replicates) == 0L) {
    stop("`replicates` must be a non-empty data frame.", call. = FALSE)
  }
  required <- c(
    "scenario",
    "candidate_set",
    "selection_target",
    "replicate",
    "candidate",
    "selected_aic",
    "selected_bic",
    "truth_selected_aic",
    "truth_selected_bic",
    "delta_aic",
    "delta_bic",
    "converged",
    "pdHess",
    "warning_count"
  )
  missing <- setdiff(required, names(replicates))
  if (length(missing) > 0L) {
    stop(
      "`replicates` must contain ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  truth_rows <- replicates[
    replicates$candidate == replicates$selection_target, ,
    drop = FALSE
  ]
  groups <- split(
    truth_rows,
    interaction(
      truth_rows$scenario,
      truth_rows$candidate_set,
      truth_rows$selection_target,
      drop = TRUE,
      lex.order = TRUE
    )
  )
  rows <- lapply(groups, function(group) {
    all_group <- replicates[
      replicates$scenario == group$scenario[[1L]] &
        replicates$candidate_set == group$candidate_set[[1L]], ,
      drop = FALSE
    ]
    aic_rate <- mean(group$truth_selected_aic)
    bic_rate <- mean(group$truth_selected_bic)
    n_replicate <- length(unique(group$replicate))
    data.frame(
      surface = "model_selection",
      artifact_grain = "selection_summary",
      scenario = group$scenario[[1L]],
      candidate_set = group$candidate_set[[1L]],
      selection_target = group$selection_target[[1L]],
      n_replicate = n_replicate,
      aic_truth_selection_rate = aic_rate,
      aic_truth_selection_mcse =
        phase18_model_selection_binomial_mcse(aic_rate, n_replicate),
      bic_truth_selection_rate = bic_rate,
      bic_truth_selection_mcse =
        phase18_model_selection_binomial_mcse(bic_rate, n_replicate),
      mean_delta_aic_truth = mean(group$delta_aic, na.rm = TRUE),
      mean_delta_bic_truth = mean(group$delta_bic, na.rm = TRUE),
      candidate_convergence_rate = mean(all_group$converged),
      candidate_pdHess_rate = mean(all_group$pdHess),
      candidate_warning_rate = mean(all_group$warning_count > 0),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_model_selection_binomial_mcse <- function(p, n) {
  if (!is.finite(p) || !is.finite(n) || n <= 0) {
    return(NA_real_)
  }
  sqrt(p * (1 - p) / n)
}
