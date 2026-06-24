#!/usr/bin/env Rscript

devtools::load_all(quiet = TRUE)

script_file <- sub(
  "^--file=",
  "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1L]
)
if (length(script_file) == 0L || is.na(script_file)) {
  script_file <- "tools"
}
repo_root <- normalizePath(file.path(dirname(script_file), ".."))
if (!file.exists(file.path(repo_root, "DESCRIPTION"))) {
  repo_root <- normalizePath(getwd())
}

artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-24-spatial-mu-domain-guard-diagnostic"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

artifact_path <- file.path(
  artifact_dir,
  "structured-re-spatial-mu-domain-guard-diagnostic-results.tsv"
)
status_path <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "dashboard",
  "structured-re-spatial-mu-domain-guard-diagnostic.tsv"
)

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

correlated_effects <- function(K, sds) {
  z <- replicate(length(sds), as.vector(t(chol(K)) %*% stats::rnorm(nrow(K))))
  out <- sweep(z, 2L, sds, `*`)
  colnames(out) <- names(sds)
  out
}

make_spatial_data <- function(seed, n_each, sds) {
  set.seed(seed)
  n <- 8L
  labels <- paste0("site_", seq_len(n))
  theta <- seq(0, 1.5 * pi, length.out = n)
  coords <- data.frame(
    x = cos(theta) + seq_len(n) / (3 * n),
    y = sin(theta)
  )
  rownames(coords) <- labels
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords,
    site = labels,
    group = "site"
  )
  K <- solve(as.matrix(precision$precision))
  effects <- correlated_effects(K, sds)
  rownames(effects) <- labels

  site <- rep(labels, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), times = length(labels))
  eta_mu <- 0.35 +
    0.20 * x +
    effects[site, "mu_intercept"] +
    effects[site, "mu_x"] * x
  eta_sigma <- -1.05 +
    effects[site, "sigma_intercept"] +
    effects[site, "sigma_x"] * x
  data <- data.frame(
    y = eta_mu + exp(eta_sigma) * stats::rnorm(length(x)),
    x = x,
    site = site
  )

  list(
    data = data,
    coords = coords,
    realized_sds = apply(effects, 2L, stats::sd)
  )
}

fit_spatial <- function(sim) {
  coords <- sim$coords
  drmTMB(
    bf(
      y ~ x + spatial(1 + x | site, coords = coords),
      sigma ~ spatial(1 + x | site, coords = coords)
    ),
    family = gaussian(),
    data = sim$data,
    control = drm_control(optimizer = list(eval.max = 1200, iter.max = 1200))
  )
}

