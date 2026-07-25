#!/usr/bin/env Rscript

# Additive coverage-and-interval harness for the Beta phylogenetic q1
# direct-SD arc (capability-ledger cell mc-0017). This is a SIBLING of the
# interior-DGP recovery runner, not a modification of it: it sys.source()s
# `tools/run-beta-phylo-q1-sd-interior-recovery.R` (which itself sys.source()s
# the immutable predecessor `tools/run-beta-phylo-q1-sd-regression-recovery.R`)
# to reuse the frozen interior DGP (`beta_phylo_sd_regression_dgp`), the cell
# grid (`pr2_cells`), and the frozen certification seed grid
# (`pr2_seed_grid("certification")`), then adds Wald/profile interval
# coverage scoring on top. The point-recovery scoring path in both sourced
# runners is untouched; every function defined here uses the `pr2c_` prefix.
#
# Estimand, scale, and coverage-gate contract:
#   docs/dev-log/2026-07-17-beta-phylo-q1-coverage-estimand-alignment.md (S0)
#
# This script BUILDS the harness; it does not launch the full N~1200
# promotion-arm campaign. That launch is a separate, deliberate step (S3) on
# Totoro/DRAC, using `--n-promotion=` / `--n-context=` below.

`%||%` <- function(x, y) if (is.null(x)) y else x

pr2c_here <- function() {
  # An explicit option wins over `--file=`. When this runner is `sys.source()`d
  # by a test, `commandArgs()` still reports the *driver* script, so `--file=`
  # resolves the sibling lookup below into the driver's directory and the
  # top-level `sys.source()` aborts at file level. Launched normally the option
  # is unset and `--file=` is used exactly as before.
  option_path <- getOption("drmTMB.coverage.runner_path")
  script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  path <- if (!is.null(option_path)) {
    option_path
  } else if (length(script_arg)) {
    sub("^--file=", "", script_arg[[1L]])
  } else {
    "tools/run-beta-phylo-q1-sd-coverage.R"
  }
  normalizePath(path, mustWork = TRUE)
}

pr2c_interior_runner_path <- function() {
  file.path(dirname(pr2c_here()), "run-beta-phylo-q1-sd-interior-recovery.R")
}

sys.source(pr2c_interior_runner_path(), envir = environment())

pr2c_context <- function() {
  script_path <- pr2c_here()
  list(
    script_path = script_path,
    repo_root = normalizePath(
      file.path(dirname(script_path), ".."),
      mustWork = TRUE
    )
  )
}

# ---- Estimand (S0 Sec 2-3): fixed alpha coefficients, log-SD link scale ----

pr2c_coefficients <- function() c("alpha_intercept", "alpha_x")

pr2c_coefficient_parm <- function(coefficient) {
  switch(
    coefficient,
    alpha_intercept = "fixef:sd_phylo(spp_id):(Intercept)",
    alpha_x = "fixef:sd_phylo(spp_id):x_tau",
    stop("Unknown coefficient: ", coefficient, call. = FALSE)
  )
}

pr2c_truths <- function() {
  c(alpha_intercept = log(0.30), alpha_x = 0.25)
}

pr2c_methods <- function() c("wald", "profile")

pr2c_confint_fields <- function() {
  c(
    "lower",
    "upper",
    "width",
    "scale",
    "conf_status",
    "profile_engine",
    "covered",
    "miss_direction"
  )
}

# ---- Coverage-scoring helpers (pure; unit-tested without a live fit) ----

pr2c_covered <- function(lower, upper, truth) {
  ok <- is.finite(lower) & is.finite(upper)
  out <- rep(NA, length(lower))
  out[ok] <- lower[ok] <= truth & truth <= upper[ok]
  out
}

pr2c_miss_direction <- function(lower, upper, truth) {
  ok <- is.finite(lower) & is.finite(upper)
  out <- rep(NA_character_, length(lower))
  out[ok] <- ifelse(
    truth < lower[ok],
    "below",
    ifelse(truth > upper[ok], "above", "covered")
  )
  out
}

