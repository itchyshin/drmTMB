#!/usr/bin/env Rscript
# Frozen four-fixture point/profile receipt for the 0.7.1 ordinary-Laplace
# bridge.  This is one seed per fixture, not the 500-seed evidence campaign.
# Every target is emitted, including an error/non-finite profile endpoint.

suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1L || !identical(args[[1L]], "--write")) stop("usage: Rscript run-four-fixture-receipt.R --write [fixture]", call. = FALSE)
root <- normalizePath(".")
receipt_rel <- "docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/receipt/"
out <- file.path(root, sub("/$", "", receipt_rel))
jl <- Sys.getenv("DRM_JL_PATH", "")
if (!nzchar(jl) || !dir.exists(jl)) stop("DRM_JL_PATH must name the committed DRM.jl lane", call. = FALSE)
hash <- function(x) unname(tools::md5sum(x)[[1L]])
stamp <- function(repo) system2("git", c("-C", shQuote(repo), "rev-parse", "HEAD"), stdout = TRUE)
tree_clean <- function(repo, exclude_receipts = FALSE) {
  status <- system2("git", c("-C", shQuote(repo), "status", "--porcelain"), stdout = TRUE)
  if (exclude_receipts) status <- status[!grepl(paste0("^\\?\\? ", receipt_rel), status)]
  identical(status, character())
}
pkg_version <- function(package) {
  if (!requireNamespace(package, quietly = TRUE)) return(NA_character_)
  as.character(utils::packageVersion(package))
}
runner_path <- sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())][[1L]])
runner_sha256 <- unname(tools::sha256sum(runner_path)[[1L]])
drmtmb_tree_clean_at_start <- tree_clean(root, exclude_receipts = TRUE)
drm_jl_tree_clean_at_start <- tree_clean(jl)
dir.create(out, recursive = TRUE, showWarnings = FALSE)
one_line_error <- function(x) if (inherits(x, "error")) gsub("[\r\n]+", " | ", conditionMessage(x)) else NA_character_
runtime_identity <- function(command, args = "--version") {
  path <- Sys.which(command)
  if (!nzchar(path)) return(NA_character_)
  out <- tryCatch(system2(path, args, stdout = TRUE, stderr = TRUE), error = function(e) character())
  if (length(out) == 0L) NA_character_ else paste(out, collapse = " | ")
}

receipt_provenance <- function(fit, id, engine, target, spec, drm_jl_path) {
  julia <- identical(engine, "julia")
  coupled <- identical(id, "nb2_coupled")
  requested <- if (julia) fit$requested_marginal %||% if (coupled) "default" else "Laplace" else "none"
  effective <- if (julia) fit$effective_marginal %||% NA_character_ else "not_applicable"
  integrator <- if (julia) fit$effective_integrator %||% NA_character_ else "tmb_joint_laplace"
  convention <- if (!julia) "tmb_makeadfun_random_joint_laplace_ml" else if (coupled) "q2_augmented_state_laplace_ml_native_covariance" else "scalar_mode_curvature_laplace_ml"
  data.frame(
    fixture = id,
    engine = engine,
    parm = target,
    drmtmb_commit = stamp(root),
    drmtmb_tree_clean = drmtmb_tree_clean_at_start,
    drm_jl_commit = stamp(drm_jl_path),
    drm_jl_tree_clean = drm_jl_tree_clean_at_start,
    r_runtime = R.version.string,
    tmb_version = pkg_version("TMB"),
    juliacall_version = pkg_version("JuliaCall"),
    julia_runtime = if (julia) runtime_identity("julia") else NA_character_,
    julia_project = if (julia) normalizePath(drm_jl_path) else NA_character_,
    julia_threads = if (julia) Sys.getenv("JULIA_NUM_THREADS", "unset") else NA_character_,
    blas_threads = if (julia) Sys.getenv("OPENBLAS_NUM_THREADS", "unset") else NA_character_,
    requested_marginal = as.character(requested),
    effective_marginal = as.character(effective),
    effective_integrator = as.character(integrator),
    objective_convention = convention,
    runner_sha256 = runner_sha256,
    stringsAsFactors = FALSE
  )
}

