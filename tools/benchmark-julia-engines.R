#!/usr/bin/env Rscript

# Compare native TMB and experimental Julia engines from R.
#
# This is a deliberate benchmark tool, not a package test. Run it from a clean
# Rscript process so the first-call columns have a clear interpretation.

env_value <- function(name, default = "") {
  value <- Sys.getenv(name, unset = NA_character_)
  if (is.na(value) || !nzchar(value)) {
    return(default)
  }
  value
}

env_flag <- function(name, default = FALSE) {
  value <- tolower(env_value(name, if (default) "true" else "false"))
  value %in% c("1", "true", "t", "yes", "y")
}

env_int <- function(name, default) {
  value <- suppressWarnings(as.integer(env_value(name, as.character(default))))
  if (length(value) != 1L || is.na(value)) {
    return(default)
  }
  value
}

env_int_vector <- function(name, default) {
  raw <- env_value(name, paste(default, collapse = ","))
  values <- suppressWarnings(as.integer(strsplit(raw, ",", fixed = TRUE)[[1L]]))
  values <- values[!is.na(values)]
  if (length(values) == 0L) {
    return(default)
  }
  values
}

script_path <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  prefix <- "--file="
  hit <- args[startsWith(args, prefix)]
  if (length(hit) > 0L) {
    return(normalizePath(sub(prefix, "", hit[[1L]]), mustWork = TRUE))
  }
  normalizePath(
    file.path("tools", "benchmark-julia-engines.R"),
    mustWork = FALSE
  )
}

repo_root <- normalizePath(
  file.path(dirname(script_path()), ".."),
  mustWork = TRUE
)
setwd(repo_root)

find_julia_binary <- function() {
  explicit <- env_value("DRMTMB_ENGINE_BENCH_JULIA_BIN", "")
  candidates <- c(
    explicit,
    unname(Sys.which("julia")),
    Sys.glob(file.path(
      Sys.getenv("HOME"),
      ".julia",
      "juliaup",
      "julia-*",
      "bin",
      "julia"
    ))
  )
  candidates <- candidates[nzchar(candidates)]
  hits <- candidates[file.exists(candidates)]
  if (length(hits) == 0L) {
    return("")
  }
  hits[[1L]]
}

configure_julia_binary <- function() {
  julia_bin <- find_julia_binary()
  if (!nzchar(julia_bin)) {
    return("")
  }
  julia_home <- dirname(julia_bin)
  Sys.setenv(
    JULIA_HOME = julia_home,
    PATH = paste(julia_home, Sys.getenv("PATH"), sep = .Platform$path.sep)
  )
  julia_bin
}

julia_bin <- configure_julia_binary()

pin_low_level_threads <- env_flag("DRMTMB_ENGINE_BENCH_PIN_THREADS", TRUE)
if (pin_low_level_threads) {
  Sys.setenv(
    OMP_NUM_THREADS = "1",
    OPENBLAS_NUM_THREADS = "1",
    MKL_NUM_THREADS = "1",
    VECLIB_MAXIMUM_THREADS = "1",
    NUMEXPR_NUM_THREADS = "1"
  )
}

mode <- match.arg(
  env_value("DRMTMB_ENGINE_BENCH_MODE", "both"),
  c("fixed", "phylo", "both")
)
reps <- env_int("DRMTMB_ENGINE_BENCH_REPS", 3L)
fixed_n <- env_int_vector("DRMTMB_ENGINE_BENCH_N", c(100L, 1000L, 10000L))
phylo_n <- env_int_vector("DRMTMB_ENGINE_BENCH_PHYLO_N", c(100L, 1000L, 9993L))
include_first_call <- env_flag("DRMTMB_ENGINE_BENCH_FIRST_CALL", TRUE)
out_dir <- file.path(repo_root, "docs", "dev-log", "benchmarks")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out_csv <- env_value(
  "DRMTMB_ENGINE_BENCH_OUT",
  file.path(out_dir, paste0("r-engine-comparison-", Sys.Date(), ".csv"))
)
out_meta <- sub("\\.csv$", "-metadata.md", out_csv)
if (identical(out_meta, out_csv)) {
  out_meta <- paste0(out_csv, "-metadata.md")
}

require_package <- function(package, why) {
  if (!requireNamespace(package, quietly = TRUE)) {
    stop(
      sprintf("Package {%s} is required to %s.", package, why),
      call. = FALSE
    )
  }
}

