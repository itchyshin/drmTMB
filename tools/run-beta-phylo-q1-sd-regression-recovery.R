#!/usr/bin/env Rscript

`%||%` <- function(x, y) if (is.null(x)) y else x

pr2_context <- function() {
  script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  script_path <- if (length(script_arg)) {
    sub("^--file=", "", script_arg[[1L]])
  } else {
    "tools/run-beta-phylo-q1-sd-regression-recovery.R"
  }
  script_path <- normalizePath(script_path, mustWork = TRUE)
  list(
    script_path = script_path,
    repo_root = normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
  )
}

parse_pr2_args <- function(args = commandArgs(trailingOnly = TRUE)) {
  out <- list(
    mode = "design",
    output = NULL,
    one_fit = NULL,
    smoke = NULL,
    cores = 1L,
    resume = FALSE
  )
  for (arg in args) {
    if (startsWith(arg, "--mode=")) {
      out$mode <- sub("^--mode=", "", arg)
    } else if (startsWith(arg, "--output=")) {
      out$output <- sub("^--output=", "", arg)
    } else if (startsWith(arg, "--cores=")) {
      out$cores <- as.integer(sub("^--cores=", "", arg))
    } else if (startsWith(arg, "--one-fit=")) {
      out$one_fit <- sub("^--one-fit=", "", arg)
    } else if (startsWith(arg, "--smoke=")) {
      out$smoke <- sub("^--smoke=", "", arg)
    } else if (identical(arg, "--resume")) {
      out$resume <- TRUE
    } else {
      stop("Unknown argument: ", arg, call. = FALSE)
    }
  }
  if (!out$mode %in% c("design", "one_fit", "smoke", "certification")) {
    stop("`mode` must be design, one_fit, smoke, or certification.", call. = FALSE)
  }
  if (is.na(out$cores) || out$cores < 1L || out$cores > 32L) {
    stop("`cores` must be an integer from 1 through 32.", call. = FALSE)
  }
  if (out$mode %in% c("design", "one_fit") && out$cores != 1L) {
    stop("Design and one_fit modes require `cores = 1`.", call. = FALSE)
  }
  out
}

pr2_rng_kind <- function() {
  c(kind = "L'Ecuyer-CMRG", normal.kind = "Inversion", sample.kind = "Rejection")
}

with_pr2_rng <- function(seed, code) {
  old_kind <- RNGkind()
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  old_seed <- if (had_seed) get(".Random.seed", envir = .GlobalEnv) else NULL
  on.exit(
    {
      suppressWarnings(do.call(RNGkind, as.list(old_kind)))
      if (had_seed) {
        assign(".Random.seed", old_seed, envir = .GlobalEnv)
      } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
        rm(".Random.seed", envir = .GlobalEnv)
      }
    },
    add = TRUE
  )
  do.call(RNGkind, as.list(pr2_rng_kind()))
  set.seed(seed)
  force(code)
}

pr2_cells <- function() {
  cells <- do.call(
    rbind,
    lapply(c("distinct", "shared"), function(design) {
      do.call(
        rbind,
        lapply(c(256L, 512L, 1024L), function(g) {
          data.frame(
            predictor_design = design,
            g = g,
            m = c(2L, 4L),
            stringsAsFactors = FALSE
          )
        })
      )
    })
  )
  cells$cell_number <- seq_len(nrow(cells))
  cells$cell_id <- sprintf(
    "%s_g%04d_m%02d",
    cells$predictor_design,
    cells$g,
    cells$m
  )
  rownames(cells) <- NULL
  cells[c("cell_id", "cell_number", "predictor_design", "g", "m")]
}

pr2_seed_grid <- function(mode = c("certification", "smoke", "one_fit")) {
  mode <- match.arg(mode)
  reps <- if (mode == "certification") 400L else 1L
  cells <- pr2_cells()
  grid <- cells[rep(seq_len(nrow(cells)), each = reps), , drop = FALSE]
  grid$replicate <- rep(seq_len(reps), times = nrow(cells))
  seed_base <- if (mode == "certification") 2100000000L else 2090000000L
  grid$seed <- as.integer(
    seed_base - 10000L * grid$cell_number - grid$replicate
  )
  if (mode == "one_fit") {
    grid <- grid[1L, , drop = FALSE]
    grid$seed <- 2080000000L - 10000L * grid$cell_number - grid$replicate
  }
  rownames(grid) <- NULL
  grid
}

pr2_design_path <- function(repo_root) {
  file.path(
    repo_root,
    "docs/dev-log/simulation-designs",
    "2026-07-16-beta-phylo-q1-pr2-sd-regression",
    "design.tsv"
  )
}

pr2_frozen_design_sha256 <- function() {
  "e28e908cb832849977236a490545e2f9caa93dd79ecb0553c85292ad2da82927"
}

pr2_prior_manifest_path <- function(repo_root) {
  file.path(dirname(pr2_design_path(repo_root)), "prior-design-manifest.tsv")
}

pr2_seed_audit_path <- function(repo_root) {
  file.path(dirname(pr2_design_path(repo_root)), "seed-audit.tsv")
}

pr2_frozen_prior_manifest_sha256 <- function() {
  "517420047e8af797eee2eccb70033de497eca01b186b4fb49a82223950768c82"
}

pr2_frozen_seed_audit_sha256 <- function() {
  "cfd104ba75cf681554c21c5173236767b8ad5ea371e1abf4f2639570851da077"
}

pr2_sha256 <- function(path) {
  command <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  args <- if (identical(command, "shasum")) c("-a", "256", path) else path
  output <- system2(command, args, stdout = TRUE, stderr = TRUE)
  if (!identical(attr(output, "status") %||% 0L, 0L) || length(output) != 1L) {
    stop("Could not calculate SHA-256 for ", path, call. = FALSE)
  }
  strsplit(trimws(output), "[[:space:]]+")[[1L]][[1L]]
}

