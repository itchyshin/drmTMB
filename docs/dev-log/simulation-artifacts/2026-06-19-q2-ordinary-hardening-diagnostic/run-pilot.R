args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "docs/dev-log/simulation-artifacts/2026-06-19-q2-ordinary-hardening-diagnostic/run-pilot.R",
    mustWork = TRUE
  )
}

artifact_dir <- dirname(script_path)
repo_root <- normalizePath(
  file.path(artifact_dir, "../../../.."),
  mustWork = TRUE
)
tables_dir <- file.path(artifact_dir, "tables")
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)

suppressPackageStartupMessages(devtools::load_all(repo_root, quiet = TRUE))

master_seed <- 20260619L
n_rep <- as.integer(Sys.getenv("DRMTMB_Q2_N_REP", "100"))
stopifnot(is.finite(n_rep), n_rep >= 1L)
rho_guard <- 0.999999
rho_boundary <- 0.98
run_start_elapsed <- proc.time()[["elapsed"]]

git_lines <- function(...) {
  tryCatch(
    system2("git", c("-C", repo_root, ...), stdout = TRUE, stderr = TRUE),
    warning = function(w) NA_character_,
    error = function(e) NA_character_
  )
}

git_value <- function(...) {
  out <- git_lines(...)
  if (!length(out) || all(is.na(out))) {
    return(NA_character_)
  }
  out[[1L]]
}

capture_fit <- function(expr) {
  warnings <- character()
  value <- withCallingHandlers(
    tryCatch(expr, error = function(e) e),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(value = value, warnings = warnings)
}

max_abs_gradient <- function(fit) {
  gradient <- tryCatch(fit$obj$gr(fit$opt$par), error = function(e) NA_real_)
  if (!is.numeric(gradient) || !any(is.finite(gradient))) {
    return(NA_real_)
  }
  max(abs(gradient), na.rm = TRUE)
}

optimizer_attempt_summary <- function(fit) {
  attempts <- fit$optimizer_attempts
  if (is.null(attempts) || !length(attempts)) {
    return(NA_character_)
  }
  if (is.data.frame(attempts)) {
    return(paste(
      vapply(
        seq_len(nrow(attempts)),
        function(i) {
          paste0(
            attempts$optimizer_preset[[i]],
            ":",
            attempts$optimizer[[i]],
            ":conv=",
            attempts$convergence[[i]],
            ":status=",
            attempts$status[[i]],
            ":obj=",
            signif(attempts$objective[[i]], 6)
          )
        },
        character(1L)
      ),
      collapse = " | "
    ))
  }
  paste(
    vapply(
      attempts,
      function(x) {
        preset <- if (!is.null(x$preset)) x$preset else NA_character_
        convergence <- if (!is.null(x$convergence)) {
          x$convergence
        } else {
          NA_integer_
        }
        objective <- if (!is.null(x$objective)) x$objective else NA_real_
        paste0(preset, ":conv=", convergence, ":obj=", signif(objective, 6))
      },
      character(1L)
    ),
    collapse = " | "
  )
}

optimizer_used_summary <- function(fit) {
  used <- fit$optimizer_used
  if (is.null(used)) {
    return(NA_character_)
  }
  if (is.list(used)) {
    optimizer <- if (!is.null(used$optimizer)) used$optimizer else NA_character_
    preset <- if (!is.null(used$optimizer_preset)) {
      used$optimizer_preset
    } else {
      NA_character_
    }
    attempt <- if (!is.null(used$attempt)) used$attempt else NA_integer_
    convergence <- if (!is.null(used$convergence)) {
      used$convergence
    } else {
      NA_integer_
    }
    retried <- if (!is.null(used$retried)) used$retried else NA
    return(paste0(
      optimizer,
      ":",
      preset,
      ":attempt=",
      attempt,
      ":conv=",
      convergence,
      ":retried=",
      retried
    ))
  }
  as.character(used)
}

q2_control <- function() {
  drm_control(
    optimizer_preset = "default",
    multi_start = 1L,
    fallback_optimizer = NULL
  )
}

first_check_value <- function(checks, check, field) {
  row <- checks[checks$check == check, , drop = FALSE]
  if (nrow(row) == 0L || !field %in% names(row)) {
    return(NA_character_)
  }
  as.character(row[[field]][[1L]])
}

check_status <- function(checks, check) {
  first_check_value(checks, check, "status")
}

check_value <- function(checks, check) {
  first_check_value(checks, check, "value")
}

check_message <- function(checks, check) {
  first_check_value(checks, check, "message")
}

gradient_component <- function(value) {
  out <- sub("^.*component=([^;]+).*$", "\\1", value)
  if (identical(out, value)) {
    return(NA_character_)
  }
  out
}

rho_link <- function(rho) {
  atanh(pmax(pmin(rho / rho_guard, 1 - 1e-12), -1 + 1e-12))
}

rho_response_local <- function(eta) {
  rho_guard * tanh(eta)
}

correlated_effects <- function(n_id, rho) {
  u1 <- stats::rnorm(n_id)
  u2 <- rho * u1 + sqrt(1 - rho^2) * stats::rnorm(n_id)
  list(u1 = u1, u2 = u2)
}

univ_mu_sigma_data <- function(n_id, n_each, rho, seed) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  f <- factor(rep(c("A", "B"), length.out = n))
  u <- correlated_effects(n_id, rho)
  mu <- 0.2 + 0.45 * x + 0.12 * (f == "B") + 0.55 * u$u1[id]
  sigma <- exp(log(0.55) + 0.18 * z - 0.10 * (f == "B") + 0.28 * u$u2[id])
  data.frame(
    y = stats::rnorm(n, mean = mu, sd = sigma),
    x = x,
    z = z,
    f = f,
    id = id,
    stringsAsFactors = FALSE
  )
}

