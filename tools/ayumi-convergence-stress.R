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
    stop("Package `", package, "` is required for this local stress script.")
  }
}

stress_data_dir <- function() {
  Sys.getenv(
    "DRMTMB_TEST_DIR",
    unset = file.path(dirname(getwd()), "drmTMB-test")
  )
}

stress_output_dir <- function() {
  Sys.getenv(
    "DRMTMB_AYUMI_STRESS_OUT",
    unset = "docs/dev-log/ayumi-convergence/slices-353-362"
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

clean_lightness_data <- function(path) {
  columns <- c(
    "phylo_name",
    "Delhey_lightness_male",
    "Delhey_lightness_female",
    "mean_tavg",
    "mean_prec",
    "sd_tavg",
    "Delhey_percent_tree_cover"
  )
  dat <- data.table::fread(path, select = columns, showProgress = FALSE)
  dat <- dat[stats::complete.cases(dat)]
  dat[, phylo_name := as.character(phylo_name)]
  dat
}

make_aggregate_data <- function(dat, n_species = 80L) {
  aggregated <- dat[,
    .(
      male = mean(Delhey_lightness_male),
      female = mean(Delhey_lightness_female),
      mean_tavg = mean(mean_tavg),
      mean_prec = mean(mean_prec),
      sd_tavg = mean(sd_tavg),
      tree_cover = mean(Delhey_percent_tree_cover),
      n_rows = .N
    ),
    by = phylo_name
  ]
  data.table::setorder(aggregated, phylo_name)
  index <- unique(round(seq(1, nrow(aggregated), length.out = n_species)))
  out <- as.data.frame(aggregated[index])
  add_model_columns(out)
}

make_row_data <- function(dat, species, rows_per_species = 5L) {
  row_dat <- dat[phylo_name %in% species]
  data.table::setorder(row_dat, phylo_name)
  row_dat <- row_dat[, utils::head(.SD, rows_per_species), by = phylo_name]
  out <- as.data.frame(row_dat)
  names(out)[names(out) == "Delhey_lightness_male"] <- "male"
  names(out)[names(out) == "Delhey_lightness_female"] <- "female"
  names(out)[names(out) == "Delhey_percent_tree_cover"] <- "tree_cover"
  out$n_rows <- ave(out$phylo_name, out$phylo_name, FUN = length)
  add_model_columns(out)
}

add_model_columns <- function(dat) {
  out <- dat
  out$species <- out$phylo_name
  out$male_z <- scale_numeric(out$male)
  out$female_z <- scale_numeric(out$female)
  out$temp_z <- scale_numeric(out$mean_tavg)
  out$prec_z <- scale_numeric(log1p(pmax(out$mean_prec, 0)))
  out$temp_var_z <- scale_numeric(log1p(pmax(out$sd_tavg, 0)))
  out$tree_cover_z <- scale_numeric(out$tree_cover)
  out
}

subset_tree <- function(tree, species) {
  missing <- setdiff(species, tree$tip.label)
  if (length(missing) > 0L) {
    stop(
      "Missing species in tree: ",
      paste(utils::head(missing, 8L), collapse = ", ")
    )
  }
  ape::keep.tip(tree, species)
}

force_ultrametric_for_stress <- function(tree) {
  captured <- NULL
  captured_output <- utils::capture.output(
    captured <- capture_conditions(
      phytools::force.ultrametric(tree, method = "extend")
    )
  )
  list(
    tree = captured$value,
    output = captured_output,
    warnings = captured$warnings,
    messages = captured$messages
  )
}

make_formula <- function(kind, tree = NULL) {
  switch(
    kind,
    base = bf(
      mu1 = male_z ~ temp_z + prec_z,
      mu2 = female_z ~ temp_z + prec_z,
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    ls_rho = bf(
      mu1 = male_z ~ temp_z + prec_z,
      mu2 = female_z ~ temp_z + prec_z,
      sigma1 = ~temp_var_z,
      sigma2 = ~temp_var_z,
      rho12 = ~tree_cover_z
    ),
    ordinary_two_mu_sigma = bf(
      mu1 = male_z ~ temp_z + (1 | p | species),
      mu2 = female_z ~ temp_z + (1 | q | species),
      sigma1 = ~ temp_var_z + (1 | p | species),
      sigma2 = ~ temp_var_z + (1 | q | species),
      rho12 = ~tree_cover_z
    ),
    phylo_mean = bf(
      mu1 = male_z ~ temp_z + phylo(1 | p | species, tree = tree),
      mu2 = female_z ~ temp_z + phylo(1 | p | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    phylo_q4 = bf(
      mu1 = male_z ~ temp_z + phylo(1 | p | species, tree = tree),
      mu2 = female_z ~ temp_z + phylo(1 | p | species, tree = tree),
      sigma1 = ~ temp_var_z + phylo(1 | p | species, tree = tree),
      sigma2 = ~ temp_var_z + phylo(1 | p | species, tree = tree),
      rho12 = ~1
    ),
    phylo_q4_const = bf(
      mu1 = male_z ~ temp_z + phylo(1 | p | species, tree = tree),
      mu2 = female_z ~ temp_z + phylo(1 | p | species, tree = tree),
      sigma1 = ~ phylo(1 | p | species, tree = tree),
      sigma2 = ~ phylo(1 | p | species, tree = tree),
      rho12 = ~1
    ),
    phylo_q4_rho = bf(
      mu1 = male_z ~ temp_z + phylo(1 | p | species, tree = tree),
      mu2 = female_z ~ temp_z + phylo(1 | p | species, tree = tree),
      sigma1 = ~ temp_var_z + phylo(1 | p | species, tree = tree),
      sigma2 = ~ temp_var_z + phylo(1 | p | species, tree = tree),
      rho12 = ~tree_cover_z
    ),
    stop("Unknown formula kind: ", kind)
  )
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

fit_scenario <- function(scenario, data_sets, trees) {
  dat <- data_sets[[scenario$data]]
  tree <- trees[[scenario$tree]]
  formula <- make_formula(scenario$formula, tree = tree)
  control <- drm_control(
    optimizer_preset = scenario$preset,
    keep_tmb_object = TRUE,
    keep_data = TRUE
  )
  expr <- quote(
    drmTMB(
      formula,
      family = biv_gaussian(),
      data = dat,
      control = control
    )
  )
  timing <- system.time(result <- capture_conditions(eval(expr)))
  fit <- result$value
  common <- data.frame(
    scenario = scenario$name,
    data = scenario$data,
    formula = scenario$formula,
    tree = scenario$tree,
    optimizer_preset = scenario$preset,
    n_rows = nrow(dat),
    n_species = length(unique(dat$species)),
    elapsed_sec = unname(timing[["elapsed"]]),
    n_fit_warnings = length(result$warnings),
    n_fit_messages = length(result$messages),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  if (inherits(fit, "error")) {
    return(list(
      summary = cbind(
        common,
        status = "error",
        error = conditionMessage(fit),
        convergence = NA_integer_,
        opt_message = NA_character_,
        pdHess = NA,
        objective = NA_real_,
        check_warnings = NA_integer_,
        check_errors = NA_integer_,
        check_notes = NA_integer_
      ),
      fit_warnings = warning_rows(
        scenario$name,
        result$warnings,
        "fit_warning"
      ),
      fit_messages = warning_rows(
        scenario$name,
        result$messages,
        "fit_message"
      ),
      checks = data.frame(),
      corpairs = data.frame(),
      targets = data.frame(),
      intervals = data.frame()
    ))
  }

  checks <- safe_table(check_drm(fit))
  pairs <- safe_table(corpairs(fit))
  targets <- safe_table(profile_targets(fit))
  gradients <- gradient_summary(fit)
  intervals <- if (isTRUE(scenario$profile_intervals)) {
    safe_table(corpairs(fit, conf.int = TRUE))
  } else {
    data.frame()
  }

  list(
    summary = cbind(
      common,
      status = "fit",
      error = NA_character_,
      convergence = as.integer(fit$opt$convergence),
      opt_message = as.character(fit$opt$message),
      pdHess = isTRUE(fit$sdr$pdHess),
      objective = as.numeric(fit$opt$objective),
      gradients,
      check_warnings = sum(checks$status == "warning", na.rm = TRUE),
      check_errors = sum(checks$status == "error", na.rm = TRUE),
      check_notes = sum(checks$status == "note", na.rm = TRUE)
    ),
    fit_warnings = warning_rows(scenario$name, result$warnings, "fit_warning"),
    fit_messages = warning_rows(scenario$name, result$messages, "fit_message"),
    checks = add_scenario_column(checks, scenario$name),
    corpairs = add_scenario_column(pairs, scenario$name),
    targets = add_scenario_column(targets, scenario$name),
    intervals = add_scenario_column(intervals, scenario$name)
  )
}

safe_table <- function(x) {
  if (is.null(x)) {
    return(data.frame())
  }
  out <- as.data.frame(x, stringsAsFactors = FALSE)
  row.names(out) <- NULL
  out
}

warning_rows <- function(scenario, values, type) {
  if (!length(values)) {
    return(data.frame())
  }
  data.frame(
    scenario = scenario,
    type = type,
    message = as.character(values),
    stringsAsFactors = FALSE
  )
}

add_scenario_column <- function(dat, scenario) {
  if (nrow(dat) == 0L) {
    return(dat)
  }
  cbind(scenario = scenario, dat, stringsAsFactors = FALSE)
}

bind_tables <- function(tables) {
  tables <- Filter(function(x) nrow(x) > 0L, tables)
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

label_test_path <- function(path, root) {
  root <- normalizePath(root, mustWork = FALSE)
  path <- normalizePath(path, mustWork = FALSE)
  sub(
    paste0("^", gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", root)),
    "DRMTMB_TEST_DIR",
    path
  )
}

main <- function() {
  load_drmtmb()
  require_package("data.table")
  require_package("ape")
  require_package("phytools")

  root <- stress_data_dir()
  out_dir <- stress_output_dir()
  data_path <- file.path(root, "data_raw", "data_6196spp.csv")
  tree_path <- file.path(root, "data_raw", "tre_10597spp.nex")
  if (!file.exists(data_path)) {
    stop("Missing data file: ", data_path)
  }
  if (!file.exists(tree_path)) {
    stop("Missing tree file: ", tree_path)
  }

  raw <- clean_lightness_data(data_path)
  aggregate_80 <- make_aggregate_data(raw)
  row5_80 <- make_row_data(raw, species = aggregate_80$species)
  tree_full <- ape::read.nexus(tree_path)
  raw_tree <- subset_tree(tree_full, aggregate_80$species)
  forced <- force_ultrametric_for_stress(raw_tree)

  trees <- list(
    none = NULL,
    raw = raw_tree,
    forced = forced$tree
  )
  data_sets <- list(
    aggregate_80 = aggregate_80,
    row5_80 = row5_80
  )
  scenarios <- list(
    list(
      name = "agg_base_80_careful",
      data = "aggregate_80",
      formula = "base",
      tree = "none",
      preset = "careful",
      profile_intervals = TRUE
    ),
    list(
      name = "agg_ls_rho_80_careful",
      data = "aggregate_80",
      formula = "ls_rho",
      tree = "none",
      preset = "careful",
      profile_intervals = FALSE
    ),
    list(
      name = "agg_phylo_mean_raw_tree_80",
      data = "aggregate_80",
      formula = "phylo_mean",
      tree = "raw",
      preset = "careful",
      profile_intervals = FALSE
    ),
    list(
      name = "agg_phylo_mean_forced_tree_80_careful",
      data = "aggregate_80",
      formula = "phylo_mean",
      tree = "forced",
      preset = "careful",
      profile_intervals = FALSE
    ),
    list(
      name = "agg_phylo_q4_forced_tree_80_careful",
      data = "aggregate_80",
      formula = "phylo_q4",
      tree = "forced",
      preset = "careful",
      profile_intervals = FALSE
    ),
    list(
      name = "agg_phylo_q4_forced_tree_80_robust",
      data = "aggregate_80",
      formula = "phylo_q4_const",
      tree = "forced",
      preset = "robust",
      profile_intervals = FALSE
    ),
    list(
      name = "agg_phylo_q4_rho_forced_tree_80_robust",
      data = "aggregate_80",
      formula = "phylo_q4_rho",
      tree = "forced",
      preset = "robust",
      profile_intervals = FALSE
    ),
    list(
      name = "row5_ordinary_two_mu_sigma_80_robust",
      data = "row5_80",
      formula = "ordinary_two_mu_sigma",
      tree = "none",
      preset = "robust",
      profile_intervals = FALSE
    ),
    list(
      name = "row5_phylo_mean_forced_tree_80_robust",
      data = "row5_80",
      formula = "phylo_mean",
      tree = "forced",
      preset = "robust",
      profile_intervals = FALSE
    ),
    list(
      name = "row5_phylo_q4_forced_tree_80_robust",
      data = "row5_80",
      formula = "phylo_q4",
      tree = "forced",
      preset = "robust",
      profile_intervals = FALSE
    )
  )

  results <- lapply(
    scenarios,
    fit_scenario,
    data_sets = data_sets,
    trees = trees
  )
  tree_preflight <- data.frame(
    input_data = label_test_path(data_path, root),
    input_tree = label_test_path(tree_path, root),
    aggregate_rows = nrow(aggregate_80),
    aggregate_species = length(unique(aggregate_80$species)),
    row5_rows = nrow(row5_80),
    row5_species = length(unique(row5_80$species)),
    raw_tree_tips = length(raw_tree$tip.label),
    raw_tree_ultrametric = ape::is.ultrametric(raw_tree),
    forced_tree_ultrametric = ape::is.ultrametric(forced$tree),
    forced_output = paste(forced$output, collapse = " | "),
    forced_warnings = paste(forced$warnings, collapse = " | "),
    forced_messages = paste(forced$messages, collapse = " | "),
    stringsAsFactors = FALSE
  )

  write_table(tree_preflight, file.path(out_dir, "tree-preflight.csv"))
  write_table(
    bind_tables(lapply(results, `[[`, "summary")),
    file.path(out_dir, "fit-summary.csv")
  )
  write_table(
    bind_tables(lapply(results, `[[`, "checks")),
    file.path(out_dir, "check-rows.csv")
  )
  write_table(
    bind_tables(lapply(results, `[[`, "corpairs")),
    file.path(out_dir, "corpairs.csv")
  )
  write_table(
    bind_tables(lapply(results, `[[`, "targets")),
    file.path(out_dir, "profile-targets.csv")
  )
  write_table(
    bind_tables(lapply(results, `[[`, "intervals")),
    file.path(out_dir, "profile-intervals.csv")
  )
  write_table(
    bind_tables(c(
      lapply(results, `[[`, "fit_warnings"),
      lapply(results, `[[`, "fit_messages")
    )),
    file.path(out_dir, "fit-conditions.csv")
  )
  message("Wrote Ayumi convergence stress summaries to ", out_dir)
}

main()
