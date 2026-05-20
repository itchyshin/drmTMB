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

ns_fun <- function(name) {
  get(name, envir = asNamespace("drmTMB"))
}

require_package <- function(package) {
  if (!requireNamespace(package, quietly = TRUE)) {
    stop("Package `", package, "` is required for this local prototype.")
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

env_num <- function(name, default) {
  value <- Sys.getenv(name, unset = as.character(default))
  out <- suppressWarnings(as.numeric(value))
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

prototype_output_dir <- function(n_species) {
  Sys.getenv(
    "DRMTMB_Q2_START_OUT",
    unset = file.path(
      "docs/dev-log/ayumi-convergence/slices-373-382",
      if (is.finite(n_species) && n_species > 0L) {
        paste0("q2-start-prototype-", n_species, "species")
      } else {
        "q2-start-prototype-full"
      }
    )
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

select_species <- function(species, n_species) {
  species <- sort(unique(species))
  if (
    !is.finite(n_species) || n_species <= 0L || n_species >= length(species)
  ) {
    return(species)
  }
  species[unique(round(seq(1, length(species), length.out = n_species)))]
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

make_aggregate_data <- function(dat, species) {
  aggregated <- dat[
    phylo_name %in% species,
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
    fixed_residual = bf(
      mu1 = male_z ~ temp_z,
      mu2 = female_z ~ temp_z,
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    ordinary_species_q2 = bf(
      mu1 = male_z ~ temp_z + (1 | p | species),
      mu2 = female_z ~ temp_z + (1 | p | species),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    phylo_q2 = bf(
      mu1 = male_z ~ temp_z + phylo(1 | p | species, tree = tree),
      mu2 = female_z ~ temp_z + phylo(1 | p | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    stop("Unknown formula kind: ", kind)
  )
}

build_biv_spec <- function(formula, data, env) {
  spec <- ns_fun("drm_build_biv_gaussian_spec")(
    formula = formula,
    data = data,
    env = env,
    weights = NULL
  )
  spec$response_names <- ns_fun("drm_spec_response_names")(spec)
  ns_fun("add_covariance_probe_parameter")(spec)
}

make_fit_from_spec <- function(formula, data, env, control, start_strategy) {
  spec <- build_biv_spec(formula, data, env)
  start_result <- start_strategy$modify(spec$start)
  spec$start <- start_result$start
  obj <- TMB::MakeADFun(
    data = spec$tmb_data,
    parameters = spec$start,
    map = spec$map,
    random = spec$random_names,
    DLL = "drmTMB",
    silent = TRUE
  )
  opt <- stats::nlminb(
    start = obj$par,
    objective = obj$fn,
    gradient = obj$gr,
    control = control$optimizer
  )
  ns_fun("drm_pin_tmb_object_to_optimum")(obj, opt)
  tmb_state <- ns_fun("drm_tmb_selected_state")(obj, opt)
  uncertainty <- ns_fun("drm_compute_uncertainty")(obj, opt, control)
  par_list <- obj$env$parList(opt$par)
  par <- ns_fun("split_tmb_parameters")(par_list, spec)
  fit <- list(
    call = match.call(),
    formula = formula,
    family = biv_gaussian(),
    data = spec$data,
    model = spec,
    obj = obj,
    opt = opt,
    sdr = uncertainty$sdr,
    uncertainty = uncertainty$state,
    tmb_state = tmb_state,
    par = par,
    coefficients = par,
    sdpars = ns_fun("split_tmb_sdpars")(par_list, spec),
    corpars = ns_fun("split_tmb_corpars")(par_list, spec),
    random_effects = ns_fun("split_tmb_random_effects")(par_list, spec),
    ordinal = ns_fun("ordinal_fit_info")(par_list, spec),
    logLik = -opt$objective,
    df = length(opt$par),
    nobs = spec$nobs,
    start_provenance = start_result$provenance
  )
  class(fit) <- "drmTMB"
  ns_fun("drm_apply_storage_control")(fit, control)
}

identity_strategy <- function() {
  list(
    name = "default_current_start",
    modify = function(start) {
      list(
        start = start,
        provenance = data.frame(
          strategy = "default_current_start",
          action = "default",
          target = NA_character_,
          source = NA_character_,
          value = NA_real_,
          stringsAsFactors = FALSE
        )
      )
    }
  )
}

copy_vector <- function(start, source, target_name, source_name = target_name) {
  if (!target_name %in% names(start) || !source_name %in% names(source)) {
    return(list(start = start, copied = FALSE))
  }
  if (length(start[[target_name]]) != length(source[[source_name]])) {
    return(list(start = start, copied = FALSE))
  }
  start[[target_name]] <- unname(source[[source_name]])
  list(start = start, copied = TRUE)
}

source_parlist <- function(fit) {
  fit$obj$env$parList(fit$opt$par)
}

copy_strategy <- function(
  name,
  source,
  copy_plan,
  jitter = NULL,
  seed = NA_integer_
) {
  list(
    name = name,
    modify = function(start) {
      source_list <- source_parlist(source)
      provenance <- data.frame()
      for (entry in copy_plan) {
        copied <- copy_vector(
          start,
          source_list,
          target_name = entry$target,
          source_name = entry$source
        )
        start <- copied$start
        provenance <- rbind(
          provenance,
          data.frame(
            strategy = name,
            action = if (copied$copied) "copied" else "skipped",
            target = entry$target,
            source = entry$source,
            value = NA_real_,
            stringsAsFactors = FALSE
          )
        )
      }
      if (!is.null(jitter)) {
        set.seed(seed)
        for (target in jitter$targets) {
          if (target %in% names(start)) {
            delta <- stats::rnorm(length(start[[target]]), 0, jitter$sd)
            start[[target]] <- start[[target]] + delta
            provenance <- rbind(
              provenance,
              data.frame(
                strategy = name,
                action = "jittered",
                target = target,
                source = NA_character_,
                value = jitter$sd,
                stringsAsFactors = FALSE
              )
            )
          }
        }
      }
      list(start = start, provenance = provenance)
    }
  )
}

jitter_only_strategy <- function(name, targets, sd, seed) {
  list(
    name = name,
    modify = function(start) {
      set.seed(seed)
      provenance <- data.frame()
      for (target in targets) {
        if (target %in% names(start)) {
          delta <- stats::rnorm(length(start[[target]]), 0, sd)
          start[[target]] <- start[[target]] + delta
          provenance <- rbind(
            provenance,
            data.frame(
              strategy = name,
              action = "jittered",
              target = target,
              source = NA_character_,
              value = sd,
              stringsAsFactors = FALSE
            )
          )
        }
      }
      list(start = start, provenance = provenance)
    }
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

extract_check_value <- function(checks, check_name) {
  row <- checks[checks$check == check_name, , drop = FALSE]
  if (!nrow(row)) {
    return(NA_character_)
  }
  as.character(row$value[[1L]])
}

extract_max_gradient <- function(checks) {
  value <- extract_check_value(checks, "fixed_gradient")
  if (is.na(value)) {
    return(NA_real_)
  }
  parsed <- sub(".*max=([-+0-9.eE]+).*", "\\1", value)
  suppressWarnings(as.numeric(parsed))
}

fit_record <- function(
  name,
  role,
  formula_kind,
  data_name,
  data,
  tree,
  control,
  strategy
) {
  formula <- make_formula(formula_kind, tree = tree)
  message(
    format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    " START ",
    role,
    " ",
    name,
    " data=",
    data_name,
    " n=",
    nrow(data),
    " species=",
    length(unique(data$species)),
    " strategy=",
    strategy$name
  )
  timing <- system.time(
    captured <- capture_conditions(
      make_fit_from_spec(
        formula,
        data,
        env = environment(),
        control = control,
        start_strategy = strategy
      )
    )
  )
  fit <- captured$value
  common <- data.frame(
    name = name,
    role = role,
    formula = formula_kind,
    data = data_name,
    n_rows = nrow(data),
    n_species = length(unique(data$species)),
    start_strategy = strategy$name,
    elapsed_sec = unname(timing[["elapsed"]]),
    n_fit_warnings = length(captured$warnings),
    n_fit_messages = length(captured$messages),
    stringsAsFactors = FALSE
  )
  if (inherits(fit, "error")) {
    return(list(
      fit = NULL,
      summary = cbind(
        common,
        status = "error",
        error = conditionMessage(fit),
        convergence = NA_integer_,
        opt_message = NA_character_,
        objective = NA_real_,
        max_fixed_gradient = NA_real_,
        residual_rho12_min = NA_real_,
        residual_rho12_max = NA_real_,
        n_check_warnings = NA_integer_,
        n_check_errors = NA_integer_,
        stringsAsFactors = FALSE
      ),
      checks = data.frame(),
      corpairs = data.frame(),
      provenance = data.frame(),
      conditions = condition_rows(name, captured)
    ))
  }
  checks <- safe_table(check_drm(fit))
  pairs <- safe_table(corpairs(fit))
  residual <- pairs[pairs$level == "residual", , drop = FALSE]
  summary <- cbind(
    common,
    status = "fit",
    error = NA_character_,
    convergence = as.integer(fit$opt$convergence),
    opt_message = as.character(fit$opt$message),
    objective = as.numeric(fit$opt$objective),
    max_fixed_gradient = extract_max_gradient(checks),
    residual_rho12_min = if (nrow(residual)) {
      min(residual$estimate)
    } else {
      NA_real_
    },
    residual_rho12_max = if (nrow(residual)) {
      max(residual$estimate)
    } else {
      NA_real_
    },
    n_check_warnings = sum(checks$status == "warning", na.rm = TRUE),
    n_check_errors = sum(checks$status == "error", na.rm = TRUE),
    stringsAsFactors = FALSE
  )
  list(
    fit = fit,
    summary = summary,
    checks = cbind(name = name, checks, stringsAsFactors = FALSE),
    corpairs = cbind(name = name, pairs, stringsAsFactors = FALSE),
    provenance = cbind(
      name = name,
      fit$start_provenance,
      stringsAsFactors = FALSE
    ),
    conditions = condition_rows(name, captured)
  )
}

condition_rows <- function(name, captured) {
  values <- c(captured$warnings, captured$messages)
  types <- c(
    rep("warning", length(captured$warnings)),
    rep("message", length(captured$messages))
  )
  if (!length(values)) {
    return(data.frame())
  }
  data.frame(
    name = name,
    type = types,
    message = values,
    stringsAsFactors = FALSE
  )
}

main <- function() {
  timeout <- env_int("DRMTMB_Q2_START_TIMEOUT", 7200L)
  setTimeLimit(elapsed = timeout, transient = TRUE)
  load_drmtmb()
  require_package("data.table")
  require_package("ape")
  require_package("phytools")

  root <- stress_data_dir()
  data_path <- file.path(root, "data_raw", "data_6196spp.csv")
  tree_path <- file.path(root, "data_raw", "tre_10597spp.nex")
  n_species <- env_int("DRMTMB_Q2_START_N_SPECIES", 300L)
  rows_per_species <- env_int("DRMTMB_Q2_START_ROWS_PER_SPECIES", 5L)
  n_jitter <- env_int("DRMTMB_Q2_START_N_JITTER", 3L)
  jitter_sd <- env_num("DRMTMB_Q2_START_JITTER_SD", 0.25)
  out_dir <- prototype_output_dir(n_species)

  raw <- clean_lightness_data(data_path)
  species <- select_species(raw$phylo_name, n_species)
  aggregate_data <- make_aggregate_data(raw, species)
  row_data <- make_row_cap_data(raw, aggregate_data$species, rows_per_species)
  tree_full <- ape::read.nexus(tree_path)
  raw_tree <- subset_tree(tree_full, aggregate_data$species)
  forced <- force_ultrametric_for_stress(raw_tree)
  tree <- forced$tree

  control <- drm_control(
    optimizer_preset = "careful",
    se = FALSE,
    keep_data = FALSE,
    keep_model_frame = FALSE,
    keep_tmb_object = TRUE
  )

  preflight <- data.frame(
    data_path = "DRMTMB_TEST_DIR/data_raw/data_6196spp.csv",
    tree_path = "DRMTMB_TEST_DIR/data_raw/tre_10597spp.nex",
    requested_species = n_species,
    selected_species = length(unique(aggregate_data$species)),
    aggregate_rows = nrow(aggregate_data),
    row_cap_rows = nrow(row_data),
    rows_per_species = rows_per_species,
    raw_tree_ultrametric = ape::is.ultrametric(raw_tree),
    forced_tree_ultrametric = ape::is.ultrametric(tree),
    n_jitter = n_jitter,
    jitter_sd = jitter_sd,
    stringsAsFactors = FALSE
  )
  write_table(preflight, file.path(out_dir, "preflight.csv"))

  source_specs <- list(
    list(
      name = "source_fixed_residual_rowcap",
      formula = "fixed_residual",
      data_name = "row_cap",
      data = row_data
    ),
    list(
      name = "source_ordinary_species_rowcap",
      formula = "ordinary_species_q2",
      data_name = "row_cap",
      data = row_data
    ),
    list(
      name = "source_phylo_q2_aggregate",
      formula = "phylo_q2",
      data_name = "aggregate",
      data = aggregate_data
    )
  )
  sources <- list()
  source_results <- list()
  for (item in source_specs) {
    result <- fit_record(
      name = item$name,
      role = "source",
      formula_kind = item$formula,
      data_name = item$data_name,
      data = item$data,
      tree = tree,
      control = control,
      strategy = identity_strategy()
    )
    source_results[[item$name]] <- result
    if (!is.null(result$fit)) {
      sources[[item$name]] <- result$fit
    }
    write_table(
      bind_tables(lapply(source_results, `[[`, "summary")),
      file.path(out_dir, "source-summary.csv")
    )
    write_table(
      bind_tables(lapply(source_results, `[[`, "checks")),
      file.path(out_dir, "source-checks.csv")
    )
    write_table(
      bind_tables(lapply(source_results, `[[`, "corpairs")),
      file.path(out_dir, "source-corpairs.csv")
    )
  }

  fixed_copy <- list(
    list(target = "beta_mu1", source = "beta_mu1"),
    list(target = "beta_mu2", source = "beta_mu2"),
    list(target = "beta_sigma1", source = "beta_sigma1"),
    list(target = "beta_sigma2", source = "beta_sigma2"),
    list(target = "beta_rho12", source = "beta_rho12")
  )
  ordinary_to_phylo_copy <- c(
    fixed_copy,
    list(
      list(target = "log_sd_phylo", source = "log_sd_mu"),
      list(target = "eta_cor_phylo", source = "eta_cor_mu")
    )
  )
  phylo_copy <- c(
    fixed_copy,
    list(
      list(target = "u_phylo", source = "u_phylo"),
      list(target = "log_sd_phylo", source = "log_sd_phylo"),
      list(target = "eta_cor_phylo", source = "eta_cor_phylo")
    )
  )

  strategies <- list(identity_strategy())
  for (i in seq_len(max(0L, n_jitter))) {
    strategies <- c(
      strategies,
      list(jitter_only_strategy(
        paste0("default_covariance_jitter_", i),
        targets = c("log_sd_phylo", "eta_cor_phylo"),
        sd = jitter_sd,
        seed = 20260619L + i
      ))
    )
  }
  if (!is.null(sources$source_fixed_residual_rowcap)) {
    strategies <- c(
      strategies,
      list(copy_strategy(
        "fixed_residual_source_start",
        sources$source_fixed_residual_rowcap,
        fixed_copy
      ))
    )
  }
  if (!is.null(sources$source_ordinary_species_rowcap)) {
    strategies <- c(
      strategies,
      list(copy_strategy(
        "ordinary_species_source_start",
        sources$source_ordinary_species_rowcap,
        ordinary_to_phylo_copy
      ))
    )
  }
  if (!is.null(sources$source_phylo_q2_aggregate)) {
    strategies <- c(
      strategies,
      list(copy_strategy(
        "phylo_q2_source_start",
        sources$source_phylo_q2_aggregate,
        phylo_copy
      ))
    )
    for (i in seq_len(max(0L, n_jitter))) {
      strategies <- c(
        strategies,
        list(copy_strategy(
          paste0("phylo_q2_source_jitter_", i),
          sources$source_phylo_q2_aggregate,
          phylo_copy,
          jitter = list(
            targets = c("log_sd_phylo", "eta_cor_phylo"),
            sd = jitter_sd
          ),
          seed = 20260519L + i
        ))
      )
    }
  }

  target_results <- list()
  for (strategy in strategies) {
    result <- fit_record(
      name = paste0("target_rowcap_phylo_q2__", strategy$name),
      role = "target",
      formula_kind = "phylo_q2",
      data_name = "row_cap",
      data = row_data,
      tree = tree,
      control = control,
      strategy = strategy
    )
    target_results[[strategy$name]] <- result
    write_table(
      bind_tables(lapply(target_results, `[[`, "summary")),
      file.path(out_dir, "target-summary.csv")
    )
    write_table(
      bind_tables(lapply(target_results, `[[`, "checks")),
      file.path(out_dir, "target-checks.csv")
    )
    write_table(
      bind_tables(lapply(target_results, `[[`, "corpairs")),
      file.path(out_dir, "target-corpairs.csv")
    )
    write_table(
      bind_tables(lapply(target_results, `[[`, "provenance")),
      file.path(out_dir, "target-start-provenance.csv")
    )
    write_table(
      bind_tables(lapply(target_results, `[[`, "conditions")),
      file.path(out_dir, "target-conditions.csv")
    )
  }

  message("Wrote q2 start prototype artifacts to ", out_dir)
}

main()