make_fixture <- function(id) {
  set.seed(switch(id, binomial_ri = 71011L, poisson_ri = 71012L, nb2_ri = 71013L, nb2_coupled = 71014L))
  G <- 12L; ni <- 10L; group <- factor(rep(seq_len(G), each = ni))
  x <- rep(seq(-1, 1, length.out = ni), G); z <- rep(seq(1, -1, length.out = ni), G)
  b <- rnorm(G, 0, 0.45)
  if (identical(id, "binomial_ri")) return(list(data = data.frame(y = rbinom(G * ni, 1, plogis(-.1 + .55 * x + b[group])), x, group), formula = bf(y ~ x + (1 | group)), family = binomial(), marginal = "Laplace"))
  if (identical(id, "poisson_ri")) return(list(data = data.frame(y = rpois(G * ni, exp(.2 + .35 * x + b[group])), x, group), formula = bf(y ~ x + (1 | group)), family = poisson(), marginal = "Laplace"))
  if (identical(id, "nb2_ri")) return(list(data = data.frame(count = rnbinom(G * ni, mu = exp(.2 + .35 * x + b[group]), size = exp(-.25)), x, group), formula = bf(count ~ x + (1 | group), sigma ~ 1), family = nbinom2(), marginal = "Laplace"))
  c <- .45 * b + rnorm(G, 0, .25)
  list(data = data.frame(count = rnbinom(G * ni, mu = exp(.2 + .35 * x + b[group]), size = exp(-.3 + .2 * z + c[group])), x, z, group), formula = bf(count ~ x + (1 | p | group), sigma ~ z + (1 | p | group)), family = nbinom2(), marginal = NULL)
}

