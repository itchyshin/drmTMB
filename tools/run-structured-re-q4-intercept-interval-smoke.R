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
plan_path <- file.path(
  dashboard_dir,
  "structured-re-q4-intercept-interval-diagnostic-plan.tsv"
)
artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-25-q4-intercept-interval-smoke"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

artifact_path <- file.path(
  artifact_dir,
  "structured-re-q4-intercept-interval-smoke-results.tsv"
)
status_path <- file.path(
  dashboard_dir,
  "structured-re-q4-intercept-interval-diagnostic-status.tsv"
)

artifact_rel <- file.path(
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-25-q4-intercept-interval-smoke",
  "structured-re-q4-intercept-interval-smoke-results.tsv"
)
evidence_rel <- file.path(
  "docs",
  "dev-log",
  "after-task",
  "2026-06-25-q4-intercept-interval-smoke-status.md"
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

make_endpoint_covariance <- function() {
  sds <- c(
    mu1_intercept = 0.55,
    mu2_intercept = 0.46,
    sigma1_intercept = 0.30,
    sigma2_intercept = 0.26
  )
  cor_mat <- diag(length(sds))
  cor_mat[lower.tri(cor_mat)] <- 0.08
  cor_mat[upper.tri(cor_mat)] <- t(cor_mat)[upper.tri(cor_mat)]
  out <- diag(sds) %*% cor_mat %*% diag(sds)
  dimnames(out) <- list(names(sds), names(sds))
  out
}

correlated_effects <- function(K) {
  endpoint_cov <- make_endpoint_covariance()
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

make_provider_data <- function(provider, seed, n = 8L, n_each = 18L) {
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

  effects <- correlated_effects(K)
  rownames(effects) <- labels
  endpoint <- rep(labels, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), times = length(labels))
  z <- rep(seq(-0.75, 0.75, length.out = n_each), times = length(labels))

  eta_mu1 <- 0.25 +
    0.22 * x +
    effects[endpoint, "mu1_intercept"]
  eta_mu2 <- -0.10 -
    0.18 * x +
    effects[endpoint, "mu2_intercept"]
  eta_sigma1 <- -1.10 +
    0.05 * z +
    effects[endpoint, "sigma1_intercept"]
  eta_sigma2 <- -1.05 -
    0.04 * z +
    effects[endpoint, "sigma2_intercept"]

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
      mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
      mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
      sigma1 = ~ z + phylo(1 | p | species, tree = tree),
      sigma2 = ~ z + phylo(1 | p | species, tree = tree),
      rho12 = ~1
    )
  } else if (identical(provider, "spatial")) {
    coords <- sim$coords
    form <- bf(
      mu1 = y1 ~ x + spatial(1 | p | site, coords = coords),
      mu2 = y2 ~ x + spatial(1 | p | site, coords = coords),
      sigma1 = ~ z + spatial(1 | p | site, coords = coords),
      sigma2 = ~ z + spatial(1 | p | site, coords = coords),
      rho12 = ~1
    )
  } else if (identical(provider, "animal")) {
    A <- sim$A
    form <- bf(
      mu1 = y1 ~ x + animal(1 | p | id, A = A),
      mu2 = y2 ~ x + animal(1 | p | id, A = A),
      sigma1 = ~ z + animal(1 | p | id, A = A),
      sigma2 = ~ z + animal(1 | p | id, A = A),
      rho12 = ~1
    )
  } else if (identical(provider, "relmat")) {
    K <- sim$K
    form <- bf(
      mu1 = y1 ~ x + relmat(1 | p | id, K = K),
      mu2 = y2 ~ x + relmat(1 | p | id, K = K),
      sigma1 = ~ z + relmat(1 | p | id, K = K),
      sigma2 = ~ z + relmat(1 | p | id, K = K),
      rho12 = ~1
    )
  }

  drmTMB(
    form,
    family = biv_gaussian(),
    data = sim$data,
    control = drm_control(
      fallback_optimizer = "BFGS",
      optimizer = list(eval.max = 1400, iter.max = 1400)
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
        if (identical(method, "bootstrap")) {
          args <- c(args, list(R = 2L, seed = 41L))
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

classify_interval_status <- function(rows) {
  finite_methods <- sort(rows$interval_method[rows$interval_finite])
  if (identical(finite_methods, c("bootstrap", "profile", "wald"))) {
    return("wald_profile_bootstrap_finite")
  }
  if (identical(finite_methods, c("bootstrap", "wald"))) {
    return("wald_bootstrap_finite_profile_failed")
  }
  if (identical(finite_methods, c("profile", "wald"))) {
    return("wald_profile_finite_bootstrap_failed")
  }
  if (identical(finite_methods, c("bootstrap", "profile"))) {
    return("profile_bootstrap_finite_wald_nonfinite")
  }
  if (identical(finite_methods, "wald")) {
    return("wald_only_finite")
  }
  if (identical(finite_methods, "profile")) {
    return("profile_only_finite")
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
  if (any(rows$method_status == "fit_error")) {
    return("fit_error")
  }
  if (any(rows$method_status == "not_run_pdhess_false")) {
    return("fit_pdhess_false")
  }
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

endpoint_token <- function(endpoint_member) {
  out <- gsub(":", "_", endpoint_member, fixed = TRUE)
  out <- gsub("(", "", out, fixed = TRUE)
  out <- gsub(")", "", out, fixed = TRUE)
  gsub("_Intercept", "_intercept", out, fixed = TRUE)
}

claim_boundary <- function(provider, interval_status) {
  provider_clause <- switch(
    provider,
    phylo = "Phylo",
    spatial = "Fixed-covariance spatial",
    animal = "Animal A-matrix",
    relmat = "Relmat K-matrix"
  )
  blocked_clause <- switch(
    provider,
    phylo = "derived-correlation intervals still blocked,",
    spatial = paste(
      "no range-estimating spatial support, derived-correlation intervals",
      "still blocked,"
    ),
    animal = paste(
      "no pedigree/Ainv bridge marshalling, derived-correlation intervals",
      "still blocked,"
    ),
    relmat = "no Q bridge marshalling, derived-correlation intervals still blocked,"
  )
  paste(
    provider_clause,
    "q4 all-four intercept direct-SD interval smoke only;",
    "status =",
    interval_status,
    "with",
    blocked_clause,
    "no interval reliability,",
    "interval coverage, q4 REML, native-TMB q4 REML, q4 AI-REML,",
    "HSquared AI-REML, broad bridge support, public support, or calibrated",
    "coverage wording promoted."
  )
}

next_gate <- function(interval_status) {
  if (identical(interval_status, "wald_profile_bootstrap_finite")) {
    return(
      "Repeat with replicated deterministic fixtures and denominator accounting before coverage-grid design."
    )
  }
  if (identical(interval_status, "no_finite_intervals")) {
    return(
      "Diagnose fit, boundary, and profile failures before denominator accounting or coverage-grid design."
    )
  }
  "Diagnose nonfinite or failed interval methods before denominator accounting or coverage-grid design."
}

status_for_target <- function(plan_row, rows, fit, target_found) {
  provider <- plan_row$structured_type[[1L]]
  endpoint_member <- plan_row$endpoint_member[[1L]]
  interval_status <- classify_interval_status(rows)
  fit_ok <- !inherits(fit, "error") && identical(fit$opt$convergence, 0L)
  pdhess <- !inherits(fit, "error") && isTRUE(fit$sdr$pdHess)
  data.frame(
    diagnostic_id = paste0(
      "q4_intercept_interval_status_",
      provider,
      "_",
      endpoint_token(endpoint_member)
    ),
    cell_id = plan_row$cell_id[[1L]],
    formula_cell = plan_row$formula_cell[[1L]],
    structured_type = provider,
    target_kind = plan_row$target_kind[[1L]],
    endpoint_member = endpoint_member,
    estimand = plan_row$estimand[[1L]],
    profile_target = plan_row$profile_target[[1L]],
    source_artifact = artifact_rel,
    observed_target_rows = as.integer(target_found),
    n_fit_ok = as.integer(fit_ok),
    n_converged = as.integer(fit_ok),
    n_pdhess = as.integer(pdhess),
    n_finite_intervals = sum(rows$interval_finite),
    wald_status = rows$method_status[rows$interval_method == "wald"],
    profile_status = rows$method_status[rows$interval_method == "profile"],
    bootstrap_status = rows$method_status[rows$interval_method == "bootstrap"],
    interval_status = interval_status,
    failure_class = classify_failure(rows),
    interval_claim_status = "diagnostic_only",
    status = "covered",
    evidence_url = evidence_rel,
    claim_boundary = claim_boundary(provider, interval_status),
    next_gate = next_gate(interval_status),
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
seeds <- c(phylo = 901L, spatial = 902L, animal = 903L, relmat = 904L)
methods <- c("wald", "profile", "bootstrap")

method_rows <- list()
status_rows <- list()

for (provider in providers) {
  message("Fitting ", provider, " q4 all-four intercept smoke model")
  sim <- make_provider_data(provider, seed = seeds[[provider]])
  fit <- tryCatch(fit_provider(provider, sim), error = function(e) e)
  if (inherits(fit, "error")) {
    message(
      "Fit failed for ",
      provider,
      ": ",
      clean_text(conditionMessage(fit))
    )
  } else {
    message(
      "Fit done for ",
      provider,
      ": convergence=",
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

    interval_rows <- if (inherits(fit, "error")) {
      fit_error_rows(methods, conditionMessage(fit))
    } else if (!isTRUE(fit$sdr$pdHess)) {
      pdhess_blocked_rows(methods)
    } else if (!target_found) {
      fit_error_rows(methods, paste("missing profile target", parm))
    } else {
      do.call(
        rbind,
        lapply(methods, function(method) {
          run_interval(fit, parm, method)
        })
      )
    }

    estimate <- if (target_found) target$estimate[[1L]] else NA_real_
    profile_ready <- target_found
    profile_note <- if (target_found) "ready" else "missing_profile_target"
    method_rows[[length(method_rows) + 1L]] <- cbind(
      data.frame(
        provider = provider,
        endpoint_member = plan_row$endpoint_member[[1L]],
        target_kind = plan_row$target_kind[[1L]],
        estimand = plan_row$estimand[[1L]],
        profile_target = parm,
        stringsAsFactors = FALSE
      ),
      interval_rows,
      data.frame(
        estimate = estimate,
        profile_ready = profile_ready,
        profile_note = profile_note,
        convergence = if (inherits(fit, "error")) {
          NA_integer_
        } else {
          fit$opt$convergence
        },
        pdHess = if (inherits(fit, "error")) NA else isTRUE(fit$sdr$pdHess),
        logLik = if (inherits(fit, "error")) {
          NA_real_
        } else {
          as.numeric(stats::logLik(fit))
        },
        stringsAsFactors = FALSE
      )
    )
    status_rows[[length(status_rows) + 1L]] <- status_for_target(
      plan_row,
      interval_rows,
      fit,
      target_found
    )
  }
}

method_out <- do.call(rbind, method_rows)
status_out <- do.call(rbind, status_rows)
utils::write.table(
  method_out,
  artifact_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)
utils::write.table(
  status_out,
  status_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)

message("wrote ", artifact_path, " with ", nrow(method_out), " rows")
message("wrote ", status_path, " with ", nrow(status_out), " rows")
