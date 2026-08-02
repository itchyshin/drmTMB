#!/usr/bin/env Rscript

# Current-source, fail-closed confirmation gate for the exact fixed-kappa
# Gaussian-mu mesh field-scale cell. Full runs are for Totoro/DRAC, never CI.
script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L])
root <- normalizePath(file.path(dirname(script), ".."))
setwd(root)
source(file.path(root, "tools", "mesh-spde-recovery-v3-helpers.R"))

smoke <- identical(tolower(Sys.getenv("DRMTMB_MESH_V3_MODE", "full")), "smoke")
if (!smoke && Sys.getenv("DRMTMB_MESH_V3_MODE", "full") != "full") {
  stop("DRMTMB_MESH_V3_MODE must be exactly 'full' or 'smoke'.")
}
suffix <- if (smoke) "-smoke" else ""
out <- Sys.getenv(
  "DRMTMB_MESH_V3_OUT",
  file.path(root, paste0(
    "docs/dev-log/simulation-artifacts/",
    "2026-08-02-mesh-spde-field-scale-recovery-v3", suffix
  ))
)

git_status <- system2("git", c("status", "--porcelain"), stdout = TRUE)
if (length(git_status)) {
  stop("The V3 runner requires a clean source tree before creating its receipt.")
}
if (dir.exists(out) && length(list.files(out, all.files = TRUE, no.. = TRUE))) {
  stop("The V3 output directory already contains files; receipts are immutable.")
}
dir.create(out, recursive = TRUE, showWarnings = FALSE)

sha256_file <- function(path) {
  path <- normalizePath(path, mustWork = TRUE)
  if (nzchar(Sys.which("sha256sum"))) {
    return(strsplit(system2("sha256sum", path, stdout = TRUE), "[[:space:]]+")[[1L]][1L])
  }
  if (nzchar(Sys.which("shasum"))) {
    return(strsplit(system2("shasum", c("-a", "256", path), stdout = TRUE), "[[:space:]]+")[[1L]][1L])
  }
  stop("A SHA-256 utility (sha256sum or shasum) is required.")
}

contract <- mesh_v3_contract()
design <- mesh_v3_design(smoke)
design_path <- file.path(out, "design.tsv")
utils::write.table(design, design_path, sep = "\t", row.names = FALSE, quote = FALSE)

source_sha <- trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE))
source_files <- c("DESCRIPTION", "R/drmTMB.R", "R/mesh.R", "src/drmTMB.cpp")
provenance <- data.frame(
  path = source_files,
  git_blob = vapply(source_files, function(x) {
    trimws(system2("git", c("hash-object", x), stdout = TRUE))
  }, character(1)),
  sha256 = vapply(source_files, sha256_file, character(1))
)
utils::write.table(provenance, file.path(out, "source-files.tsv"), sep = "\t",
                   row.names = FALSE, quote = FALSE)

prior_files <- c(
  "docs/dev-log/simulation-artifacts/2026-08-02-mesh-spde-field-scale-recovery-v2/raw-attempts.tsv",
  "docs/dev-log/simulation-artifacts/2026-08-02-mesh-spde-field-scale-recovery-v2/metadata.tsv",
  "docs/dev-log/simulation-artifacts/2026-08-02-mesh-spde-field-scale-recovery-v2/gate.tsv"
)
prior_hashes <- data.frame(
  path = prior_files,
  sha256 = vapply(prior_files, sha256_file, character(1))
)
utils::write.table(prior_hashes, file.path(out, "v2-receipt-hashes.tsv"), sep = "\t",
                   row.names = FALSE, quote = FALSE)