require_package("devtools", "load the local drmTMB checkout")
if (mode %in% c("phylo", "both")) {
  require_package("ape", "run the AVONET/Hackett phylogenetic benchmark")
}
if (!requireNamespace("JuliaCall", quietly = TRUE)) {
  stop(
    paste(
      "Package {JuliaCall} is required for engine = \"julia\".",
      "Install it with install.packages(\"JuliaCall\"), then rerun this script."
    ),
    call. = FALSE
  )
}

devtools::load_all(repo_root, quiet = TRUE)
if (pin_low_level_threads && requireNamespace("TMB", quietly = TRUE)) {
  invisible(capture.output(try(TMB::openmp(1L), silent = TRUE)))
}

git_output <- function(args) {
  out <- tryCatch(
    system2("git", args, stdout = TRUE, stderr = TRUE),
    error = function(e) character()
  )
  paste(out, collapse = "\n")
}

package_version_or_na <- function(package) {
  if (!requireNamespace(package, quietly = TRUE)) {
    return(NA_character_)
  }
  as.character(utils::packageVersion(package))
}

reset_julia_bridge_state <- function() {
  namespace <- asNamespace("drmTMB")
  for (name in c("drm_julia_setup_state", "drm_julia_phylo_payload_cache")) {
    if (exists(name, envir = namespace, inherits = FALSE)) {
      state <- get(name, envir = namespace)
      rm(list = ls(state, all.names = TRUE), envir = state)
    }
  }
  invisible(TRUE)
}

make_gaussian_data <- function(n, seed = 20260608L) {
  set.seed(seed + n)
  dat <- data.frame(
    temperature = stats::runif(n, -1.5, 1.5),
    canopy_open = stats::rbinom(n, 1L, 0.5)
  )
  mu <- 8 + 1.2 * dat$temperature + 0.7 * dat$canopy_open
  sigma <- exp(-0.4 + 0.35 * dat$canopy_open)
  dat$growth <- stats::rnorm(n, mean = mu, sd = sigma)
  dat
}

find_avonet_files <- function() {
  candidates <- list(
    list(
      data = file.path("..", "pigauto", "avonet", "AVONET3_BirdTree.csv"),
      tree = file.path(
        "..",
        "pigauto",
        "avonet",
        "Stage2_Hackett_MCC_no_neg.tre"
      )
    ),
    list(
      data = file.path("..", "BACE", "dev", "testing_data", "AVONET.csv"),
      tree = file.path("..", "BACE", "dev", "testing_data", "Hackett_tree.tre")
    )
  )
  for (candidate in candidates) {
    if (file.exists(candidate$data) && file.exists(candidate$tree)) {
      return(candidate)
    }
  }
  stop(
    "AVONET and Hackett tree files were not found in sibling checkouts.",
    call. = FALSE
  )
}

make_positive_branch_lengths <- function(tree, eps = 1e-8) {
  tree$edge.length <- pmax(tree$edge.length, eps)
  tree
}

make_avonet_phylo_data <- function(n_species = NULL) {
  paths <- find_avonet_files()
  avonet <- utils::read.csv(paths$data, check.names = FALSE)
  tree0 <- ape::read.tree(paths$tree)

  dat0 <- data.frame(
    species = gsub(" ", "_", avonet$Species3, fixed = TRUE),
    mass = avonet$Mass,
    hand_wing = avonet[["Hand-Wing.Index"]],
    beak = avonet[["Beak.Length_Culmen"]]
  )
  dat0 <- dat0[stats::complete.cases(dat0), , drop = FALSE]
  available <- tree0$tip.label[tree0$tip.label %in% dat0$species]
  if (!is.null(n_species)) {
    if (n_species > length(available)) {
      stop(
        sprintf(
          "Requested %s AVONET species, but only %s complete species are available.",
          n_species,
          length(available)
        ),
        call. = FALSE
      )
    }
    available <- available[seq_len(n_species)]
  }

  tree <- make_positive_branch_lengths(ape::keep.tip(tree0, available))
  dat <- dat0[match(tree$tip.label, dat0$species), , drop = FALSE]
  dat$species <- factor(dat$species, levels = tree$tip.label)
  dat$log_mass <- log(dat$mass)
  dat$hand_wing_z <- as.numeric(scale(dat$hand_wing))
  dat$beak_z <- as.numeric(scale(dat$beak))

  list(data = dat, tree = tree, source = paths)
}

time_fit <- function(fit_call) {
  gc()
  elapsed <- system.time(fit <- fit_call())[["elapsed"]]
  list(fit = fit, elapsed = unname(elapsed))
}

