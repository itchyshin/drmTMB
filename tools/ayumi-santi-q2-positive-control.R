#!/usr/bin/env Rscript

# Small positive-control simulation for the Ayumi/Santi Objective 1 q2
# phylogenetic runner. It simulates prepared species-level data, then calls the
# same runner used for real mammal or avian protocol datasets.

usage <- function() {
  cat(
    paste(
      "Usage: Rscript tools/ayumi-santi-q2-positive-control.R [options]",
      "",
      "Options:",
      "  --output-dir PATH       Output directory.",
      "                           Default: docs/dev-log/ayumi-santi/q2-objective1/sim-positive-control",
      "  --n-species N           Number of simulated species. Default: 220.",
      "  --seed N                Master seed. Default: 20260524.",
      "  --phylo-cor VALUE       True phylogenetic mu1-mu2 correlation. Default: -0.55.",
      "  --residual-rho VALUE    True residual rho12. Default: 0.15.",
      "  --sd-phylo1 VALUE       True phylogenetic SD for response 1. Default: 1.20.",
      "  --sd-phylo2 VALUE       True phylogenetic SD for response 2. Default: 1.00.",
      "  --sigma1 VALUE          True residual SD for response 1. Default: 0.25.",
      "  --sigma2 VALUE          True residual SD for response 2. Default: 0.25.",
      "  --se true|false         Ask the runner for standard errors. Default: true.",
      "  --help                  Show this help message.",
      "",
      "The simulated columns are species, log_body_mass, and log_reproductive_output.",
      "The fitted formula is the Objective 1 q2 model, with phylo() in mu1 and",
      "mu2 only and residual rho12 kept as a separate correlation layer.",
      sep = "\n"
    ),
    "\n"
  )
}