pr2_prior_design_paths <- function(repo_root) {
  manifest_path <- pr2_prior_manifest_path(repo_root)
  if (
    !file.exists(manifest_path) ||
      !identical(pr2_sha256(manifest_path), pr2_frozen_prior_manifest_sha256())
  ) {
    stop("Frozen PR 1 prior-design manifest is missing or unauthenticated.", call. = FALSE)
  }
  manifest <- utils::read.delim(
    manifest_path,
    stringsAsFactors = FALSE,
    colClasses = "character"
  )
  if (
    !identical(names(manifest), c("path", "sha256")) ||
      nrow(manifest) != 11L || anyDuplicated(manifest$path) || anyNA(manifest)
  ) {
    stop("Frozen PR 1 prior-design manifest is malformed.", call. = FALSE)
  }
  discovered <- list.files(
    file.path(repo_root, "docs/dev-log"),
    pattern = "design\\.tsv$",
    recursive = TRUE,
    full.names = TRUE
  )
  discovered <- sort(sub(
    paste0("^", normalizePath(repo_root, mustWork = TRUE), "/"),
    "",
    discovered[grepl("beta-phylo-q1-pr1", discovered, fixed = TRUE)]
  ))
  if (!identical(sort(manifest$path), discovered)) {
    stop("Tracked PR 1 design set does not equal the frozen manifest.", call. = FALSE)
  }
  paths <- file.path(repo_root, manifest$path)
  observed_hash <- vapply(paths, pr2_sha256, character(1L))
  if (!identical(unname(observed_hash), manifest$sha256)) {
    stop("A frozen PR 1 design hash does not match its manifest.", call. = FALSE)
  }
  paths
}

pr2_seed_audit <- function(grid, repo_root, mode) {
  integer_seed <- suppressWarnings(as.integer(grid$seed))
  if (
    !is.numeric(grid$seed) || anyNA(grid$seed) ||
      anyNA(integer_seed) || any(grid$seed != integer_seed)
  ) {
    stop("Current PR 2 seeds must be finite integers.", call. = FALSE)
  }
  prior_paths <- pr2_prior_design_paths(repo_root)
  if (!length(prior_paths)) {
    stop("No tracked PR 1 designs were found for seed authentication.", call. = FALSE)
  }
  prior <- lapply(prior_paths, function(path) {
    value <- utils::read.delim(path, stringsAsFactors = FALSE)
    if (!"seed" %in% names(value) || anyNA(value$seed)) {
      stop("Malformed prior design: ", path, call. = FALSE)
    }
    seed <- suppressWarnings(as.integer(value$seed))
    if (anyNA(seed) || any(as.character(seed) != as.character(value$seed))) {
      stop("Malformed prior design: ", path, call. = FALSE)
    }
    seed
  })
  names(prior) <- make.unique(basename(dirname(prior_paths)))
  siblings <- list(
    certification = pr2_seed_grid("certification")$seed,
    smoke = pr2_seed_grid("smoke")$seed,
    one_fit = pr2_seed_grid("one_fit")$seed
  )
  siblings[[mode]] <- NULL
  audit <- rbind(
    data.frame(
      check = "unique_current_seeds",
      observed = length(unique(grid$seed)),
      expected = nrow(grid),
      stringsAsFactors = FALSE
    ),
    do.call(rbind, lapply(names(prior), function(label) {
      data.frame(
        check = paste0("overlap_pr1_", label),
        observed = length(intersect(grid$seed, prior[[label]])),
        expected = 0L,
        stringsAsFactors = FALSE
      )
    })),
    do.call(rbind, lapply(names(siblings), function(label) {
      data.frame(
        check = paste0("overlap_pr2_", label),
        observed = length(intersect(grid$seed, siblings[[label]])),
        expected = 0L,
        stringsAsFactors = FALSE
      )
    }))
  )
  audit$pass <- audit$observed == audit$expected
  if (!all(audit$pass)) {
    stop(
      "PR 2 seed audit failed: ",
      paste(audit$check[!audit$pass], collapse = ", "),
      call. = FALSE
    )
  }
  audit
}

clean_pr2_text <- function(x) {
  trimws(gsub("[\r\n\t]+", " ", paste(as.character(x), collapse = " | ")))
}

pr2_standardize <- function(x) {
  as.numeric((x - mean(x)) / stats::sd(x))
}

beta_phylo_sd_regression_dgp <- function(g, m, predictor_design, seed) {
  with_pr2_rng(seed, {
    truth <- c(
      beta_mu_intercept = 0,
      beta_mu_x = 0.35,
      beta_sigma_intercept = log(0.25),
      beta_sigma_x = 0.20,
      alpha_intercept = log(0.30),
      alpha_x = 0.25
    )
    # Complete-DGP RNG order is frozen: tree, predictors, unit field, response.
    tree <- ape::rcoal(g)
    if (identical(predictor_design, "distinct")) {
      x_mu_species <- pr2_standardize(stats::rnorm(g))
      x_sigma_species <- pr2_standardize(stats::rnorm(g))
      x_tau_species <- pr2_standardize(stats::rnorm(g))
    } else if (identical(predictor_design, "shared")) {
      shared <- pr2_standardize(stats::rnorm(g))
      x_mu_species <- x_sigma_species <- x_tau_species <- shared
    } else {
      stop("Unknown predictor design: ", predictor_design, call. = FALSE)
    }
    A <- drmTMB:::drm_phylo_tip_covariance(tree)
    unit_tip <- as.vector(t(chol(A)) %*% stats::rnorm(g))
    tau <- exp(truth[["alpha_intercept"]] + truth[["alpha_x"]] * x_tau_species)
    location_effect <- tau * unit_tip
    names(location_effect) <- tree$tip.label
    spp_id <- factor(rep(tree$tip.label, each = m), levels = tree$tip.label)
    species_index <- rep(seq_len(g), each = m)
    x_mu <- x_mu_species[species_index]
    x_sigma <- x_sigma_species[species_index]
    x_tau <- x_tau_species[species_index]
    eta_mu <- truth[["beta_mu_intercept"]] +
      truth[["beta_mu_x"]] * x_mu + location_effect[as.character(spp_id)]
    log_sigma <- truth[["beta_sigma_intercept"]] +
      truth[["beta_sigma_x"]] * x_sigma
    mu <- stats::plogis(eta_mu)
    phi <- exp(-2 * log_sigma)
    y <- stats::rbeta(length(mu), mu * phi, (1 - mu) * phi)
    list(
      data = data.frame(y, x_mu, x_sigma, x_tau, spp_id),
      tree = tree,
      truth = truth
    )
  })
}

