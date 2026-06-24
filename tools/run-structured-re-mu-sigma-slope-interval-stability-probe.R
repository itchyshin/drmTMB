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

artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-24-mu-sigma-slope-interval-stability-probe"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

artifact_path <- file.path(
  artifact_dir,
  "structured-re-mu-sigma-slope-interval-stability-probe-results.tsv"
)
status_path <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "dashboard",
  "structured-re-mu-sigma-slope-interval-stability-probe.tsv"
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

make_provider_data <- function(provider, seed, n_each, sds) {
  set.seed(seed)
  n <- 8L

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

  effects <- correlated_effects(K, sds)
  rownames(effects) <- labels
  endpoint <- rep(labels, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), times = length(labels))
  eta_mu <- 0.35 +
    0.20 * x +
    effects[endpoint, "mu_intercept"] +
    effects[endpoint, "mu_x"] * x
  eta_sigma <- -1.05 +
    effects[endpoint, "sigma_intercept"] +
    effects[endpoint, "sigma_x"] * x
  data <- data.frame(
    y = eta_mu + exp(eta_sigma) * stats::rnorm(length(x)),
    x = x
  )
  data[[group]] <- endpoint

  c(list(data = data), extra)
}

fit_provider <- function(provider, sim) {
  if (identical(provider, "phylo")) {
    tree <- sim$tree
    form <- bf(
      y ~ x + phylo(1 + x | species, tree = tree),
      sigma ~ phylo(1 + x | species, tree = tree)
    )
  } else if (identical(provider, "spatial")) {
    coords <- sim$coords
    form <- bf(
      y ~ x + spatial(1 + x | site, coords = coords),
      sigma ~ spatial(1 + x | site, coords = coords)
    )
  } else if (identical(provider, "animal")) {
    A <- sim$A
    form <- bf(
      y ~ x + animal(1 + x | id, A = A),
      sigma ~ animal(1 + x | id, A = A)
    )
  } else if (identical(provider, "relmat")) {
    K <- sim$K
    form <- bf(
      y ~ x + relmat(1 + x | id, K = K),
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
  dpar <- if (startsWith(endpoint_member, "mu:")) "mu" else "sigma"
  coefficient <- if (grepl("Intercept", endpoint_member, fixed = TRUE)) {
    "1"
  } else {
    "0 + x"
  }
  paste0(
    "sd:",
    dpar,
    ":",
    dpar,
    ":",
    provider,
    "(",
    coefficient,
    " | ",
    group,
    ")"
  )
}

direct_sd_target <- function(endpoint_member) {
  switch(
    endpoint_member,
    "mu:(Intercept)" = "sd_mu_intercept",
    "mu:x" = "sd_mu_x",
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
              profile_endpoint_max_eval = 80L
            )
          )
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
      conf_status = "error",
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

classify_status <- function(rows) {
  if (all(rows$interval_finite)) {
    return("wald_profile_finite")
  }
  if (any(rows$interval_finite)) {
    return("partial_finite")
  }
  "wald_profile_nonfinite_boundary"
}

classify_failure <- function(rows) {
  failures <- character()
  wald <- rows[rows$interval_method == "wald", , drop = FALSE]
  profile <- rows[rows$interval_method == "profile", , drop = FALSE]
  if (!isTRUE(wald$interval_finite[[1L]])) {
    failures <- c(failures, "wald_boundary_or_nonfinite")
  }
  if (!isTRUE(profile$interval_finite[[1L]])) {
    failures <- c(failures, "profile_failed_or_nonfinite")
  }
  if (!length(failures)) {
    return("none")
  }
  paste(failures, collapse = ";")
}

claim_boundary <- function(provider, stability_status) {
  provider_clause <- switch(
    provider,
    phylo = "phylo",
    spatial = "fixed-covariance spatial",
    animal = "animal A-matrix",
    relmat = "relmat K-matrix"
  )
  blocked_clause <- switch(
    provider,
    phylo = "",
    spatial = " no range-estimating spatial support,",
    animal = " no pedigree/Ainv bridge marshalling,",
    relmat = " no Q bridge marshalling,"
  )
  clean_text(paste(
    "Matched",
    provider_clause,
    "mu+sigma one-slope stability probe only;",
    "status =",
    stability_status,
    "with",
    blocked_clause,
    "no interval reliability, interval coverage, REML, AI-REML,",
    "or broad bridge support promoted."
  ))
}

next_gate <- function(stability_status) {
  if (identical(stability_status, "wald_profile_finite")) {
    return(
      "Repeat with more seeds and bootstrap denominators before calibrated coverage wording."
    )
  }
  "Diagnose persistent spatial boundary/profile failures before coverage-grid design."
}

variants <- list(
  strong = c(
    mu_intercept = 0.60,
    mu_x = 0.45,
    sigma_intercept = 0.55,
    sigma_x = 0.40
  ),
  stronger_sigma = c(
    mu_intercept = 0.50,
    mu_x = 0.35,
    sigma_intercept = 0.80,
    sigma_x = 0.60
  )
)
variant_seeds <- c(phylo = 201L, spatial = 202L, animal = 203L, relmat = 204L)
providers <- c("phylo", "spatial", "animal", "relmat")
endpoint_members <- c("mu:(Intercept)", "mu:x", "sigma:(Intercept)", "sigma:x")
methods <- c("wald", "profile")
n_each <- 20L

method_rows <- list()
status_rows <- list()

for (variant in names(variants)) {
  sds <- variants[[variant]]
  for (provider in providers) {
    sim <- make_provider_data(
      provider,
      seed = variant_seeds[[provider]],
      n_each = n_each,
      sds = sds
    )
    fit <- fit_provider(provider, sim)
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
      rows$variant <- variant
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

      stability_status <- classify_status(rows)
      probe_id <- paste0(
        "mu_sigma_slope_interval_stability_",
        variant,
        "_",
        provider,
        "_",
        endpoint_token(endpoint_member)
      )
      status_rows[[length(status_rows) + 1L]] <- data.frame(
        probe_id = probe_id,
        cell_id = paste0("qseries_", provider, "_q1_mu_sigma_one_slope"),
        variant = variant,
        formula_cell = switch(
          provider,
          phylo = "phylo(1 + x | species, tree = tree) in mu and sigma",
          spatial = "spatial(1 + x | site, coords = coords) in mu and sigma",
          animal = "animal(1 + x | id, A = A) in mu and sigma",
          relmat = "relmat(1 + x | id, K = K) in mu and sigma"
        ),
        structured_type = provider,
        target_kind = "direct_sd",
        endpoint_member = endpoint_member,
        direct_sd_target = direct_sd_target(endpoint_member),
        profile_target = parm,
        source_artifact = file.path(
          "docs",
          "dev-log",
          "simulation-artifacts",
          "2026-06-24-mu-sigma-slope-interval-stability-probe",
          "structured-re-mu-sigma-slope-interval-stability-probe-results.tsv"
        ),
        n_each = n_each,
        intended_sd_mu_intercept = sds[["mu_intercept"]],
        intended_sd_mu_x = sds[["mu_x"]],
        intended_sd_sigma_intercept = sds[["sigma_intercept"]],
        intended_sd_sigma_x = sds[["sigma_x"]],
        observed_target_rows = as.integer(target_found),
        n_fit_ok = as.integer(fit$opt$convergence == 0L),
        n_pdhess = as.integer(isTRUE(fit$sdr$pdHess)),
        estimate = if (target_found) target$estimate[[1L]] else NA_real_,
        wald_status = rows$method_status[rows$interval_method == "wald"],
        profile_status = rows$method_status[rows$interval_method == "profile"],
        stability_status = stability_status,
        failure_class = classify_failure(rows),
        interval_claim_status = "diagnostic_only",
        status = "covered",
        evidence_url = "docs/dev-log/after-task/2026-06-24-mu-sigma-slope-interval-stability-probe.md",
        claim_boundary = claim_boundary(provider, stability_status),
        next_gate = next_gate(stability_status),
        stringsAsFactors = FALSE
      )
    }
  }
}

method_out <- do.call(rbind, method_rows)
method_out <- method_out[
  c(
    "variant",
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
character_method_cols <- vapply(method_out, is.character, logical(1L))
method_out[character_method_cols] <- lapply(
  method_out[character_method_cols],
  clean_text
)

status_out <- do.call(rbind, status_rows)
character_status_cols <- vapply(status_out, is.character, logical(1L))
status_out[character_status_cols] <- lapply(
  status_out[character_status_cols],
  clean_text
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

message("Wrote ", normalizePath(artifact_path, winslash = "/"))
message("Wrote ", normalizePath(status_path, winslash = "/"))