pr2c_mcse <- function(hits, n) {
  if (is.na(n) || n <= 0L) {
    return(NA_real_)
  }
  rate <- hits / n
  sqrt(rate * (1 - rate) / n)
}

pr2c_exact_ci <- function(hits, n, conf_level = 0.95) {
  if (is.na(n) || n <= 0L) {
    return(c(lower = NA_real_, upper = NA_real_))
  }
  ci <- stats::binom.test(hits, n, conf.level = conf_level)$conf.int
  c(lower = as.numeric(ci[[1L]]), upper = as.numeric(ci[[2L]]))
}

# ---- Cells, roles, and priority order (S0 Sec 8: 2 promotion + 8 context) ----

pr2c_cells <- function() {
  cells <- pr2_cells()
  cells <- cells[!(cells$g == 1024L & cells$m == 2L), , drop = FALSE]
  cells$role <- ifelse(cells$g == 1024L & cells$m == 4L, "promotion", "context")
  cells <- cells[
    order(cells$role != "promotion", cells$cell_number),
    ,
    drop = FALSE
  ]
  rownames(cells) <- NULL
  cells
}

pr2c_default_n <- function(cells = pr2c_cells(), n_promotion = 1200L, n_context = 400L) {
  stats::setNames(
    ifelse(cells$role == "promotion", n_promotion, n_context),
    cells$cell_id
  )
}

pr2c_default_methods <- function(cells = pr2c_cells()) {
  out <- stats::setNames(
    replicate(nrow(cells), pr2c_methods(), simplify = FALSE),
    cells$cell_id
  )
  out
}

# ---- Seeds: reuse the frozen certification grid; extend disjointly beyond N=400 ----

pr2c_extra_seed_base <- function() 1990000000L

pr2c_seed_grid <- function(cells = pr2c_cells(), n_by_cell) {
  frozen <- pr2_seed_grid("certification")
  do.call(rbind, lapply(seq_len(nrow(cells)), function(i) {
    cell <- cells[i, , drop = FALSE]
    n <- n_by_cell[[cell$cell_id]]
    if (is.null(n) || is.na(n) || n < 1L) {
      stop("Missing or invalid N for cell: ", cell$cell_id, call. = FALSE)
    }
    reps <- seq_len(n)
    frozen_reps <- reps[reps <= 400L]
    extra_reps <- reps[reps > 400L]
    frozen_rows <- frozen[
      frozen$cell_id == cell$cell_id & frozen$replicate %in% frozen_reps,
      ,
      drop = FALSE
    ]
    frozen_rows$seed_source <- "frozen_certification"
    extra_rows <- if (length(extra_reps)) {
      data.frame(
        cell_id = cell$cell_id,
        cell_number = cell$cell_number,
        predictor_design = cell$predictor_design,
        g = cell$g,
        m = cell$m,
        replicate = extra_reps,
        seed = as.integer(
          pr2c_extra_seed_base() - 10000L * cell$cell_number - extra_reps
        ),
        seed_source = "extra_coverage",
        stringsAsFactors = FALSE
      )
    } else {
      NULL
    }
    combined <- rbind(frozen_rows, extra_rows)
    combined$role <- cell$role
    combined
  }))
}

# Frozen-seed reuse (S0 Sec 7) plus disjointness of any beyond-N=400
# extension seeds from every known certification/smoke/one_fit grid in both
# the stopped and successor lineages.
pr2c_seed_audit <- function(grid) {
  known <- c(
    pr2_seed_grid("certification")$seed,
    pr2_seed_grid("smoke")$seed,
    pr2_seed_grid("one_fit")$seed,
    stopped_pr2_seed_grid("certification")$seed,
    stopped_pr2_seed_grid("smoke")$seed,
    stopped_pr2_seed_grid("one_fit")$seed
  )
  frozen_rows <- grid[grid$seed_source == "frozen_certification", , drop = FALSE]
  frozen_reference <- pr2_seed_grid("certification")
  matched <- merge(
    frozen_rows[c("cell_id", "replicate", "seed")],
    frozen_reference[c("cell_id", "replicate", "seed")],
    by = c("cell_id", "replicate"),
    suffixes = c("", "_expected")
  )
  frozen_ok <- nrow(matched) == nrow(frozen_rows) &&
    all(matched$seed == matched$seed_expected)
  extra_rows <- grid[grid$seed_source == "extra_coverage", , drop = FALSE]
  extra_ok <- !anyDuplicated(extra_rows$seed) && !any(extra_rows$seed %in% known)
  unique_ok <- !anyDuplicated(grid$seed)
  list(
    frozen_matches_certification = frozen_ok,
    extra_disjoint_from_known = extra_ok,
    seeds_unique = unique_ok,
    pass = isTRUE(frozen_ok) && isTRUE(extra_ok) && isTRUE(unique_ok)
  )
}

