phase18_parametric_bootstrap <- function(
  fit,
  statistic_fun,
  refit_fun,
  nsim = 100L,
  seed = NULL,
  cores = 1L,
  backend = "none"
) {
  if (!inherits(fit, "drmTMB")) {
    stop("`fit` must be a drmTMB object.", call. = FALSE)
  }
  phase18_assert_bootstrap_function(statistic_fun, "statistic_fun")
  phase18_assert_bootstrap_function(refit_fun, "refit_fun")
  assert_positive_whole_number(nsim, "nsim")
  if (!is.null(seed)) {
    assert_positive_whole_number(seed, "seed")
  }
  plan <- phase18_bootstrap_parallel_plan(
    nsim = as.integer(nsim),
    cores = cores,
    backend = backend
  )

  simulations <- stats::simulate(fit, nsim = nsim, seed = seed)
  worker <- function(i) {
    phase18_parametric_bootstrap_one(
      fit = fit,
      simulations = simulations,
      index = i,
      statistic_fun = statistic_fun,
      refit_fun = refit_fun
    )
  }
  rows <- phase18_bootstrap_lapply(seq_len(nsim), worker, plan)
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out$bootstrap_backend <- plan$backend
  out$bootstrap_requested_cores <- plan$requested_cores
  out$bootstrap_cores <- plan$cores
  out
}

phase18_parametric_bootstrap_one <- function(
  fit,
  simulations,
  index,
  statistic_fun,
  refit_fun
) {
  tryCatch(
    {
      boot_fit <- refit_fun(
        fit = fit,
        simulations = simulations,
        index = index
      )
      statistic <- statistic_fun(boot_fit)
      phase18_bootstrap_statistic_rows(
        statistic = statistic,
        index = index,
        status = "ok",
        error = NA_character_
      )
    },
    error = function(e) {
      data.frame(
        artifact_grain = "bootstrap",
        bootstrap = index,
        parameter = NA_character_,
        estimate = NA_real_,
        status = "error",
        error = conditionMessage(e),
        stringsAsFactors = FALSE
      )
    }
  )
}

phase18_bootstrap_statistic_rows <- function(
  statistic,
  index,
  status,
  error
) {
  if (!is.numeric(statistic) || length(statistic) == 0L) {
    stop(
      "`statistic_fun()` must return a non-empty numeric vector.",
      call. = FALSE
    )
  }
  if (is.null(names(statistic)) || any(!nzchar(names(statistic)))) {
    names(statistic) <- paste0("statistic_", seq_along(statistic))
  }
  data.frame(
    artifact_grain = "bootstrap",
    bootstrap = index,
    parameter = names(statistic),
    estimate = unname(statistic),
    status = status,
    error = error,
    stringsAsFactors = FALSE
  )
}

