args <- commandArgs(trailingOnly = TRUE)

parse_args <- function(args) {
  out <- list(
    output_dir = "docs/dev-log/simulation-artifacts/2026-06-29-count-intercept-recovery-grid-local",
    n_rep = 80L,
    seed_start = 2026062901L,
    cores = 2L,
    backend = "multicore",
    lanes = "ordinary_structured,phylo_formal,phylo_interaction",
    families = "poisson,nbinom2",
    overwrite = FALSE
  )
  for (arg in args) {
    if (startsWith(arg, "--output_dir=")) {
      out$output_dir <- sub("^--output_dir=", "", arg)
    } else if (startsWith(arg, "--n_rep=")) {
      out$n_rep <- as.integer(sub("^--n_rep=", "", arg))
    } else if (startsWith(arg, "--seed_start=")) {
      out$seed_start <- as.integer(sub("^--seed_start=", "", arg))
    } else if (startsWith(arg, "--cores=")) {
      out$cores <- as.integer(sub("^--cores=", "", arg))
    } else if (startsWith(arg, "--backend=")) {
      out$backend <- sub("^--backend=", "", arg)
    } else if (startsWith(arg, "--lanes=")) {
      out$lanes <- sub("^--lanes=", "", arg)
    } else if (startsWith(arg, "--families=")) {
      out$families <- sub("^--families=", "", arg)
    } else if (identical(arg, "--overwrite")) {
      out$overwrite <- TRUE
    } else {
      stop("Unknown argument: ", arg, call. = FALSE)
    }
  }
  if (!is.finite(out$n_rep) || out$n_rep < 1L) {
    stop("`--n_rep` must be a positive integer.", call. = FALSE)
  }
  if (!is.finite(out$seed_start) || out$seed_start < 1L) {
    stop("`--seed_start` must be a positive integer.", call. = FALSE)
  }
  if (!is.finite(out$cores) || out$cores < 1L) {
    stop("`--cores` must be a positive integer.", call. = FALSE)
  }
  if (!out$backend %in% c("none", "multicore")) {
    stop("`--backend` must be `none` or `multicore`.", call. = FALSE)
  }
  parse_csv <- function(x) {
    x <- trimws(strsplit(x, ",", fixed = TRUE)[[1L]])
    x[nzchar(x)]
  }
  out$lanes <- unique(parse_csv(out$lanes))
  if ("all" %in% out$lanes) {
    out$lanes <- c("ordinary_structured", "phylo_formal", "phylo_interaction")
  }
  valid_lanes <- c("ordinary_structured", "phylo_formal", "phylo_interaction")
  unknown_lanes <- setdiff(out$lanes, valid_lanes)
  if (length(unknown_lanes)) {
    stop(
      "`--lanes` has unknown values: ",
      paste(unknown_lanes, collapse = ", "),
      call. = FALSE
    )
  }
  if (!length(out$lanes)) {
    stop("`--lanes` must select at least one lane.", call. = FALSE)
  }
  out$families <- unique(parse_csv(out$families))
  if ("all" %in% out$families) {
    out$families <- c("poisson", "nbinom2")
  }
  valid_families <- c("poisson", "nbinom2")
  unknown_families <- setdiff(out$families, valid_families)
  if (length(unknown_families)) {
    stop(
      "`--families` has unknown values: ",
      paste(unknown_families, collapse = ", "),
      call. = FALSE
    )
  }
  if (!length(out$families)) {
    stop("`--families` must select at least one family.", call. = FALSE)
  }
  out
}

opts <- parse_args(args)
artifact_dir <- normalizePath(opts$output_dir, mustWork = FALSE)
artifact_url <- opts$output_dir
if (dir.exists(artifact_dir) && !isTRUE(opts$overwrite)) {
  stop(
    "Output directory already exists. Use --overwrite to replace it: ",
    artifact_dir,
    call. = FALSE
  )
}
if (dir.exists(artifact_dir) && isTRUE(opts$overwrite)) {
  unlink(artifact_dir, recursive = TRUE, force = TRUE)
}
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(
  file.path(artifact_dir, "logs"),
  recursive = TRUE,
  showWarnings = FALSE
)
dir.create(
  file.path(artifact_dir, "tables"),
  recursive = TRUE,
  showWarnings = FALSE
)

repo_root <- normalizePath(getwd(), mustWork = TRUE)
rscript <- file.path(R.home("bin"), "Rscript")

