#!/usr/bin/env Rscript

load_drmtmb <- function() {
  if (
    requireNamespace("devtools", quietly = TRUE) && file.exists("DESCRIPTION")
  ) {
    devtools::load_all(".", quiet = TRUE)
    return(invisible(TRUE))
  }
  library(drmTMB)
  invisible(TRUE)
}

require_package <- function(package) {
  if (!requireNamespace(package, quietly = TRUE)) {
    stop("Package `", package, "` is required for this bootstrap prototype.")
  }
}

env_int <- function(name, default) {
  value <- Sys.getenv(name, unset = as.character(default))
  out <- suppressWarnings(as.integer(value))
  if (!is.finite(out) || is.na(out)) {
    default
  } else {
    out
  }
}

env_chr <- function(name, default) {
  value <- Sys.getenv(name, unset = default)
  if (!nzchar(value)) default else value
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

scale_numeric <- function(x) {
  as.numeric(scale(x))
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

condition_rows <- function(replicate, values, type) {
  if (!length(values)) {
    return(data.frame())
  }
  data.frame(
    replicate = replicate,
    type = type,
    message = as.character(values),
    stringsAsFactors = FALSE
  )
}

find_input <- function(root, candidates) {
  for (candidate in candidates) {
    path <- file.path(root, candidate)
    if (file.exists(path)) {
      return(path)
    }
  }
  stop(
    "Could not find any expected input under `",
    root,
    "`: ",
    paste(candidates, collapse = ", ")
  )
}

prepare_species_data <- function(data_path) {
  columns <- c(
    "phylo_name",
    "Order1",
    "temporal_scenario",
    "aggr_resolution",
    "n_0.2_cells",
    "Beak.Length_Culmen",
    "Mass",
    "mean_tavg",
    "mean_prec"
  )
  dat <- data.table::fread(data_path, select = columns, showProgress = FALSE)
  if ("temporal_scenario" %in% names(dat)) {
    dat <- dat[temporal_scenario == "variable"]
  }
  if ("aggr_resolution" %in% names(dat)) {
    dat <- dat[aggr_resolution == "id_1_degree"]
  }
  if ("Order1" %in% names(dat)) {
    dat <- dat[Order1 == "Passeriformes"]
  }
  dat <- dat[
    is.finite(Mass) &
      Mass > 0 &
      is.finite(Beak.Length_Culmen) &
      Beak.Length_Culmen > 0 &
      is.finite(mean_tavg) &
      is.finite(mean_prec)
  ]
  sp <- dat[,
    .(
      Mass = mean(Mass, na.rm = TRUE),
      Beak = mean(Beak.Length_Culmen, na.rm = TRUE),
      mean_tavg = weighted.mean(mean_tavg, pmax(n_0.2_cells, 1), na.rm = TRUE),
      mean_prec = weighted.mean(mean_prec, pmax(n_0.2_cells, 1), na.rm = TRUE),
      n_rows = .N
    ),
    by = phylo_name
  ]
  data.table::setorder(sp, phylo_name)
  sp[, species := as.character(phylo_name)]
  sp[, Mass_z := scale_numeric(log(Mass))]
  sp[, Mass_cov_z := Mass_z]
  sp[, Beak_z := scale_numeric(log(Beak))]
  sp[, mean_tavg_z := scale_numeric(mean_tavg)]
  sp[, mean_prec_z := scale_numeric(mean_prec)]
  as.data.frame(sp)
}

patch_tree <- function(tree) {
  edge <- tree$edge.length
  if (any(is.na(edge) | edge <= 0)) {
    unit <- median(edge[edge > 0], na.rm = TRUE)
    if (!is.finite(unit)) {
      unit <- 1
    }
    edge[is.na(edge) | edge <= 0] <- unit * 1e-6
    tree$edge.length <- edge
  }
  tree
}

prepare_tree <- function(tree_path, species) {
  tree <- ape::read.nexus(tree_path)
  shared <- intersect(species, tree$tip.label)
  if (length(shared) < 2L) {
    stop("Tree and species data have fewer than two shared labels.")
  }
  tree <- ape::keep.tip(tree, shared)
  tree <- patch_tree(tree)
  if (!ape::is.binary(tree)) {
    set.seed(42)
    tree <- ape::multi2di(tree, random = TRUE)
    tree <- patch_tree(tree)
  }
  if (!ape::is.ultrametric(tree)) {
    tree <- phytools::force.ultrametric(tree, method = "extend")
  }
  tree
}

make_formula <- function(model, tree = NULL) {
  switch(
    model,
    PV2_locphylo = bf(
      mu1 = Mass_z ~ 1 +
        mean_tavg_z +
        I(mean_tavg_z^2) +
        mean_prec_z +
        I(mean_prec_z^2) +
        phylo(1 | p | species, tree = tree),
      mu2 = Beak_z ~ 1 +
        mean_tavg_z +
        I(mean_tavg_z^2) +
        mean_prec_z +
        I(mean_prec_z^2) +
        Mass_cov_z +
        phylo(1 | p | species, tree = tree),
      sigma1 = ~ 1 +
        mean_tavg_z +
        I(mean_tavg_z^2) +
        mean_prec_z +
        I(mean_prec_z^2),
      sigma2 = ~ 1 +
        mean_tavg_z +
        I(mean_tavg_z^2) +
        mean_prec_z +
        I(mean_prec_z^2) +
        Mass_cov_z,
      rho12 = ~1
    ),
    PV2_main_q4 = bf(
      mu1 = Mass_z ~ 1 +
        mean_tavg_z +
        I(mean_tavg_z^2) +
        mean_prec_z +
        I(mean_prec_z^2) +
        phylo(1 | p | species, tree = tree),
      mu2 = Beak_z ~ 1 +
        mean_tavg_z +
        I(mean_tavg_z^2) +
        mean_prec_z +
        I(mean_prec_z^2) +
        Mass_cov_z +
        phylo(1 | p | species, tree = tree),
      sigma1 = ~ 1 +
        mean_tavg_z +
        I(mean_tavg_z^2) +
        mean_prec_z +
        I(mean_prec_z^2) +
        phylo(1 | p | species, tree = tree),
      sigma2 = ~ 1 +
        mean_tavg_z +
        I(mean_tavg_z^2) +
        mean_prec_z +
        I(mean_prec_z^2) +
        Mass_cov_z +
        phylo(1 | p | species, tree = tree),
      rho12 = ~1
    ),
    PV2_phylo_fallback = bf(
      mu1 = Mass_z ~ 1 +
        mean_tavg_z +
        I(mean_tavg_z^2) +
        mean_prec_z +
        I(mean_prec_z^2) +
        phylo(1 | pl | species, tree = tree),
      mu2 = Beak_z ~ 1 +
        mean_tavg_z +
        I(mean_tavg_z^2) +
        mean_prec_z +
        I(mean_prec_z^2) +
        Mass_cov_z +
        phylo(1 | pl | species, tree = tree),
      sigma1 = ~ 1 +
        mean_tavg_z +
        I(mean_tavg_z^2) +
        mean_prec_z +
        I(mean_prec_z^2) +
        phylo(1 | ps | species, tree = tree),
      sigma2 = ~ 1 +
        mean_tavg_z +
        I(mean_tavg_z^2) +
        mean_prec_z +
        I(mean_prec_z^2) +
        Mass_cov_z +
        phylo(1 | ps | species, tree = tree),
      rho12 = ~1
    ),
    PV2_phylo_fallback_sigma_intercept = bf(
      mu1 = Mass_z ~ 1 +
        mean_tavg_z +
        I(mean_tavg_z^2) +
        mean_prec_z +
        I(mean_prec_z^2) +
        phylo(1 | pl | species, tree = tree),
      mu2 = Beak_z ~ 1 +
        mean_tavg_z +
        I(mean_tavg_z^2) +
        mean_prec_z +
        I(mean_prec_z^2) +
        Mass_cov_z +
        phylo(1 | pl | species, tree = tree),
      sigma1 = ~ 1 +
        phylo(1 | ps | species, tree = tree),
      sigma2 = ~ 1 +
        phylo(1 | ps | species, tree = tree),
      rho12 = ~1
    ),
    stop("Unknown bootstrap model: ", model)
  )
}

extract_boot_summary <- function(fit, replicate, elapsed_sec) {
  rho_link <- NA_real_
  if (!is.null(fit$coefficients$rho12)) {
    rho_link <- unname(fit$coefficients$rho12[["(Intercept)"]])
  }
  grad <- tryCatch(fit$obj$gr(fit$opt$par), error = function(e) numeric())
  grad_abs <- abs(grad)
  gradient_max <- if (length(grad_abs)) {
    max(grad_abs, na.rm = TRUE)
  } else {
    NA_real_
  }
  gradient_component <- NA_character_
  if (length(grad_abs) && is.finite(gradient_max)) {
    grad_names <- names(grad_abs)
    gradient_index <- which.max(grad_abs)
    if (!is.null(grad_names) && length(grad_names) >= gradient_index) {
      gradient_component <- grad_names[[gradient_index]]
    } else {
      gradient_component <- paste0("par[", gradient_index, "]")
    }
  }
  pairs <- tryCatch(corpairs(fit), error = function(e) data.frame())
  phylo_cor <- NA_real_
  phylo_scale_cor <- NA_real_
  if (is.data.frame(pairs) && nrow(pairs) > 0L) {
    index <- which(
      pairs$level == "phylogenetic" &
        pairs$from_dpar == "mu1" &
        pairs$to_dpar == "mu2"
    )
    if (length(index) > 0L) {
      phylo_cor <- pairs$estimate[index[[1L]]]
    }
    scale_index <- which(
      pairs$level == "phylogenetic" &
        pairs$from_dpar == "sigma1" &
        pairs$to_dpar == "sigma2"
    )
    if (length(scale_index) > 0L) {
      phylo_scale_cor <- pairs$estimate[scale_index[[1L]]]
    }
  }
  data.frame(
    replicate = replicate,
    status = "fit",
    elapsed_sec = elapsed_sec,
    convergence = fit$opt$convergence,
    optimizer_message = fit$opt$message,
    objective = fit$opt$objective,
    gradient_max = gradient_max,
    gradient_component = gradient_component,
    logLik = unname(as.numeric(stats::logLik(fit))),
    AIC = stats::AIC(fit),
    rho12_link = rho_link,
    rho12_response = tanh(rho_link),
    phylo_mu1_mu2_cor = phylo_cor,
    phylo_sigma1_sigma2_cor = phylo_scale_cor,
    beta_mu2_mass = unname(fit$coefficients$mu2[["Mass_cov_z"]]),
    stringsAsFactors = FALSE
  )
}

fit_boot_replicate <- function(
  i,
  data,
  sims,
  model,
  tree,
  optimizer_control
) {
  dat_i <- data
  dat_i$Mass_z <- sims[[paste0("sim_", i, "_y1")]]
  dat_i$Beak_z <- sims[[paste0("sim_", i, "_y2")]]
  started <- Sys.time()
  captured <- capture_conditions(
    drmTMB(
      make_formula(model, tree = tree),
      family = biv_gaussian(),
      data = dat_i,
      control = drm_control(optimizer = optimizer_control, se = FALSE)
    )
  )
  elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  if (inherits(captured$value, "error")) {
    return(list(
      summary = data.frame(
        replicate = i,
        status = "error",
        elapsed_sec = elapsed,
        convergence = NA_integer_,
        optimizer_message = NA_character_,
        objective = NA_real_,
        gradient_max = NA_real_,
        gradient_component = NA_character_,
        logLik = NA_real_,
        AIC = NA_real_,
        rho12_link = NA_real_,
        rho12_response = NA_real_,
        phylo_mu1_mu2_cor = NA_real_,
        phylo_sigma1_sigma2_cor = NA_real_,
        beta_mu2_mass = NA_real_,
        stringsAsFactors = FALSE
      ),
      conditions = bind_tables(list(
        condition_rows(i, conditionMessage(captured$value), "error"),
        condition_rows(i, captured$warnings, "warning"),
        condition_rows(i, captured$messages, "message")
      ))
    ))
  }
  list(
    summary = extract_boot_summary(captured$value, i, elapsed),
    conditions = bind_tables(list(
      condition_rows(i, captured$warnings, "warning"),
      condition_rows(i, captured$messages, "message")
    ))
  )
}

run_parallel <- function(tasks, worker, backend, cores) {
  if (identical(backend, "none") || cores <= 1L || length(tasks) <= 1L) {
    return(lapply(tasks, worker))
  }
  if (identical(backend, "multicore")) {
    if (.Platform$OS.type == "windows") {
      stop("The multicore backend is unavailable on Windows; use psock.")
    }
    return(parallel::mclapply(tasks, worker, mc.cores = cores))
  }
  if (identical(backend, "psock")) {
    cluster <- parallel::makeCluster(cores)
    on.exit(parallel::stopCluster(cluster), add = TRUE)
    parallel::clusterCall(cluster, setwd, getwd())
    parallel::clusterEvalQ(cluster, {
      if (
        requireNamespace("devtools", quietly = TRUE) &&
          file.exists("DESCRIPTION")
      ) {
        devtools::load_all(".", quiet = TRUE)
      } else {
        library(drmTMB)
      }
      NULL
    })
    parallel::clusterExport(
      cluster,
      varlist = c(
        "capture_conditions",
        "condition_rows",
        "bind_tables",
        "make_formula",
        "extract_boot_summary",
        "fit_boot_replicate",
        "data",
        "sims",
        "model",
        "tree",
        "optimizer_control"
      ),
      envir = environment(worker)
    )
    return(parallel::parLapply(cluster, tasks, worker))
  }
  stop("Unknown backend: ", backend)
}

main <- function() {
  require_package("data.table")
  require_package("ape")
  require_package("phytools")
  load_drmtmb()

  model <- env_chr("DRMTMB_BOOT_MODEL", "PV2_locphylo")
  root <- env_chr(
    "BERGMANN_DRMTMB_DIR",
    file.path(dirname(getwd()), "bergmann-drmTMB")
  )
  fit_rds <- env_chr(
    "DRMTMB_BOOT_FIT_RDS",
    "docs/dev-log/ayumi-convergence/slices-391-402/mass-beak-pv2-rerun/fits.rds"
  )
  out <- env_chr(
    "DRMTMB_BOOT_OUT",
    "docs/dev-log/ayumi-convergence/slices-391-402/mass-beak-bootstrap"
  )
  B <- env_int("DRMTMB_BOOT_R", 20L)
  requested_cores <- max(1L, env_int("DRMTMB_BOOT_CORES", min(4L, B)))
  cores <- min(10L, requested_cores)
  backend <- env_chr(
    "DRMTMB_BOOT_BACKEND",
    if (cores > 1L) "multicore" else "none"
  )
  seed <- env_int("DRMTMB_BOOT_SEED", 20260519L)
  optimizer_control <- list(
    iter.max = env_int("DRMTMB_BOOT_ITER_MAX", 1000L),
    eval.max = env_int("DRMTMB_BOOT_EVAL_MAX", 1000L)
  )

  if (!backend %in% c("none", "multicore", "psock")) {
    stop("DRMTMB_BOOT_BACKEND must be one of none, multicore, or psock.")
  }
  if (B < 1L) {
    stop("DRMTMB_BOOT_R must be positive.")
  }

  fits <- readRDS(fit_rds)
  fit <- if (is.list(fits) && model %in% names(fits)) {
    fits[[model]]
  } else if (inherits(fits, "drmTMB")) {
    fits
  } else {
    stop("Could not find model `", model, "` in ", fit_rds)
  }
  data_path <- find_input(
    root,
    c(
      "data_raw/data_6196spp.csv",
      "data/data_6196spp.csv"
    )
  )
  tree_path <- find_input(
    root,
    c(
      "data_raw/tre_10597spp.nex",
      "data_raw/tree_6196spp.nex",
      "data/tree_6196spp.nex"
    )
  )
  data <- prepare_species_data(data_path)
  tree <- prepare_tree(tree_path, data$species)
  shared <- intersect(data$species, tree$tip.label)
  data <- data[data$species %in% shared, , drop = FALSE]
  data <- data[order(data$species), , drop = FALSE]
  tree <- ape::keep.tip(tree, shared)

  sims <- simulate(fit, nsim = B, seed = seed)
  tasks <- seq_len(B)
  worker <- function(i) {
    tryCatch(
      fit_boot_replicate(
        i,
        data = data,
        sims = sims,
        model = model,
        tree = tree,
        optimizer_control = optimizer_control
      ),
      error = function(e) {
        list(
          summary = data.frame(
            replicate = i,
            status = "worker_error",
            elapsed_sec = NA_real_,
            convergence = NA_integer_,
            optimizer_message = NA_character_,
            objective = NA_real_,
            gradient_max = NA_real_,
            gradient_component = NA_character_,
            logLik = NA_real_,
            AIC = NA_real_,
            rho12_link = NA_real_,
            rho12_response = NA_real_,
            phylo_mu1_mu2_cor = NA_real_,
            phylo_sigma1_sigma2_cor = NA_real_,
            beta_mu2_mass = NA_real_,
            stringsAsFactors = FALSE
          ),
          conditions = condition_rows(i, conditionMessage(e), "worker_error")
        )
      }
    )
  }
  started <- Sys.time()
  results <- run_parallel(tasks, worker, backend = backend, cores = cores)
  elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))

  preflight <- data.frame(
    item = c(
      "model",
      "fit_rds",
      "B",
      "backend",
      "requested_cores",
      "cores",
      "seed",
      "elapsed_sec",
      "optimizer_iter_max",
      "optimizer_eval_max",
      "n_species"
    ),
    value = c(
      model,
      fit_rds,
      B,
      backend,
      requested_cores,
      cores,
      seed,
      elapsed,
      optimizer_control$iter.max,
      optimizer_control$eval.max,
      nrow(data)
    ),
    stringsAsFactors = FALSE
  )
  summary <- bind_tables(lapply(results, `[[`, "summary"))
  conditions <- bind_tables(lapply(results, `[[`, "conditions"))
  write_table(preflight, file.path(out, "preflight.csv"))
  write_table(summary, file.path(out, "bootstrap-summary.csv"))
  write_table(conditions, file.path(out, "bootstrap-conditions.csv"))
  print(preflight)
  print(summary)
  cat("Wrote bootstrap artifacts to ", out, "\n", sep = "")
}

main()
