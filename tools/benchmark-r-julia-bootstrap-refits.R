#!/usr/bin/env Rscript

# Benchmark bootstrap/profile repeated inference for the current Julia bridge.
#
# This script deliberately lives in tools/: it compares public native
# confint(), public Julia-engine confint(), and optional development-only
# bridge/direct-DRM.jl rows.

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

env_logical_vector <- function(name, default) {
  raw <- tolower(env_value(name, paste(default, collapse = ",")))
  values <- trimws(strsplit(raw, ",", fixed = TRUE)[[1L]])
  out <- values %in% c("1", "true", "t", "yes", "y")
  ok <- values %in%
    c(
      "1",
      "true",
      "t",
      "yes",
      "y",
      "0",
      "false",
      "f",
      "no",
      "n"
    )
  out <- out[ok]
  if (length(out) == 0L) {
    return(default)
  }
  unique(out)
}

script_path <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  prefix <- "--file="
  hit <- args[startsWith(args, prefix)]
  if (length(hit) > 0L) {
    return(normalizePath(sub(prefix, "", hit[[1L]]), mustWork = TRUE))
  }
  normalizePath(
    file.path("tools", "benchmark-r-julia-bootstrap-refits.R"),
    mustWork = FALSE
  )
}

repo_root <- normalizePath(
  file.path(dirname(script_path()), ".."),
  mustWork = TRUE
)
setwd(repo_root)