run_action_task <- function(
  task,
  subdir,
  master_seed,
  condition_shard = 1L,
  condition_shards = 1L,
  condition_set = "all"
) {
  output_dir <- file.path(artifact_dir, subdir)
  log_path <- file.path(artifact_dir, "logs", paste0(subdir, ".log"))
  cmd_args <- c(
    "--no-init-file",
    file.path(repo_root, "inst/sim/run/sim_run_actions_cell.R"),
    paste0("--task=", task),
    paste0("--output-dir=", output_dir),
    paste0("--n-reps=", opts$n_rep),
    paste0("--master-seed=", master_seed),
    paste0("--cores=", opts$cores),
    paste0("--backend=", opts$backend),
    "--bootstrap-nsim=0",
    "--bootstrap-cores=1",
    "--bootstrap-backend=none",
    "--profile-parameters=",
    paste0("--condition-shard=", condition_shard),
    paste0("--condition-shards=", condition_shards),
    paste0("--condition-set=", condition_set),
    "--overwrite=true",
    "--render=false"
  )
  status <- system2(
    rscript,
    shQuote(cmd_args),
    stdout = log_path,
    stderr = log_path
  )
  if (!identical(status, 0L)) {
    stop("Action task failed: ", task, " (see ", log_path, ")", call. = FALSE)
  }
  output_dir
}

balanced_tree <- function(n_tip = 4L, prefix = "sp") {
  stopifnot(n_tip >= 2L, log2(n_tip) == floor(log2(n_tip)))
  edges <- matrix(integer(), ncol = 2L)
  edge_lengths <- numeric()
  next_node <- n_tip + 1L

  build <- function(tips) {
    if (length(tips) == 1L) {
      return(tips)
    }
    node <- next_node
    next_node <<- next_node + 1L
    mid <- length(tips) / 2L
    left <- build(tips[seq_len(mid)])
    right <- build(tips[seq.int(mid + 1L, length(tips))])
    edges <<- rbind(edges, c(node, left), c(node, right))
    edge_lengths <<- c(edge_lengths, 1, 1)
    node
  }

  build(seq_len(n_tip))
  structure(
    list(
      edge = edges,
      edge.length = edge_lengths,
      tip.label = paste0(prefix, "_", seq_len(n_tip)),
      Nnode = n_tip - 1L
    ),
    class = "phylo"
  )
}

