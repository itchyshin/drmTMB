#!/usr/bin/env Rscript
# Fail-closed aggregate of the four independently reconciled 0.7.1 fixtures.
# It never reads the old unprefixed receipt files: each fixture's reconciler is
# the authority, and this script only joins those current-pin outputs.

r071_fixtures <- function() c("binomial_ri", "poisson_ri", "nb2_ri", "nb2_coupled")

r071_targets <- function(id) {
  common <- data.frame(
    parm = c("fixef:mu:(Intercept)", "fixef:mu:x"),
    target_class = "fixed-effect", profile_ready = TRUE,
    stringsAsFactors = FALSE
  )
  if (id %in% c("binomial_ri", "poisson_ri")) {
    return(rbind(common, data.frame(
      parm = "sd:mu:(1 | group)", target_class = "random-effect-sd",
      profile_ready = TRUE, stringsAsFactors = FALSE
    )))
  }
  if (identical(id, "nb2_ri")) {
    return(rbind(common, data.frame(
      parm = c("fixef:sigma:(Intercept)", "sd:mu:(1 | group)"),
      target_class = c("fixed-effect", "random-effect-sd"),
      profile_ready = TRUE, stringsAsFactors = FALSE
    )))
  }
  if (!identical(id, "nb2_coupled")) stop("unknown fixture: ", id, call. = FALSE)
  rbind(common, data.frame(
    parm = c("fixef:sigma:(Intercept)", "fixef:sigma:z", "cholesky:recov:L11",
             "cholesky:recov:L22", "cholesky:recov:L21"),
    target_class = c("fixed-effect", "fixed-effect", rep("covariance-coordinate", 3L)),
    profile_ready = TRUE, stringsAsFactors = FALSE
  ))
}

r071_sha <- function(repo) {
  out <- suppressWarnings(system2("git", c("-C", shQuote(repo), "rev-parse", "HEAD"), stdout = TRUE, stderr = FALSE))
  if (!is.null(attr(out, "status")) || length(out) != 1L) stop("cannot resolve HEAD for ", repo, call. = FALSE)
  out[[1L]]
}

r071_read_one <- function(path, label) {
  if (!file.exists(path)) stop("missing ", label, ": ", path, call. = FALSE)
  read.delim(path, check.names = FALSE, stringsAsFactors = FALSE)
}

r071_same_targets <- function(observed, expected, id) {
  needed <- c("parm", "target_class", "profile_ready")
  if (!identical(names(observed), needed)) stop("target manifest schema drift for ", id, call. = FALSE)
  observed <- observed[order(observed$parm), needed, drop = FALSE]
  expected <- expected[order(expected$parm), needed, drop = FALSE]
  row.names(observed) <- row.names(expected) <- NULL
  identical(observed, expected)
}

r071_key <- function(x) paste(x$fixture, x$engine, x$parm, sep = "\r")

