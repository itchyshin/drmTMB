#!/usr/bin/env Rscript

`%||%` <- function(x, y) if (is.null(x)) y else x

successor_script_context <- function() {
  script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  script_path <- if (length(script_arg)) {
    sub("^--file=", "", script_arg[[1L]])
  } else {
    "tools/run-beta-phylo-q1-successor-recovery.R"
  }
  script_path <- normalizePath(script_path, mustWork = TRUE)
  list(
    script_path = script_path,
    repo_root = normalizePath(
      file.path(dirname(script_path), ".."),
      mustWork = TRUE
    )
  )
}

successor_load_base_runner <- function(repo_root) {
  env <- new.env(parent = globalenv())
  sys.source(
    file.path(repo_root, "tools", "run-beta-phylo-q1-recovery.R"),
    envir = env
  )
  env
}

parse_successor_args <- function(args = commandArgs(trailingOnly = TRUE)) {
  out <- list(mode = "certification", output = NULL, cores = 1L, resume = FALSE)
  for (arg in args) {
    if (startsWith(arg, "--mode=")) {
      out$mode <- sub("^--mode=", "", arg)
    } else if (startsWith(arg, "--output=")) {
      out$output <- sub("^--output=", "", arg)
    } else if (startsWith(arg, "--cores=")) {
      out$cores <- as.integer(sub("^--cores=", "", arg))
    } else if (identical(arg, "--resume")) {
      out$resume <- TRUE
    } else {
      stop("Unknown argument: ", arg, call. = FALSE)
    }
  }
  if (!out$mode %in% c("design", "smoke", "certification")) {
    stop("`mode` must be design, smoke, or certification.", call. = FALSE)
  }
  if (is.na(out$cores) || out$cores < 1L || out$cores > 96L) {
    stop("`cores` must be an integer from 1 through 96.", call. = FALSE)
  }
  out
}

successor_rng_kind <- function() {
  c(
    kind = "Mersenne-Twister",
    normal.kind = "Inversion",
    sample.kind = "Rejection"
  )
}

successor_sha256 <- function(path) {
  sha256sum <- Sys.which("sha256sum")
  shasum <- Sys.which("shasum")
  output <- if (nzchar(sha256sum)) {
    system2(sha256sum, path, stdout = TRUE, stderr = TRUE)
  } else if (nzchar(shasum)) {
    system2(shasum, c("-a", "256", path), stdout = TRUE, stderr = TRUE)
  } else {
    stop(
      "A SHA-256 command is required for frozen-design authentication.",
      call. = FALSE
    )
  }
  if (!identical(attr(output, "status") %||% 0L, 0L) || length(output) != 1L) {
    stop("Could not calculate SHA-256 for ", path, call. = FALSE)
  }
  strsplit(trimws(output), "[[:space:]]+")[[1L]][[1L]]
}

with_successor_rng <- function(code) {
  old_kind <- RNGkind()
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  old_seed <- if (had_seed) get(".Random.seed", envir = .GlobalEnv) else NULL
  on.exit(
    {
      do.call(RNGkind, as.list(old_kind))
      if (had_seed) {
        assign(".Random.seed", old_seed, envir = .GlobalEnv)
      } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
        rm(".Random.seed", envir = .GlobalEnv)
      }
    },
    add = TRUE
  )
  do.call(RNGkind, as.list(successor_rng_kind()))
  force(code)
}

successor_seed_grid <- function(mode = c("certification", "smoke")) {
  mode <- match.arg(mode)
  spec <- if (mode == "certification") {
    list(reps = 400L, master_seed = 2026071641L)
  } else {
    list(reps = 1L, master_seed = 2026071640L)
  }
  cells <- data.frame(
    g = c(512L, 1024L),
    m = 4L,
    cell_number = 1:2,
    cell_id = c("g0512_m04", "g1024_m04")
  )
  grid <- cells[rep(seq_len(nrow(cells)), each = spec$reps), , drop = FALSE]
  grid$replicate <- rep(seq_len(spec$reps), times = nrow(cells))
  grid$seed <- with_successor_rng({
    set.seed(spec$master_seed)
    sample.int(.Machine$integer.max, nrow(grid), replace = FALSE)
  })
  rownames(grid) <- NULL
  attr(grid, "master_seed") <- spec$master_seed
  grid
}

