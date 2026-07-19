#!/usr/bin/env Rscript

# Arc 3a retained-denominator recovery runner.
#
# This script executes local fits only. It never launches remote work and never
# writes GitHub artifacts. The certification defaults are frozen in
# docs/dev-log/2026-07-14-arc3a-recovery-campaign-manifest.md.

`%||%` <- function(x, y) if (is.null(x)) y else x

clean_text <- function(x) {
  x <- as.character(x %||% "")
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  trimws(gsub(" +", " ", x))
}

parse_integer_vector <- function(x, name) {
  out <- suppressWarnings(as.integer(strsplit(x, ",", fixed = TRUE)[[1L]]))
  if (!length(out) || anyNA(out) || any(out < 1L)) {
    stop(
      "--",
      name,
      " must be a comma-separated vector of positive integers",
      call. = FALSE
    )
  }
  out
}

parse_args <- function(args) {
  out <- list(
    mode = "tiny",
    output = NULL,
    seed_output = NULL,
    session_output = NULL,
    reps = NULL,
    M = NULL,
    n_per_level = 20L,
    routes = NULL,
    load = "source",
    shard_index = 1L,
    shard_count = 1L,
    help = FALSE
  )
  for (arg in args) {
    if (identical(arg, "--help")) {
      out$help <- TRUE
    } else if (startsWith(arg, "--mode=")) {
      out$mode <- sub("^--mode=", "", arg)
    } else if (startsWith(arg, "--output=")) {
      out$output <- sub("^--output=", "", arg)
    } else if (startsWith(arg, "--seed-output=")) {
      out$seed_output <- sub("^--seed-output=", "", arg)
    } else if (startsWith(arg, "--session-output=")) {
      out$session_output <- sub("^--session-output=", "", arg)
    } else if (startsWith(arg, "--reps=")) {
      out$reps <- as.integer(sub("^--reps=", "", arg))
    } else if (startsWith(arg, "--M=")) {
      out$M <- parse_integer_vector(sub("^--M=", "", arg), "M")
    } else if (startsWith(arg, "--n-per-level=")) {
      out$n_per_level <- as.integer(sub("^--n-per-level=", "", arg))
    } else if (startsWith(arg, "--routes=")) {
      out$routes <- strsplit(sub("^--routes=", "", arg), ",", fixed = TRUE)[[
        1L
      ]]
    } else if (startsWith(arg, "--load=")) {
      out$load <- sub("^--load=", "", arg)
    } else if (startsWith(arg, "--shard-index=")) {
      out$shard_index <- as.integer(sub("^--shard-index=", "", arg))
    } else if (startsWith(arg, "--shard-count=")) {
      out$shard_count <- as.integer(sub("^--shard-count=", "", arg))
    } else {
      stop("Unknown argument: ", arg, call. = FALSE)
    }
  }

  out$mode <- match.arg(
    out$mode,
    c(
      "tiny",
      "smoke",
      "pilot",
      "certification",
      "phylo_smoke",
      "phylo_pilot",
      "phylo_certification",
      "diagnostic"
    )
  )
  if (identical(out$mode, "smoke")) {
    out$mode <- "tiny"
  }
  out$load <- match.arg(out$load, c("source", "installed"))
  if (is.na(out$n_per_level) || out$n_per_level < 1L) {
    stop("--n-per-level must be a positive integer", call. = FALSE)
  }
  if (is.na(out$shard_count) || out$shard_count < 1L || out$shard_count > 96L) {
    stop("--shard-count must be an integer from 1 through 96", call. = FALSE)
  }
  if (
    is.na(out$shard_index) ||
      out$shard_index < 1L ||
      out$shard_index > out$shard_count
  ) {
    stop(
      "--shard-index must be an integer from 1 through --shard-count",
      call. = FALSE
    )
  }

  defaults <- switch(
    out$mode,
    tiny = list(reps = 1L, M = 16L),
    pilot = list(reps = 10L, M = 16L),
    certification = list(reps = 400L, M = c(16L, 32L, 64L)),
    phylo_smoke = list(reps = 1L, M = 16L),
    phylo_pilot = list(reps = 10L, M = 16L),
    phylo_certification = list(reps = 400L, M = c(16L, 32L, 64L)),
    diagnostic = list(reps = 1L, M = 16L)
  )
  out$reps <- out$reps %||% defaults$reps
  out$M <- out$M %||% defaults$M
  if (is.na(out$reps) || out$reps < 1L) {
    stop("--reps must be a positive integer", call. = FALSE)
  }
  if (any(log2(out$M) != floor(log2(out$M)))) {
    stop(
      "Every --M value must be a power of two for the balanced tree",
      call. = FALSE
    )
  }

  if (out$mode %in% c("certification", "phylo_certification")) {
    if (
      !identical(as.integer(out$M), c(16L, 32L, 64L)) ||
        !identical(as.integer(out$reps), 400L) ||
        !identical(as.integer(out$n_per_level), 20L)
    ) {
      stop(
        "Certification modes are frozen at M=16,32,64, reps=400, and n-per-level=20; use --mode=diagnostic for overrides",
        call. = FALSE
      )
    }
  }
  out
}