pr2_recovery_attempt <- function(row, identity = NULL) {
  started <- proc.time()[["elapsed"]]
  generated <- beta_phylo_sd_regression_dgp(
    row$g,
    row$m,
    row$predictor_design,
    row$seed
  )
  tree <- generated$tree
  warnings <- character()
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
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) {
      error <<- clean_pr2_text(conditionMessage(e))
      NULL
    }
  )
  elapsed <- proc.time()[["elapsed"]] - started
  estimate <- stats::setNames(rep(NA_real_, 6L), names(generated$truth))
  gradient <- numeric()
  condition_number <- NA_real_
  min_tau <- NA_real_
  max_tau <- NA_real_
  if (!is.null(fit)) {
    alpha <- fit$par[["sd_phylo(spp_id)"]]
    estimate <- c(
      beta_mu_intercept = fit$par$mu[[1L]],
      beta_mu_x = fit$par$mu[[2L]],
      beta_sigma_intercept = fit$par$sigma[[1L]],
      beta_sigma_x = fit$par$sigma[[2L]],
      alpha_intercept = alpha[[1L]],
      alpha_x = alpha[[2L]]
    )
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
  base <- data.frame(
    cell_id = row$cell_id,
    cell_number = row$cell_number,
    predictor_design = row$predictor_design,
    g = row$g,
    m = row$m,
    replicate = row$replicate,
    seed = row$seed,
    elapsed = elapsed,
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
    warning_count = length(warnings),
    warnings = clean_pr2_text(warnings),
    error = error,
    stringsAsFactors = FALSE
  )
  out <- cbind(
    base,
    as.data.frame(as.list(stats::setNames(
      generated$truth,
      paste0("truth_", names(generated$truth))
    ))),
    as.data.frame(as.list(stats::setNames(
      estimate,
      paste0("estimate_", names(estimate))
    )))
  )
  if (!is.null(identity)) {
    out <- cbind(out, identity[rep(1L, nrow(out)), , drop = FALSE])
  }
  out
}

pr2_parameters <- function() {
  c(
    "beta_mu_intercept",
    "beta_mu_x",
    "beta_sigma_intercept",
    "beta_sigma_x",
    "alpha_intercept",
    "alpha_x"
  )
}

pr2_finite_summary <- function(x, fun, ...) {
  x <- x[is.finite(x)]
  if (!length(x)) {
    return(NA_real_)
  }
  as.numeric(fun(x, ...))
}

summarize_pr2_recovery <- function(raw) {
  cells <- unique(raw[c("cell_id", "cell_number", "predictor_design", "g", "m")])
  do.call(rbind, lapply(seq_len(nrow(cells)), function(i) {
    rows <- raw[raw$cell_id == cells$cell_id[[i]], , drop = FALSE]
    do.call(rbind, lapply(pr2_parameters(), function(parameter) {
      estimate <- rows[[paste0("estimate_", parameter)]]
      truth <- rows[[paste0("truth_", parameter)]]
      finite <- is.finite(estimate) & is.finite(truth)
      error <- estimate[finite] - truth[finite]
      quantile <- if (length(error)) {
        stats::quantile(error, c(0.05, 0.50, 0.95), names = FALSE)
      } else {
        rep(NA_real_, 3L)
      }
      data.frame(
        cells[i, , drop = FALSE],
        parameter = parameter,
        attempted = nrow(rows),
        finite = sum(finite),
        bias = if (length(error)) mean(error) else NA_real_,
        mcse_bias = if (length(error) > 1L) stats::sd(error) / sqrt(length(error)) else NA_real_,
        rmse = if (length(error)) sqrt(mean(error^2)) else NA_real_,
        error_q05 = quantile[[1L]],
        error_median = quantile[[2L]],
        error_q95 = quantile[[3L]],
        stringsAsFactors = FALSE
      )
    }))
  }))
}

