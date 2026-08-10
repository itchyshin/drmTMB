#!/usr/bin/env Rscript
# Deterministic S0-B fixed-effect binomial separation spike.  This is a
# scratchpad harness, not package code and intentionally has no public API.

args <- commandArgs(trailingOnly = TRUE)
if (!identical(args, c("--stage", "binomial"))) {
  stop("Usage: separation-diagnostic-spike.R --stage binomial", call. = FALSE)
}

required_head <- "b441227fa0e11f9ab4347fc963266801cfb75a5f"
required_lib <- "/private/tmp/drmTMB-separation-s0-pkglib"
output <- "scratchpad/separation-diagnostic-results.tsv"

clean_text <- function(x) gsub("[\t\r\n]+", " ", paste(x, collapse = " | "))
num_text <- function(x) {
  if (length(x) == 0L || is.na(x[[1L]])) return(NA_character_)
  if (is.infinite(x[[1L]])) return(if (x[[1L]] > 0) "Inf" else "-Inf")
  formatC(x[[1L]], digits = 16L, format = "fg", flag = "#")
}
direction <- function(x) {
  if (length(x) == 0L || is.na(x[[1L]])) return("NA")
  if (is.infinite(x[[1L]])) return(if (x[[1L]] > 0) "+Inf" else "-Inf")
  "finite"
}
softplus <- function(x) pmax(x, 0) + log1p(exp(-abs(x)))

if (!identical(find.package("drmTMB"), file.path(required_lib, "drmTMB"))) {
  stop("drmTMB did not resolve to the exact-source temporary library", call. = FALSE)
}
if (!identical(as.character(utils::packageDescription("drmTMB")$Version), "0.6.0")) {
  stop("unexpected drmTMB version", call. = FALSE)
}
head <- system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE)
if (!identical(head, required_head)) stop("unexpected git HEAD", call. = FALSE)
if (!identical(as.character(utils::packageVersion("detectseparation")), "0.4.0")) {
  stop("detectseparation 0.4.0 is required", call. = FALSE)
}

library(drmTMB)
library(brglm2)
# `brglm2` retains a defunct compatibility binding named detect_separation;
# attach the maintained package last so glm(method = "detect_separation")
# resolves to detectseparation 0.4.0.
library(detectseparation)