parse_args <- function(args) {
  opts <- list(
    output_dir = "docs/dev-log/ayumi-santi/q2-objective1/sim-positive-control",
    n_species = "220",
    seed = "20260524",
    phylo_cor = "-0.55",
    residual_rho = "0.15",
    sd_phylo1 = "1.20",
    sd_phylo2 = "1.00",
    sigma1 = "0.25",
    sigma2 = "0.25",
    se = "true",
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

num_opt <- function(value, name) {
  out <- suppressWarnings(as.numeric(value))
  if (!is.finite(out) || is.na(out)) {
    stop("--", name, " must be finite.", call. = FALSE)
  }
  out
}

int_opt <- function(value, name) {
  out <- suppressWarnings(as.integer(value))
  if (!is.finite(out) || is.na(out) || out <= 1L) {
    stop("--", name, " must be an integer greater than 1.", call. = FALSE)
  }
  out
}

cor_opt <- function(value, name) {
  out <- num_opt(value, name)
  if (abs(out) >= 1) {
    stop("--", name, " must be strictly between -1 and 1.", call. = FALSE)
  }
  out
}

positive_opt <- function(value, name) {
  out <- num_opt(value, name)
  if (out <= 0) {
    stop("--", name, " must be positive.", call. = FALSE)
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

make_covariance <- function(sd1, sd2, rho) {
  matrix(
    c(sd1^2, rho * sd1 * sd2, rho * sd1 * sd2, sd2^2),
    nrow = 2L
  )
}

simulate_matrix_normal <- function(row_cov, col_cov) {
  row_cov <- as.matrix(row_cov)
  col_cov <- as.matrix(col_cov)
  row_cov <- row_cov + diag(1e-8, nrow(row_cov))
  col_cov <- col_cov + diag(1e-8, nrow(col_cov))
  z <- matrix(stats::rnorm(nrow(row_cov) * nrow(col_cov)), nrow(row_cov))
  l_row <- t(chol(row_cov))
  l_row %*% z %*% chol(col_cov)
}

write_table <- function(dat, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(dat, path, row.names = FALSE, na = "")
}

first_matching_estimate <- function(dat, patterns) {
  if (!is.data.frame(dat) || !nrow(dat)) {
    return(NA_real_)
  }
  text <- apply(dat, 1L, paste, collapse = " ")
  keep <- rep(TRUE, nrow(dat))
  for (pattern in patterns) {
    keep <- keep & grepl(pattern, text)
  }
  if (!any(keep) || !"estimate" %in% names(dat)) {
    return(NA_real_)
  }
  as.numeric(dat$estimate[which(keep)[[1L]]])
}

read_csv_if_exists <- function(path) {
  if (!file.exists(path)) {
    return(data.frame())
  }
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

write_comparison <- function(output_dir, truth) {
  runner_dir <- file.path(output_dir, "runner-fit")
  pairs <- read_csv_if_exists(file.path(runner_dir, "corpairs.csv"))
  rho <- read_csv_if_exists(file.path(runner_dir, "rho12-summary.csv"))
  sdpars <- read_csv_if_exists(file.path(runner_dir, "sdpars.csv"))
  fit_summary <- read_csv_if_exists(file.path(runner_dir, "fit-summary.csv"))

  phylo_cor_hat <- first_matching_estimate(
    pairs,
    c("phylogenetic", "mu1", "mu2")
  )
  sd1_hat <- first_matching_estimate(sdpars, c("mu1", "phylo"))
  sd2_hat <- first_matching_estimate(sdpars, c("mu2", "phylo"))
  rho_hat <- if (nrow(rho) && "mean" %in% names(rho)) {
    rho$mean[[1L]]
  } else {
    NA_real_
  }

  out <- data.frame(
    quantity = c(
      "phylo_mu1_mu2_cor",
      "residual_rho12",
      "sd_phylo_mu1",
      "sd_phylo_mu2"
    ),
    truth = c(
      truth$phylo_cor,
      truth$residual_rho,
      truth$sd_phylo1,
      truth$sd_phylo2
    ),
    estimate = c(phylo_cor_hat, rho_hat, sd1_hat, sd2_hat),
    abs_error = abs(c(
      phylo_cor_hat - truth$phylo_cor,
      rho_hat - truth$residual_rho,
      sd1_hat - truth$sd_phylo1,
      sd2_hat - truth$sd_phylo2
    )),
    stringsAsFactors = FALSE
  )
  write_table(out, file.path(output_dir, "truth-vs-estimate.csv"))

  if (nrow(fit_summary)) {
    write_table(fit_summary, file.path(output_dir, "fit-summary-copy.csv"))
  }
  invisible(out)
}

run_runner <- function(output_dir, data_path, tree_path, se) {
  runner <- file.path("tools", "ayumi-santi-q2-objective1-runner.R")
  args <- c(
    "--vanilla",
    runner,
    "--data",
    data_path,
    "--tree",
    tree_path,
    "--species",
    "species",
    "--response1",
    "log_body_mass",
    "--response2",
    "log_reproductive_output",
    "--label",
    "sim_positive_control",
    "--output-dir",
    file.path(output_dir, "runner-fit"),
    "--se",
    if (se) "true" else "false"
  )
  status <- system2("Rscript", args, stdout = TRUE, stderr = TRUE)
  writeLines(status, file.path(output_dir, "runner.log"))
  status_code <- attr(status, "status")
  if (!is.null(status_code) && !identical(status_code, 0L)) {
    stop(
      "Objective 1 runner failed with status ",
      status_code,
      "; see runner.log.",
      call. = FALSE
    )
  }
  invisible(status)
}

main <- function(args = commandArgs(trailingOnly = TRUE)) {
  opts <- parse_args(args)
  if (opts$help) {
    usage()
    return(invisible(NULL))
  }

  require_package("ape")

  output_dir <- opts$output_dir
  n_species <- int_opt(opts$n_species, "n-species")
  seed <- int_opt(opts$seed, "seed")
  phylo_cor <- cor_opt(opts$phylo_cor, "phylo-cor")
  residual_rho <- cor_opt(opts$residual_rho, "residual-rho")
  sd_phylo1 <- positive_opt(opts$sd_phylo1, "sd-phylo1")
  sd_phylo2 <- positive_opt(opts$sd_phylo2, "sd-phylo2")
  sigma1 <- positive_opt(opts$sigma1, "sigma1")
  sigma2 <- positive_opt(opts$sigma2, "sigma2")
  se <- bool_opt(opts$se, "se")

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  set.seed(seed)
  tree <- ape::rcoal(n_species)
  tree$tip.label <- paste0("sp_", seq_len(n_species))
  phylo_cor_mat <- ape::vcv.phylo(tree, corr = TRUE)
  phylo_sigma <- make_covariance(sd_phylo1, sd_phylo2, phylo_cor)
  residual_sigma <- make_covariance(sigma1, sigma2, residual_rho)
  u <- simulate_matrix_normal(phylo_cor_mat, phylo_sigma)
  e <- matrix(stats::rnorm(n_species * 2L), n_species) %*% chol(residual_sigma)
  y <- sweep(u + e, 2L, c(1.5, 0.4), "+")

  dat <- data.frame(
    species = tree$tip.label,
    log_body_mass = y[, 1L],
    log_reproductive_output = y[, 2L],
    stringsAsFactors = FALSE
  )
  truth <- data.frame(
    item = c(
      "n_species",
      "seed",
      "phylo_cor",
      "residual_rho",
      "sd_phylo1",
      "sd_phylo2",
      "sigma1",
      "sigma2"
    ),
    value = c(
      n_species,
      seed,
      phylo_cor,
      residual_rho,
      sd_phylo1,
      sd_phylo2,
      sigma1,
      sigma2
    )
  )
  data_path <- file.path(output_dir, "sim-data.rds")
  tree_path <- file.path(output_dir, "sim-tree.rds")
  saveRDS(dat, data_path)
  saveRDS(tree, tree_path)
  write_table(dat, file.path(output_dir, "sim-data.csv"))
  write_table(truth, file.path(output_dir, "truth.csv"))

  run_runner(output_dir, data_path, tree_path, se = se)
  comparison <- write_comparison(
    output_dir,
    list(
      phylo_cor = phylo_cor,
      residual_rho = residual_rho,
      sd_phylo1 = sd_phylo1,
      sd_phylo2 = sd_phylo2
    )
  )
  print(comparison)
  cat("Wrote q2 positive-control artifacts to ", output_dir, "\n", sep = "")
  invisible(comparison)
}

if (identical(environment(), globalenv())) {
  main()
}