# ---- Per-cell phylogenetic structure summary (S0 Sec 5, Fisher item 4) ----

pr2c_tree_summary <- function(tree) {
  tip_depths <- ape::node.depth.edgelength(tree)[seq_len(ape::Ntip(tree))]
  cophenetic_matrix <- ape::cophenetic.phylo(tree)
  mean_pairwise <- mean(cophenetic_matrix[upper.tri(cophenetic_matrix)])
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  mean_offdiag_corr <- mean(A[upper.tri(A)])
  g <- ape::Ntip(tree)
  # Effective-N proxy: design-effect deflation of g under a common average
  # pairwise phylogenetic correlation (n / (1 + (n - 1) * rho)).
  effective_n_proxy <- g / (1 + (g - 1) * mean_offdiag_corr)
  list(
    tree_depth = max(tip_depths),
    mean_pairwise_distance = mean_pairwise,
    mean_offdiag_correlation = mean_offdiag_corr,
    effective_n_proxy = effective_n_proxy
  )
}

# ---- Wald/profile confint scoring for one fitted object ----

pr2c_confint_method <- function(fit, method, level = 0.95) {
  parms <- vapply(pr2c_coefficients(), pr2c_coefficient_parm, character(1L))
  truths <- pr2c_truths()
  if (is.null(fit)) {
    return(list(table = NULL, error = NA_character_))
  }
  result <- tryCatch(
    confint(fit, parm = unname(parms), level = level, method = method),
    error = function(e) e
  )
  if (inherits(result, "error")) {
    return(list(table = NULL, error = clean_pr2_text(conditionMessage(result))))
  }
  required <- c("parm", "lower", "upper", "scale", "conf.status")
  if (!all(required %in% names(result))) {
    stop(
      "confint() output is missing expected columns for method '",
      method,
      "'.",
      call. = FALSE
    )
  }
  # Estimand scale-match guard (S0 Sec 3): these targets must be reported on
  # the log-SD linear-predictor ("link") scale, matching the alpha truths.
  if (!all(result$scale == "link")) {
    stop(
      "Estimand scale-match guard failed: confint() did not return ",
      "scale == \"link\" for the sd_phylo(spp_id) fixed-effect targets ",
      "(see docs/dev-log/2026-07-17-beta-phylo-q1-coverage-estimand-",
      "alignment.md Sec 3).",
      call. = FALSE
    )
  }
  rows <- lapply(names(parms), function(coefficient) {
    row <- result[result$parm == parms[[coefficient]], , drop = FALSE]
    if (nrow(row) != 1L) {
      stop(
        "confint() did not return exactly one row for ",
        parms[[coefficient]],
        call. = FALSE
      )
    }
    truth <- truths[[coefficient]]
    data.frame(
      coefficient = coefficient,
      lower = row$lower[[1L]],
      upper = row$upper[[1L]],
      width = row$upper[[1L]] - row$lower[[1L]],
      scale = row$scale[[1L]],
      conf_status = row$conf.status[[1L]],
      profile_engine = if ("profile.engine" %in% names(row)) {
        row$profile.engine[[1L]]
      } else {
        NA_character_
      },
      covered = pr2c_covered(row$lower[[1L]], row$upper[[1L]], truth),
      miss_direction = pr2c_miss_direction(row$lower[[1L]], row$upper[[1L]], truth),
      stringsAsFactors = FALSE
    )
  })
  list(table = do.call(rbind, rows), error = NA_character_)
}

