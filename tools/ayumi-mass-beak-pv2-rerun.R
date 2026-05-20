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
    stop("Package `", package, "` is required for this local rerun script.")
  }
}

env_flag <- function(name, default = FALSE) {
  value <- Sys.getenv(name, unset = if (default) "true" else "false")
  tolower(value) %in% c("1", "true", "yes", "y")
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

bergmann_dir <- function() {
  env_chr(
    "BERGMANN_DRMTMB_DIR",
    file.path(dirname(getwd()), "bergmann-drmTMB")
  )
}

output_dir <- function() {
  env_chr(
    "DRMTMB_PV2_RERUN_OUT",
    "docs/dev-log/ayumi-convergence/slices-391-402/mass-beak-pv2-rerun"
  )
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

write_table <- function(dat, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(dat, path, row.names = FALSE, na = "")
}

add_model_column <- function(dat, model) {
  if (!nrow(dat)) {
    return(dat)
  }
  cbind(model = model, dat, stringsAsFactors = FALSE)
}

condition_rows <- function(model, values, type) {
  if (!length(values)) {
    return(data.frame())
  }
  data.frame(
    model = model,
    type = type,
    message = as.character(values),
    stringsAsFactors = FALSE
  )
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

vif_values <- function(X) {
  X <- X[, colnames(X) != "(Intercept)", drop = FALSE]
  out <- numeric(ncol(X))
  names(out) <- colnames(X)
  for (j in seq_len(ncol(X))) {
    fit <- stats::lm.fit(cbind(1, X[, -j, drop = FALSE]), X[, j])
    rss <- sum(fit$residuals^2)
    tss <- sum((X[, j] - mean(X[, j]))^2)
    r2 <- 1 - rss / tss
    out[[j]] <- 1 / (1 - r2)
  }
  out
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
  sp
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

design_diagnostics <- function(sp) {
  X <- stats::model.matrix(
    ~ mean_tavg_z +
      I(mean_tavg_z^2) +
      mean_prec_z +
      I(mean_prec_z^2) +
      Mass_cov_z,
    data = sp
  )
  vif <- vif_values(X)
  lm_fit <- stats::lm(
    Beak_z ~ Mass_cov_z +
      mean_tavg_z +
      I(mean_tavg_z^2) +
      mean_prec_z +
      I(mean_prec_z^2),
    data = sp
  )
  data.frame(
    diagnostic = c(
      "n_species",
      "cor_mass_beak",
      "condition_number_mu2_design",
      paste0("vif_", names(vif)),
      "lm_beak_on_mass_slope",
      "lm_beak_on_mass_se",
      "lm_beak_r2"
    ),
    value = c(
      nrow(sp),
      stats::cor(sp$Mass_z, sp$Beak_z),
      kappa(X, exact = TRUE),
      unname(vif),
      unname(stats::coef(lm_fit)[["Mass_cov_z"]]),
      unname(summary(lm_fit)$coefficients["Mass_cov_z", "Std. Error"]),
      summary(lm_fit)$r.squared
    ),
    stringsAsFactors = FALSE
  )
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
    stop("Unknown model: ", model)
  )
}

fit_one <- function(model, sp, tree, optimizer_control) {
  formula <- make_formula(model, tree = tree)
  started <- Sys.time()
  captured <- capture_conditions(
    drmTMB(
      formula,
      family = biv_gaussian(),
      data = as.data.frame(sp),
      control = drm_control(
        optimizer = optimizer_control,
        se = env_flag("DRMTMB_PV2_SE", TRUE)
      )
    )
  )
  elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  if (inherits(captured$value, "error")) {
    return(list(
      fit = NULL,
      summary = data.frame(
        model = model,
        status = "error",
        elapsed_sec = elapsed,
        convergence = NA_integer_,
        pdHess = NA,
        logLik = NA_real_,
        AIC = NA_real_,
        rho12_link = NA_real_,
        rho12_response = NA_real_,
        stringsAsFactors = FALSE
      ),
      conditions = bind_tables(list(
        condition_rows(model, conditionMessage(captured$value), "error"),
        condition_rows(model, captured$warnings, "warning"),
        condition_rows(model, captured$messages, "message")
      )),
      fixef = data.frame(),
      corpairs = data.frame(),
      covariance = data.frame(),
      check = data.frame()
    ))
  }
  fit <- captured$value
  rho_link <- NA_real_
  if (!is.null(fit$coefficients$rho12)) {
    rho_link <- unname(fit$coefficients$rho12[["(Intercept)"]])
  }
  gradients <- gradient_summary(fit)
  list(
    fit = fit,
    summary = data.frame(
      model = model,
      status = "fit",
      elapsed_sec = elapsed,
      convergence = fit$opt$convergence,
      pdHess = if (is.null(fit$sdr)) NA else isTRUE(fit$sdr$pdHess),
      logLik = unname(as.numeric(stats::logLik(fit))),
      AIC = stats::AIC(fit),
      rho12_link = rho_link,
      rho12_response = tanh(rho_link),
      gradients,
      stringsAsFactors = FALSE
    ),
    conditions = bind_tables(list(
      condition_rows(model, captured$warnings, "warning"),
      condition_rows(model, captured$messages, "message")
    )),
    fixef = add_model_column(safe_table(summary(fit)$coefficients), model),
    corpairs = add_model_column(safe_table(corpairs(fit)), model),
    covariance = add_model_column(safe_table(summary(fit)$covariance), model),
    check = add_model_column(safe_table(check_drm(fit)), model)
  )
}

main <- function() {
  require_package("data.table")
  require_package("ape")
  require_package("phytools")
  load_drmtmb()

  root <- bergmann_dir()
  out <- output_dir()
  dir.create(out, recursive = TRUE, showWarnings = FALSE)

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
  sp <- prepare_species_data(data_path)
  tree <- prepare_tree(tree_path, sp$species)
  shared <- intersect(sp$species, tree$tip.label)
  sp <- sp[sp$species %in% shared]
  data.table::setorder(sp, species)
  tree <- ape::keep.tip(tree, shared)

  preflight <- data.frame(
    item = c(
      "bergmann_dir",
      "data_path",
      "tree_path",
      "n_species",
      "n_tree_tips",
      "tree_is_ultrametric",
      "tree_is_binary",
      "se",
      "opt_iter_max",
      "opt_eval_max"
    ),
    value = c(
      root,
      data_path,
      tree_path,
      nrow(sp),
      length(tree$tip.label),
      ape::is.ultrametric(tree),
      ape::is.binary(tree),
      env_flag("DRMTMB_PV2_SE", TRUE),
      env_int("DRMTMB_PV2_ITER_MAX", 2000L),
      env_int("DRMTMB_PV2_EVAL_MAX", 2000L)
    ),
    stringsAsFactors = FALSE
  )
  write_table(preflight, file.path(out, "preflight.csv"))
  write_table(design_diagnostics(sp), file.path(out, "design-diagnostics.csv"))

  modes <- strsplit(
    env_chr(
      "DRMTMB_PV2_MODELS",
      "PV2_locphylo,PV2_main_q4,PV2_phylo_fallback"
    ),
    ",",
    fixed = TRUE
  )[[1L]]
  modes <- trimws(modes)
  if (!env_flag("DRMTMB_PV2_RUN_Q4", TRUE)) {
    modes <- setdiff(modes, "PV2_main_q4")
  }
  optimizer_control <- list(
    iter.max = env_int("DRMTMB_PV2_ITER_MAX", 2000L),
    eval.max = env_int("DRMTMB_PV2_EVAL_MAX", 2000L)
  )

  fits <- list()
  results <- list()
  for (model in modes) {
    cat("Fitting ", model, "...\n", sep = "")
    results[[model]] <- fit_one(model, sp, tree, optimizer_control)
    fits[[model]] <- results[[model]]$fit
    print(results[[model]]$summary)
  }

  write_table(
    bind_tables(lapply(results, `[[`, "summary")),
    file.path(out, "fit-summary.csv")
  )
  write_table(
    bind_tables(lapply(results, `[[`, "conditions")),
    file.path(out, "fit-conditions.csv")
  )
  write_table(
    bind_tables(lapply(results, `[[`, "fixef")),
    file.path(out, "fixed-effects.csv")
  )
  write_table(
    bind_tables(lapply(results, `[[`, "corpairs")),
    file.path(out, "corpairs.csv")
  )
  write_table(
    bind_tables(lapply(results, `[[`, "covariance")),
    file.path(out, "covariance.csv")
  )
  write_table(
    bind_tables(lapply(results, `[[`, "check")),
    file.path(out, "check-rows.csv")
  )
  saveRDS(
    Filter(Negate(is.null), fits),
    file.path(out, "fits.rds")
  )
  cat("Wrote PV2 Mass+Beak rerun artifacts to ", out, "\n", sep = "")
}

main()