biv_mu_data <- function(n_id, n_each, rho, seed) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  f <- factor(rep(c("A", "B"), length.out = n))
  u <- correlated_effects(n_id, rho)
  e1 <- stats::rnorm(n)
  e2 <- 0.15 * e1 + sqrt(1 - 0.15^2) * stats::rnorm(n)
  data.frame(
    y1 = 0.2 + 0.4 * x + 0.10 * (f == "B") + 0.55 * u$u1[id] + 0.35 * e1,
    y2 = -0.1 - 0.3 * x - 0.08 * (f == "B") + 0.50 * u$u2[id] + 0.38 * e2,
    x = x,
    f = f,
    id = id,
    stringsAsFactors = FALSE
  )
}

biv_sigma_data <- function(n_id, n_each, rho, seed) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  f <- factor(rep(c("A", "B"), length.out = n))
  u <- correlated_effects(n_id, rho)
  e1 <- stats::rnorm(n)
  e2 <- 0.10 * e1 + sqrt(1 - 0.10^2) * stats::rnorm(n)
  sigma1 <- exp(log(0.45) + 0.10 * z + 0.06 * (f == "B") + 0.22 * u$u1[id])
  sigma2 <- exp(log(0.50) - 0.08 * z - 0.06 * (f == "B") + 0.22 * u$u2[id])
  data.frame(
    y1 = 0.2 + 0.35 * x + 0.10 * (f == "B") + sigma1 * e1,
    y2 = -0.1 - 0.25 * x - 0.08 * (f == "B") + sigma2 * e2,
    x = x,
    z = z,
    f = f,
    id = id,
    stringsAsFactors = FALSE
  )
}