pr2_recovery_gates <- function(raw, expected_reps, certification = FALSE) {
  expected <- pr2_seed_grid(if (certification) "certification" else "smoke")
  key <- c("cell_id", "cell_number", "predictor_design", "g", "m", "replicate", "seed")
  if (
    nrow(raw) != nrow(expected) ||
      anyDuplicated(paste(raw$cell_id, raw$replicate, raw$seed)) ||
      !isTRUE(all.equal(raw[key], expected[key], tolerance = 0, check.attributes = FALSE))
  ) {
    stop("Retained attempts do not equal the complete frozen design.", call. = FALSE)
  }
  summary <- summarize_pr2_recovery(raw)
  cells <- unique(raw[c("cell_id", "cell_number", "predictor_design", "g", "m")])
  estimate_columns <- paste0("estimate_", pr2_parameters())
  quality <- do.call(rbind, lapply(seq_len(nrow(cells)), function(i) {
    rows <- raw[raw$cell_id == cells$cell_id[[i]], , drop = FALSE]
    finite <- all(vapply(rows[estimate_columns], function(x) all(is.finite(x)), logical(1L)))
    data.frame(
      cells[i, , drop = FALSE],
      attempted = nrow(rows),
      convergence_rate = mean(!is.na(rows$convergence) & rows$convergence == 0L),
      pdHess_rate = mean(rows$pdHess %in% TRUE),
      all_six_finite = finite,
      warning_attempts = sum(rows$warning_count > 0L, na.rm = TRUE),
      warning_count_total = sum(rows$warning_count, na.rm = TRUE),
      error_attempts = sum(!is.na(rows$error) & nzchar(rows$error)),
      hessian_condition_median = pr2_finite_summary(
        rows$fixed_hessian_condition,
        stats::median
      ),
      hessian_condition_q95 = pr2_finite_summary(
        rows$fixed_hessian_condition,
        stats::quantile,
        probs = 0.95,
        names = FALSE
      ),
      stringsAsFactors = FALSE
    )
  }))
  quality$quality_pass <- quality$attempted == expected_reps &
    quality$convergence_rate >= 0.95 &
    quality$pdHess_rate >= 0.95 &
    quality$all_six_finite &
    quality$warning_attempts == 0L &
    quality$error_attempts == 0L

  summary$mc_lower <- summary$bias - 1.96 * summary$mcse_bias
  summary$mc_upper <- summary$bias + 1.96 * summary$mcse_bias
  summary$parameter_pass <- ifelse(
    summary$parameter %in% c("alpha_intercept", "alpha_x"),
    is.finite(summary$mc_lower) & summary$mc_lower >= -0.10 &
      is.finite(summary$mc_upper) & summary$mc_upper <= 0.10,
    is.finite(summary$bias) & abs(summary$bias) <= 0.10
  )
  summary$parameter_pass <- summary$parameter_pass &
    summary$attempted == expected_reps & summary$finite == expected_reps

  shared <- raw[raw$predictor_design == "shared", , drop = FALSE]
  shared_correlations <- do.call(rbind, lapply(unique(shared$cell_id), function(id) {
    rows <- shared[shared$cell_id == id, , drop = FALSE]
    columns <- paste0("estimate_", c("beta_mu_x", "beta_sigma_x", "alpha_x"))
    matrix <- as.matrix(rows[columns])
    variable_columns <- if (nrow(matrix) > 1L && all(is.finite(matrix))) {
      apply(matrix, 2L, stats::sd) > 0
    } else {
      rep(FALSE, ncol(matrix))
    }
    corr <- if (nrow(matrix) > 2L && all(variable_columns)) {
      stats::cor(matrix)
    } else {
      matrix(NA_real_, 3L, 3L, dimnames = list(columns, columns))
    }
    pairs <- which(upper.tri(corr), arr.ind = TRUE)
    data.frame(
      cell_id = id,
      from = colnames(corr)[pairs[, 1L]],
      to = colnames(corr)[pairs[, 2L]],
      correlation = corr[pairs],
      stringsAsFactors = FALSE
    )
  }))

  promotion <- quality$g == 1024L & quality$m == 4L
  promotion_cells <- quality[promotion, c("cell_id", "predictor_design"), drop = FALSE]
  promotion_cells$pass <- FALSE
  if (certification) {
    promotion_cells$pass <- vapply(promotion_cells$cell_id, function(id) {
      quality$quality_pass[quality$cell_id == id] &&
        all(summary$parameter_pass[summary$cell_id == id])
    }, logical(1L))
  }
  promotion_value <- function(design) {
    value <- promotion_cells$pass[
      promotion_cells$predictor_design == design
    ]
    if (length(value) != 1L || is.na(value)) FALSE else isTRUE(value)
  }
  decision <- data.frame(
    distinct_g1024_m4 = promotion_value("distinct"),
    shared_g1024_m4 = promotion_value("shared"),
    status = if (!certification) {
      "SMOKE_ONLY_NO_PROMOTION"
    } else if (nrow(promotion_cells) == 2L && all(promotion_cells$pass)) {
      "PASS_EXACT_TWO_G1024_M4"
    } else {
      "HOLD_NO_PR2_PROMOTION"
    },
    stringsAsFactors = FALSE
  )
  list(
    summary = summary,
    quality = quality,
    shared_correlations = shared_correlations,
    promotion_cells = promotion_cells,
    decision = decision
  )
}

write_pr2_tsv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile("atomic-", tmpdir = dirname(path), fileext = ".tsv")
  on.exit(unlink(temporary), add = TRUE)
  utils::write.table(
    x,
    temporary,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = "NA"
  )
  if (!file.rename(temporary, path)) {
    stop("Could not move output into place: ", path, call. = FALSE)
  }
  invisible(path)
}

pr2_identity_columns <- function() {
  c(
    "source_git_head",
    "source_git_tree",
    "runner_sha256",
    "design_sha256",
    "prior_manifest_sha256",
    "tracked_seed_audit_sha256",
    "dll_sha256"
  )
}

pr2_attempt_columns <- function() {
  c(
    "cell_id", "cell_number", "predictor_design", "g", "m", "replicate",
    "seed", "elapsed", "fit_success", "convergence", "pdHess",
    "max_gradient", "fixed_hessian_condition", "min_tau", "max_tau",
    "warning_count", "warnings", "error",
    paste0("truth_", pr2_parameters()),
    paste0("estimate_", pr2_parameters()),
    pr2_identity_columns()
  )
}

pr2_attempt_col_classes <- function() {
  columns <- pr2_attempt_columns()
  classes <- stats::setNames(rep("numeric", length(columns)), columns)
  classes[c(
    "cell_id", "predictor_design", "warnings", "error", pr2_identity_columns()
  )] <- "character"
  classes[c(
    "cell_number", "g", "m", "replicate", "seed", "convergence", "warning_count"
  )] <- "integer"
  classes[c("fit_success", "pdHess")] <- "logical"
  unname(classes)
}

pr2_source_identity <- function(context) {
  git <- Sys.which("git")
  dll_path <- getLoadedDLLs()[["drmTMB"]][["path"]]
  data.frame(
    source_git_head = trimws(system2(
      git,
      c("-C", context$repo_root, "rev-parse", "HEAD"),
      stdout = TRUE
    )),
    source_git_tree = trimws(system2(
      git,
      c("-C", context$repo_root, "rev-parse", "HEAD^{tree}"),
      stdout = TRUE
    )),
    runner_sha256 = pr2_sha256(context$script_path),
    design_sha256 = pr2_sha256(pr2_design_path(context$repo_root)),
    prior_manifest_sha256 = pr2_sha256(pr2_prior_manifest_path(context$repo_root)),
    tracked_seed_audit_sha256 = pr2_sha256(pr2_seed_audit_path(context$repo_root)),
    dll_sha256 = pr2_sha256(dll_path),
    stringsAsFactors = FALSE
  )
}

pr2_same_source <- function(observed, expected, include_dll = FALSE) {
  columns <- setdiff(pr2_identity_columns(), "dll_sha256")
  if (include_dll) {
    columns <- pr2_identity_columns()
  }
  all(vapply(columns, function(column) {
    identical(as.character(observed[[column]]), as.character(expected[[column]]))
  }, logical(1L)))
}

