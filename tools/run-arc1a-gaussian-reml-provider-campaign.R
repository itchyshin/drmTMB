#!/usr/bin/env Rscript

# Arc 1a: Gaussian mean-side spatial/animal/relmat REML campaign.
#
# The approved grid is seven provider-by-M cells crossed with two random-effect
# shapes. Recovery fits paired ML and REML estimates to the same 400 generated
# datasets per base cell. Profile coverage fits REML to 1,000 datasets per base
# cell and profiles every direct structured-SD target: one target for the
# intercept shape and two targets for the one-slope shape.

Sys.setenv(
  OMP_NUM_THREADS = "1",
  OPENBLAS_NUM_THREADS = "1",
  MKL_NUM_THREADS = "1",
  TMB_NTHREADS = "1"
)

`%||%` <- function(x, y) if (is.null(x)) y else x

args <- commandArgs(trailingOnly = TRUE)

arg_value <- function(name, default = NULL) {
  prefix <- paste0("--", name, "=")
  hit <- grep(paste0("^", prefix), args, value = TRUE)
  if (!length(hit)) return(default)
  sub(prefix, "", hit[[length(hit)]], fixed = TRUE)
}

arg_flag <- function(name, default = FALSE) {
  value <- arg_value(name, NULL)
  if (is.null(value)) return(default)
  tolower(trimws(value)) %in% c("1", "true", "yes", "y")
}

if (any(args %in% c("--help", "-h"))) {
  cat(paste(
    "Usage: Rscript tools/run-arc1a-gaussian-reml-provider-campaign.R [options]",
    "",
    "Required:",
    "  --phase=recovery|profile",
    "  --output-dir=PATH",
    "",
    "Options:",
    "  --n-rep=N                  Datasets per base cell (default: 400 recovery; 1000 profile).",
    "  --ncores=N                 Fork workers, capped at 90 and host cores (default: 1).",
    "  --overwrite=true|false     Replace this phase's existing artifacts (default: false; otherwise resume).",
    "  --profile-engine=endpoint  Required fixed profile engine (default: endpoint).",
    "  --profile-max-eval=N       Optional constrained evaluations per endpoint side; omit for no cap.",
    "",
    "Environment:",
    "  ARC1A_CHECKPOINT_SIZE      Dataset tasks per atomic checkpoint (default: max(25, 4*ncores)).",
    sep = "\n"
  ))
  quit(status = 0L)
}

phase <- arg_value("phase", NULL)
if (is.null(phase) || !phase %in% c("recovery", "profile")) {
  stop("`--phase` must be `recovery` or `profile`.", call. = FALSE)
}

output_dir_arg <- arg_value("output-dir", NULL)
if (is.null(output_dir_arg) || !nzchar(output_dir_arg)) {
  stop("`--output-dir` is required.", call. = FALSE)
}
output_dir <- normalizePath(path.expand(output_dir_arg), mustWork = FALSE)

default_n_rep <- if (identical(phase, "recovery")) 400L else 1000L
n_rep <- suppressWarnings(as.integer(arg_value("n-rep", as.character(default_n_rep))))
if (length(n_rep) != 1L || is.na(n_rep) || n_rep < 1L) {
  stop("`--n-rep` must be a positive integer.", call. = FALSE)
}

ncores_requested <- suppressWarnings(as.integer(arg_value("ncores", "1")))
if (length(ncores_requested) != 1L || is.na(ncores_requested) || ncores_requested < 1L) {
  stop("`--ncores` must be a positive integer.", call. = FALSE)
}
if (ncores_requested > 90L) {
  stop("`--ncores` must not exceed the approved Totoro hard cap of 90.", call. = FALSE)
}
ncores_detected <- suppressWarnings(parallel::detectCores(logical = TRUE))
if (length(ncores_detected) != 1L || is.na(ncores_detected)) ncores_detected <- 1L
ncores_actual <- min(ncores_requested, ncores_detected)

overwrite <- arg_flag("overwrite", FALSE)
profile_engine <- arg_value("profile-engine", "endpoint")
if (!identical(profile_engine, "endpoint")) {
  stop(
    "Arc 1a pins `--profile-engine=endpoint`; fallback or mixed profile engines are forbidden.",
    call. = FALSE
  )
}
profile_max_eval_arg <- arg_value("profile-max-eval", NULL)
profile_max_eval <- if (is.null(profile_max_eval_arg) || !nzchar(profile_max_eval_arg)) {
  NULL
} else {
  value <- suppressWarnings(as.integer(profile_max_eval_arg))
  if (length(value) != 1L || is.na(value) || value < 1L) {
    stop("`--profile-max-eval` must be a positive integer when supplied.", call. = FALSE)
  }
  value
}