pr2c_widen_confint <- function(method, confint_result) {
  fields <- pr2c_confint_fields()
  out <- list()
  for (coefficient in pr2c_coefficients()) {
    row <- if (!is.null(confint_result$table)) {
      confint_result$table[confint_result$table$coefficient == coefficient, , drop = FALSE]
    } else {
      NULL
    }
    for (field in fields) {
      name <- paste(method, coefficient, field, sep = "_")
      out[[name]] <- if (!is.null(row) && nrow(row) == 1L) row[[field]][[1L]] else NA
    }
  }
  out[[paste0(method, "_error")]] <- confint_result$error %||% NA_character_
  out
}

# ---- Attempt-schema (wide, one row per replicate) ----

pr2c_attempt_columns <- function() {
  base <- c(
    "cell_id",
    "cell_number",
    "role",
    "predictor_design",
    "g",
    "m",
    "replicate",
    "seed",
    "seed_source",
    "truth_alpha_intercept",
    "truth_alpha_x",
    "elapsed_fit",
    "fit_success",
    "convergence",
    "pdHess",
    "max_gradient",
    "fixed_hessian_condition",
    "min_tau",
    "max_tau",
    "warning_count",
    "warnings",
    "error",
    "initial_boundary_count",
    "total_redraws",
    "max_response_redraws",
    "cap_exhausted",
    "all_final_responses_strict_interior",
    "tree_depth",
    "mean_pairwise_distance",
    "mean_offdiag_correlation",
    "effective_n_proxy"
  )
  elapsed <- paste0("elapsed_", pr2c_methods())
  extra <- unlist(lapply(pr2c_methods(), function(method) {
    c(
      unlist(lapply(pr2c_coefficients(), function(coefficient) {
        paste(method, coefficient, pr2c_confint_fields(), sep = "_")
      })),
      paste0(method, "_error")
    )
  }))
  c(base, elapsed, extra)
}

# ---- Single-replicate attempt: DGP + fit once, then score both methods ----
# Mirrors the fit call in `stopped_pr2_recovery_attempt()`
# (tools/run-beta-phylo-q1-sd-regression-recovery.R:338-353) but retains
# `fit` (needed for `confint(..., method = "profile")`) instead of
# discarding it, and reuses the successor interior DGP
# (`beta_phylo_sd_regression_dgp`, tools/run-beta-phylo-q1-sd-interior-
# recovery.R:212-258) unchanged.