acquire_pr2_lock <- function(out_dir) {
  lock_dir <- paste0(out_dir, ".lock")
  dir.create(dirname(lock_dir), recursive = TRUE, showWarnings = FALSE)
  if (!dir.create(lock_dir, showWarnings = FALSE)) {
    stop(
      "Output lock already exists: ", lock_dir,
      ". Verify that no runner owns it before removing a stale lock.",
      call. = FALSE
    )
  }
  write_pr2_tsv(
    data.frame(
      pid = Sys.getpid(),
      host = Sys.info()[["nodename"]],
      acquired_at = format(Sys.time(), tz = "UTC", usetz = TRUE),
      stringsAsFactors = FALSE
    ),
    file.path(lock_dir, "owner.tsv")
  )
  lock_dir
}

release_pr2_lock <- function(lock_dir) {
  unlink(lock_dir, recursive = TRUE)
  invisible(!dir.exists(lock_dir))
}

pr2_attempt_path <- function(shard_dir, row) {
  file.path(
    shard_dir,
    sprintf("%s-r%04d-s%d.tsv", row$cell_id, row$replicate, row$seed)
  )
}

pr2_shard_seal_path <- function(path) {
  paste0(path, ".sha256.tsv")
}

validate_pr2_shard <- function(path, row, identity) {
  seal_path <- pr2_shard_seal_path(path)
  if (!file.exists(path) || !file.exists(seal_path)) {
    stop("Retained shard or its seal is missing: ", path, call. = FALSE)
  }
  seal <- utils::read.delim(
    seal_path,
    stringsAsFactors = FALSE,
    colClasses = "character"
  )
  if (
    !identical(names(seal), "sha256") || nrow(seal) != 1L ||
      !identical(seal$sha256[[1L]], pr2_sha256(path))
  ) {
    stop("Retained shard hash authentication failed: ", path, call. = FALSE)
  }
  value <- utils::read.delim(
    path,
    stringsAsFactors = FALSE,
    colClasses = pr2_attempt_col_classes()
  )
  if (nrow(value) != 1L || !identical(names(value), pr2_attempt_columns())) {
    stop("Retained shard schema is malformed: ", path, call. = FALSE)
  }
  keys <- c(
    "cell_id", "cell_number", "predictor_design", "g", "m", "replicate", "seed"
  )
  key_ok <- all(vapply(keys, function(key) {
    identical(as.character(value[[key]]), as.character(row[[key]]))
  }, logical(1L)))
  truth <- c(
    beta_mu_intercept = 0,
    beta_mu_x = 0.35,
    beta_sigma_intercept = log(0.25),
    beta_sigma_x = 0.20,
    alpha_intercept = log(0.30),
    alpha_x = 0.25
  )
  truth_ok <- all(vapply(names(truth), function(parameter) {
    isTRUE(all.equal(
      value[[paste0("truth_", parameter)]],
      unname(truth[[parameter]]),
      tolerance = 1e-14,
      check.attributes = FALSE
    ))
  }, logical(1L)))
  identity_ok <- pr2_same_source(value, identity, include_dll = TRUE)
  content_ok <- is.finite(value$elapsed[[1L]]) && value$elapsed[[1L]] >= 0 &&
    !is.na(value$fit_success[[1L]]) && !is.na(value$pdHess[[1L]]) &&
    !is.na(value$warning_count[[1L]]) && value$warning_count[[1L]] >= 0L &&
    is.character(value$warnings) && is.character(value$error)
  if (!key_ok || !truth_ok || !identity_ok || !content_ok) {
    stop("Retained shard key, truth, or source identity is malformed: ", path, call. = FALSE)
  }
  value
}

write_pr2_shard <- function(value, path, row, identity) {
  if (!identical(names(value), pr2_attempt_columns())) {
    stop("Attempt schema changed before shard write.", call. = FALSE)
  }
  write_pr2_tsv(value, path)
  write_pr2_tsv(
    data.frame(sha256 = pr2_sha256(path), stringsAsFactors = FALSE),
    pr2_shard_seal_path(path)
  )
  validate_pr2_shard(path, row, identity)
}

pr2_manifest_paths <- function(out_dir) {
  out_dir <- normalizePath(out_dir, mustWork = TRUE)
  paths <- list.files(out_dir, recursive = TRUE, full.names = TRUE, all.files = TRUE)
  paths <- paths[file.info(paths)$isdir %in% FALSE]
  excluded <- file.path(out_dir, c("output-manifest.tsv", "completion-seal.tsv"))
  sort(setdiff(paths, excluded))
}

write_pr2_output_manifest <- function(out_dir) {
  out_dir <- normalizePath(out_dir, mustWork = TRUE)
  paths <- pr2_manifest_paths(out_dir)
  relative <- substring(paths, nchar(normalizePath(out_dir, mustWork = TRUE)) + 2L)
  manifest <- data.frame(
    path = relative,
    bytes = unname(file.info(paths)$size),
    sha256 = vapply(paths, pr2_sha256, character(1L)),
    stringsAsFactors = FALSE
  )
  manifest_path <- file.path(out_dir, "output-manifest.tsv")
  write_pr2_tsv(manifest, manifest_path)
  write_pr2_tsv(
    data.frame(
      manifest_sha256 = pr2_sha256(manifest_path),
      stringsAsFactors = FALSE
    ),
    file.path(out_dir, "completion-seal.tsv")
  )
  invisible(manifest)
}

