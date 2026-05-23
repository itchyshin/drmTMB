#!/usr/bin/env Rscript

# Optional non-CRAN benchmark for large univariate Gaussian phylogenetic
# location fits. Run from the package root, for example:
# Rscript bench/large-phylo-location.R --rows 100000 --species 1000

load_drmTMB <- function() {
  if (
    file.exists("DESCRIPTION") &&
      dir.exists("R") &&
      requireNamespace("devtools", quietly = TRUE)
  ) {
    devtools::load_all(quiet = TRUE)
    return(invisible(TRUE))
  }
  if (requireNamespace("drmTMB", quietly = TRUE)) {
    suppressPackageStartupMessages(library(drmTMB))
    return(invisible(TRUE))
  }
  stop(
    "Install drmTMB or run this script from the package root with devtools available.",
    call. = FALSE
  )
}

parse_args <- function(args = commandArgs(trailingOnly = TRUE)) {
  defaults <- list(
    rows = 5000L,
    species = 128L,
    seed = 20260510L,
    structured = "phylo",
    tree = "balanced",
    factor_heavy = FALSE,
    sigma_x = FALSE,
    sparse_fixed = FALSE,
    aggregate_gaussian = FALSE,
    aggregation_cells = 80L,
    cell_random_effect = FALSE,
    cell_random_effect_cells = 80L,
    memory_light = TRUE,
    eval_max = 200L,
    iter_max = 200L,
    output = ""
  )
  if (any(args %in% c("-h", "--help"))) {
    print_usage()
    quit(save = "no", status = 0)
  }
  if (length(args) == 0L) {
    return(defaults)
  }
  i <- 1L
  while (i <= length(args)) {
    key <- args[[i]]
    value <- NULL
    if (grepl("^--[^=]+=", key)) {
      parts <- strsplit(sub("^--", "", key), "=", fixed = TRUE)[[1L]]
      key <- parts[[1L]]
      value <- parts[[2L]]
    } else {
      key <- sub("^--", "", key)
      i <- i + 1L
      if (i > length(args)) {
        stop("Missing value for --", key, call. = FALSE)
      }
      value <- args[[i]]
    }
    key <- gsub("-", "_", key, fixed = TRUE)
    if (!key %in% names(defaults)) {
      stop("Unknown argument --", key, call. = FALSE)
    }
    defaults[[key]] <- cast_arg(value, defaults[[key]], key)
    i <- i + 1L
  }
  defaults
}

cast_arg <- function(value, template, key) {
  if (is.logical(template)) {
    value <- tolower(value)
    if (!value %in% c("true", "false", "1", "0", "yes", "no")) {
      stop("--", key, " must be true or false.", call. = FALSE)
    }
    return(value %in% c("true", "1", "yes"))
  }
  if (is.integer(template)) {
    out <- suppressWarnings(as.integer(value))
    if (is.na(out) || out <= 0L) {
      stop("--", key, " must be a positive integer.", call. = FALSE)
    }
    return(out)
  }
  value
}

print_usage <- function() {
  cat(
    "Usage: Rscript bench/large-phylo-location.R [options]\n\n",
    "Options:\n",
    "  --rows N              Number of observation rows; default 5000\n",
    "  --species N           Number of species; default 128\n",
    "  --seed N              Random seed; default 20260510\n",
    "  --structured phylo|none  Structured effect path; default phylo\n",
    "  --tree balanced|star  Synthetic ultrametric tree shape; default balanced\n",
    "  --factor-heavy bool   Add a 40-level habitat factor; default false\n",
    "  --sigma-x bool        Fit sigma ~ x1 instead of sigma ~ 1; default false\n",
    "  --sparse-fixed bool   Use sparse Gaussian mu fixed effects; default false\n",
    "  --aggregate-gaussian bool  Use Gaussian sufficient-statistic row aggregation; default false\n",
    "  --aggregation-cells N Number of repeated fixed-effect cells when aggregating; default 80\n",
    "  --cell-random-effect bool  Add a location random intercept (1 | cell_id); default false\n",
    "  --cell-random-effect-cells N Number of cell random-effect levels; default 80\n",
    "  --memory-light bool   Use all fitted-object storage controls; default true\n",
    "  --eval-max N          nlminb eval.max; default 200\n",
    "  --iter-max N          nlminb iter.max; default 200\n",
    "  --output PATH         Optional CSV output path\n",
    sep = ""
  )
}

