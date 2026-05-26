#!/usr/bin/env Rscript

# Developer-only harness for the Ayumi/Santi Objective 1 q2 phylogenetic
# validation slice. It intentionally lives under tools/ rather than R/.

usage <- function() {
  cat(
    paste(
      "Usage: Rscript tools/ayumi-santi-q2-objective1-runner.R [options]",
      "",
      "Required:",
      "  --data PATH             CSV or RDS data frame.",
      "  --tree PATH             RDS, Nexus, or Newick phylo tree.",
      "  --species COLUMN        Species column matching tree tip labels.",
      "  --response1 COLUMN      First response column.",
      "  --response2 COLUMN      Second response column.",
      "",
      "Optional:",
      "  --label TEXT            Run label. Default: objective1_q2_phylo.",
      "  --output-dir PATH       Output directory.",
      "                           Default: docs/dev-log/ayumi-santi/q2-objective1/<label>",
      "  --mu1-rhs RHS           Fixed RHS before the mu1 phylo term. Default: 1.",
      "  --mu2-rhs RHS           Fixed RHS before the mu2 phylo term. Default: 1.",
      "  --sigma1-rhs RHS        sigma1 RHS. Default: 1.",
      "  --sigma2-rhs RHS        sigma2 RHS. Default: 1.",
      "  --tree-format FORMAT    auto, rds, nexus, or newick. Default: auto.",
      "  --max-species N         Optional deterministic species cap for smoke runs.",
      "  --se true|false         Compute standard errors. Default: true.",
      "  --force-ultrametric true|false",
      "                           Force non-ultrametric trees with phytools. Default: false.",
      "  --resolve-polytomies true|false",
      "                           Randomly resolve polytomies with ape. Default: false.",
      "  --dry-run true|false    Write preflight and formula only. Default: false.",
      "  --help                  Show this help message.",
      "",
      "The fitted model is q2 by construction: phylo() appears in mu1 and mu2",
      "with the shared block label p; sigma1, sigma2, and rho12 stay ordinary",
      "formula terms. This is the Objective 1 route, not the q4 PLSM route.",
      sep = "\n"
    ),
    "\n"
  )
}

parse_args <- function(args) {
  opts <- list(
    data = NULL,
    tree = NULL,
    species = NULL,
    response1 = NULL,
    response2 = NULL,
    label = "objective1_q2_phylo",
    output_dir = NULL,
    mu1_rhs = "1",
    mu2_rhs = "1",
    sigma1_rhs = "1",
    sigma2_rhs = "1",
    tree_format = "auto",
    max_species = "",
    se = "true",
    force_ultrametric = "false",
    resolve_polytomies = "false",
    dry_run = "false",
    help = FALSE
  )

  i <- 1L
  while (i <= length(args)) {
    arg <- args[[i]]
    if (identical(arg, "--help") || identical(arg, "-h")) {
      opts$help <- TRUE
      i <- i + 1L
      next
    }
    if (!startsWith(arg, "--")) {
      stop("Unexpected argument: ", arg, call. = FALSE)
    }
    key_value <- substring(arg, 3L)
    if (grepl("=", key_value, fixed = TRUE)) {
      pieces <- strsplit(key_value, "=", fixed = TRUE)[[1L]]
      key <- pieces[[1L]]
      value <- paste(pieces[-1L], collapse = "=")
      i <- i + 1L
    } else {
      key <- key_value
      i <- i + 1L
      if (i > length(args)) {
        stop("Missing value for --", key, ".", call. = FALSE)
      }
      value <- args[[i]]
      i <- i + 1L
    }
    key <- gsub("-", "_", key, fixed = TRUE)
    if (!key %in% names(opts)) {
      stop(
        "Unknown option --",
        gsub("_", "-", key, fixed = TRUE),
        ".",
        call. = FALSE
      )
    }
    opts[[key]] <- value
  }
  opts
}

bool_opt <- function(value, name) {
  value <- tolower(trimws(value))
  if (value %in% c("1", "true", "yes", "y")) {
    return(TRUE)
  }
  if (value %in% c("0", "false", "no", "n")) {
    return(FALSE)
  }
  stop("--", name, " must be true or false.", call. = FALSE)
}

integer_opt <- function(value, name, allow_empty = TRUE) {
  if (allow_empty && (!nzchar(value) || is.na(value))) {
    return(NA_integer_)
  }
  out <- suppressWarnings(as.integer(value))
  if (!is.finite(out) || is.na(out) || out <= 0L) {
    stop("--", name, " must be a positive integer.", call. = FALSE)
  }
  out
}