new_phylo_interaction_data <- function(
  seed,
  n_plant = 4L,
  n_pollinator = 4L,
  n_each = 8L,
  sd_pair = 0.45,
  sigma_nb2 = 0.35
) {
  set.seed(seed)
  plant_tree <- balanced_tree(n_plant, "plant")
  pollinator_tree <- balanced_tree(n_pollinator, "poll")
  plant_cov <- drmTMB:::drm_phylo_tip_covariance(plant_tree)
  pollinator_cov <- drmTMB:::drm_phylo_tip_covariance(pollinator_tree)
  pair_cov <- kronecker(pollinator_cov, plant_cov)
  pair_grid <- expand.grid(
    plant = plant_tree$tip.label,
    pollinator = pollinator_tree$tip.label,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  pair_effect <- as.vector(
    t(chol(pair_cov)) %*% stats::rnorm(nrow(pair_grid), sd = sd_pair)
  )
  pair_name <- paste0(pair_grid$plant, ":", pair_grid$pollinator)
  names(pair_effect) <- pair_name

  row_id <- rep(seq_len(nrow(pair_grid)), each = n_each)
  dat <- pair_grid[row_id, , drop = FALSE]
  x <- stats::rnorm(nrow(dat))
  beta_mu <- c("(Intercept)" = 0.45, x = -0.20)
  eta <- beta_mu[[1L]] +
    beta_mu[[2L]] * x +
    pair_effect[paste0(dat$plant, ":", dat$pollinator)]
  dat$x <- x
  dat$count <- stats::rpois(nrow(dat), lambda = exp(eta))
  dat$nb2 <- stats::rnbinom(
    nrow(dat),
    size = 1 / sigma_nb2^2,
    mu = exp(eta)
  )

  list(
    data = dat,
    plant_tree = plant_tree,
    pollinator_tree = pollinator_tree,
    beta_mu = beta_mu,
    sd_pair = sd_pair,
    sigma_nb2 = sigma_nb2,
    n_plant = n_plant,
    n_pollinator = n_pollinator,
    n_each = n_each
  )
}

fit_phylo_interaction_one <- function(family_name, seed, replicate) {
  sim <- new_phylo_interaction_data(seed)
  plant_tree <- sim$plant_tree
  pollinator_tree <- sim$pollinator_tree
  warnings <- character()
  elapsed <- NA_real_
  fit <- withCallingHandlers(
    {
      timing <- system.time({
        fit <- if (identical(family_name, "poisson")) {
          drmTMB(
            bf(
              count ~ x +
                phylo_interaction(
                  1 | plant:pollinator,
                  tree1 = plant_tree,
                  tree2 = pollinator_tree
                )
            ),
            family = stats::poisson(link = "log"),
            data = sim$data
          )
        } else {
          drmTMB(
            bf(
              nb2 ~ x +
                phylo_interaction(
                  1 | plant:pollinator,
                  tree1 = plant_tree,
                  tree2 = pollinator_tree
                ),
              sigma ~ 1
            ),
            family = nbinom2(),
            data = sim$data
          )
        }
      })
      elapsed <<- unname(timing[["elapsed"]])
      fit
    },
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  label <- "phylo_interaction(1 | plant:pollinator)"
  parm <- paste0("sd:mu:", label)
  targets <- tryCatch(profile_targets(fit), error = function(e) data.frame())
  target_row <- targets[targets$parm == parm, , drop = FALSE]
  checks <- tryCatch(check_drm(fit), error = function(e) data.frame())
  boundary_row <- checks[
    checks$check == "random_effect_sd_boundary",
    ,
    drop = FALSE
  ]
  coefficients <- tryCatch(summary(fit)$coefficients, error = function(e) NULL)
  se <- NA_real_
  if (
    is.data.frame(coefficients) &&
      "std_error" %in% names(coefficients) &&
      parm %in% row.names(coefficients)
  ) {
    se <- coefficients[parm, "std_error"]
  }

  cell_id <- if (identical(family_name, "poisson")) {
    "qseries_phylo_interaction_poisson_q1_mu"
  } else {
    "qseries_phylo_interaction_nbinom2_q1_mu"
  }
  family_label <- if (identical(family_name, "poisson")) {
    "poisson()"
  } else {
    "nbinom2()"
  }
  estimate <- unname(fit$sdpars$mu[[label]])

  list(
    manifest = data.frame(
      lane = "phylo_interaction",
      family = family_label,
      cell_id = cell_id,
      replicate = replicate,
      seed = seed,
      status = "ok",
      skipped = FALSE,
      warning_count = length(warnings),
      error = NA_character_,
      elapsed = elapsed,
      stringsAsFactors = FALSE
    ),
    replicate = data.frame(
      lane = "phylo_interaction",
      family = family_label,
      family_label = family_label,
      provider = "phylo_interaction",
      cell_id = cell_id,
      internal_cell_id = cell_id,
      replicate = replicate,
      seed = seed,
      parameter = parm,
      parameter_class = "phylo_interaction_sd",
      truth = sim$sd_pair,
      estimate = estimate,
      std.error = se,
      error = estimate - sim$sd_pair,
      converged = isTRUE(fit$opt$convergence == 0),
      pdHess = isTRUE(fit$sdr$pdHess),
      nobs = stats::nobs(fit),
      n_plant = sim$n_plant,
      n_pollinator = sim$n_pollinator,
      n_each = sim$n_each,
      profile_target_status = if (nrow(target_row)) {
        ifelse(target_row$profile_ready[[1L]], "ready", "not_ready")
      } else {
        "unavailable"
      },
      profile_target_parameter = if (nrow(target_row)) {
        target_row$tmb_parameter[[1L]]
      } else {
        NA_character_
      },
      diagnostic_status = if (nrow(boundary_row)) {
        boundary_row$status[[1L]]
      } else {
        "unavailable"
      },
      diagnostic_message = if (nrow(boundary_row)) {
        boundary_row$message[[1L]]
      } else {
        NA_character_
      },
      warning_count = length(warnings),
      warnings = paste(warnings, collapse = " | "),
      elapsed = elapsed,
      artifact_grain = "family_replicate_seed",
      stringsAsFactors = FALSE
    )
  )
}

fit_phylo_interaction_safe <- function(family_name, seed, replicate) {
  tryCatch(
    fit_phylo_interaction_one(family_name, seed, replicate),
    error = function(e) {
      cell_id <- if (identical(family_name, "poisson")) {
        "qseries_phylo_interaction_poisson_q1_mu"
      } else {
        "qseries_phylo_interaction_nbinom2_q1_mu"
      }
      family_label <- if (identical(family_name, "poisson")) {
        "poisson()"
      } else {
        "nbinom2()"
      }
      list(
        manifest = data.frame(
          lane = "phylo_interaction",
          family = family_label,
          cell_id = cell_id,
          replicate = replicate,
          seed = seed,
          status = "error",
          skipped = FALSE,
          warning_count = 0L,
          error = conditionMessage(e),
          elapsed = NA_real_,
          stringsAsFactors = FALSE
        ),
        replicate = data.frame(),
        failure = data.frame(
          lane = "phylo_interaction",
          family = family_label,
          cell_id = cell_id,
          replicate = replicate,
          seed = seed,
          status = "error",
          severity = "fit_error",
          message = conditionMessage(e),
          skipped = FALSE,
          stringsAsFactors = FALSE
        )
      )
    }
  )
}

bind_rows <- function(pieces) {
  pieces <- Filter(function(x) is.data.frame(x) && nrow(x) > 0L, pieces)
  if (!length(pieces)) {
    return(data.frame())
  }
  all_names <- unique(unlist(lapply(pieces, names), use.names = FALSE))
  pieces <- lapply(pieces, function(x) {
    missing <- setdiff(all_names, names(x))
    for (name in missing) {
      x[[name]] <- NA
    }
    x[all_names]
  })
  do.call(rbind, pieces)
}

read_csv <- function(path) {
  if (!file.exists(path)) {
    return(data.frame())
  }
  utils::read.csv(path, stringsAsFactors = FALSE)
}

add_lane <- function(rows, lane) {
  if (!nrow(rows)) {
    rows$lane <- character(0)
    return(rows)
  }
  rows$lane <- lane
  rows
}

has_lane <- function(lane) {
  lane %in% opts$lanes
}

has_family <- function(family_name) {
  family_name %in% opts$families
}

filter_selected_families <- function(rows) {
  if (!nrow(rows) || !"family_label" %in% names(rows)) {
    return(rows)
  }
  family_name <- sub("[(][)]$", "", rows$family_label)
  rows[family_name %in% opts$families, , drop = FALSE]
}

decorate_ordinary_replicates <- function(rows) {
  if (!nrow(rows)) {
    return(rows)
  }
  rows <- rows[rows$parameter_class == "structured_sd", , drop = FALSE]
  rows$lane <- "ordinary_structured"
  rows$provider <- rows$structured_type
  rows$family_label <- ifelse(
    rows$family == "poisson",
    "poisson()",
    "nbinom2()"
  )
  rows$qseries_cell_id <- paste0(
    "qseries_",
    rows$structured_type,
    "_",
    rows$family,
    "_q1_mu_intercept"
  )
  rows$internal_cell_id <- rows$cell_id
  rows$cell_id <- rows$qseries_cell_id
  rows
}

decorate_phylo_replicates <- function(rows, family_label, qseries_cell_id) {
  if (!nrow(rows)) {
    return(rows)
  }
  rows <- rows[startsWith(rows$parameter, "sd:mu:"), , drop = FALSE]
  rows$lane <- "phylo_formal"
  rows$provider <- "phylo"
  rows$family_label <- family_label
  rows$qseries_cell_id <- qseries_cell_id
  rows$internal_cell_id <- rows$cell_id
  rows$cell_id <- qseries_cell_id
  rows
}

mcse_mean <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) < 2L) {
    return(NA_real_)
  }
  stats::sd(x) / sqrt(length(x))
}

