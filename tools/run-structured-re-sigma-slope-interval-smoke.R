#!/usr/bin/env Rscript

devtools::load_all(quiet = TRUE)

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

script_file <- sub(
  "^--file=",
  "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1L] %||% "tools"
)
repo_root <- normalizePath(file.path(dirname(script_file), ".."))
if (!file.exists(file.path(repo_root, "DESCRIPTION"))) {
  repo_root <- normalizePath(getwd())
}

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-24-sigma-slope-interval-smoke"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

plan_path <- file.path(
  dashboard_dir,
  "structured-re-sigma-slope-interval-diagnostic-plan.tsv"
)
artifact_path <- file.path(
  artifact_dir,
  "structured-re-sigma-slope-interval-smoke-results.tsv"
)
status_path <- file.path(
  dashboard_dir,
  "structured-re-sigma-slope-interval-diagnostic-status.tsv"
)

balanced_tree <- function(n_tip = 8L) {
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
      tip.label = paste0("sp_", seq_len(n_tip)),
      Nnode = n_tip - 1L
    ),
    class = "phylo"
  )
}

scaled_effects <- function(K, sds) {
  z <- replicate(length(sds), as.vector(t(chol(K)) %*% stats::rnorm(nrow(K))))
  out <- sweep(z, 2L, sds, `*`)
  colnames(out) <- names(sds)
  out
}

make_provider_data <- function(provider, seed, n = 8L, n_each = 16L) {
  set.seed(seed)

  if (identical(provider, "phylo")) {
    tree <- balanced_tree(n)
    labels <- tree$tip.label
    K <- drmTMB:::drm_phylo_tip_covariance(tree)
    group <- "species"
    extra <- list(tree = tree)
  } else if (identical(provider, "spatial")) {
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
    group <- "site"
    extra <- list(coords = coords)
  } else if (identical(provider, "animal")) {
    pedigree <- data.frame(
      id = paste0("id", seq_len(8L)),
      dam = c(NA, NA, NA, NA, "id1", "id3", "id5", "id1"),
      sire = c(NA, NA, NA, NA, "id2", "id4", "id6", "id3"),
      stringsAsFactors = FALSE
    )
    K <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
    labels <- rownames(K)
    group <- "id"
    extra <- list(A = K)
  } else if (identical(provider, "relmat")) {
    labels <- paste0("id", seq_len(n))
    K <- outer(seq_len(n), seq_len(n), function(i, j) 0.35^abs(i - j))
    diag(K) <- diag(K) + 0.15
    dimnames(K) <- list(labels, labels)
    group <- "id"
    extra <- list(K = K)
  } else {
    stop("Unknown provider: ", provider, call. = FALSE)
  }

  effects <- scaled_effects(
    K,
    c(sigma_intercept = 0.50, sigma_x = 0.38)
  )
  rownames(effects) <- labels
  endpoint <- rep(labels, each = n_each)
  x <- rep(seq(-1.2, 1.2, length.out = n_each), times = length(labels))
  eta_mu <- 0.35 + 0.25 * x
  eta_sigma <- -0.90 +
    effects[endpoint, "sigma_intercept"] +
    effects[endpoint, "sigma_x"] * x
  data <- data.frame(
    y = eta_mu + exp(eta_sigma) * stats::rnorm(length(x)),
    x = x
  )
  data[[group]] <- endpoint

  c(list(data = data, group = group), extra)
}

fit_provider <- function(provider) {
  sim <- make_provider_data(
    provider,
    seed = c(phylo = 231L, spatial = 232L, animal = 233L, relmat = 234L)[[
      provider
    ]]
  )

  if (identical(provider, "phylo")) {
    tree <- sim$tree
    form <- bf(
      y ~ x,
      sigma ~ phylo(1 + x | species, tree = tree)
    )
  } else if (identical(provider, "spatial")) {
    coords <- sim$coords
    form <- bf(
      y ~ x,
      sigma ~ spatial(1 + x | site, coords = coords)
    )
  } else if (identical(provider, "animal")) {
    A <- sim$A
    form <- bf(
      y ~ x,
      sigma ~ animal(1 + x | id, A = A)
    )
  } else if (identical(provider, "relmat")) {
    K <- sim$K
    form <- bf(
      y ~ x,
      sigma ~ relmat(1 + x | id, K = K)
    )
  }

  drmTMB(
    form,
    family = gaussian(),
    data = sim$data,
    control = drm_control(optimizer = list(eval.max = 1200, iter.max = 1200))
  )
}