fit_route <- function(route, data) {
  if (identical(route, "univ_mu_sigma")) {
    return(drmTMB(
      bf(y ~ x + f + (1 | p | id), sigma ~ z + f + (1 | p | id)),
      family = gaussian(),
      data = data,
      control = q2_control()
    ))
  }
  if (identical(route, "biv_mu")) {
    return(drmTMB(
      bf(
        mu1 = y1 ~ x + f + (1 | p | id),
        mu2 = y2 ~ x + f + (1 | p | id),
        sigma1 = ~1,
        sigma2 = ~1,
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = data,
      control = q2_control()
    ))
  }
  if (identical(route, "biv_sigma")) {
    return(drmTMB(
      bf(
        mu1 = y1 ~ x + f,
        mu2 = y2 ~ x + f,
        sigma1 = ~ z + f + (1 | p | id),
        sigma2 = ~ z + f + (1 | p | id),
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = data,
      control = q2_control()
    ))
  }
  stop("Unknown route: ", route)
}

route_data <- function(route, n_id, n_each, rho, seed) {
  if (identical(route, "univ_mu_sigma")) {
    return(univ_mu_sigma_data(n_id, n_each, rho, seed))
  }
  if (identical(route, "biv_mu")) {
    return(biv_mu_data(n_id, n_each, rho, seed))
  }
  if (identical(route, "biv_sigma")) {
    return(biv_sigma_data(n_id, n_each, rho, seed))
  }
  stop("Unknown route: ", route)
}

route_check <- function(route) {
  switch(
    route,
    univ_mu_sigma = "mu_sigma_random_effect_covariance",
    biv_mu = "biv_mu_random_effect_covariance",
    biv_sigma = "biv_sigma_random_effect_covariance",
    stop("Unknown route: ", route)
  )
}

route_correlation <- function(route, fit) {
  switch(
    route,
    univ_mu_sigma = unname(fit$corpars$mu_sigma[[1L]]),
    biv_mu = unname(fit$corpars$mu[[1L]]),
    biv_sigma = unname(fit$corpars$sigma[[1L]]),
    stop("Unknown route: ", route)
  )
}

route_sd_1 <- function(route, fit) {
  switch(
    route,
    univ_mu_sigma = unname(fit$sdpars$mu[[1L]]),
    biv_mu = unname(fit$sdpars$mu[[1L]]),
    biv_sigma = unname(fit$sdpars$sigma[[1L]]),
    stop("Unknown route: ", route)
  )
}

route_sd_2 <- function(route, fit) {
  switch(
    route,
    univ_mu_sigma = unname(fit$sdpars$sigma[[1L]]),
    biv_mu = unname(fit$sdpars$mu[[2L]]),
    biv_sigma = unname(fit$sdpars$sigma[[2L]]),
    stop("Unknown route: ", route)
  )
}

source_grid <- data.frame(
  target = c(
    "negative_high",
    "negative_edge",
    "zero",
    "moderate",
    "positive_edge",
    "positive_high",
    "positive_boundary"
  ),
  rho_true = c(-0.95, -0.80, 0, 0.40, 0.80, 0.95, 0.98),
  purpose = c(
    "negative near-boundary stress",
    "strong negative ordinary edge",
    "false boundary-warning screen",
    "ordinary moderate positive correlation",
    "strong positive ordinary edge",
    "positive near-boundary stress",
    "fitted-boundary visibility at check_drm default"
  ),
  stringsAsFactors = FALSE
)
source_grid$eta_equivalent <- rho_link(source_grid$rho_true)
source_grid$rho_guarded <- rho_response_local(source_grid$eta_equivalent)
source_grid$rho_unguarded <- tanh(source_grid$eta_equivalent)
source_grid$guard_delta <- source_grid$rho_unguarded -
  source_grid$rho_guarded
source_grid$boundary_distance <- 1 - abs(source_grid$rho_guarded)
source_grid$one_minus_rho2 <- 1 - source_grid$rho_guarded^2
source_grid$delta_derivative <- rho_guard *
  (1 - tanh(source_grid$eta_equivalent)^2)

conditions <- do.call(
  rbind,
  list(
    data.frame(
      route = "univ_mu_sigma",
      check_name = route_check("univ_mu_sigma"),
      covariance_route = "univariate mu/sigma random intercept",
      formula_label = "bf(y ~ x + f + (1 | p | id), sigma ~ z + f + (1 | p | id))",
      family = "gaussian",
      response_encoding = "single Gaussian response",
      q_dimension = 2L,
      same_response = TRUE,
      n_id = 34L,
      n_each = 8L,
      rho_true = source_grid$rho_true,
      target = source_grid$target,
      purpose = source_grid$purpose,
      stringsAsFactors = FALSE
    ),
    data.frame(
      route = "biv_mu",
      check_name = route_check("biv_mu"),
      covariance_route = "bivariate mu1/mu2 random intercept",
      formula_label = "bf(mu1 = y1 ~ x + f + (1 | p | id), mu2 = y2 ~ x + f + (1 | p | id), sigma1 = ~ 1, sigma2 = ~ 1, rho12 = ~ 1)",
      family = "biv_gaussian",
      response_encoding = "two Gaussian responses",
      q_dimension = 2L,
      same_response = FALSE,
      n_id = 36L,
      n_each = 8L,
      rho_true = source_grid$rho_true,
      target = source_grid$target,
      purpose = source_grid$purpose,
      stringsAsFactors = FALSE
    ),
    data.frame(
      route = "biv_sigma",
      check_name = route_check("biv_sigma"),
      covariance_route = "bivariate sigma1/sigma2 random intercept",
      formula_label = "bf(mu1 = y1 ~ x + f, mu2 = y2 ~ x + f, sigma1 = ~ z + f + (1 | p | id), sigma2 = ~ z + f + (1 | p | id), rho12 = ~ 1)",
      family = "biv_gaussian",
      response_encoding = "two Gaussian responses",
      q_dimension = 2L,
      same_response = FALSE,
      n_id = 40L,
      n_each = 10L,
      rho_true = source_grid$rho_true,
      target = source_grid$target,
      purpose = source_grid$purpose,
      stringsAsFactors = FALSE
    )
  )
)
conditions$structured <- FALSE
conditions$rho12_random_effect <- FALSE
conditions$cell_id <- paste(conditions$route, conditions$target, sep = "_")
conditions <- conditions[,
  c(
    "cell_id",
    "route",
    "check_name",
    "covariance_route",
    "formula_label",
    "family",
    "response_encoding",
    "q_dimension",
    "same_response",
    "structured",
    "rho12_random_effect",
    "target",
    "purpose",
    "n_id",
    "n_each",
    "rho_true"
  )
]

fit_rows <- list()
check_rows <- list()
failure_rows <- list()
set.seed(master_seed)
replicate_seeds <- sample.int(.Machine$integer.max, nrow(conditions) * n_rep)
seed_index <- 0L

for (i in seq_len(nrow(conditions))) {
  cell <- conditions[i, , drop = FALSE]
  for (replicate_id in seq_len(n_rep)) {
    seed_index <- seed_index + 1L
    seed <- replicate_seeds[[seed_index]]
    data <- route_data(
      route = cell$route[[1L]],
      n_id = cell$n_id[[1L]],
      n_each = cell$n_each[[1L]],
      rho = cell$rho_true[[1L]],
      seed = seed
    )
    start_time <- proc.time()[["elapsed"]]
    result <- capture_fit(fit_route(cell$route[[1L]], data))
    elapsed <- proc.time()[["elapsed"]] - start_time
    fit <- result$value
    if (inherits(fit, "error")) {
      failure_rows[[length(failure_rows) + 1L]] <- data.frame(
        cell_id = cell$cell_id,
        route = cell$route,
        target = cell$target,
        replicate_id = replicate_id,
        seed = seed,
        rho_true = cell$rho_true,
        stage = "fit",
        message = conditionMessage(fit),
        stringsAsFactors = FALSE
      )
      next
    }

    checks <- check_drm(fit, rho_boundary = rho_boundary)
    target_check <- cell$check_name[[1L]]
    covariance_value <- check_value(checks, target_check)
    rho_hat <- route_correlation(cell$route[[1L]], fit)
    eta_hat <- rho_link(rho_hat)
    optimizer_attempts <- fit$optimizer_attempts
    n_optimizer_attempts <- if (is.null(optimizer_attempts)) {
      0L
    } else if (is.data.frame(optimizer_attempts)) {
      nrow(optimizer_attempts)
    } else {
      length(optimizer_attempts)
    }

    fit_rows[[length(fit_rows) + 1L]] <- data.frame(
      evidence_lane = "native_r_tmb",
      direct_julia_claim = FALSE,
      julia_via_r_claim = FALSE,
      cell_id = cell$cell_id,
      route = cell$route,
      check_name = target_check,
      covariance_route = cell$covariance_route,
      formula_label = cell$formula_label,
      family = cell$family,
      response_encoding = cell$response_encoding,
      q_dimension = cell$q_dimension,
      same_response = cell$same_response,
      structured = cell$structured,
      rho12_random_effect = cell$rho12_random_effect,
      target = cell$target,
      purpose = cell$purpose,
      replicate_id = replicate_id,
      seed = seed,
      n_id = cell$n_id,
      n_each = cell$n_each,
      n_obs = nrow(data),
      n_missing_response = sum(!stats::complete.cases(data)),
      factor_balance = paste(
        names(table(data$f)),
        as.integer(table(data$f)),
        sep = "=",
        collapse = ";"
      ),
      rho_true = cell$rho_true,
      eta_true_equivalent = rho_link(cell$rho_true),
      rho_hat = rho_hat,
      eta_hat = eta_hat,
      rho_error = rho_hat - cell$rho_true,
      abs_rho_error = abs(rho_hat - cell$rho_true),
      eta_error = eta_hat - rho_link(cell$rho_true),
      boundary_distance = 1 - abs(rho_hat),
      one_minus_rho2 = 1 - rho_hat^2,
      guard_delta_at_eta_hat = tanh(eta_hat) - rho_response_local(eta_hat),
      delta_derivative_at_eta_hat = rho_guard * (1 - tanh(eta_hat)^2),
      component_sd_1 = route_sd_1(cell$route[[1L]], fit),
      component_sd_2 = route_sd_2(cell$route[[1L]], fit),
      optimizer_preset = "default",
      control_label = "drm_control(default, multi_start=1, fallback=NULL)",
      start_source = "package_default",
      starts_clamped = NA,
      starts_adjusted = NA,
      optimizer_used = optimizer_used_summary(fit),
      n_optimizer_attempts = n_optimizer_attempts,
      optimizer_attempts = optimizer_attempt_summary(fit),
      multi_start = 1L,
      fallback_optimizer = NA_character_,
      retry_count = max(0L, n_optimizer_attempts - 1L),
      profile_requested = FALSE,
      bootstrap_requested = FALSE,
      converged = isTRUE(fit$opt$convergence == 0),
      convergence_code = as.integer(fit$opt$convergence),
      convergence_message = if (!is.null(fit$opt$message)) {
        fit$opt$message
      } else {
        NA_character_
      },
      iterations = if (!is.null(fit$opt$iterations)) {
        fit$opt$iterations
      } else {
        NA_integer_
      },
      function_evaluations = if (!is.null(fit$opt$evaluations)) {
        unname(fit$opt$evaluations[["function"]])
      } else {
        NA_integer_
      },
      gradient_evaluations = if (!is.null(fit$opt$evaluations)) {
        unname(fit$opt$evaluations[["gradient"]])
      } else {
        NA_integer_
      },
      pdHess = isTRUE(fit$sdr$pdHess),
      sdreport_status = check_status(checks, "sdreport_status"),
      max_abs_gradient = max_abs_gradient(fit),
      fixed_gradient_status = check_status(checks, "fixed_gradient"),
      fixed_gradient_value = check_value(checks, "fixed_gradient"),
      fixed_gradient_component = gradient_component(
        check_value(checks, "fixed_gradient")
      ),
      covariance_status = check_status(checks, target_check),
      covariance_value = covariance_value,
      covariance_message = check_message(checks, target_check),
      objective = fit$opt$objective,
      logLik = as.numeric(stats::logLik(fit)),
      AIC = stats::AIC(fit),
      BIC = stats::BIC(fit),
      elapsed = elapsed,
      warning_count = length(result$warnings),
      warnings = paste(result$warnings, collapse = " | "),
      stringsAsFactors = FALSE
    )

    checks$cell_id <- cell$cell_id
    checks$route <- cell$route
    checks$target <- cell$target
    checks$replicate_id <- replicate_id
    checks$seed <- seed
    checks$rho_true <- cell$rho_true
    check_rows[[length(check_rows) + 1L]] <- checks[,
      c(
        "cell_id",
        "route",
        "target",
        "replicate_id",
        "seed",
        "rho_true",
        "check",
        "status",
        "value",
        "message"
      ),
      drop = FALSE
    ]
  }
}

fit_diagnostics <- if (length(fit_rows)) {
  do.call(rbind, fit_rows)
} else {
  data.frame()
}
check_drm_rows <- if (length(check_rows)) {
  do.call(rbind, check_rows)
} else {
  data.frame(
    cell_id = character(),
    route = character(),
    target = character(),
    replicate_id = integer(),
    seed = integer(),
    rho_true = numeric(),
    check = character(),
    status = character(),
    value = character(),
    message = character(),
    stringsAsFactors = FALSE
  )
}
failures <- if (length(failure_rows)) {
  do.call(rbind, failure_rows)
} else {
  data.frame(
    cell_id = character(),
    route = character(),
    target = character(),
    replicate_id = integer(),
    seed = integer(),
    rho_true = numeric(),
    stage = character(),
    message = character(),
    stringsAsFactors = FALSE
  )
}

exposure <- if (nrow(fit_diagnostics)) {
  data.frame(
    cell_id = fit_diagnostics$cell_id,
    route = fit_diagnostics$route,
    check_name = fit_diagnostics$check_name,
    target = fit_diagnostics$target,
    replicate_id = fit_diagnostics$replicate_id,
    seed = fit_diagnostics$seed,
    rho_true = fit_diagnostics$rho_true,
    guard_multiplier = rho_guard,
    rho_boundary = rho_boundary,
    true_abs_rho_max = abs(fit_diagnostics$rho_true),
    fit_abs_rho_max = abs(fit_diagnostics$rho_hat),
    min_1_minus_rho_sq = fit_diagnostics$one_minus_rho2,
    boundary_distance = fit_diagnostics$boundary_distance,
    n_abs_fit_rho_gt_0_90 = as.integer(abs(fit_diagnostics$rho_hat) > 0.90),
    n_abs_fit_rho_gt_0_95 = as.integer(abs(fit_diagnostics$rho_hat) > 0.95),
    n_abs_fit_rho_gt_0_98 = as.integer(abs(fit_diagnostics$rho_hat) > 0.98),
    n_abs_fit_rho_gt_0_99 = as.integer(abs(fit_diagnostics$rho_hat) > 0.99),
    covariance_status = fit_diagnostics$covariance_status,
    covariance_value = fit_diagnostics$covariance_value,
    covariance_message = fit_diagnostics$covariance_message,
    stringsAsFactors = FALSE
  )
} else {
  data.frame()
}

estimate_columns <- c(
  "cell_id",
  "route",
  "target",
  "replicate_id",
  "seed",
  "rho_true",
  "eta_true_equivalent",
  "rho_hat",
  "eta_hat",
  "rho_error",
  "abs_rho_error",
  "eta_error",
  "component_sd_1",
  "component_sd_2",
  "boundary_distance",
  "one_minus_rho2"
)
estimates <- if (nrow(fit_diagnostics)) {
  fit_diagnostics[, estimate_columns, drop = FALSE]
} else {
  data.frame()
}

apply_response_missingness <- function(route, data, seed, prop = 0.05) {
  set.seed(seed)
  n <- nrow(data)
  n_miss <- max(1L, floor(prop * n))
  miss_rows <- sample.int(n, n_miss)
  if (identical(route, "univ_mu_sigma")) {
    data$y[miss_rows] <- NA_real_
  } else {
    split <- ceiling(n_miss / 2)
    data$y1[miss_rows[seq_len(split)]] <- NA_real_
    data$y2[miss_rows[seq(from = split + 1L, to = n_miss)]] <- NA_real_
  }
  data
}

missing_smoke <- do.call(
  rbind,
  lapply(unique(conditions$route), function(route) {
    condition <- conditions[
      conditions$route == route & conditions$target == "moderate",
      ,
      drop = FALSE
    ][1L, , drop = FALSE]
    seed <- master_seed + match(route, unique(conditions$route)) * 100000L
    data <- route_data(
      route = route,
      n_id = condition$n_id[[1L]],
      n_each = condition$n_each[[1L]],
      rho = condition$rho_true[[1L]],
      seed = seed
    )
    data <- apply_response_missingness(route, data, seed + 1L)
    result <- capture_fit(fit_route(route, data))
    if (inherits(result$value, "error")) {
      return(data.frame(
        route = route,
        target = "moderate",
        seed = seed,
        n_obs = nrow(data),
        n_missing_response = sum(!stats::complete.cases(data)),
        fit_error = TRUE,
        converged = NA,
        pdHess = NA,
        dropped_rows_status = NA_character_,
        dropped_rows_value = NA_character_,
        covariance_status = NA_character_,
        message = conditionMessage(result$value),
        stringsAsFactors = FALSE
      ))
    }
    checks <- check_drm(result$value, rho_boundary = rho_boundary)
    data.frame(
      route = route,
      target = "moderate",
      seed = seed,
      n_obs = nrow(data),
      n_missing_response = sum(!stats::complete.cases(data)),
      fit_error = FALSE,
      converged = isTRUE(result$value$opt$convergence == 0),
      pdHess = isTRUE(result$value$sdr$pdHess),
      dropped_rows_status = check_status(checks, "dropped_rows"),
      dropped_rows_value = check_value(checks, "dropped_rows"),
      covariance_status = check_status(checks, condition$check_name[[1L]]),
      message = check_message(checks, "dropped_rows"),
      stringsAsFactors = FALSE
    )
  })
)

status_mcse <- function(x) {
  n <- length(x)
  if (!n) {
    return(NA_real_)
  }
  p <- mean(x, na.rm = TRUE)
  sqrt(p * (1 - p) / n)
}

condition_summary <- if (nrow(conditions)) {
  do.call(
    rbind,
    lapply(seq_len(nrow(conditions)), function(i) {
      condition <- conditions[i, , drop = FALSE]
      rows <- fit_diagnostics[
        fit_diagnostics$cell_id == condition$cell_id,
        ,
        drop = FALSE
      ]
      fail_rows <- failures[
        failures$cell_id == condition$cell_id,
        ,
        drop = FALSE
      ]
      check_cells <- unique(check_drm_rows[
        check_drm_rows$cell_id == condition$cell_id &
          check_drm_rows$status %in% c("warning", "error"),
        c("cell_id", "replicate_id"),
        drop = FALSE
      ])
      n_success <- nrow(rows)
      n_requested <- n_rep
      data.frame(
        cell_id = condition$cell_id,
        route = condition$route,
        check_name = condition$check_name,
        covariance_route = condition$covariance_route,
        target = condition$target,
        rho_true = condition$rho_true,
        n_requested = n_requested,
        n_attempted = n_success + nrow(fail_rows),
        n_fit_error = nrow(fail_rows),
        n_successful_fit = n_success,
        n_warning = if (n_success) sum(rows$warning_count > 0L) else 0L,
        n_converged = if (n_success) sum(rows$converged, na.rm = TRUE) else 0L,
        convergence_rate = if (n_success) mean(rows$converged) else NA_real_,
        convergence_rate_mcse = if (n_success) {
          status_mcse(rows$converged)
        } else {
          NA_real_
        },
        n_pdHess = if (n_success) sum(rows$pdHess, na.rm = TRUE) else 0L,
        pdHess_rate = if (n_success) mean(rows$pdHess) else NA_real_,
        pdHess_rate_mcse = if (n_success) {
          status_mcse(rows$pdHess)
        } else {
          NA_real_
        },
        n_converged_and_pdHess = if (n_success) {
          sum(rows$converged & rows$pdHess, na.rm = TRUE)
        } else {
          0L
        },
        n_gradient_ok = if (n_success) {
          sum(rows$fixed_gradient_status == "ok", na.rm = TRUE)
        } else {
          0L
        },
        fixed_gradient_ok_rate = if (n_success) {
          mean(rows$fixed_gradient_status == "ok", na.rm = TRUE)
        } else {
          NA_real_
        },
        n_check_drm_warning_or_error = nrow(check_cells),
        n_covariance_warning = if (n_success) {
          sum(rows$covariance_status == "warning", na.rm = TRUE)
        } else {
          0L
        },
        covariance_warning_rate = if (n_success) {
          mean(rows$covariance_status == "warning", na.rm = TRUE)
        } else {
          NA_real_
        },
        mean_rho_error = if (n_success) {
          mean(rows$rho_error, na.rm = TRUE)
        } else {
          NA_real_
        },
        mean_rho_error_mcse = if (n_success) {
          stats::sd(rows$rho_error, na.rm = TRUE) / sqrt(n_success)
        } else {
          NA_real_
        },
        rmse_rho = if (n_success) {
          sqrt(mean(rows$rho_error^2, na.rm = TRUE))
        } else {
          NA_real_
        },
        median_abs_rho_error = if (n_success) {
          stats::median(abs(rows$rho_error), na.rm = TRUE)
        } else {
          NA_real_
        },
        q90_abs_rho_error = if (n_success) {
          unname(stats::quantile(abs(rows$rho_error), 0.9, na.rm = TRUE))
        } else {
          NA_real_
        },
        max_abs_rho_error = if (n_success) {
          max(abs(rows$rho_error), na.rm = TRUE)
        } else {
          NA_real_
        },
        min_boundary_distance = if (n_success) {
          min(rows$boundary_distance, na.rm = TRUE)
        } else {
          NA_real_
        },
        max_abs_gradient = if (n_success) {
          max(rows$max_abs_gradient, na.rm = TRUE)
        } else {
          NA_real_
        },
        max_retry_count = if (n_success) {
          max(rows$retry_count, na.rm = TRUE)
        } else {
          NA_integer_
        },
        stringsAsFactors = FALSE
      )
    })
  )
} else {
  data.frame()
}

route_summary <- if (nrow(fit_diagnostics)) {
  do.call(
    rbind,
    lapply(unique(fit_diagnostics$route), function(route) {
      rows <- fit_diagnostics[fit_diagnostics$route == route, , drop = FALSE]
      summary_rows <- condition_summary[
        condition_summary$route == route,
        ,
        drop = FALSE
      ]
      data.frame(
        route = route,
        check_name = rows$check_name[[1L]],
        n_fit = nrow(rows),
        n_converged = sum(rows$converged, na.rm = TRUE),
        n_pdHess = sum(rows$pdHess, na.rm = TRUE),
        n_gradient_ok = sum(rows$fixed_gradient_status == "ok", na.rm = TRUE),
        n_check_drm_warning_or_error = sum(
          summary_rows$n_check_drm_warning_or_error,
          na.rm = TRUE
        ),
        n_covariance_warning = sum(
          rows$covariance_status == "warning",
          na.rm = TRUE
        ),
        n_r_warning = sum(rows$warning_count > 0L, na.rm = TRUE),
        max_abs_fit_rho = max(abs(rows$rho_hat), na.rm = TRUE),
        min_boundary_distance = min(rows$boundary_distance, na.rm = TRUE),
        max_abs_gradient = max(rows$max_abs_gradient, na.rm = TRUE),
        stringsAsFactors = FALSE
      )
    })
  )
} else {
  data.frame()
}

run_summary <- data.frame(
  artifact = basename(artifact_dir),
  timestamp_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  git_sha = git_value("rev-parse", "HEAD"),
  git_branch = git_value("branch", "--show-current"),
  git_dirty = any(nzchar(git_lines("status", "--porcelain"))),
  command = paste(commandArgs(trailingOnly = FALSE), collapse = " "),
  runner_path = script_path,
  master_seed = master_seed,
  rng_kind = paste(RNGkind(), collapse = "/"),
  evidence_lane = "native_r_tmb",
  direct_julia_claim = FALSE,
  julia_via_r_claim = FALSE,
  r_version = R.version.string,
  platform = R.version$platform,
  os_type = .Platform$OS.type,
  machine = Sys.info()[["machine"]],
  matrix_version = as.character(utils::packageVersion("Matrix")),
  tmb_version = as.character(utils::packageVersion("TMB")),
  rcpp_eigen_version = as.character(utils::packageVersion("RcppEigen")),
  drmtmb_version = as.character(utils::packageVersion("drmTMB")),
  n_source_rows = nrow(source_grid),
  n_routes = length(unique(conditions$route)),
  n_fit_cells = nrow(conditions),
  n_replicates_per_cell = n_rep,
  n_requested = nrow(conditions) * n_rep,
  n_attempted = nrow(fit_diagnostics) + nrow(failures),
  n_fit_errors = nrow(failures),
  n_converged = if (nrow(fit_diagnostics)) {
    sum(fit_diagnostics$converged)
  } else {
    0L
  },
  n_pdHess = if (nrow(fit_diagnostics)) sum(fit_diagnostics$pdHess) else 0L,
  n_converged_and_pdHess = if (nrow(condition_summary)) {
    sum(condition_summary$n_converged_and_pdHess)
  } else {
    0L
  },
  n_gradient_ok = if (nrow(condition_summary)) {
    sum(condition_summary$n_gradient_ok)
  } else {
    0L
  },
  n_check_drm_warning_or_error = if (nrow(condition_summary)) {
    sum(condition_summary$n_check_drm_warning_or_error)
  } else {
    0L
  },
  n_covariance_warnings = if (nrow(condition_summary)) {
    sum(condition_summary$n_covariance_warning)
  } else {
    0L
  },
  max_abs_rho_error = if (nrow(fit_diagnostics)) {
    max(abs(fit_diagnostics$rho_error), na.rm = TRUE)
  } else {
    NA_real_
  },
  max_abs_gradient = if (nrow(fit_diagnostics)) {
    max(fit_diagnostics$max_abs_gradient, na.rm = TRUE)
  } else {
    NA_real_
  },
  min_boundary_distance = if (nrow(fit_diagnostics)) {
    min(fit_diagnostics$boundary_distance, na.rm = TRUE)
  } else {
    NA_real_
  },
  max_retry_count = if (nrow(fit_diagnostics)) {
    max(fit_diagnostics$retry_count, na.rm = TRUE)
  } else {
    NA_integer_
  },
  elapsed_total = proc.time()[["elapsed"]] - run_start_elapsed,
  stringsAsFactors = FALSE
)

write.csv(
  source_grid,
  file.path(tables_dir, "q2-ordinary-covariance-source-grid.csv"),
  row.names = FALSE
)
write.csv(
  conditions,
  file.path(tables_dir, "q2-ordinary-covariance-conditions.csv"),
  row.names = FALSE
)
write.csv(
  fit_diagnostics,
  file.path(tables_dir, "q2-ordinary-covariance-fit-diagnostics.csv"),
  row.names = FALSE
)
write.csv(
  estimates,
  file.path(tables_dir, "q2-ordinary-covariance-estimates.csv"),
  row.names = FALSE
)
write.csv(
  exposure,
  file.path(tables_dir, "q2-ordinary-covariance-exposure.csv"),
  row.names = FALSE
)
write.csv(
  condition_summary,
  file.path(tables_dir, "q2-ordinary-covariance-recovery-summary.csv"),
  row.names = FALSE
)
write.csv(
  route_summary,
  file.path(tables_dir, "q2-ordinary-covariance-status-summary.csv"),
  row.names = FALSE
)
write.csv(
  check_drm_rows,
  file.path(tables_dir, "q2-ordinary-covariance-check-drm.csv"),
  row.names = FALSE
)
write.csv(
  failures,
  file.path(tables_dir, "q2-ordinary-covariance-failures.csv"),
  row.names = FALSE
)
write.csv(
  missing_smoke,
  file.path(tables_dir, "q2-ordinary-covariance-missing-factor-smoke.csv"),
  row.names = FALSE
)
write.csv(
  run_summary,
  file.path(artifact_dir, "q2-ordinary-covariance-run-summary.csv"),
  row.names = FALSE
)
session_info <- sub("[[:space:]]+$", "", capture.output(sessionInfo()))
writeLines(
  c(
    paste0("artifact: ", basename(artifact_dir)),
    paste0("timestamp_utc: ", run_summary$timestamp_utc),
    paste0("git_sha: ", run_summary$git_sha),
    paste0("git_branch: ", run_summary$git_branch),
    paste0("git_dirty: ", run_summary$git_dirty),
    paste0("command: ", run_summary$command),
    paste0("evidence_lane: ", run_summary$evidence_lane),
    paste0("direct_julia_claim: ", run_summary$direct_julia_claim),
    paste0("julia_via_r_claim: ", run_summary$julia_via_r_claim),
    "",
    session_info
  ),
  file.path(artifact_dir, "session-info.txt")
)

cat("q2 ordinary covariance hardening diagnostic complete\n")
print(run_summary)
