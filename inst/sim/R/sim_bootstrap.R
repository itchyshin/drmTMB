phase18_parametric_bootstrap <- function(
  fit,
  statistic_fun,
  refit_fun,
  nsim = 100L,
  seed = NULL
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

  simulations <- stats::simulate(fit, nsim = nsim, seed = seed)
  rows <- lapply(seq_len(nsim), function(i) {
    phase18_parametric_bootstrap_one(
      fit = fit,
      simulations = simulations,
      index = i,
      statistic_fun = statistic_fun,
      refit_fun = refit_fun
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
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