frozen_successor_design_path <- function(repo_root) {
  file.path(
    repo_root,
    "docs/dev-log/simulation-designs",
    "2026-07-16-beta-phylo-q1-pr1-successor-high-information",
    "design.tsv"
  )
}

prior_design_paths <- function(repo_root) {
  roots <- c(
    "simulation-artifacts/2026-07-16-beta-phylo-q1-pr1-recovery-original-hold",
    "simulation-artifacts/2026-07-16-beta-phylo-q1-pr1-recovery-addendum-hold",
    "simulation-artifacts/2026-07-16-beta-phylo-q1-pr1-disjoint-repair-smoke-local",
    "simulation-artifacts/2026-07-16-beta-phylo-q1-pr1-disjoint-repair-pilot-aborted",
    "simulation-designs/2026-07-16-beta-phylo-q1-pr1-disjoint-repair"
  )
  setNames(
    file.path(repo_root, "docs/dev-log", roots, "design.tsv"),
    c(
      "original_m2",
      "prior_m4_nonindependent",
      "repair_smoke",
      "repair_pilot",
      "repair_design"
    )
  )
}

successor_seed_audit <- function(grid, repo_root, include_smoke = TRUE) {
  paths <- prior_design_paths(repo_root)
  missing <- paths[!file.exists(paths)]
  if (length(missing)) {
    stop(
      "Missing prior design: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  prior <- lapply(paths, function(path) {
    data <- utils::read.delim(path, stringsAsFactors = FALSE)
    if (!"seed" %in% names(data) || anyNA(data$seed)) {
      stop("Malformed prior design: ", path, call. = FALSE)
    }
    as.integer(data$seed)
  })
  audit <- rbind(
    data.frame(
      check = "unique_current_seeds",
      observed = length(unique(grid$seed)),
      expected = nrow(grid)
    ),
    do.call(
      rbind,
      lapply(names(prior), function(label) {
        data.frame(
          check = paste0("overlap_", label),
          observed = length(intersect(grid$seed, prior[[label]])),
          expected = 0L
        )
      })
    )
  )
  sibling <- if (include_smoke) {
    list(label = "successor_smoke", seeds = successor_seed_grid("smoke")$seed)
  } else {
    list(
      label = "successor_certification",
      seeds = successor_seed_grid("certification")$seed
    )
  }
  if (length(sibling$seeds)) {
    audit <- rbind(
      audit,
      data.frame(
        check = paste0("overlap_", sibling$label),
        observed = length(intersect(grid$seed, sibling$seeds)),
        expected = 0L
      )
    )
  }
  audit$pass <- audit$observed == audit$expected
  if (!all(audit$pass)) {
    stop(
      "Successor seed audit failed: ",
      paste(audit$check[!audit$pass], collapse = ", "),
      call. = FALSE
    )
  }
  audit
}

assert_frozen_successor_design <- function(grid, path) {
  if (!file.exists(path)) {
    stop("Frozen successor design is missing: ", path, call. = FALSE)
  }
  observed <- utils::read.delim(path, stringsAsFactors = FALSE)
  attr(grid, "master_seed") <- NULL
  if (!identical(observed, grid)) {
    stop(
      "Frozen successor design does not match generated grid.",
      call. = FALSE
    )
  }
  expected_hash <- "73685aed37eda78f7a5fb86cb90e0d6974a54fb1055d11214bdea8b316415b9f"
  if (!identical(successor_sha256(path), expected_hash)) {
    stop("Frozen successor design SHA-256 mismatch.", call. = FALSE)
  }
  invisible(TRUE)
}

mc_interval_gate <- function(summary, level = 0.95) {
  row <- summary[summary$parameter == "log_tau", , drop = FALSE]
  z <- stats::qnorm(1 - (1 - level) / 2)
  row$lower <- row$bias - z * row$mcse_bias
  row$upper <- row$bias + z * row$mcse_bias
  row$pass <- is.finite(row$lower) &
    is.finite(row$upper) &
    row$lower >= -0.10 &
    row$upper <= 0.10
  row
}