checkpoint_size <- suppressWarnings(as.integer(Sys.getenv(
  "ARC1A_CHECKPOINT_SIZE",
  as.character(max(25L, 4L * ncores_actual))
)))
if (length(checkpoint_size) != 1L || is.na(checkpoint_size) || checkpoint_size < 1L) {
  stop("ARC1A_CHECKPOINT_SIZE must be a positive integer.", call. = FALSE)
}

script_file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_file <- if (length(script_file_arg)) {
  normalizePath(sub("^--file=", "", script_file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath("tools/run-arc1a-gaussian-reml-provider-campaign.R", mustWork = TRUE)
}
repo_root <- normalizePath(file.path(dirname(script_file), ".."), mustWork = TRUE)
if (!file.exists(file.path(repo_root, "DESCRIPTION"))) {
  stop("Could not resolve the drmTMB repository root from the campaign script.", call. = FALSE)
}

if (!requireNamespace("pkgload", quietly = TRUE)) {
  stop("pkgload is required to compile and load drmTMB from this checkout.", call. = FALSE)
}
suppressWarnings(suppressMessages(pkgload::load_all(repo_root, quiet = TRUE)))

BASE_SEED <- 20260714L
N_EACH <- 20L
X_VALUES <- seq(-1, 1, length.out = N_EACH)
TRUTH <- list(beta0 = 0.4, beta_x = 0.25, sigma = 0.5, tau0 = 0.5, tau_x = 0.38)

provider_cells <- rbind(
  data.frame(provider = "spatial", M = c(8L, 16L, 32L), stringsAsFactors = FALSE),
  data.frame(provider = "relmat", M = c(8L, 16L, 32L), stringsAsFactors = FALSE),
  data.frame(provider = "animal", M = 8L, stringsAsFactors = FALSE)
)
cells <- do.call(rbind, lapply(seq_len(nrow(provider_cells)), function(i) {
  data.frame(
    provider = provider_cells$provider[[i]],
    M = provider_cells$M[[i]],
    shape = c("intercept", "one_slope"),
    stringsAsFactors = FALSE
  )
}))
row.names(cells) <- NULL
cells$cell_index <- seq_len(nrow(cells))
cells$base_cell_id <- sprintf(
  "arc1a_%s_m%02d_%s",
  cells$provider,
  cells$M,
  cells$shape
)
cells$n_each <- N_EACH
cells$beta0 <- TRUTH$beta0
cells$beta_x <- TRUTH$beta_x
cells$sigma <- TRUTH$sigma
cells$tau0 <- TRUTH$tau0
cells$tau_x <- ifelse(cells$shape == "one_slope", TRUTH$tau_x, NA_real_)
cells$n_targets <- ifelse(cells$shape == "intercept", 1L, 2L)
cells$seed_formula <- paste(
  "set.seed(20260714); sample.int(.Machine$integer.max, 19600, replace=FALSE);",
  "recovery indices 1:5600 then profile indices 5601:19600 in stable cell/replicate order"
)

group_name <- function(provider) if (identical(provider, "spatial")) "site" else "id"

target_table <- function(cell) {
  group <- group_name(cell$provider[[1L]])
  provider <- cell$provider[[1L]]
  out <- data.frame(
    target_role = "intercept",
    target_parameter = sprintf("sd:mu:%s(1 | %s)", provider, group),
    target_term = sprintf("%s(1 | %s)", provider, group),
    truth = TRUTH$tau0,
    stringsAsFactors = FALSE
  )
  if (identical(cell$shape[[1L]], "one_slope")) {
    out <- rbind(out, data.frame(
      target_role = "slope_x",
      target_parameter = sprintf("sd:mu:%s(0 + x | %s)", provider, group),
      target_term = sprintf("%s(0 + x | %s)", provider, group),
      truth = TRUTH$tau_x,
      stringsAsFactors = FALSE
    ))
  }
  out
}

cells$target_parameters <- vapply(seq_len(nrow(cells)), function(i) {
  paste(target_table(cells[i, , drop = FALSE])$target_parameter, collapse = ";")
}, character(1L))

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- NA_character_
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

write_tsv <- function(x, path) {
  character_cols <- vapply(x, is.character, logical(1L))
  x[character_cols] <- lapply(x[character_cols], clean_text)
  utils::write.table(
    x,
    path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA"
  )
}

atomic_write_tsv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(pattern = paste0(basename(path), "."), tmpdir = dirname(path))
  on.exit(unlink(temporary), add = TRUE)
  write_tsv(x, temporary)
  if (!file.rename(temporary, path)) {
    stop("Could not atomically install artifact: ", path, call. = FALSE)
  }
  invisible(path)
}

read_tsv <- function(path) {
  utils::read.delim(
    path,
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE,
    na.strings = "NA"
  )
}

git_value <- function(args) {
  out <- tryCatch(
    system2("git", c("-C", shQuote(repo_root), args), stdout = TRUE, stderr = FALSE),
    error = function(e) character()
  )
  if (!length(out)) NA_character_ else paste(out, collapse = "\n")
}

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
raw_path <- file.path(output_dir, paste0(phase, "-raw.tsv"))
seed_manifest_path <- file.path(output_dir, paste0(phase, "-seed-manifest.tsv"))
seed_pool_path <- file.path(output_dir, "arc1a-seed-pool.tsv")
run_manifest_path <- file.path(output_dir, paste0(phase, "-run-manifest.tsv"))
cell_manifest_path <- file.path(output_dir, "arc1a-cells.tsv")
log_path <- file.path(output_dir, paste0(phase, "-campaign.log"))

phase_outputs <- c(
  raw_path,
  seed_manifest_path,
  run_manifest_path,
  log_path,
  file.path(output_dir, paste0(phase, "-summary.tsv")),
  file.path(output_dir, paste0(phase, "-fit-summary.tsv"))
)
if (identical(phase, "recovery")) {
  phase_outputs <- c(phase_outputs, file.path(output_dir, "recovery-paired-summary.tsv"))
}
if (overwrite) unlink(phase_outputs, recursive = FALSE, force = TRUE)

atomic_write_tsv(cells, cell_manifest_path)

# Freeze all 19,600 dataset seeds once, independent of a smoke's reduced n_rep.
# Stable order is recovery cell-major/replicate-minor, then profile likewise.
set.seed(BASE_SEED)
frozen_seeds <- sample.int(.Machine$integer.max, 19600L, replace = FALSE)
full_phase_manifest <- function(phase_name, phase_n_rep, pool_offset) {
  out <- do.call(rbind, lapply(seq_len(nrow(cells)), function(i) {
    data.frame(
      phase = phase_name,
      base_cell_id = cells$base_cell_id[[i]],
      cell_index = cells$cell_index[[i]],
      provider = cells$provider[[i]],
      M = cells$M[[i]],
      shape = cells$shape[[i]],
      replicate_index = seq_len(phase_n_rep),
      n_targets = cells$n_targets[[i]],
      stringsAsFactors = FALSE
    )
  }))
  row.names(out) <- NULL
  out$seed_pool_index <- pool_offset + seq_len(nrow(out))
  out$seed <- frozen_seeds[out$seed_pool_index]
  out$seed_pool_formula <- cells$seed_formula[[1L]]
  out$full_phase_n_rep <- phase_n_rep
  out$task_id <- paste(out$base_cell_id, out$replicate_index, sep = "::")
  out
}
recovery_seed_pool <- full_phase_manifest("recovery", 400L, 0L)
profile_seed_pool <- full_phase_manifest("profile", 1000L, nrow(recovery_seed_pool))
seed_pool <- rbind(recovery_seed_pool, profile_seed_pool)
stopifnot(
  nrow(seed_pool) == 19600L,
  !anyDuplicated(seed_pool$seed),
  identical(seed_pool$seed_pool_index, seq_len(19600L))
)
atomic_write_tsv(seed_pool, seed_pool_path)

phase_seed_pool <- if (identical(phase, "recovery")) recovery_seed_pool else profile_seed_pool
if (n_rep > unique(phase_seed_pool$full_phase_n_rep)) {
  stop(
    "`--n-rep` exceeds the frozen phase contract (400 recovery; 1000 profile).",
    call. = FALSE
  )
}
seed_manifest <- phase_seed_pool[
  phase_seed_pool$replicate_index <= n_rep,
  ,
  drop = FALSE
]
seed_manifest$execution_status <- "scheduled"
seed_manifest$task_id <- paste(seed_manifest$base_cell_id, seed_manifest$replicate_index, sep = "::")
atomic_write_tsv(seed_manifest, seed_manifest_path)

run_manifest <- data.frame(
  key = c(
    "generated_at_utc", "phase", "command", "host", "repo_root", "git_sha",
    "git_dirty", "package_version", "runner_path", "runner_md5",
    "summarizer_path", "summarizer_md5", "n_rep", "n_base_cells",
    "expected_unique_fits", "expected_target_rows", "base_seed", "seed_formula",
    "seed_pool_size", "seed_pool_path",
    "n_each", "x_values", "beta0", "beta_x", "sigma", "tau0", "tau_x",
    "ncores_requested", "ncores_detected", "ncores_actual", "checkpoint_size",
    "profile_engine", "profile_max_eval", "OMP_NUM_THREADS",
    "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS", "TMB_NTHREADS", "raw_path"
  ),
  value = c(
    format(Sys.time(), tz = "UTC", usetz = TRUE), phase,
    paste(commandArgs(FALSE), collapse = " "), unname(Sys.info()[["nodename"]]),
    repo_root, git_value(c("rev-parse", "HEAD")),
    !is.na(git_value(c("status", "--porcelain"))),
    as.character(utils::packageVersion("drmTMB")), script_file,
    unname(tools::md5sum(script_file)),
    file.path(repo_root, "tools", "summarize-arc1a-gaussian-reml-provider-campaign.R"),
    if (file.exists(file.path(repo_root, "tools", "summarize-arc1a-gaussian-reml-provider-campaign.R"))) {
      unname(tools::md5sum(file.path(repo_root, "tools", "summarize-arc1a-gaussian-reml-provider-campaign.R")))
    } else NA_character_,
    n_rep, nrow(cells),
    if (identical(phase, "recovery")) nrow(cells) * n_rep * 2L else nrow(cells) * n_rep,
    sum(cells$n_targets) * n_rep * if (identical(phase, "recovery")) 2L else 1L,
    BASE_SEED, unique(cells$seed_formula), nrow(seed_pool), seed_pool_path,
    N_EACH, paste(signif(X_VALUES, 8), collapse = ","),
    TRUTH$beta0, TRUTH$beta_x, TRUTH$sigma, TRUTH$tau0, TRUTH$tau_x,
    ncores_requested, ncores_detected, ncores_actual, checkpoint_size,
    if (identical(phase, "profile")) profile_engine else NA_character_,
    profile_max_eval %||% NA_integer_,
    Sys.getenv("OMP_NUM_THREADS"), Sys.getenv("OPENBLAS_NUM_THREADS"),
    Sys.getenv("MKL_NUM_THREADS"), Sys.getenv("TMB_NTHREADS"), raw_path
  ),
  stringsAsFactors = FALSE
)
atomic_write_tsv(run_manifest, run_manifest_path)

append_log <- function(...) {
  text <- paste0(format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"), " ", paste0(..., collapse = ""))
  cat(text, "\n", file = log_path, append = TRUE)
  message(text)
}

spatial_K <- function(M) {
  labels <- paste0("site_", seq_len(M))
  theta <- seq(0, 1.5 * pi, length.out = M)
  coords <- data.frame(
    x = cos(theta) + seq_len(M) / (3 * M),
    y = sin(theta)
  )
  row.names(coords) <- labels
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords,
    site = labels,
    group = "site"
  )
  list(labels = labels, coords = coords, K = solve(as.matrix(precision$precision)))
}

relmat_K <- function(M) {
  labels <- paste0("id", seq_len(M))
  K <- outer(seq_len(M), seq_len(M), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(labels, labels)
  list(labels = labels, K = K)
}

animal_K <- function(M) {
  if (!identical(as.integer(M), 8L)) {
    stop("The approved animal constructor is fixed at M = 8.", call. = FALSE)
  }
  pedigree <- data.frame(
    id = paste0("id", 1:8),
    dam = c(NA, NA, NA, NA, "id1", "id3", "id5", "id1"),
    sire = c(NA, NA, NA, NA, "id2", "id4", "id6", "id3"),
    stringsAsFactors = FALSE
  )
  K <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  list(labels = rownames(K), pedigree = pedigree, K = K)
}

# Constructors are deterministic within a base cell; precompute them once.
cell_objects <- lapply(seq_len(nrow(cells)), function(i) {
  switch(
    cells$provider[[i]],
    spatial = spatial_K(cells$M[[i]]),
    relmat = relmat_K(cells$M[[i]]),
    animal = animal_K(cells$M[[i]])
  )
})
names(cell_objects) <- cells$base_cell_id

scaled_effects <- function(K, sds) {
  z <- replicate(length(sds), as.vector(t(chol(K)) %*% stats::rnorm(nrow(K))))
  out <- sweep(z, 2L, sds, `*`)
  colnames(out) <- names(sds)
  out
}

simulate_cell <- function(cell, seed) {
  set.seed(seed)
  object <- cell_objects[[cell$base_cell_id[[1L]]]]
  sds <- c(intercept = TRUTH$tau0)
  if (identical(cell$shape[[1L]], "one_slope")) sds <- c(sds, slope_x = TRUTH$tau_x)
  effects <- scaled_effects(object$K, sds)
  row.names(effects) <- object$labels
  group <- rep(object$labels, each = N_EACH)
  x <- rep(X_VALUES, times = length(object$labels))
  mu <- TRUTH$beta0 + TRUTH$beta_x * x + effects[group, "intercept"]
  if (identical(cell$shape[[1L]], "one_slope")) {
    mu <- mu + effects[group, "slope_x"] * x
  }
  dat <- data.frame(y = stats::rnorm(length(mu), mu, TRUTH$sigma), x = x)
  dat[[group_name(cell$provider[[1L]])]] <- group
  list(data = dat, object = object)
}

build_formula <- function(cell, sim) {
  provider <- cell$provider[[1L]]
  random_term <- if (identical(cell$shape[[1L]], "intercept")) "1" else "1 + x"
  if (identical(provider, "spatial")) {
    coords <- sim$object$coords
    if (identical(random_term, "1")) {
      bf(y ~ x + spatial(1 | site, coords = coords), sigma ~ 1)
    } else {
      bf(y ~ x + spatial(1 + x | site, coords = coords), sigma ~ 1)
    }
  } else if (identical(provider, "relmat")) {
    K <- sim$object$K
    if (identical(random_term, "1")) {
      bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1)
    } else {
      bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1)
    }
  } else {
    A <- sim$object$K
    if (identical(random_term, "1")) {
      bf(y ~ x + animal(1 | id, A = A), sigma ~ 1)
    } else {
      bf(y ~ x + animal(1 + x | id, A = A), sigma ~ 1)
    }
  }
}

