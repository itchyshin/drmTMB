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
fixtures <- args[-1L]
if (length(fixtures) == 0L) fixtures <- all_fixtures
if (length(fixtures) != 1L || !fixtures %in% all_fixtures) stop("run exactly one named fixture per R process", call. = FALSE)
requested_target <- Sys.getenv("DRMTMB_071_TARGET", "")
requested_engine <- Sys.getenv("DRMTMB_071_ENGINE", "")
run_suffix <- if (nzchar(requested_target) || nzchar(requested_engine)) paste0("-", gsub("[^A-Za-z0-9]+", "_", paste(requested_engine, requested_target, sep = "-"))) else ""
target_rows <- list(); point_rows <- list(); profile_rows <- list(); fixture_rows <- list()
for (id in fixtures) {
  spec <- make_fixture(id); data_path <- file.path(out, paste0(id, ".csv")); write.csv(spec$data, data_path, row.names = FALSE)
  fixture_rows[[id]] <- data.frame(fixture = id, bytes_md5 = hash(data_path), n = nrow(spec$data), stringsAsFactors = FALSE)
  ft <- tryCatch(drmTMB(spec$formula, spec$family, spec$data, engine = "tmb"), error = identity)
  fj_args <- list(formula = spec$formula, family = spec$family, data = spec$data, engine = "julia")
  if (!is.null(spec$marginal)) fj_args$marginal <- spec$marginal
  fj <- tryCatch(do.call(drmTMB, fj_args), error = identity)
  native_ok <- !inherits(ft, "error"); julia_ok <- !inherits(fj, "error")
  targets <- if (julia_ok) profile_targets(fj) else data.frame(parm = "<fit_failed>", target_class = "fit", profile_ready = FALSE)
  # Persist the denominator and target inventory BEFORE the first profile
  # call.  A JuliaCall/profile crash is an outcome, never a reason to lose an
  # attempted fixture from the evidence bank.
  write.table(data.frame(
    fixture = id, engine = c("tmb", "julia"),
    fit_status = c(if (native_ok) "returned" else "fit_failed", if (julia_ok) "returned" else "fit_failed"),
    converged = c(if (native_ok) is_converged(ft) else FALSE, if (julia_ok) is_converged(fj) else FALSE),
    loglik = c(if (native_ok) as.numeric(logLik(ft)) else NA_real_, if (julia_ok) as.numeric(logLik(fj)) else NA_real_),
    stringsAsFactors = FALSE
  ), file.path(out, paste0(id, "-fit-checkpoint.tsv")), sep = "\t", row.names = FALSE, quote = FALSE)
  write.table(data.frame(fixture = id, parm = targets$parm, target_class = targets$target_class, profile_ready = targets$profile_ready, stringsAsFactors = FALSE), file.path(out, paste0(id, "-target-checkpoint.tsv")), sep = "\t", row.names = FALSE, quote = FALSE)
  if (nzchar(requested_target)) {
    targets <- targets[targets$parm == requested_target, , drop = FALSE]
    if (nrow(targets) != 1L) stop("requested target is absent from the generated manifest: ", requested_target, call. = FALSE)
  }
  engines <- if (nzchar(requested_engine)) requested_engine else c("tmb", "julia")
  if (!all(engines %in% c("tmb", "julia"))) stop("DRMTMB_071_ENGINE must be tmb or julia", call. = FALSE)
  for (i in seq_len(nrow(targets))) {
    target <- targets$parm[[i]]; ready <- isTRUE(targets$profile_ready[[i]])
    target_rows[[length(target_rows) + 1L]] <- data.frame(fixture = id, parm = target, target_class = targets$target_class[[i]], profile_ready = ready, stringsAsFactors = FALSE)
    point_rows[[length(point_rows) + 1L]] <- data.frame(fixture = id, engine = "tmb", parm = target, fit_status = if (native_ok) "returned" else "fit_failed", converged = if (native_ok) is_converged(ft) else FALSE, loglik = if (native_ok) as.numeric(logLik(ft)) else NA_real_, error = one_line_error(ft), stringsAsFactors = FALSE)
    point_rows[[length(point_rows) + 1L]] <- data.frame(fixture = id, engine = "julia", parm = target, fit_status = if (julia_ok) "returned" else "fit_failed", converged = if (julia_ok) is_converged(fj) else FALSE, loglik = if (julia_ok) as.numeric(logLik(fj)) else NA_real_, error = one_line_error(fj), stringsAsFactors = FALSE)
    for (engine in engines) {
      fit <- if (identical(engine, "tmb")) ft else fj
      marker <- file.path(out, paste0(id, "-profile-boundary.log"))
      cat(sprintf("START\t%s\t%s\n", engine, target), file = marker, append = TRUE)
      ans <- if (!inherits(fit, "error") && (identical(engine, "tmb") || ready)) tryCatch(confint(fit, parm = target, method = "profile", threads = FALSE), error = identity) else NULL
      cat(sprintf("RETURN\t%s\t%s\n", engine, target), file = marker, append = TRUE)
      status <- if (inherits(fit, "error")) "fit_failed" else if (is.null(ans)) "not_profile_ready" else if (inherits(ans, "error")) "profile_failed" else if (!all(is.finite(c(ans$lower[[1L]], ans$upper[[1L]]))) ) "nonfinite_endpoint" else "profile"
      profile_rows[[length(profile_rows) + 1L]] <- data.frame(fixture = id, engine = engine, parm = target, profile_status = status, lower = if (is.data.frame(ans)) ans$lower[[1L]] else NA_real_, upper = if (is.data.frame(ans)) ans$upper[[1L]] else NA_real_, error = one_line_error(ans), stringsAsFactors = FALSE)
    }
  }
}
write.table(do.call(rbind, fixture_rows), file.path(out, paste0(id, run_suffix, "-fixture-manifest.tsv")), sep = "\t", row.names = FALSE, quote = FALSE)
write.table(do.call(rbind, target_rows), file.path(out, paste0(id, run_suffix, "-target-manifest.tsv")), sep = "\t", row.names = FALSE, quote = FALSE)
write.table(do.call(rbind, point_rows), file.path(out, paste0(id, run_suffix, "-point-receipt.tsv")), sep = "\t", row.names = FALSE, quote = FALSE)
write.table(do.call(rbind, profile_rows), file.path(out, paste0(id, run_suffix, "-profile-receipt.tsv")), sep = "\t", row.names = FALSE, quote = FALSE)
writeLines(c("# 0.7.1 four-fixture receipt", "", paste0("- drmTMB: `", stamp(root), "`"), paste0("- DRM.jl: `", stamp(jl), "`"), "- This is one frozen fixture per family; it is not coverage evidence."), file.path(out, "README.md"))
cat("FOUR_FIXTURE_RECEIPT_WRITTEN\n")
