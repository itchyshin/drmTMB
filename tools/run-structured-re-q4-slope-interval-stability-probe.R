#!/usr/bin/env Rscript

cli_args <- commandArgs(trailingOnly = TRUE)
if (any(cli_args %in% c("--help", "-h"))) {
  cat(
    paste(
      "Usage: Rscript tools/run-structured-re-q4-slope-interval-stability-probe.R",
      "",
      "Runs the fixed q4 all-four one-slope direct-SD interval stability probe",
      "for phylo, spatial, animal, and relmat, then writes:",
      "  docs/dev-log/simulation-artifacts/2026-06-24-q4-slope-interval-stability-probe/structured-re-q4-slope-interval-stability-probe-results.tsv",
      "  docs/dev-log/dashboard/structured-re-q4-slope-interval-stability-probe.tsv",
      "",
      "No command-line options are currently supported other than --help.",
      "This is diagnostic-only evidence; it does not promote q4/q8 interval",
      "coverage, REML, AI-REML, bridge support, supported, or public support.",
      sep = "\n"
    ),
    "\n"
  )
  quit(status = 0L)
}

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
plan_path <- file.path(
  dashboard_dir,
  "structured-re-q4-slope-interval-diagnostic-plan.tsv"
)
artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-24-q4-slope-interval-stability-probe"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