fit_cell <- function(cell, sim, estimator) {
  warnings <- character()
  started <- proc.time()[["elapsed"]]
  fit_error <- NA_character_
  fit <- tryCatch(
    withCallingHandlers(
      drmTMB(
        build_formula(cell, sim),
        family = gaussian(),
        data = sim$data,
        REML = identical(estimator, "REML"),
        control = drm_control(
          keep_tmb_object = TRUE,
          optimizer = list(eval.max = 1400L, iter.max = 1400L)
        )
      ),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) {
      fit_error <<- conditionMessage(e)
      NULL
    }
  )
  list(
    fit = fit,
    fit_error = fit_error,
    warnings = unique(warnings),
    elapsed_sec = proc.time()[["elapsed"]] - started
  )
}

fit_status <- function(fit_result) {
  if (is.null(fit_result$fit)) return("fit_error")
  if (!isTRUE(fit_result$fit$opt$convergence == 0L)) return("nonconverged")
  "converged"
}

fit_metadata <- function(fit_result) {
  fit <- fit_result$fit
  if (is.null(fit)) {
    return(list(
      convergence = NA_integer_, pdHess = NA, objective = NA_real_,
      beta0_hat = NA_real_, beta_x_hat = NA_real_, sigma_hat = NA_real_,
      max_abs_gradient_fixed = NA_real_
    ))
  }
  beta <- tryCatch(as.numeric(fit$par$mu), error = function(e) numeric())
  sigma_hat <- tryCatch(exp(as.numeric(fit$par$sigma[[1L]])), error = function(e) NA_real_)
  gradient <- tryCatch(as.numeric(fit$sdr$gradient.fixed), error = function(e) numeric())
  if (!length(gradient) || any(!is.finite(gradient))) {
    gradient <- tryCatch(as.numeric(fit$obj$gr(fit$opt$par)), error = function(e) numeric())
  }
  max_abs_gradient_fixed <- if (length(gradient) && all(is.finite(gradient))) {
    max(abs(gradient))
  } else {
    NA_real_
  }
  list(
    convergence = suppressWarnings(as.integer(fit$opt$convergence[[1L]])),
    pdHess = isTRUE(fit$sdr$pdHess),
    objective = suppressWarnings(as.numeric(fit$opt$objective[[1L]])),
    beta0_hat = if (length(beta) >= 1L) beta[[1L]] else NA_real_,
    beta_x_hat = if (length(beta) >= 2L) beta[[2L]] else NA_real_,
    sigma_hat = sigma_hat,
    max_abs_gradient_fixed = max_abs_gradient_fixed
  )
}

