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

stress_data_dir <- function() {
  Sys.getenv(
    "DRMTMB_TEST_DIR",
    unset = file.path(dirname(getwd()), "drmTMB-test")
  )
}

stress_output_dir <- function() {
  Sys.getenv(
    "DRMTMB_AYUMI_FULL_OUT",
    unset = "docs/dev-log/ayumi-convergence/slices-363-372/full-species-live"
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

make_aggregate_data <- function(dat) {
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
  add_model_columns(as.data.frame(aggregated))
}

make_row_cap_data <- function(dat, species, rows_per_species) {
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
    ordinary_species = bf(
      mu1 = male_z ~ temp_z + (1 | p | species),
      mu2 = female_z ~ temp_z + (1 | p | species),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    phylo_mean = bf(
      mu1 = male_z ~ temp_z + phylo(1 | p | species, tree = tree),
      mu2 = female_z ~ temp_z + phylo(1 | p | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    phylo_plus_ordinary = bf(
      mu1 = male_z ~ temp_z +
        (1 | p | species) +
        phylo(1 | p | species, tree = tree),
      mu2 = female_z ~ temp_z +
        (1 | p | species) +
        phylo(1 | p | species, tree = tree),
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
    stop("Unknown formula kind: ", kind)
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

fit_scenario <- function(scenario, data_sets, trees) {
  dat <- data_sets[[scenario$data]]
  tree <- trees[[scenario$tree]]
  formula <- make_formula(scenario$formula, tree = tree)
  control <- drm_control(
    optimizer_preset = scenario$preset,
    se = scenario$se,
    keep_data = FALSE,
    keep_model_frame = FALSE,
    keep_tmb_object = TRUE
  )
  message(
    format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    " START ",
    scenario$name,
    " n=",
    nrow(dat),
    " species=",
    length(unique(dat$species)),
    " se=",
    scenario$se
  )
  timing <- system.time(
    result <- capture_conditions(
      drmTMB(
        formula,
        family = biv_gaussian(),
        data = dat,
        control = control
      )
    )
  )
  fit <- result$value
  common <- data.frame(
    scenario = scenario$name,
    data = scenario$data,
    formula = scenario$formula,
    tree = scenario$tree,
    optimizer_preset = scenario$preset,
    se = scenario$se,
    n_rows = nrow(dat),
    n_species = length(unique(dat$species)),
    elapsed_sec = unname(timing[["elapsed"]]),
    n_fit_warnings = length(result$warnings),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  if (inherits(fit, "error")) {
    out <- list(
      summary = cbind(
        common,
        status = "error",
        error = conditionMessage(fit),
        convergence = NA_integer_,
        opt_message = NA_character_,
        uncertainty_status = NA_character_,
        pdHess = NA,
        objective = NA_real_,
        check_warnings = NA_integer_,
        check_errors = NA_integer_,
        check_notes = NA_integer_
      ),
      conditions = warning_rows(scenario$name, result$warnings, "fit_warning"),
      checks = data.frame(),
      corpairs = data.frame(),
      targets = data.frame()
    )
    print(out$summary)
    return(out)
  }

  checks <- safe_table(check_drm(fit))
  pairs <- safe_table(corpairs(fit))
  targets <- safe_table(profile_targets(fit))
  out <- list(
    summary = cbind(
      common,
      status = "fit",
      error = NA_character_,
      convergence = as.integer(fit$opt$convergence),
      opt_message = as.character(fit$opt$message),
      uncertainty_status = as.character(fit$uncertainty$status),
      pdHess = isTRUE(fit$sdr$pdHess),
      objective = as.numeric(fit$opt$objective),
      check_warnings = sum(checks$status == "warning", na.rm = TRUE),
      check_errors = sum(checks$status == "error", na.rm = TRUE),
      check_notes = sum(checks$status == "note", na.rm = TRUE)
    ),
    conditions = bind_tables(list(
      warning_rows(scenario$name, result$warnings, "fit_warning"),
      warning_rows(scenario$name, result$messages, "fit_message")
    )),
    checks = add_scenario_column(checks, scenario$name),
    corpairs = add_scenario_column(pairs, scenario$name),
    targets = add_scenario_column(targets, scenario$name)
  )
  print(out$summary)
  out
}

build_scenarios <- function(include_row_cap, include_q4, se) {
  scenarios <- list(
    list(
      name = "full_base_careful_no_se",
      data = "aggregate_all_species",
      formula = "base",
      tree = "none",
      preset = "careful",
      se = se
    ),
    list(
      name = "full_ls_rho_careful_no_se",
      data = "aggregate_all_species",
      formula = "ls_rho",
      tree = "none",
      preset = "careful",
      se = se
    ),
    list(
      name = "full_phylo_mean_raw_tree_no_se",
      data = "aggregate_all_species",
      formula = "phylo_mean",
      tree = "raw",
      preset = "careful",
      se = se
    ),
    list(
      name = "full_phylo_mean_forced_tree_careful_no_se",
      data = "aggregate_all_species",
      formula = "phylo_mean",
      tree = "forced",
      preset = "careful",
      se = se
    )
  )
  if (include_row_cap) {
    scenarios <- c(
      scenarios,
      list(
        list(
          name = "rowcap_ordinary_species_careful_no_se",
          data = "row_cap_all_species",
          formula = "ordinary_species",
          tree = "none",
          preset = "careful",
          se = se
        ),
        list(
          name = "rowcap_phylo_mean_forced_tree_careful_no_se",
          data = "row_cap_all_species",
          formula = "phylo_mean",
          tree = "forced",
          preset = "careful",
          se = se
        ),
        list(
          name = "rowcap_phylo_plus_ordinary_careful_no_se",
          data = "row_cap_all_species",
          formula = "phylo_plus_ordinary",
          tree = "forced",
          preset = "careful",
          se = se
        )
      )
    )
  }
  if (include_q4) {
    scenarios <- c(
      scenarios,
      list(
        list(
          name = "full_phylo_q4_forced_tree_robust_no_se",
          data = "aggregate_all_species",
          formula = "phylo_q4",
          tree = "forced",
          preset = "robust",
          se = se
        )
      )
    )
  }
  scenarios
}

main <- function() {
  timeout <- env_int("DRMTMB_AYUMI_FULL_TIMEOUT", 1800L)
  setTimeLimit(elapsed = timeout, transient = TRUE)
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

  row_cap <- env_int("DRMTMB_AYUMI_FULL_ROWS_PER_SPECIES", 5L)
  include_row_cap <- env_flag("DRMTMB_AYUMI_FULL_INCLUDE_ROW_CAP", TRUE)
  include_q4 <- env_flag("DRMTMB_AYUMI_FULL_INCLUDE_Q4", FALSE)
  se <- env_flag("DRMTMB_AYUMI_FULL_SE", FALSE)

  raw <- clean_lightness_data(data_path)
  aggregate_all <- make_aggregate_data(raw)
  row_cap_all <- if (include_row_cap) {
    make_row_cap_data(raw, aggregate_all$species, row_cap)
  } else {
    aggregate_all[0, ]
  }
  tree_full <- ape::read.nexus(tree_path)
  raw_tree <- subset_tree(tree_full, aggregate_all$species)
  forced <- force_ultrametric_for_stress(raw_tree)

  trees <- list(
    none = NULL,
    raw = raw_tree,
    forced = forced$tree
  )
  data_sets <- list(
    aggregate_all_species = aggregate_all,
    row_cap_all_species = row_cap_all
  )

  tree_preflight <- data.frame(
    input_data = label_test_path(data_path, root),
    input_tree = label_test_path(tree_path, root),
    raw_rows = nrow(raw),
    raw_species = data.table::uniqueN(raw$phylo_name),
    aggregate_rows = nrow(aggregate_all),
    aggregate_species = length(unique(aggregate_all$species)),
    row_cap = if (include_row_cap) row_cap else NA_integer_,
    row_cap_rows = nrow(row_cap_all),
    row_cap_species = length(unique(row_cap_all$species)),
    raw_tree_tips = length(raw_tree$tip.label),
    raw_tree_ultrametric = ape::is.ultrametric(raw_tree),
    forced_tree_ultrametric = ape::is.ultrametric(forced$tree),
    forced_output = paste(forced$output, collapse = " | "),
    forced_warnings = paste(forced$warnings, collapse = " | "),
    forced_messages = paste(forced$messages, collapse = " | "),
    stringsAsFactors = FALSE
  )
  write_table(tree_preflight, file.path(out_dir, "tree-preflight.csv"))

  scenarios <- build_scenarios(include_row_cap, include_q4, se)
  results <- vector("list", length(scenarios))
  for (i in seq_along(scenarios)) {
    results[[i]] <- fit_scenario(
      scenarios[[i]],
      data_sets = data_sets,
      trees = trees
    )
    write_table(
      bind_tables(lapply(results[seq_len(i)], `[[`, "summary")),
      file.path(out_dir, "fit-summary.csv")
    )
    write_table(
      bind_tables(lapply(results[seq_len(i)], `[[`, "checks")),
      file.path(out_dir, "check-rows.csv")
    )
    write_table(
      bind_tables(lapply(results[seq_len(i)], `[[`, "corpairs")),
      file.path(out_dir, "corpairs.csv")
    )
    write_table(
      bind_tables(lapply(results[seq_len(i)], `[[`, "targets")),
      file.path(out_dir, "profile-targets.csv")
    )
    write_table(
      bind_tables(lapply(results[seq_len(i)], `[[`, "conditions")),
      file.path(out_dir, "fit-conditions.csv")
    )
  }
  message("Wrote Ayumi full-species summaries to ", out_dir)
}

main()