time_reps <- function(fit_call, reps) {
  times <- numeric(reps)
  fit <- NULL
  for (i in seq_len(reps)) {
    result <- time_fit(fit_call)
    times[[i]] <- result$elapsed
    fit <- result$fit
  }
  list(times = times, fit = fit)
}

flatten_numeric <- function(x) {
  as.numeric(unlist(x, use.names = FALSE))
}

coef_vector <- function(fit) {
  unlist(stats::coef(fit), use.names = TRUE)
}

max_common_coef_diff <- function(fit_a, fit_b) {
  coef_a <- coef_vector(fit_a)
  coef_b <- coef_vector(fit_b)
  common <- intersect(names(coef_a), names(coef_b))
  if (length(common) == 0L) {
    return(NA_real_)
  }
  max(abs(coef_a[common] - coef_b[common]), na.rm = TRUE)
}

max_response_diff <- function(fun, fit_a, fit_b) {
  value_a <- flatten_numeric(fun(fit_a))
  value_b <- flatten_numeric(fun(fit_b))
  if (length(value_a) == 0L || length(value_b) == 0L) {
    return(NA_real_)
  }
  max(abs(value_a - value_b), na.rm = TRUE)
}

phylo_sd_value <- function(fit) {
  vals <- unlist(fit$sdpars$mu, use.names = FALSE)
  if (length(vals) == 0L) {
    return(NA_real_)
  }
  as.numeric(vals[[1L]])
}

convergence_code <- function(fit) {
  if (!is.null(fit$opt$convergence)) {
    return(as.integer(fit$opt$convergence))
  }
  as.integer(!is_converged(fit))
}

uncertainty_status <- function(fit) {
  if (!is.null(fit$uncertainty$status)) {
    return(fit$uncertainty$status)
  }
  NA_character_
}

finite_dpars <- function(fit) {
  value <- fit$uncertainty$finite_dpars
  if (is.null(value) || length(value) == 0L) {
    return(NA_character_)
  }
  paste(value, collapse = ";")
}

benchmark_pair <- function(label, n, rows, species, make_tmb, make_julia) {
  message(sprintf("Benchmarking %s, n = %s, reps = %s", label, n, reps))
  tmb_first <- list(fit = NULL, elapsed = NA_real_)
  julia_first <- list(fit = NULL, elapsed = NA_real_)

  if (include_first_call) {
    reset_julia_bridge_state()
    tmb_first <- time_fit(make_tmb)
    reset_julia_bridge_state()
    julia_first <- time_fit(make_julia)
  } else {
    invisible(make_tmb())
    invisible(make_julia())
  }

  tmb_warm <- time_reps(make_tmb, reps)
  julia_warm <- time_reps(make_julia, reps)
  fit_tmb <- tmb_warm$fit
  fit_julia <- julia_warm$fit

  tmb_median <- stats::median(tmb_warm$times)
  julia_median <- stats::median(julia_warm$times)
  data.frame(
    model = label,
    n = n,
    rows = rows,
    species = species,
    reps = reps,
    tmb_first_call_s = tmb_first$elapsed,
    julia_first_call_s = julia_first$elapsed,
    tmb_warm_median_s = tmb_median,
    julia_warm_median_s = julia_median,
    tmb_warm_min_s = min(tmb_warm$times),
    julia_warm_min_s = min(julia_warm$times),
    speedup_warm_tmb_over_julia = tmb_median / julia_median,
    logLik_tmb = as.numeric(stats::logLik(fit_tmb)),
    logLik_julia = as.numeric(stats::logLik(fit_julia)),
    logLik_diff = abs(
      as.numeric(stats::logLik(fit_tmb)) -
        as.numeric(stats::logLik(fit_julia))
    ),
    max_common_coef_diff = max_common_coef_diff(fit_tmb, fit_julia),
    max_fitted_diff = max_response_diff(stats::fitted, fit_tmb, fit_julia),
    max_sigma_diff = max_response_diff(stats::sigma, fit_tmb, fit_julia),
    sd_phylo_tmb = phylo_sd_value(fit_tmb),
    sd_phylo_julia = phylo_sd_value(fit_julia),
    sd_phylo_diff = abs(phylo_sd_value(fit_tmb) - phylo_sd_value(fit_julia)),
    tmb_convergence = convergence_code(fit_tmb),
    julia_convergence = convergence_code(fit_julia),
    tmb_uncertainty = uncertainty_status(fit_tmb),
    julia_uncertainty = uncertainty_status(fit_julia),
    julia_finite_dpars = finite_dpars(fit_julia),
    tmb_backend = "R drmTMB/TMB default",
    julia_backend = "R drmTMB/JuliaCall/DRM.jl default",
    backend_scope = "single R process; JuliaCall starts or reuses one Julia runtime",
    first_call_scope = paste(
      "first call in this R process after clearing R-side bridge state;",
      "only the first Julia row includes Julia runtime setup"
    ),
    stringsAsFactors = FALSE
  )
}