target_inventory <- function(fit, expected) {
  if (is.null(fit)) return(NULL)
  inventory <- tryCatch(profile_targets(fit), error = function(e) NULL)
  if (is.null(inventory)) return(NULL)
  inventory[match(expected$target_parameter, inventory$parm), , drop = FALSE]
}

base_target_row <- function(task, cell, estimator, target, fit_result, metadata) {
  fit_id <- paste(task$task_id[[1L]], estimator, sep = "::")
  out <- data.frame(
    phase = phase,
    task_id = task$task_id[[1L]],
    fit_id = fit_id,
    base_cell_id = cell$base_cell_id[[1L]],
    cell_index = cell$cell_index[[1L]],
    provider = cell$provider[[1L]],
    M = cell$M[[1L]],
    shape = cell$shape[[1L]],
    replicate_index = task$replicate_index[[1L]],
    seed_pool_index = task$seed_pool_index[[1L]],
    seed = task$seed[[1L]],
    estimator = estimator,
    target_role = target$target_role[[1L]],
    target_parameter = target$target_parameter[[1L]],
    target_term = target$target_term[[1L]],
    truth = target$truth[[1L]],
    beta0_truth = TRUTH$beta0,
    beta_x_truth = TRUTH$beta_x,
    sigma_truth = TRUTH$sigma,
    n_each = N_EACH,
    nobs = cell$M[[1L]] * N_EACH,
    fit_status = fit_status(fit_result),
    fit_error = fit_result$fit_error,
    convergence = metadata$convergence,
    pdHess = metadata$pdHess,
    objective = metadata$objective,
    beta0_hat = metadata$beta0_hat,
    beta_x_hat = metadata$beta_x_hat,
    sigma_hat = metadata$sigma_hat,
    max_abs_gradient_fixed = metadata$max_abs_gradient_fixed,
    fit_elapsed_sec = fit_result$elapsed_sec,
    fit_warning_count = length(fit_result$warnings),
    fit_warnings = paste(fit_result$warnings, collapse = " | "),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  if (anyDuplicated(names(out))) {
    stop("Internal error: duplicate raw-output column names.", call. = FALSE)
  }
  out
}

recovery_rows <- function(task, cell, sim, estimator) {
  expected <- target_table(cell)
  fit_result <- fit_cell(cell, sim, estimator)
  metadata <- fit_metadata(fit_result)
  inventory <- target_inventory(fit_result$fit, expected)
  rows <- lapply(seq_len(nrow(expected)), function(i) {
    row <- base_target_row(task, cell, estimator, expected[i, , drop = FALSE], fit_result, metadata)
    inventory_ok <- !is.null(inventory) && nrow(inventory) >= i &&
      !is.na(inventory$parm[[i]]) &&
      identical(inventory$parm[[i]], expected$target_parameter[[i]])
    estimate <- if (inventory_ok) suppressWarnings(as.numeric(inventory$estimate[[i]])) else NA_real_
    row$target_inventory_ok <- inventory_ok
    row$target_type <- if (inventory_ok) as.character(inventory$target_type[[i]]) else NA_character_
    row$profile_ready <- if (inventory_ok) isTRUE(inventory$profile_ready[[i]]) else FALSE
    row$tmb_parameter <- if (inventory_ok) as.character(inventory$tmb_parameter[[i]]) else NA_character_
    row$estimate <- estimate
    row$error <- estimate - expected$truth[[i]]
    row$squared_error <- (estimate - expected$truth[[i]])^2
    row
  })
  do.call(rbind, rows)
}

profile_rows <- function(task, cell, sim) {
  estimator <- "REML"
  expected <- target_table(cell)
  fit_result <- fit_cell(cell, sim, estimator)
  metadata <- fit_metadata(fit_result)
  inventory <- target_inventory(fit_result$fit, expected)

  rows <- lapply(seq_len(nrow(expected)), function(i) {
    target <- expected[i, , drop = FALSE]
    row <- base_target_row(task, cell, estimator, target, fit_result, metadata)
    inventory_ok <- !is.null(inventory) && nrow(inventory) >= i &&
      !is.na(inventory$parm[[i]]) &&
      identical(inventory$parm[[i]], target$target_parameter[[1L]])
    row$target_inventory_ok <- inventory_ok
    row$target_type <- if (inventory_ok) as.character(inventory$target_type[[i]]) else NA_character_
    row$profile_ready <- if (inventory_ok) isTRUE(inventory$profile_ready[[i]]) else FALSE
    row$tmb_parameter <- if (inventory_ok) as.character(inventory$tmb_parameter[[i]]) else NA_character_
    row$estimate <- if (inventory_ok) suppressWarnings(as.numeric(inventory$estimate[[i]])) else NA_real_
    row$profile_attempted <- FALSE
    row$profile_engine <- profile_engine
    row$profile_conf_status <- NA_character_
    row$profile_boundary <- NA
    row$profile_message <- NA_character_
    row$profile_error <- NA_character_
    row$profile_lower <- NA_real_
    row$profile_upper <- NA_real_
    row$profile_valid <- FALSE
    row$profile_two_sided_finite <- FALSE
    row$profile_finite <- FALSE
    row$profile_covered <- FALSE
    row$truth_below_interval <- NA
    row$truth_above_interval <- NA
    row$profile_width <- NA_real_
    row$profile_elapsed_sec <- NA_real_
    row$profile_warning_count <- 0L
    row$profile_warnings <- NA_character_

    if (!identical(row$fit_status[[1L]], "converged")) return(row)
    row$profile_attempted <- TRUE
    if (!inventory_ok || !identical(row$target_type[[1L]], "direct") ||
        !isTRUE(row$profile_ready[[1L]])) {
      row$profile_conf_status <- "profile_failed"
      row$profile_message <- "expected direct profile-ready target was unavailable"
      return(row)
    }

    profile_warnings <- character()
    profile_error <- NA_character_
    started <- proc.time()[["elapsed"]]
    profile_args <- list(
      object = fit_result$fit,
      parm = target$target_parameter[[1L]],
      method = "profile",
      level = 0.95,
      profile_engine = "endpoint",
      parallel = "none"
    )
    if (!is.null(profile_max_eval)) profile_args$profile_endpoint_max_eval <- profile_max_eval
    ci <- tryCatch(
      withCallingHandlers(
        do.call(stats::confint, profile_args),
        warning = function(w) {
          profile_warnings <<- c(profile_warnings, conditionMessage(w))
          invokeRestart("muffleWarning")
        }
      ),
      error = function(e) {
        profile_error <<- conditionMessage(e)
        NULL
      }
    )
    row$profile_elapsed_sec <- proc.time()[["elapsed"]] - started
    row$profile_warning_count <- length(unique(profile_warnings))
    row$profile_warnings <- paste(unique(profile_warnings), collapse = " | ")
    row$profile_error <- profile_error
    if (is.null(ci) || !nrow(ci)) {
      row$profile_conf_status <- "profile_failed"
      row$profile_message <- if (is.na(profile_error)) "profile returned no rows" else profile_error
      return(row)
    }
    if (!identical(as.character(ci$profile.engine[[1L]]), "endpoint")) {
      row$profile_conf_status <- "profile_failed"
      row$profile_message <- "unexpected non-endpoint profile engine"
      return(row)
    }
    row$profile_conf_status <- as.character(ci$conf.status[[1L]])
    row$profile_boundary <- as.logical(ci$profile.boundary[[1L]])
    row$profile_message <- as.character(ci$profile.message[[1L]])
    row$profile_lower <- suppressWarnings(as.numeric(ci$lower[[1L]]))
    row$profile_upper <- suppressWarnings(as.numeric(ci$upper[[1L]]))
    status_allows_interval <- row$profile_conf_status[[1L]] %in%
      c("profile", "profile_one_sided")
    endpoints_present <- !is.na(row$profile_lower[[1L]]) &&
      !is.na(row$profile_upper[[1L]]) &&
      row$profile_lower[[1L]] <= row$profile_upper[[1L]]
    at_least_one_finite <- is.finite(row$profile_lower[[1L]]) ||
      is.finite(row$profile_upper[[1L]])
    row$profile_valid <- status_allows_interval && endpoints_present && at_least_one_finite
    row$profile_two_sided_finite <- row$profile_valid[[1L]] &&
      is.finite(row$profile_lower[[1L]]) && is.finite(row$profile_upper[[1L]])
    row$profile_finite <- row$profile_two_sided_finite[[1L]]
    if (row$profile_valid[[1L]]) {
      row$profile_covered <- target$truth[[1L]] >= row$profile_lower[[1L]] &&
        target$truth[[1L]] <= row$profile_upper[[1L]]
      row$truth_below_interval <- target$truth[[1L]] < row$profile_lower[[1L]]
      row$truth_above_interval <- target$truth[[1L]] > row$profile_upper[[1L]]
      row$profile_width <- if (row$profile_two_sided_finite[[1L]]) {
        row$profile_upper[[1L]] - row$profile_lower[[1L]]
      } else {
        Inf
      }
    }
    row
  })
  do.call(rbind, rows)
}

task_failure_rows <- function(task, message) {
  cell <- cells[cells$base_cell_id == task$base_cell_id[[1L]], , drop = FALSE]
  expected <- target_table(cell)
  estimators <- if (identical(phase, "recovery")) c("ML", "REML") else "REML"
  rows <- list()
  k <- 1L
  for (estimator in estimators) {
    fit_result <- list(fit = NULL, fit_error = message, warnings = character(), elapsed_sec = NA_real_)
    metadata <- fit_metadata(fit_result)
    for (i in seq_len(nrow(expected))) {
      row <- base_target_row(task, cell, estimator, expected[i, , drop = FALSE], fit_result, metadata)
      row$target_inventory_ok <- FALSE
      row$target_type <- NA_character_
      row$profile_ready <- FALSE
      row$tmb_parameter <- NA_character_
      row$estimate <- NA_real_
      if (identical(phase, "recovery")) {
        row$error <- NA_real_
        row$squared_error <- NA_real_
      } else {
        row$profile_attempted <- FALSE
        row$profile_engine <- profile_engine
        row$profile_conf_status <- NA_character_
        row$profile_boundary <- NA
        row$profile_message <- NA_character_
        row$profile_error <- NA_character_
        row$profile_lower <- NA_real_
        row$profile_upper <- NA_real_
        row$profile_valid <- FALSE
        row$profile_two_sided_finite <- FALSE
        row$profile_finite <- FALSE
        row$profile_covered <- FALSE
        row$truth_below_interval <- NA
        row$truth_above_interval <- NA
        row$profile_width <- NA_real_
        row$profile_elapsed_sec <- NA_real_
        row$profile_warning_count <- 0L
        row$profile_warnings <- NA_character_
      }
      rows[[k]] <- row
      k <- k + 1L
    }
  }
  do.call(rbind, rows)
}

run_task <- function(task) {
  tryCatch({
    cell <- cells[cells$base_cell_id == task$base_cell_id[[1L]], , drop = FALSE]
    sim <- simulate_cell(cell, task$seed[[1L]])
    if (identical(phase, "recovery")) {
      rbind(
        recovery_rows(task, cell, sim, "ML"),
        recovery_rows(task, cell, sim, "REML")
      )
    } else {
      profile_rows(task, cell, sim)
    }
  }, error = function(e) task_failure_rows(task, conditionMessage(e)))
}

raw <- if (file.exists(raw_path) && !overwrite) read_tsv(raw_path) else NULL
expected_rows_by_task <- setNames(
  seed_manifest$n_targets * if (identical(phase, "recovery")) 2L else 1L,
  seed_manifest$task_id
)
completed_tasks <- character()
if (!is.null(raw) && nrow(raw)) {
  task_counts <- table(raw$task_id)
  completed_tasks <- names(task_counts)[
    task_counts == expected_rows_by_task[names(task_counts)]
  ]
  # Remove any partial task before replaying it.
  raw <- raw[raw$task_id %in% completed_tasks, , drop = FALSE]
  if (anyDuplicated(paste(raw$fit_id, raw$target_parameter, sep = "::"))) {
    stop("Existing raw artifact contains duplicate fit-target keys.", call. = FALSE)
  }
}

pending <- seed_manifest[!seed_manifest$task_id %in% completed_tasks, , drop = FALSE]
append_log(
  "phase=", phase,
  " base_cells=", nrow(cells),
  " n_rep=", n_rep,
  " pending_tasks=", nrow(pending),
  " resumed_tasks=", length(completed_tasks),
  " ncores=", ncores_actual
)

if (nrow(pending)) {
  chunk_starts <- seq.int(1L, nrow(pending), by = checkpoint_size)
  for (chunk_index in seq_along(chunk_starts)) {
    lo <- chunk_starts[[chunk_index]]
    hi <- min(nrow(pending), lo + checkpoint_size - 1L)
    chunk <- split(pending[lo:hi, , drop = FALSE], seq_len(hi - lo + 1L))
    result <- if (.Platform$OS.type != "windows" && ncores_actual > 1L) {
      parallel::mclapply(chunk, run_task, mc.cores = ncores_actual, mc.preschedule = FALSE)
    } else {
      lapply(chunk, run_task)
    }
    new_rows <- do.call(rbind, result)
    raw <- if (is.null(raw) || !nrow(raw)) new_rows else rbind(raw, new_rows)
    row.names(raw) <- NULL
    raw <- raw[order(raw$cell_index, raw$replicate_index, raw$estimator, raw$target_role), , drop = FALSE]
    atomic_write_tsv(raw, raw_path)
    append_log(
      "checkpoint=", chunk_index, "/", length(chunk_starts),
      " completed_tasks=", hi, "/", nrow(pending),
      " raw_rows=", nrow(raw)
    )
  }
}

if (is.null(raw)) {
  stop("Campaign produced no raw rows.", call. = FALSE)
}

final_counts <- table(raw$task_id)
if (length(final_counts) != nrow(seed_manifest) ||
    any(final_counts != expected_rows_by_task[names(final_counts)])) {
  stop("Raw artifact is incomplete after campaign execution.", call. = FALSE)
}
if (anyDuplicated(paste(raw$fit_id, raw$target_parameter, sep = "::"))) {
  stop("Raw artifact contains duplicate fit-target keys after execution.", call. = FALSE)
}

seed_manifest$execution_status <- "completed"
atomic_write_tsv(seed_manifest, seed_manifest_path)

summarizer_path <- file.path(repo_root, "tools", "summarize-arc1a-gaussian-reml-provider-campaign.R")
if (!file.exists(summarizer_path)) {
  stop("Campaign summarizer is missing: ", summarizer_path, call. = FALSE)
}
summarizer_env <- new.env(parent = globalenv())
sys.source(summarizer_path, envir = summarizer_env)
summarizer_env$summarize_arc1a_phase(phase = phase, output_dir = output_dir)

append_log(
  "DONE phase=", phase,
  " unique_fits=", length(unique(raw$fit_id)),
  " target_rows=", nrow(raw),
  " raw=", raw_path
)