started_utc <- format(Sys.time(), tz = "UTC", usetz = TRUE)
write_metadata <- function(status, dll_path = "", finished = "") {
  values <- c(
    run_status = status, run_mode = if (smoke) "SMOKE_NOT_PROMOTION" else "FULL_PROMOTION_GATE",
    source_sha = source_sha, source_tree_at_start = "clean",
    runner_sha256 = sha256_file(script),
    helper_sha256 = sha256_file(file.path(root, "tools", "mesh-spde-recovery-v3-helpers.R")),
    design_sha256 = sha256_file(design_path), host = Sys.info()[["nodename"]],
    platform = R.version$platform, r_version = R.version.string,
    started_utc = started_utc,
    kappa_fixed = contract$kappa, field_scale_truth = contract$field_scale,
    residual_sd_truth = contract$residual_sd,
    n_sites = paste(contract$n_sites, collapse = ","),
    replicates_per_rung = contract$replicates_per_rung,
    attempts_expected = if (smoke) nrow(design) else length(contract$n_sites) * contract$replicates_per_rung,
    max_abs_relative_bias = contract$max_abs_relative_bias,
    max_rmse_log_scale = contract$max_rmse_log_scale,
    max_gradient = contract$max_gradient,
    monte_carlo_confidence = contract$confidence_level,
    dll_path = dll_path,
    dll_sha256 = if (nzchar(dll_path) && file.exists(dll_path)) sha256_file(dll_path) else "",
    raw_attempts_sha256 = if (file.exists(file.path(out, "raw-attempts.tsv"))) {
      sha256_file(file.path(out, "raw-attempts.tsv"))
    } else "",
    summary_sha256 = if (file.exists(file.path(out, "summary.tsv"))) {
      sha256_file(file.path(out, "summary.tsv"))
    } else "",
    gate_sha256 = if (file.exists(file.path(out, "gate.tsv"))) {
      sha256_file(file.path(out, "gate.tsv"))
    } else "",
    finished_utc = finished
  )
  utils::write.table(data.frame(key = names(values), value = unname(values)),
                     file.path(out, "metadata.tsv"), sep = "\t",
                     row.names = FALSE, quote = FALSE)
}
write_metadata("RUNNING")