endpoint_profile_target <- function(provider, endpoint_member) {
  group <- switch(
    provider,
    phylo = "species",
    spatial = "site",
    animal = "id",
    relmat = "id"
  )
  coefficient <- if (grepl("Intercept", endpoint_member, fixed = TRUE)) {
    "1"
  } else {
    "0 + x"
  }
  paste0("sd:sigma:", provider, "(", coefficient, " | ", group, ")")
}

direct_sd_target <- function(endpoint_member) {
  switch(
    endpoint_member,
    "sigma:(Intercept)" = "sd_sigma_intercept",
    "sigma:x" = "sd_sigma_x"
  )
}

endpoint_token <- function(endpoint_member) {
  out <- gsub(":", "_", endpoint_member, fixed = TRUE)
  out <- gsub("(", "", out, fixed = TRUE)
  out <- gsub(")", "", out, fixed = TRUE)
  gsub("_Intercept", "_intercept", out, fixed = TRUE)
}

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

run_interval <- function(fit, parm, method) {
  warnings <- character()
  result <- withCallingHandlers(
    tryCatch(
      {
        args <- list(object = fit, parm = parm, method = method, level = 0.70)
        if (identical(method, "profile")) {
          args <- c(
            args,
            list(
              profile_engine = "endpoint",
              trace = FALSE,
              profile_endpoint_max_eval = 70L
            )
          )
        }
        if (identical(method, "bootstrap")) {
          args <- c(args, list(R = 2L, seed = 23L))
        }
        do.call(stats::confint, args)
      },
      error = function(e) e
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  if (inherits(result, "error")) {
    return(data.frame(
      interval_method = method,
      method_status = "error",
      interval_finite = FALSE,
      lower = NA_real_,
      upper = NA_real_,
      conf_status = NA_character_,
      method_message = clean_text(conditionMessage(result)),
      method_warnings = clean_text(paste(warnings, collapse = " | ")),
      stringsAsFactors = FALSE
    ))
  }

  interval_finite <- is.finite(result$lower[[1L]]) &&
    is.finite(result$upper[[1L]])
  data.frame(
    interval_method = method,
    method_status = if (interval_finite) "finite" else "nonfinite",
    interval_finite = interval_finite,
    lower = result$lower[[1L]],
    upper = result$upper[[1L]],
    conf_status = if ("conf.status" %in% names(result)) {
      result$conf.status[[1L]]
    } else {
      NA_character_
    },
    method_message = clean_text(
      if ("profile.message" %in% names(result)) {
        as.character(result$profile.message[[1L]])
      } else {
        NA_character_
      }
    ),
    method_warnings = clean_text(paste(warnings, collapse = " | ")),
    stringsAsFactors = FALSE
  )
}

classify_interval_status <- function(rows) {
  finite_methods <- rows$interval_method[rows$interval_finite]
  if (identical(sort(finite_methods), c("bootstrap", "profile", "wald"))) {
    return("wald_profile_bootstrap_finite")
  }
  if (identical(sort(finite_methods), c("bootstrap", "wald"))) {
    return("wald_bootstrap_finite_profile_failed")
  }
  if (identical(finite_methods, "bootstrap")) {
    return("bootstrap_only_finite_boundary")
  }
  if (length(finite_methods)) {
    return("partial_finite")
  }
  "no_finite_intervals"
}

classify_failure <- function(rows) {
  failures <- character()
  wald <- rows[rows$interval_method == "wald", , drop = FALSE]
  profile <- rows[rows$interval_method == "profile", , drop = FALSE]
  bootstrap <- rows[rows$interval_method == "bootstrap", , drop = FALSE]
  if (!isTRUE(wald$interval_finite[[1L]])) {
    failures <- c(failures, "wald_boundary_or_nonfinite")
  }
  if (!isTRUE(profile$interval_finite[[1L]])) {
    failures <- c(failures, "profile_failed_or_nonfinite")
  }
  if (!isTRUE(bootstrap$interval_finite[[1L]])) {
    failures <- c(failures, "bootstrap_failed_or_nonfinite")
  }
  if (!length(failures)) {
    return("none")
  }
  paste(failures, collapse = ";")
}

provider_clause <- function(provider) {
  switch(
    provider,
    phylo = "phylo",
    spatial = "fixed-covariance spatial",
    animal = "animal A-matrix",
    relmat = "relmat K-matrix"
  )
}

blocked_clause <- function(provider) {
  switch(
    provider,
    phylo = "",
    spatial = " no range-estimating spatial support,",
    animal = " no pedigree/Ainv bridge marshalling,",
    relmat = " no Q bridge marshalling,"
  )
}

claim_boundary <- function(provider, interval_status) {
  paste(
    provider_clause(provider),
    "sigma-only one-slope interval smoke only;",
    "status =",
    interval_status,
    "with",
    blocked_clause(provider),
    "no interval reliability, interval coverage, REML, AI-REML,",
    "matched mu+sigma support, or broad bridge support promoted."
  )
}

next_gate <- function(interval_status) {
  if (identical(interval_status, "wald_profile_bootstrap_finite")) {
    return(
      "Repeat with more deterministic fixtures and denominator accounting before calibrated coverage wording."
    )
  }
  "Diagnose boundary/profile failures before coverage-grid design or public interval wording."
}

providers <- c("phylo", "spatial", "animal", "relmat")
endpoint_members <- c("sigma:(Intercept)", "sigma:x")
methods <- c("wald", "profile", "bootstrap")
source_artifact <- file.path(
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-24-sigma-slope-interval-smoke",
  "structured-re-sigma-slope-interval-smoke-results.tsv"
)

plan_rows <- list()
for (provider in providers) {
  for (endpoint_member in endpoint_members) {
    diagnostic_id <- paste0(
      "sigma_slope_interval_",
      provider,
      "_",
      endpoint_token(endpoint_member)
    )
    plan_rows[[length(plan_rows) + 1L]] <- data.frame(
      diagnostic_id = diagnostic_id,
      cell_id = paste0("qseries_", provider, "_q1_sigma_one_slope"),
      formula_cell = switch(
        provider,
        phylo = "sigma ~ phylo(1 + x | species, tree = tree)",
        spatial = "sigma ~ spatial(1 + x | site, coords = coords)",
        animal = "sigma ~ animal(1 + x | id, A = A)",
        relmat = "sigma ~ relmat(1 + x | id, K = K)"
      ),
      structured_type = provider,
      target_kind = "direct_sd",
      endpoint_member = endpoint_member,
      direct_sd_target = direct_sd_target(endpoint_member),
      profile_target = endpoint_profile_target(provider, endpoint_member),
      interval_methods = "wald;profile;bootstrap",
      required_fit_evidence = "point_fit;extractor_ready;profile_targets_direct_ready;same_target_fixture_parity",
      required_interval_evidence = "finite_intervals_by_method;coverage_mcse<=0.01",
      denominator_fields = "coverage_denominator;n_total;n_fit_ok;n_failed_fit;n_pdhess;n_interval_finite;n_interval_unavailable;coverage_mcse",
      current_blocker = "interval_diagnostics_not_run",
      status = "planned",
      evidence_url = "docs/dev-log/after-task/2026-06-24-sigma-slope-interval-diagnostic-plan.md",
      claim_boundary = paste(
        provider_clause(provider),
        "sigma-only one-slope interval diagnostic plan only;",
        blocked_clause(provider),
        "no interval reliability, interval coverage, REML, AI-REML,",
        "matched mu+sigma support, or broad bridge support is promoted."
      ),
      next_gate = "Run deterministic sigma-only target-level Wald/profile/bootstrap smoke before calibrated coverage wording.",
      stringsAsFactors = FALSE
    )
  }
}

method_rows <- list()
status_rows <- list()

for (provider in providers) {
  fit <- fit_provider(provider)
  targets <- profile_targets(fit)

  for (endpoint_member in endpoint_members) {
    parm <- endpoint_profile_target(provider, endpoint_member)
    target <- targets[match(parm, targets$parm), , drop = FALSE]
    target_found <- nrow(target) == 1L && identical(target$parm[[1L]], parm)

    rows <- do.call(
      rbind,
      lapply(methods, function(method) {
        run_interval(fit, parm, method)
      })
    )
    rows$provider <- provider
    rows$endpoint_member <- endpoint_member
    rows$direct_sd_target <- direct_sd_target(endpoint_member)
    rows$profile_target <- parm
    rows$estimate <- if (target_found) target$estimate[[1L]] else NA_real_
    rows$profile_ready <- if (target_found) {
      target$profile_ready[[1L]]
    } else {
      FALSE
    }
    rows$profile_note <- if (target_found) {
      target$profile_note[[1L]]
    } else {
      NA_character_
    }
    rows$convergence <- fit$opt$convergence
    rows$pdHess <- isTRUE(fit$sdr$pdHess)
    rows$logLik <- as.numeric(stats::logLik(fit))
    method_rows[[length(method_rows) + 1L]] <- rows

    interval_status <- classify_interval_status(rows)
    diagnostic_id <- paste0(
      "sigma_slope_interval_status_",
      provider,
      "_",
      endpoint_token(endpoint_member)
    )
    status_rows[[length(status_rows) + 1L]] <- data.frame(
      diagnostic_id = diagnostic_id,
      cell_id = paste0("qseries_", provider, "_q1_sigma_one_slope"),
      formula_cell = switch(
        provider,
        phylo = "sigma ~ phylo(1 + x | species, tree = tree)",
        spatial = "sigma ~ spatial(1 + x | site, coords = coords)",
        animal = "sigma ~ animal(1 + x | id, A = A)",
        relmat = "sigma ~ relmat(1 + x | id, K = K)"
      ),
      structured_type = provider,
      target_kind = "direct_sd",
      endpoint_member = endpoint_member,
      direct_sd_target = direct_sd_target(endpoint_member),
      profile_target = parm,
      source_artifact = source_artifact,
      observed_target_rows = as.integer(target_found),
      n_fit_ok = as.integer(fit$opt$convergence == 0L),
      n_converged = as.integer(fit$opt$convergence == 0L),
      n_pdhess = as.integer(isTRUE(fit$sdr$pdHess)),
      n_finite_intervals = sum(rows$interval_finite),
      wald_status = rows$method_status[rows$interval_method == "wald"],
      profile_status = rows$method_status[rows$interval_method == "profile"],
      bootstrap_status = rows$method_status[
        rows$interval_method == "bootstrap"
      ],
      interval_status = interval_status,
      failure_class = classify_failure(rows),
      interval_claim_status = "diagnostic_only",
      status = "covered",
      evidence_url = "docs/dev-log/after-task/2026-06-24-sigma-slope-interval-smoke-status.md",
      claim_boundary = claim_boundary(provider, interval_status),
      next_gate = next_gate(interval_status),
      stringsAsFactors = FALSE
    )
  }
}

plan_out <- do.call(rbind, plan_rows)
method_out <- do.call(rbind, method_rows)
method_out <- method_out[
  c(
    "provider",
    "endpoint_member",
    "direct_sd_target",
    "profile_target",
    "interval_method",
    "method_status",
    "interval_finite",
    "lower",
    "upper",
    "conf_status",
    "method_message",
    "method_warnings",
    "estimate",
    "profile_ready",
    "profile_note",
    "convergence",
    "pdHess",
    "logLik"
  )
]
status_out <- do.call(rbind, status_rows)

for (object_name in c("plan_out", "method_out", "status_out")) {
  object <- get(object_name)
  character_cols <- vapply(object, is.character, logical(1L))
  object[character_cols] <- lapply(object[character_cols], clean_text)
  assign(object_name, object)
}

utils::write.table(
  plan_out,
  file = plan_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)
utils::write.table(
  method_out,
  file = artifact_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)
utils::write.table(
  status_out,
  file = status_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)

message("Wrote ", normalizePath(plan_path, winslash = "/"))
message("Wrote ", normalizePath(artifact_path, winslash = "/"))
message("Wrote ", normalizePath(status_path, winslash = "/"))
