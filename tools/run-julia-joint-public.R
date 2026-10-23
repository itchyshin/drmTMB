#!/usr/bin/env Rscript
# Two registered public workflows. Retain native failures separately from
# internal adapter checks; never weaken the frozen numerical tolerance.
args <- commandArgs(TRUE)
if (length(args) != 3L) stop("usage: run-julia-joint-public.R JULIA_ROOT FROZEN_JSON NEW_PREFIX")
julia_root <- normalizePath(args[[1]], mustWork = TRUE)
fixture <- normalizePath(args[[2]], mustWork = TRUE)
prefix <- args[[3]]
if (any(file.exists(paste0(prefix, c(".json", ".rds"))))) stop("refusing stale output")
Sys.setenv(DRM_JL_PATH = julia_root, DRMTMB_JULIA_TESTS = "true",
           JULIA_NUM_THREADS = "1", OPENBLAS_NUM_THREADS = "1")
root <- normalizePath(".", mustWork = TRUE)
sha <- function(path) digest::digest(file = path, algo = "sha256")
manifest <- function() {
  paths <- c(sort(list.files("R", pattern = "[.]R$", full.names = TRUE)), "NAMESPACE",
    sort(list.files("src", pattern = "[.](cpp|h|hpp)$", full.names = TRUE, recursive = TRUE)),
    sort(list.files(file.path(julia_root, "src"), pattern = "[.]jl$", full.names = TRUE, recursive = TRUE)))
  paths <- normalizePath(paths, mustWork = TRUE)
  as.list(setNames(vapply(paths, sha, ""), paths))
}
before <- manifest()
pkgload::load_all(root, quiet = TRUE, recompile = FALSE)
ref <- jsonlite::read_json(fixture, simplifyVector = TRUE)
out <- list(scope = "Two Gaussian-response joint public workflows; full programme gates remain open",
  fixture_sha256 = sha(fixture), runner_sha256 = sha("tools/run-julia-joint-public.R"),
  R_version = R.version.string, source_before = before, cases = list(),
  native_tolerance = 4e-6, adapter_tolerance = 1e-10,
  loaded_native_DLL_sha256 = sha(getLoadedDLLs()[["drmTMB"]][["path"]]))
save_receipt <- function() jsonlite::write_json(out, paste0(prefix, ".json"),
  pretty = TRUE, auto_unbox = TRUE, digits = 17, na = "string", null = "null")
