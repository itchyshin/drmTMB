#!/usr/bin/env Rscript
# Candidate-only adapter. The independent oracle owns reference calculations.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("usage: r-bridge.R fixture.json output.json")
if (identical(Sys.getenv("DRM_PRIOR_USE_INSTALLED"), "1")) {
  lib <- Sys.getenv("DRM_PRIOR_R_LIB")
  if (!nzchar(lib)) stop("DRM_PRIOR_R_LIB must identify the isolated package library")
  dep_lib <- Sys.getenv("DRM_PRIOR_DEP_LIB")
  .libPaths(c(lib, if (nzchar(dep_lib)) dep_lib, .libPaths()))
  suppressPackageStartupMessages(library(drmTMB, lib.loc = lib))
  if (!identical(normalizePath(getNamespaceInfo(asNamespace("drmTMB"), "path")),
                 normalizePath(file.path(lib, "drmTMB")))) stop("wrong drmTMB namespace")
} else {
  suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))
}
f <- jsonlite::fromJSON(args[[1]], simplifyVector = TRUE)
d <- as.data.frame(f$raw_data)
d$f <- factor(d$f, levels = c("A", "B"))
d$group <- factor(d$group)
if (!identical(as.integer(as.character(d$group)), as.integer(f$group)) ||
    !identical(as.numeric(d$y), as.numeric(f$y))) stop("response or grouping mismatch")
source_mean <- f$formula$mean
source_x <- model.matrix(as.formula(source_mean), d)
d$fB <- as.numeric(d$f == "B")
transport_mean <- gsub('I(as.numeric(f == "B"))', "fB", source_mean, fixed = TRUE)
x <- model.matrix(as.formula(transport_mean), d)
w <- model.matrix(as.formula(f$formula$scale), d)
same_matrix <- function(a, b) identical(dim(a), dim(b)) &&
  isTRUE(all.equal(as.numeric(a), as.numeric(b), tolerance = 1e-14))
if (!same_matrix(source_x, f$X) || !same_matrix(x, f$X) || !same_matrix(w, f$W)) stop("fixture model-matrix mismatch")
mean_expr <- paste0(transport_mean, " + ", f$formula$random_intercept)
fm <- eval(parse(text = sprintf("bf(mu = %s, sigma = %s)", mean_expr, f$formula$scale)))
pr <- lapply(seq_len(if (is.data.frame(f$priors)) nrow(f$priors) else 0L), function(i) {
  p <- f$priors[i, ]
  block <- if (p$block == "beta") "mu" else "sigma"
  col <- if (block == "mu") colnames(x)[p$index + 1L] else colnames(w)[p$index + 1L]
  if (p$kind == "normal") drm_prior_normal(block, col, mean = p$mean, sd = p$sd)
  else drm_prior_ridge(block, col, lambda = p$lam)
})
priors <- if (length(pr)) do.call(drm_priors, pr) else NULL
raw_factor_control <- "not_applicable"
if (!identical(source_mean, transport_mean)) {
  original <- eval(parse(text = sprintf("bf(mu = %s + %s, sigma = %s)",
    source_mean, f$formula$random_intercept, f$formula$scale)))
  denied <- tryCatch({ drmTMB(original, data = d, engine = "julia"); NULL }, error = identity)
  if (!inherits(denied, "error") || !grepl("factor coefficient names", conditionMessage(denied), fixed = TRUE))
    stop("raw factor bridge refusal did not hold")
  raw_factor_control <- "raw_factor_formula_refused"
}
fit <- drmTMB(fm, data = d, priors = priors, engine = "julia")
negative_control <- "not_requested"
if (identical(Sys.getenv("DRM_PRIOR_NEGATIVE_SELECTOR"), "1")) {
  payload <- fit$bridge_payload
  payload$options$prior_expected[[1L]]$coef <- "__deliberate_wrong_coordinate__"
  bad <- tryCatch({
    drmTMB:::drm_julia_call_conditional_gaussian_components(
      formula = payload$formula, family = "gaussian", data = payload$data,
      tree = payload$tree, options = payload$options)
    NULL
  }, error = identity)
  if (!inherits(bad, "error") || !grepl("resolved prior coordinates differ", conditionMessage(bad), fixed = TRUE))
    stop("wrong-selector negative control was not rejected as expected")
  bad_names <- as.character(fit$bridge$coef_names)
  mu_columns <- grep("^mu_", bad_names)
  if (length(mu_columns) < 2L) stop("negative control requires two mean columns")
  bad_names[mu_columns[2L]] <- paste0(bad_names[mu_columns[2L]], "__wrong")
  bad_labels <- tryCatch({
    drmTMB:::drm_julia_bridge_check_coef_labels(bad_names, fit$bridge_payload)
    NULL
  }, error = identity)
  if (!inherits(bad_labels, "error") || !grepl("do not match", conditionMessage(bad_labels), fixed = TRUE))
    stop("wrong-column negative control was not rejected")
  denied <- tryCatch({ confint(fit, method = "profile"); NULL }, error = identity)
  if (!inherits(denied, "error") || !grepl("fixed-effect prior", conditionMessage(denied), fixed = TRUE))
    stop("active-prior profile was not refused as expected: ",
         if (inherits(denied, "error")) conditionMessage(denied) else "returned successfully")
  negative_control <- "wrong_selector_wrong_column_and_profile_refused"
}
beta <- coef(fit, dpar = "mu")
gamma <- coef(fit, dpar = "sigma")
if (!identical(names(beta), colnames(x)) || !identical(names(gamma), colnames(w)))
  stop("bridge coefficient names or order do not match fixture matrices")
sds <- unlist(fit$sdpars$mu, use.names = TRUE)
if (length(sds) != 1L || !is.finite(sds[[1]]) || sds[[1]] < 0) stop("unexpected bridge group SD")
converged <- fit$bridge[["converged"]]
if (!is.logical(converged) || length(converged) != 1L || is.na(converged))
  stop("bridge did not supply an unambiguous convergence status")
result <- list(schema_version = 1, id = f$id, engine = "R/Julia-bridge",
  namespace_path = getNamespaceInfo(asNamespace("drmTMB"), "path"),
  dll = getLoadedDLLs()[["drmTMB"]][["path"]],
  dll_sha256 = strsplit(system2("shasum", c("-a", "256", shQuote(getLoadedDLLs()[["drmTMB"]][["path"]])), stdout = TRUE), "[[:space:]]+")[[1]][1],
  X_columns = I(colnames(x)), W_columns = I(colnames(w)),
  source_formula = source_mean, transport_formula = transport_mean,
  column_mapping = as.list(stats::setNames(colnames(x), colnames(source_x))),
  raw_factor_control = raw_factor_control,
  coordinate_order = c(paste0("beta:", colnames(x)), paste0("gamma:", colnames(w)), "tau"),
  negative_control = negative_control,
  selectors = fit$resolved_priors,
  point = list(status = "arbitrary_point_unavailable"),
  fit = list(converged = converged, theta = c(unname(beta), unname(gamma), unname(sds)),
    sd_name = names(sds), objective = fit$penalized_objective,
    data_nll = -fit$logLik, prior = fit$fixed_prior_penalty,
    gradient_availability = if (length(fit$penalized_gradient)) "reported_native_order_unverified" else "unavailable",
    gradient_native = fit$penalized_gradient,
    hessian_availability = "unavailable",
    bridge_diagnostics = fit$bridge[c("converged", "convergence", "optimizer", "estim_method")]))
jsonlite::write_json(result, args[[2]], auto_unbox = TRUE, digits = 16, pretty = TRUE, na = "null")
