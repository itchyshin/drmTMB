#!/usr/bin/env Rscript

# Runs the remaining Ayumi/Santi no-real-data simulation slices:
# q2 mini-grid, univariate PLSM positive control, q4 diagnostic positive
# control, split-fit class contrast smoke, and an integration summary.

usage <- function() {
  cat(
    paste(
      "Usage: Rscript tools/ayumi-santi-finish-sim-slices.R [options]",
      "",
      "Options:",
      "  --output-dir PATH       Output directory.",
      "                           Default: docs/dev-log/ayumi-santi/sim-slices",
      "  --seed N                Master seed. Default: 20260524.",
      "  --help                  Show this help message.",
      "",
      "This script uses simulated data only. It does not read or fit Ayumi or",
      "Santi's real prepared datasets.",
      sep = "\n"
    ),
    "\n"
  )
}

parse_args <- function(args) {
  opts <- list(
    output_dir = "docs/dev-log/ayumi-santi/sim-slices",
    seed = "20260524",
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

int_opt <- function(value, name) {
  out <- suppressWarnings(as.integer(value))
  if (!is.finite(out) || is.na(out)) {
    stop("--", name, " must be an integer.", call. = FALSE)
  }
  out
}

require_package <- function(package) {
  if (!requireNamespace(package, quietly = TRUE)) {
    stop(
      "Package `",
      package,
      "` is required for this local script.",
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
  suppressPackageStartupMessages(library(drmTMB))
  invisible(TRUE)
}

write_table <- function(dat, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(dat, path, row.names = FALSE, na = "")
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

make_covariance <- function(sd, corr) {
  diag(sd) %*% corr %*% diag(sd)
}

matrix_normal <- function(row_cov, col_cov) {
  row_cov <- as.matrix(row_cov) + diag(1e-8, nrow(row_cov))
  col_cov <- as.matrix(col_cov) + diag(1e-8, nrow(col_cov))
  z <- matrix(stats::rnorm(nrow(row_cov) * nrow(col_cov)), nrow(row_cov))
  t(chol(row_cov)) %*% z %*% chol(col_cov)
}

gradient_max <- function(fit) {
  grad <- tryCatch(fit$obj$gr(fit$opt$par), error = function(e) numeric())
  if (!length(grad)) {
    return(NA_real_)
  }
  max(abs(grad), na.rm = TRUE)
}

first_pair_estimate <- function(fit, patterns) {
  pairs <- tryCatch(corpairs(fit, level = "phylogenetic"), error = function(e) {
    data.frame()
  })
  if (!nrow(pairs)) {
    return(NA_real_)
  }
  text <- apply(pairs, 1L, paste, collapse = " ")
  keep <- rep(TRUE, nrow(pairs))
  for (pattern in patterns) {
    keep <- keep & grepl(pattern, text)
  }
  if (!any(keep)) {
    return(NA_real_)
  }
  pairs$estimate[which(keep)[[1L]]]
}

read_csv_if_exists <- function(path) {
  if (!file.exists(path)) {
    return(data.frame())
  }
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

run_q2_grid <- function(output_dir) {
  grid <- data.frame(
    cell = c("small_strong", "medium_moderate", "default_strong"),
    n_species = c(80L, 140L, 220L),
    phylo_cor = c(-0.55, -0.40, -0.55),
    residual_rho = c(0.15, 0.20, 0.15),
    sd_phylo1 = c(1.20, 0.90, 1.20),
    sd_phylo2 = c(1.00, 0.80, 1.00),
    sigma1 = c(0.25, 0.35, 0.25),
    sigma2 = c(0.25, 0.35, 0.25),
    stringsAsFactors = FALSE
  )
  summaries <- vector("list", nrow(grid))
  for (i in seq_len(nrow(grid))) {
    row <- grid[i, ]
    cell_dir <- file.path(output_dir, "q2-mini-grid", row$cell)
    args <- c(
      "--vanilla",
      "tools/ayumi-santi-q2-positive-control.R",
      "--output-dir",
      cell_dir,
      "--n-species",
      row$n_species,
      "--phylo-cor",
      row$phylo_cor,
      "--residual-rho",
      row$residual_rho,
      "--sd-phylo1",
      row$sd_phylo1,
      "--sd-phylo2",
      row$sd_phylo2,
      "--sigma1",
      row$sigma1,
      "--sigma2",
      row$sigma2,
      "--seed",
      20260524L + i
    )
    log <- system2("Rscript", args, stdout = TRUE, stderr = TRUE)
    writeLines(log, file.path(cell_dir, "positive-control.log"))
    status <- attr(log, "status")
    if (!is.null(status) && !identical(status, 0L)) {
      stop("q2 grid cell failed: ", row$cell, call. = FALSE)
    }
    fit_summary <- read_csv_if_exists(file.path(
      cell_dir,
      "runner-fit",
      "fit-summary.csv"
    ))
    comparison <- read_csv_if_exists(file.path(
      cell_dir,
      "truth-vs-estimate.csv"
    ))
    summaries[[i]] <- data.frame(
      cell = row$cell,
      n_species = row$n_species,
      convergence = fit_summary$convergence[[1L]],
      pdHess = fit_summary$pdHess[[1L]],
      gradient_max = fit_summary$gradient_max[[1L]],
      max_abs_error = max(comparison$abs_error, na.rm = TRUE),
      phylo_cor_error = comparison$abs_error[
        comparison$quantity == "phylo_mu1_mu2_cor"
      ],
      rho12_error = comparison$abs_error[
        comparison$quantity == "residual_rho12"
      ],
      stringsAsFactors = FALSE
    )
  }
  out <- bind_tables(summaries)
  write_table(out, file.path(output_dir, "q2-mini-grid-summary.csv"))
  out
}

run_univariate_plsm <- function(output_dir, seed) {
  set.seed(seed)
  n_species <- 120L
  n_each <- 12L
  tree <- ape::rcoal(n_species)
  tree$tip.label <- paste0("sp_", seq_len(n_species))
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  corr <- matrix(c(1, 0.70, 0.70, 1), nrow = 2L)
  u <- matrix_normal(A, make_covariance(c(mu = 0.90, sigma = 0.55), corr))
  dimnames(u) <- list(tree$tip.label, c("mu", "sigma"))
  species <- rep(tree$tip.label, each = n_each)
  n <- length(species)
  temp <- stats::rnorm(n)
  precip <- stats::rnorm(n)
  eta_mu <- 0.25 + 0.45 * temp - 0.20 * precip + u[species, "mu"]
  eta_sigma <- -1.05 + 0.20 * temp + 0.10 * precip + u[species, "sigma"]
  dat <- data.frame(
    species = species,
    trait = eta_mu + exp(eta_sigma) * stats::rnorm(n),
    temp = temp,
    precip = precip
  )
  fit <- capture_conditions(
    drmTMB(
      bf(
        trait ~ temp + precip + phylo(1 | p | species, tree = tree),
        sigma ~ temp + precip + phylo(1 | p | species, tree = tree)
      ),
      family = gaussian(),
      data = dat
    )
  )
  if (inherits(fit$value, "error")) {
    stop(
      "univariate PLSM fit failed: ",
      conditionMessage(fit$value),
      call. = FALSE
    )
  }
  fit <- fit$value
  slice_dir <- file.path(output_dir, "univariate-plsm")
  dir.create(slice_dir, recursive = TRUE, showWarnings = FALSE)
  saveRDS(fit, file.path(slice_dir, "fit.rds"))
  saveRDS(dat, file.path(slice_dir, "sim-data.rds"))
  saveRDS(tree, file.path(slice_dir, "sim-tree.rds"))
  write_table(dat, file.path(slice_dir, "sim-data.csv"))
  write_table(
    safe_table(corpairs(fit, level = "phylogenetic")),
    file.path(slice_dir, "corpairs.csv")
  )
  write_table(
    safe_table(check_drm(fit)),
    file.path(slice_dir, "check-rows.csv")
  )
  write_table(
    safe_table(profile_targets(fit)),
    file.path(slice_dir, "profile-targets.csv")
  )
  est_cor <- first_pair_estimate(fit, c("phylogenetic", "mu", "sigma"))
  summary <- data.frame(
    slice = "univariate_plsm",
    n_species = n_species,
    n_rows = n,
    truth_mu_sigma_cor = 0.70,
    estimate_mu_sigma_cor = est_cor,
    abs_error = abs(est_cor - 0.70),
    convergence = fit$opt$convergence,
    pdHess = isTRUE(fit$sdr$pdHess),
    gradient_max = gradient_max(fit),
    stringsAsFactors = FALSE
  )
  write_table(summary, file.path(slice_dir, "summary.csv"))
  summary
}

run_q4_positive_control <- function(output_dir, seed) {
  set.seed(20260806L)
  n_tip <- 32L
  n_each <- 16L
  tree <- ape::stree(n_tip, type = "balanced")
  tree$tip.label <- paste0("sp_", seq_len(n_tip))
  tree$edge.length <- rep(1, nrow(tree$edge))
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  sd_phylo <- c(mu1 = 0.75, mu2 = 0.65, sigma1 = 0.45, sigma2 = 0.40)
  corr <- matrix(
    c(
      1.00,
      0.50,
      0.10,
      0.05,
      0.50,
      1.00,
      0.05,
      0.10,
      0.10,
      0.05,
      1.00,
      0.55,
      0.05,
      0.10,
      0.55,
      1.00
    ),
    nrow = 4L,
    byrow = TRUE,
    dimnames = list(names(sd_phylo), names(sd_phylo))
  )
  u <- matrix_normal(A, make_covariance(sd_phylo, corr))
  dimnames(u) <- list(tree$tip.label, names(sd_phylo))
  species <- rep(tree$tip.label, each = n_each)
  n <- length(species)
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  eta_mu1 <- 0.35 + 0.30 * x + u[species, "mu1"]
  eta_mu2 <- -0.20 - 0.25 * x + u[species, "mu2"]
  log_sigma1 <- -1.15 + 0.20 * z + u[species, "sigma1"]
  log_sigma2 <- -1.05 - 0.15 * z + u[species, "sigma2"]
  rho12 <- 0.15
  e1 <- stats::rnorm(n)
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)
  dat <- data.frame(
    y1 = eta_mu1 + exp(log_sigma1) * e1,
    y2 = eta_mu2 + exp(log_sigma2) * e2,
    x = x,
    z = z,
    species = species
  )
  fit <- capture_conditions(
    suppressWarnings(
      drmTMB(
        bf(
          mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
          mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
          sigma1 = ~ z + phylo(1 | p | species, tree = tree),
          sigma2 = ~ z + phylo(1 | p | species, tree = tree),
          rho12 = ~1
        ),
        family = c(gaussian(), gaussian()),
        data = dat,
        control = list(eval.max = 1000, iter.max = 1000)
      )
    )
  )
  if (inherits(fit$value, "error")) {
    stop(
      "q4 positive-control fit failed: ",
      conditionMessage(fit$value),
      call. = FALSE
    )
  }
  fit <- fit$value
  slice_dir <- file.path(output_dir, "q4-positive-control")
  dir.create(slice_dir, recursive = TRUE, showWarnings = FALSE)
  saveRDS(fit, file.path(slice_dir, "fit.rds"))
  write_table(dat, file.path(slice_dir, "sim-data.csv"))
  write_table(
    safe_table(corpairs(fit, level = "phylogenetic", conf.int = TRUE)),
    file.path(slice_dir, "corpairs.csv")
  )
  write_table(
    safe_table(check_drm(fit)),
    file.path(slice_dir, "check-rows.csv")
  )
  write_table(
    safe_table(profile_targets(fit)),
    file.path(slice_dir, "profile-targets.csv")
  )
  pairs <- corpairs(fit, level = "phylogenetic")
  mu_cor <- first_pair_estimate(fit, c("phylogenetic", "mu1", "mu2"))
  scale_cor <- first_pair_estimate(fit, c("phylogenetic", "sigma1", "sigma2"))
  summary <- data.frame(
    slice = "q4_positive_control",
    n_species = n_tip,
    n_rows = n,
    convergence = fit$opt$convergence,
    pdHess = isTRUE(fit$sdr$pdHess),
    gradient_max = gradient_max(fit),
    n_phylo_pairs = nrow(pairs),
    truth_mu1_mu2_cor = corr["mu1", "mu2"],
    estimate_mu1_mu2_cor = mu_cor,
    truth_sigma1_sigma2_cor = corr["sigma1", "sigma2"],
    estimate_sigma1_sigma2_cor = scale_cor,
    rho12_truth = rho12,
    rho12_estimate = unique(rho12(fit))[[1L]],
    stringsAsFactors = FALSE
  )
  write_table(summary, file.path(slice_dir, "summary.csv"))
  summary
}

run_split_fit <- function(output_dir, seed) {
  set.seed(seed)
  n_per_class <- c(terrestrial = 160L, aquatic = 160L, aerial = 160L)
  rhos <- c(terrestrial = -0.75, aquatic = -0.20, aerial = 0.65)
  rows <- list()
  fits <- list()
  for (class in names(n_per_class)) {
    n_species <- n_per_class[[class]]
    tree <- ape::rcoal(n_species)
    tree$tip.label <- paste0(class, "_sp_", seq_len(n_species))
    A <- drmTMB:::drm_phylo_tip_covariance(tree)
    u <- matrix_normal(
      A,
      make_covariance(
        c(1.40, 1.20),
        matrix(c(1, rhos[[class]], rhos[[class]], 1), 2L)
      )
    )
    dimnames(u) <- list(tree$tip.label, c("mu1", "mu2"))
    residual_rho <- 0.10
    e1 <- stats::rnorm(n_species, sd = 0.12)
    e2 <- residual_rho *
      e1 +
      sqrt(1 - residual_rho^2) * stats::rnorm(n_species, sd = 0.12)
    dat <- data.frame(
      lifestyle = class,
      species = tree$tip.label,
      log_body_mass = 1 + u[, "mu1"] + e1,
      log_reproductive_output = 0.2 + u[, "mu2"] + e2,
      stringsAsFactors = FALSE
    )
    fit <- capture_conditions(
      drmTMB(
        bf(
          mu1 = log_body_mass ~ 1 + phylo(1 | p | species, tree = tree),
          mu2 = log_reproductive_output ~ 1 +
            phylo(1 | p | species, tree = tree),
          sigma1 = ~1,
          sigma2 = ~1,
          rho12 = ~1
        ),
        family = biv_gaussian(),
        data = dat
      )
    )
    if (inherits(fit$value, "error")) {
      stop(
        "split fit failed for ",
        class,
        ": ",
        conditionMessage(fit$value),
        call. = FALSE
      )
    }
    fit <- fit$value
    fits[[class]] <- fit
    rows[[class]] <- data.frame(
      class = class,
      n_species = n_species,
      truth_phylo_cor = rhos[[class]],
      estimate_phylo_cor = first_pair_estimate(
        fit,
        c("phylogenetic", "mu1", "mu2")
      ),
      residual_rho12 = unique(rho12(fit))[[1L]],
      convergence = fit$opt$convergence,
      pdHess = isTRUE(fit$sdr$pdHess),
      gradient_max = gradient_max(fit),
      stringsAsFactors = FALSE
    )
  }
  slice_dir <- file.path(output_dir, "split-fit-class-contrast")
  dir.create(slice_dir, recursive = TRUE, showWarnings = FALSE)
  summary <- bind_tables(rows)
  write_table(summary, file.path(slice_dir, "summary.csv"))
  saveRDS(fits, file.path(slice_dir, "fits.rds"))
  summary
}

write_integration_summary <- function(output_dir, results) {
  fmt <- function(x) {
    trimws(formatC(x, digits = 3L, format = "fg"))
  }
  q2 <- results$q2_grid
  univariate <- results$univariate_plsm[1L, ]
  q4 <- results$q4[1L, ]
  split_fit <- results$split_fit
  lines <- c(
    "# Ayumi/Santi Simulation Slice Summary",
    "",
    "These artifacts finish the no-real-data simulation path for the",
    "Ayumi/Santi phylogenetic protocol work.",
    "",
    "## Completed Slices",
    "",
    "1. q2 Objective 1 mini-grid: `q2-mini-grid-summary.csv`.",
    "2. univariate ecogeographic PLSM positive control: `univariate-plsm/summary.csv`.",
    "3. q4 bivariate PLSM diagnostic positive control: `q4-positive-control/summary.csv`.",
    "4. lifestyle/nest-habitat split-fit analogue: `split-fit-class-contrast/summary.csv`.",
    "5. integration summary: this file.",
    "",
    "## Run Highlights",
    "",
    paste0(
      "- q2 mini-grid: ",
      nrow(q2),
      " converged cells, all `pdHess = TRUE`; largest gradient ",
      fmt(max(q2$gradient_max, na.rm = TRUE)),
      "."
    ),
    paste0(
      "- univariate PLSM: truth `mu`-`sigma` phylogenetic correlation ",
      fmt(univariate$truth_mu_sigma_cor),
      ", estimate ",
      fmt(univariate$estimate_mu_sigma_cor),
      ", gradient ",
      fmt(univariate$gradient_max),
      "."
    ),
    paste0(
      "- q4 bivariate PLSM: ",
      q4$n_phylo_pairs,
      " phylogenetic correlation rows, convergence ",
      q4$convergence,
      ", `pdHess = ",
      q4$pdHess,
      "`, gradient ",
      fmt(q4$gradient_max),
      "."
    ),
    paste0(
      "- split-fit class contrast: ",
      paste(split_fit$class, collapse = ", "),
      " all converged with `pdHess = TRUE`."
    ),
    "",
    "## Interpretation Boundary",
    "",
    "All inputs are simulated. These runs test model routes, extraction, and",
    "diagnostic reporting. They do not make biological claims for Ayumi or",
    "Santi's real datasets.",
    "",
    "## Next With Real Data",
    "",
    "Run `tools/ayumi-santi-q2-objective1-runner.R --dry-run true` on the",
    "prepared mammal and avian Objective 1 datasets, then fit one representative",
    "tree for each if the preflight tables are clean."
  )
  writeLines(lines, file.path(output_dir, "README.md"))
  saveRDS(results, file.path(output_dir, "all-results.rds"))
}

main <- function(args = commandArgs(trailingOnly = TRUE)) {
  opts <- parse_args(args)
  if (opts$help) {
    usage()
    return(invisible(NULL))
  }
  require_package("ape")
  load_drmtmb()
  output_dir <- opts$output_dir
  seed <- int_opt(opts$seed, "seed")
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  results <- list(
    q2_grid = run_q2_grid(output_dir),
    univariate_plsm = run_univariate_plsm(output_dir, seed + 10L),
    q4 = run_q4_positive_control(output_dir, seed + 20L),
    split_fit = run_split_fit(output_dir, seed + 30L)
  )
  write_integration_summary(output_dir, results)
  print(results)
  cat(
    "Wrote Ayumi/Santi simulation-slice artifacts to ",
    output_dir,
    "\n",
    sep = ""
  )
  invisible(results)
}

if (identical(environment(), globalenv())) {
  main()
}