all_fixtures <- c("binomial_ri", "poisson_ri", "nb2_ri", "nb2_coupled")
declared_targets <- function(id) {
  common <- data.frame(
    parm = c("fixef:mu:(Intercept)", "fixef:mu:x"),
    target_class = "fixed-effect", profile_ready = TRUE,
    stringsAsFactors = FALSE
  )
  if (id %in% c("binomial_ri", "poisson_ri")) {
    return(rbind(common, data.frame(parm = "sd:mu:(1 | group)", target_class = "random-effect-sd", profile_ready = TRUE)))
  }
  if (identical(id, "nb2_ri")) {
    return(rbind(
      common,
      # `sigma` is exp(fixef:sigma:(Intercept)), not a second outer
      # parameter.  The frozen manifest compares the free log-link coordinate.
      data.frame(parm = c("fixef:sigma:(Intercept)", "sd:mu:(1 | group)"),
                 target_class = c("fixed-effect", "random-effect-sd"),
                 profile_ready = c(TRUE, TRUE))
    ))
  }
  rbind(
    common,
    data.frame(parm = c("fixef:sigma:(Intercept)", "fixef:sigma:z", "cholesky:recov:L11", "cholesky:recov:L22", "cholesky:recov:L21"),
               target_class = c("fixed-effect", "fixed-effect", "covariance-coordinate", "covariance-coordinate", "covariance-coordinate"),
               profile_ready = TRUE)
  )
}
same_manifest <- function(observed, declared) {
  observed <- observed[order(observed$parm), c("parm", "target_class"), drop = FALSE]
  declared <- declared[order(declared$parm), c("parm", "target_class"), drop = FALSE]
  row.names(observed) <- NULL
  row.names(declared) <- NULL
  identical(observed, declared)
}
fixtures <- args[-1L]
if (length(fixtures) == 0L) fixtures <- all_fixtures
if (length(fixtures) != 1L || !fixtures %in% all_fixtures) stop("run exactly one named fixture per R process", call. = FALSE)
requested_target <- Sys.getenv("DRMTMB_071_TARGET", "")
requested_engine <- Sys.getenv("DRMTMB_071_ENGINE", "")
if (identical(Sys.getenv("DRMTMB_071_STREAM_ALL", ""), "true")) {
  stop("stream-all mode is retired: run exactly one fixture-engine-target task and reconcile the durable sidecars", call. = FALSE)
}
if (!nzchar(requested_target) || !nzchar(requested_engine)) {
  stop(
    "set both DRMTMB_071_TARGET and DRMTMB_071_ENGINE; profile receipts are intentionally one engine-target task at a time and must be reconciled explicitly",
    call. = FALSE
  )
}
receipt_suffix <- function(engine, target) paste0("-", sub("_+$", "", gsub("[^A-Za-z0-9]+", "_", paste(engine, target, sep = "-"))))
target_rows <- list(); point_rows <- list(); profile_rows <- list(); fixture_rows <- list()
for (id in fixtures) {
  spec <- make_fixture(id); data_path <- file.path(out, paste0(id, ".csv")); write.csv(spec$data, data_path, row.names = FALSE)
  fixture_rows[[id]] <- data.frame(fixture = id, bytes_md5 = hash(data_path), n = nrow(spec$data), stringsAsFactors = FALSE)
  if (!requested_engine %in% c("tmb", "julia")) stop("DRMTMB_071_ENGINE must be tmb or julia", call. = FALSE)
  fit <- if (identical(requested_engine, "tmb")) {
    tryCatch(drmTMB(spec$formula, spec$family, spec$data, engine = "tmb"), error = identity)
  } else {
    fj_args <- list(formula = spec$formula, family = spec$family, data = spec$data, engine = "julia")
    if (!is.null(spec$marginal)) fj_args$marginal <- spec$marginal
    tryCatch(do.call(drmTMB, fj_args), error = identity)
  }
  declared <- declared_targets(id)
  observed_full <- if (inherits(fit, "error")) declared else profile_targets(fit)
  missing_common <- setdiff(declared$parm, observed_full$parm)
  if (length(missing_common)) stop("generated target manifest omits common targets for ", id, " on ", requested_engine, ": ", paste(missing_common, collapse = ", "), call. = FALSE)
  observed <- observed_full[observed_full$parm %in% declared$parm, , drop = FALSE]
  if (!same_manifest(observed, declared)) stop("generated target manifest disagrees with frozen declaration for ", id, " on ", requested_engine, call. = FALSE)
  target <- observed[observed$parm == requested_target, c("parm", "target_class", "profile_ready"), drop = FALSE]
  if (nrow(target) != 1L) stop("requested target is absent from the declared manifest: ", requested_target, call. = FALSE)
  ready <- isTRUE(target$profile_ready[[1L]])
  target_rows[[1L]] <- data.frame(fixture = id, target, stringsAsFactors = FALSE)
  point_rows[[1L]] <- data.frame(fixture = id, engine = requested_engine, parm = requested_target, fit_status = if (inherits(fit, "error")) "fit_failed" else "returned", converged = if (inherits(fit, "error")) FALSE else is_converged(fit), loglik = if (inherits(fit, "error")) NA_real_ else as.numeric(logLik(fit)), error = one_line_error(fit), stringsAsFactors = FALSE)
  sidecar <- receipt_suffix(requested_engine, requested_target)
  # Persist the denominator and manifest before profiling.  Each task owns one
  # engine only, avoiding JuliaCall teardown coupling with the native engine.
  write.table(fixture_rows[[id]], file.path(out, paste0(id, sidecar, "-fixture-manifest.tsv")), sep = "\t", row.names = FALSE, quote = FALSE)
  write.table(target_rows[[1L]], file.path(out, paste0(id, sidecar, "-target-manifest.tsv")), sep = "\t", row.names = FALSE, quote = FALSE)
  full_inventory <- observed_full[, c("parm", "target_class", "profile_ready"), drop = FALSE]
  full_inventory$fixture <- id
  full_inventory$engine <- requested_engine
  full_inventory$target_scope <- ifelse(full_inventory$parm %in% declared$parm, "common", "engine_only")
  write.table(full_inventory[, c("fixture", "engine", "parm", "target_class", "profile_ready", "target_scope")], file.path(out, paste0(id, sidecar, "-target-inventory.tsv")), sep = "\t", row.names = FALSE, quote = FALSE)
  write.table(point_rows[[1L]], file.path(out, paste0(id, sidecar, "-point-receipt.tsv")), sep = "\t", row.names = FALSE, quote = FALSE)
  provenance <- if (inherits(fit, "error")) {
    julia <- identical(requested_engine, "julia")
    coupled <- identical(id, "nb2_coupled")
    data.frame(
      fixture = id, engine = requested_engine, parm = requested_target,
      drmtmb_commit = stamp(root), drmtmb_tree_clean = drmtmb_tree_clean_at_start,
      drm_jl_commit = stamp(jl), drm_jl_tree_clean = drm_jl_tree_clean_at_start,
      r_runtime = R.version.string,
      tmb_version = pkg_version("TMB"), juliacall_version = pkg_version("JuliaCall"),
      julia_runtime = if (julia) runtime_identity("julia") else NA_character_,
      julia_project = if (julia) normalizePath(jl) else NA_character_,
      julia_threads = if (julia) Sys.getenv("JULIA_NUM_THREADS", "unset") else NA_character_,
      blas_threads = if (julia) Sys.getenv("OPENBLAS_NUM_THREADS", "unset") else NA_character_,
      requested_marginal = if (julia) if (coupled) "default" else "Laplace" else "none",
      effective_marginal = NA_character_, effective_integrator = NA_character_,
      objective_convention = if (!julia) "tmb_makeadfun_random_joint_laplace_ml" else if (coupled) "q2_augmented_state_laplace_ml_native_covariance" else "scalar_mode_curvature_laplace_ml",
      runner_sha256 = runner_sha256, stringsAsFactors = FALSE
    )
  } else {
    receipt_provenance(fit, id, requested_engine, requested_target, spec, jl)
  }
  write.table(provenance, file.path(out, paste0(id, sidecar, "-provenance.tsv")), sep = "\t", row.names = FALSE, quote = FALSE)
  # Leave a conservative terminal classification before entering the profile
  # engine.  If a JuliaCall teardown kills this R process, reconciliation sees
  # an attempted, failed profile rather than a silently absent denominator.
  provisional_profile <- data.frame(
    fixture = id, engine = requested_engine, parm = requested_target,
    profile_status = "profile_failed", lower = NA_real_, upper = NA_real_,
    error = "profile attempt did not return after its durable checkpoint",
    stringsAsFactors = FALSE
  )
  write.table(provisional_profile, file.path(out, paste0(id, sidecar, "-profile-receipt.tsv")), sep = "\t", row.names = FALSE, quote = FALSE)
  marker <- file.path(out, paste0(id, "-profile-boundary.log"))
  cat(sprintf("START\t%s\t%s\n", requested_engine, requested_target), file = marker, append = TRUE)
  profile_args <- if (identical(requested_engine, "tmb") && startsWith(requested_target, "cholesky:recov:")) {
    list(object = fit, parm = requested_target, method = "profile")
  } else {
    list(object = fit, parm = requested_target, method = "profile", threads = FALSE)
  }
  ans <- if (!inherits(fit, "error") && (identical(requested_engine, "tmb") || ready)) tryCatch(do.call(confint, profile_args), error = identity) else NULL
  status <- if (inherits(fit, "error")) "fit_failed" else if (is.null(ans)) "not_profile_ready" else if (inherits(ans, "error")) "profile_failed" else if (!all(is.finite(c(ans$lower[[1L]], ans$upper[[1L]])))) "nonfinite_endpoint" else "profile"
  profile_rows[[1L]] <- data.frame(fixture = id, engine = requested_engine, parm = requested_target, profile_status = status, lower = if (is.data.frame(ans)) ans$lower[[1L]] else NA_real_, upper = if (is.data.frame(ans)) ans$upper[[1L]] else NA_real_, error = one_line_error(ans), stringsAsFactors = FALSE)
  write.table(profile_rows[[1L]], file.path(out, paste0(id, sidecar, "-profile-receipt.tsv")), sep = "\t", row.names = FALSE, quote = FALSE)
  cat(sprintf("RETURN\t%s\t%s\n", requested_engine, requested_target), file = marker, append = TRUE)
}
cat("FOUR_FIXTURE_RECEIPT_WRITTEN\n")