balanced_ultrametric_tree <- function(n_tip) {
  edges <- matrix(integer(), ncol = 2L)
  edge_lengths <- numeric()
  next_node <- n_tip + 1L

  build <- function(tips) {
    if (length(tips) == 1L) {
      return(list(node = tips[[1L]], height = 0))
    }
    node <- next_node
    next_node <<- next_node + 1L
    mid <- floor(length(tips) / 2L)
    left <- build(tips[seq_len(mid)])
    right <- build(tips[seq.int(mid + 1L, length(tips))])
    height <- max(left$height, right$height) + 1
    edges <<- rbind(edges, c(node, left$node), c(node, right$node))
    edge_lengths <<- c(
      edge_lengths,
      height - left$height,
      height - right$height
    )
    list(node = node, height = height)
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

star_ultrametric_tree <- function(n_tip) {
  root <- n_tip + 1L
  structure(
    list(
      edge = cbind(root, seq_len(n_tip)),
      edge.length = rep(1, n_tip),
      tip.label = paste0("sp_", seq_len(n_tip)),
      Nnode = 1L
    ),
    class = "phylo"
  )
}

tree_height <- function(tree) {
  edge <- tree$edge
  children <- split(seq_len(nrow(edge)), edge[, 1L])
  root <- setdiff(unique(edge[, 1L]), edge[, 2L])[[1L]]
  depth <- numeric(length(tree$tip.label) + tree$Nnode)
  stack <- root
  while (length(stack) > 0L) {
    parent <- stack[[length(stack)]]
    stack <- stack[-length(stack)]
    child_edges <- children[[as.character(parent)]]
    for (edge_id in child_edges) {
      child <- edge[edge_id, 2L]
      depth[[child]] <- depth[[parent]] + tree$edge.length[[edge_id]]
      stack <- c(stack, child)
    }
  }
  max(depth[seq_along(tree$tip.label)])
}

simulate_phylo_effect <- function(tree, sd_phylo) {
  edge <- tree$edge
  children <- split(seq_len(nrow(edge)), edge[, 1L])
  root <- setdiff(unique(edge[, 1L]), edge[, 2L])[[1L]]
  height <- tree_height(tree)
  effect <- numeric(length(tree$tip.label) + tree$Nnode)
  stack <- root
  while (length(stack) > 0L) {
    parent <- stack[[length(stack)]]
    stack <- stack[-length(stack)]
    child_edges <- children[[as.character(parent)]]
    for (edge_id in child_edges) {
      child <- edge[edge_id, 2L]
      effect[[child]] <- effect[[parent]] +
        stats::rnorm(
          1L,
          sd = sd_phylo * sqrt(tree$edge.length[[edge_id]] / height)
        )
      stack <- c(stack, child)
    }
  }
  stats::setNames(effect[seq_along(tree$tip.label)], tree$tip.label)
}

simulate_benchmark_data <- function(args) {
  set.seed(args$seed)
  if (!args$structured %in% c("phylo", "none")) {
    stop("--structured must be phylo or none.", call. = FALSE)
  }
  tree <- NULL
  species_levels <- paste0("sp_", seq_len(args$species))
  if (identical(args$structured, "phylo")) {
    tree <- switch(
      args$tree,
      balanced = balanced_ultrametric_tree(args$species),
      star = star_ultrametric_tree(args$species),
      stop("--tree must be balanced or star.", call. = FALSE)
    )
    species_levels <- tree$tip.label
  }
  species <- sample(species_levels, args$rows, replace = TRUE)
  if (isTRUE(args$aggregate_gaussian)) {
    n_cells <- min(args$aggregation_cells, args$rows)
    cell <- sample(seq_len(n_cells), args$rows, replace = TRUE)
    grid_size <- max(2L, ceiling(sqrt(n_cells)))
    x1_grid <- seq(-1, 1, length.out = grid_size)
    x2_grid <- seq(-0.8, 0.8, length.out = grid_size)
    x1 <- x1_grid[((seq_len(n_cells) - 1L) %% grid_size) + 1L][cell]
    x2 <- x2_grid[((seq_len(n_cells) - 1L) %/% grid_size) + 1L][cell]
  } else {
    cell <- NULL
    x1 <- stats::rnorm(args$rows)
    x2 <- stats::runif(args$rows, -1, 1)
  }
  cell_id <- NULL
  eta_mu <- 0.2 + 0.35 * x1 - 0.15 * x2
  if (isTRUE(args$cell_random_effect)) {
    n_cell_re <- min(args$cell_random_effect_cells, args$rows)
    cell_id <- factor(
      sample(paste0("cell_", seq_len(n_cell_re)), args$rows, replace = TRUE),
      levels = paste0("cell_", seq_len(n_cell_re))
    )
    cell_effect <- stats::rnorm(nlevels(cell_id), sd = 0.25)
    names(cell_effect) <- levels(cell_id)
    eta_mu <- eta_mu + cell_effect[cell_id]
  }
  if (!is.null(tree)) {
    phylo_effect <- simulate_phylo_effect(tree, sd_phylo = 0.5)
    eta_mu <- eta_mu + phylo_effect[species]
  }
  habitat <- NULL
  if (isTRUE(args$factor_heavy)) {
    habitat_levels <- paste0("hab_", 1:40)
    habitat <- if (isTRUE(args$aggregate_gaussian)) {
      factor(
        habitat_levels[((cell - 1L) %% length(habitat_levels)) + 1L],
        levels = habitat_levels
      )
    } else {
      factor(sample(habitat_levels, args$rows, replace = TRUE))
    }
    habitat_effect <- stats::rnorm(nlevels(habitat), sd = 0.08)
    names(habitat_effect) <- levels(habitat)
    eta_mu <- eta_mu + habitat_effect[habitat]
  }
  eta_sigma <- rep(log(0.4), args$rows)
  if (isTRUE(args$sigma_x)) {
    eta_sigma <- eta_sigma + 0.15 * x1
  }
  dat <- data.frame(
    y = stats::rnorm(args$rows, mean = eta_mu, sd = exp(eta_sigma)),
    x1 = x1,
    x2 = x2,
    species = species
  )
  if (!is.null(habitat)) {
    dat$habitat <- habitat
  }
  if (!is.null(cell_id)) {
    dat$cell_id <- cell_id
  }
  list(data = dat, tree = tree)
}

fit_formula <- function(args) {
  if (isTRUE(args$sparse_fixed) && !identical(args$structured, "none")) {
    stop(
      "--sparse-fixed true currently requires --structured none.",
      call. = FALSE
    )
  }
  if (isTRUE(args$sparse_fixed) && isTRUE(args$sigma_x)) {
    stop(
      "--sparse-fixed true currently requires --sigma-x false.",
      call. = FALSE
    )
  }
  if (isTRUE(args$aggregate_gaussian) && !identical(args$structured, "none")) {
    stop(
      "--aggregate-gaussian true currently requires --structured none.",
      call. = FALSE
    )
  }
  if (isTRUE(args$aggregate_gaussian) && isTRUE(args$sparse_fixed)) {
    stop(
      "--aggregate-gaussian true cannot be combined with --sparse-fixed true yet.",
      call. = FALSE
    )
  }
  if (isTRUE(args$aggregate_gaussian) && isTRUE(args$cell_random_effect)) {
    stop(
      "--aggregate-gaussian true cannot be combined with --cell-random-effect true.",
      call. = FALSE
    )
  }
  if (isTRUE(args$sparse_fixed) && isTRUE(args$cell_random_effect)) {
    stop(
      "--sparse-fixed true cannot be combined with --cell-random-effect true.",
      call. = FALSE
    )
  }

  mu_terms <- c("x1", "x2")
  if (isTRUE(args$factor_heavy)) {
    mu_terms <- c(mu_terms, "habitat")
  }
  if (identical(args$structured, "phylo")) {
    mu_terms <- c(mu_terms, "phylo(1 | species, tree = tree)")
  }
  if (isTRUE(args$cell_random_effect)) {
    mu_terms <- c(mu_terms, "(1 | cell_id)")
  }
  mu_formula <- stats::as.formula(paste(
    "y ~",
    paste(mu_terms, collapse = " + ")
  ))
  sigma_formula <- stats::as.formula(
    if (isTRUE(args$sigma_x)) "~ x1" else "~ 1"
  )
  eval(
    substitute(
      bf(mu_formula, sigma = sigma_formula),
      list(mu_formula = mu_formula, sigma_formula = sigma_formula)
    ),
    envir = parent.frame()
  )
}

object_mb <- function(x) {
  as.numeric(utils::object.size(x)) / 1024^2
}

benchmark_design_summary <- function(fit) {
  summary_fun <- get0(
    "fixed_effect_design_summary",
    envir = asNamespace("drmTMB"),
    inherits = FALSE
  )
  if (is.null(summary_fun)) {
    return(data.frame())
  }
  summary_fun(fit$model$X)
}

benchmark_largest_design <- function(fit) {
  design <- benchmark_design_summary(fit)
  if (nrow(design) == 0L) {
    return(list(
      name = NA_character_,
      cols = NA_integer_,
      nonzero = NA_real_,
      density = NA_real_
    ))
  }
  largest <- design[which.max(design$size_mb), , drop = FALSE]
  list(
    name = largest$dpar[[1L]],
    cols = largest$n_cols[[1L]],
    nonzero = largest$n_nonzero[[1L]],
    density = largest$density[[1L]]
  )
}

benchmark_aggregation_summary <- function(fit) {
  summary_fun <- get0(
    "drm_gaussian_aggregation_summary",
    envir = asNamespace("drmTMB"),
    inherits = FALSE
  )
  if (is.null(summary_fun)) {
    return(list(cells = NA_integer_, ratio = NA_real_, largest = NA_real_))
  }
  summary <- summary_fun(fit$model$aggregation$gaussian)
  if (is.null(summary)) {
    return(list(cells = NA_integer_, ratio = NA_real_, largest = NA_real_))
  }
  list(
    cells = summary$aggregation_cells[[1L]],
    ratio = summary$compression_ratio[[1L]],
    largest = summary$largest_cell_n[[1L]]
  )
}

gc_used_mb <- function() {
  gc_out <- gc()
  bytes_per_cell <- c(Ncells = 56, Vcells = 8)
  cell_names <- intersect(names(bytes_per_cell), rownames(gc_out))
  sum(gc_out[cell_names, "used"] * bytes_per_cell[cell_names]) / 1024^2
}

opt_scalar <- function(x, name, default = NA_real_) {
  value <- x[[name]]
  if (is.null(value) || length(value) == 0L) {
    return(default)
  }
  unname(value[[1L]])
}

package_version_or_na <- function(package) {
  if (!requireNamespace(package, quietly = TRUE)) {
    return(NA_character_)
  }
  as.character(utils::packageVersion(package))
}

format_cli_value <- function(value) {
  if (is.logical(value)) {
    return(tolower(as.character(value)))
  }
  as.character(value)
}

benchmark_command <- function(args) {
  keys <- c(
    "rows",
    "species",
    "seed",
    "structured",
    "tree",
    "factor_heavy",
    "sigma_x",
    "sparse_fixed",
    "aggregate_gaussian",
    "aggregation_cells",
    "cell_random_effect",
    "cell_random_effect_cells",
    "memory_light",
    "eval_max",
    "iter_max",
    "output"
  )
  pieces <- c("Rscript", "bench/large-phylo-location.R")
  for (key in keys) {
    value <- format_cli_value(args[[key]])
    if (identical(key, "output") && !nzchar(value)) {
      next
    }
    pieces <- c(
      pieces,
      paste0("--", gsub("_", "-", key, fixed = TRUE)),
      shQuote(value, type = "sh")
    )
  }
  paste(pieces, collapse = " ")
}

local_package_version <- function() {
  if (file.exists("DESCRIPTION")) {
    desc <- tryCatch(
      utils::read.dcf("DESCRIPTION", fields = "Version"),
      error = function(e) NULL
    )
    if (!is.null(desc) && length(desc) > 0L && nzchar(desc[[1L]])) {
      return(desc[[1L]])
    }
  }
  package_version_or_na("drmTMB")
}

local_git_sha <- function() {
  out <- tryCatch(
    system2(
      "git",
      c("rev-parse", "--short", "HEAD"),
      stdout = TRUE,
      stderr = FALSE
    ),
    warning = function(w) character(),
    error = function(e) character()
  )
  if (length(out) == 0L || !nzchar(out[[1L]])) {
    return(NA_character_)
  }
  out[[1L]]
}

local_git_dirty <- function() {
  out <- tryCatch(
    system2("git", c("status", "--porcelain"), stdout = TRUE, stderr = FALSE),
    warning = function(w) NA_character_,
    error = function(e) NA_character_
  )
  if (length(out) == 1L && is.na(out[[1L]])) {
    return(NA)
  }
  length(out) > 0L
}

benchmark_environment <- function(args) {
  sys <- Sys.info()
  sys_value <- function(name) {
    value <- unname(sys[[name]])
    if (is.null(value) || is.na(value) || !nzchar(value)) {
      return(NA_character_)
    }
    value
  }
  list(
    run_started_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    r_version = paste(R.version$major, R.version$minor, sep = "."),
    platform = R.version$platform,
    os = paste(
      na.omit(c(sys_value("sysname"), sys_value("release"))),
      collapse = " "
    ),
    machine = sys_value("machine"),
    drmTMB_version = local_package_version(),
    TMB_version = package_version_or_na("TMB"),
    git_sha = local_git_sha(),
    git_dirty = local_git_dirty(),
    benchmark_command = benchmark_command(args)
  )
}

run_benchmark <- function(args) {
  load_drmTMB()
  if (args$species < 2L && identical(args$structured, "phylo")) {
    stop("--species must be at least 2 for phylogenetic models.", call. = FALSE)
  }
  fit_formula(args)
  env <- benchmark_environment(args)
  gc()
  before_mb <- gc_used_mb()
  data_time <- system.time(sim <- simulate_benchmark_data(args))
  data_mb <- object_mb(sim$data)
  tree_mb <- if (is.null(sim$tree)) 0 else object_mb(sim$tree)
  gc()
  pre_fit_mb <- gc_used_mb()
  control <- drm_control(
    optimizer = list(eval.max = args$eval_max, iter.max = args$iter_max),
    keep_data = !args$memory_light,
    keep_model_frame = !args$memory_light,
    keep_tmb_object = !args$memory_light,
    sparse_fixed = args$sparse_fixed,
    aggregate_gaussian = args$aggregate_gaussian
  )
  fit_time <- system.time({
    tree <- sim$tree
    fit <- drmTMB(
      fit_formula(args),
      family = gaussian(),
      data = sim$data,
      control = control
    )
  })
  gc()
  post_fit_mb <- gc_used_mb()
  predict_time <- system.time(pred <- predict(fit, dpar = "mu"))
  residual_time <- system.time(res <- residuals(fit))
  opt_message <- fit$opt$message
  if (is.null(opt_message) || length(opt_message) == 0L) {
    opt_message <- NA_character_
  }
  largest_design <- benchmark_largest_design(fit)
  aggregation <- benchmark_aggregation_summary(fit)

  cbind(
    as.data.frame(env, stringsAsFactors = FALSE),
    data.frame(
      rows = args$rows,
      species = args$species,
      structured = args$structured,
      tree = args$tree,
      factor_heavy = args$factor_heavy,
      sigma_x = args$sigma_x,
      sparse_fixed = args$sparse_fixed,
      aggregate_gaussian = args$aggregate_gaussian,
      aggregation_cells_requested = args$aggregation_cells,
      aggregation_cells_fitted = aggregation$cells,
      aggregation_compression_ratio = aggregation$ratio,
      aggregation_largest_cell_n = aggregation$largest,
      cell_random_effect = args$cell_random_effect,
      cell_random_effect_cells = args$cell_random_effect_cells,
      memory_light = args$memory_light,
      convergence = fit$opt$convergence,
      convergence_message = opt_message[[1L]],
      iterations = opt_scalar(fit$opt, "iterations"),
      function_evaluations = opt_scalar(fit$opt$evaluations, "function"),
      gradient_evaluations = opt_scalar(fit$opt$evaluations, "gradient"),
      nobs = stats::nobs(fit),
      data_build_sec = unname(data_time[["elapsed"]]),
      fit_sec = unname(fit_time[["elapsed"]]),
      predict_mu_sec = unname(predict_time[["elapsed"]]),
      residuals_sec = unname(residual_time[["elapsed"]]),
      data_object_mb = data_mb,
      tree_object_mb = tree_mb,
      fit_object_mb = object_mb(fit),
      model_matrix_mb = object_mb(fit$model$X),
      model_matrix_largest = largest_design$name,
      model_matrix_largest_cols = largest_design$cols,
      model_matrix_largest_nonzero = largest_design$nonzero,
      model_matrix_largest_density = largest_design$density,
      tmb_data_mb = object_mb(fit$model$tmb_data),
      gc_used_mb_before = before_mb,
      gc_used_mb_pre_fit = pre_fit_mb,
      gc_used_mb_post_fit = post_fit_mb,
      mu_mean = mean(pred),
      residual_sd = stats::sd(res),
      sigma_hat = mean(stats::sigma(fit)),
      sd_phylo_hat = if (identical(args$structured, "phylo")) {
        unname(fit$sdpars$mu[[1L]])
      } else {
        NA_real_
      },
      stringsAsFactors = FALSE
    )
  )
}

write_result <- function(result, output) {
  if (!nzchar(output)) {
    print(result, row.names = FALSE)
    return(invisible(result))
  }
  dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
  append <- file.exists(output) && file.info(output)$size > 0
  if (append) {
    header <- names(utils::read.csv(output, nrows = 0L, check.names = FALSE))
    if (!identical(header, names(result))) {
      stop(
        "Existing benchmark CSV has a different schema. ",
        "Choose a new --output path or remove the old benchmark CSV.",
        call. = FALSE
      )
    }
  }
  utils::write.table(
    result,
    file = output,
    sep = ",",
    row.names = FALSE,
    col.names = !append,
    append = append
  )
  message("Wrote benchmark result to ", output)
  invisible(result)
}

main <- function() {
  args <- parse_args()
  result <- run_benchmark(args)
  write_result(result, args$output)
}

if (identical(environment(), globalenv())) {
  main()
}
