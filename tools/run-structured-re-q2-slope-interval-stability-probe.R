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
  "2026-06-24-q2-slope-interval-stability-probe"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

artifact_path <- file.path(
  artifact_dir,
  "structured-re-q2-slope-interval-stability-probe-results.tsv"
)
status_path <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "dashboard",
  "structured-re-q2-slope-interval-stability-probe.tsv"
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

correlated_slope_effects <- function(K, sd_mu1_x, sd_mu2_x, cor_mu1_mu2_x) {
  endpoint_cov <- matrix(
    c(
      sd_mu1_x^2,
      cor_mu1_mu2_x * sd_mu1_x * sd_mu2_x,
      cor_mu1_mu2_x * sd_mu1_x * sd_mu2_x,
      sd_mu2_x^2
    ),
    nrow = 2L
  )
  base <- t(chol(K)) %*% matrix(stats::rnorm(nrow(K) * 2L), nrow(K), 2L)
  out <- base %*% chol(endpoint_cov)
  colnames(out) <- c("mu1_x", "mu2_x")
  out
}

make_provider_data <- function(provider, seed, variant) {
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

  effects <- correlated_slope_effects(
    K,
    sd_mu1_x = variant$sd_mu1_x,
    sd_mu2_x = variant$sd_mu2_x,
    cor_mu1_mu2_x = variant$cor_mu1_mu2_x
  )
  rownames(effects) <- labels
  endpoint <- rep(labels, each = variant$n_each)
  x <- rep(
    seq(-1.25, 1.25, length.out = variant$n_each),
    times = length(labels)
  )
  eta1 <- 0.30 + 0.35 * x + effects[endpoint, "mu1_x"] * x
  eta2 <- -0.15 + 0.25 * x + effects[endpoint, "mu2_x"] * x

  residual_cov <- matrix(
    c(
      variant$sigma1^2,
      variant$rho12 * variant$sigma1 * variant$sigma2,
      variant$rho12 * variant$sigma1 * variant$sigma2,
      variant$sigma2^2
    ),
    nrow = 2L
  )
  residual <- matrix(stats::rnorm(length(x) * 2L), ncol = 2L) %*%
    chol(residual_cov)

  data <- data.frame(
    y1 = eta1 + residual[, 1L],
    y2 = eta2 + residual[, 2L],
    x = x
  )
  data[[group]] <- endpoint

  c(list(data = data), extra)
}

fit_provider <- function(provider, sim) {
  if (identical(provider, "phylo")) {
    tree <- sim$tree
    form <- bf(
      mu1 = y1 ~ x + phylo(0 + x | p | species, tree = tree),
      mu2 = y2 ~ x + phylo(0 + x | p | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    )
  } else if (identical(provider, "spatial")) {
    coords <- sim$coords
    form <- bf(
      mu1 = y1 ~ x + spatial(0 + x | p | site, coords = coords),
      mu2 = y2 ~ x + spatial(0 + x | p | site, coords = coords),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    )
  } else if (identical(provider, "animal")) {
    A <- sim$A
    form <- bf(
      mu1 = y1 ~ x + animal(0 + x | p | id, A = A),
      mu2 = y2 ~ x + animal(0 + x | p | id, A = A),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    )
  } else if (identical(provider, "relmat")) {
    K <- sim$K
    form <- bf(
      mu1 = y1 ~ x + relmat(0 + x | p | id, K = K),
      mu2 = y2 ~ x + relmat(0 + x | p | id, K = K),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    )
  }

  drmTMB(
    form,
    family = biv_gaussian(),
    data = sim$data,
    control = drm_control(optimizer = list(eval.max = 1600, iter.max = 1600))
  )
}

profile_target <- function(provider, endpoint_member) {
  group <- switch(
    provider,
    phylo = "species",
    spatial = "site",
    animal = "id",
    relmat = "id"
  )
  if (identical(endpoint_member, "mu1:x")) {
    return(paste0("sd:mu:mu1:", provider, "(0 + x | p | ", group, ")"))
  }
  if (identical(endpoint_member, "mu2:x")) {
    return(paste0("sd:mu:mu2:", provider, "(0 + x | p | ", group, ")"))
  }
  paste0("cor:", provider, ":cor(mu1:x,mu2:x | p | ", group, ")")
}

estimand <- function(endpoint_member) {
  switch(
    endpoint_member,
    "mu1:x" = "sd_mu1_x",
    "mu2:x" = "sd_mu2_x",
    "mu1:x+mu2:x" = "cor_mu1_mu2_x"
  )
}

target_kind <- function(endpoint_member) {
  if (identical(endpoint_member, "mu1:x+mu2:x")) {
    return("direct_correlation")
  }
  "direct_sd"
}

endpoint_token <- function(endpoint_member) {
  switch(
    endpoint_member,
    "mu1:x" = "mu1_x",
    "mu2:x" = "mu2_x",
    "mu1:x+mu2:x" = "cor_mu1_mu2_x"
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
              profile_endpoint_max_eval = 90L
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
    provider_clause,
    "q2 slope interval stability probe only;",
    "status =",
    stability_status,
    "with",
    blocked_clause,
    "no interval reliability, interval coverage, q4/q8, REML, AI-REML,",
    "or broad bridge support promoted."
  ))
}