summarize_successor_recovery <- function(raw) {
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
          usable <- is.finite(estimate) & is.finite(truth)
          error <- estimate[usable] - truth[usable]
          data.frame(
            cells[i, , drop = FALSE],
            parameter = parameter,
            attempted = nrow(rows),
            usable = sum(usable),
            bias = if (length(error)) mean(error) else NA_real_,
            rmse = if (length(error)) sqrt(mean(error^2)) else NA_real_,
            mcse_bias = if (length(error) > 1L) {
              stats::sd(error) / sqrt(length(error))
            } else {
              NA_real_
            }
          )
        })
      )
    })
  )
}

successor_recovery_gates <- function(
  raw,
  base_runner = NULL,
  expected_reps,
  bootstrap_seed = 2026071695L
) {
  key <- paste(raw$cell_id, raw$replicate, raw$seed, sep = ":")
  counts <- table(raw$g)
  if (
    anyDuplicated(key) ||
      !identical(
        as.integer(counts[as.character(c(512L, 1024L))]),
        rep(expected_reps, 2L)
      )
  ) {
    stop(
      "Successor retained denominator or attempt keys are invalid.",
      call. = FALSE
    )
  }
  summary <- summarize_successor_recovery(raw)
  quality <- unique(raw[c("cell_id", "g", "m")])
  quality$convergence_rate <- vapply(
    quality$cell_id,
    function(id) {
      value <- raw$convergence[raw$cell_id == id]
      mean(!is.na(value) & value == 0L)
    },
    numeric(1)
  )
  quality$pdHess_rate <- vapply(
    quality$cell_id,
    function(id) {
      mean(raw$pdHess[raw$cell_id == id] %in% TRUE)
    },
    numeric(1)
  )
  estimate_columns <- paste0(
    "estimate_",
    c(
      "beta_mu_intercept",
      "beta_mu_x",
      "beta_sigma_intercept",
      "beta_sigma_x",
      "log_tau"
    )
  )
  quality$all_estimates_finite <- vapply(
    quality$cell_id,
    function(id) {
      rows <- raw[raw$cell_id == id, estimate_columns, drop = FALSE]
      all(vapply(rows, function(x) all(is.finite(x)), logical(1)))
    },
    logical(1)
  )
  quality$pass <- quality$convergence_rate >= 0.95 &
    quality$pdHess_rate >= 0.95 &
    quality$all_estimates_finite

  fixed <- summary[summary$parameter != "log_tau", , drop = FALSE]
  fixed$pass <- fixed$attempted == expected_reps &
    fixed$usable == expected_reps &
    is.finite(fixed$bias) &
    abs(fixed$bias) <= 0.10
  log_tau <- mc_interval_gate(summary)
  log_tau$pass <- log_tau$pass &
    log_tau$attempted == expected_reps &
    log_tau$usable == expected_reps

  parameters <- unique(summary$parameter)
  rmse <- do.call(
    rbind,
    lapply(seq_along(parameters), function(i) {
      parameter <- parameters[[i]]
      column <- paste0("estimate_", parameter)
      truth <- paste0("truth_", parameter)
      error512 <- raw[[column]][raw$g == 512L] - raw[[truth]][raw$g == 512L]
      error1024 <- raw[[column]][raw$g == 1024L] - raw[[truth]][raw$g == 1024L]
      error512 <- error512[is.finite(error512)]
      error1024 <- error1024[is.finite(error1024)]
      rmse512 <- sqrt(mean(error512^2))
      rmse1024 <- sqrt(mean(error1024^2))
      with_successor_rng({
        set.seed(bootstrap_seed + i)
        boot <- replicate(2000L, {
          sqrt(mean(sample(error1024, replace = TRUE)^2)) -
            sqrt(mean(sample(error512, replace = TRUE)^2))
        })
        interval <- stats::quantile(boot, c(0.025, 0.975), names = FALSE)
      })
      data.frame(
        parameter = parameter,
        n512 = length(error512),
        n1024 = length(error1024),
        rmse512 = rmse512,
        rmse1024 = rmse1024,
        delta = rmse1024 - rmse512,
        lower = interval[[1L]],
        upper = interval[[2L]],
        role = "descriptive_only"
      )
    })
  )

  cell_pass <- vapply(
    c(512L, 1024L),
    function(g) {
      quality$pass[quality$g == g] &&
        all(fixed$pass[fixed$g == g]) &&
        log_tau$pass[log_tau$g == g]
    },
    logical(1)
  )
  names(cell_pass) <- c("g512", "g1024")
  decision <- if (!cell_pass[["g1024"]]) {
    "HOLD_NO_PR1"
  } else if (cell_pass[["g512"]]) {
    "PASS_EXACT_G512_G1024"
  } else {
    "PASS_EXACT_G1024_ONLY"
  }
  list(
    summary = summary,
    quality = quality,
    fixed = fixed,
    log_tau = log_tau,
    rmse = rmse,
    decision = data.frame(
      g512 = cell_pass[["g512"]],
      g1024 = cell_pass[["g1024"]],
      status = decision
    )
  )
}