phase18_bootstrap_percentile_intervals <- function(
  draws,
  conf.level = 0.95,
  parameter = "parameter",
  estimate = "estimate",
  status = "status"
) {
  if (!is.data.frame(draws) || nrow(draws) == 0L) {
    stop("`draws` must be a non-empty data frame.", call. = FALSE)
  }
  use_status <- !is.null(status) &&
    is.character(status) &&
    length(status) == 1L &&
    nzchar(status)
  required <- c(parameter, estimate, if (use_status) status else character())
  missing <- setdiff(required, names(draws))
  if (length(missing) > 0L) {
    stop(
      "`draws` must contain ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  if (
    !is.numeric(conf.level) ||
      length(conf.level) != 1L ||
      !is.finite(conf.level) ||
      conf.level <= 0 ||
      conf.level >= 1
  ) {
    stop("`conf.level` must be one number between 0 and 1.", call. = FALSE)
  }

  ok <- if (use_status) {
    as.character(draws[[status]]) == "ok"
  } else {
    rep(TRUE, nrow(draws))
  }
  draws <- draws[ok & !is.na(draws[[parameter]]), , drop = FALSE]
  if (nrow(draws) == 0L) {
    return(phase18_empty_bootstrap_intervals(parameter))
  }
  split_key <- as.character(draws[[parameter]])
  pieces <- split(draws, split_key)
  alpha <- 1 - conf.level
  rows <- lapply(pieces, function(x) {
    values <- as.numeric(x[[estimate]])
    values <- values[is.finite(values)]
    interval_ok <- length(values) >= 2L
    qs <- if (interval_ok) {
      stats::quantile(
        values,
        probs = c(alpha / 2, 1 - alpha / 2),
        names = FALSE,
        type = 8
      )
    } else {
      c(NA_real_, NA_real_)
    }
    data.frame(
      parameter = x[[parameter]][[1L]],
      conf.low = qs[[1L]],
      conf.high = qs[[2L]],
      conf.level = conf.level,
      n_bootstrap = length(values),
      interval_method = "parametric_bootstrap",
      interval_scale = "statistic",
      interval_status = if (interval_ok) "ok" else "failed",
      interval_message = if (interval_ok) {
        ""
      } else {
        "fewer than two finite bootstrap estimates"
      },
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_bootstrap_interval_columns <- function(
  summary,
  fit,
  statistic_fun,
  refit_fun,
  nsim = 0L,
  conf.level = 0.70,
  seed = NULL,
  interval_scale = "formula_coefficient",
  cores = 1L,
  backend = "none"
) {
  phase18_assert_summary_columns(summary, c("parameter"))
  if (
    !is.numeric(nsim) ||
      length(nsim) != 1L ||
      is.na(nsim) ||
      nsim < 0 ||
      nsim != as.integer(nsim)
  ) {
    stop("`nsim` must be a non-negative whole number.", call. = FALSE)
  }
  if (
    !is.numeric(conf.level) ||
      length(conf.level) != 1L ||
      !is.finite(conf.level) ||
      conf.level <= 0 ||
      conf.level >= 1
  ) {
    stop("`conf.level` must be one number between 0 and 1.", call. = FALSE)
  }
  if (
    !is.character(interval_scale) ||
      length(interval_scale) != 1L ||
      !nzchar(interval_scale)
  ) {
    stop("`interval_scale` must be one non-empty string.", call. = FALSE)
  }

  out <- phase18_initialise_interval_columns(
    summary,
    prefix = "bootstrap",
    conf.level = conf.level,
    method = "parametric_bootstrap",
    interval_scale = interval_scale,
    default_status = "not_requested"
  )
  out$bootstrap.n <- 0L
  out$bootstrap.backend <- NA_character_
  out$bootstrap.requested_cores <- NA_integer_
  out$bootstrap.cores <- NA_integer_
  if (identical(as.integer(nsim), 0L)) {
    return(out)
  }
  out$bootstrap.status <- "failed"
  out$bootstrap.message <- "no finite bootstrap estimates"

  draws <- phase18_parametric_bootstrap(
    fit = fit,
    statistic_fun = statistic_fun,
    refit_fun = refit_fun,
    nsim = as.integer(nsim),
    seed = seed,
    cores = cores,
    backend = backend
  )
  out$bootstrap.backend <- unique(draws$bootstrap_backend)[[1L]]
  out$bootstrap.requested_cores <- unique(draws$bootstrap_requested_cores)[[1L]]
  out$bootstrap.cores <- unique(draws$bootstrap_cores)[[1L]]
  intervals <- phase18_bootstrap_percentile_intervals(
    draws,
    conf.level = conf.level
  )
  matched <- match(out$parameter, intervals$parameter)
  ok <- !is.na(matched)
  out$bootstrap.conf.low[ok] <- intervals$conf.low[matched[ok]]
  out$bootstrap.conf.high[ok] <- intervals$conf.high[matched[ok]]
  out$bootstrap.status[ok] <- intervals$interval_status[matched[ok]]
  out$bootstrap.message[ok] <- intervals$interval_message[matched[ok]]
  out$bootstrap.n[ok] <- intervals$n_bootstrap[matched[ok]]
  out
}

phase18_bootstrap_parallel_plan <- function(
  nsim,
  cores = 1L,
  backend = "none"
) {
  assert_positive_whole_number(nsim, "nsim")
  assert_positive_whole_number(cores, "cores")
  if (
    !is.character(backend) ||
      length(backend) != 1L ||
      !nzchar(backend)
  ) {
    stop("`backend` must be one non-empty character string.", call. = FALSE)
  }
  if (!backend %in% c("none", "multicore")) {
    stop(
      "`backend` must be either \"none\" or \"multicore\".",
      call. = FALSE
    )
  }
  if (identical(backend, "multicore") && .Platform$OS.type == "windows") {
    stop(
      "`backend = \"multicore\"` is not available on Windows.",
      call. = FALSE
    )
  }

  requested_cores <- as.integer(cores)
  actual_cores <- if (identical(backend, "none")) {
    1L
  } else {
    min(10L, as.integer(nsim), requested_cores)
  }
  list(
    backend = backend,
    requested_cores = requested_cores,
    cores = actual_cores
  )
}

phase18_bootstrap_lapply <- function(indices, worker, plan) {
  if (identical(plan$backend, "none") || identical(plan$cores, 1L)) {
    return(lapply(indices, worker))
  }
  parallel::mclapply(indices, worker, mc.cores = plan$cores)
}

phase18_empty_bootstrap_intervals <- function(parameter) {
  data.frame(
    parameter = character(),
    conf.low = numeric(),
    conf.high = numeric(),
    conf.level = numeric(),
    n_bootstrap = integer(),
    interval_method = character(),
    interval_scale = character(),
    interval_status = character(),
    interval_message = character(),
    stringsAsFactors = FALSE
  )
}

phase18_assert_bootstrap_function <- function(x, name) {
  if (!is.function(x)) {
    stop("`", name, "` must be a function.", call. = FALSE)
  }
  invisible(x)
}