fit_objects <- list()
start <- proc.time()[["elapsed"]]
drmTMB:::drm_julia_setup()
JuliaCall::julia_command("using LinearAlgebra; BLAS.set_num_threads(1)")
out$runtime <- JuliaCall::julia_eval('Dict("julia"=>string(VERSION),"threads"=>Threads.nthreads(),"blas"=>BLAS.get_num_threads(),"source"=>pathof(DRM))')
stopifnot(out$runtime$threads == 1L, out$runtime$blas == 1L)
for (kind in c("gaussian", "bernoulli")) {
  out$cases[[kind]] <- tryCatch({
    f <- ref$cases[[kind]]$fixture
    decode <- function(x) suppressWarnings(as.numeric(x))
    d <- data.frame(y = decode(f$y), x = decode(f$x), z = decode(f$z))
    stopifnot(nrow(d) == 160L, sum(is.na(d$y)) == 4L, sum(is.na(d$x)) == 10L)
    if (kind == "bernoulli") d$x <- factor(d$x, levels = c(0, 1))
    imp <- if (kind == "gaussian") list(x = x ~ z) else
      list(x = impute_model(x ~ z, family = binomial()))
    form <- bf(y ~ z + mi(x), sigma ~ 1)
    fit <- function(engine) drmTMB(form, family = gaussian(), data = d, impute = imp,
      missing = miss_control(response = "include", predictor = "model"), engine = engine)
    tick <- proc.time()[["elapsed"]]; native <- fit("tmb")
    native_seconds <- proc.time()[["elapsed"]] - tick
    tick <- proc.time()[["elapsed"]]; bridge <- fit("julia")
    bridge_seconds <- proc.time()[["elapsed"]] - tick
    # Keep completed fits even if a later public operation fails.
    fit_objects[[kind]] <- list(native = native, bridge = bridge)
    raw <- unname(bridge$joint$raw_theta)
    native_raw <- unname(c(coef(native, "mu"), coef(native, "sigma"), coef(native, "mi_x"),
                          if (kind == "gaussian") log(coef(native, "sigma_mi_x"))))
    native_labels <- paste(rep(names(coef(native)), lengths(coef(native))),
                           unlist(lapply(coef(native), names)), sep = ":")
    imp_all <- imputed(bridge, rows = "all")
    imp_missing <- imputed(bridge)
    fresh <- d[which(complete.cases(d))[1:6], , drop = FALSE]
    mu <- predict(bridge); sigma <- predict(bridge, dpar = "sigma")
    mu_expected <- raw[1L] + raw[2L] * d$z + raw[3L] * imp_all$estimate
    pub <- unname(unlist(coef(bridge)))
    J <- rep(1, length(raw))
    expected_pub <- raw
    if (kind == "gaussian") {
      expected_pub[length(raw)] <- exp(raw[length(raw)])
      J[length(raw)] <- exp(raw[length(raw)])
    }
    expected_V <- bridge$joint$raw_vcov * outer(J, J)
    summary_table <- summary(bridge)$coefficients
    wald <- confint(bridge)
    numeric_checks <- c(
      public_coefficient_scale = max(abs(pub - expected_pub)),
      public_covariance_scale = max(abs(vcov(bridge) - expected_V)),
      training_mean = max(abs(mu - mu_expected)),
      training_sigma = max(abs(sigma - exp(raw[4L]))),
      newdata_mean = max(abs(predict(bridge, newdata = fresh) -
        (raw[1L] + raw[2L] * fresh$z + raw[3L] * if (kind == "gaussian") fresh$x else as.numeric(as.character(fresh$x))))),
      newdata_sigma = max(abs(predict(bridge, newdata = fresh, dpar = "sigma") - exp(raw[4L]))))
    flags <- c(converged = is_converged(bridge), nobs = nobs(bridge) == 156L,
      coefficient_labels = identical(names(bridge$coef_vector), native_labels),
      rows = identical(imp_all$original_row, seq_len(160)),
      masks = identical(imp_all$observed, !is.na(d$x)),
      missing_rows = identical(imp_missing$model_row, which(is.na(d$x))),
      observed_se_unavailable = all(is.na(imp_all$std_error[!is.na(d$x)])),
      missing_se_available = all(is.finite(imp_missing$std_error)),
      no_se = all(is.na(imputed(bridge, se = FALSE)$std_error)),
      missing_response_residual = identical(is.na(residuals(bridge)), is.na(d$y)),
      summary_rows = nrow(summary_table) == length(raw),
      wald_rows = nrow(wald) == length(raw), wald_finite = all(is.finite(wald$lower) & is.finite(wald$upper)))
    native_predict <- function(newdata = NULL) tryCatch(
      list(status = "PASS", value = predict(native, newdata = newdata)),
      error = function(e) list(status = "ERROR", message = conditionMessage(e), value = NA_real_))
    native_training <- native_predict()
    native_newdata <- native_predict(fresh)
    native_errors <- c(theta = max(abs(raw - native_raw)),
      loglik = abs(as.numeric(logLik(bridge)) - as.numeric(logLik(native))),
      imputed_mean = max(abs(imp_all$estimate - imputed(native, rows = "all")$estimate)),
      imputed_se = max(abs(imp_missing$std_error - imputed(native)$std_error)),
      training_mean = max(abs(mu - native_training$value)),
      newdata_mean = max(abs(predict(bridge, newdata = fresh) - native_newdata$value)))
    adapter_pass <- all(flags) && all(is.finite(numeric_checks) & numeric_checks <= out$adapter_tolerance)
    native_pass <- all(is.finite(native_errors) & native_errors <= out$native_tolerance)
    list(status = if (adapter_pass) "PASS" else "FAIL", adapter_flags = as.list(flags),
      adapter_errors = as.list(numeric_checks), native_status = if (native_pass) "PASS" else "FAIL",
      native_errors = as.list(native_errors), raw_theta = raw, native_raw_theta = native_raw,
      raw_covariance = bridge$joint$raw_vcov, public_covariance = vcov(bridge),
      loglik = as.numeric(logLik(bridge)), native_loglik = as.numeric(logLik(native)), nobs = nobs(bridge),
      training_mu = mu, training_sigma = sigma,
      newdata_mu = predict(bridge, newdata = fresh),
      newdata_sigma = predict(bridge, newdata = fresh, dpar = "sigma"),
      coefficients = coef(bridge), summary = summary_table, wald = wald,
      native_training_prediction = native_training, native_newdata_prediction = native_newdata,
      imputed_all = imp_all, native_imputed_all = imputed(native, rows = "all"),
      seconds = list(native = native_seconds, bridge = bridge_seconds))
  }, error = function(e) list(status = "ERROR", message = conditionMessage(e)))
  save_receipt(); cat(kind, out$cases[[kind]]$status, "\n")
}
out$elapsed <- proc.time()[["elapsed"]] - start
out$source_after <- manifest()
out$source_unchanged <- identical(before, out$source_after)
out$status <- if (out$source_unchanged && all(vapply(out$cases, function(x) identical(x$status, "PASS"), TRUE))) "PASS" else "FAIL"
out$native_status <- if (all(vapply(out$cases, function(x) identical(x$native_status, "PASS"), TRUE))) "PASS" else "FAIL"
save_receipt(); saveRDS(fit_objects, paste0(prefix, ".rds"))
cat("JOINT_PUBLIC_ADAPTER_", out$status, "; NATIVE_PARITY_", out$native_status, "\n", sep = "")
if (out$status != "PASS") quit(status = 1L)
