output_dir <- commandArgs(trailingOnly = TRUE)
output_dir <- if (length(output_dir) >= 1L && nzchar(output_dir[[1L]])) {
  output_dir[[1L]]
} else {
  "docs/dev-log/simulation-artifacts/2026-06-28-phylo-interaction-count-recovery-smoke-local"
}

if (file.exists("DESCRIPTION") && requireNamespace("devtools", quietly = TRUE)) {
  devtools::load_all(quiet = TRUE)
} else {
  library(drmTMB)
}

artifact_dir <- normalizePath(output_dir, mustWork = FALSE)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)
table_dir <- file.path(artifact_dir, "tables")
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)

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

new_data <- function(
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

fit_one <- function(family_name, seed, replicate) {
  sim <- new_data(seed)
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
  family_label <- if (identical(family_name, "poisson")) "poisson()" else "nbinom2()"

  list(
    manifest = data.frame(
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
      family = family_label,
      cell_id = cell_id,
      replicate = replicate,
      seed = seed,
      parameter = parm,
      parameter_class = "phylo_interaction_sd",
      truth = sim$sd_pair,
      estimate = unname(fit$sdpars$mu[[label]]),
      std.error = se,
      error = unname(fit$sdpars$mu[[label]]) - sim$sd_pair,
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

fit_safe <- function(family_name, seed, replicate) {
  tryCatch(
    fit_one(family_name, seed, replicate),
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

families <- c("poisson", "nbinom2")
seeds <- 2026062801:2026062804
results <- list()
for (family_name in families) {
  for (replicate in seq_along(seeds)) {
    key <- paste(family_name, replicate, sep = "_")
    results[[key]] <- fit_safe(family_name, seeds[[replicate]], replicate)
  }
}

manifest <- do.call(rbind, lapply(results, `[[`, "manifest"))
replicates <- do.call(
  rbind,
  Filter(
    function(x) is.data.frame(x) && nrow(x) > 0L,
    lapply(results, `[[`, "replicate")
  )
)
failures <- do.call(
  rbind,
  Filter(
    function(x) is.data.frame(x) && nrow(x) > 0L,
    lapply(results, `[[`, "failure")
  )
)
if (is.null(failures)) {
  failures <- data.frame(
    family = character(),
    cell_id = character(),
    replicate = integer(),
    seed = integer(),
    status = character(),
    severity = character(),
    message = character(),
    skipped = logical(),
    stringsAsFactors = FALSE
  )
}

aggregate <- do.call(
  rbind,
  lapply(split(replicates, replicates$family), function(rows) {
    data.frame(
      family = rows$family[[1L]],
      cell_id = rows$cell_id[[1L]],
      n_replicates = length(unique(rows$replicate)),
      n_sd_rows = nrow(rows),
      n_converged_sd_rows = sum(rows$converged),
      n_pdhess_sd_rows = sum(rows$pdHess),
      n_finite_sd_estimate_rows = sum(is.finite(rows$estimate)),
      n_boundary_warning_rows = sum(rows$diagnostic_status != "ok"),
      mean_estimate = mean(rows$estimate),
      bias = mean(rows$error),
      rmse = sqrt(mean(rows$error^2)),
      stringsAsFactors = FALSE
    )
  })
)

utils::write.csv(
  manifest,
  file.path(table_dir, "phylo-interaction-count-smoke-manifest.csv"),
  row.names = FALSE
)
utils::write.csv(
  replicates,
  file.path(table_dir, "phylo-interaction-count-smoke-replicates.csv"),
  row.names = FALSE
)
utils::write.csv(
  failures,
  file.path(table_dir, "phylo-interaction-count-smoke-failures.csv"),
  row.names = FALSE
)
utils::write.csv(
  aggregate,
  file.path(table_dir, "phylo-interaction-count-smoke-aggregate.csv"),
  row.names = FALSE
)

writeLines(capture.output(sessionInfo()), file.path(artifact_dir, "sessionInfo.txt"))
git_sha <- tryCatch(
  system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE),
  error = function(e) "git-sha-unavailable"
)
writeLines(git_sha, file.path(artifact_dir, "git-sha.txt"))
writeLines(
  c(
    "phylo_interaction count q1 local smoke",
    paste("output_dir:", artifact_dir),
    paste("families:", paste(families, collapse = ",")),
    paste("seeds:", paste(seeds, collapse = ",")),
    paste("rows:", nrow(replicates)),
    paste("failures:", nrow(failures))
  ),
  file.path(artifact_dir, "run-log.txt")
)

print(aggregate)