assert_successor_clean <- function(repo_root, protected_paths) {
  git <- Sys.which("git")
  if (!nzchar(git)) {
    stop("Git is required for protected-path authentication.", call. = FALSE)
  }
  status <- system2(
    git,
    c(
      "-C",
      repo_root,
      "status",
      "--porcelain",
      "--untracked-files=all",
      "--",
      "R",
      "src",
      protected_paths
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  if (length(status) || !identical(attr(status, "status") %||% 0L, 0L)) {
    stop(
      "Successor protected paths are not clean: ",
      paste(status, collapse = " | "),
      call. = FALSE
    )
  }
  tracked <- vapply(
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
  if (!all(tracked)) {
    stop(
      "Successor protected paths are untracked: ",
      paste(protected_paths[!tracked], collapse = ", "),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

allowed_compute_host <- function(
  host = Sys.info()[["nodename"]],
  slurm_job_id = Sys.getenv("SLURM_JOB_ID", unset = ""),
  cluster = Sys.getenv("CC_CLUSTER", unset = "")
) {
  if (grepl("^totoro([.-]|$)", tolower(host))) {
    return(TRUE)
  }
  allowed_cluster <- tolower(cluster) %in%
    c(
      "fir",
      "nibi",
      "rorqual",
      "trillium",
      "narval",
      "killarney",
      "vulcan",
      "tamia"
    )
  nzchar(slurm_job_id) && allowed_cluster
}

successor_preflight_manifest <- function(
  repo_root,
  protected_paths,
  design_paths,
  design_hashes,
  require_compute_host = TRUE
) {
  assert_successor_clean(repo_root, protected_paths)
  git <- Sys.which("git")
  rows <- list()
  add <- function(
    check,
    observed,
    expected,
    pass = identical(observed, expected)
  ) {
    rows[[length(rows) + 1L]] <<- data.frame(
      check = check,
      observed = as.character(observed),
      expected = as.character(expected),
      pass = isTRUE(pass),
      stringsAsFactors = FALSE
    )
  }
  add(
    "R_tree",
    trimws(system2(
      git,
      c("-C", repo_root, "rev-parse", "HEAD:R"),
      stdout = TRUE
    )),
    "6908d26231d0133020cdf71d11b022898b33bba3"
  )
  add(
    "src_tree",
    trimws(system2(
      git,
      c("-C", repo_root, "rev-parse", "HEAD:src"),
      stdout = TRUE
    )),
    "5e385ee36b910f907c807c5d5c3767b34e22a373"
  )
  for (path in protected_paths) {
    observed <- trimws(system2(
      git,
      c("-C", repo_root, "hash-object", path),
      stdout = TRUE
    ))
    expected <- trimws(system2(
      git,
      c("-C", repo_root, "rev-parse", paste0("HEAD:", path)),
      stdout = TRUE
    ))
    add(
      paste0("git_blob_", gsub("[^A-Za-z0-9]+", "_", path)),
      observed,
      expected
    )
  }
  for (name in names(design_paths)) {
    path <- design_paths[[name]]
    observed <- if (file.exists(path)) successor_sha256(path) else NA_character_
    add(paste0("sha256_", name), observed, unname(design_hashes[[name]]))
  }
  add("TMB_version", as.character(utils::packageVersion("TMB")), "1.9.21")
  add(
    "RNG_kind",
    paste(successor_rng_kind(), collapse = "/"),
    "Mersenne-Twister/Inversion/Rejection"
  )
  host <- Sys.info()[["nodename"]]
  add(
    "compute_host",
    host,
    "Totoro or active SLURM allocation on named DRAC cluster",
    !require_compute_host || allowed_compute_host(host)
  )
  add(
    "not_github_actions",
    Sys.getenv("GITHUB_ACTIONS", unset = "false"),
    "false",
    !tolower(Sys.getenv("GITHUB_ACTIONS", unset = "false")) %in%
      c("1", "true", "yes")
  )
  add(
    "OPENBLAS_NUM_THREADS",
    Sys.getenv("OPENBLAS_NUM_THREADS", unset = ""),
    "1"
  )
  out <- do.call(rbind, rows)
  if (!all(out$pass)) {
    stop(
      "Successor preflight failed: ",
      paste(out$check[!out$pass], collapse = ", "),
      call. = FALSE
    )
  }
  out
}

prior_design_hashes <- function() {
  c(
    original_m2 = "203025d9e593ae0b1a56d45fbbf35ab6f9fc959fee78bf4a14b1f5215f8e2b8a",
    prior_m4_nonindependent = "3c4d1eb2826f17d936fc85a07e7096166527ede00bb2e3901feacb5c2955503c",
    repair_smoke = "adaa06bb0d5ca100d37d573089d8c0df986d48f640d27d16fe64ba6ad53b047c",
    repair_pilot = "1e18d29890a6df5a9d83bea9277bfd0cc177433f06e310b0749011b38979834a",
    repair_design = "cfd025e7280ff30db4d95bcdf86da48c251080d516ba1324e80d88681138676a"
  )
}

write_tsv <- function(x, path) {
  utils::write.table(
    x,
    path,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = "NA"
  )
}

write_tsv_atomic <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile("atomic-", tmpdir = dirname(path), fileext = ".tsv")
  on.exit(unlink(temporary), add = TRUE)
  write_tsv(x, temporary)
  if (!file.rename(temporary, path)) {
    stop("Could not atomically move output into place: ", path, call. = FALSE)
  }
  invisible(path)
}

attempt_shard_path <- function(shard_dir, row) {
  file.path(
    shard_dir,
    sprintf("%s-r%04d-s%d.tsv", row$cell_id, row$replicate, row$seed)
  )
}

read_attempt_shard <- function(path, row) {
  value <- utils::read.delim(path, stringsAsFactors = FALSE)
  expected_names <- c(
    "cell_id",
    "cell_number",
    "g",
    "m",
    "replicate",
    "seed",
    "elapsed",
    "fit_success",
    "convergence",
    "pdHess",
    "max_gradient",
    "boundary",
    "warning_count",
    "warnings",
    "error",
    "truth_beta_mu_intercept",
    "truth_beta_mu_x",
    "truth_beta_sigma_intercept",
    "truth_beta_sigma_x",
    "truth_log_tau",
    "estimate_beta_mu_intercept",
    "estimate_beta_mu_x",
    "estimate_beta_sigma_intercept",
    "estimate_beta_sigma_x",
    "estimate_log_tau"
  )
  if (
    nrow(value) != 1L ||
      !identical(names(value), expected_names) ||
      value$cell_id != row$cell_id ||
      value$cell_number != row$cell_number ||
      value$g != row$g ||
      value$m != row$m ||
      value$replicate != row$replicate ||
      value$seed != row$seed
  ) {
    stop("Malformed or mismatched attempt shard: ", path, call. = FALSE)
  }
  value
}

prepare_resumable_output <- function(
  out_dir,
  grid,
  audit,
  preflight,
  resume = FALSE
) {
  design_path <- file.path(out_dir, "design.tsv")
  preflight_path <- file.path(out_dir, "preflight-manifest.tsv")
  audit_path <- file.path(out_dir, "seed-audit.tsv")
  if (!resume) {
    if (
      dir.exists(out_dir) &&
        length(list.files(out_dir, all.files = TRUE, no.. = TRUE))
    ) {
      stop("Output directory is not empty: ", out_dir, call. = FALSE)
    }
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    write_tsv_atomic(grid, design_path)
    write_tsv_atomic(audit, audit_path)
    write_tsv_atomic(preflight, preflight_path)
  } else {
    if (
      !file.exists(design_path) ||
        !file.exists(preflight_path) ||
        !file.exists(audit_path)
    ) {
      stop(
        "Resume requires an existing design and preflight manifest.",
        call. = FALSE
      )
    }
    observed_grid <- utils::read.delim(design_path, stringsAsFactors = FALSE)
    expected_grid <- grid
    attr(expected_grid, "master_seed") <- NULL
    observed_preflight <- utils::read.delim(
      preflight_path,
      stringsAsFactors = FALSE
    )
    observed_audit <- utils::read.delim(audit_path, stringsAsFactors = FALSE)
    if (
      !identical(observed_grid, expected_grid) ||
        !identical(observed_preflight, preflight) ||
        !identical(observed_audit, audit)
    ) {
      stop(
        "Resume design or preflight does not match the current run.",
        call. = FALSE
      )
    }
  }
  shard_dir <- file.path(out_dir, "attempts")
  dir.create(shard_dir, recursive = TRUE, showWarnings = FALSE)
  shard_dir
}

run_successor_recovery <- function(args = parse_successor_args()) {
  context <- successor_script_context()
  base <- successor_load_base_runner(context$repo_root)
  design_path <- frozen_successor_design_path(context$repo_root)
  grid <- successor_seed_grid(
    if (args$mode == "smoke") "smoke" else "certification"
  )
  audit <- successor_seed_audit(
    grid,
    context$repo_root,
    include_smoke = args$mode != "smoke"
  )
  out_dir <- args$output %||%
    file.path(
      context$repo_root,
      "docs/dev-log/simulation-artifacts",
      paste0("2026-07-16-beta-phylo-q1-pr1-successor-", args$mode)
    )
  if (args$mode == "design") {
    base$assert_empty_output_dir(out_dir)
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    write_tsv(grid, file.path(out_dir, "design.tsv"))
    write_tsv(audit, file.path(out_dir, "seed-audit.tsv"))
    writeLines(
      capture.output(sessionInfo()),
      file.path(out_dir, "session-info.txt")
    )
    return(invisible(list(grid = grid, audit = audit)))
  }

  assert_frozen_successor_design(
    successor_seed_grid("certification"),
    design_path
  )
  protected <- c(
    "AGENTS.md",
    "docs/dev-log/2026-07-16-beta-phylo-q1-pr1-successor-evidence-contract.md",
    "tests/testthat/test-beta-phylo-q1-successor-runners.R",
    "tools/run-beta-phylo-q1-recovery.R",
    "tools/run-beta-phylo-q1-successor-recovery.R",
    "tools/run-beta-phylo-q1-is-diagnostic.R",
    file.path(
      "docs/dev-log/simulation-designs",
      "2026-07-16-beta-phylo-q1-pr1-successor-high-information",
      "design.tsv"
    ),
    file.path(
      "docs/dev-log/simulation-designs",
      "2026-07-16-beta-phylo-q1-pr1-is-diagnostic",
      "design.tsv"
    )
  )
  design_paths <- c(
    prior_design_paths(context$repo_root),
    successor = design_path,
    diagnostic = file.path(
      context$repo_root,
      "docs/dev-log/simulation-designs",
      "2026-07-16-beta-phylo-q1-pr1-is-diagnostic",
      "design.tsv"
    )
  )
  design_hashes <- c(
    prior_design_hashes(),
    successor = "73685aed37eda78f7a5fb86cb90e0d6974a54fb1055d11214bdea8b316415b9f",
    diagnostic = "fefc3ca7cd143f946cbd68d2a99ddfab56ad2acb5001659911d393bb6dbdce6f"
  )
  preflight <- successor_preflight_manifest(
    context$repo_root,
    protected,
    design_paths,
    design_hashes,
    require_compute_host = TRUE
  )
  shard_dir <- prepare_resumable_output(
    out_dir,
    grid,
    audit,
    preflight,
    resume = args$resume
  )
  devtools::load_all(context$repo_root, quiet = TRUE)
  provenance <- data.frame(
    status = "PRE_DISPATCH",
    mode = args$mode,
    master_seed = attr(grid, "master_seed"),
    attempts = nrow(grid),
    git_head = trimws(system2(
      "git",
      c("-C", context$repo_root, "rev-parse", "HEAD"),
      stdout = TRUE
    )),
    runner_sha256 = base$sha256_file(context$script_path),
    base_runner_sha256 = base$sha256_file(file.path(
      context$repo_root,
      "tools",
      "run-beta-phylo-q1-recovery.R"
    )),
    design_sha256 = base$sha256_file(file.path(out_dir, "design.tsv")),
    rng_kind = paste(successor_rng_kind(), collapse = "/"),
    package_version = as.character(utils::packageVersion("drmTMB")),
    TMB_version = as.character(utils::packageVersion("TMB")),
    host = Sys.info()[["nodename"]]
  )
  write_tsv_atomic(provenance, file.path(out_dir, "run-provenance.tsv"))
  expected_shards <- vapply(
    seq_len(nrow(grid)),
    function(i) {
      basename(attempt_shard_path(shard_dir, grid[i, , drop = FALSE]))
    },
    character(1)
  )
  existing_shards <- list.files(shard_dir, pattern = "\\.tsv$")
  if (length(setdiff(existing_shards, expected_shards))) {
    stop("Attempt shard directory contains unexpected files.", call. = FALSE)
  }
  rows <- split(grid, seq_len(nrow(grid)))
  worker <- function(x) {
    row <- x[1L, , drop = FALSE]
    path <- attempt_shard_path(shard_dir, row)
    if (file.exists(path)) {
      return(read_attempt_shard(path, row))
    }
    value <- with_successor_rng(base$recovery_attempt(row))
    write_tsv_atomic(value, path)
    value
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
  if (any(vapply(result, inherits, logical(1), "try-error"))) {
    stop(
      "One or more workers failed; completed attempt shards were preserved.",
      call. = FALSE
    )
  }
  final_shards <- sort(list.files(shard_dir, pattern = "\\.tsv$"))
  if (!identical(final_shards, sort(expected_shards))) {
    stop("Attempt shard set is incomplete or unexpected.", call. = FALSE)
  }
  raw <- do.call(rbind, result)
  design_columns <- c("g", "m", "cell_number", "cell_id", "replicate", "seed")
  observed_design <- raw[design_columns]
  expected_design <- grid[design_columns]
  attr(expected_design, "master_seed") <- NULL
  rownames(observed_design) <- NULL
  rownames(expected_design) <- NULL
  if (
    !isTRUE(all.equal(
      observed_design,
      expected_design,
      tolerance = 0,
      check.attributes = FALSE
    ))
  ) {
    stop(
      "Aggregated attempts do not match the complete frozen design.",
      call. = FALSE
    )
  }
  gates <- successor_recovery_gates(
    raw,
    base,
    expected_reps = if (args$mode == "smoke") 1L else 400L
  )
  write_tsv_atomic(raw, file.path(out_dir, "raw-attempts.tsv"))
  write_tsv_atomic(gates$summary, file.path(out_dir, "summary.tsv"))
  write_tsv_atomic(gates$quality, file.path(out_dir, "quality-gates.tsv"))
  write_tsv_atomic(gates$fixed, file.path(out_dir, "fixed-effect-gates.tsv"))
  write_tsv_atomic(
    gates$log_tau,
    file.path(out_dir, "log-tau-equivalence-gates.tsv")
  )
  write_tsv_atomic(gates$rmse, file.path(out_dir, "rmse-difference.tsv"))
  write_tsv_atomic(gates$decision, file.path(out_dir, "promotion-decision.tsv"))
  writeLines(
    capture.output(sessionInfo()),
    file.path(out_dir, "session-info.txt")
  )
  provenance$status <- "COMPLETE"
  write_tsv_atomic(provenance, file.path(out_dir, "run-provenance.tsv"))
  invisible(c(list(raw = raw), gates))
}

if (sys.nframe() == 0L) {
  run_successor_recovery()
}