bench_fixed_gaussian <- function(n) {
  dat <- make_gaussian_data(n)
  form <- bf(growth ~ temperature + canopy_open, sigma ~ canopy_open)
  benchmark_pair(
    label = "fixed Gaussian",
    n = n,
    rows = nrow(dat),
    species = NA_integer_,
    make_tmb = function() {
      drmTMB(form, family = stats::gaussian(), data = dat, engine = "tmb")
    },
    make_julia = function() {
      drmTMB(form, family = stats::gaussian(), data = dat, engine = "julia")
    }
  )
}

bench_phylo_gaussian <- function(n) {
  av <- make_avonet_phylo_data(n_species = n)
  tree <- av$tree
  form <- bf(
    log_mass ~ hand_wing_z + beak_z + phylo(1 | species, tree = tree),
    sigma ~ 1
  )
  benchmark_pair(
    label = "AVONET phylogenetic Gaussian",
    n = n,
    rows = nrow(av$data),
    species = nrow(av$data),
    make_tmb = function() {
      drmTMB(form, family = stats::gaussian(), data = av$data, engine = "tmb")
    },
    make_julia = function() {
      drmTMB(form, family = stats::gaussian(), data = av$data, engine = "julia")
    }
  )
}

rows <- list()
if (mode %in% c("fixed", "both")) {
  rows <- c(rows, lapply(fixed_n, bench_fixed_gaussian))
}
if (mode %in% c("phylo", "both")) {
  rows <- c(rows, lapply(phylo_n, bench_phylo_gaussian))
}
bench <- do.call(rbind, rows)
utils::write.csv(bench, out_csv, row.names = FALSE)

metadata <- c(
  "# R Engine Comparison Benchmark Metadata",
  "",
  paste0("- timestamp: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  paste0("- repo: ", repo_root),
  paste0("- git_head: ", git_output(c("rev-parse", "--short", "HEAD"))),
  paste0("- git_status_short: |"),
  paste0(
    "  ",
    strsplit(git_output(c("status", "--short")), "\n", fixed = TRUE)[[1L]]
  ),
  paste0("- R: ", R.version.string),
  paste0("- platform: ", R.version$platform),
  paste0("- drmTMB_version: ", package_version_or_na("drmTMB")),
  paste0("- TMB_version: ", package_version_or_na("TMB")),
  paste0("- JuliaCall_version: ", package_version_or_na("JuliaCall")),
  paste0("- ape_version: ", package_version_or_na("ape")),
  paste0("- julia_bin: ", julia_bin),
  paste0("- mode: ", mode),
  paste0("- reps: ", reps),
  paste0("- fixed_n: ", paste(fixed_n, collapse = ",")),
  paste0("- phylo_n: ", paste(phylo_n, collapse = ",")),
  paste0("- include_first_call: ", include_first_call),
  paste0("- pin_low_level_threads: ", pin_low_level_threads),
  paste0("- OMP_NUM_THREADS: ", Sys.getenv("OMP_NUM_THREADS", unset = "")),
  paste0(
    "- OPENBLAS_NUM_THREADS: ",
    Sys.getenv("OPENBLAS_NUM_THREADS", unset = "")
  ),
  paste0("- MKL_NUM_THREADS: ", Sys.getenv("MKL_NUM_THREADS", unset = "")),
  paste0(
    "- VECLIB_MAXIMUM_THREADS: ",
    Sys.getenv("VECLIB_MAXIMUM_THREADS", unset = "")
  ),
  paste0("- DRM_JL_PATH: ", Sys.getenv("DRM_JL_PATH", unset = "")),
  paste0("- output_csv: ", out_csv),
  "",
  "First-call timing is not an operating-system cold-start benchmark after the",
  "first Julia row. It means the first fit in this R process after clearing",
  "the R-side Julia bridge state. Warm timing rows are repeated fits in the",
  "same R process."
)
writeLines(metadata, out_meta)

message("Wrote benchmark CSV: ", out_csv)
message("Wrote benchmark metadata: ", out_meta)