authenticate_pr2_output <- function(out_dir) {
  manifest_path <- file.path(out_dir, "output-manifest.tsv")
  seal_path <- file.path(out_dir, "completion-seal.tsv")
  provenance_path <- file.path(out_dir, "run-provenance.tsv")
  if (!all(file.exists(c(manifest_path, seal_path, provenance_path)))) {
    stop("Authenticated COMPLETE output is missing from: ", out_dir, call. = FALSE)
  }
  seal <- utils::read.delim(
    seal_path,
    stringsAsFactors = FALSE,
    colClasses = "character"
  )
  if (
    !identical(names(seal), "manifest_sha256") || nrow(seal) != 1L ||
      !identical(seal$manifest_sha256[[1L]], pr2_sha256(manifest_path))
  ) {
    stop("Output manifest seal failed authentication: ", out_dir, call. = FALSE)
  }
  manifest <- utils::read.delim(
    manifest_path,
    stringsAsFactors = FALSE,
    colClasses = c("character", "numeric", "character")
  )
  if (
    !identical(names(manifest), c("path", "bytes", "sha256")) ||
      anyDuplicated(manifest$path) || anyNA(manifest)
  ) {
    stop("Output manifest is malformed: ", out_dir, call. = FALSE)
  }
  paths <- pr2_manifest_paths(out_dir)
  relative <- substring(paths, nchar(normalizePath(out_dir, mustWork = TRUE)) + 2L)
  if (!identical(manifest$path, relative)) {
    stop("Output file set differs from its manifest: ", out_dir, call. = FALSE)
  }
  observed_bytes <- unname(file.info(paths)$size)
  observed_hash <- vapply(paths, pr2_sha256, character(1L))
  if (
    !identical(as.numeric(manifest$bytes), as.numeric(observed_bytes)) ||
      !identical(manifest$sha256, unname(observed_hash))
  ) {
    stop("Output file hash or size differs from its manifest: ", out_dir, call. = FALSE)
  }
  provenance <- utils::read.delim(
    provenance_path,
    stringsAsFactors = FALSE,
    colClasses = "character"
  )
  if (nrow(provenance) != 1L || !identical(provenance$status[[1L]], "COMPLETE")) {
    stop("Output provenance is not COMPLETE: ", out_dir, call. = FALSE)
  }
  provenance
}

pr2_allowed_host <- function(host = Sys.info()[["nodename"]]) {
  grepl("^totoro([.-]|$)", tolower(host)) ||
    (nzchar(Sys.getenv("SLURM_JOB_ID")) &&
      tolower(Sys.getenv("CC_CLUSTER")) %in%
        c("fir", "nibi", "rorqual", "trillium", "narval", "killarney", "vulcan", "tamia"))
}

pr2_thread_variables <- function() {
  c(
    "OPENBLAS_NUM_THREADS",
    "OMP_NUM_THREADS",
    "MKL_NUM_THREADS",
    "VECLIB_MAXIMUM_THREADS",
    "BLIS_NUM_THREADS"
  )
}

pr2_thread_guard <- function(environment = Sys.getenv(pr2_thread_variables())) {
  data.frame(
    variable = pr2_thread_variables(),
    observed = unname(environment[pr2_thread_variables()]),
    expected = "1",
    pass = unname(environment[pr2_thread_variables()]) == "1",
    stringsAsFactors = FALSE
  )
}

pr2_preflight <- function(repo_root, design_path, require_compute_host = TRUE) {
  git <- Sys.which("git")
  prior_manifest_path <- pr2_prior_manifest_path(repo_root)
  tracked_seed_audit_path <- pr2_seed_audit_path(repo_root)
  protected <- c(
    "DESCRIPTION",
    "NAMESPACE",
    "R",
    "src",
    "R/methods.R",
    "tests/testthat/test-beta-location-scale.R",
    "tests/testthat/test-beta-phylo-direct-sd.R",
    "tests/testthat/test-beta-phylo-q1-sd-regression-runner.R",
    "tools/run-beta-phylo-q1-sd-regression-recovery.R",
    "docs/dev-log/2026-07-16-beta-phylo-q1-pr2-symbolic-alignment.md",
    file.path(
      "docs/dev-log/simulation-designs",
      "2026-07-16-beta-phylo-q1-pr2-sd-regression",
      "design.tsv"
    ),
    file.path(
      "docs/dev-log/simulation-designs",
      "2026-07-16-beta-phylo-q1-pr2-sd-regression",
      "prior-design-manifest.tsv"
    ),
    file.path(
      "docs/dev-log/simulation-designs",
      "2026-07-16-beta-phylo-q1-pr2-sd-regression",
      "seed-audit.tsv"
    )
  )
  status <- system2(
    git,
    c("-C", repo_root, "status", "--porcelain", "--untracked-files=all", "--", protected),
    stdout = TRUE,
    stderr = TRUE
  )
  rows <- list()
  add <- function(check, observed, expected, pass = identical(observed, expected)) {
    rows[[length(rows) + 1L]] <<- data.frame(
      check,
      observed = as.character(observed),
      expected = as.character(expected),
      pass = isTRUE(pass),
      stringsAsFactors = FALSE
    )
  }
  add("protected_paths_clean", length(status), 0L)
  add(
    "frozen_design_sha256",
    if (file.exists(design_path)) pr2_sha256(design_path) else NA_character_,
    pr2_frozen_design_sha256()
  )
  add(
    "prior_manifest_sha256",
    if (file.exists(prior_manifest_path)) pr2_sha256(prior_manifest_path) else NA_character_,
    pr2_frozen_prior_manifest_sha256()
  )
  add(
    "tracked_seed_audit_sha256",
    if (file.exists(tracked_seed_audit_path)) pr2_sha256(tracked_seed_audit_path) else NA_character_,
    pr2_frozen_seed_audit_sha256()
  )
  add("TMB_version", as.character(utils::packageVersion("TMB")), "1.9.21")
  add(
    "RNG_kind",
    paste(pr2_rng_kind(), collapse = "/"),
    "L'Ecuyer-CMRG/Inversion/Rejection"
  )
  add(
    "compute_host",
    Sys.info()[["nodename"]],
    "Totoro or active named DRAC allocation",
    !require_compute_host || pr2_allowed_host()
  )
  add(
    "not_github_actions",
    Sys.getenv("GITHUB_ACTIONS", unset = "false"),
    "false",
    !tolower(Sys.getenv("GITHUB_ACTIONS", unset = "false")) %in% c("1", "true", "yes")
  )
  thread_guard <- pr2_thread_guard()
  for (i in seq_len(nrow(thread_guard))) {
    add(
      thread_guard$variable[[i]],
      thread_guard$observed[[i]],
      thread_guard$expected[[i]],
      thread_guard$pass[[i]]
    )
  }
  blas_path <- unname(extSoftVersion()[["BLAS"]])
  add("active_BLAS", blas_path, "non-empty recorded path", nzchar(blas_path))
  git_head <- trimws(system2(git, c("-C", repo_root, "rev-parse", "HEAD"), stdout = TRUE))
  git_tree <- trimws(system2(
    git,
    c("-C", repo_root, "rev-parse", "HEAD^{tree}"),
    stdout = TRUE
  ))
  add(
    "git_head",
    git_head,
    "40-character commit",
    length(git_head) == 1L && grepl("^[0-9a-f]{40}$", git_head)
  )
  add(
    "git_tree",
    git_tree,
    "40-character tree",
    length(git_tree) == 1L && grepl("^[0-9a-f]{40}$", git_tree)
  )
  out <- do.call(rbind, rows)
  if (!all(out$pass)) {
    stop(
      "PR 2 preflight failed: ",
      paste(out$check[!out$pass], collapse = ", "),
      call. = FALSE
    )
  }
  out
}