usage <- function() {
  cat(paste(
    "Usage:",
    "  Rscript tools/arc3a-positive-continuous-structured-mu-recovery.R",
    "    --mode=tiny|pilot|certification|phylo_smoke|phylo_pilot|phylo_certification|diagnostic --output=PATH",
    "    [--seed-output=PATH] [--session-output=PATH]",
    "    [--reps=N] [--M=16,32,64] [--n-per-level=20]",
    "    [--routes=gamma_phylo,lognormal_phylo,lognormal_relmat_K,lognormal_relmat_Q,gamma_relmat_K]",
    "    [--load=source|installed] [--shard-index=1] [--shard-count=1]",
    "",
    "tiny/smoke: five manifest smoke fits at M=16, replicate 1",
    "pilot: 50 manifest pilot fits at M=16",
    "certification: one deterministic shard of the exactly 6,000-fit frozen manifest",
    "phylo_smoke: two fresh-seed addendum fits at M=16",
    "phylo_pilot: 20 fresh-seed addendum fits at M=16",
    "phylo_certification: one deterministic shard of the exactly 2,400-fit fresh addendum",
    "diagnostic: configurable local-only run; never certification evidence",
    sep = "\n"
  ))
}

args <- parse_args(commandArgs(trailingOnly = TRUE))
if (args$help) {
  usage()
  quit(save = "no", status = 0L)
}

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_path <- if (length(script_arg)) {
  sub("^--file=", "", script_arg[[1L]])
} else {
  "tools"
}
repo_root <- normalizePath(
  file.path(dirname(script_path), ".."),
  mustWork = FALSE
)
if (!file.exists(file.path(repo_root, "DESCRIPTION"))) {
  repo_root <- normalizePath(getwd())
}

all_routes <- data.frame(
  fit_route = c(
    "gamma_phylo",
    "lognormal_phylo",
    "lognormal_relmat_K",
    "lognormal_relmat_Q",
    "gamma_relmat_K"
  ),
  dgp_cell = c(
    "gamma_phylo",
    "lognormal_phylo",
    "lognormal_relmat",
    "lognormal_relmat",
    "gamma_relmat"
  ),
  family = c("gamma", "lognormal", "lognormal", "lognormal", "gamma"),
  provider = c("phylo", "phylo", "relmat", "relmat", "relmat"),
  representation = c("tree", "tree", "K", "Q", "K"),
  role = c("new", "new", "new", "new_parity", "comparator"),
  stringsAsFactors = FALSE
)
if (!is.null(args$routes)) {
  unknown <- setdiff(args$routes, all_routes$fit_route)
  if (length(unknown)) {
    stop("Unknown route(s): ", paste(unknown, collapse = ", "), call. = FALSE)
  }
  all_routes <- all_routes[
    match(args$routes, all_routes$fit_route),
    ,
    drop = FALSE
  ]
}
if (!nrow(all_routes)) {
  stop("No fit routes selected", call. = FALSE)
}
if (
  identical(args$mode, "certification") &&
    !identical(
      all_routes$fit_route,
      c(
        "gamma_phylo",
        "lognormal_phylo",
        "lognormal_relmat_K",
        "lognormal_relmat_Q",
        "gamma_relmat_K"
      )
    )
) {
  stop(
    "Certification must include all five frozen routes in canonical order",
    call. = FALSE
  )
}
if (
  args$mode %in%
    c("phylo_smoke", "phylo_pilot", "phylo_certification") &&
    !identical(all_routes$fit_route, c("gamma_phylo", "lognormal_phylo"))
) {
  stop(
    "Phylo certification must include exactly gamma_phylo,lognormal_phylo in canonical order",
    call. = FALSE
  )
}

