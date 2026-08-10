#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (!identical(args, c("--stage", "binomial-s0a2"))) {
  stop(
    "Usage: separation-s0a2-cone-spike.R --stage binomial-s0a2",
    call. = FALSE
  )
}

options(warn = 1)

required_versions <- c(
  drmTMB = "0.6.0",
  detectseparation = "0.4.0",
  ROI = "1.0.2",
  ROI.plugin.lpsolve = "1.0.2",
  brglm2 = "1.1.0",
  TMB = "1.9.21"
)
for (pkg in names(required_versions)) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("required package is absent: ", pkg, call. = FALSE)
  }
  observed <- as.character(utils::packageVersion(pkg))
  if (!identical(observed, unname(required_versions[[pkg]]))) {
    stop(
      pkg, " version ", required_versions[[pkg]],
      " is required; found ", observed,
      call. = FALSE
    )
  }
}

tol <- 1e-8
detector_tol <- 1e-4
ray_grid <- c(0, 0.5, 1, 2, 4, 8, 16)
output <- "scratchpad/separation-s0a2-cone-results.tsv"

columns <- c(
  "record_type", "stage", "fixture", "engine", "check", "coefficient",
  "expected", "observed", "status", "detail", "solver_status",
  "solver_objective", "max_residual", "ray", "t", "direct_objective",
  "compiled_objective", "direct_delta", "compiled_delta", "retained_rows",
  "design_columns", "trials_sum", "active_weight_sum", "detector_outcome",
  "detector_class", "warnings", "error", "record_id"
)
records <- list()

clean_text <- function(x) {
  if (is.null(x) || !length(x) || all(is.na(x))) {
    return(NA_character_)
  }
  paste(as.character(x), collapse = " | ")
}

num_text <- function(x) {
  if (is.null(x) || !length(x) || all(is.na(x))) {
    return(NA_character_)
  }
  paste(formatC(as.numeric(x), digits = 17, format = "fg"), collapse = ",")
}