rows <- list()
append_row <- function(...) rows[[length(rows) + 1L]] <<- data.frame(
  ..., stringsAsFactors = FALSE, check.names = FALSE
)
capture <- function(expr) {
  warnings <- character()
  error <- NA_character_
  value <- withCallingHandlers(
    tryCatch(expr, error = function(e) { error <<- conditionMessage(e); NULL }),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(value = value, warnings = clean_text(warnings), error = error)
}
fixture <- function(id, data, formula, expected_class, expected, weight = NULL,
                    missing_include = FALSE) {
  list(id = id, data = data, formula = formula, expected_class = expected_class,
       expected = expected, weight = weight, missing_include = missing_include)
}

core <- list(
  fixture("mu_overlap", data.frame(y01 = c(0L, 1L, 0L, 1L, 0L, 1L),
                                   x = c(-1, -1, 0, 0, 1, 1)),
          y01 ~ x, "none", c("(Intercept)" = "finite", x = "finite")),
  fixture("mu_complete", data.frame(y01 = c(0L, 0L, 1L, 1L),
                                    x = c(-2, -1, 1, 2)),
          y01 ~ x, "complete", c("(Intercept)" = "finite", x = "+Inf")),
  fixture("mu_mirrored", data.frame(y01 = c(1L, 1L, 0L, 0L),
                                    x = c(-2, -1, 1, 2)),
          y01 ~ x, "complete", c(x = "-Inf")),
  fixture("mu_quasi", data.frame(y01 = c(0L, 0L, 1L, 1L),
                                 x = c(-1, 0, 0, 1)),
          y01 ~ x, "quasi_complete", c("(Intercept)" = "finite", x = "+Inf")),
  fixture("mu_intercept_all_success", data.frame(y01 = rep(1L, 4L)),
          y01 ~ 1, "complete", c("(Intercept)" = "+Inf")),
  fixture("mu_intercept_all_failure", data.frame(y01 = rep(0L, 4L)),
          y01 ~ 1, "complete", c("(Intercept)" = "-Inf")),
  fixture("mu_quasi_expanded", data.frame(y01 = c(0L, 0L, 0L, 1L, 1L, 1L),
                                          x = c(-1, -1, 0, 0, 1, 1)),
          y01 ~ x, "quasi_complete", c("(Intercept)" = "finite", x = "+Inf")),
  fixture("mu_quasi_grouped", data.frame(success = c(0L, 1L, 2L),
                                         failure = c(2L, 1L, 0L), x = c(-1, 0, 1)),
          cbind(success, failure) ~ x, "quasi_complete",
          c("(Intercept)" = "finite", x = "+Inf")),
  fixture("rank_deficient_control", data.frame(y01 = c(0L, 1L, 0L, 1L, 0L, 1L),
                                               x = c(-1, -1, 0, 0, 1, 1),
                                               twox = c(-2, -2, 0, 0, 2, 2)),
          y01 ~ x + twox, "rank_deficient", c())
)
controls <- list(
  fixture("mu_zero_weight", data.frame(y01 = c(0L, 0L, 1L, 1L, 0L),
                                      x = c(-2, -1, 1, 2, 2), w = c(1, 1, 1, 1, 0)),
          y01 ~ x, "complete", c("(Intercept)" = "finite", x = "+Inf"), "w"),
  fixture("mu_finite_offset", data.frame(y01 = c(0L, 0L, 1L, 1L),
                                         x = c(-2, -1, 1, 2), off = c(-.7, .2, .4, -.3)),
          y01 ~ x + offset(off), "complete", c("(Intercept)" = "finite", x = "+Inf")),
  fixture("mu_response_mask", data.frame(y01 = c(0L, 0L, 1L, 1L, NA_integer_),
                                         x = c(-2, -1, 1, 2, 2)),
          y01 ~ x, "complete", c("(Intercept)" = "finite", x = "+Inf"),
          missing_include = TRUE)
)

ray_gate_rows <- function() {
  t <- c(0, 2, 4, 8, 16)
  displayed_c <- c(2.772588722240, .290155877922, .036970668581, .000671037816, .000000225070)
  displayed_q <- c(2.772588722240, 1.640150383206, 1.422594216956, 1.386965173866, 1.386294586190)
  displayed_f <- c(4.158883083360, 5.894006405292, 9.458894072791, 17.387635986611, 33.386294811261)
  lc <- 2 * softplus(-2 * t) + 2 * softplus(-t)
  lq <- 2 * log(2) + 2 * softplus(-t)
  lf <- 2 * (softplus(t) + softplus(-t)) + 2 * log(2)
  expanded <- vapply(t, function(tt) {
    p <- stats::plogis(tt * c(-1, -1, 0, 0, 1, 1))
    -sum(stats::dbinom(c(0, 0, 0, 1, 1, 1), 1, p, log = TRUE))
  }, numeric(1))
  grouped <- vapply(t, function(tt) {
    p <- stats::plogis(tt * c(-1, 0, 1))
    -sum(stats::dbinom(c(0, 1, 2), c(2, 2, 2), p, log = TRUE))
  }, numeric(1))
  # The raw grouped curve includes its binomial constants; compare only the
  # normalized curves required by the symbolic contract.
  grouped_expanded_equal <- max(abs((expanded - expanded[[1L]]) -
                                     (grouped - grouped[[1L]]))) < 1e-8
  checks <- c(max(abs(lc - displayed_c)) < 1e-8,
              max(abs(lq - displayed_q)) < 1e-8,
              max(abs(lf - displayed_f)) < 1e-8,
              all(diff(lc) < 0) && lc[5] < 2.3e-7 && lc[1] - lc[5] > 2.7725884,
              all(diff(lq) < 0) && abs(lq[5] - log(4)) < 1e-6 && lq[1] - lq[5] > 1.3862940,
              lf[2] - lf[1] > 1.7, grouped_expanded_equal)
  names(checks) <- c("displayed_complete", "displayed_quasi", "displayed_finite",
                     "complete_ray", "quasi_ray", "finite_no_ray", "grouped_expanded_ray")
  for (nm in names(checks)) append_row(
    record_type = "gate", stage = "binomial", fixture = "symbolic_ray",
    engine = "symbolic", coefficient = nm, coefficient_value = NA_character_,
    oracle_direction = NA_character_, expected_direction = NA_character_,
    rank_status = "full_rank", detector_class = NA_character_, expected_class = NA_character_,
    status = if (checks[[nm]]) "PASS" else "FAIL", detail = NA_character_,
    retained_rows = NA_integer_, design_columns = NA_integer_, trials_sum = NA_real_,
    positive_weight_sum = NA_real_, offset_summary = NA_character_, logLik = NA_character_,
    objective = NA_character_, convergence = NA_character_, optimizer_message = NA_character_,
    max_abs_gradient = NA_character_, pdHess = NA_character_, warnings = NA_character_, error = NA_character_
  )
  all(checks)
}

detector_class <- function(fit) {
  if (!isTRUE(fit$outcome)) return("none")
  if (isTRUE(fit$complete)) "complete" else "quasi_complete"
}
run_fixture <- function(fx, phase) {
  dat <- fx$data
  glm_args <- list(formula = fx$formula, data = dat, family = stats::binomial())
  if (!is.null(fx$weight)) glm_args$weights <- dat[[fx$weight]]
  mf <- do.call(stats::model.frame, c(list(formula = fx$formula, data = dat,
                                             na.action = stats::na.omit),
                                        if (is.null(fx$weight)) list() else list(weights = dat[[fx$weight]])))
  x <- stats::model.matrix(attr(mf, "terms"), mf)
  rank <- qr(x)$rank
  rank_status <- if (rank == ncol(x)) "full_rank" else "rank_deficient"
  response <- stats::model.response(mf)
  trials <- if (is.matrix(response)) sum(rowSums(response)) else length(response)
  weight_sum <- if (is.null(fx$weight)) nrow(mf) else sum(model.weights(mf))
  offset <- model.offset(mf)
  offset_summary <- if (is.null(offset)) "none" else paste(range(offset), collapse = ":")

  if (rank_status == "rank_deficient") {
    append_row(record_type = "gate", stage = phase, fixture = fx$id, engine = "detectseparation",
      coefficient = "design_rank", coefficient_value = as.character(rank), oracle_direction = NA_character_,
      expected_direction = NA_character_, rank_status = rank_status, detector_class = "not_run",
      expected_class = fx$expected_class, status = "PASS", detail = "rank checked before LP; detector not run",
      retained_rows = nrow(mf), design_columns = ncol(x), trials_sum = trials, positive_weight_sum = weight_sum,
      offset_summary = offset_summary, logLik = NA_character_, objective = NA_character_,
      convergence = NA_character_, optimizer_message = NA_character_, max_abs_gradient = NA_character_,
      pdHess = NA_character_, warnings = NA_character_, error = NA_character_)
  } else {
    det <- capture(do.call(stats::glm, c(glm_args, list(method = "detect_separation", separation_type = TRUE))))
    if (is.null(det$value)) {
      append_row(record_type = "gate", stage = phase, fixture = fx$id, engine = "detectseparation",
        coefficient = "detector", coefficient_value = NA_character_, oracle_direction = "NA",
        expected_direction = NA_character_, rank_status = rank_status, detector_class = "error",
        expected_class = fx$expected_class, status = "FAIL", detail = "detector error",
        retained_rows = nrow(mf), design_columns = ncol(x), trials_sum = trials, positive_weight_sum = weight_sum,
        offset_summary = offset_summary, logLik = NA_character_, objective = NA_character_,
        convergence = NA_character_, optimizer_message = NA_character_, max_abs_gradient = NA_character_,
        pdHess = NA_character_, warnings = det$warnings, error = det$error)
    } else {
      observed_class <- detector_class(det$value)
      class_ok <- identical(observed_class, fx$expected_class)
      append_row(record_type = "gate", stage = phase, fixture = fx$id, engine = "detectseparation",
        coefficient = "classification", coefficient_value = observed_class, oracle_direction = NA_character_,
        expected_direction = fx$expected_class, rank_status = rank_status, detector_class = observed_class,
        expected_class = fx$expected_class, status = if (class_ok) "PASS" else "FAIL",
        detail = NA_character_, retained_rows = nrow(mf), design_columns = ncol(x), trials_sum = trials,
        positive_weight_sum = weight_sum, offset_summary = offset_summary, logLik = NA_character_,
        objective = NA_character_, convergence = NA_character_, optimizer_message = NA_character_,
        max_abs_gradient = NA_character_, pdHess = NA_character_, warnings = det$warnings, error = det$error)
      for (nm in names(det$value$coefficients)) {
        expected <- if (nm %in% names(fx$expected)) unname(fx$expected[[nm]]) else character()
        observed <- direction(det$value$coefficients[[nm]])
        append_row(record_type = "gate", stage = phase, fixture = fx$id, engine = "detectseparation",
          coefficient = nm, coefficient_value = num_text(det$value$coefficients[[nm]]), oracle_direction = observed,
          expected_direction = if (length(expected)) expected else NA_character_, rank_status = rank_status,
          detector_class = observed_class, expected_class = fx$expected_class,
          status = if (!length(expected) || identical(observed, expected)) "PASS" else "FAIL",
          detail = NA_character_, retained_rows = nrow(mf), design_columns = ncol(x), trials_sum = trials,
          positive_weight_sum = weight_sum, offset_summary = offset_summary, logLik = NA_character_,
          objective = NA_character_, convergence = NA_character_, optimizer_message = NA_character_,
          max_abs_gradient = NA_character_, pdHess = NA_character_, warnings = det$warnings, error = det$error)
      }
    }
  }

  fitters <- list(
    glm = function() do.call(stats::glm, glm_args),
    brglm2_mean_bias_reduction = function() do.call(stats::glm, c(glm_args, list(method = "brglmFit", type = "AS_mean"))),
    drmTMB_ML = function() {
      a <- list(formula = do.call(drmTMB::bf, list(fx$formula)), family = stats::binomial(), data = dat)
      if (!is.null(fx$weight)) a$weights <- dat[[fx$weight]]
      if (fx$missing_include) a$missing <- drmTMB::miss_control(response = "include")
      do.call(drmTMB::drmTMB, a)
    }
  )
  for (engine in names(fitters)) {
    out <- capture(fitters[[engine]]())
    fit <- out$value
    if (is.null(fit)) {
      append_row(record_type = "fit", stage = phase, fixture = fx$id, engine = engine,
        coefficient = NA_character_, coefficient_value = NA_character_, oracle_direction = NA_character_,
        expected_direction = NA_character_, rank_status = rank_status, detector_class = NA_character_,
        expected_class = fx$expected_class, status = "RETAINED_FAILURE", detail = "fit error",
        retained_rows = nrow(mf), design_columns = ncol(x), trials_sum = trials, positive_weight_sum = weight_sum,
        offset_summary = offset_summary, logLik = NA_character_, objective = NA_character_,
        convergence = NA_character_, optimizer_message = NA_character_, max_abs_gradient = NA_character_,
        pdHess = NA_character_, warnings = out$warnings, error = out$error)
      next
    }
    co <- if (identical(engine, "drmTMB_ML")) stats::coef(fit, dpar = "mu") else stats::coef(fit)
    ll <- if (identical(engine, "drmTMB_ML")) fit$logLik else as.numeric(stats::logLik(fit))
    objective <- if (identical(engine, "drmTMB_ML")) fit$opt$objective else -ll
    convergence <- if (identical(engine, "drmTMB_ML")) fit$opt$convergence else fit$converged
    message <- if (identical(engine, "drmTMB_ML")) fit$opt$message else NA_character_
    grad <- if (identical(engine, "drmTMB_ML")) max(abs(fit$obj$gr(fit$opt$par))) else NA_real_
    hess <- if (identical(engine, "drmTMB_ML")) fit$sdr$pdHess else NA
    for (nm in names(co)) append_row(record_type = "fit", stage = phase, fixture = fx$id, engine = engine,
      coefficient = nm, coefficient_value = num_text(co[[nm]]), oracle_direction = NA_character_,
      expected_direction = NA_character_, rank_status = rank_status, detector_class = NA_character_,
      expected_class = fx$expected_class, status = "RECORDED", detail = "objective values include their native binomial constants",
      retained_rows = nrow(mf), design_columns = ncol(x), trials_sum = trials, positive_weight_sum = weight_sum,
      offset_summary = offset_summary, logLik = num_text(ll), objective = num_text(objective),
      convergence = clean_text(convergence), optimizer_message = clean_text(message), max_abs_gradient = num_text(grad),
      pdHess = clean_text(hess), warnings = out$warnings, error = out$error)
  }
}

write_results <- function() {
  result <- do.call(rbind, rows)
  utils::write.table(result, output, sep = "\t", row.names = FALSE, quote = TRUE, na = "")
}

# A finite, non-empty detector result is required before the frozen core begins.
smoke <- core[[1L]]
smoke_fit <- capture(stats::glm(smoke$formula, data = smoke$data, family = stats::binomial(),
                                method = "detect_separation", separation_type = TRUE))
if (is.null(smoke_fit$value) || length(smoke_fit$value$coefficients) == 0L ||
    any(!is.finite(smoke_fit$value$coefficients))) {
  append_row(record_type = "gate", stage = "binomial", fixture = "smoke_overlap", engine = "detectseparation",
    coefficient = "smoke", coefficient_value = NA_character_, oracle_direction = NA_character_,
    expected_direction = "finite", rank_status = NA_character_, detector_class = NA_character_,
    expected_class = "none", status = "FAIL", detail = "overlap smoke did not return finite, non-empty output",
    retained_rows = NA_integer_, design_columns = NA_integer_, trials_sum = NA_real_, positive_weight_sum = NA_real_,
    offset_summary = NA_character_, logLik = NA_character_, objective = NA_character_, convergence = NA_character_,
    optimizer_message = NA_character_, max_abs_gradient = NA_character_, pdHess = NA_character_,
    warnings = smoke_fit$warnings, error = smoke_fit$error)
  write_results(); stop("overlap smoke failed; results retained", call. = FALSE)
}
append_row(record_type = "gate", stage = "binomial", fixture = "smoke_overlap", engine = "detectseparation",
  coefficient = "smoke", coefficient_value = "finite_nonempty", oracle_direction = "finite",
  expected_direction = "finite", rank_status = "full_rank", detector_class = "none", expected_class = "none",
  status = "PASS", detail = "finite, non-empty maintained-detector output", retained_rows = nrow(smoke$data),
  design_columns = 2L, trials_sum = nrow(smoke$data), positive_weight_sum = nrow(smoke$data),
  offset_summary = "none", logLik = NA_character_, objective = NA_character_, convergence = NA_character_,
  optimizer_message = NA_character_, max_abs_gradient = NA_character_, pdHess = NA_character_,
  warnings = smoke_fit$warnings, error = smoke_fit$error)

rays_ok <- ray_gate_rows()
for (fx in core) run_fixture(fx, "binomial_core")
write_results()
result <- do.call(rbind, rows)
core_ok <- rays_ok && !any(result$record_type == "gate" & result$stage %in% c("binomial", "binomial_core") & result$status == "FAIL")
if (!core_ok) stop("core gate failed; controls intentionally not run; results retained", call. = FALSE)
for (fx in controls) run_fixture(fx, "binomial_controls")
write_results()