artifact_path <- file.path(
  artifact_dir,
  "structured-re-q4-slope-interval-stability-probe-results.tsv"
)
status_path <- file.path(
  dashboard_dir,
  "structured-re-q4-slope-interval-stability-probe.tsv"
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

make_endpoint_covariance <- function(sds) {
  cor_mat <- diag(length(sds))
  cor_mat[lower.tri(cor_mat)] <- 0.08
  cor_mat[upper.tri(cor_mat)] <- t(cor_mat)[upper.tri(cor_mat)]
  out <- diag(sds) %*% cor_mat %*% diag(sds)
  dimnames(out) <- list(names(sds), names(sds))
  out
}

correlated_effects <- function(K, sds) {
  endpoint_cov <- make_endpoint_covariance(sds)
  base <- t(chol(K)) %*%
    matrix(
      stats::rnorm(nrow(K) * ncol(endpoint_cov)),
      nrow(K),
      ncol(endpoint_cov)
    )
  out <- base %*% chol(endpoint_cov)
  colnames(out) <- colnames(endpoint_cov)
  out
}

make_provider_data <- function(provider, seed, n = 8L, n_each = 18L, sds) {
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
    labels <- paste0("id", seq_len(n))
    K <- outer(seq_len(n), seq_len(n), function(i, j) 0.32^abs(i - j))
    diag(K) <- diag(K) + 0.18
    dimnames(K) <- list(labels, labels)
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
  z <- rep(seq(-0.75, 0.75, length.out = n_each), times = length(labels))

  eta_mu1 <- 0.25 +
    0.22 * x +
    effects[endpoint, "mu1_intercept"] +
    effects[endpoint, "mu1_x"] * x
  eta_mu2 <- -0.10 -
    0.18 * x +
    effects[endpoint, "mu2_intercept"] +
    effects[endpoint, "mu2_x"] * x
  eta_sigma1 <- -1.10 +
    0.05 * z +
    effects[endpoint, "sigma1_intercept"] +
    effects[endpoint, "sigma1_x"] * x
  eta_sigma2 <- -1.05 -
    0.04 * z +
    effects[endpoint, "sigma2_intercept"] +
    effects[endpoint, "sigma2_x"] * x

  rho12 <- 0.12
  residual_std <- matrix(stats::rnorm(length(endpoint) * 2L), ncol = 2L) %*%
    chol(matrix(c(1, rho12, rho12, 1), nrow = 2L))
  data <- data.frame(
    y1 = eta_mu1 + exp(eta_sigma1) * residual_std[, 1L],
    y2 = eta_mu2 + exp(eta_sigma2) * residual_std[, 2L],
    x = x,
    z = z
  )
  data[[group]] <- endpoint

  c(list(data = data, group = group), extra)
}

fit_provider <- function(provider, sim) {
  if (identical(provider, "phylo")) {
    tree <- sim$tree
    form <- bf(
      mu1 = y1 ~ x + phylo(1 + x | p | species, tree = tree),
      mu2 = y2 ~ x + phylo(1 + x | p | species, tree = tree),
      sigma1 = ~ z + phylo(1 + x | p | species, tree = tree),
      sigma2 = ~ z + phylo(1 + x | p | species, tree = tree),
      rho12 = ~1
    )
  } else if (identical(provider, "spatial")) {
    coords <- sim$coords
    form <- bf(
      mu1 = y1 ~ x + spatial(1 + x | p | site, coords = coords),
      mu2 = y2 ~ x + spatial(1 + x | p | site, coords = coords),
      sigma1 = ~ z + spatial(1 + x | p | site, coords = coords),
      sigma2 = ~ z + spatial(1 + x | p | site, coords = coords),
      rho12 = ~1
    )
  } else if (identical(provider, "animal")) {
    A <- sim$A
    form <- bf(
      mu1 = y1 ~ x + animal(1 + x | p | id, A = A),
      mu2 = y2 ~ x + animal(1 + x | p | id, A = A),
      sigma1 = ~ z + animal(1 + x | p | id, A = A),
      sigma2 = ~ z + animal(1 + x | p | id, A = A),
      rho12 = ~1
    )
  } else if (identical(provider, "relmat")) {
    K <- sim$K
    form <- bf(
      mu1 = y1 ~ x + relmat(1 + x | p | id, K = K),
      mu2 = y2 ~ x + relmat(1 + x | p | id, K = K),
      sigma1 = ~ z + relmat(1 + x | p | id, K = K),
      sigma2 = ~ z + relmat(1 + x | p | id, K = K),
      rho12 = ~1
    )
  }

  drmTMB(
    form,
    family = biv_gaussian(),
    data = sim$data,
    control = drm_control(
      fallback_optimizer = "BFGS",
      optimizer = list(eval.max = 1600, iter.max = 1600)
    )
  )
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
              profile_endpoint_max_eval = 60L
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

fit_error_rows <- function(methods, message) {
  do.call(
    rbind,
    lapply(methods, function(method) {
      data.frame(
        interval_method = method,
        method_status = "fit_error",
        interval_finite = FALSE,
        lower = NA_real_,
        upper = NA_real_,
        conf_status = "fit_error",
        method_message = clean_text(message),
        method_warnings = "NA",
        stringsAsFactors = FALSE
      )
    })
  )
}

pdhess_blocked_rows <- function(methods) {
  do.call(
    rbind,
    lapply(methods, function(method) {
      data.frame(
        interval_method = method,
        method_status = "not_run_pdhess_false",
        interval_finite = FALSE,
        lower = NA_real_,
        upper = NA_real_,
        conf_status = "not_run_pdhess_false",
        method_message = "fit converged without a positive-definite Hessian",
        method_warnings = "NA",
        stringsAsFactors = FALSE
      )
    })
  )
}

classify_stability_status <- function(rows) {
  if (any(rows$method_status == "fit_error")) {
    return("fit_error")
  }
  if (any(rows$method_status == "not_run_pdhess_false")) {
    return("pdhess_blocked")
  }
  finite_methods <- sort(rows$interval_method[rows$interval_finite])
  if (identical(finite_methods, c("profile", "wald"))) {
    return("wald_profile_finite")
  }
  if (identical(finite_methods, "wald")) {
    return("wald_finite_profile_nonfinite")
  }
  if (identical(finite_methods, "profile")) {
    return("profile_finite_wald_nonfinite")
  }
  if (length(finite_methods)) {
    return("partial_finite")
  }
  "no_finite_intervals"
}

classify_failure <- function(rows) {
  if (any(rows$method_status == "fit_error")) {
    return("fit_error")
  }
  if (any(rows$method_status == "not_run_pdhess_false")) {
    return("fit_pdhess_false")
  }
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

endpoint_token <- function(endpoint_member) {
  out <- gsub(":", "_", endpoint_member, fixed = TRUE)
  out <- gsub("(", "", out, fixed = TRUE)
  out <- gsub(")", "", out, fixed = TRUE)
  gsub("_Intercept", "_intercept", out, fixed = TRUE)
}

claim_boundary <- function(provider, stability_status) {
  provider_clause <- switch(
    provider,
    phylo = "Phylo",
    spatial = "Fixed-covariance spatial",
    animal = "Animal A-matrix",
    relmat = "Relmat K-matrix"
  )
  blocked_clause <- switch(
    provider,
    phylo = "",
    spatial = " no range-estimating spatial support,",
    animal = " no pedigree/Ainv bridge marshalling,",
    relmat = " no Q bridge marshalling,"
  )
  paste(
    provider_clause,
    "q4 all-four one-slope direct-SD interval stability probe only;",
    "status =",
    stability_status,
    "with",
    blocked_clause,
    "derived-correlation intervals still blocked, no interval reliability,",
    "interval coverage, q4 REML, AI-REML, or broad bridge support promoted."
  )
}

next_gate <- function(stability_status) {
  if (identical(stability_status, "wald_profile_finite")) {
    return(
      "Repeat with replicated deterministic fixtures and denominator accounting before calibrated coverage wording."
    )
  }
  if (identical(stability_status, "pdhess_blocked")) {
    return(
      "Diagnose persistent q4 all-four one-slope Hessian failures before denominator accounting or coverage-grid design."
    )
  }
  "Diagnose nonfinite or failed interval methods before denominator accounting or coverage-grid design."
}

status_for_target <- function(
  plan_row,
  rows,
  fit,
  target_found,
  variant,
  spec
) {
  provider <- plan_row$structured_type[[1L]]
  endpoint_member <- plan_row$endpoint_member[[1L]]
  stability_status <- classify_stability_status(rows)
  failure_class <- classify_failure(rows)
  fit_ok <- !inherits(fit, "error") && identical(fit$opt$convergence, 0L)
  pdhess <- !inherits(fit, "error") && isTRUE(fit$sdr$pdHess)
  data.frame(
    probe_id = paste0(
      "q4_slope_interval_stability_",
      variant,
      "_",
      provider,
      "_",
      endpoint_token(endpoint_member)
    ),
    cell_id = plan_row$cell_id[[1L]],
    variant = variant,
    formula_cell = plan_row$formula_cell[[1L]],
    structured_type = provider,
    target_kind = plan_row$target_kind[[1L]],
    endpoint_member = endpoint_member,
    estimand = plan_row$estimand[[1L]],
    profile_target = plan_row$profile_target[[1L]],
    source_artifact = file.path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q4-slope-interval-stability-probe",
      "structured-re-q4-slope-interval-stability-probe-results.tsv"
    ),
    n_levels = spec$n,
    n_each = spec$n_each,
    intended_sd_mu1_intercept = spec$sds[["mu1_intercept"]],
    intended_sd_mu1_x = spec$sds[["mu1_x"]],
    intended_sd_mu2_intercept = spec$sds[["mu2_intercept"]],
    intended_sd_mu2_x = spec$sds[["mu2_x"]],
    intended_sd_sigma1_intercept = spec$sds[["sigma1_intercept"]],
    intended_sd_sigma1_x = spec$sds[["sigma1_x"]],
    intended_sd_sigma2_intercept = spec$sds[["sigma2_intercept"]],
    intended_sd_sigma2_x = spec$sds[["sigma2_x"]],
    observed_target_rows = as.integer(target_found),
    n_fit_ok = as.integer(fit_ok),
    n_pdhess = as.integer(pdhess),
    estimate = if (target_found) rows$estimate[[1L]] else NA_real_,
    wald_status = rows$method_status[rows$interval_method == "wald"],
    profile_status = rows$method_status[rows$interval_method == "profile"],
    stability_status = stability_status,
    failure_class = failure_class,
    interval_claim_status = "diagnostic_only",
    status = "covered",
    evidence_url = "docs/dev-log/after-task/2026-06-24-q4-slope-interval-stability-probe.md",
    claim_boundary = claim_boundary(provider, stability_status),
    next_gate = next_gate(stability_status),
    stringsAsFactors = FALSE
  )
}

plan <- utils::read.delim(
  plan_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
direct_plan <- plan[plan$target_kind == "direct_sd", , drop = FALSE]
direct_plan <- direct_plan[
  order(direct_plan$structured_type, direct_plan$diagnostic_id),
]

providers <- c("phylo", "spatial", "animal", "relmat")
seeds <- c(phylo = 801L, spatial = 802L, animal = 803L, relmat = 804L)
variants <- list(
  strong = list(
    seed_offset = 0L,
    n = 8L,
    n_each = 24L,
    sds = c(
      mu1_intercept = 0.70,
      mu1_x = 0.48,
      mu2_intercept = 0.62,
      mu2_x = 0.44,
      sigma1_intercept = 0.50,
      sigma1_x = 0.34,
      sigma2_intercept = 0.46,
      sigma2_x = 0.30
    )
  ),
  more_levels = list(
    seed_offset = 100L,
    n = 16L,
    n_each = 12L,
    sds = c(
      mu1_intercept = 0.62,
      mu1_x = 0.42,
      mu2_intercept = 0.56,
      mu2_x = 0.38,
      sigma1_intercept = 0.42,
      sigma1_x = 0.28,
      sigma2_intercept = 0.40,
      sigma2_x = 0.26
    )
  )
)
methods <- c("wald", "profile")

method_rows <- list()
status_rows <- list()

for (variant in names(variants)) {
  spec <- variants[[variant]]
  for (provider in providers) {
    message(
      "Fitting ",
      provider,
      " q4 all-four one-slope stability model (",
      variant,
      ")"
    )
    sim <- make_provider_data(
      provider,
      seed = seeds[[provider]] + spec$seed_offset,
      n = spec$n,
      n_each = spec$n_each,
      sds = spec$sds
    )
    fit <- tryCatch(fit_provider(provider, sim), error = function(e) e)
    if (inherits(fit, "error")) {
      message(
        "Fit failed for ",
        provider,
        " (",
        variant,
        "): ",
        clean_text(conditionMessage(fit))
      )
    } else {
      message(
        "Fit done for ",
        provider,
        " (",
        variant,
        "): convergence=",
        fit$opt$convergence,
        ", pdHess=",
        isTRUE(fit$sdr$pdHess)
      )
    }
    targets <- if (inherits(fit, "error")) {
      data.frame()
    } else {
      profile_targets(fit)
    }
    provider_plan <- direct_plan[
      direct_plan$structured_type == provider,
      ,
      drop = FALSE
    ]

    for (i in seq_len(nrow(provider_plan))) {
      plan_row <- provider_plan[i, , drop = FALSE]
      parm <- plan_row$profile_target[[1L]]
      target <- targets[match(parm, targets$parm), , drop = FALSE]
      target_found <- nrow(target) == 1L && identical(target$parm[[1L]], parm)

      rows <- if (inherits(fit, "error")) {
        fit_error_rows(methods, conditionMessage(fit))
      } else if (!isTRUE(fit$sdr$pdHess)) {
        message(
          "  interval ",
          provider,
          " ",
          plan_row$endpoint_member[[1L]],
          " blocked: pdHess=FALSE"
        )
        pdhess_blocked_rows(methods)
      } else {
        do.call(
          rbind,
          lapply(methods, function(method) {
            message(
              "  interval ",
              provider,
              " ",
              plan_row$endpoint_member[[1L]],
              " ",
              method
            )
            out <- run_interval(fit, parm, method)
            message(
              "  interval ",
              provider,
              " ",
              plan_row$endpoint_member[[1L]],
              " ",
              method,
              " -> ",
              out$method_status[[1L]]
            )
            out
          })
        )
      }
      rows$variant <- variant
      rows$provider <- provider
      rows$endpoint_member <- plan_row$endpoint_member[[1L]]
      rows$target_kind <- plan_row$target_kind[[1L]]
      rows$estimand <- plan_row$estimand[[1L]]
      rows$profile_target <- parm
      rows$n_levels <- spec$n
      rows$n_each <- spec$n_each
      rows$intended_sd_mu1_intercept <- spec$sds[["mu1_intercept"]]
      rows$intended_sd_mu1_x <- spec$sds[["mu1_x"]]
      rows$intended_sd_mu2_intercept <- spec$sds[["mu2_intercept"]]
      rows$intended_sd_mu2_x <- spec$sds[["mu2_x"]]
      rows$intended_sd_sigma1_intercept <- spec$sds[["sigma1_intercept"]]
      rows$intended_sd_sigma1_x <- spec$sds[["sigma1_x"]]
      rows$intended_sd_sigma2_intercept <- spec$sds[["sigma2_intercept"]]
      rows$intended_sd_sigma2_x <- spec$sds[["sigma2_x"]]
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
      rows$convergence <- if (inherits(fit, "error")) {
        NA_integer_
      } else {
        fit$opt$convergence
      }
      rows$pdHess <- if (inherits(fit, "error")) {
        FALSE
      } else {
        isTRUE(fit$sdr$pdHess)
      }
      rows$logLik <- if (inherits(fit, "error")) {
        NA_real_
      } else {
        as.numeric(stats::logLik(fit))
      }
      method_rows[[length(method_rows) + 1L]] <- rows
      status_rows[[length(status_rows) + 1L]] <- status_for_target(
        plan_row,
        rows,
        fit,
        target_found,
        variant,
        spec
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
    "target_kind",
    "estimand",
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
    "logLik",
    "n_levels",
    "n_each",
    "intended_sd_mu1_intercept",
    "intended_sd_mu1_x",
    "intended_sd_mu2_intercept",
    "intended_sd_mu2_x",
    "intended_sd_sigma1_intercept",
    "intended_sd_sigma1_x",
    "intended_sd_sigma2_intercept",
    "intended_sd_sigma2_x"
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