choice_opt <- function(value, choices, name) {
  if (!value %in% choices) {
    stop(
      "--",
      name,
      " must be one of: ",
      paste(choices, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  value
}

required_opt <- function(opts, name) {
  value <- opts[[name]]
  if (is.null(value) || !nzchar(value)) {
    stop(
      "--",
      gsub("_", "-", name, fixed = TRUE),
      " is required.",
      call. = FALSE
    )
  }
  value
}

require_package <- function(package) {
  if (!requireNamespace(package, quietly = TRUE)) {
    stop(
      "Package `",
      package,
      "` is required for this local runner.",
      call. = FALSE
    )
  }
}

load_drmtmb <- function() {
  if (
    file.exists("DESCRIPTION") &&
      dir.exists("R") &&
      requireNamespace("devtools", quietly = TRUE)
  ) {
    devtools::load_all(".", quiet = TRUE)
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

quote_name <- function(name) {
  if (grepl("^[.A-Za-z][._A-Za-z0-9]*$", name) && !name %in% reserved_words()) {
    return(name)
  }
  paste0("`", gsub("`", "\\\\`", name, fixed = TRUE), "`")
}

reserved_words <- function() {
  c(
    "if",
    "else",
    "repeat",
    "while",
    "function",
    "for",
    "in",
    "next",
    "break",
    "TRUE",
    "FALSE",
    "NULL",
    "Inf",
    "NaN",
    "NA",
    "NA_integer_",
    "NA_real_",
    "NA_complex_",
    "NA_character_"
  )
}

normalize_rhs <- function(rhs) {
  rhs <- trimws(rhs)
  if (!nzchar(rhs)) {
    return("1")
  }
  rhs
}

add_rhs_term <- function(rhs, term) {
  rhs <- normalize_rhs(rhs)
  if (identical(rhs, "0")) {
    return(term)
  }
  paste(rhs, term, sep = " + ")
}

formula_expr <- function(lhs, rhs) {
  text <- if (nzchar(lhs)) {
    paste(quote_name(lhs), "~", normalize_rhs(rhs))
  } else {
    paste("~", normalize_rhs(rhs))
  }
  parse(text = text)[[1L]]
}

rhs_vars <- function(rhs) {
  rhs <- normalize_rhs(rhs)
  unique(all.vars(stats::as.formula(paste("~", rhs))))
}

read_data <- function(path) {
  if (!file.exists(path)) {
    stop("Missing data file: ", path, call. = FALSE)
  }
  ext <- tolower(tools::file_ext(path))
  if (identical(ext, "rds")) {
    dat <- readRDS(path)
  } else {
    dat <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  }
  if (!is.data.frame(dat)) {
    stop("--data must contain a data frame.", call. = FALSE)
  }
  dat
}

read_tree <- function(path, format) {
  if (!file.exists(path)) {
    stop("Missing tree file: ", path, call. = FALSE)
  }
  require_package("ape")
  ext <- tolower(tools::file_ext(path))
  if (identical(format, "auto")) {
    format <- if (identical(ext, "rds")) {
      "rds"
    } else if (ext %in% c("nex", "nexus")) {
      "nexus"
    } else {
      "newick"
    }
  }
  tree <- switch(
    format,
    rds = readRDS(path),
    nexus = ape::read.nexus(path),
    newick = ape::read.tree(path),
    stop("Unsupported tree format: ", format, call. = FALSE)
  )
  if (!inherits(tree, "phylo")) {
    stop("--tree must contain an object with class `phylo`.", call. = FALSE)
  }
  tree
}

patch_tree_edges <- function(tree) {
  edge <- tree$edge.length
  if (is.null(edge)) {
    stop("Tree must contain branch lengths.", call. = FALSE)
  }
  if (any(is.na(edge) | edge <= 0)) {
    unit <- stats::median(edge[edge > 0], na.rm = TRUE)
    if (!is.finite(unit)) {
      unit <- 1
    }
    edge[is.na(edge) | edge <= 0] <- unit * 1e-6
    tree$edge.length <- edge
  }
  tree
}

prepare_data_tree <- function(
  dat,
  tree,
  species_col,
  required_cols,
  max_species = NA_integer_,
  resolve_polytomies = FALSE,
  force_ultrametric = FALSE
) {
  missing_cols <- setdiff(required_cols, names(dat))
  if (length(missing_cols) > 0L) {
    stop(
      "Data are missing required column(s): ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  complete <- stats::complete.cases(dat[, required_cols, drop = FALSE])
  dat <- dat[complete, , drop = FALSE]
  dat[[species_col]] <- as.character(dat[[species_col]])
  dat <- dat[
    nzchar(dat[[species_col]]) & !is.na(dat[[species_col]]),
    ,
    drop = FALSE
  ]

  shared <- sort(intersect(unique(dat[[species_col]]), tree$tip.label))
  if (length(shared) < 2L) {
    stop(
      "Data and tree have fewer than two shared species labels.",
      call. = FALSE
    )
  }
  if (!is.na(max_species) && max_species < length(shared)) {
    shared <- shared[seq_len(max_species)]
  }
  dat <- dat[dat[[species_col]] %in% shared, , drop = FALSE]
  dat <- dat[order(dat[[species_col]]), , drop = FALSE]
  tree <- ape::keep.tip(tree, shared)
  tree <- patch_tree_edges(tree)

  if (resolve_polytomies && !ape::is.binary(tree)) {
    set.seed(20260524L)
    tree <- ape::multi2di(tree, random = TRUE)
    tree <- patch_tree_edges(tree)
  }
  if (force_ultrametric && !ape::is.ultrametric(tree)) {
    require_package("phytools")
    tree <- phytools::force.ultrametric(tree, method = "extend")
    tree <- patch_tree_edges(tree)
  }

  list(data = dat, tree = tree, shared_species = shared)
}

make_q2_formula <- function(
  response1,
  response2,
  species_col,
  mu1_rhs,
  mu2_rhs,
  sigma1_rhs,
  sigma2_rhs,
  tree
) {
  phylo_term <- paste0(
    "phylo(1 | p | ",
    quote_name(species_col),
    ", tree = tree)"
  )
  calls <- list(
    mu1 = formula_expr(response1, add_rhs_term(mu1_rhs, phylo_term)),
    mu2 = formula_expr(response2, add_rhs_term(mu2_rhs, phylo_term)),
    sigma1 = formula_expr("", sigma1_rhs),
    sigma2 = formula_expr("", sigma2_rhs),
    rho12 = formula_expr("", "1")
  )
  eval(as.call(c(list(as.name("bf")), calls)), envir = environment())
}

deparse_one <- function(x) {
  paste(deparse(x, width.cutoff = 500L), collapse = " ")
}

format_drm_formula <- function(formula) {
  calls <- formula$calls
  names <- formula$names
  out <- "<drm_formula>"
  for (i in seq_along(calls)) {
    prefix <- if (nzchar(names[[i]])) paste0(names[[i]], " = ") else ""
    out <- c(out, paste0("  ", prefix, deparse_one(calls[[i]])))
  }
  out
}

capture_conditions <- function(expr) {
  warnings <- character()
  messages <- character()
  value <- withCallingHandlers(
    tryCatch(expr, error = function(e) e),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    },
    message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  list(value = value, warnings = warnings, messages = messages)
}

safe_table <- function(x) {
  if (is.null(x)) {
    return(data.frame())
  }
  out <- as.data.frame(x, stringsAsFactors = FALSE)
  row_names <- row.names(out)
  if (
    nrow(out) > 0L &&
      !is.null(row_names) &&
      !identical(row_names, as.character(seq_len(nrow(out))))
  ) {
    out <- cbind(term = row_names, out, stringsAsFactors = FALSE)
  }
  row.names(out) <- NULL
  out
}

write_table <- function(dat, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(dat, path, row.names = FALSE, na = "")
}

condition_rows <- function(values, type) {
  if (!length(values)) {
    return(data.frame())
  }
  data.frame(
    type = type,
    message = as.character(values),
    stringsAsFactors = FALSE
  )
}

bind_tables <- function(tables) {
  tables <- Filter(function(x) is.data.frame(x) && nrow(x) > 0L, tables)
  if (!length(tables)) {
    return(data.frame())
  }
  columns <- unique(unlist(lapply(tables, names), use.names = FALSE))
  tables <- lapply(tables, function(tab) {
    missing <- setdiff(columns, names(tab))
    for (col in missing) {
      tab[[col]] <- NA
    }
    tab[columns]
  })
  out <- do.call(rbind, tables)
  row.names(out) <- NULL
  out
}

gradient_summary <- function(fit) {
  grad <- tryCatch(fit$obj$gr(fit$opt$par), error = function(e) numeric())
  grad_abs <- abs(grad)
  gradient_max <- if (length(grad_abs)) {
    max(grad_abs, na.rm = TRUE)
  } else {
    NA_real_
  }
  gradient_component <- NA_character_
  if (length(grad_abs) && is.finite(gradient_max)) {
    gradient_index <- which.max(grad_abs)
    grad_names <- names(grad_abs)
    gradient_component <- if (
      !is.null(grad_names) && length(grad_names) >= gradient_index
    ) {
      grad_names[[gradient_index]]
    } else {
      paste0("par[", gradient_index, "]")
    }
  }
  data.frame(
    gradient_max = gradient_max,
    gradient_component = gradient_component,
    stringsAsFactors = FALSE
  )
}

sdpars_table <- function(fit) {
  sdpars <- fit$sdpars
  if (is.null(sdpars) || !length(sdpars)) {
    return(data.frame())
  }
  out <- list()
  for (dpar in names(sdpars)) {
    values <- sdpars[[dpar]]
    if (is.null(values) || !length(values)) {
      next
    }
    out[[length(out) + 1L]] <- data.frame(
      dpar = dpar,
      term = names(values),
      estimate = as.numeric(values),
      stringsAsFactors = FALSE
    )
  }
  bind_tables(out)
}

rho12_table <- function(fit) {
  values <- tryCatch(rho12(fit), error = function(e) numeric())
  if (!length(values)) {
    return(data.frame())
  }
  data.frame(
    n = length(values),
    min = min(values, na.rm = TRUE),
    mean = mean(values, na.rm = TRUE),
    max = max(values, na.rm = TRUE),
    unique_values = length(unique(round(values, 12L))),
    stringsAsFactors = FALSE
  )
}

write_preflight <- function(path, rows) {
  write_table(
    data.frame(
      item = names(rows),
      value = unname(unlist(rows, use.names = FALSE)),
      stringsAsFactors = FALSE
    ),
    path
  )
}

fit_and_write <- function(formula, dat, tree, out_dir, se) {
  started <- Sys.time()
  captured <- capture_conditions(
    drmTMB(
      formula,
      family = biv_gaussian(),
      data = dat,
      control = drm_control(se = se)
    )
  )
  elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  if (inherits(captured$value, "error")) {
    write_table(
      data.frame(
        status = "error",
        elapsed_sec = elapsed,
        convergence = NA_integer_,
        pdHess = NA,
        logLik = NA_real_,
        AIC = NA_real_,
        stringsAsFactors = FALSE
      ),
      file.path(out_dir, "fit-summary.csv")
    )
    write_table(
      bind_tables(list(
        condition_rows(conditionMessage(captured$value), "error"),
        condition_rows(captured$warnings, "warning"),
        condition_rows(captured$messages, "message")
      )),
      file.path(out_dir, "fit-conditions.csv")
    )
    stop("Model fit failed; see fit-conditions.csv.", call. = FALSE)
  }

  fit <- captured$value
  write_table(
    cbind(
      data.frame(
        status = "fit",
        elapsed_sec = elapsed,
        convergence = fit$opt$convergence,
        optimizer_message = fit$opt$message,
        pdHess = if (is.null(fit$sdr)) NA else isTRUE(fit$sdr$pdHess),
        logLik = unname(as.numeric(stats::logLik(fit))),
        AIC = stats::AIC(fit),
        stringsAsFactors = FALSE
      ),
      gradient_summary(fit)
    ),
    file.path(out_dir, "fit-summary.csv")
  )
  write_table(
    bind_tables(list(
      condition_rows(captured$warnings, "warning"),
      condition_rows(captured$messages, "message")
    )),
    file.path(out_dir, "fit-conditions.csv")
  )
  write_table(
    safe_table(summary(fit)$coefficients),
    file.path(out_dir, "fixed-effects.csv")
  )
  write_table(
    safe_table(summary(fit)$covariance),
    file.path(out_dir, "covariance.csv")
  )
  write_table(safe_table(corpairs(fit)), file.path(out_dir, "corpairs.csv"))
  write_table(sdpars_table(fit), file.path(out_dir, "sdpars.csv"))
  write_table(rho12_table(fit), file.path(out_dir, "rho12-summary.csv"))
  write_table(
    safe_table(profile_targets(fit)),
    file.path(out_dir, "profile-targets.csv")
  )
  write_table(safe_table(check_drm(fit)), file.path(out_dir, "check-rows.csv"))
  saveRDS(fit, file.path(out_dir, "fit.rds"))
  invisible(fit)
}

main <- function(args = commandArgs(trailingOnly = TRUE)) {
  opts <- parse_args(args)
  if (opts$help) {
    usage()
    return(invisible(NULL))
  }

  data_path <- required_opt(opts, "data")
  tree_path <- required_opt(opts, "tree")
  species_col <- required_opt(opts, "species")
  response1 <- required_opt(opts, "response1")
  response2 <- required_opt(opts, "response2")
  label <- opts$label
  if (is.null(opts$output_dir) || !nzchar(opts$output_dir)) {
    opts$output_dir <- file.path(
      "docs",
      "dev-log",
      "ayumi-santi",
      "q2-objective1",
      label
    )
  }
  tree_format <- choice_opt(
    opts$tree_format,
    c("auto", "rds", "nexus", "newick"),
    "tree-format"
  )
  max_species <- integer_opt(opts$max_species, "max-species")
  se <- bool_opt(opts$se, "se")
  dry_run <- bool_opt(opts$dry_run, "dry-run")
  force_ultrametric <- bool_opt(opts$force_ultrametric, "force-ultrametric")
  resolve_polytomies <- bool_opt(opts$resolve_polytomies, "resolve-polytomies")

  dat_raw <- read_data(data_path)
  tree_raw <- read_tree(tree_path, tree_format)
  required_cols <- unique(c(
    species_col,
    response1,
    response2,
    rhs_vars(opts$mu1_rhs),
    rhs_vars(opts$mu2_rhs),
    rhs_vars(opts$sigma1_rhs),
    rhs_vars(opts$sigma2_rhs)
  ))
  prepared <- prepare_data_tree(
    dat_raw,
    tree_raw,
    species_col = species_col,
    required_cols = required_cols,
    max_species = max_species,
    resolve_polytomies = resolve_polytomies,
    force_ultrametric = force_ultrametric
  )
  dat <- prepared$data
  tree <- prepared$tree

  load_drmtmb()
  formula <- make_q2_formula(
    response1 = response1,
    response2 = response2,
    species_col = species_col,
    mu1_rhs = opts$mu1_rhs,
    mu2_rhs = opts$mu2_rhs,
    sigma1_rhs = opts$sigma1_rhs,
    sigma2_rhs = opts$sigma2_rhs,
    tree = tree
  )

  dir.create(opts$output_dir, recursive = TRUE, showWarnings = FALSE)
  writeLines(
    format_drm_formula(formula),
    file.path(opts$output_dir, "formula.txt")
  )
  write_preflight(
    file.path(opts$output_dir, "preflight.csv"),
    list(
      label = label,
      data_path = normalizePath(data_path, mustWork = FALSE),
      tree_path = normalizePath(tree_path, mustWork = FALSE),
      output_dir = normalizePath(opts$output_dir, mustWork = FALSE),
      species_column = species_col,
      response1 = response1,
      response2 = response2,
      mu1_rhs = opts$mu1_rhs,
      mu2_rhs = opts$mu2_rhs,
      sigma1_rhs = opts$sigma1_rhs,
      sigma2_rhs = opts$sigma2_rhs,
      n_input_rows = nrow(dat_raw),
      n_complete_shared_rows = nrow(dat),
      n_input_species = length(unique(as.character(dat_raw[[species_col]]))),
      n_shared_species = length(prepared$shared_species),
      n_tree_tips = length(tree$tip.label),
      tree_is_binary = ape::is.binary(tree),
      tree_is_ultrametric = ape::is.ultrametric(tree),
      max_species = if (is.na(max_species)) "" else max_species,
      se = se,
      dry_run = dry_run,
      force_ultrametric = force_ultrametric,
      resolve_polytomies = resolve_polytomies
    )
  )

  if (dry_run) {
    cat(
      "Wrote q2 Objective 1 dry-run artifacts to ",
      opts$output_dir,
      "\n",
      sep = ""
    )
    return(invisible(NULL))
  }

  fit_and_write(formula, dat, tree, opts$output_dir, se = se)
  cat("Wrote q2 Objective 1 fit artifacts to ", opts$output_dir, "\n", sep = "")
  invisible(NULL)
}

if (identical(environment(), globalenv())) {
  main()
}