prepare_pr2_output <- function(out_dir, grid, audit, preflight, resume = FALSE) {
  design_path <- file.path(out_dir, "design.tsv")
  audit_path <- file.path(out_dir, "seed-audit.tsv")
  preflight_path <- file.path(out_dir, "preflight-manifest.tsv")
  if (!resume) {
    if (dir.exists(out_dir) && length(list.files(out_dir, all.files = TRUE, no.. = TRUE))) {
      stop("Output directory is not empty: ", out_dir, call. = FALSE)
    }
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    write_pr2_tsv(grid, design_path)
    write_pr2_tsv(audit, audit_path)
    write_pr2_tsv(preflight, preflight_path)
  } else {
    observed_grid <- utils::read.delim(design_path, stringsAsFactors = FALSE)
    observed_audit <- utils::read.delim(audit_path, stringsAsFactors = FALSE)
    observed_preflight <- utils::read.delim(
      preflight_path,
      stringsAsFactors = FALSE,
      colClasses = c("character", "character", "character", "logical")
    )
    if (
      !identical(observed_grid, grid) ||
        !identical(observed_audit, audit) ||
        !identical(observed_preflight, preflight)
    ) {
      stop("Resume metadata does not match the frozen run.", call. = FALSE)
    }
  }
  shard_dir <- file.path(out_dir, "attempts")
  dir.create(shard_dir, recursive = TRUE, showWarnings = FALSE)
  shard_dir
}

pr2_default_output <- function(repo_root, mode) {
  file.path(
    repo_root,
    "docs/dev-log/simulation-artifacts",
    paste0("2026-07-16-beta-phylo-q1-pr2-sd-regression-", mode)
  )
}

authenticate_pr2_stage_output <- function(out_dir, expected_mode, expected_attempts) {
  provenance <- authenticate_pr2_output(out_dir)
  if (
    provenance$mode[[1L]] != expected_mode ||
      as.integer(provenance$attempts[[1L]]) != expected_attempts
  ) {
    stop("Authenticated stage mode or attempt count is wrong: ", out_dir, call. = FALSE)
  }
  raw <- utils::read.delim(
    file.path(out_dir, "raw-attempts.tsv"),
    stringsAsFactors = FALSE
  )
  if (nrow(raw) != expected_attempts) {
    stop("Authenticated stage raw-attempt count is wrong: ", out_dir, call. = FALSE)
  }
  if (expected_mode == "one_fit") {
    estimate_columns <- paste0("estimate_", pr2_parameters())
    passed <- all(estimate_columns %in% names(raw)) &&
      isTRUE(raw$fit_success[[1L]]) && raw$convergence[[1L]] == 0L &&
      isTRUE(raw$pdHess[[1L]]) &&
      all(is.finite(unlist(raw[1L, estimate_columns], use.names = FALSE))) &&
      is.finite(raw$max_gradient[[1L]]) &&
      is.finite(raw$fixed_hessian_condition[[1L]]) &&
      raw$warning_count[[1L]] == 0L &&
      (is.na(raw$error[[1L]]) || !nzchar(raw$error[[1L]]))
    if (!passed) {
      stop("Authenticated one-fit stage did not pass its diagnostic gate.", call. = FALSE)
    }
  }
  if (expected_mode == "smoke") {
    quality <- utils::read.delim(
      file.path(out_dir, "quality-gates.tsv"),
      stringsAsFactors = FALSE
    )
    decision <- utils::read.delim(
      file.path(out_dir, "promotion-decision.tsv"),
      stringsAsFactors = FALSE
    )
    passed <- nrow(quality) == 12L && all(quality$quality_pass %in% TRUE) &&
      nrow(decision) == 1L &&
      decision$status[[1L]] == "SMOKE_ONLY_NO_PROMOTION" &&
      !decision$distinct_g1024_m4[[1L]] &&
      !decision$shared_g1024_m4[[1L]]
    if (!passed) {
      stop("Authenticated smoke stage did not pass all 12 mechanical cells.", call. = FALSE)
    }
  }
  provenance
}

