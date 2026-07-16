#!/usr/bin/env Rscript

parse_args <- function(args = commandArgs(trailingOnly = TRUE)) {
  out <- list(
    mode = "smoke",
    reps = NULL,
    cores = 1L,
    output = NULL,
    seed = NULL,
    m = NULL
  )
  for (arg in args) {
    if (startsWith(arg, "--mode=")) {
      out$mode <- sub("^--mode=", "", arg)
    } else if (startsWith(arg, "--reps=")) {
      out$reps <- as.integer(sub("^--reps=", "", arg))
    } else if (startsWith(arg, "--cores=")) {
      out$cores <- as.integer(sub("^--cores=", "", arg))
    } else if (startsWith(arg, "--output=")) {
      out$output <- sub("^--output=", "", arg)
    } else if (startsWith(arg, "--seed=")) {
      out$seed <- as.integer(sub("^--seed=", "", arg))
    } else if (startsWith(arg, "--m=")) {
      out$m <- as.integer(sub("^--m=", "", arg))
    } else {
      stop("Unknown argument: ", arg, call. = FALSE)
    }
  }
  out$mode <- match.arg(
    out$mode,
    c(
      "smoke",
      "pilot",
      "certification",
      "addendum",
      "diagnostic",
      "repair_smoke",
      "repair_pilot",
      "repair_design",
      "addendum_repair"
    )
  )
  defaults <- switch(
    out$mode,
    smoke = list(reps = 1L, m = 2L, seed = 2026071601L),
    pilot = list(reps = 10L, m = 2L, seed = 2026071601L),
    certification = list(reps = 400L, m = 2L, seed = 2026071601L),
    addendum = list(reps = 400L, m = 4L, seed = 2026071602L),
    diagnostic = list(reps = 1L, m = 2L, seed = 2026071601L),
    repair_smoke = list(reps = 1L, m = 4L, seed = 2026071629L),
    repair_pilot = list(reps = 10L, m = 4L, seed = 2026071630L),
    repair_design = list(reps = 400L, m = 4L, seed = 2026071631L),
    addendum_repair = list(reps = 400L, m = 4L, seed = 2026071631L)
  )
  out$reps <- out$reps %||% defaults$reps
  out$m <- out$m %||% defaults$m
  out$seed <- out$seed %||% defaults$seed
  if (
    anyNA(c(out$reps, out$cores, out$seed, out$m)) ||
      out$reps < 1L ||
      out$cores < 1L ||
      out$cores > 32L ||
      out$m < 1L
  ) {
    stop(
      "`reps`, `m`, `cores`, and `seed` must be valid; cores must be 1 through 32.",
      call. = FALSE
    )
  }
  if (
    identical(out$mode, "certification") &&
      (!identical(out$reps, 400L) || !identical(out$m, 2L))
  ) {
    stop(
      "Certification is frozen at 400 replicates per cell and m=2.",
      call. = FALSE
    )
  }
  if (
    identical(out$mode, "addendum") &&
      (!identical(out$reps, 400L) || !identical(out$m, 4L))
  ) {
    stop(
      "Addendum mode is frozen at 400 replicates per cell and m=4.",
      call. = FALSE
    )
  }
  repair_freeze <- list(
    repair_smoke = c(reps = 1L, m = 4L, seed = 2026071629L),
    repair_pilot = c(reps = 10L, m = 4L, seed = 2026071630L),
    repair_design = c(reps = 400L, m = 4L, seed = 2026071631L),
    addendum_repair = c(reps = 400L, m = 4L, seed = 2026071631L)
  )
  if (out$mode %in% names(repair_freeze)) {
    frozen <- repair_freeze[[out$mode]]
    observed <- c(reps = out$reps, m = out$m, seed = out$seed)
    if (!identical(as.integer(observed), as.integer(frozen))) {
      stop(
        "Repair modes use frozen replicate, m, and seed values.",
        call. = FALSE
      )
    }
  }
  out
}

`%||%` <- function(x, y) if (is.null(x)) y else x

repair_rng_kind <- function() {
  c(
    kind = "Mersenne-Twister",
    normal.kind = "Inversion",
    sample.kind = "Rejection"
  )
}