default_output <- file.path(
  tempdir(),
  paste0("arc3a-positive-continuous-structured-mu-", args$mode, "-raw.tsv")
)
raw_path <- normalizePath(args$output %||% default_output, mustWork = FALSE)
strip_tsv <- function(path) sub("\\.tsv$", "", path, ignore.case = TRUE)
seed_path <- normalizePath(
  args$seed_output %||% paste0(strip_tsv(raw_path), "-seeds.tsv"),
  mustWork = FALSE
)
session_path <- normalizePath(
  args$session_output %||% paste0(strip_tsv(raw_path), "-session.txt"),
  mustWork = FALSE
)
for (path in c(raw_path, seed_path, session_path)) {
  if (file.exists(path)) {
    stop("Refusing to overwrite existing output: ", path, call. = FALSE)
  }
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
}

write_tsv <- function(x, path) {
  utils::write.table(
    x,
    file = path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA"
  )
}

append_tsv <- function(x, path) {
  append <- file.exists(path)
  utils::write.table(
    x,
    file = path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    col.names = !append,
    append = append,
    na = "NA"
  )
}

sha256_file <- function(path) {
  sha256sum <- Sys.which("sha256sum")
  shasum <- Sys.which("shasum")
  quoted_path <- shQuote(path)
  out <- if (nzchar(sha256sum)) {
    system2(sha256sum, quoted_path, stdout = TRUE, stderr = TRUE)
  } else if (nzchar(shasum)) {
    system2(shasum, c("-a", "256", quoted_path), stdout = TRUE, stderr = TRUE)
  } else {
    stop(
      "sha256sum or shasum is required for the campaign hash contract",
      call. = FALSE
    )
  }
  token <- strsplit(out[[1L]], "[[:space:]]+")[[1L]][[1L]]
  if (!grepl("^[0-9a-fA-F]{64}$", token)) {
    stop("Could not parse SHA-256 for ", path, call. = FALSE)
  }
  tolower(token)
}

sha256_object <- function(x) {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(x, path, version = 3)
  sha256_file(path)
}

git_value <- function(args) {
  out <- tryCatch(
    system2("git", c("-C", repo_root, args), stdout = TRUE, stderr = TRUE),
    error = function(e) character()
  )
  if (!length(out)) NA_character_ else clean_text(out[[1L]])
}

load_package <- function(load) {
  if (identical(load, "source")) {
    if (!requireNamespace("pkgload", quietly = TRUE)) {
      stop("pkgload is required for --load=source", call. = FALSE)
    }
    pkgload::load_all(repo_root, quiet = TRUE, export_all = FALSE)
  } else {
    if (!requireNamespace("drmTMB", quietly = TRUE)) {
      stop("drmTMB is not installed for --load=installed", call. = FALSE)
    }
    suppressPackageStartupMessages(library(drmTMB))
  }
  invisible(TRUE)
}

load_package(args$load)

source_sha <- git_value(c("rev-parse", "HEAD"))
dirty_lines <- tryCatch(
  system2(
    "git",
    c("-C", repo_root, "status", "--porcelain"),
    stdout = TRUE,
    stderr = TRUE
  ),
  error = function(e) paste("git status failed:", conditionMessage(e))
)
source_dirty <- length(dirty_lines) > 0L
host <- Sys.info()[["nodename"]] %||% "unknown"
is_phylo_addendum <- args$mode %in%
  c("phylo_smoke", "phylo_pilot", "phylo_certification")
r_tree_sha <- git_value(c("rev-parse", "HEAD:R"))
src_tree_sha <- git_value(c("rev-parse", "HEAD:src"))
if (
  is_phylo_addendum &&
    (!identical(r_tree_sha, "84e4d7111a3514f119e5386d9299044aa78a36b7") ||
      !identical(src_tree_sha, "5e385ee36b910f907c807c5d5c3767b34e22a373"))
) {
  stop(
    "Phylo addendum requires R/ and src/ trees byte-identical to primary source 0ef41a69",
    call. = FALSE
  )
}
campaign_id <- if (is_phylo_addendum) {
  "arc3a_phylo_recovery_addendum_20260714"
} else {
  "arc3a_positive_continuous_structured_mu_20260714"
}
master_seed <- if (is_phylo_addendum) 2026071431L else 2026071403L
truth_beta0 <- 0.20
truth_beta_x <- 0.35
truth_beta_sigma <- log(0.35)
truth_tau <- 0.50