rmse_mcse <- function(error) {
  error <- error[is.finite(error)]
  if (length(error) < 2L) {
    return(NA_real_)
  }
  rmse <- sqrt(mean(error^2))
  if (!is.finite(rmse) || rmse == 0) {
    return(NA_real_)
  }
  stats::sd(error^2) / sqrt(length(error)) / (2 * rmse)
}

near_zero_sd_threshold <- 1e-4

diagnostic_status_ok <- function(status) {
  status <- as.character(status)
  vapply(
    status,
    function(x) {
      if (is.na(x) || !nzchar(x)) {
        return(FALSE)
      }
      parts <- trimws(strsplit(x, "[|]")[[1L]])
      length(parts) > 0L && all(parts == "ok")
    },
    logical(1)
  )
}

recovery_verdict <- function(
  n_rows,
  fit_ok,
  pdhess_false,
  finite_estimate,
  near_zero_estimate,
  boundary_warning
) {
  if (n_rows == 0L) {
    return("no_replicates")
  }
  fit_rate <- fit_ok / n_rows
  pdhess_false_rate <- pdhess_false / n_rows
  finite_rate <- finite_estimate / n_rows
  near_zero_rate <- near_zero_estimate / n_rows
  boundary_rate <- boundary_warning / n_rows
  if (fit_rate < 0.98 || finite_rate < 0.98) {
    return("recovery_blocked_fit_or_finite_rate")
  }
  if (pdhess_false_rate > 0.02) {
    return("recovery_caveat_pdhess_rate")
  }
  if (near_zero_rate >= 0.25) {
    return("recovery_caveat_near_zero_rate")
  }
  if (boundary_rate > 0.05) {
    return("recovery_caveat_boundary_rate")
  }
  "recovery_only_passed"
}