next_gate <- function(stability_status) {
  if (identical(stability_status, "wald_profile_finite")) {
    return(
      "Repeat with more seeds and bootstrap denominators before calibrated coverage wording."
    )
  }
  "Diagnose persistent q2 slope boundary/profile failures before coverage-grid design."
}

variants <- list(
  strong = list(
    n_each = 28L,
    sd_mu1_x = 0.95,
    sd_mu2_x = 0.85,
    cor_mu1_mu2_x = 0.25,
    sigma1 = 0.22,
    sigma2 = 0.24,
    rho12 = 0.05
  ),
  stronger_slope = list(
    n_each = 36L,
    sd_mu1_x = 1.35,
    sd_mu2_x = 1.15,
    cor_mu1_mu2_x = 0.20,
    sigma1 = 0.18,
    sigma2 = 0.20,
    rho12 = 0.05
  )
)
variant_seed_offsets <- c(strong = 0L, stronger_slope = 50L)
provider_seeds <- c(phylo = 401L, spatial = 402L, animal = 403L, relmat = 404L)
providers <- c("phylo", "spatial", "animal", "relmat")
endpoint_members <- c("mu1:x", "mu2:x", "mu1:x+mu2:x")
methods <- c("wald", "profile")

method_rows <- list()
status_rows <- list()

for (variant_name in names(variants)) {
  variant <- variants[[variant_name]]
  for (provider in providers) {
    sim <- make_provider_data(
      provider,
      seed = provider_seeds[[provider]] + variant_seed_offsets[[variant_name]],
      variant = variant
    )
    fit <- fit_provider(provider, sim)
    targets <- profile_targets(fit)

    for (endpoint_member in endpoint_members) {
      parm <- profile_target(provider, endpoint_member)
      target <- targets[match(parm, targets$parm), , drop = FALSE]
      target_found <- nrow(target) == 1L && identical(target$parm[[1L]], parm)
      rows <- do.call(
        rbind,
        lapply(methods, function(method) {
          run_interval(fit, parm, method)
        })
      )
      rows$variant <- variant_name
      rows$provider <- provider
      rows$endpoint_member <- endpoint_member
      rows$target_kind <- target_kind(endpoint_member)
      rows$estimand <- estimand(endpoint_member)
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
        "q2_slope_interval_stability_",
        variant_name,
        "_",
        provider,
        "_",
        endpoint_token(endpoint_member)
      )
      status_rows[[length(status_rows) + 1L]] <- data.frame(
        probe_id = probe_id,
        cell_id = paste0("qseries_", provider, "_q2_mu1_mu2_one_slope"),
        variant = variant_name,
        formula_cell = switch(
          provider,
          phylo = "phylo(0 + x | p | species, tree = tree) in mu1 and mu2",
          spatial = "spatial(0 + x | p | site, coords = coords) in mu1 and mu2",
          animal = "animal(0 + x | p | id, A = A) in mu1 and mu2",
          relmat = "relmat(0 + x | p | id, K = K) in mu1 and mu2"
        ),
        structured_type = provider,
        target_kind = target_kind(endpoint_member),
        endpoint_member = endpoint_member,
        estimand = estimand(endpoint_member),
        profile_target = parm,
        source_artifact = file.path(
          "docs",
          "dev-log",
          "simulation-artifacts",
          "2026-06-24-q2-slope-interval-stability-probe",
          "structured-re-q2-slope-interval-stability-probe-results.tsv"
        ),
        n_each = variant$n_each,
        intended_sd_mu1_x = variant$sd_mu1_x,
        intended_sd_mu2_x = variant$sd_mu2_x,
        intended_cor_mu1_mu2_x = variant$cor_mu1_mu2_x,
        residual_sd1 = variant$sigma1,
        residual_sd2 = variant$sigma2,
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
        evidence_url = "docs/dev-log/after-task/2026-06-24-q2-slope-interval-stability-probe.md",
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