session_lines <- c(
  paste0("campaign_id=", campaign_id),
  paste0("source_commit_sha=", source_sha),
  paste0("r_tree_sha=", r_tree_sha),
  paste0("src_tree_sha=", src_tree_sha),
  paste0("source_dirty=", source_dirty),
  paste0("source_dirty_paths=", clean_text(paste(dirty_lines, collapse = ";"))),
  paste0("host=", host),
  paste0("mode=", args$mode),
  paste0("load=", args$load),
  paste0("command=", clean_text(paste(commandArgs(FALSE), collapse = " "))),
  paste0("master_seed=", master_seed),
  paste0("M=", paste(args$M, collapse = ",")),
  paste0("n_per_level=", args$n_per_level),
  paste0("reps=", args$reps),
  paste0("routes=", paste(all_routes$fit_route, collapse = ",")),
  paste0("shard_index=", args$shard_index),
  paste0("shard_count=", args$shard_count),
  paste0(
    "OPENBLAS_NUM_THREADS=",
    Sys.getenv("OPENBLAS_NUM_THREADS", unset = "")
  ),
  paste0("OMP_NUM_THREADS=", Sys.getenv("OMP_NUM_THREADS", unset = "")),
  paste0("MKL_NUM_THREADS=", Sys.getenv("MKL_NUM_THREADS", unset = "")),
  paste0("TMB_NTHREADS=", Sys.getenv("TMB_NTHREADS", unset = "")),
  capture.output(sessionInfo())
)
writeLines(session_lines, session_path)
session_manifest_hash <- sha256_file(session_path)