widget_state_for_verdict <- function(verdict) {
  if (identical(verdict, "recovery_only_passed")) {
    return("non_gaussian_recovery_only")
  }
  if (startsWith(verdict, "recovery_caveat")) {
    return("non_gaussian_recovery_caveat")
  }
  "non_gaussian_recovery_blocked"
}

summarise_recovery <- function(rows) {
  if (!nrow(rows)) {
    return(data.frame())
  }
  pieces <- lapply(split(rows, rows$cell_id), function(x) {
    n_rows <- nrow(x)
    fit_ok <- sum(x$converged %in% TRUE, na.rm = TRUE)
    pdhess_false <- sum(!(x$pdHess %in% TRUE), na.rm = TRUE)
    finite_estimate <- sum(is.finite(x$estimate), na.rm = TRUE)
    near_zero_estimate <- sum(
      is.finite(x$estimate) & x$estimate < near_zero_sd_threshold,
      na.rm = TRUE
    )
    boundary_warning <- if ("diagnostic_status" %in% names(x)) {
      sum(!diagnostic_status_ok(x$diagnostic_status))
    } else {
      NA_integer_
    }
    verdict <- recovery_verdict(
      n_rows = n_rows,
      fit_ok = fit_ok,
      pdhess_false = pdhess_false,
      finite_estimate = finite_estimate,
      near_zero_estimate = near_zero_estimate,
      boundary_warning = boundary_warning
    )
    provider <- x$provider[[1L]]
    family <- x$family_label[[1L]]
    data.frame(
      recovery_id = paste0("count_intercept_recovery_", x$cell_id[[1L]]),
      cell_id = x$cell_id[[1L]],
      family = family,
      structured_type = provider,
      n_rep = n_rows,
      n_seed_replicates = length(unique(x$replicate)),
      n_internal_conditions = length(unique(x$internal_cell_id)),
      fit_ok = fit_ok,
      nonconverged = n_rows - fit_ok,
      pdhess_false = pdhess_false,
      finite_estimate_rows = finite_estimate,
      near_zero_threshold = near_zero_sd_threshold,
      near_zero_estimate_rows = near_zero_estimate,
      near_zero_estimate_rate = near_zero_estimate / n_rows,
      boundary_warning_rows = boundary_warning,
      true_sd = mean(x$truth, na.rm = TRUE),
      mean_sd = mean(x$estimate, na.rm = TRUE),
      bias_sd = mean(x$error, na.rm = TRUE),
      rmse_sd = sqrt(mean(x$error^2, na.rm = TRUE)),
      bias_mcse = mcse_mean(x$error),
      rmse_mcse = rmse_mcse(x$error),
      recovery_verdict = verdict,
      widget_state = widget_state_for_verdict(verdict),
      linked_cell_id = x$cell_id[[1L]],
      linked_coverage_status = "planned",
      evidence_url = artifact_url,
      claim_boundary = paste(
        "Non-Gaussian count-intercept recovery measured locally with",
        n_rows,
        "structured-SD rows for",
        family,
        provider,
        "q1 mu. The sidecar reports fit, pdHess, finite-estimate,",
        "near-zero-estimate, bias, RMSE, and MCSE diagnostics. This",
        "is RECOVERY evidence only and is not interval-ready or",
        "coverage-ready: it does NOT promote",
        "interval_status, coverage_status, inference_ready, supported,",
        "REML, AI-REML, bridge support, q2/q4 count covariance, high-q,",
        "or public support."
      ),
      next_gate = paste(
        "If the row is clean, rerun or top up on the primary cluster before",
        "any public recovery wording; if caveated, diagnose the Hessian or",
        "near-zero lower-tail mechanism first. Intervals and coverage remain",
        "unsupported."
      ),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, pieces)
}

if (
  file.exists("DESCRIPTION") && requireNamespace("devtools", quietly = TRUE)
) {
  devtools::load_all(quiet = TRUE)
} else {
  library(drmTMB)
}

writeLines(
  c(
    "structured RE count-intercept recovery grid",
    paste("output_dir:", artifact_dir),
    paste("n_rep:", opts$n_rep),
    paste("seed_start:", opts$seed_start),
    paste("cores:", opts$cores),
    paste("backend:", opts$backend),
    paste("lanes:", paste(opts$lanes, collapse = ",")),
    paste("families:", paste(opts$families, collapse = ","))
  ),
  file.path(artifact_dir, "run-log.txt")
)

ordinary_dir <- NULL
phylo_poisson_dir <- NULL
phylo_nbinom2_dir <- NULL
if (has_lane("ordinary_structured")) {
  ordinary_dir <- run_action_task(
    "count_structured_q1",
    "ordinary",
    master_seed = opts$seed_start,
    condition_set = "all"
  )
}
if (has_lane("phylo_formal") && has_family("poisson")) {
  phylo_poisson_dir <- run_action_task(
    "poisson_phylo_q1_formal",
    "phylo-poisson",
    master_seed = opts$seed_start + 100000L,
    condition_shard = 7L,
    condition_shards = 54L
  )
}
if (has_lane("phylo_formal") && has_family("nbinom2")) {
  phylo_nbinom2_dir <- run_action_task(
    "nbinom2_phylo_q1_formal",
    "phylo-nbinom2",
    master_seed = opts$seed_start + 200000L,
    condition_shard = 7L,
    condition_shards = 72L
  )
}

phylo_seeds <- seq.int(opts$seed_start + 300000L, length.out = opts$n_rep)
phylo_interaction_results <- list()
if (has_lane("phylo_interaction")) {
  for (family_name in opts$families) {
    for (replicate in seq_along(phylo_seeds)) {
      key <- paste(family_name, replicate, sep = "_")
      phylo_interaction_results[[key]] <- fit_phylo_interaction_safe(
        family_name,
        phylo_seeds[[replicate]],
        replicate
      )
    }
  }
}
phylo_interaction_manifest <- bind_rows(
  lapply(phylo_interaction_results, `[[`, "manifest")
)
phylo_interaction_replicates <- bind_rows(
  lapply(phylo_interaction_results, `[[`, "replicate")
)
phylo_interaction_failures <- bind_rows(
  lapply(phylo_interaction_results, `[[`, "failure")
)

ordinary_replicates <- if (is.null(ordinary_dir)) {
  data.frame()
} else {
  filter_selected_families(decorate_ordinary_replicates(read_csv(file.path(
    ordinary_dir,
    "tables",
    "count-structured-q1-replicates.csv"
  ))))
}
phylo_poisson_replicates <- if (is.null(phylo_poisson_dir)) {
  data.frame()
} else {
  decorate_phylo_replicates(
    read_csv(file.path(
      phylo_poisson_dir,
      "tables",
      "poisson-phylo-q1-replicates.csv"
    )),
    "poisson()",
    "qseries_phylo_poisson_q1_mu_intercept"
  )
}
phylo_nbinom2_replicates <- if (is.null(phylo_nbinom2_dir)) {
  data.frame()
} else {
  decorate_phylo_replicates(
    read_csv(file.path(
      phylo_nbinom2_dir,
      "tables",
      "nbinom2-phylo-q1-replicates.csv"
    )),
    "nbinom2()",
    "qseries_phylo_nbinom2_q1_mu_intercept"
  )
}

all_replicates <- bind_rows(list(
  ordinary_replicates,
  phylo_poisson_replicates,
  phylo_nbinom2_replicates,
  phylo_interaction_replicates
))
summary <- summarise_recovery(all_replicates)
summary <- summary[
  order(summary$structured_type, summary$family),
  ,
  drop = FALSE
]

manifest <- bind_rows(list(
  if (is.null(ordinary_dir)) data.frame() else add_lane(
    read_csv(file.path(
      ordinary_dir,
      "tables",
      "count-structured-q1-manifest.csv"
    )),
    "ordinary_structured"
  ),
  if (is.null(phylo_poisson_dir)) data.frame() else add_lane(
    read_csv(file.path(
      phylo_poisson_dir,
      "tables",
      "poisson-phylo-q1-manifest.csv"
    )),
    "phylo_formal"
  ),
  if (is.null(phylo_nbinom2_dir)) data.frame() else add_lane(
    read_csv(file.path(
      phylo_nbinom2_dir,
      "tables",
      "nbinom2-phylo-q1-manifest.csv"
    )),
    "phylo_formal"
  ),
  phylo_interaction_manifest
))
failures <- bind_rows(list(
  if (is.null(ordinary_dir)) data.frame() else add_lane(
    read_csv(file.path(
      ordinary_dir,
      "tables",
      "count-structured-q1-failures.csv"
    )),
    "ordinary_structured"
  ),
  if (is.null(phylo_poisson_dir)) data.frame() else add_lane(
    read_csv(file.path(
      phylo_poisson_dir,
      "tables",
      "poisson-phylo-q1-failures.csv"
    )),
    "phylo_formal"
  ),
  if (is.null(phylo_nbinom2_dir)) data.frame() else add_lane(
    read_csv(file.path(
      phylo_nbinom2_dir,
      "tables",
      "nbinom2-phylo-q1-failures.csv"
    )),
    "phylo_formal"
  ),
  phylo_interaction_failures
))

table_dir <- file.path(artifact_dir, "tables")
utils::write.csv(
  all_replicates,
  file.path(table_dir, "count-intercept-recovery-replicates.csv"),
  row.names = FALSE
)
utils::write.csv(
  summary,
  file.path(table_dir, "count-intercept-recovery-summary.csv"),
  row.names = FALSE
)
utils::write.csv(
  manifest,
  file.path(table_dir, "count-intercept-recovery-manifest.csv"),
  row.names = FALSE
)
utils::write.csv(
  failures,
  file.path(table_dir, "count-intercept-recovery-failures.csv"),
  row.names = FALSE
)
utils::write.table(
  summary,
  file.path(table_dir, "count-intercept-recovery-summary.tsv"),
  sep = "\t",
  row.names = FALSE,
  quote = FALSE
)

seed_manifest <- data.frame(
  lane = character(),
  seed_start = integer(),
  n_rep = integer(),
  stringsAsFactors = FALSE
)
if (has_lane("ordinary_structured")) {
  seed_manifest <- rbind(
    seed_manifest,
    data.frame(
      lane = "ordinary_structured",
      seed_start = opts$seed_start,
      n_rep = opts$n_rep
    )
  )
}
if (has_lane("phylo_formal") && has_family("poisson")) {
  seed_manifest <- rbind(
    seed_manifest,
    data.frame(
      lane = "phylo_poisson",
      seed_start = opts$seed_start + 100000L,
      n_rep = opts$n_rep
    )
  )
}
if (has_lane("phylo_formal") && has_family("nbinom2")) {
  seed_manifest <- rbind(
    seed_manifest,
    data.frame(
      lane = "phylo_nbinom2",
      seed_start = opts$seed_start + 200000L,
      n_rep = opts$n_rep
    )
  )
}
if (has_lane("phylo_interaction")) {
  seed_manifest <- rbind(
    seed_manifest,
    data.frame(
      lane = paste0("phylo_interaction_", opts$families),
      seed_start = opts$seed_start + 300000L,
      n_rep = opts$n_rep
    )
  )
}
utils::write.csv(
  seed_manifest,
  file.path(table_dir, "count-intercept-recovery-seed-manifest.csv"),
  row.names = FALSE
)
writeLines(
  capture.output(sessionInfo()),
  file.path(artifact_dir, "sessionInfo.txt")
)
git_sha <- tryCatch(
  system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE),
  error = function(e) "git-sha-unavailable"
)
writeLines(git_sha, file.path(artifact_dir, "git-sha.txt"))
module_list <- tryCatch(
  system2("module", "list", stdout = TRUE, stderr = TRUE),
  error = function(e) "module-list-unavailable-local-run"
)
writeLines(module_list, file.path(artifact_dir, "module-list.txt"))

print(summary)
