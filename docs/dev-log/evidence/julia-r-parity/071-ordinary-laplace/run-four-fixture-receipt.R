#!/usr/bin/env Rscript
# Frozen four-fixture point/profile receipt for the 0.7.1 ordinary-Laplace
# bridge.  This is one seed per fixture, not the 500-seed evidence campaign.
# Every target is emitted, including an error/non-finite profile endpoint.

suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1L || !identical(args[[1L]], "--write")) stop("usage: Rscript run-four-fixture-receipt.R --write [fixture]", call. = FALSE)
root <- normalizePath(".")
out <- file.path(root, "docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/receipt")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
jl <- Sys.getenv("DRM_JL_PATH", "")
if (!nzchar(jl) || !dir.exists(jl)) stop("DRM_JL_PATH must name the committed DRM.jl lane", call. = FALSE)
hash <- function(x) unname(tools::md5sum(x)[[1L]])
stamp <- function(repo) system2("git", c("-C", shQuote(repo), "rev-parse", "HEAD"), stdout = TRUE)
one_line_error <- function(x) if (inherits(x, "error")) gsub("[\r\n]+", " | ", conditionMessage(x)) else NA_character_

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
      data.frame(parm = c("fixef:sigma:(Intercept)", "sigma", "sd:mu:(1 | group)"),
                 target_class = c("fixed-effect", "distributional-scale", "random-effect-sd"),
                 profile_ready = c(TRUE, FALSE, TRUE))
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
  identical(
    observed[order(observed$parm), c("parm", "target_class", "profile_ready"), drop = FALSE],
    declared[order(declared$parm), c("parm", "target_class", "profile_ready"), drop = FALSE]
  )
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
  observed <- if (inherits(fit, "error")) declared else profile_targets(fit)
  if (!same_manifest(observed, declared)) stop("generated target manifest disagrees with frozen declaration for ", id, " on ", requested_engine, call. = FALSE)
  target <- declared[declared$parm == requested_target, , drop = FALSE]
  if (nrow(target) != 1L) stop("requested target is absent from the declared manifest: ", requested_target, call. = FALSE)
  ready <- isTRUE(target$profile_ready[[1L]])
  target_rows[[1L]] <- data.frame(fixture = id, target, stringsAsFactors = FALSE)
  point_rows[[1L]] <- data.frame(fixture = id, engine = requested_engine, parm = requested_target, fit_status = if (inherits(fit, "error")) "fit_failed" else "returned", converged = if (inherits(fit, "error")) FALSE else is_converged(fit), loglik = if (inherits(fit, "error")) NA_real_ else as.numeric(logLik(fit)), error = one_line_error(fit), stringsAsFactors = FALSE)
  sidecar <- receipt_suffix(requested_engine, requested_target)
  # Persist the denominator and manifest before profiling.  Each task owns one
  # engine only, avoiding JuliaCall teardown coupling with the native engine.
  write.table(fixture_rows[[id]], file.path(out, paste0(id, sidecar, "-fixture-manifest.tsv")), sep = "\t", row.names = FALSE, quote = FALSE)
  write.table(target_rows[[1L]], file.path(out, paste0(id, sidecar, "-target-manifest.tsv")), sep = "\t", row.names = FALSE, quote = FALSE)
  write.table(point_rows[[1L]], file.path(out, paste0(id, sidecar, "-point-receipt.tsv")), sep = "\t", row.names = FALSE, quote = FALSE)
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