# Build the immutable canonical seed manifest before any fit. Even smoke and
# pilot select from the certification seed stream so their first replicate is
# exactly the predeclared replicate 1 at M=16.
canonical_cells <- if (is_phylo_addendum) {
  c("gamma_phylo", "lognormal_phylo")
} else {
  c("gamma_phylo", "lognormal_phylo", "lognormal_relmat", "gamma_relmat")
}
canonical_M <- c(16L, 32L, 64L)
canonical_reps <- 400L
seed_manifest <- expand.grid(
  dgp_cell = canonical_cells,
  M = canonical_M,
  replicate = seq_len(canonical_reps),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
seed_manifest <- seed_manifest[
  order(
    match(seed_manifest$dgp_cell, canonical_cells),
    seed_manifest$M,
    seed_manifest$replicate
  ),
  ,
  drop = FALSE
]
set.seed(master_seed)
seed_manifest$dgp_seed <- sample.int(
  .Machine$integer.max,
  nrow(seed_manifest),
  replace = FALSE
)
seed_manifest$master_seed <- master_seed
selected_dgp <- unique(all_routes$dgp_cell)
selected_seeds <- seed_manifest[
  seed_manifest$dgp_cell %in%
    selected_dgp &
    seed_manifest$M %in% args$M &
    seed_manifest$replicate <= args$reps,
  ,
  drop = FALSE
]
write_tsv(selected_seeds, seed_path)
if (!file.exists(seed_path) || file.info(seed_path)$size <= 0L) {
  stop("Seed manifest is empty", call. = FALSE)
}

balanced_tree <- function(M) {
  edge <- matrix(integer(), ncol = 2L)
  edge_length <- numeric()
  next_node <- M + 1L
  build <- function(tips) {
    if (length(tips) == 1L) {
      return(tips)
    }
    node <- next_node
    next_node <<- next_node + 1L
    half <- length(tips) / 2L
    left <- build(tips[seq_len(half)])
    right <- build(tips[seq.int(half + 1L, length(tips))])
    edge <<- rbind(edge, c(node, left), c(node, right))
    edge_length <<- c(edge_length, 1, 1)
    node
  }
  build(seq_len(M))
  structure(
    list(
      edge = edge,
      edge.length = edge_length,
      tip.label = sprintf("g%03d", seq_len(M)),
      Nnode = M - 1L
    ),
    class = "phylo"
  )
}

relatedness <- function(M) {
  labels <- sprintf("g%03d", seq_len(M))
  K <- outer(seq_len(M), seq_len(M), function(i, j) 0.5^abs(i - j))
  dimnames(K) <- list(labels, labels)
  K
}

provider_geometry <- function(provider, M) {
  tree <- balanced_tree(M)
  K <- relatedness(M)
  Q <- solve(K)
  covariance <- if (identical(provider, "phylo")) {
    drmTMB:::drm_phylo_tip_covariance(tree)
  } else {
    K
  }
  list(
    tree = tree,
    K = K,
    Q = Q,
    covariance = covariance,
    tree_hash = if (identical(provider, "phylo")) {
      sha256_object(tree)
    } else {
      NA_character_
    },
    K_hash = if (identical(provider, "relmat")) {
      sha256_object(K)
    } else {
      NA_character_
    },
    Q_hash = if (identical(provider, "relmat")) {
      sha256_object(Q)
    } else {
      NA_character_
    }
  )
}

simulate_dgp <- function(family, provider, M, n_per_level, seed) {
  geometry <- provider_geometry(provider, M)
  set.seed(seed)
  field <- as.vector(
    t(chol(geometry$covariance)) %*% stats::rnorm(M)
  ) *
    truth_tau
  names(field) <- rownames(geometry$covariance)
  id <- rep(names(field), each = n_per_level)
  x <- stats::rnorm(length(id))
  eta_mu <- truth_beta0 + truth_beta_x * x + field[id]
  sigma <- exp(truth_beta_sigma)
  y <- if (identical(family, "lognormal")) {
    stats::rlnorm(length(id), meanlog = eta_mu, sdlog = sigma)
  } else {
    stats::rgamma(
      length(id),
      shape = 1 / sigma^2,
      scale = exp(eta_mu) * sigma^2
    )
  }
  list(
    data = data.frame(
      y = unname(y),
      x = x,
      id = factor(id, levels = names(field))
    ),
    field = field,
    geometry = geometry
  )
}

empty_row <- function(route, M, replicate, dgp_seed, global_fit_index) {
  data.frame(
    campaign_id = campaign_id,
    source_commit_sha = source_sha,
    source_dirty = source_dirty,
    host = host,
    phase = args$mode,
    shard_index = args$shard_index,
    shard_count = args$shard_count,
    global_fit_index = global_fit_index,
    fit_route = route$fit_route,
    dgp_cell = route$dgp_cell,
    family = route$family,
    provider = route$provider,
    representation = route$representation,
    role = route$role,
    M = M,
    n_per_level = args$n_per_level,
    N = M * args$n_per_level,
    replicate = replicate,
    dgp_seed = dgp_seed,
    fit_key = paste(route$fit_route, M, replicate, sep = ":"),
    attempted = TRUE,
    fit_success = FALSE,
    analysis_success = FALSE,
    failure_stage = "dgp",
    error_class = NA_character_,
    error_message = NA_character_,
    warning_message = NA_character_,
    elapsed_seconds = NA_real_,
    convergence_code = NA_integer_,
    convergence_message = NA_character_,
    objective = NA_real_,
    hessian_covariance_values = NA_character_,
    hessian_diagnostic_finite = FALSE,
    pdHess = NA,
    boundary = NA,
    gross_sigma = NA,
    truth_beta0 = truth_beta0,
    truth_beta_x = truth_beta_x,
    truth_beta_sigma = truth_beta_sigma,
    truth_tau = truth_tau,
    estimate_beta0 = NA_real_,
    estimate_beta_x = NA_real_,
    estimate_beta_sigma = NA_real_,
    estimate_tau = NA_real_,
    extractor_beta_mu_names = NA_character_,
    extractor_beta_sigma_names = NA_character_,
    extractor_sd_name = NA_character_,
    extractor_random_block = NA_character_,
    prediction_identity_max_abs_error = NA_real_,
    conditional_field_rmse = NA_real_,
    conditional_field_correlation = NA_real_,
    field_level_names = NA_character_,
    truth_field_values = NA_character_,
    estimate_field_values = NA_character_,
    tree_hash = NA_character_,
    K_hash = NA_character_,
    Q_hash = NA_character_,
    provider_object_hash = NA_character_,
    session_manifest_hash = session_manifest_hash,
    stringsAsFactors = FALSE
  )
}

record_failure <- function(row, stage, condition) {
  row$failure_stage <- stage
  row$error_class <- paste(class(condition), collapse = "/")
  row$error_message <- clean_text(conditionMessage(condition))
  row
}

fit_one <- function(route, M, replicate, dgp_seed, global_fit_index) {
  row <- empty_row(route, M, replicate, dgp_seed, global_fit_index)
  sim <- tryCatch(
    simulate_dgp(route$family, route$provider, M, args$n_per_level, dgp_seed),
    error = identity
  )
  if (inherits(sim, "error")) {
    return(record_failure(row, "dgp", sim))
  }

  row$tree_hash <- sim$geometry$tree_hash
  row$K_hash <- sim$geometry$K_hash
  row$Q_hash <- sim$geometry$Q_hash
  row$field_level_names <- paste(names(sim$field), collapse = ";")
  row$truth_field_values <- paste(
    sprintf("%.17g", unname(sim$field)),
    collapse = ";"
  )
  row$provider_object_hash <- switch(
    route$representation,
    tree = row$tree_hash,
    K = row$K_hash,
    Q = row$Q_hash
  )

  tree <- sim$geometry$tree
  K <- sim$geometry$K
  Q <- sim$geometry$Q
  formula <- tryCatch(
    switch(
      route$representation,
      tree = bf(y ~ x + phylo(1 | id, tree = tree), sigma ~ 1),
      K = bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1),
      Q = bf(y ~ x + relmat(1 | id, Q = Q), sigma ~ 1)
    ),
    error = identity
  )
  if (inherits(formula, "error")) {
    return(record_failure(row, "provider_build", formula))
  }

  warnings <- character()
  family <- if (identical(route$family, "lognormal")) {
    lognormal()
  } else {
    stats::Gamma(link = "log")
  }
  elapsed <- system.time({
    fit <- tryCatch(
      withCallingHandlers(
        drmTMB(
          formula,
          family = family,
          data = sim$data,
          REML = FALSE,
          control = drm_control(
            se = TRUE,
            optimizer = list(eval.max = 800, iter.max = 800)
          )
        ),
        warning = function(w) {
          warnings <<- c(warnings, conditionMessage(w))
          invokeRestart("muffleWarning")
        }
      ),
      error = identity
    )
  })
  row$elapsed_seconds <- unname(elapsed[["elapsed"]])
  row$warning_message <- clean_text(paste(warnings, collapse = "; "))
  if (inherits(fit, "error")) {
    return(record_failure(row, "fit_error", fit))
  }

  row$convergence_code <- suppressWarnings(as.integer(fit$opt$convergence[[
    1L
  ]]))
  row$convergence_message <- clean_text(fit$opt$message %||% "")
  row$objective <- suppressWarnings(as.numeric(
    fit$opt$objective[[1L]] %||% fit$obj$fn()
  ))
  if (is.na(row$convergence_code) || row$convergence_code != 0L) {
    row$failure_stage <- "optimizer"
    return(row)
  }

  key <- paste0(route$provider, "_mu")
  sd_name <- sprintf("%s(1 | id)", route$provider)
  extracted <- tryCatch(
    {
      beta_mu <- coef(fit, "mu")
      beta_sigma <- coef(fit, "sigma")
      tau_hat <- unname(fit$sdpars$mu[[sd_name]])
      re <- ranef(fit, key)
      contribution <- drmTMB:::phylo_mu_contribution(fit, dpar = "mu")
      fixed <- as.vector(fit$model$X$mu %*% beta_mu)
      predicted <- predict(fit, dpar = "mu", type = "link")
      field_hat <- tapply(contribution, sim$data$id, function(x) {
        values <- unique(x)
        if (length(values) != 1L) {
          stop(
            "Conditional structured contribution varies within a structured level",
            call. = FALSE
          )
        }
        values[[1L]]
      })
      field_hat <- field_hat[names(sim$field)]
      list(
        beta_mu = beta_mu,
        beta_sigma = beta_sigma,
        tau = tau_hat,
        re = re,
        contribution = contribution,
        prediction_error = max(abs(unname(predicted) - fixed - contribution)),
        field_rmse = sqrt(mean((field_hat - sim$field)^2)),
        field_correlation = stats::cor(field_hat, sim$field),
        field_hat = field_hat
      )
    },
    error = identity
  )
  if (inherits(extracted, "error")) {
    return(record_failure(row, "extractor", extracted))
  }

  row$estimate_beta0 <- unname(extracted$beta_mu[["(Intercept)"]])
  row$estimate_beta_x <- unname(extracted$beta_mu[["x"]])
  row$estimate_beta_sigma <- unname(extracted$beta_sigma[["(Intercept)"]])
  row$estimate_tau <- extracted$tau
  row$extractor_beta_mu_names <- paste(names(extracted$beta_mu), collapse = ";")
  row$extractor_beta_sigma_names <- paste(
    names(extracted$beta_sigma),
    collapse = ";"
  )
  row$extractor_sd_name <- sd_name
  row$extractor_random_block <- key
  row$prediction_identity_max_abs_error <- extracted$prediction_error
  row$conditional_field_rmse <- extracted$field_rmse
  row$conditional_field_correlation <- extracted$field_correlation
  row$estimate_field_values <- paste(
    sprintf("%.17g", unname(extracted$field_hat)),
    collapse = ";"
  )

  finite_targets <- all(is.finite(c(
    row$objective,
    row$estimate_beta0,
    row$estimate_beta_x,
    row$estimate_beta_sigma,
    row$estimate_tau,
    row$prediction_identity_max_abs_error,
    row$conditional_field_rmse,
    row$conditional_field_correlation
  )))
  scale_identity_ok <- is.finite(row$prediction_identity_max_abs_error) &&
    row$prediction_identity_max_abs_error <= 1e-8
  named_extractors_ok <- identical(
    names(extracted$beta_mu),
    c("(Intercept)", "x")
  ) &&
    identical(names(extracted$beta_sigma), "(Intercept)") &&
    identical(names(fit$sdpars$mu), sd_name) &&
    identical(names(fit$random_effects), key)
  if (!finite_targets || !scale_identity_ok || !named_extractors_ok) {
    row$failure_stage <- "nonfinite"
    row$error_message <- clean_text(paste(
      "finite_targets=",
      finite_targets,
      "scale_identity_ok=",
      scale_identity_ok,
      "named_extractors_ok=",
      named_extractors_ok
    ))
    return(row)
  }

  row$fit_success <- TRUE
  row$pdHess <- isTRUE(fit$sdr$pdHess)
  covariance <- fit$sdr$cov.fixed
  if (!is.null(covariance) && length(covariance) > 0L) {
    row$hessian_covariance_values <- paste(
      sprintf("%.17g", as.numeric(covariance)),
      collapse = ";"
    )
  }
  row$hessian_diagnostic_finite <- !is.null(covariance) &&
    length(covariance) > 0L &&
    all(is.finite(covariance))
  row$analysis_success <- row$fit_success && row$hessian_diagnostic_finite
  row$boundary <- row$estimate_tau <= 0.05 || row$estimate_tau >= 2.00
  sigma_hat <- exp(row$estimate_beta_sigma)
  row$gross_sigma <- sigma_hat < 0.0875 || sigma_hat > 1.40
  row$failure_stage <- if (row$hessian_diagnostic_finite) "none" else "hessian"
  row
}