find_julia_binary <- function() {
  explicit <- env_value("DRMTMB_BOOT_BENCH_JULIA_BIN", "")
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

pin_low_level_threads <- env_flag("DRMTMB_BOOT_BENCH_PIN_THREADS", TRUE)
if (pin_low_level_threads) {
  Sys.setenv(
    OMP_NUM_THREADS = "1",
    OPENBLAS_NUM_THREADS = "1",
    MKL_NUM_THREADS = "1",
    VECLIB_MAXIMUM_THREADS = "1",
    NUMEXPR_NUM_THREADS = "1"
  )
}

B <- env_int("DRMTMB_BOOT_BENCH_B", 10L)
n_species <- env_int("DRMTMB_BOOT_BENCH_SPECIES", 1000L)
seed <- env_int("DRMTMB_BOOT_BENCH_SEED", 20260609L)
r_workers <- unique(env_int_vector("DRMTMB_BOOT_BENCH_R_WORKERS", c(1L, 4L)))
run_julia_confint <- env_flag("DRMTMB_BOOT_BENCH_RUN_JULIA_CONFINT", TRUE)
julia_confint_thread_modes <- env_logical_vector(
  "DRMTMB_BOOT_BENCH_JULIA_CONFINT_THREADS",
  c(FALSE, TRUE)
)
run_julia_bridge <- env_flag("DRMTMB_BOOT_BENCH_RUN_JULIA_BRIDGE", FALSE)
run_profile <- env_flag("DRMTMB_BOOT_BENCH_RUN_PROFILE", FALSE)
profile_workers <- unique(
  env_int_vector("DRMTMB_BOOT_BENCH_PROFILE_WORKERS", r_workers)
)
run_direct_julia <- env_flag("DRMTMB_BOOT_BENCH_RUN_DIRECT_JULIA", FALSE)
direct_julia_threads <- unique(
  env_int_vector("DRMTMB_BOOT_BENCH_DIRECT_JULIA_THREADS", 4L)
)
direct_julia_B <- env_int("DRMTMB_BOOT_BENCH_DIRECT_B", B)

out_dir <- file.path(repo_root, "docs", "dev-log", "benchmarks")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out_csv <- env_value(
  "DRMTMB_BOOT_BENCH_OUT",
  file.path(out_dir, paste0("r-julia-bootstrap-refits-", Sys.Date(), ".csv"))
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
require_package("ape", "run the AVONET/Hackett phylogenetic benchmark")
if (run_julia_confint || run_julia_bridge) {
  require_package("JuliaCall", "run Julia-engine inference rows")
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

phylo_sd_value <- function(fit) {
  vals <- unlist(fit$sdpars$mu, use.names = FALSE)
  if (length(vals) == 0L) {
    return(NA_real_)
  }
  as.numeric(vals[[1L]])
}

common_result_columns <- function(row) {
  row$julia_threaded <- NA
  row$julia_workers <- NA_integer_
  row$julia_threads <- NA_integer_
  row$julia_blas_threads <- NA_integer_
  row
}

convergence_code <- function(fit) {
  if (!is.null(fit$opt$convergence)) {
    return(as.integer(fit$opt$convergence))
  }
  as.integer(!is_converged(fit))
}

bootstrap_interval_from_draws <- function(draws, level) {
  ok <- is.finite(draws$estimate) & draws$converged
  if (sum(ok) < 2L) {
    return(c(lower = NA_real_, upper = NA_real_))
  }
  probs <- c((1 - level) / 2, (1 + level) / 2)
  stats::quantile(draws$estimate[ok], probs = probs, names = FALSE, type = 7)
}

benchmark_r_bootstrap <- function(fit, target, workers, level) {
  backend <- if (workers <= 1L) "none" else "multicore"
  label <- if (identical(backend, "none")) {
    "R native bootstrap serial"
  } else {
    "R native bootstrap multicore"
  }
  message(sprintf("Running %s, B = %s, workers = %s", label, B, workers))
  elapsed <- system.time(
    ci <- stats::confint(
      fit,
      parm = target,
      method = "bootstrap",
      R = B,
      seed = seed,
      parallel = backend,
      workers = workers
    )
  )[["elapsed"]]
  common_result_columns(data.frame(
    task = "bootstrap",
    route = label,
    model = "AVONET phylogenetic Gaussian",
    species = n_species,
    rows = stats::nobs(fit),
    B = B,
    backend = backend,
    process_model = if (identical(backend, "none")) {
      "single R process"
    } else {
      "forked R worker processes"
    },
    workers = unique(ci$bootstrap.workers)[[1L]],
    requested_workers = workers,
    elapsed_s = unname(elapsed),
    sec_per_refit = unname(elapsed) / B,
    first_call_s = NA_real_,
    used = unique(ci$bootstrap.n)[[1L]],
    failed = unique(ci$bootstrap.failed)[[1L]],
    lower = ci$lower[[1L]],
    upper = ci$upper[[1L]],
    target = target,
    status = ci$conf.status[[1L]],
    message = ci$profile.message[[1L]],
    comparison_scope = "public confint bootstrap; native TMB refits",
    direct_report = NA_character_,
    stringsAsFactors = FALSE
  ))
}

benchmark_r_profile <- function(fit, target, workers, level) {
  backend <- if (workers <= 1L) "none" else "multicore"
  label <- if (identical(backend, "none")) {
    "R native profile serial"
  } else {
    "R native profile multicore"
  }
  message(sprintf("Running %s, workers = %s", label, workers))
  ci <- NULL
  elapsed <- system.time(
    ci <- tryCatch(
      stats::confint(
        fit,
        parm = target,
        level = level,
        method = "profile",
        profile_engine = "endpoint",
        parallel = backend,
        workers = workers
      ),
      error = function(err) err
    )
  )[["elapsed"]]
  if (inherits(ci, "error")) {
    return(common_result_columns(data.frame(
      task = "profile",
      route = label,
      model = "AVONET phylogenetic Gaussian",
      species = n_species,
      rows = stats::nobs(fit),
      B = NA_integer_,
      backend = backend,
      process_model = if (identical(backend, "none")) {
        "single R process"
      } else {
        "forked R endpoint worker processes"
      },
      workers = if (identical(backend, "none")) 1L else min(2L, workers),
      requested_workers = workers,
      elapsed_s = unname(elapsed),
      sec_per_refit = NA_real_,
      first_call_s = NA_real_,
      used = 0L,
      failed = 1L,
      lower = NA_real_,
      upper = NA_real_,
      target = target,
      status = "error",
      message = conditionMessage(ci),
      comparison_scope = "public confint profile endpoint; native TMB objective",
      direct_report = NA_character_,
      stringsAsFactors = FALSE
    )))
  }

  actual_workers <- if ("endpoint_workers" %in% names(ci)) {
    unique(ci$endpoint_workers)[[1L]]
  } else if (identical(backend, "none")) {
    1L
  } else {
    min(2L, workers)
  }
  common_result_columns(data.frame(
    task = "profile",
    route = label,
    model = "AVONET phylogenetic Gaussian",
    species = n_species,
    rows = stats::nobs(fit),
    B = NA_integer_,
    backend = backend,
    process_model = if (identical(backend, "none")) {
      "single R process"
    } else {
      "forked R endpoint worker processes"
    },
    workers = actual_workers,
    requested_workers = workers,
    elapsed_s = unname(elapsed),
    sec_per_refit = NA_real_,
    first_call_s = NA_real_,
    used = 1L,
    failed = 0L,
    lower = ci$lower[[1L]],
    upper = ci$upper[[1L]],
    target = target,
    status = ci$conf.status[[1L]],
    message = ci$profile.message[[1L]],
    comparison_scope = "public confint profile endpoint; native TMB objective",
    direct_report = NA_character_,
    stringsAsFactors = FALSE
  ))
}

benchmark_julia_public_confint <- function(form, dat, target, level, threads) {
  label_suffix <- if (isTRUE(threads)) "threaded" else "serial"
  message(sprintf(
    "Running Julia public confint rows, threads = %s",
    label_suffix
  ))
  first <- time_fit(function() {
    drmTMB(form, family = stats::gaussian(), data = dat, engine = "julia")
  })
  fit <- first$fit
  julia_targets <- profile_targets(fit)
  julia_target <- grep("^sd:mu:phylo", julia_targets$parm, value = TRUE)[[1L]]

  rows <- list()
  elapsed <- system.time(
    boot <- stats::confint(
      fit,
      parm = julia_target,
      method = "bootstrap",
      R = B,
      seed = seed,
      threads = threads
    )
  )[["elapsed"]]
  rows[[length(rows) + 1L]] <- data.frame(
    task = "bootstrap",
    route = paste("Julia public confint bootstrap", label_suffix),
    model = "AVONET phylogenetic Gaussian",
    species = n_species,
    rows = stats::nobs(fit),
    B = B,
    backend = if (isTRUE(threads)) "Julia threads" else "Julia serial",
    process_model = if (isTRUE(threads)) {
      "one Julia process with shared-memory threads"
    } else {
      "one Julia process, one bootstrap worker"
    },
    workers = boot$julia.workers[[1L]],
    requested_workers = if (isTRUE(threads)) {
      boot$julia.threads[[1L]]
    } else {
      1L
    },
    elapsed_s = unname(elapsed),
    sec_per_refit = unname(elapsed) / B,
    first_call_s = first$elapsed,
    used = boot$bootstrap.n[[1L]],
    failed = boot$bootstrap.failed[[1L]],
    lower = boot$lower[[1L]],
    upper = boot$upper[[1L]],
    target = target,
    status = boot$conf.status[[1L]],
    message = boot$profile.message[[1L]],
    comparison_scope = "public confint bootstrap; Julia-engine bridge primitive",
    direct_report = NA_character_,
    julia_threaded = boot$julia.threaded[[1L]],
    julia_workers = boot$julia.workers[[1L]],
    julia_threads = boot$julia.threads[[1L]],
    julia_blas_threads = boot$julia.blas_threads[[1L]],
    stringsAsFactors = FALSE
  )

  if (run_profile) {
    elapsed <- system.time(
      prof <- tryCatch(
        stats::confint(
          fit,
          parm = julia_target,
          method = "profile",
          level = level,
          threads = threads
        ),
        error = function(err) err
      )
    )[["elapsed"]]
    if (inherits(prof, "error")) {
      rows[[length(rows) + 1L]] <- data.frame(
        task = "profile",
        route = paste("Julia public confint profile", label_suffix),
        model = "AVONET phylogenetic Gaussian",
        species = n_species,
        rows = stats::nobs(fit),
        B = NA_integer_,
        backend = if (isTRUE(threads)) "Julia threads" else "Julia serial",
        process_model = if (isTRUE(threads)) {
          "one Julia process with shared-memory threads"
        } else {
          "one Julia process, one profile worker"
        },
        workers = if (isTRUE(threads)) {
          min(2L, boot$julia.threads[[1L]])
        } else {
          1L
        },
        requested_workers = if (isTRUE(threads)) {
          boot$julia.threads[[1L]]
        } else {
          1L
        },
        elapsed_s = unname(elapsed),
        sec_per_refit = NA_real_,
        first_call_s = first$elapsed,
        used = 0L,
        failed = 1L,
        lower = NA_real_,
        upper = NA_real_,
        target = target,
        status = "profile_unavailable",
        message = gsub("\\s+", " ", conditionMessage(prof)),
        comparison_scope = paste(
          "public confint profile; Julia bridge blocked because",
          "sparse-profile parity is not established"
        ),
        direct_report = NA_character_,
        julia_threaded = isTRUE(threads),
        julia_workers = if (isTRUE(threads)) {
          min(2L, boot$julia.threads[[1L]])
        } else {
          1L
        },
        julia_threads = boot$julia.threads[[1L]],
        julia_blas_threads = boot$julia.blas_threads[[1L]],
        stringsAsFactors = FALSE
      )
      return(do.call(rbind, rows))
    }
    rows[[length(rows) + 1L]] <- data.frame(
      task = "profile",
      route = paste("Julia public confint profile", label_suffix),
      model = "AVONET phylogenetic Gaussian",
      species = n_species,
      rows = stats::nobs(fit),
      B = NA_integer_,
      backend = if (isTRUE(threads)) "Julia threads" else "Julia serial",
      process_model = if (isTRUE(threads)) {
        "one Julia process with shared-memory threads"
      } else {
        "one Julia process, one profile worker"
      },
      workers = prof$julia.workers[[1L]],
      requested_workers = if (isTRUE(threads)) {
        prof$julia.threads[[1L]]
      } else {
        1L
      },
      elapsed_s = unname(elapsed),
      sec_per_refit = NA_real_,
      first_call_s = first$elapsed,
      used = 1L,
      failed = 0L,
      lower = prof$lower[[1L]],
      upper = prof$upper[[1L]],
      target = target,
      status = prof$conf.status[[1L]],
      message = prof$profile.message[[1L]],
      comparison_scope = "public confint profile; Julia-engine bridge primitive",
      direct_report = NA_character_,
      julia_threaded = prof$julia.threaded[[1L]],
      julia_workers = prof$julia.workers[[1L]],
      julia_threads = prof$julia.threads[[1L]],
      julia_blas_threads = prof$julia.blas_threads[[1L]],
      stringsAsFactors = FALSE
    )
  }

  do.call(rbind, rows)
}

benchmark_julia_bridge_loop <- function(form, dat, simulations, target, level) {
  message(sprintf("Running Julia bridge refit loop, B = %s", B))
  first <- time_fit(function() {
    drmTMB(form, family = stats::gaussian(), data = dat, engine = "julia")
  })
  draws <- vector("list", B)
  elapsed <- system.time({
    for (i in seq_len(B)) {
      dat_i <- dat
      dat_i$log_mass <- simulations[[i]]
      fit_i <- tryCatch(
        drmTMB(
          form,
          family = stats::gaussian(),
          data = dat_i,
          engine = "julia"
        ),
        error = function(err) err
      )
      if (inherits(fit_i, "error")) {
        draws[[i]] <- data.frame(
          replicate = i,
          estimate = NA_real_,
          converged = FALSE,
          logLik = NA_real_,
          message = conditionMessage(fit_i)
        )
      } else {
        draws[[i]] <- data.frame(
          replicate = i,
          estimate = phylo_sd_value(fit_i),
          converged = identical(convergence_code(fit_i), 0L),
          logLik = as.numeric(stats::logLik(fit_i)),
          message = if (identical(convergence_code(fit_i), 0L)) {
            "ok"
          } else {
            paste("convergence", convergence_code(fit_i))
          }
        )
      }
    }
  })[["elapsed"]]
  draws <- do.call(rbind, draws)
  ci <- bootstrap_interval_from_draws(draws, level = level)
  common_result_columns(data.frame(
    task = "bootstrap",
    route = "Julia bridge bootstrap-shaped refit loop",
    model = "AVONET phylogenetic Gaussian",
    species = n_species,
    rows = nrow(dat),
    B = B,
    backend = "R loop over JuliaCall",
    process_model = "single R process plus one Julia runtime",
    workers = 1L,
    requested_workers = 1L,
    elapsed_s = unname(elapsed),
    sec_per_refit = unname(elapsed) / B,
    first_call_s = first$elapsed,
    used = sum(draws$converged),
    failed = sum(!draws$converged),
    lower = ci[[1L]],
    upper = ci[[2L]],
    target = target,
    status = if (sum(draws$converged) >= 2L) {
      "bootstrap_loop"
    } else {
      "unavailable"
    },
    message = paste0(sum(draws$converged), "/", B, " converged Julia refits"),
    comparison_scope = paste(
      "benchmark-only refit loop; not public confint;",
      "not Julia-threaded from R yet"
    ),
    direct_report = NA_character_,
    stringsAsFactors = FALSE
  ))
}

parse_direct_julia_bootstrap_report <- function(
  path,
  threads,
  B_direct,
  n_species
) {
  lines <- readLines(path, warn = FALSE)
  pattern <- paste0("^\\| ", B_direct, " \\| (serial|threaded) \\|")
  hits <- grep(pattern, lines, value = TRUE)
  if (length(hits) == 0L) {
    stop(
      "Could not find bootstrap rows in direct Julia report.",
      call. = FALSE
    )
  }
  rows <- lapply(hits, function(hit) {
    fields <- trimws(strsplit(hit, "\\|", fixed = FALSE)[[1L]])
    fields <- fields[nzchar(fields)]
    mode <- fields[[2L]]
    used <- as.integer(fields[[7L]])
    failed <- as.integer(fields[[8L]])
    elapsed <- as.numeric(fields[[9L]])
    workers <- as.integer(fields[[3L]])
    common_result_columns(data.frame(
      task = "bootstrap",
      route = if (identical(mode, "serial")) {
        "Direct DRM.jl bootstrap serial"
      } else {
        "Direct DRM.jl bootstrap threaded"
      },
      model = "AVONET phylogenetic Gaussian",
      species = n_species,
      rows = n_species,
      B = B_direct,
      backend = if (identical(mode, "serial")) {
        "Julia serial"
      } else {
        "Julia threads"
      },
      process_model = if (identical(mode, "serial")) {
        "one Julia process, one bootstrap worker"
      } else {
        "one Julia process with shared-memory threads"
      },
      workers = workers,
      requested_workers = threads,
      elapsed_s = elapsed,
      sec_per_refit = elapsed / used,
      first_call_s = NA_real_,
      used = used,
      failed = failed,
      lower = NA_real_,
      upper = NA_real_,
      target = "sd:mu:phylo(1 | species)",
      status = if (identical(failed, 0L)) "ok" else "partial",
      message = fields[[12L]],
      comparison_scope = paste(
        "direct DRM.jl benchmark, not the R bridge;",
        "same AVONET/Hackett model shape and pruned tree"
      ),
      direct_report = path,
      stringsAsFactors = FALSE
    ))
  })
  do.call(rbind, rows)
}

parse_direct_julia_profile_report <- function(path, threads, n_species) {
  lines <- readLines(path, warn = FALSE)
  pattern <- "^\\| resd \\| (serial|threaded) \\|"
  hits <- grep(pattern, lines, value = TRUE)
  if (length(hits) == 0L) {
    return(NULL)
  }
  rows <- lapply(hits, function(hit) {
    fields <- trimws(strsplit(hit, "\\|", fixed = FALSE)[[1L]])
    fields <- fields[nzchar(fields)]
    mode <- fields[[2L]]
    workers <- as.integer(fields[[3L]])
    ok <- identical(fields[[4L]], "yes")
    used <- as.integer(fields[[6L]])
    failed <- as.integer(fields[[7L]])
    elapsed <- as.numeric(fields[[8L]])
    common_result_columns(data.frame(
      task = "profile",
      route = if (identical(mode, "serial")) {
        "Direct DRM.jl profile serial"
      } else {
        "Direct DRM.jl profile threaded"
      },
      model = "AVONET phylogenetic Gaussian",
      species = n_species,
      rows = n_species,
      B = NA_integer_,
      backend = if (identical(mode, "serial")) {
        "Julia serial"
      } else {
        "Julia threads"
      },
      process_model = if (identical(mode, "serial")) {
        "one Julia process, one profile worker"
      } else {
        "one Julia process with shared-memory threads"
      },
      workers = workers,
      requested_workers = threads,
      elapsed_s = elapsed,
      sec_per_refit = NA_real_,
      first_call_s = NA_real_,
      used = used,
      failed = failed,
      lower = as.numeric(fields[[10L]]),
      upper = as.numeric(fields[[11L]]),
      target = "sd:mu:phylo(1 | species)",
      status = if (ok) "ok" else "error",
      message = fields[[13L]],
      comparison_scope = paste(
        "direct DRM.jl profile_result benchmark, not the R bridge;",
        "same AVONET/Hackett model shape and pruned tree"
      ),
      direct_report = path,
      stringsAsFactors = FALSE
    ))
  })
  do.call(rbind, rows)
}

benchmark_direct_julia <- function(
  threads,
  B_direct,
  avonet_path,
  tree,
  run_profile
) {
  drm_path <- normalizePath(
    file.path(repo_root, "..", "DRM.jl"),
    mustWork = TRUE
  )
  direct_tree <- tempfile(
    pattern = sprintf("avonet-hackett-%s-species-", n_species),
    fileext = ".tre"
  )
  ape::write.tree(tree, file = direct_tree)
  out <- file.path(
    out_dir,
    sprintf(
      "direct-drmjl-avonet-bootstrap-n%s-B%s-threads-%s-%s.md",
      n_species,
      B_direct,
      threads,
      Sys.Date()
    )
  )
  args <- c(
    paste0("--project=", drm_path),
    paste0("--threads=", threads),
    file.path(drm_path, "bench", "avonet_phylo_gaussian_algorithms.jl"),
    paste0("--avonet=", normalizePath(avonet_path, mustWork = TRUE)),
    paste0("--tree=", direct_tree),
    "--g-tols=1e-4",
    "--algorithms=auto",
    "--reps=1",
    paste0("--bootstrap-B=", B_direct),
    "--bootstrap-mode=both",
    if (isTRUE(run_profile)) "--profile" else character(),
    if (isTRUE(run_profile)) "--profile-mode=both" else character(),
    if (isTRUE(run_profile)) "--profile-parm=resd" else character(),
    paste0("--out=", out)
  )
  message(sprintf(
    "Running direct DRM.jl bootstrap, B = %s, Julia threads = %s",
    B_direct,
    threads
  ))
  status <- system2(
    julia_bin,
    shQuote(args),
    env = c(
      paste0("JULIA_NUM_THREADS=", threads),
      "OPENBLAS_NUM_THREADS=1",
      "OMP_NUM_THREADS=1"
    )
  )
  if (!identical(status, 0L)) {
    stop("Direct DRM.jl bootstrap command failed.", call. = FALSE)
  }
  boot <- parse_direct_julia_bootstrap_report(
    out,
    threads = threads,
    B_direct = B_direct,
    n_species = n_species
  )
  prof <- parse_direct_julia_profile_report(
    out,
    threads = threads,
    n_species = n_species
  )
  if (is.null(prof)) {
    return(boot)
  }
  rbind(boot, prof)
}

level <- 0.95
av <- make_avonet_phylo_data(n_species = n_species)
tree <- av$tree
form <- bf(
  log_mass ~ hand_wing_z + beak_z + phylo(1 | species, tree = tree),
  sigma ~ 1
)

message(sprintf("Fitting native TMB base model, species = %s", n_species))
base <- time_fit(function() {
  drmTMB(
    form,
    family = stats::gaussian(),
    data = av$data,
    engine = "tmb",
    control = drm_control(keep_data = TRUE)
  )
})
fit_tmb <- base$fit
targets <- profile_targets(fit_tmb)
target <- grep("^sd:mu:phylo", targets$parm, value = TRUE)[[1L]]
simulations <- stats::simulate(fit_tmb, nsim = B, seed = seed)

rows <- lapply(r_workers, function(workers) {
  benchmark_r_bootstrap(
    fit_tmb,
    target = target,
    workers = workers,
    level = level
  )
})
if (run_julia_confint) {
  rows <- c(
    rows,
    lapply(julia_confint_thread_modes, function(threads) {
      benchmark_julia_public_confint(
        form = form,
        dat = av$data,
        target = target,
        level = level,
        threads = threads
      )
    })
  )
}
if (run_julia_bridge) {
  rows <- c(
    rows,
    list(benchmark_julia_bridge_loop(
      form = form,
      dat = av$data,
      simulations = simulations,
      target = target,
      level = level
    ))
  )
}
if (run_profile) {
  rows <- c(
    rows,
    lapply(profile_workers, function(workers) {
      benchmark_r_profile(
        fit_tmb,
        target = target,
        workers = workers,
        level = level
      )
    })
  )
}
if (run_direct_julia) {
  direct_rows <- lapply(direct_julia_threads, function(threads) {
    benchmark_direct_julia(
      threads = threads,
      B_direct = direct_julia_B,
      avonet_path = av$source$data,
      tree = tree,
      run_profile = run_profile
    )
  })
  rows <- c(rows, direct_rows)
}

bench <- do.call(rbind, rows)
bench$base_fit_s <- base$elapsed
bench$seed <- seed
utils::write.csv(bench, out_csv, row.names = FALSE)

metadata <- c(
  "# R and Julia Bootstrap/Profile Refit Benchmark Metadata",
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
  paste0("- species: ", n_species),
  paste0("- B: ", B),
  paste0("- seed: ", seed),
  paste0("- r_workers: ", paste(r_workers, collapse = ",")),
  paste0("- run_julia_confint: ", run_julia_confint),
  paste0(
    "- julia_confint_thread_modes: ",
    paste(julia_confint_thread_modes, collapse = ",")
  ),
  paste0(
    "- JULIA_NUM_THREADS: ",
    Sys.getenv("JULIA_NUM_THREADS", unset = "")
  ),
  paste0("- run_julia_bridge: ", run_julia_bridge),
  paste0("- run_profile: ", run_profile),
  paste0("- profile_workers: ", paste(profile_workers, collapse = ",")),
  paste0("- run_direct_julia: ", run_direct_julia),
  paste0(
    "- direct_julia_threads: ",
    paste(direct_julia_threads, collapse = ",")
  ),
  paste0("- direct_julia_B: ", direct_julia_B),
  paste0("- base_fit_s: ", format(base$elapsed, digits = 6)),
  paste0("- target: ", target),
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
  paste0("- output_csv: ", out_csv),
  "",
  "The R native bootstrap/profile rows call public confint(). The Julia public",
  "confint rows call confint.drmTMB_julia() on a Julia-engine fit and report",
  "the Julia worker/thread metadata returned by the bridge. The optional Julia",
  "bridge loop row is a benchmark-only R loop over simulated responses and",
  "drmTMB(..., engine = \"julia\") refits. Direct DRM.jl rows, when requested,",
  "come from the sibling DRM.jl benchmark script and are labelled separately."
)
writeLines(metadata, out_meta)

message("Wrote benchmark CSV: ", out_csv)
message("Wrote benchmark metadata: ", out_meta)