authorize_pr2_stage <- function(args, context, identity) {
  if (args$mode == "one_fit") {
    return(invisible(TRUE))
  }
  one_fit_dir <- args$one_fit %||% pr2_default_output(context$repo_root, "one_fit")
  one_fit <- authenticate_pr2_stage_output(one_fit_dir, "one_fit", 1L)
  if (!pr2_same_source(one_fit, identity, include_dll = FALSE)) {
    stop("One-fit authorization does not match the current frozen source.", call. = FALSE)
  }
  if (args$mode == "smoke") {
    return(invisible(TRUE))
  }
  smoke_dir <- args$smoke %||% pr2_default_output(context$repo_root, "smoke")
  smoke <- authenticate_pr2_stage_output(smoke_dir, "smoke", 12L)
  if (!pr2_same_source(smoke, identity, include_dll = TRUE)) {
    stop(
      "Smoke authorization does not match the current source and compiled DLL.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

resume_pr2_provenance <- function(provenance, mode, attempts, identity) {
  if (
    nrow(provenance) != 1L ||
      !provenance$status[[1L]] %in% c("PRE_DISPATCH", "COMPLETE") ||
      provenance$mode[[1L]] != mode ||
      as.integer(provenance$attempts[[1L]]) != attempts ||
      !pr2_same_source(provenance, identity, include_dll = TRUE)
  ) {
    stop("Resume provenance does not authenticate the interrupted run.", call. = FALSE)
  }
  provenance$status <- "PRE_DISPATCH"
  provenance$completed_at <- NA_character_
  provenance
}

run_pr2_recovery <- function(args = parse_pr2_args()) {
  context <- pr2_context()
  design_path <- pr2_design_path(context$repo_root)
  certification_grid <- pr2_seed_grid("certification")
  if (args$mode == "design") {
    out_dir <- args$output %||% dirname(design_path)
    if (dir.exists(out_dir) && length(list.files(out_dir, all.files = TRUE, no.. = TRUE))) {
      stop("Design output directory is not empty: ", out_dir, call. = FALSE)
    }
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    write_pr2_tsv(certification_grid, file.path(out_dir, "design.tsv"))
    write_pr2_tsv(
      pr2_seed_audit(certification_grid, context$repo_root, "certification"),
      file.path(out_dir, "seed-audit.tsv")
    )
    return(invisible(certification_grid))
  }
  observed_design <- utils::read.delim(design_path, stringsAsFactors = FALSE)
  if (!identical(observed_design, certification_grid)) {
    stop("Frozen PR 2 design does not equal the generated certification grid.", call. = FALSE)
  }
  grid_mode <- if (args$mode == "certification") "certification" else args$mode
  grid <- pr2_seed_grid(grid_mode)
  audit <- pr2_seed_audit(grid, context$repo_root, grid_mode)
  preflight <- pr2_preflight(
    context$repo_root,
    design_path,
    require_compute_host = args$mode != "one_fit"
  )
  out_dir <- args$output %||% pr2_default_output(context$repo_root, args$mode)
  lock_dir <- acquire_pr2_lock(out_dir)
  on.exit(release_pr2_lock(lock_dir), add = TRUE)
  shard_dir <- prepare_pr2_output(out_dir, grid, audit, preflight, args$resume)
  devtools::load_all(context$repo_root, quiet = TRUE)
  identity <- pr2_source_identity(context)
  authorize_pr2_stage(args, context, identity)
  provenance_path <- file.path(out_dir, "run-provenance.tsv")
  if (args$resume) {
    completion_files <- file.path(
      out_dir,
      c("output-manifest.tsv", "completion-seal.tsv")
    )
    if (all(file.exists(completion_files))) {
      authenticate_pr2_output(out_dir)
      stop("The requested output is already authenticated and COMPLETE.", call. = FALSE)
    }
    provenance <- utils::read.delim(
      provenance_path,
      stringsAsFactors = FALSE,
      colClasses = "character"
    )
    provenance <- resume_pr2_provenance(
      provenance,
      args$mode,
      nrow(grid),
      identity
    )
    write_pr2_tsv(provenance, provenance_path)
  } else {
    provenance <- cbind(
      data.frame(
        status = "PRE_DISPATCH",
        mode = args$mode,
        attempts = nrow(grid),
        started_at = format(Sys.time(), tz = "UTC", usetz = TRUE),
        completed_at = NA_character_,
        rng_kind = paste(pr2_rng_kind(), collapse = "/"),
        package_version = as.character(utils::packageVersion("drmTMB")),
        TMB_version = as.character(utils::packageVersion("TMB")),
        host = Sys.info()[["nodename"]],
        active_blas = unname(extSoftVersion()[["BLAS"]]),
        stringsAsFactors = FALSE
      ),
      identity
    )
    write_pr2_tsv(provenance, provenance_path)
  }
  rows <- split(grid, seq_len(nrow(grid)))
  worker <- function(row) {
    row <- row[1L, , drop = FALSE]
    path <- pr2_attempt_path(shard_dir, row)
    if (file.exists(path)) {
      return(validate_pr2_shard(path, row, identity))
    }
    value <- pr2_recovery_attempt(row, identity)
    write_pr2_shard(value, path, row, identity)
  }
  result <- if (args$cores == 1L || .Platform$OS.type == "windows") {
    lapply(rows, worker)
  } else {
    parallel::mclapply(rows, worker, mc.cores = args$cores, mc.preschedule = FALSE)
  }
  if (any(vapply(result, inherits, logical(1L), "try-error"))) {
    stop("One or more workers failed; completed shards were retained.", call. = FALSE)
  }
  raw <- do.call(rbind, result)
  rownames(raw) <- NULL
  if (args$mode == "one_fit") {
    gates <- NULL
  } else {
    gates <- pr2_recovery_gates(
      raw,
      expected_reps = if (args$mode == "certification") 400L else 1L,
      certification = args$mode == "certification"
    )
  }
  write_pr2_tsv(raw, file.path(out_dir, "raw-attempts.tsv"))
  if (!is.null(gates)) {
    write_pr2_tsv(gates$summary, file.path(out_dir, "summary.tsv"))
    write_pr2_tsv(gates$quality, file.path(out_dir, "quality-gates.tsv"))
    write_pr2_tsv(
      gates$shared_correlations,
      file.path(out_dir, "shared-slope-correlations.tsv")
    )
    write_pr2_tsv(
      gates$promotion_cells,
      file.path(out_dir, "promotion-cells.tsv")
    )
    write_pr2_tsv(gates$decision, file.path(out_dir, "promotion-decision.tsv"))
  }
  writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
  provenance$status <- "COMPLETE"
  provenance$completed_at <- format(Sys.time(), tz = "UTC", usetz = TRUE)
  write_pr2_tsv(provenance, provenance_path)
  write_pr2_output_manifest(out_dir)
  authenticated <- authenticate_pr2_output(out_dir)
  if (!pr2_same_source(authenticated, identity, include_dll = TRUE)) {
    stop("Final output read-back changed source identity.", call. = FALSE)
  }
  invisible(c(list(raw = raw), gates %||% list()))
}

if (sys.nframe() == 0L) {
  run_pr2_recovery()
}
