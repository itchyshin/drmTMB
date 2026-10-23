# Retained parametric-bootstrap shards (issue #861; owner decision 18,
# 2026-10-11: internal only, no export).
#
# A shard is a reproducible slice of a parametric bootstrap. It keeps every
# attempted refit -- its replicate index, the seed that generated its data,
# its terminal status and failure message, and the target draws -- so
# expensive refits can be run as independent jobs (cluster array tasks,
# separate R sessions on Windows) and joined afterwards. Replicate `j` draws
# its data from its own L'Ecuyer-CMRG stream, derived only from the shard's
# `seed` and `j`, so a replicate's data never depend on which shard or worker
# ran it. Splitting `1:R` into shards and combining them therefore gives the
# same attempt ledger as one shard over `1:R`.
#
# This does not change `confint(method = "bootstrap")`, its interval
# estimand, or its denominators, and it makes no calibration claim.

drm_bootstrap_shard_schema_version <- 1L

# Internal. Run bootstrap replicates `indices` for `parm` and return a
# "drm_bootstrap_shard". `parallel`/`workers` follow ?drmTMB-parallel; every
# backend returns the same shard.
drm_bootstrap_shard <- function(
  object,
  parm,
  indices,
  seed,
  refit_control = NULL,
  re_form = NULL,
  parallel = c("none", "multicore", "cluster"),
  workers = NULL
) {
  parallel <- match.arg(parallel)
  if (!inherits(object, "drmTMB")) {
    cli::cli_abort("{.arg object} must be a {.cls drmTMB} fit.")
  }
  if (is.null(object$data)) {
    cli::cli_abort(c(
      "Bootstrap shards need the model data stored in {.code fit$data}.",
      i = "Refit with {.code drm_control(keep_data = TRUE)}."
    ))
  }
  if (
    !is.numeric(indices) || !length(indices) || anyNA(indices) ||
      any(indices < 1) || any(indices != as.integer(indices)) ||
      anyDuplicated(indices)
  ) {
    cli::cli_abort(
      "{.arg indices} must be distinct positive whole numbers."
    )
  }
  if (
    !is.numeric(seed) || length(seed) != 1L || is.na(seed) ||
      seed != as.integer(seed)
  ) {
    cli::cli_abort("{.arg seed} must be a single whole number.")
  }
  indices <- sort(as.integer(indices))
  seed <- as.integer(seed)
  targets <- profile_match_confint_targets(
    drm_profile_targets(object),
    parm,
    fixed_only = FALSE
  )
  target_names <- targets$parm
  plan <- bootstrap_parallel_plan(
    length(indices),
    parallel = parallel,
    workers = workers
  )
  refit_control <- bootstrap_refit_control(refit_control)
  if (!identical(plan$backend, "none")) {
    refit_control$parallel <- "none"
  }
  worker <- function(index) {
    simulations <- drm_bootstrap_replicate_simulation(
      object,
      seed = seed,
      index = index,
      re_form = re_form
    )
    out <- bootstrap_refit_one(
      object = object,
      simulations = simulations,
      index = 1L,
      target_names = target_names,
      refit_control = refit_control
    )
    out$bootstrap <- index
    out$replicate_seed <- seed
    out
  }
  attempts <- do.call(rbind, drm_parallel_lapply(indices, worker, plan))
  row.names(attempts) <- NULL
  structure(
    list(
      header = drm_bootstrap_shard_header(
        object,
        target_names = target_names,
        seed = seed,
        re_form = re_form,
        refit_control = refit_control
      ),
      indices = indices,
      attempts = attempts
    ),
    class = "drm_bootstrap_shard"
  )
}