run_campaign <- function() {
pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
dlls <- getLoadedDLLs()
dll_path <- if ("drmTMB" %in% names(dlls)) dlls[["drmTMB"]][["path"]] else ""
versions <- data.frame(
  package = c("drmTMB", "TMB", "Matrix", "fmesher", "sf"),
  version = vapply(c("drmTMB", "TMB", "Matrix", "fmesher", "sf"), function(x) {
    if (requireNamespace(x, quietly = TRUE)) as.character(utils::packageVersion(x)) else "NOT_INSTALLED"
  }, character(1))
)
utils::write.table(versions, file.path(out, "package-versions.tsv"), sep = "\t",
                   row.names = FALSE, quote = FALSE)
write_metadata("RUNNING", dll_path = dll_path)

raw_path <- file.path(out, "raw-attempts.tsv")
heartbeat_path <- file.path(out, "heartbeat.tsv")
append_tsv <- function(x, path) {
  fresh <- !file.exists(path)
  utils::write.table(x, path, sep = "\t", row.names = FALSE, quote = FALSE,
                     na = "", append = !fresh, col.names = fresh)
}

one_attempt <- function(n_site, replicate, seed) {
  started <- Sys.time()
  warnings <- character()
  n_vertex <- NA_integer_
  result <- tryCatch(withCallingHandlers({
    set.seed(seed)
    xy <- cbind(
      runif(n_site, 0, contract$domain_width),
      runif(n_site, 0, contract$domain_width)
    )
    rownames(xy) <- as.character(seq_len(n_site))
    attr(xy, "crs") <- sf::st_crs(3857)
    class(xy) <- c("drmTMB_coords", class(xy))
    mesh <- make_mesh(
      xy, kappa = contract$kappa, max.edge = contract$max_edge,
      offset = contract$offset, cutoff = contract$cutoff,
      max.n = max(160L, 2L * n_site)
    )
    n_vertex <- ncol(mesh$A_st)
    Q <- as.matrix(
      contract$kappa^4 * mesh$spde$c0 +
        2 * contract$kappa^2 * mesh$spde$g1 + mesh$spde$g2
    )
    omega <- contract$field_scale * as.vector(backsolve(chol(Q), rnorm(n_vertex)))
    dat <- data.frame(
      y = 1.2 + as.vector(mesh$A_st %*% omega) +
        rnorm(n_site, sd = contract$residual_sd),
      site = paste0("o", seq_len(n_site))
    )
    fit <- drmTMB(
      bf(y ~ spatial(1 | site, mesh = mesh), sigma ~ 1),
      gaussian(), dat
    )
    estimate <- unname(fit$sdpars$mu[["spatial(1 | site)"]])
    max_gradient <- max(abs(fit$obj$gr(fit$opt$par)))
    data.frame(
      n_site, replicate, seed, n_vertex, fit_ok = TRUE,
      convergence = fit$opt$convergence, pdHess = isTRUE(fit$sdr$pdHess),
      objective = fit$opt$objective, max_gradient,
      estimate, residual_estimate = exp(unname(fit$coefficients$sigma[[1L]])),
      relative_error = estimate / contract$field_scale - 1,
      near_zero = estimate < contract$near_zero_fraction * contract$field_scale,
      warning_count = length(warnings), warning = paste(warnings, collapse = " | "),
      error = "", stringsAsFactors = FALSE
    )
  }, warning = function(w) {
    warnings <<- c(warnings, conditionMessage(w))
    invokeRestart("muffleWarning")
  }), error = function(e) data.frame(
    n_site, replicate, seed, n_vertex, fit_ok = FALSE,
    convergence = NA_integer_, pdHess = NA, objective = NA_real_,
    max_gradient = NA_real_, estimate = NA_real_, residual_estimate = NA_real_,
    relative_error = NA_real_, near_zero = NA,
    warning_count = length(warnings), warning = paste(warnings, collapse = " | "),
    error = conditionMessage(e), stringsAsFactors = FALSE
  ))
  result$started_utc <- format(started, tz = "UTC", usetz = TRUE)
  result$finished_utc <- format(Sys.time(), tz = "UTC", usetz = TRUE)
  result$elapsed_seconds <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  result
}

rows <- vector("list", nrow(design))
for (i in seq_len(nrow(design))) {
  append_tsv(data.frame(
    attempt = i, n_site = design$n_site[[i]], seed = design$seed[[i]],
    status = "STARTED", timestamp_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
  ), heartbeat_path)
  rows[[i]] <- one_attempt(design$n_site[[i]], design$replicate[[i]], design$seed[[i]])
  append_tsv(rows[[i]], raw_path)
  append_tsv(data.frame(
    attempt = i, n_site = design$n_site[[i]], seed = design$seed[[i]],
    status = "COMPLETE", timestamp_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
  ), heartbeat_path)
}

rows <- do.call(rbind, rows)
summary <- mesh_v3_mc_summary(rows, smoke = smoke)
utils::write.table(summary, file.path(out, "summary.tsv"), sep = "\t",
                   row.names = FALSE, quote = FALSE)
all_pass <- !smoke && nrow(summary) == length(contract$n_sites) && all(summary$gate_pass)
decision <- if (smoke) {
  "SMOKE_ONLY_NOT_PROMOTION"
} else if (all_pass) {
  "PASS_POINT_RECOVERY_GATE"
} else {
  "BLOCKED_POINT_RECOVERY_GATE"
}
gate <- data.frame(
  expected_attempts = nrow(design), observed_attempts = nrow(rows),
  all_rungs_pass = all_pass, decision = decision
)
utils::write.table(gate, file.path(out, "gate.tsv"), sep = "\t",
                   row.names = FALSE, quote = FALSE)
write_metadata("COMPLETE", dll_path = dll_path,
               finished = format(Sys.time(), tz = "UTC", usetz = TRUE))
print(summary)
print(gate)
invisible(gate)
}

tryCatch(
  run_campaign(),
  error = function(e) {
    write_metadata("INCOMPLETE", finished = format(Sys.time(), tz = "UTC", usetz = TRUE))
    stop(e)
  }
)