r071_validate_fixture <- function(id, out, drmtmb_sha, drmjl_sha, runner_sha256) {
  targets <- r071_targets(id)
  profile <- r071_read_one(file.path(out, paste0(id, "-profile-receipt.tsv")), paste(id, "profile receipt"))
  point <- r071_read_one(file.path(out, paste0(id, "-point-receipt.tsv")), paste(id, "point receipt"))
  provenance <- r071_read_one(file.path(out, paste0(id, "-provenance.tsv")), paste(id, "provenance"))
  manifest <- r071_read_one(file.path(out, paste0(id, "-target-manifest.tsv")), paste(id, "target manifest"))
  if (!r071_same_targets(manifest, targets, id)) stop("target manifest differs from frozen declaration for ", id, call. = FALSE)

  expected <- expand.grid(engine = c("tmb", "julia"), parm = targets$parm,
                          KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  expected$fixture <- id
  expected <- expected[, c("fixture", "engine", "parm")]
  if (!all(c("fixture", "engine", "parm", "profile_status") %in% names(profile)) ||
      !all(c("fixture", "engine", "parm", "fit_status") %in% names(point))) {
    stop("receipt schema drift for ", id, call. = FALSE)
  }
  if (nrow(profile) != nrow(expected) || nrow(point) != nrow(expected) ||
      nrow(provenance) != nrow(expected) ||
      !setequal(r071_key(profile), r071_key(expected)) ||
      !setequal(r071_key(point), r071_key(expected)) ||
      !setequal(r071_key(provenance), r071_key(expected))) {
    stop("incomplete engine-target denominator for ", id, call. = FALSE)
  }
  allowed_profile <- c("profile", "fit_failed", "profile_failed", "nonfinite_endpoint", "truth_outside")
  if (any(!profile$profile_status %in% allowed_profile)) {
    stop("unknown profile classification for ", id, call. = FALSE)
  }
  required_provenance <- c("drmtmb_commit", "drmtmb_tree_clean", "drm_jl_commit", "drm_jl_tree_clean",
                           "requested_marginal", "effective_marginal", "effective_integrator", "objective_convention")
  if (!all(required_provenance %in% names(provenance)) ||
      any(provenance$drmtmb_commit != drmtmb_sha) || any(provenance$drm_jl_commit != drmjl_sha) ||
      !all(provenance$drmtmb_tree_clean) || !all(provenance$drm_jl_tree_clean) ||
      !"runner_sha256" %in% names(provenance) || any(provenance$runner_sha256 != runner_sha256)) {
    stop("stale or unclean provenance for ", id, call. = FALSE)
  }
  list(profile = profile, point = point, provenance = provenance,
       targets = transform(targets, fixture = id)[, c("fixture", "parm", "target_class", "profile_ready")])
}

r071_reconcile_all <- function(root = ".", drmjl_path,
                               out = file.path(root, "docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/receipt"),
                               summary_path = file.path(root, "docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/reconciled-summary.tsv")) {
  root <- normalizePath(root)
  drmjl_path <- normalizePath(drmjl_path)
  drmtmb_sha <- r071_sha(root)
  drmjl_sha <- r071_sha(drmjl_path)
  runner_path <- file.path(root, "docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/run-four-fixture-receipt.R")
  if (!file.exists(runner_path)) stop("missing receipt runner: ", runner_path, call. = FALSE)
  runner_sha256 <- unname(tools::sha256sum(runner_path)[[1L]])
  parts <- lapply(r071_fixtures(), r071_validate_fixture, out = out, drmtmb_sha = drmtmb_sha, drmjl_sha = drmjl_sha, runner_sha256 = runner_sha256)
  names(parts) <- r071_fixtures()
  profile <- do.call(rbind, lapply(parts, `[[`, "profile"))
  point <- do.call(rbind, lapply(parts, `[[`, "point"))
  provenance <- do.call(rbind, lapply(parts, `[[`, "provenance"))
  targets <- do.call(rbind, lapply(parts, `[[`, "targets"))
  profile_count <- function(x, fixture_names, engine, status) sum(x$fixture %in% fixture_names & x$engine == engine & x$profile_status == status)
  row_for <- function(capability_id, fixture_names) {
    target_count <- sum(targets$fixture %in% fixture_names)
    engine_target_count <- 2L * target_count
    finite <- profile_count(profile, fixture_names, "tmb", "profile") + profile_count(profile, fixture_names, "julia", "profile")
    nonfinite <- profile_count(profile, fixture_names, "tmb", "nonfinite_endpoint") + profile_count(profile, fixture_names, "julia", "nonfinite_endpoint")
    other <- engine_target_count - finite - nonfinite
    data.frame(
      capability_id = capability_id,
      fixtures = paste(fixture_names, collapse = ","), fixture_count = length(fixture_names),
      declared_target_count = target_count, engine_target_count = engine_target_count,
      finite_profile_count = finite, nonfinite_endpoint_count = nonfinite,
      other_terminal_count = other,
      classification = if (other > 0L) "CLASSIFIED_WITH_OTHER_TERMINAL" else if (nonfinite > 0L) "CLASSIFIED_WITH_RETAINED_NONFINITE_ENDPOINT" else "CLASSIFIED_FINITE",
      drmtmb_commit = drmtmb_sha, drm_jl_commit = drmjl_sha, runner_sha256 = runner_sha256,
      stringsAsFactors = FALSE
    )
  }
  summary <- rbind(
    row_for("ordinary_ri_scalar_laplace", c("binomial_ri", "poisson_ri", "nb2_ri")),
    row_for("ordinary_nb2_coupled_laplace", "nb2_coupled")
  )
  dir.create(dirname(summary_path), recursive = TRUE, showWarnings = FALSE)
  write.table(summary, summary_path, sep = "\t", row.names = FALSE, quote = FALSE)
  summary
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (!identical(args, "--write")) stop("usage: Rscript reconcile-four-fixture-summary.R --write", call. = FALSE)
  jl <- Sys.getenv("DRM_JL_PATH", "")
  if (!nzchar(jl) || !dir.exists(jl)) stop("DRM_JL_PATH must name the committed DRM.jl lane", call. = FALSE)
  r071_reconcile_all(drmjl_path = jl)
  cat("FOUR_FIXTURE_SUMMARY_RECONCILED\n")
}