add_record <- function(...) {
  row <- as.list(rep(NA_character_, length(columns)))
  names(row) <- columns
  values <- list(...)
  unknown <- setdiff(names(values), columns)
  if (length(unknown)) {
    stop("unknown result columns: ", paste(unknown, collapse = ", "), call. = FALSE)
  }
  for (nm in names(values)) {
    row[[nm]] <- clean_text(values[[nm]])
  }
  row$record_id <- sprintf("s0a2-%04d", length(records) + 1L)
  records[[length(records) + 1L]] <<- as.data.frame(
    row,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  invisible(NULL)
}

write_results <- function() {
  if (!length(records)) {
    add_record(
      record_type = "system", stage = "binomial-s0a2",
      fixture = "none", engine = "harness", check = "empty_result_guard",
      expected = "nonempty", observed = "empty", status = "FAIL"
    )
  }
  result <- do.call(rbind, records)
  utils::write.table(
    result,
    output,
    sep = "\t",
    row.names = FALSE,
    col.names = TRUE,
    quote = TRUE,
    na = ""
  )
  invisible(result)
}

capture_conditions <- function(expr) {
  warnings <- character()
  error <- NULL
  value <- withCallingHandlers(
    tryCatch(
      expr,
      error = function(e) {
        error <<- conditionMessage(e)
        NULL
      }
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(
    value = value,
    warnings = clean_text(warnings),
    error = error
  )
}

sign_set <- function(negative, zero, positive) {
  c(negative = negative, zero = zero, positive = positive)
}

fixture <- function(
    id,
    data,
    formula,
    expected_class,
    expected_signs = NULL,
    rays = list(),
    weight = NULL,
    missing_include = FALSE,
    rank_deficient = FALSE,
    control_expected = NULL) {
  list(
    id = id,
    data = data,
    formula = formula,
    expected_class = expected_class,
    expected_signs = expected_signs,
    rays = rays,
    weight = weight,
    missing_include = missing_include,
    rank_deficient = rank_deficient,
    control_expected = control_expected
  )
}

core_fixtures <- list(
  fixture(
    "mu_overlap",
    data.frame(
      y01 = c(0L, 1L, 0L, 1L, 0L, 1L),
      x = c(-1, -1, 0, 0, 1, 1)
    ),
    y01 ~ x,
    "none",
    rays = list(
      intercept_positive = c(1, 0),
      intercept_negative = c(-1, 0),
      slope_positive = c(0, 1),
      slope_negative = c(0, -1)
    )
  ),
  fixture(
    "mu_complete_shifted_forced",
    data.frame(y01 = c(0L, 0L, 1L, 1L), x = 0:3),
    y01 ~ x,
    "complete",
    list(
      "(Intercept)" = sign_set(TRUE, FALSE, FALSE),
      x = sign_set(FALSE, FALSE, TRUE)
    ),
    list(shifted_forced = c(-3, 2))
  ),
  fixture(
    "mu_complete_shifted_forced_mirror",
    data.frame(y01 = c(1L, 1L, 0L, 0L), x = 0:3),
    y01 ~ x,
    "complete",
    list(
      "(Intercept)" = sign_set(FALSE, FALSE, TRUE),
      x = sign_set(TRUE, FALSE, FALSE)
    ),
    list(shifted_forced_mirror = c(3, -2))
  ),
  fixture(
    "mu_complete_centered_ambiguous",
    data.frame(y01 = c(0L, 0L, 1L, 1L), x = c(-2, -1, 1, 2)),
    y01 ~ x,
    "complete",
    list(
      "(Intercept)" = sign_set(TRUE, TRUE, TRUE),
      x = sign_set(FALSE, FALSE, TRUE)
    ),
    list(
      centered_intercept_negative = c(-1, 2),
      centered_intercept_zero = c(0, 1),
      centered_intercept_positive = c(1, 2)
    )
  ),
  fixture(
    "mu_quasi",
    data.frame(y01 = c(0L, 0L, 1L, 1L), x = c(-1, 0, 0, 1)),
    y01 ~ x,
    "quasi_complete",
    list(
      "(Intercept)" = sign_set(FALSE, TRUE, FALSE),
      x = sign_set(FALSE, FALSE, TRUE)
    ),
    list(quasi = c(0, 1))
  ),
  fixture(
    "mu_intercept_all_success",
    data.frame(y01 = rep(1L, 4L)),
    y01 ~ 1,
    "complete",
    list("(Intercept)" = sign_set(FALSE, FALSE, TRUE)),
    list(all_success = 1)
  ),
  fixture(
    "mu_intercept_all_failure",
    data.frame(y01 = rep(0L, 4L)),
    y01 ~ 1,
    "complete",
    list("(Intercept)" = sign_set(TRUE, FALSE, FALSE)),
    list(all_failure = -1)
  ),
  fixture(
    "mu_quasi_expanded",
    data.frame(
      y01 = c(0L, 0L, 0L, 1L, 1L, 1L),
      x = c(-1, -1, 0, 0, 1, 1)
    ),
    y01 ~ x,
    "quasi_complete",
    list(
      "(Intercept)" = sign_set(FALSE, TRUE, FALSE),
      x = sign_set(FALSE, FALSE, TRUE)
    ),
    list(quasi_expanded = c(0, 1))
  ),
  fixture(
    "mu_quasi_grouped",
    data.frame(
      success = c(0L, 1L, 2L),
      failure = c(2L, 1L, 0L),
      x = c(-1, 0, 1)
    ),
    cbind(success, failure) ~ x,
    "quasi_complete",
    list(
      "(Intercept)" = sign_set(FALSE, TRUE, FALSE),
      x = sign_set(FALSE, FALSE, TRUE)
    ),
    list(quasi_grouped = c(0, 1))
  ),
  fixture(
    "rank_deficient_control",
    data.frame(
      y01 = c(0L, 1L, 0L, 1L, 0L, 1L),
      x = c(-1, -1, 0, 0, 1, 1),
      twox = c(-2, -2, 0, 0, 2, 2)
    ),
    y01 ~ x + twox,
    "rank_deficient",
    rank_deficient = TRUE
  )
)

centered_expected <- list(
  X = cbind("(Intercept)" = 1, x = c(-2, -1, 1, 2)),
  y = c(0, 0, 1, 1),
  trials = rep(1, 4),
  weights = rep(1, 4)
)

control_fixtures <- list(
  fixture(
    "mu_zero_weight",
    data.frame(
      y01 = c(0L, 0L, 1L, 1L, 0L),
      x = c(-2, -1, 1, 2, 2),
      w = c(1, 1, 1, 1, 0)
    ),
    y01 ~ x,
    "complete",
    list(
      "(Intercept)" = sign_set(TRUE, TRUE, TRUE),
      x = sign_set(FALSE, FALSE, TRUE)
    ),
    list(
      centered_intercept_negative = c(-1, 2),
      centered_intercept_zero = c(0, 1),
      centered_intercept_positive = c(1, 2)
    ),
    weight = "w",
    control_expected = c(centered_expected, list(offset = rep(0, 4)))
  ),
  fixture(
    "mu_finite_offset",
    data.frame(
      y01 = c(0L, 0L, 1L, 1L),
      x = c(-2, -1, 1, 2),
      off = c(-0.7, 0.2, 0.4, -0.3)
    ),
    y01 ~ x + offset(off),
    "complete",
    list(
      "(Intercept)" = sign_set(TRUE, TRUE, TRUE),
      x = sign_set(FALSE, FALSE, TRUE)
    ),
    list(
      centered_intercept_negative = c(-1, 2),
      centered_intercept_zero = c(0, 1),
      centered_intercept_positive = c(1, 2)
    ),
    control_expected = c(
      centered_expected,
      list(offset = c(-0.7, 0.2, 0.4, -0.3))
    )
  ),
  fixture(
    "mu_response_mask",
    data.frame(
      y01 = c(0L, 0L, 1L, 1L, NA_integer_),
      x = c(-2, -1, 1, 2, 2)
    ),
    y01 ~ x,
    "complete",
    list(
      "(Intercept)" = sign_set(TRUE, TRUE, TRUE),
      x = sign_set(FALSE, FALSE, TRUE)
    ),
    list(
      centered_intercept_negative = c(-1, 2),
      centered_intercept_zero = c(0, 1),
      centered_intercept_positive = c(1, 2)
    ),
    missing_include = TRUE,
    control_expected = c(centered_expected, list(offset = rep(0, 4)))
  )
)

fit_drm <- function(fx) {
  call_args <- list(
    formula = do.call(drmTMB::bf, list(fx$formula)),
    family = stats::binomial(),
    data = fx$data
  )
  if (!is.null(fx$weight)) {
    call_args$weights <- fx$data[[fx$weight]]
  }
  if (isTRUE(fx$missing_include)) {
    call_args$missing <- drmTMB::miss_control(response = "include")
  }
  do.call(drmTMB::drmTMB, call_args)
}

extract_spec <- function(fit) {
  observed <- fit$model$missing_data$observed_y
  active <- observed & fit$model$weights > 0 & fit$model$trials > 0
  X <- fit$model$X$mu[active, , drop = FALSE]
  y <- as.numeric(fit$model$y[active])
  trials <- as.numeric(fit$model$trials[active])
  weights <- as.numeric(fit$model$weights[active])
  offset <- as.numeric(fit$model$offset$mu[active])
  if (
    any(!is.finite(X)) || any(!is.finite(y)) ||
      any(!is.finite(trials)) || any(!is.finite(weights)) ||
      any(!is.finite(offset))
  ) {
    stop("non-finite active fitted specification", call. = FALSE)
  }
  if (
    any(trials <= 0) || any(weights <= 0) ||
      any(y < 0) || any(y > trials) ||
      any(abs(y - round(y)) > tol) ||
      any(abs(trials - round(trials)) > tol)
  ) {
    stop("invalid active grouped-binomial specification", call. = FALSE)
  }
  list(
    X = X,
    y = round(y),
    trials = round(trials),
    weights = weights,
    offset = offset,
    active = active
  )
}

expand_spec <- function(spec) {
  X_rows <- list()
  y_rows <- list()
  weight_rows <- list()
  offset_rows <- list()
  source_rows <- list()
  cursor <- 0L
  for (i in seq_len(nrow(spec$X))) {
    n_failure <- spec$trials[[i]] - spec$y[[i]]
    n_success <- spec$y[[i]]
    if (n_failure > 0) {
      cursor <- cursor + 1L
      X_rows[[cursor]] <- spec$X[rep(i, n_failure), , drop = FALSE]
      y_rows[[cursor]] <- rep(0, n_failure)
      weight_rows[[cursor]] <- rep(spec$weights[[i]], n_failure)
      offset_rows[[cursor]] <- rep(spec$offset[[i]], n_failure)
      source_rows[[cursor]] <- rep(i, n_failure)
    }
    if (n_success > 0) {
      cursor <- cursor + 1L
      X_rows[[cursor]] <- spec$X[rep(i, n_success), , drop = FALSE]
      y_rows[[cursor]] <- rep(1, n_success)
      weight_rows[[cursor]] <- rep(spec$weights[[i]], n_success)
      offset_rows[[cursor]] <- rep(spec$offset[[i]], n_success)
      source_rows[[cursor]] <- rep(i, n_success)
    }
  }
  list(
    X = do.call(rbind, X_rows),
    y = unlist(y_rows, use.names = FALSE),
    weights = unlist(weight_rows, use.names = FALSE),
    offset = unlist(offset_rows, use.names = FALSE),
    source_row = unlist(source_rows, use.names = FALSE)
  )
}

build_cone <- function(spec) {
  p <- ncol(spec$X)
  B <- matrix(numeric(), nrow = 0L, ncol = p)
  E <- matrix(numeric(), nrow = 0L, ncol = p)
  B_source <- integer()
  E_source <- integer()
  for (i in seq_len(nrow(spec$X))) {
    if (spec$y[[i]] == 0) {
      B <- rbind(B, -spec$X[i, , drop = FALSE])
      B_source <- c(B_source, i)
    } else if (spec$y[[i]] == spec$trials[[i]]) {
      B <- rbind(B, spec$X[i, , drop = FALSE])
      B_source <- c(B_source, i)
    } else {
      E <- rbind(E, spec$X[i, , drop = FALSE])
      E_source <- c(E_source, i)
    }
  }
  colnames(B) <- colnames(spec$X)
  colnames(E) <- colnames(spec$X)
  list(B = B, E = E, B_source = B_source, E_source = E_source)
}

constraint_residual <- function(L, direction, rhs, solution) {
  lhs <- as.numeric(L %*% solution)
  residual <- numeric(length(rhs))
  residual[direction == ">="] <- pmax(
    rhs[direction == ">="] - lhs[direction == ">="],
    0
  )
  residual[direction == "<="] <- pmax(
    lhs[direction == "<="] - rhs[direction == "<="],
    0
  )
  residual[direction == "=="] <- abs(
    lhs[direction == "=="] - rhs[direction == "=="]
  )
  if (length(residual)) max(residual) else 0
}

solve_cone <- function(cone, sign_index = NULL, sign_mode = NULL) {
  p <- ncol(cone$B)
  L <- matrix(numeric(), nrow = 0L, ncol = p)
  direction <- character()
  rhs <- numeric()
  if (nrow(cone$B)) {
    L <- rbind(L, cone$B)
    direction <- c(direction, rep(">=", nrow(cone$B)))
    rhs <- c(rhs, rep(0, nrow(cone$B)))
  }
  if (nrow(cone$E)) {
    L <- rbind(L, cone$E)
    direction <- c(direction, rep("==", nrow(cone$E)))
    rhs <- c(rhs, rep(0, nrow(cone$E)))
  }
  L <- rbind(L, matrix(colSums(cone$B), nrow = 1L))
  direction <- c(direction, ">=")
  rhs <- c(rhs, 1)
  if (!is.null(sign_index)) {
    sign_row <- numeric(p)
    sign_row[[sign_index]] <- 1
    L <- rbind(L, sign_row)
    if (identical(sign_mode, "positive")) {
      direction <- c(direction, ">=")
      rhs <- c(rhs, 1)
    } else if (identical(sign_mode, "negative")) {
      direction <- c(direction, "<=")
      rhs <- c(rhs, -1)
    } else if (identical(sign_mode, "zero")) {
      direction <- c(direction, "==")
      rhs <- c(rhs, 0)
    } else {
      stop("unknown sign mode", call. = FALSE)
    }
  }
  op <- ROI::OP(
    objective = rep(0, p),
    constraints = ROI::L_constraint(L, direction, rhs),
    types = rep("C", p),
    bounds = ROI::V_bound(
      li = seq_len(p), lb = rep(-Inf, p),
      ui = seq_len(p), ub = rep(Inf, p),
      nobj = p
    ),
    maximum = FALSE
  )
  result <- ROI::ROI_solve(op, solver = "lpsolve")
  status_code <- ROI::solution(result, "status_code")
  solution <- if (identical(status_code, 0L)) {
    as.numeric(ROI::solution(result, "primal"))
  } else {
    rep(NA_real_, p)
  }
  residual <- if (identical(status_code, 0L)) {
    constraint_residual(L, direction, rhs, solution)
  } else {
    NA_real_
  }
  state <- if (identical(status_code, 0L) && residual <= tol) {
    "feasible"
  } else if (identical(status_code, 1L)) {
    "infeasible"
  } else {
    "unresolved"
  }
  list(
    state = state,
    status_code = status_code,
    objective = if (identical(status_code, 0L)) {
      ROI::solution(result, "objval")
    } else {
      NA_real_
    },
    solution = solution,
    residual = residual,
    message = clean_text(ROI::solution(result, "msg"))
  )
}

solve_strict_margin <- function(expanded) {
  X_bar <- expanded$X * (2 * expanded$y - 1)
  p <- ncol(X_bar)
  q <- 2L * p + 1L
  L_margin <- cbind(X_bar, -X_bar, -1)
  L_l1 <- matrix(c(rep(1, 2L * p), 0), nrow = 1L)
  L <- rbind(L_margin, L_l1)
  direction <- c(rep(">=", nrow(L_margin)), "<=")
  rhs <- c(rep(0, nrow(L_margin)), 1)
  objective <- c(rep(0, 2L * p), 1)
  lower <- c(rep(0, 2L * p), -Inf)
  upper <- rep(Inf, q)
  op <- ROI::OP(
    objective = objective,
    constraints = ROI::L_constraint(L, direction, rhs),
    types = rep("C", q),
    bounds = ROI::V_bound(
      li = seq_len(q), lb = lower,
      ui = seq_len(q), ub = upper,
      nobj = q
    ),
    maximum = TRUE
  )
  result <- ROI::ROI_solve(op, solver = "lpsolve")
  status_code <- ROI::solution(result, "status_code")
  solution <- if (identical(status_code, 0L)) {
    as.numeric(ROI::solution(result, "primal"))
  } else {
    rep(NA_real_, q)
  }
  residual <- if (identical(status_code, 0L)) {
    constraint_residual(L, direction, rhs, solution)
  } else {
    NA_real_
  }
  delta <- if (identical(status_code, 0L)) solution[[q]] else NA_real_
  state <- if (
    identical(status_code, 0L) &&
      residual <= tol &&
      is.finite(delta) &&
      delta >= -tol
  ) {
    "solved"
  } else {
    "unresolved"
  }
  list(
    state = state,
    status_code = status_code,
    objective = if (identical(status_code, 0L)) {
      ROI::solution(result, "objval")
    } else {
      NA_real_
    },
    solution = solution,
    delta = delta,
    residual = residual,
    message = clean_text(ROI::solution(result, "msg"))
  )
}

detector_class <- function(detector) {
  if (!isTRUE(detector$outcome)) {
    return("none")
  }
  if (isTRUE(detector$complete)) {
    return("complete")
  }
  if (identical(detector$complete, FALSE)) {
    return("quasi_complete")
  }
  "undetermined"
}

direct_nll <- function(spec, beta) {
  eta <- as.numeric(spec$offset + spec$X %*% beta)
  -sum(
    spec$weights *
      stats::dbinom(
        spec$y,
        size = spec$trials,
        prob = stats::plogis(eta),
        log = TRUE
      )
  )
}

record_fit_symptoms <- function(fx, fit, spec, fit_warnings, fit_error) {
  if (is.null(fit)) {
    add_record(
      record_type = "fit", stage = "binomial-core", fixture = fx$id,
      engine = "drmTMB_ML", check = "fit", expected = "object",
      observed = "error", status = "FAIL", warnings = fit_warnings,
      error = fit_error
    )
    return(FALSE)
  }
  coefficients <- stats::coef(fit, dpar = "mu")
  max_gradient <- capture_conditions(max(abs(fit$obj$gr(fit$opt$par))))
  for (nm in names(coefficients)) {
    add_record(
      record_type = "fit", stage = "binomial-core", fixture = fx$id,
      engine = "drmTMB_ML", check = "coefficient", coefficient = nm,
      observed = num_text(coefficients[[nm]]), status = "RECORDED",
      detail = paste0(
        "convergence=", fit$opt$convergence,
        "; message=", fit$opt$message,
        "; objective=", num_text(fit$opt$objective),
        "; max_gradient=", num_text(max_gradient$value),
        "; pdHess=", clean_text(fit$sdr$pdHess)
      ),
      retained_rows = nrow(spec$X), design_columns = ncol(spec$X),
      trials_sum = sum(spec$trials),
      active_weight_sum = sum(spec$weights),
      warnings = clean_text(c(fit_warnings, max_gradient$warnings)),
      error = clean_text(c(fit_error, max_gradient$error))
    )
  }
  TRUE
}

record_glm_comparators <- function(fx, fit, spec) {
  glm_out <- capture_conditions(
    stats::glm.fit(
      x = spec$X,
      y = spec$y / spec$trials,
      weights = spec$weights * spec$trials,
      offset = spec$offset,
      family = stats::binomial()
    )
  )
  br_out <- capture_conditions(
    brglm2::brglmFit(
      x = spec$X,
      y = spec$y / spec$trials,
      weights = spec$weights * spec$trials,
      offset = spec$offset,
      family = stats::binomial(),
      type = "AS_mean"
    )
  )
  for (item in list(
    list(name = "glm", out = glm_out),
    list(name = "brglm2_mean_bias_reduction", out = br_out)
  )) {
    if (is.null(item$out$value)) {
      add_record(
        record_type = "fit", stage = "binomial-core", fixture = fx$id,
        engine = item$name, check = "fit", expected = "object",
        observed = "error",
        status = if (identical(item$name, "glm")) "FAIL" else "RETAINED_FAILURE",
        warnings = item$out$warnings, error = item$out$error
      )
      next
    }
    coefficients <- item$out$value$coefficients
    names(coefficients) <- colnames(spec$X)
    for (nm in names(coefficients)) {
      add_record(
        record_type = "fit", stage = "binomial-core", fixture = fx$id,
        engine = item$name, check = "coefficient", coefficient = nm,
        observed = num_text(coefficients[[nm]]), status = "RECORDED",
        detail = paste0(
          "converged=", clean_text(item$out$value$converged),
          "; deviance=", num_text(item$out$value$deviance)
        ),
        retained_rows = nrow(spec$X), design_columns = ncol(spec$X),
        trials_sum = sum(spec$trials),
        active_weight_sum = sum(spec$weights),
        warnings = item$out$warnings, error = item$out$error
      )
    }
  }
  if (identical(fx$expected_class, "none") && !is.null(glm_out$value)) {
    drm_coef <- stats::coef(fit, dpar = "mu")
    glm_coef <- glm_out$value$coefficients
    names(glm_coef) <- colnames(spec$X)
    difference <- max(abs(drm_coef - glm_coef))
    add_record(
      record_type = "gate", stage = "binomial-core", fixture = fx$id,
      engine = "drmTMB_vs_glm", check = "overlap_coefficients",
      expected = "<=1e-6", observed = num_text(difference),
      status = if (is.finite(difference) && difference <= 1e-6) "PASS" else "FAIL"
    )
  }
}

verify_objective <- function(fx, fit, spec) {
  p <- ncol(spec$X)
  opt_par <- fit$opt$par
  extracted <- stats::coef(fit, dpar = "mu")
  par_list <- fit$obj$env$parList(opt_par)$beta_mu
  mapping_checks <- c(
    length = length(opt_par) == p,
    free_names = all(names(opt_par) == "beta_mu"),
    coefficient_names = identical(names(extracted), colnames(spec$X)),
    par_list_values = isTRUE(all.equal(
      unname(par_list),
      unname(extracted),
      tolerance = 1e-12
    ))
  )
  mapping_ok <- all(mapping_checks)
  add_record(
    record_type = "gate", stage = "objective-rays", fixture = fx$id,
    engine = "drmTMB_compiled", check = "parameter_mapping",
    expected = "all_true",
    observed = paste(names(mapping_checks), mapping_checks, sep = "=", collapse = ";"),
    status = if (mapping_ok) "PASS" else "FAIL"
  )
  if (!mapping_ok) {
    return(FALSE)
  }
  par_0 <- opt_par
  par_0[] <- 0
  compiled_0 <- fit$obj$fn(par_0)
  direct_0 <- direct_nll(spec, rep(0, p))
  fixture_ok <- TRUE
  for (ray_name in names(fx$rays)) {
    d <- as.numeric(fx$rays[[ray_name]])
    if (length(d) != p) {
      add_record(
        record_type = "gate", stage = "objective-rays", fixture = fx$id,
        engine = "harness", check = "ray_dimension", ray = ray_name,
        expected = p, observed = length(d), status = "FAIL"
      )
      fixture_ok <- FALSE
      next
    }
    compiled_values <- numeric(length(ray_grid))
    direct_values <- numeric(length(ray_grid))
    alignment_ok <- logical(length(ray_grid))
    mapping_ray_ok <- logical(length(ray_grid))
    for (k in seq_along(ray_grid)) {
      t_value <- ray_grid[[k]]
      beta_t <- t_value * d
      par_t <- par_0
      par_t[] <- beta_t
      mapped <- fit$obj$env$parList(par_t)$beta_mu
      mapping_ray_ok[[k]] <- isTRUE(all.equal(
        unname(mapped),
        unname(beta_t),
        tolerance = 1e-12
      ))
      compiled_values[[k]] <- fit$obj$fn(par_t)
      direct_values[[k]] <- direct_nll(spec, beta_t)
      compiled_delta <- compiled_values[[k]] - compiled_0
      direct_delta <- direct_values[[k]] - direct_0
      alignment <- abs(compiled_delta - direct_delta)
      alignment_ok[[k]] <- is.finite(alignment) && alignment <= tol
      add_record(
        record_type = "objective", stage = "objective-rays", fixture = fx$id,
        engine = "drmTMB_compiled_vs_direct", check = "objective_delta",
        expected = "<=1e-8", observed = num_text(alignment),
        status = if (alignment_ok[[k]] && mapping_ray_ok[[k]]) "PASS" else "FAIL",
        ray = ray_name, t = t_value,
        direct_objective = num_text(direct_values[[k]]),
        compiled_objective = num_text(compiled_values[[k]]),
        direct_delta = num_text(direct_delta),
        compiled_delta = num_text(compiled_delta)
      )
    }
    if (identical(fx$expected_class, "none")) {
      t_one <- which(ray_grid == 1)
      ray_gate <- (
        length(t_one) == 1L &&
          compiled_values[[t_one]] > compiled_0 + tol &&
          direct_values[[t_one]] > direct_0 + tol &&
          all(alignment_ok) &&
          all(mapping_ray_ok)
      )
      detail <- paste0(
        "compiled_delta_t1=", num_text(compiled_values[[t_one]] - compiled_0),
        "; direct_delta_t1=", num_text(direct_values[[t_one]] - direct_0)
      )
    } else {
      compiled_steps <- diff(compiled_values)
      direct_steps <- diff(direct_values)
      non_worsening <- all(compiled_steps <= tol) && all(direct_steps <= tol)
      strict <- (
        compiled_0 - min(compiled_values) > tol &&
          direct_0 - min(direct_values) > tol
      )
      ray_gate <- (
        non_worsening && strict &&
          all(alignment_ok) && all(mapping_ray_ok)
      )
      detail <- paste0(
        "max_compiled_step=", num_text(max(compiled_steps)),
        "; max_direct_step=", num_text(max(direct_steps)),
        "; compiled_improvement=", num_text(compiled_0 - min(compiled_values)),
        "; direct_improvement=", num_text(direct_0 - min(direct_values))
      )
    }
    add_record(
      record_type = "gate", stage = "objective-rays", fixture = fx$id,
      engine = "drmTMB_compiled_vs_direct", check = "ray_verdict",
      expected = if (identical(fx$expected_class, "none")) {
        "interior_minimum"
      } else {
        "non_worsening_and_strict"
      },
      observed = detail, status = if (ray_gate) "PASS" else "FAIL",
      ray = ray_name
    )
    fixture_ok <- fixture_ok && ray_gate
  }
  fixture_ok
}

verify_control_extraction <- function(fx, spec) {
  expected <- fx$control_expected
  checks <- c(
    X = isTRUE(all.equal(
      unname(spec$X),
      unname(expected$X),
      tolerance = 0
    )),
    X_names = identical(colnames(spec$X), colnames(expected$X)),
    y = identical(as.numeric(spec$y), as.numeric(expected$y)),
    trials = identical(as.numeric(spec$trials), as.numeric(expected$trials)),
    weights = identical(as.numeric(spec$weights), as.numeric(expected$weights)),
    offset = identical(as.numeric(spec$offset), as.numeric(expected$offset))
  )
  ok <- all(checks)
  add_record(
    record_type = "gate", stage = "exact-row-controls", fixture = fx$id,
    engine = "drmTMB_fitted_spec", check = "exact_active_specification",
    expected = "all_true",
    observed = paste(names(checks), checks, sep = "=", collapse = ";"),
    status = if (ok) "PASS" else "FAIL",
    retained_rows = nrow(spec$X), design_columns = ncol(spec$X),
    trials_sum = sum(spec$trials), active_weight_sum = sum(spec$weights)
  )
  ok
}

run_fixture <- function(fx, stage) {
  fixture_ok <- TRUE
  fit_out <- capture_conditions(fit_drm(fx))
  fit <- fit_out$value
  if (is.null(fit)) {
    add_record(
      record_type = "gate", stage = stage, fixture = fx$id,
      engine = "drmTMB", check = "fit_object",
      expected = "object", observed = "error", status = "FAIL",
      warnings = fit_out$warnings, error = fit_out$error
    )
    return(FALSE)
  }
  spec_out <- capture_conditions(extract_spec(fit))
  spec <- spec_out$value
  if (is.null(spec)) {
    add_record(
      record_type = "gate", stage = stage, fixture = fx$id,
      engine = "drmTMB_fitted_spec", check = "extract",
      expected = "valid_spec", observed = "error", status = "FAIL",
      warnings = spec_out$warnings, error = spec_out$error
    )
    return(FALSE)
  }
  rank_value <- qr(spec$X)$rank
  full_rank <- rank_value == ncol(spec$X)
  expected_rank <- if (isTRUE(fx$rank_deficient)) "rank_deficient" else "full_rank"
  observed_rank <- if (full_rank) "full_rank" else "rank_deficient"
  rank_ok <- identical(expected_rank, observed_rank)
  add_record(
    record_type = "gate", stage = stage, fixture = fx$id,
    engine = "base_qr", check = "design_rank", expected = expected_rank,
    observed = observed_rank, status = if (rank_ok) "PASS" else "FAIL",
    detail = paste0("rank=", rank_value, "; p=", ncol(spec$X)),
    retained_rows = nrow(spec$X), design_columns = ncol(spec$X),
    trials_sum = sum(spec$trials), active_weight_sum = sum(spec$weights)
  )
  fixture_ok <- fixture_ok && rank_ok
  record_fit_symptoms(
    fx, fit, spec,
    fit_warnings = fit_out$warnings,
    fit_error = fit_out$error
  )
  record_glm_comparators(fx, fit, spec)
  if (isTRUE(fx$rank_deficient)) {
    add_record(
      record_type = "gate", stage = stage, fixture = fx$id,
      engine = "harness", check = "separation_not_run",
      expected = "not_run", observed = "not_run",
      status = if (!full_rank) "PASS" else "FAIL"
    )
    return(fixture_ok && !full_rank)
  }
  if (!full_rank) {
    return(FALSE)
  }
  expanded <- expand_spec(spec)
  cone <- build_cone(spec)
  base_cone <- solve_cone(cone)
  expected_separation <- !identical(fx$expected_class, "none")
  base_expected <- if (expected_separation) "feasible" else "infeasible"
  base_ok <- identical(base_cone$state, base_expected)
  add_record(
    record_type = "oracle", stage = stage, fixture = fx$id,
    engine = "ROI_lpsolve_cone", check = "improving_cone",
    expected = base_expected, observed = base_cone$state,
    status = if (base_ok) "PASS" else "FAIL",
    solver_status = base_cone$status_code,
    solver_objective = num_text(base_cone$objective),
    max_residual = num_text(base_cone$residual),
    detail = paste0(
      "solution=",
      paste(
        colnames(spec$X),
        formatC(base_cone$solution, digits = 17, format = "fg"),
        sep = "=",
        collapse = ";"
      ),
      "; B_source=", paste(cone$B_source, collapse = ","),
      "; E_source=", paste(cone$E_source, collapse = ","),
      "; message=", base_cone$message
    ),
    retained_rows = nrow(spec$X), design_columns = ncol(spec$X)
  )
  fixture_ok <- fixture_ok && base_ok
  strict <- solve_strict_margin(expanded)
  strict_class <- if (!identical(strict$state, "solved")) {
    "unresolved"
  } else if (strict$delta > tol) {
    "complete"
  } else if (abs(strict$delta) <= tol) {
    "quasi_complete"
  } else {
    "unresolved"
  }
  oracle_class <- if (identical(base_cone$state, "infeasible")) {
    "none"
  } else if (identical(base_cone$state, "feasible")) {
    strict_class
  } else {
    "unresolved"
  }
  class_ok <- identical(oracle_class, fx$expected_class)
  add_record(
    record_type = "oracle", stage = stage, fixture = fx$id,
    engine = "ROI_lpsolve_strict_margin", check = "separation_class",
    expected = fx$expected_class, observed = oracle_class,
    status = if (class_ok) "PASS" else "FAIL",
    solver_status = strict$status_code,
    solver_objective = num_text(strict$objective),
    max_residual = num_text(strict$residual),
    detail = paste0(
      "delta=", num_text(strict$delta),
      "; solution=", num_text(strict$solution),
      "; message=", strict$message
    )
  )
  fixture_ok <- fixture_ok && class_ok

  sign_bits <- list()
  if (identical(base_cone$state, "feasible")) {
    for (j in seq_len(ncol(spec$X))) {
      coefficient <- colnames(spec$X)[[j]]
      sign_solutions <- lapply(
        c("negative", "zero", "positive"),
        function(mode) solve_cone(cone, j, mode)
      )
      names(sign_solutions) <- c("negative", "zero", "positive")
      bits <- vapply(
        sign_solutions,
        function(solution) identical(solution$state, "feasible"),
        logical(1)
      )
      sign_bits[[coefficient]] <- bits
      expected_bits <- fx$expected_signs[[coefficient]]
      for (mode in names(sign_solutions)) {
        solution <- sign_solutions[[mode]]
        add_record(
          record_type = "oracle", stage = stage, fixture = fx$id,
          engine = "ROI_lpsolve_cone", check = paste0("sign_", mode),
          coefficient = coefficient,
          expected = if (isTRUE(expected_bits[[mode]])) "feasible" else "infeasible",
          observed = solution$state,
          status = if (
            identical(
              solution$state,
              if (isTRUE(expected_bits[[mode]])) "feasible" else "infeasible"
            )
          ) "PASS" else "FAIL",
          solver_status = solution$status_code,
          solver_objective = num_text(solution$objective),
          max_residual = num_text(solution$residual),
          detail = paste0(
            "solution=",
            paste(
              colnames(spec$X),
              formatC(solution$solution, digits = 17, format = "fg"),
              sep = "=",
              collapse = ";"
            ),
            "; message=", solution$message
          )
        )
      }
      bits_ok <- identical(unname(bits), unname(expected_bits))
      add_record(
        record_type = "oracle", stage = stage, fixture = fx$id,
        engine = "ROI_lpsolve_cone", check = "coefficient_sign_feasibility",
        coefficient = coefficient,
        expected = paste(names(expected_bits), expected_bits, sep = "=", collapse = ";"),
        observed = paste(names(bits), bits, sep = "=", collapse = ";"),
        status = if (bits_ok) "PASS" else "FAIL"
      )
      fixture_ok <- fixture_ok && bits_ok
    }
  }

  detector_out <- capture_conditions(
    detectseparation::detect_separation(
      x = expanded$X,
      y = expanded$y,
      weights = expanded$weights,
      offset = expanded$offset,
      family = stats::binomial(),
      control = detectseparation::detect_separation_control(
        solver = "lpsolve",
        tolerance = detector_tol,
        separation_type = TRUE
      ),
      intercept = TRUE,
      singular.ok = FALSE
    )
  )
  detector <- detector_out$value
  if (is.null(detector)) {
    add_record(
      record_type = "detector", stage = stage, fixture = fx$id,
      engine = "detectseparation", check = "detector_object",
      expected = "object", observed = "error", status = "FAIL",
      warnings = detector_out$warnings, error = detector_out$error
    )
    fixture_ok <- FALSE
  } else {
    observed_detector_class <- detector_class(detector)
    detector_class_ok <- identical(observed_detector_class, fx$expected_class)
    add_record(
      record_type = "detector", stage = stage, fixture = fx$id,
      engine = "detectseparation", check = "separation_class",
      expected = fx$expected_class, observed = observed_detector_class,
      status = if (detector_class_ok) "PASS" else "FAIL",
      detector_outcome = detector$outcome,
      detector_class = observed_detector_class,
      warnings = detector_out$warnings, error = detector_out$error
    )
    fixture_ok <- fixture_ok && detector_class_ok
    detector_coef <- stats::coef(detector)
    names(detector_coef) <- colnames(spec$X)
    if (identical(base_cone$state, "infeasible")) {
      finite_ok <- all(detector_coef == 0)
      add_record(
        record_type = "detector", stage = stage, fixture = fx$id,
        engine = "detectseparation", check = "overlap_indicators",
        expected = "all_finite_zero",
        observed = paste(names(detector_coef), detector_coef, sep = "=", collapse = ";"),
        status = if (finite_ok && !isTRUE(detector$outcome)) "PASS" else "FAIL"
      )
      fixture_ok <- fixture_ok && finite_ok && !isTRUE(detector$outcome)
    } else if (identical(base_cone$state, "feasible")) {
      for (nm in names(detector_coef)) {
        value <- detector_coef[[nm]]
        required_bit <- if (is.infinite(value) && value > 0) {
          "positive"
        } else if (is.infinite(value) && value < 0) {
          "negative"
        } else if (identical(as.numeric(value), 0)) {
          "zero"
        } else {
          "invalid"
        }
        compatible <- (
          required_bit %in% names(sign_bits[[nm]]) &&
            isTRUE(sign_bits[[nm]][[required_bit]])
        )
        add_record(
          record_type = "detector", stage = stage, fixture = fx$id,
          engine = "detectseparation", check = "coefficient_compatibility",
          coefficient = nm, expected = "feasible_indicator",
          observed = paste0(value, " -> ", required_bit),
          status = if (compatible) "PASS" else "FAIL",
          detector_outcome = detector$outcome,
          detector_class = observed_detector_class
        )
        fixture_ok <- fixture_ok && compatible
      }
    }
  }
  if (!is.null(fx$control_expected)) {
    fixture_ok <- verify_control_extraction(fx, spec) && fixture_ok
  }
  objective_ok <- verify_objective(fx, fit, spec)
  fixture_ok <- fixture_ok && objective_ok
  fixture_ok
}

main <- function() {
  add_record(
    record_type = "receipt", stage = "preflight", fixture = "lane",
    engine = "harness", check = "authorization",
    expected = "binomial_s0a2_only",
    observed = "binomial_s0a2_only",
    status = "PASS",
    detail = "no hurdle; no S1; no package integration; no PR; no push; no merge"
  )
  add_record(
    record_type = "receipt", stage = "preflight", fixture = "runtime",
    engine = "R", check = "versions",
    expected = paste(names(required_versions), required_versions, sep = "=", collapse = ";"),
    observed = paste(
      names(required_versions),
      vapply(
        names(required_versions),
        function(pkg) as.character(utils::packageVersion(pkg)),
        character(1)
      ),
      sep = "=",
      collapse = ";"
    ),
    status = "PASS",
    detail = paste0("R=", getRversion(), "; platform=", R.version$platform)
  )
  core_outcomes <- vapply(
    core_fixtures,
    run_fixture,
    logical(1),
    stage = "binomial-core"
  )
  grouped <- records
  core_ok <- all(core_outcomes) &&
    !any(vapply(
      grouped,
      function(row) {
        row$stage[[1]] %in% c("binomial-core", "objective-rays") &&
          row$status[[1]] %in% c("FAIL", "UNRESOLVED")
      },
      logical(1)
    ))
  add_record(
    record_type = "gate", stage = "binomial-core", fixture = "all_core",
    engine = "harness", check = "core_verdict", expected = "PASS",
    observed = if (core_ok) "PASS" else "FAIL",
    status = if (core_ok) "PASS" else "FAIL",
    detail = paste(names(core_outcomes), core_outcomes, sep = "=", collapse = ";")
  )
  controls_ok <- FALSE
  if (core_ok) {
    control_outcomes <- vapply(
      control_fixtures,
      run_fixture,
      logical(1),
      stage = "exact-row-controls"
    )
    controls_ok <- all(control_outcomes)
    add_record(
      record_type = "gate", stage = "exact-row-controls",
      fixture = "all_controls", engine = "harness",
      check = "controls_verdict", expected = "PASS",
      observed = if (controls_ok) "PASS" else "FAIL",
      status = if (controls_ok) "PASS" else "FAIL",
      detail = paste(names(control_outcomes), control_outcomes, sep = "=", collapse = ";")
    )
  } else {
    add_record(
      record_type = "gate", stage = "exact-row-controls",
      fixture = "all_controls", engine = "harness",
      check = "controls_verdict", expected = "not_run_after_core_failure",
      observed = "not_run_after_core_failure", status = "PASS"
    )
  }
  final_ok <- core_ok && controls_ok
  add_record(
    record_type = "gate", stage = "binomial-s0a2",
    fixture = "programme", engine = "harness",
    check = "s0a2_verdict", expected = "PASS",
    observed = if (final_ok) "PASS" else "FAIL",
    status = if (final_ok) "PASS" else "FAIL",
    detail = "STOP after binomial S0-A2; hurdle and S1 are not authorized"
  )
  result <- write_results()
  cat(
    "S0-A2 rows=", nrow(result),
    " pass=", sum(result$status == "PASS", na.rm = TRUE),
    " fail=", sum(result$status == "FAIL", na.rm = TRUE),
    " recorded=", sum(result$status == "RECORDED", na.rm = TRUE),
    "\n",
    sep = ""
  )
  if (!final_ok) {
    stop("S0-A2 gate failed; results retained; hurdle and S1 not run", call. = FALSE)
  }
  cat("S0-A2 PASS; STOP before hurdle and S1\n")
  invisible(TRUE)
}

fatal <- capture_conditions(main())
if (!is.null(fatal$error) && !file.exists(output)) {
  add_record(
    record_type = "system", stage = "binomial-s0a2",
    fixture = "programme", engine = "harness", check = "fatal_error",
    expected = "none", observed = fatal$error, status = "FAIL",
    warnings = fatal$warnings, error = fatal$error
  )
  write_results()
}
if (!is.null(fatal$error)) {
  stop(fatal$error, call. = FALSE)
}