fixed_domain_scan <- function(fit, target, offsets) {
  position <- as.integer(drmTMB:::profile_target_opt_positions(fit, target))
  drmTMB:::drm_pin_tmb_object_to_optimum(fit$obj, fit$opt, fit$tmb_state)
  par0 <- fit$opt$par
  free <- seq_along(par0) != position
  rows <- lapply(offsets, function(offset) {
    full <- par0
    full[[position]] <- par0[[position]] + offset
    fn <- tryCatch(fit$obj$fn(full), error = function(e) e)
    gr <- tryCatch(fit$obj$gr(full)[free], error = function(e) e)
    data.frame(
      offset = offset,
      objective_finite = is.numeric(fn) && length(fn) == 1L && is.finite(fn),
      gradient_finite = is.numeric(gr) && all(is.finite(gr)),
      gradient_bad_n = if (is.numeric(gr)) {
        sum(!is.finite(gr))
      } else {
        NA_integer_
      },
      fn_message = if (inherits(fn, "error")) conditionMessage(fn) else "ok",
      gr_message = if (inherits(gr, "error")) conditionMessage(gr) else "ok",
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

guarded_evaluator <- function(fit, position, mode) {
  par0 <- fit$opt$par
  free <- seq_along(par0) != position
  last_free <- par0[free]

  evaluate <- function(theta) {
    full0 <- par0
    fn_free <- function(pfree) {
      full <- full0
      full[free] <- pfree
      full[[position]] <- theta
      value <- tryCatch(fit$obj$fn(full), error = function(e) NA_real_)
      if (!is.finite(value)) {
        return(1e100)
      }
      value
    }
    gr_free <- function(pfree) {
      full <- full0
      full[free] <- pfree
      full[[position]] <- theta
      gradient <- tryCatch(
        fit$obj$gr(full)[free],
        error = function(e) rep(NA_real_, length(pfree))
      )
      if (any(!is.finite(gradient))) {
        return(rep(0, length(pfree)))
      }
      gradient
    }
    opt <- if (identical(mode, "fn_penalty")) {
      stats::nlminb(
        last_free,
        fn_free,
        control = list(eval.max = 1200, iter.max = 1200)
      )
    } else {
      stats::nlminb(
        last_free,
        fn_free,
        gr_free,
        control = list(eval.max = 1200, iter.max = 1200)
      )
    }
    last_free <<- opt$par
    if (
      !is.finite(opt$objective) ||
        opt$objective >= 1e99 ||
        !opt$convergence %in% c(0L, 1L)
    ) {
      stop(opt$message)
    }
    list(nll = unname(opt$objective), par = opt$par)
  }

  list(evaluate = evaluate)
}

guarded_crossing <- function(
  evaluator,
  theta_hat,
  nll_hat,
  cutoff,
  initial_step = 0.25,
  max_bracket_steps = 60L
) {
  n_eval <- 0L
  eval_root <- function(theta) {
    n_eval <<- n_eval + 1L
    out <- evaluator$evaluate(theta)
    out$nll - nll_hat - cutoff
  }

  at_hat <- -cutoff
  step <- initial_step
  n_bracket_step <- 0L
  outer <- theta_hat - step
  outer_value <- eval_root(outer)
  for (i in seq_len(max_bracket_steps)) {
    if (is.finite(outer_value) && outer_value >= 0) {
      break
    }
    step <- step * 1.6
    n_bracket_step <- i
    outer <- theta_hat - step
    outer_value <- eval_root(outer)
  }
  if (!is.finite(outer_value) || outer_value < 0) {
    stop("could_not_bracket")
  }
  root <- stats::uniroot(
    eval_root,
    interval = sort(c(theta_hat, outer)),
    f.lower = outer_value,
    f.upper = at_hat,
    tol = 1e-4
  )
  list(
    theta = root$root,
    endpoint = exp(root$root),
    root_error = abs(root$f.root),
    n_eval = n_eval,
    bracket_step = step,
    n_bracket_step = n_bracket_step
  )
}

run_guarded_mode <- function(fit, target, mode) {
  warning_text <- character()
  position <- as.integer(drmTMB:::profile_target_opt_positions(fit, target))
  drmTMB:::drm_pin_tmb_object_to_optimum(fit$obj, fit$opt, fit$tmb_state)
  theta_hat <- unname(fit$opt$par[[position]])
  nll_hat <- unname(fit$opt$objective)
  cutoff <- stats::qchisq(0.70, df = 1) / 2
  evaluator <- guarded_evaluator(fit, position, mode = mode)
  result <- withCallingHandlers(
    tryCatch(
      guarded_crossing(
        evaluator = evaluator,
        theta_hat = theta_hat,
        nll_hat = nll_hat,
        cutoff = cutoff
      ),
      error = function(e) e
    ),
    warning = function(w) {
      warning_text <<- c(warning_text, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  if (inherits(result, "error")) {
    return(list(
      status = "nonfinite",
      endpoint = NA_real_,
      root_error = NA_real_,
      n_eval = NA_integer_,
      message = clean_text(conditionMessage(result)),
      warnings = clean_text(paste(warning_text, collapse = " | "))
    ))
  }

  list(
    status = "finite",
    endpoint = result$endpoint,
    root_error = result$root_error,
    n_eval = result$n_eval,
    message = "ok",
    warnings = clean_text(paste(warning_text, collapse = " | "))
  )
}

diagnostic_status <- function(design_id, fn_status, zero_gr_status) {
  if (identical(fn_status, "finite") && identical(zero_gr_status, "finite")) {
    return("finite_control")
  }
  if (identical(design_id, "strong_seed202")) {
    return("optimizer_path_boundary_not_rescued")
  }
  "optimizer_path_lower_not_rescued"
}

claim_boundary <- function(status) {
  clean_text(paste(
    "Fixed-covariance spatial mu:x domain-guard diagnostic only;",
    "status =",
    status,
    "with no range-estimating spatial support, no interval reliability,",
    "interval coverage, REML, AI-REML, broad bridge support, public support,",
    "or coverage denominator admission promoted."
  ))
}

next_gate <- function(status) {
  if (identical(status, "finite_control")) {
    return(
      "Use as finite control only; require replicated denominators before coverage wording."
    )
  }
  "Investigate constrained-profile boundary handling or keep this regime out of coverage denominators."
}

designs <- list(
  smoke_seed102 = list(
    seed = 102L,
    n_each = 10L,
    sds = c(
      mu_intercept = 0.40,
      mu_x = 0.24,
      sigma_intercept = 0.22,
      sigma_x = 0.14
    )
  ),
  strong_seed202 = list(
    seed = 202L,
    n_each = 20L,
    sds = c(
      mu_intercept = 0.60,
      mu_x = 0.45,
      sigma_intercept = 0.55,
      sigma_x = 0.40
    )
  ),
  strong_n50_seed202 = list(
    seed = 202L,
    n_each = 50L,
    sds = c(
      mu_intercept = 0.60,
      mu_x = 0.45,
      sigma_intercept = 0.55,
      sigma_x = 0.40
    )
  ),
  mu_dominant_seed202 = list(
    seed = 202L,
    n_each = 20L,
    sds = c(
      mu_intercept = 0.80,
      mu_x = 0.60,
      sigma_intercept = 0.12,
      sigma_x = 0.08
    )
  )
)

domain_offsets <- c(0, -0.001, -0.01, -0.05, -0.1, -0.25, -0.5, -1, -3)
target_name <- "sd:mu:mu:spatial(0 + x | site)"
rows <- list()

for (design_id in names(designs)) {
  design <- designs[[design_id]]
  sim <- make_spatial_data(
    seed = design$seed,
    n_each = design$n_each,
    sds = design$sds
  )
  fit <- fit_spatial(sim)
  targets <- profile_targets(fit)
  target <- targets[targets$parm == target_name, , drop = FALSE]
  position <- as.integer(drmTMB:::profile_target_opt_positions(fit, target))
  theta_hat <- unname(fit$opt$par[[position]])
  domain <- fixed_domain_scan(fit, target, offsets = domain_offsets)
  fn_penalty <- run_guarded_mode(fit, target, mode = "fn_penalty")
  zero_gr_penalty <- run_guarded_mode(fit, target, mode = "zero_gr_penalty")
  status <- diagnostic_status(
    design_id,
    fn_status = fn_penalty$status,
    zero_gr_status = zero_gr_penalty$status
  )
  rows[[length(rows) + 1L]] <- data.frame(
    diagnostic_id = paste0("spatial_mu_x_domain_guard_", design_id),
    cell_id = "qseries_spatial_q1_mu_sigma_one_slope",
    design_id = design_id,
    seed = design$seed,
    n_each = design$n_each,
    formula_cell = "spatial(1 + x | site, coords = coords) in mu and sigma",
    structured_type = "spatial",
    target_kind = "direct_sd",
    endpoint_member = "mu:x",
    direct_sd_target = "sd_mu_x",
    profile_target = target_name,
    profile_side = "lower",
    source_artifact = file.path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-spatial-mu-domain-guard-diagnostic",
      "structured-re-spatial-mu-domain-guard-diagnostic-results.tsv"
    ),
    source_lower_start = "docs/dev-log/dashboard/structured-re-spatial-mu-lower-start-diagnostic.tsv",
    domain_offsets = paste(domain_offsets, collapse = ";"),
    n_domain_offsets = length(domain_offsets),
    n_fixed_objective_finite = sum(domain$objective_finite),
    n_fixed_gradient_finite = sum(domain$gradient_finite),
    n_fixed_gradient_bad_total = sum(domain$gradient_bad_n, na.rm = TRUE),
    intended_sd_mu_intercept = design$sds[["mu_intercept"]],
    intended_sd_mu_x = design$sds[["mu_x"]],
    intended_sd_sigma_intercept = design$sds[["sigma_intercept"]],
    intended_sd_sigma_x = design$sds[["sigma_x"]],
    realized_sd_mu_intercept = sim$realized_sds[["mu_intercept"]],
    realized_sd_mu_x = sim$realized_sds[["mu_x"]],
    realized_sd_sigma_intercept = sim$realized_sds[["sigma_intercept"]],
    realized_sd_sigma_x = sim$realized_sds[["sigma_x"]],
    estimate = target$estimate[[1L]],
    theta_hat = theta_hat,
    profile_ready = target$profile_ready[[1L]],
    guarded_initial_step = 0.25,
    fn_penalty_status = fn_penalty$status,
    fn_penalty_endpoint = fn_penalty$endpoint,
    fn_penalty_root_error = fn_penalty$root_error,
    fn_penalty_n_eval = fn_penalty$n_eval,
    fn_penalty_message = fn_penalty$message,
    zero_gr_penalty_status = zero_gr_penalty$status,
    zero_gr_penalty_endpoint = zero_gr_penalty$endpoint,
    zero_gr_penalty_root_error = zero_gr_penalty$root_error,
    zero_gr_penalty_n_eval = zero_gr_penalty$n_eval,
    zero_gr_penalty_message = zero_gr_penalty$message,
    diagnostic_status = status,
    interval_claim_status = "diagnostic_only",
    denominator_admission = "not_admitted",
    status = "covered",
    evidence_url = "docs/dev-log/after-task/2026-06-24-spatial-mu-domain-guard-diagnostic.md",
    claim_boundary = claim_boundary(status),
    next_gate = next_gate(status),
    stringsAsFactors = FALSE
  )
}

out <- do.call(rbind, rows)
character_cols <- vapply(out, is.character, logical(1L))
out[character_cols] <- lapply(out[character_cols], clean_text)

utils::write.table(
  out,
  file = artifact_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)
utils::write.table(
  out,
  file = status_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)

message("Wrote ", normalizePath(artifact_path, winslash = "/"))
message("Wrote ", normalizePath(status_path, winslash = "/"))