pr2c_recovery_attempt <- function(row, methods = pr2c_methods(), level = 0.95) {
  started <- proc.time()[["elapsed"]]
  generated <- beta_phylo_sd_regression_dgp(
    row$g,
    row$m,
    row$predictor_design,
    row$seed
  )
  tree <- generated$tree
  tree_summary <- pr2c_tree_summary(tree)

  warnings_seen <- character()
  error <- NA_character_
  fit <- tryCatch(
    withCallingHandlers(
      drmTMB::drmTMB(
        drmTMB::bf(
          y ~ x_mu + drmTMB::phylo(1 | spp_id, tree = tree),
          sigma ~ x_sigma,
          sd(spp_id, level = "phylogenetic") ~ x_tau
        ),
        family = drmTMB::beta(),
        data = generated$data,
        control = drmTMB::drm_control(
          optimizer_preset = "robust",
          se_report_covariance = FALSE,
          se_group_sd = FALSE
        )
      ),
      warning = function(w) {
        warnings_seen <<- c(warnings_seen, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) {
      error <<- clean_pr2_text(conditionMessage(e))
      NULL
    }
  )
  elapsed_fit <- proc.time()[["elapsed"]] - started

  gradient <- numeric()
  condition_number <- NA_real_
  min_tau <- NA_real_
  max_tau <- NA_real_
  if (!is.null(fit)) {
    gradient <- tryCatch(as.numeric(fit$sdr$gradient.fixed), error = function(e) numeric())
    condition_number <- tryCatch(
      as.numeric(kappa(fit$sdr$cov.fixed, exact = TRUE)),
      error = function(e) NA_real_
    )
    tau_hat <- tryCatch(
      predict(fit, dpar = "sd_phylo(spp_id)"),
      error = function(e) numeric()
    )
    if (length(tau_hat) && all(is.finite(tau_hat))) {
      min_tau <- min(tau_hat)
      max_tau <- max(tau_hat)
    }
  }

  elapsed_by_method <- stats::setNames(rep(NA_real_, length(pr2c_methods())), pr2c_methods())
  extra <- list()
  for (method in pr2c_methods()) {
    if (method %in% methods) {
      call_started <- proc.time()[["elapsed"]]
      confint_result <- pr2c_confint_method(fit, method, level = level)
      elapsed_by_method[[method]] <- proc.time()[["elapsed"]] - call_started
    } else {
      confint_result <- list(table = NULL, error = NA_character_)
    }
    extra <- c(extra, pr2c_widen_confint(method, confint_result))
  }

  base <- data.frame(
    cell_id = row$cell_id,
    cell_number = row$cell_number,
    role = row$role,
    predictor_design = row$predictor_design,
    g = row$g,
    m = row$m,
    replicate = row$replicate,
    seed = row$seed,
    seed_source = row$seed_source,
    truth_alpha_intercept = unname(pr2c_truths()[["alpha_intercept"]]),
    truth_alpha_x = unname(pr2c_truths()[["alpha_x"]]),
    elapsed_fit = elapsed_fit,
    fit_success = !is.null(fit),
    convergence = if (is.null(fit)) NA_integer_ else fit$opt$convergence,
    pdHess = if (is.null(fit)) FALSE else isTRUE(fit$sdr$pdHess),
    max_gradient = if (length(gradient) && all(is.finite(gradient))) {
      max(abs(gradient))
    } else {
      NA_real_
    },
    fixed_hessian_condition = condition_number,
    min_tau = min_tau,
    max_tau = max_tau,
    warning_count = length(warnings_seen),
    warnings = clean_pr2_text(warnings_seen),
    error = error,
    initial_boundary_count = generated$telemetry$initial_boundary_count,
    total_redraws = generated$telemetry$total_redraws,
    max_response_redraws = generated$telemetry$max_response_redraws,
    cap_exhausted = generated$telemetry$cap_exhausted,
    all_final_responses_strict_interior = generated$telemetry$all_final_responses_strict_interior,
    tree_depth = tree_summary$tree_depth,
    mean_pairwise_distance = tree_summary$mean_pairwise_distance,
    mean_offdiag_correlation = tree_summary$mean_offdiag_correlation,
    effective_n_proxy = tree_summary$effective_n_proxy,
    elapsed_wald = unname(elapsed_by_method[["wald"]]),
    elapsed_profile = unname(elapsed_by_method[["profile"]]),
    stringsAsFactors = FALSE
  )

  out <- cbind(base, as.data.frame(extra, stringsAsFactors = FALSE))
  out[pr2c_attempt_columns()]
}

# ---- Crash-safe incremental TSV writer (lock-serialized single-line append) ----

pr2c_append_row <- function(row, path, lock_path = paste0(path, ".lock")) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  values <- vapply(seq_along(row), function(i) {
    value <- row[[i]]
    if (length(value) != 1L || is.na(value)) "NA" else as.character(value)
  }, character(1L))
  line <- paste(values, collapse = "\t")
  header <- paste(names(row), collapse = "\t")
  waited <- 0
  while (!dir.create(lock_path, showWarnings = FALSE)) {
    Sys.sleep(0.05)
    waited <- waited + 0.05
    if (waited > 60) {
      stop("Could not acquire coverage append lock: ", lock_path, call. = FALSE)
    }
  }
  on.exit(unlink(lock_path, recursive = TRUE), add = TRUE)
  if (!file.exists(path)) {
    cat(header, "\n", file = path, sep = "", append = TRUE)
  }
  cat(line, "\n", file = path, sep = "", append = TRUE)
  flush(stdout())
  invisible(path)
}

pr2c_done_keys <- function(path) {
  if (!file.exists(path)) {
    return(character())
  }
  existing <- utils::read.delim(path, stringsAsFactors = FALSE)
  if (!nrow(existing)) {
    return(character())
  }
  paste(existing$cell_id, existing$replicate, existing$seed)
}

# ---- Per-cell aggregation (S0 Sec 5) ----

pr2c_aggregate_coverage <- function(raw) {
  cells <- unique(raw[c("cell_id", "cell_number", "role", "predictor_design", "g", "m")])
  rows <- list()
  for (i in seq_len(nrow(cells))) {
    cell_rows <- raw[raw$cell_id == cells$cell_id[[i]], , drop = FALSE]
    for (method in pr2c_methods()) {
      for (coefficient in pr2c_coefficients()) {
        lower_col <- paste(method, coefficient, "lower", sep = "_")
        upper_col <- paste(method, coefficient, "upper", sep = "_")
        width_col <- paste(method, coefficient, "width", sep = "_")
        covered_col <- paste(method, coefficient, "covered", sep = "_")
        miss_col <- paste(method, coefficient, "miss_direction", sep = "_")
        if (!lower_col %in% names(cell_rows)) {
          next
        }
        attempted <- nrow(cell_rows)
        finite <- is.finite(cell_rows[[lower_col]]) & is.finite(cell_rows[[upper_col]])
        n <- sum(finite)
        hits <- sum(cell_rows[[covered_col]][finite] %in% TRUE)
        ci <- pr2c_exact_ci(hits, n)
        rows[[length(rows) + 1L]] <- data.frame(
          cells[i, , drop = FALSE],
          method = method,
          coefficient = coefficient,
          attempted = attempted,
          interval_finite_n = n,
          interval_finite_rate = if (attempted > 0L) n / attempted else NA_real_,
          hits = hits,
          rate = if (n > 0L) hits / n else NA_real_,
          mcse = pr2c_mcse(hits, n),
          exact_ci_lower = ci[["lower"]],
          exact_ci_upper = ci[["upper"]],
          miss_below_n = sum(cell_rows[[miss_col]][finite] == "below"),
          miss_above_n = sum(cell_rows[[miss_col]][finite] == "above"),
          mean_width = if (n > 0L) mean(cell_rows[[width_col]][finite]) else NA_real_,
          stringsAsFactors = FALSE
        )
      }
    }
  }
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

pr2c_aggregate_tree <- function(raw) {
  cells <- unique(raw[c("cell_id", "cell_number", "role", "predictor_design", "g", "m")])
  rows <- lapply(seq_len(nrow(cells)), function(i) {
    cell_rows <- raw[raw$cell_id == cells$cell_id[[i]], , drop = FALSE]
    data.frame(
      cells[i, , drop = FALSE],
      n_trees = nrow(cell_rows),
      mean_tree_depth = mean(cell_rows$tree_depth, na.rm = TRUE),
      mean_pairwise_distance = mean(cell_rows$mean_pairwise_distance, na.rm = TRUE),
      mean_offdiag_correlation = mean(cell_rows$mean_offdiag_correlation, na.rm = TRUE),
      mean_effective_n_proxy = mean(cell_rows$effective_n_proxy, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

# ---- Driver ----

pr2c_default_output <- function(repo_root) {
  file.path(
    repo_root,
    "docs/dev-log/simulation-artifacts",
    "2026-07-17-beta-phylo-q1-coverage"
  )
}

run_pr2c_coverage <- function(
  cells = pr2c_cells(),
  n_promotion = 1200L,
  n_context = 400L,
  methods_by_cell = pr2c_default_methods(cells),
  cores = 1L,
  output = NULL,
  resume = FALSE,
  level = 0.95
) {
  context <- pr2c_context()
  n_by_cell <- pr2c_default_n(cells, n_promotion, n_context)
  grid <- pr2c_seed_grid(cells, n_by_cell)
  audit <- pr2c_seed_audit(grid)
  if (!audit$pass) {
    stop(
      "Coverage seed audit failed: ",
      paste(names(audit)[!vapply(audit, isTRUE, logical(1L))], collapse = ", "),
      call. = FALSE
    )
  }

  out_dir <- output %||% pr2c_default_output(context$repo_root)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  raw_path <- file.path(out_dir, "raw-coverage.tsv")
  log_path <- file.path(out_dir, "progress.log")

  done <- if (resume) pr2c_done_keys(raw_path) else character()
  grid$pr2c_key <- paste(grid$cell_id, grid$replicate, grid$seed)
  pending <- grid[!grid$pr2c_key %in% done, , drop = FALSE]
  pending$pr2c_key <- NULL
  pending <- pending[
    order(match(pending$cell_id, cells$cell_id), pending$replicate),
    ,
    drop = FALSE
  ]
  message(sprintf(
    "Coverage: %d pending of %d total replicates (output=%s).",
    nrow(pending),
    nrow(grid),
    out_dir
  ))

  if (!nrow(pending)) {
    return(invisible(raw_path))
  }

  rows <- split(pending, seq_len(nrow(pending)))
  worker <- function(row) {
    row <- row[1L, , drop = FALSE]
    Sys.setenv(
      OPENBLAS_NUM_THREADS = "1",
      OMP_NUM_THREADS = "1",
      MKL_NUM_THREADS = "1",
      VECLIB_MAXIMUM_THREADS = "1"
    )
    methods <- methods_by_cell[[row$cell_id]] %||% pr2c_methods()
    result <- tryCatch(
      pr2c_recovery_attempt(row, methods = methods, level = level),
      error = function(e) e
    )
    if (inherits(result, "error")) {
      cat(
        sprintf(
          "[%s] ERROR cell=%s rep=%s seed=%s: %s\n",
          format(Sys.time(), tz = "UTC", usetz = TRUE),
          row$cell_id,
          row$replicate,
          row$seed,
          conditionMessage(result)
        ),
        file = log_path,
        append = TRUE
      )
      return(result)
    }
    pr2c_append_row(result, raw_path)
    cat(
      sprintf(
        "[%s] done cell=%s rep=%s seed=%s fit_success=%s pdHess=%s\n",
        format(Sys.time(), tz = "UTC", usetz = TRUE),
        row$cell_id,
        row$replicate,
        row$seed,
        result$fit_success[[1L]],
        result$pdHess[[1L]]
      ),
      file = log_path,
      append = TRUE
    )
    flush(stdout())
    result
  }

  results <- if (cores == 1L || .Platform$OS.type == "windows") {
    lapply(rows, worker)
  } else {
    parallel::mclapply(rows, worker, mc.cores = cores, mc.preschedule = FALSE)
  }

  failures <- vapply(results, inherits, logical(1L), "error")
  if (any(failures)) {
    stop(
      sum(failures),
      " of ",
      length(results),
      " coverage replicate(s) failed; see ",
      log_path,
      call. = FALSE
    )
  }
  invisible(raw_path)
}

# ---- Thin CLI (for the deliberate S3 campaign launch; not auto-run when sourced) ----

parse_pr2c_args <- function(args = commandArgs(trailingOnly = TRUE)) {
  out <- list(
    cores = 1L,
    output = NULL,
    n_promotion = 1200L,
    n_context = 400L,
    resume = FALSE
  )
  for (arg in args) {
    if (startsWith(arg, "--cores=")) {
      out$cores <- as.integer(sub("^--cores=", "", arg))
    } else if (startsWith(arg, "--output=")) {
      out$output <- sub("^--output=", "", arg)
    } else if (startsWith(arg, "--n-promotion=")) {
      out$n_promotion <- as.integer(sub("^--n-promotion=", "", arg))
    } else if (startsWith(arg, "--n-context=")) {
      out$n_context <- as.integer(sub("^--n-context=", "", arg))
    } else if (identical(arg, "--resume")) {
      out$resume <- TRUE
    } else {
      stop("Unknown argument: ", arg, call. = FALSE)
    }
  }
  out
}

if (sys.nframe() == 0L) {
  cli_args <- parse_pr2c_args()
  run_pr2c_coverage(
    n_promotion = cli_args$n_promotion,
    n_context = cli_args$n_context,
    cores = cli_args$cores,
    output = cli_args$output,
    resume = cli_args$resume
  )
}