schedule <- merge(
  all_routes,
  selected_seeds,
  by = "dgp_cell",
  all.x = TRUE,
  sort = FALSE
)
schedule <- schedule[
  order(
    match(schedule$fit_route, all_routes$fit_route),
    schedule$M,
    schedule$replicate
  ),
  ,
  drop = FALSE
]
full_expected_rows <- nrow(all_routes) * length(args$M) * args$reps
if (nrow(schedule) != full_expected_rows || anyNA(schedule$dgp_seed)) {
  stop("Internal schedule mismatch before fitting", call. = FALSE)
}
schedule$global_fit_index <- seq_len(nrow(schedule))
schedule <- schedule[
  ((schedule$global_fit_index - 1L) %% args$shard_count) + 1L ==
    args$shard_index,
  ,
  drop = FALSE
]
expected_rows <- sum(
  ((seq_len(full_expected_rows) - 1L) %% args$shard_count) + 1L ==
    args$shard_index
)
if (nrow(schedule) != expected_rows || expected_rows < 1L) {
  stop("Internal shard schedule mismatch before fitting", call. = FALSE)
}

results <- vector("list", nrow(schedule))
for (i in seq_len(nrow(schedule))) {
  route <- schedule[
    i,
    c("fit_route", "dgp_cell", "family", "provider", "representation", "role")
  ]
  results[[i]] <- fit_one(
    route,
    M = schedule$M[[i]],
    replicate = schedule$replicate[[i]],
    dgp_seed = schedule$dgp_seed[[i]],
    global_fit_index = schedule$global_fit_index[[i]]
  )
  append_tsv(results[[i]], raw_path)
  if (i == 1L) {
    first <- results[[i]]
    if (!nrow(first) || anyNA(first$attempted) || !isTRUE(first$attempted)) {
      stop(
        "First fit did not produce one valid attempted row; aborting before scale-up",
        call. = FALSE
      )
    }
    first_read_back <- utils::read.delim(
      raw_path,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
    if (
      nrow(first_read_back) != 1L || !isTRUE(first_read_back$attempted[[1L]])
    ) {
      stop(
        "First attempted row failed immediate TSV read-back; aborting before scale-up",
        call. = FALSE
      )
    }
  }
}
raw <- do.call(rbind, results)

required_columns <- c(
  "campaign_id",
  "source_commit_sha",
  "host",
  "phase",
  "fit_route",
  "dgp_cell",
  "family",
  "provider",
  "shard_index",
  "shard_count",
  "global_fit_index",
  "representation",
  "M",
  "n_per_level",
  "N",
  "replicate",
  "dgp_seed",
  "fit_key",
  "attempted",
  "fit_success",
  "analysis_success",
  "failure_stage",
  "error_class",
  "error_message",
  "elapsed_seconds",
  "convergence_code",
  "convergence_message",
  "objective",
  "hessian_covariance_values",
  "hessian_diagnostic_finite",
  "pdHess",
  "boundary",
  "gross_sigma",
  "truth_beta0",
  "truth_beta_x",
  "truth_beta_sigma",
  "truth_tau",
  "estimate_beta0",
  "estimate_beta_x",
  "estimate_beta_sigma",
  "estimate_tau",
  "extractor_beta_mu_names",
  "extractor_beta_sigma_names",
  "extractor_sd_name",
  "extractor_random_block",
  "prediction_identity_max_abs_error",
  "conditional_field_rmse",
  "conditional_field_correlation",
  "field_level_names",
  "truth_field_values",
  "estimate_field_values",
  "tree_hash",
  "K_hash",
  "Q_hash",
  "session_manifest_hash"
)
if (!file.exists(raw_path) || file.info(raw_path)$size <= 0L) {
  stop("Raw TSV is empty", call. = FALSE)
}
read_back <- utils::read.delim(
  raw_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
if (nrow(read_back) != expected_rows) {
  stop(
    "Raw TSV read-back row count mismatch: expected ",
    expected_rows,
    ", got ",
    nrow(read_back),
    call. = FALSE
  )
}
missing_columns <- setdiff(required_columns, names(read_back))
if (length(missing_columns)) {
  stop(
    "Raw TSV is missing columns: ",
    paste(missing_columns, collapse = ", "),
    call. = FALSE
  )
}
if (anyDuplicated(read_back$fit_key)) {
  stop("Raw TSV has duplicate immutable fit keys", call. = FALSE)
}
if (!all(read_back$attempted %in% TRUE)) {
  stop("Raw TSV lost attempted rows", call. = FALSE)
}
if (
  !identical(
    read_back$session_manifest_hash,
    rep(session_manifest_hash, nrow(read_back))
  )
) {
  stop("Raw TSV session-manifest hash mismatch", call. = FALSE)
}

message("wrote raw attempts: ", raw_path, " (", nrow(raw), " rows)")
message(
  "shard=",
  args$shard_index,
  "/",
  args$shard_count,
  "; frozen_full_manifest_rows=",
  full_expected_rows
)
message(
  "wrote seed manifest: ",
  seed_path,
  " (",
  nrow(selected_seeds),
  " DGP rows)"
)
message("wrote session manifest: ", session_path)
message("raw_sha256=", sha256_file(raw_path))
message("fit_success=", sum(raw$fit_success), "/", nrow(raw))
message("analysis_success=", sum(raw$analysis_success), "/", nrow(raw))
if (!args$mode %in% c("certification", "phylo_certification")) {
  message(
    "claim_boundary=preflight_or_diagnostic_only_not_certification_evidence"
  )
}