# Internal. Join compatible shards. Fails closed when the shards come from
# different fits, targets, settings, package builds or schemas, or when any
# replicate (seed, index) appears twice. All attempts, failures included, are
# retained.
drm_bootstrap_combine <- function(...) {
  shards <- list(...)
  if (length(shards) == 1L && is.list(shards[[1L]]) &&
    !inherits(shards[[1L]], "drm_bootstrap_shard")) {
    shards <- shards[[1L]]
  }
  if (!length(shards) ||
    !all(vapply(shards, inherits, logical(1L), "drm_bootstrap_shard"))) {
    cli::cli_abort(
      "Every input must be a {.cls drm_bootstrap_shard}.",
      class = "drmTMB_bootstrap_shard_incompatible"
    )
  }
  reference <- shards[[1L]]$header
  for (k in seq_along(shards)[-1L]) {
    header <- shards[[k]]$header
    differing <- names(reference)[!vapply(
      names(reference),
      function(field) identical(reference[[field]], header[[field]]),
      logical(1L)
    )]
    if (length(differing) || !identical(sort(names(reference)), sort(names(header)))) {
      cli::cli_abort(
        c(
          "Bootstrap shard {k} is not compatible with shard 1.",
          x = "Differing header field{?s}: {.field {differing}}.",
          i = "Only shards from the same fit, targets, seed, settings, package build and schema can be combined."
        ),
        class = "drmTMB_bootstrap_shard_incompatible"
      )
    }
  }
  indices <- unlist(lapply(shards, `[[`, "indices"), use.names = FALSE)
  overlap <- unique(indices[duplicated(indices)])
  if (length(overlap)) {
    cli::cli_abort(
      c(
        "Bootstrap shards overlap: replicate{?s} {overlap} appear{?s/} more than once.",
        i = "Each replicate's data come from the shared seed and its index, so an overlapping replicate would be counted twice."
      ),
      class = "drmTMB_bootstrap_shard_overlap"
    )
  }
  attempts <- do.call(rbind, lapply(shards, `[[`, "attempts"))
  attempts <- attempts[order(attempts$bootstrap, match(attempts$parm, reference$targets)), , drop = FALSE]
  row.names(attempts) <- NULL
  structure(
    list(header = reference, indices = sort(indices), attempts = attempts),
    class = "drm_bootstrap_shard"
  )
}

# Internal. Per-target denominators of a shard: attempted, usable, and failed
# refits, with failures split by terminal status. Nothing is dropped.
drm_bootstrap_ledger <- function(shard) {
  if (!inherits(shard, "drm_bootstrap_shard")) {
    cli::cli_abort("{.arg shard} must be a {.cls drm_bootstrap_shard}.")
  }
  attempts <- shard$attempts
  rows <- lapply(shard$header$targets, function(target) {
    a <- attempts[attempts$parm == target, , drop = FALSE]
    data.frame(
      parm = target,
      attempted = nrow(a),
      usable = sum(a$refit_ok & a$estimate_finite),
      refit_error = sum(a$refit_status == "refit_error"),
      refit_nonconverged = sum(a$refit_status == "refit_nonconverged"),
      target_missing = sum(a$refit_status == "target_missing"),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

drm_bootstrap_shard_header <- function(
  object,
  target_names,
  seed,
  re_form,
  refit_control
) {
  provenance <- drm_provenance()
  list(
    schema_version = drm_bootstrap_shard_schema_version,
    package_version = provenance$package_version,
    git_sha = provenance$git_sha,
    estimator = object$estimator,
    fit_fingerprint = list(
      formula = paste(deparse(object$formula), collapse = " "),
      family = paste(deparse(object$family), collapse = " "),
      nobs = object$nobs,
      par = unname(object$opt$par),
      objective = unname(object$opt$objective)
    ),
    targets = target_names,
    seed = seed,
    re_form = if (is.null(re_form)) "NULL" else paste(deparse(re_form), collapse = " "),
    refit = list(
      optimizer_method = refit_control$optimizer_method,
      optimizer_preset = refit_control$optimizer_preset,
      se = refit_control$se,
      multi_start = refit_control$multi_start
    )
  )
}

# Simulate replicate `index` from its own L'Ecuyer-CMRG stream: stream
# `index` after `set.seed(seed, kind = "L'Ecuyer-CMRG")`. The caller's RNG
# kind and stream are restored afterwards.
drm_bootstrap_replicate_simulation <- function(object, seed, index, re_form) {
  had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  saved_seed <- if (had_seed) get(".Random.seed", envir = globalenv())
  saved_kind <- RNGkind()
  on.exit(
    {
      RNGkind(saved_kind[[1L]], saved_kind[[2L]], saved_kind[[3L]])
      if (had_seed) {
        assign(".Random.seed", saved_seed, envir = globalenv())
      } else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
        rm(".Random.seed", envir = globalenv())
      }
    },
    add = TRUE
  )
  set.seed(seed, kind = "L'Ecuyer-CMRG")
  stream <- get(".Random.seed", envir = globalenv())
  for (k in seq_len(index)) {
    stream <- parallel::nextRNGStream(stream)
  }
  assign(".Random.seed", stream, envir = globalenv())
  stats::simulate(object, nsim = 1L, re.form = re_form)
}