with_repair_rng <- function(code) {
  old_kind <- RNGkind()
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  old_seed <- if (had_seed) {
    get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  } else {
    NULL
  }
  on.exit({
    do.call(RNGkind, as.list(old_kind))
    if (had_seed) {
      assign(".Random.seed", old_seed, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  })
  do.call(RNGkind, as.list(repair_rng_kind()))
  force(code)
}

recovery_grid <- function(reps, seed, m, seed_method = c("offset", "sample")) {
  seed_method <- match.arg(seed_method)
  cells <- data.frame(g = c(64L, 256L, 1024L), m = m)
  cells$cell_number <- seq_len(nrow(cells))
  cells$cell_id <- sprintf("g%04d_m%02d", cells$g, cells$m)
  grid <- merge(
    cells,
    data.frame(replicate = seq_len(reps)),
    by = NULL,
    sort = FALSE
  )
  grid$seed <- if (identical(seed_method, "sample")) {
    set.seed(seed)
    sample.int(.Machine$integer.max, nrow(grid), replace = FALSE)
  } else {
    as.integer(seed + 100000L * grid$cell_number + grid$replicate)
  }
  grid[order(grid$cell_number, grid$replicate), , drop = FALSE]
}

repair_mode_spec <- function() {
  data.frame(
    mode = c("repair_smoke", "repair_pilot", "addendum_repair"),
    reps = c(1L, 10L, 400L),
    m = 4L,
    seed = c(2026071629L, 2026071630L, 2026071631L),
    stringsAsFactors = FALSE
  )
}

repair_seed_grid <- function(mode) {
  if (identical(mode, "repair_design")) {
    mode <- "addendum_repair"
  }
  spec <- repair_mode_spec()
  row <- spec[spec$mode == mode, , drop = FALSE]
  if (nrow(row) != 1L) {
    stop("Unknown repair mode: ", mode, call. = FALSE)
  }
  grid <- with_repair_rng(
    recovery_grid(row$reps, row$seed, row$m, seed_method = "sample")
  )
  rownames(grid) <- NULL
  grid
}

frozen_repair_design_path <- function(repo_root) {
  file.path(
    repo_root,
    "docs/dev-log/simulation-designs",
    "2026-07-16-beta-phylo-q1-pr1-disjoint-repair",
    "design.tsv"
  )
}

assert_frozen_repair_design <- function(
  grid,
  path,
  expected_hash = "cfd025e7280ff30db4d95bcdf86da48c251080d516ba1324e80d88681138676a"
) {
  if (!file.exists(path)) {
    stop(
      "The committed disjoint repair design is missing: ",
      path,
      call. = FALSE
    )
  }
  observed_hash <- sha256_file(path)
  if (!identical(observed_hash, expected_hash)) {
    stop(
      "Committed disjoint repair design SHA-256 mismatch: ",
      observed_hash,
      call. = FALSE
    )
  }
  frozen <- utils::read.delim(path, stringsAsFactors = FALSE)
  if (
    !isTRUE(all.equal(frozen, grid, check.attributes = TRUE, tolerance = 0))
  ) {
    stop(
      "Generated certification grid does not match the committed disjoint repair design.",
      call. = FALSE
    )
  }
  invisible(frozen)
}

validate_prior_seed_design <- function(path) {
  data <- utils::read.delim(path, stringsAsFactors = FALSE)
  required <- c("g", "m", "cell_number", "cell_id", "replicate", "seed")
  if (!all(required %in% names(data))) {
    stop("Invalid prior seed design: ", path, call. = FALSE)
  }
  integer_fields <- c("g", "m", "cell_number", "replicate", "seed")
  converted <- lapply(data[integer_fields], function(x) {
    suppressWarnings(as.integer(as.character(x)))
  })
  values_are_integer <- vapply(
    integer_fields,
    function(field) {
      x <- suppressWarnings(as.numeric(as.character(data[[field]])))
      all(is.finite(x)) && all(x == converted[[field]])
    },
    logical(1)
  )
  data[integer_fields] <- converted
  key <- paste(data$cell_id, data$replicate, data$seed, sep = ":")
  valid_cells <- identical(
    sort(unique(data$g)),
    c(64L, 256L, 1024L)
  ) &&
    all(table(data$cell_id) == 400L)
  if (
    nrow(data) != 1200L ||
      anyNA(data[required]) ||
      !all(values_are_integer) ||
      anyDuplicated(data$seed) ||
      anyDuplicated(key) ||
      !valid_cells
  ) {
    stop("Invalid prior seed design: ", path, call. = FALSE)
  }
  data
}

repair_seed_audit <- function(grid, repo_root, mode) {
  prior <- c(
    original_m2 = file.path(
      repo_root,
      "docs/dev-log/simulation-artifacts",
      "2026-07-16-beta-phylo-q1-pr1-recovery-original-hold",
      "design.tsv"
    ),
    invalid_m4 = file.path(
      repo_root,
      "docs/dev-log/simulation-artifacts",
      "2026-07-16-beta-phylo-q1-pr1-recovery-addendum-hold",
      "design.tsv"
    )
  )
  missing <- prior[!file.exists(prior)]
  if (length(missing)) {
    stop(
      "Repair seed audit requires both prior design files: ",
      paste(unname(missing), collapse = ", "),
      call. = FALSE
    )
  }
  prior_seeds <- lapply(prior, function(path) {
    validate_prior_seed_design(path)$seed
  })
  canonical_mode <- if (identical(mode, "repair_design")) {
    "addendum_repair"
  } else {
    mode
  }
  sibling_modes <- setdiff(repair_mode_spec()$mode, canonical_mode)
  sibling_seeds <- lapply(sibling_modes, function(x) repair_seed_grid(x)$seed)
  names(sibling_seeds) <- sibling_modes
  rows <- c(
    list(data.frame(
      check = "unique_current_seeds",
      observed = length(unique(grid$seed)),
      expected = nrow(grid),
      pass = !anyDuplicated(grid$seed) &&
        length(unique(grid$seed)) == nrow(grid)
    )),
    lapply(names(prior_seeds), function(label) {
      overlap <- length(intersect(grid$seed, prior_seeds[[label]]))
      data.frame(
        check = paste0("overlap_", label),
        observed = overlap,
        expected = 0L,
        pass = overlap == 0L
      )
    }),
    lapply(names(sibling_seeds), function(label) {
      overlap <- length(intersect(grid$seed, sibling_seeds[[label]]))
      data.frame(
        check = paste0("overlap_", label),
        observed = overlap,
        expected = 0L,
        pass = overlap == 0L
      )
    })
  )
  audit <- do.call(rbind, rows)
  if (!all(audit$pass)) {
    failed <- audit$check[!audit$pass]
    stop(
      "Repair seed audit failed: ",
      paste(failed, collapse = ", "),
      call. = FALSE
    )
  }
  audit
}

sha256_file <- function(path) {
  sha256sum <- Sys.which("sha256sum")
  if (nzchar(sha256sum)) {
    output <- system2(sha256sum, path, stdout = TRUE, stderr = TRUE)
    status <- attr(output, "status") %||% 0L
    if (identical(status, 0L) && length(output)) {
      return(strsplit(output[[1L]], "[[:space:]]+")[[1L]][[1L]])
    }
  }
  shasum <- Sys.which("shasum")
  if (nzchar(shasum)) {
    output <- system2(
      shasum,
      c("-a", "256", path),
      stdout = TRUE,
      stderr = TRUE
    )
    status <- attr(output, "status") %||% 0L
    if (identical(status, 0L) && length(output)) {
      return(strsplit(output[[1L]], "[[:space:]]+")[[1L]][[1L]])
    }
  }
  stop("No working SHA-256 command is available.", call. = FALSE)
}

assert_repair_provenance <- function(audit) {
  required <- c("check", "observed", "expected", "pass")
  if (
    !is.data.frame(audit) ||
      !all(required %in% names(audit)) ||
      !nrow(audit) ||
      anyNA(audit$pass) ||
      !all(audit$pass)
  ) {
    failed <- if (is.data.frame(audit) && all(required %in% names(audit))) {
      audit$check[is.na(audit$pass) | !audit$pass]
    } else {
      "malformed_provenance_audit"
    }
    stop(
      "Repair provenance audit failed: ",
      paste(failed, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(audit)
}

repair_provenance_audit <- function(repo_root) {
  expected_tree <- c(
    R = "6908d26231d0133020cdf71d11b022898b33bba3",
    src = "5e385ee36b910f907c807c5d5c3767b34e22a373"
  )
  git <- Sys.which("git")
  if (!nzchar(git)) {
    stop("Git is required for the repair source-tree audit.", call. = FALSE)
  }
  source_status <- system2(
    git,
    c(
      "-C",
      repo_root,
      "status",
      "--porcelain",
      "--untracked-files=all",
      "--",
      "R",
      "src"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  source_status_code <- attr(source_status, "status") %||% 0L
  source_clean <- identical(source_status_code, 0L) && !length(source_status)
  protected_paths <- c(
    "tools/run-beta-phylo-q1-recovery.R",
    file.path(
      "docs/dev-log/simulation-designs",
      "2026-07-16-beta-phylo-q1-pr1-disjoint-repair",
      "design.tsv"
    )
  )
  protected_status <- system2(
    git,
    c(
      "-C",
      repo_root,
      "status",
      "--porcelain",
      "--untracked-files=all",
      "--",
      protected_paths
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  protected_status_code <- attr(protected_status, "status") %||% 0L
  protected_clean <- identical(protected_status_code, 0L) &&
    !length(protected_status)
  protected_tracked <- vapply(
    protected_paths,
    function(path) {
      output <- system2(
        git,
        c("-C", repo_root, "ls-files", "--error-unmatch", "--", path),
        stdout = TRUE,
        stderr = TRUE
      )
      identical(attr(output, "status") %||% 0L, 0L) && length(output) == 1L
    },
    logical(1)
  )
  observed_tree <- vapply(
    names(expected_tree),
    function(path) {
      output <- system2(
        git,
        c("-C", repo_root, "rev-parse", paste0("HEAD:", path)),
        stdout = TRUE,
        stderr = TRUE
      )
      status <- attr(output, "status") %||% 0L
      if (!identical(status, 0L) || length(output) != 1L) {
        return(NA_character_)
      }
      trimws(output[[1L]])
    },
    character(1)
  )
  artifact_root <- file.path(repo_root, "docs/dev-log/simulation-artifacts")
  original_root <- file.path(
    artifact_root,
    "2026-07-16-beta-phylo-q1-pr1-recovery-original-hold"
  )
  invalid_root <- file.path(
    artifact_root,
    "2026-07-16-beta-phylo-q1-pr1-recovery-addendum-hold"
  )
  expected_hash <- c(
    original_design = "203025d9e593ae0b1a56d45fbbf35ab6f9fc959fee78bf4a14b1f5215f8e2b8a",
    original_gates = "e00e150c24fcd6deb7d8879cecd82962dd2a0982c99c5509c55eff4fb906ab39",
    original_raw = "19256eaeecdf586f252148f90f0bedd18ba2510654c5bea3aca594388dded7d4",
    original_rmse = "a6c11cb71948d238c3bd163bfaee66c37f955b32146c1d1032fb62d7eff64032",
    original_session = "7c3faefc23dc093463e2bd690ff7515b4afab749eec19f2e275072336214e726",
    original_summary = "ebf94269b865259770595dd9732fad20d795ef97539f172d6eb9127adfebf260",
    invalid_design = "3c4d1eb2826f17d936fc85a07e7096166527ede00bb2e3901feacb5c2955503c",
    invalid_gates = "e9cf03b84a5195bbd8c71ae685dcae9ba3f80d6475ec8bb85eaab79793efb145",
    invalid_raw = "c0649b852b6a75903ad760eedbfae30445f2543d31d36cc7216f0053be6b3646",
    invalid_rmse = "e12d8211087d2c9af357b7dd0d402674f7ba230f9cd08c18e86f3fcbbe0e8b54",
    invalid_session = "7c3faefc23dc093463e2bd690ff7515b4afab749eec19f2e275072336214e726",
    invalid_summary = "f3f0bd033e910eeeb0c39b78bae69837ee3b2c18d7e6088edab0fada97fe6c38"
  )
  artifact_paths <- c(
    original_design = file.path(original_root, "design.tsv"),
    original_gates = file.path(original_root, "gates.tsv"),
    original_raw = file.path(original_root, "raw-attempts.tsv"),
    original_rmse = file.path(original_root, "rmse-difference.tsv"),
    original_session = file.path(original_root, "session-info.txt"),
    original_summary = file.path(original_root, "summary.tsv"),
    invalid_design = file.path(invalid_root, "design.tsv"),
    invalid_gates = file.path(invalid_root, "gates.tsv"),
    invalid_raw = file.path(invalid_root, "raw-attempts.tsv"),
    invalid_rmse = file.path(invalid_root, "rmse-difference.tsv"),
    invalid_session = file.path(invalid_root, "session-info.txt"),
    invalid_summary = file.path(invalid_root, "summary.tsv")
  )
  observed_hash <- vapply(
    artifact_paths,
    function(path) {
      if (!file.exists(path)) {
        return(NA_character_)
      }
      sha256_file(path)
    },
    character(1)
  )
  audit <- rbind(
    data.frame(
      check = "worktree_R_src_clean",
      observed = if (source_clean) {
        "clean"
      } else {
        paste(source_status, collapse = " | ")
      },
      expected = "clean",
      stringsAsFactors = FALSE
    ),
    data.frame(
      check = "worktree_runner_design_clean",
      observed = if (protected_clean) {
        "clean"
      } else {
        paste(protected_status, collapse = " | ")
      },
      expected = "clean",
      stringsAsFactors = FALSE
    ),
    data.frame(
      check = paste0("tracked_", c("runner", "frozen_design")),
      observed = ifelse(protected_tracked, "tracked", "untracked"),
      expected = "tracked",
      stringsAsFactors = FALSE
    ),
    data.frame(
      check = paste0("tree_", names(expected_tree)),
      observed = unname(observed_tree),
      expected = unname(expected_tree),
      stringsAsFactors = FALSE
    ),
    data.frame(
      check = paste0("sha256_", names(expected_hash)),
      observed = unname(observed_hash),
      expected = unname(expected_hash),
      stringsAsFactors = FALSE
    ),
    data.frame(
      check = "sha256_frozen_repair_design",
      observed = if (file.exists(frozen_repair_design_path(repo_root))) {
        sha256_file(frozen_repair_design_path(repo_root))
      } else {
        NA_character_
      },
      expected = "cfd025e7280ff30db4d95bcdf86da48c251080d516ba1324e80d88681138676a",
      stringsAsFactors = FALSE
    )
  )
  audit$pass <- !is.na(audit$observed) & audit$observed == audit$expected
  assert_repair_provenance(audit)
  audit
}

beta_phylo_dgp <- function(g, m, seed) {
  set.seed(seed)
  truth <- c(
    beta_mu_intercept = 0,
    beta_mu_x = 0.35,
    beta_sigma_intercept = log(0.25),
    beta_sigma_x = 0.20,
    log_tau = log(0.30)
  )
  tree <- ape::rcoal(g)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  effect <- as.vector(exp(truth[["log_tau"]]) * t(chol(A)) %*% stats::rnorm(g))
  names(effect) <- tree$tip.label
  spp_id <- factor(rep(tree$tip.label, each = m), levels = tree$tip.label)
  x <- as.numeric(scale(stats::rnorm(length(spp_id))))
  eta_mu <- truth[["beta_mu_intercept"]] +
    truth[["beta_mu_x"]] * x +
    effect[as.character(spp_id)]
  log_sigma <- truth[["beta_sigma_intercept"]] + truth[["beta_sigma_x"]] * x
  mu <- stats::plogis(eta_mu)
  phi <- exp(-2 * log_sigma)
  list(
    data = data.frame(
      y = stats::rbeta(length(mu), mu * phi, (1 - mu) * phi),
      x,
      spp_id
    ),
    tree = tree,
    truth = truth
  )
}

clean_text <- function(x) {
  x <- paste(as.character(x), collapse = " | ")
  trimws(gsub("[\r\n\t]+", " ", x))
}

recovery_attempt <- function(row) {
  started <- proc.time()[["elapsed"]]
  generated <- beta_phylo_dgp(row$g, row$m, row$seed)
  tree <- generated$tree
  warnings <- character()
  error <- NA_character_
  fit <- tryCatch(
    withCallingHandlers(
      drmTMB::drmTMB(
        drmTMB::bf(y ~ x + drmTMB::phylo(1 | spp_id, tree = tree), sigma ~ x),
        family = drmTMB::beta(),
        data = generated$data,
        control = drmTMB::drm_control(optimizer_preset = "robust")
      ),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) {
      error <<- clean_text(conditionMessage(e))
      NULL
    }
  )
  elapsed <- proc.time()[["elapsed"]] - started
  estimate <- c(
    beta_mu_intercept = NA_real_,
    beta_mu_x = NA_real_,
    beta_sigma_intercept = NA_real_,
    beta_sigma_x = NA_real_,
    log_tau = NA_real_
  )
  gradient <- numeric()
  if (!is.null(fit)) {
    estimate <- c(
      beta_mu_intercept = fit$par$mu[[1L]],
      beta_mu_x = fit$par$mu[[2L]],
      beta_sigma_intercept = fit$par$sigma[[1L]],
      beta_sigma_x = fit$par$sigma[[2L]],
      log_tau = log(fit$sdpars$mu[[1L]])
    )
    gradient <- tryCatch(
      as.numeric(fit$sdr$gradient.fixed),
      error = function(e) numeric()
    )
    if (!length(gradient) || any(!is.finite(gradient))) {
      gradient <- tryCatch(
        as.numeric(fit$obj$gr(fit$opt$par)),
        error = function(e) numeric()
      )
    }
  }
  base <- data.frame(
    cell_id = row$cell_id,
    cell_number = row$cell_number,
    g = row$g,
    m = row$m,
    replicate = row$replicate,
    seed = row$seed,
    elapsed = elapsed,
    fit_success = !is.null(fit),
    convergence = if (is.null(fit)) NA_integer_ else fit$opt$convergence,
    pdHess = if (is.null(fit)) FALSE else isTRUE(fit$sdr$pdHess),
    max_gradient = if (length(gradient) && all(is.finite(gradient))) {
      max(abs(gradient))
    } else {
      NA_real_
    },
    boundary = if (is.null(fit)) FALSE else isTRUE(fit$sdpars$mu[[1L]] < 1e-5),
    warning_count = length(warnings),
    warnings = clean_text(warnings),
    error = error,
    stringsAsFactors = FALSE
  )
  cbind(
    base,
    as.data.frame(as.list(setNames(
      generated$truth,
      paste0("truth_", names(generated$truth))
    ))),
    as.data.frame(as.list(setNames(
      estimate,
      paste0("estimate_", names(estimate))
    )))
  )
}

summarize_recovery <- function(raw) {
  parameters <- c(
    "beta_mu_intercept",
    "beta_mu_x",
    "beta_sigma_intercept",
    "beta_sigma_x",
    "log_tau"
  )
  cells <- unique(raw[c("cell_id", "cell_number", "g", "m")])
  do.call(
    rbind,
    lapply(seq_len(nrow(cells)), function(i) {
      do.call(
        rbind,
        lapply(parameters, function(parameter) {
          rows <- raw[raw$cell_id == cells$cell_id[[i]], , drop = FALSE]
          estimate <- rows[[paste0("estimate_", parameter)]]
          truth <- rows[[paste0("truth_", parameter)]]
          usable <- rows$convergence == 0L & is.finite(estimate)
          usable[is.na(usable)] <- FALSE
          error <- estimate[usable] - truth[usable]
          data.frame(
            cells[i, , drop = FALSE],
            parameter = parameter,
            attempted = nrow(rows),
            usable = sum(usable),
            convergence_rate = sum(rows$convergence == 0L, na.rm = TRUE) /
              nrow(rows),
            pdHess_rate = sum(rows$pdHess, na.rm = TRUE) / nrow(rows),
            boundary_rate = sum(rows$boundary, na.rm = TRUE) / nrow(rows),
            bias = if (length(error)) mean(error) else NA_real_,
            rmse = if (length(error)) sqrt(mean(error^2)) else NA_real_,
            mcse_bias = if (length(error) > 1L) {
              stats::sd(error) / sqrt(length(error))
            } else {
              NA_real_
            },
            stringsAsFactors = FALSE
          )
        })
      )
    })
  )
}

gate_summary <- function(raw, summary, reps) {
  high <- summary[summary$g >= 256L, , drop = FALSE]
  slope <- high[
    high$parameter %in% c("beta_mu_x", "beta_sigma_x", "log_tau"),
    ,
    drop = FALSE
  ]
  slope$limit <- 0.10
  key <- paste(raw$cell_id, raw$replicate, raw$seed, sep = ":")
  rows <- list(
    data.frame(
      gate = "attempt_rows",
      scope = "campaign",
      observed = nrow(raw),
      threshold = paste0("exactly ", 3L * reps),
      pass = nrow(raw) == 3L * reps
    ),
    data.frame(
      gate = "unique_attempt_keys",
      scope = "campaign",
      observed = length(unique(key)),
      threshold = paste0("exactly ", 3L * reps),
      pass = !anyDuplicated(key) && length(unique(key)) == 3L * reps
    )
  )
  for (cell in unique(high$cell_id)) {
    x <- high[high$cell_id == cell, , drop = FALSE][1L, ]
    rows[[length(rows) + 1L]] <- data.frame(
      gate = "convergence_rate",
      scope = cell,
      observed = x$convergence_rate,
      threshold = ">= 0.95",
      pass = x$attempted == reps && x$convergence_rate >= 0.95
    )
    rows[[length(rows) + 1L]] <- data.frame(
      gate = "pdHess_rate",
      scope = cell,
      observed = x$pdHess_rate,
      threshold = ">= 0.90",
      pass = x$attempted == reps && x$pdHess_rate >= 0.90
    )
  }
  for (i in seq_len(nrow(slope))) {
    rows[[length(rows) + 1L]] <- data.frame(
      gate = "absolute_bias",
      scope = paste0(slope$cell_id[[i]], ":", slope$parameter[[i]]),
      observed = abs(slope$bias[[i]]),
      threshold = "<= 0.10",
      pass = slope$usable[[i]] > 0L && abs(slope$bias[[i]]) <= slope$limit[[i]]
    )
  }
  out <- do.call(rbind, rows)
  out$status <- ifelse(out$pass, "PASS", "HOLD")
  out
}

rmse_difference <- function(raw) {
  parameters <- c(
    "beta_mu_intercept",
    "beta_mu_x",
    "beta_sigma_intercept",
    "beta_sigma_x",
    "log_tau"
  )
  do.call(
    rbind,
    lapply(seq_along(parameters), function(i) {
      parameter <- parameters[[i]]
      errors <- function(g) {
        rows <- raw[raw$g == g, , drop = FALSE]
        estimate <- rows[[paste0("estimate_", parameter)]]
        truth <- rows[[paste0("truth_", parameter)]]
        usable <- rows$convergence == 0L & is.finite(estimate)
        usable[is.na(usable)] <- FALSE
        estimate[usable] - truth[usable]
      }
      error256 <- errors(256L)
      error1024 <- errors(1024L)
      rmse256 <- if (length(error256)) sqrt(mean(error256^2)) else NA_real_
      rmse1024 <- if (length(error1024)) sqrt(mean(error1024^2)) else NA_real_
      set.seed(2026071690L + i)
      boot256 <- if (length(error256) > 1L) {
        replicate(
          1000L,
          sqrt(mean(sample(error256, length(error256), replace = TRUE)^2))
        )
      } else {
        NA_real_
      }
      boot1024 <- if (length(error1024) > 1L) {
        replicate(
          1000L,
          sqrt(mean(sample(error1024, length(error1024), replace = TRUE)^2))
        )
      } else {
        NA_real_
      }
      se_delta <- stats::sd(boot1024 - boot256, na.rm = TRUE)
      data.frame(
        parameter = parameter,
        n256 = length(error256),
        n1024 = length(error1024),
        rmse256 = rmse256,
        rmse1024 = rmse1024,
        delta = rmse1024 - rmse256,
        se_delta = se_delta,
        pass = is.finite(se_delta) && rmse1024 <= rmse256 + se_delta
      )
    })
  )
}

assert_empty_output_dir <- function(path) {
  if (dir.exists(path) && length(list.files(path, all.files = FALSE))) {
    stop(
      "Refusing to overwrite nonempty output directory: ",
      path,
      call. = FALSE
    )
  }
  invisible(path)
}

recovery_gate_bundle <- function(raw, reps) {
  summary <- summarize_recovery(raw)
  gates <- gate_summary(raw, summary, reps)
  rmse <- rmse_difference(raw)
  rmse_gates <- data.frame(
    gate = "rmse_nonincrease",
    scope = rmse$parameter,
    observed = rmse$delta,
    threshold = paste0(
      "delta <= MCSE (",
      format(rmse$se_delta, digits = 5L),
      ")"
    ),
    pass = rmse$pass,
    status = ifelse(rmse$pass, "PASS", "HOLD")
  )
  list(
    summary = summary,
    gates = rbind(gates, rmse_gates),
    rmse = rmse
  )
}

repair_promotion_decision <- function(repair_gates, pooled_gates) {
  repair_pass <- nrow(repair_gates) > 0L && isTRUE(all(repair_gates$pass))
  pooled_pass <- nrow(pooled_gates) > 0L && isTRUE(all(pooled_gates$pass))
  status <- if (!repair_pass) {
    "HOLD"
  } else if (!pooled_pass) {
    "INCONCLUSIVE"
  } else {
    "PASS"
  }
  data.frame(
    decision = "pr1_point_fit_recovery",
    repair_block = ifelse(repair_pass, "PASS", "HOLD"),
    pooled_m4 = ifelse(pooled_pass, "PASS", "HOLD"),
    status = status,
    promotion_authorized = identical(status, "PASS"),
    rule = paste(
      "repair HOLD => HOLD; repair PASS requires the pooled",
      "2400-attempt m=4 evidence to pass every unchanged gate"
    ),
    stringsAsFactors = FALSE
  )
}

run_recovery <- function(args = parse_args()) {
  if (!requireNamespace("ape", quietly = TRUE)) {
    stop("Package `ape` is required.", call. = FALSE)
  }
  if (!requireNamespace("devtools", quietly = TRUE)) {
    stop(
      "Package `devtools` is required for a source recovery run.",
      call. = FALSE
    )
  }
  script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  script_path <- if (length(script_arg)) {
    sub("^--file=", "", script_arg[[1L]])
  } else {
    "tools/run-beta-phylo-q1-recovery.R"
  }
  script_path <- normalizePath(script_path, mustWork = TRUE)
  repo_root <- normalizePath(
    file.path(dirname(script_path), ".."),
    mustWork = TRUE
  )
  repair_mode <- grepl("repair", args$mode, fixed = TRUE)
  provenance_audit <- if (repair_mode) {
    repair_provenance_audit(repo_root)
  } else {
    NULL
  }
  grid <- if (repair_mode) {
    repair_seed_grid(args$mode)
  } else {
    recovery_grid(args$reps, args$seed, args$m, seed_method = "offset")
  }
  frozen_repair_design <- frozen_repair_design_path(repo_root)
  if (repair_mode) {
    assert_frozen_repair_design(
      repair_seed_grid("addendum_repair"),
      frozen_repair_design
    )
  }
  seed_audit <- if (repair_mode) {
    repair_seed_audit(grid, repo_root, args$mode)
  } else {
    NULL
  }
  out_dir <- args$output %||%
    file.path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-07-16-beta-phylo-q1-pr1-recovery"
    )
  assert_empty_output_dir(out_dir)
  devtools::load_all(repo_root, quiet = TRUE)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  utils::write.table(
    grid,
    file.path(out_dir, "design.tsv"),
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = "NA"
  )
  if (!is.null(provenance_audit)) {
    utils::write.table(
      provenance_audit,
      file.path(out_dir, "provenance-audit.tsv"),
      sep = "\t",
      row.names = FALSE,
      quote = FALSE,
      na = "NA"
    )
  }
  if (!is.null(seed_audit)) {
    utils::write.table(
      seed_audit,
      file.path(out_dir, "seed-audit.tsv"),
      sep = "\t",
      row.names = FALSE,
      quote = FALSE,
      na = "NA"
    )
  }
  if (repair_mode) {
    git_head <- system2(
      Sys.which("git"),
      c("-C", repo_root, "rev-parse", "HEAD"),
      stdout = TRUE,
      stderr = TRUE
    )
    run_provenance <- data.frame(
      mode = args$mode,
      master_seed = args$seed,
      reps_per_cell = args$reps,
      m = args$m,
      attempted = nrow(grid),
      implementation_commit = "b6f74622d5c1041e438d7ac8b1ce654a40a55bc3",
      runner_commit = trimws(git_head[[1L]]),
      runner_sha256 = sha256_file(script_path),
      R_tree = provenance_audit$observed[
        provenance_audit$check == "tree_R"
      ],
      src_tree = provenance_audit$observed[
        provenance_audit$check == "tree_src"
      ],
      design_sha256 = sha256_file(file.path(out_dir, "design.tsv")),
      frozen_design_sha256 = sha256_file(frozen_repair_design),
      rng_kind = paste(repair_rng_kind(), collapse = "/"),
      package_version = as.character(utils::packageVersion("drmTMB")),
      stringsAsFactors = FALSE
    )
    utils::write.table(
      run_provenance,
      file.path(out_dir, "run-provenance.tsv"),
      sep = "\t",
      row.names = FALSE,
      quote = FALSE,
      na = "NA"
    )
  }
  if (identical(args$mode, "repair_design")) {
    writeLines(
      capture.output(sessionInfo()),
      file.path(out_dir, "session-info.txt")
    )
    return(invisible(list(grid = grid, seed_audit = seed_audit)))
  }
  rows <- split(grid, seq_len(nrow(grid)))
  worker <- function(x) {
    row <- x[1L, , drop = FALSE]
    if (repair_mode) {
      with_repair_rng(recovery_attempt(row))
    } else {
      recovery_attempt(row)
    }
  }
  result <- if (args$cores == 1L || .Platform$OS.type == "windows") {
    lapply(rows, worker)
  } else {
    parallel::mclapply(
      rows,
      worker,
      mc.cores = args$cores,
      mc.preschedule = FALSE
    )
  }
  raw <- do.call(rbind, result)
  bundle <- recovery_gate_bundle(raw, args$reps)
  summary <- bundle$summary
  gates <- bundle$gates
  rmse <- bundle$rmse
  utils::write.table(
    raw,
    file.path(out_dir, "raw-attempts.tsv"),
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = "NA"
  )
  utils::write.table(
    summary,
    file.path(out_dir, "summary.tsv"),
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = "NA"
  )
  utils::write.table(
    gates,
    file.path(out_dir, "gates.tsv"),
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = "NA"
  )
  utils::write.table(
    rmse,
    file.path(out_dir, "rmse-difference.tsv"),
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = "NA"
  )
  pooled <- NULL
  decision <- NULL
  if (identical(args$mode, "addendum_repair")) {
    prior_raw_path <- file.path(
      repo_root,
      "docs/dev-log/simulation-artifacts",
      "2026-07-16-beta-phylo-q1-pr1-recovery-addendum-hold",
      "raw-attempts.tsv"
    )
    prior_raw <- utils::read.delim(prior_raw_path, stringsAsFactors = FALSE)
    if (!identical(names(prior_raw), names(raw))) {
      stop(
        "Prior and repair m=4 raw-attempt schemas differ; pooled decision aborted.",
        call. = FALSE
      )
    }
    pooled_raw <- rbind(prior_raw, raw)
    pooled <- recovery_gate_bundle(pooled_raw, reps = 800L)
    decision <- repair_promotion_decision(gates, pooled$gates)
    pooled_output <- pooled_raw
    pooled_output$evidence_block <- rep(
      c("prior_m4_hold", "disjoint_repair"),
      c(nrow(prior_raw), nrow(raw))
    )
    utils::write.table(
      pooled_output,
      file.path(out_dir, "pooled-m4-raw-attempts.tsv"),
      sep = "\t",
      row.names = FALSE,
      quote = FALSE,
      na = "NA"
    )
    utils::write.table(
      pooled$summary,
      file.path(out_dir, "pooled-m4-summary.tsv"),
      sep = "\t",
      row.names = FALSE,
      quote = FALSE,
      na = "NA"
    )
    utils::write.table(
      pooled$gates,
      file.path(out_dir, "pooled-m4-gates.tsv"),
      sep = "\t",
      row.names = FALSE,
      quote = FALSE,
      na = "NA"
    )
    utils::write.table(
      pooled$rmse,
      file.path(out_dir, "pooled-m4-rmse-difference.tsv"),
      sep = "\t",
      row.names = FALSE,
      quote = FALSE,
      na = "NA"
    )
    utils::write.table(
      decision,
      file.path(out_dir, "promotion-decision.tsv"),
      sep = "\t",
      row.names = FALSE,
      quote = FALSE,
      na = "NA"
    )
  }
  writeLines(
    capture.output(sessionInfo()),
    file.path(out_dir, "session-info.txt")
  )
  invisible(list(
    raw = raw,
    summary = summary,
    gates = gates,
    rmse = rmse,
    pooled = pooled,
    decision = decision
  ))
}

if (sys.nframe() == 0L) {
  run_recovery()
}
