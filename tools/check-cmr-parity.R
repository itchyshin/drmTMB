#!/usr/bin/env Rscript

# Fixed-parameter parity harness. It evaluates the production drmTMB TMB CJS
# objective and independently enumerates all finite alive/dead paths from the
# literal design fixtures. The Julia adapter calls DRModels._cjs_objective.

args <- commandArgs(trailingOnly = TRUE)
fixture_root <- if (length(args) && !startsWith(args[[1L]], "--")) args[[1L]] else
  Sys.getenv("CMR_PARITY_FIXTURES", unset = file.path(getwd(), "docs/dev-log/cmr/fixtures"))
fixture_root <- normalizePath(fixture_root, mustWork = TRUE)
read_fixture <- function(name, types = NA) {
  path <- file.path(fixture_root, name)
  if (!file.exists(path)) stop("missing parity fixture: ", path, call. = FALSE)
  read.csv(path, stringsAsFactors = FALSE, colClasses = types, check.names = FALSE)
}
assert_close <- function(x, y, tol, what) {
  if (!is.finite(x) || abs(x - y) > tol)
    stop(sprintf("%s differs: %.17g vs %.17g (tol %.1g)", what, x, y, tol), call. = FALSE)
}

if (!requireNamespace("drmTMB", quietly = TRUE))
  stop("drmTMB must be loaded from the M1 source build before running this adapter; it never calls load_all() or compiles the package.", call. = FALSE)
ns <- asNamespace("drmTMB")
need <- c("cmr_data", ".cmr_join_predictors", ".cmr_design")
missing <- need[!vapply(need, exists, logical(1), envir = ns, inherits = FALSE)]
if (length(missing)) stop("loaded drmTMB namespace lacks M1 CMR functions: ", paste(missing, collapse = ", "), call. = FALSE)
if (!("drmTMB" %in% names(getLoadedDLLs())))
  stop("the drmTMB DLL is not loaded; run this adapter after the parent-owned R DLL build.", call. = FALSE)

histories <- read_fixture("parity-histories.csv", c("character", "character", "integer", "integer"))
orders <- read_fixture("parity-orders.csv", c("character", "integer", "character"))
phi_raw <- read_fixture("parity-phi.csv", c("character", "numeric", "numeric", "numeric", "character", "numeric"))
p_raw <- read_fixture("parity-p.csv", c("character", "numeric", "numeric", "character", "numeric"))
phi_literal <- read_fixture("parity-phi-design.csv", c("character", "integer", "integer", "numeric", "numeric", "numeric", "numeric"))
p_literal <- read_fixture("parity-p-design.csv", c("character", "integer", "integer", "integer", "numeric", "numeric", "numeric", "numeric"))
coefficients <- read_fixture("parity-coefficients.csv")
frozen_truth <- read_fixture("parity-truth.csv")
occasions <- c(0, 1, 2.5, 4.5, 5.5)
intervals <- c(1, 1.5, 2, 1)
cmr_data <- get("cmr_data", envir = ns)
join_predictors <- get(".cmr_join_predictors", envir = ns)
cmr_design <- get(".cmr_design", envir = ns)

# Brute-force state-path oracle. Each bit selects alive (1) or dead (0) at a
# post-capture occasion. Paths that resurrect after death or capture while dead
# have zero probability. This is independent of the native forward recursion.
enumerate_history <- function(history, end, first, freq, id, phi_eta, p_eta) {
  chars <- strsplit(history, "", fixed = TRUE)[[1L]]
  observed <- chars != "?"
  y <- rep.int(0L, length(chars))
  y[observed] <- as.integer(chars[observed])
  steps <- end - first
  total <- 0
  if (steps == 0L) return(0)
  for (mask in 0:(2^steps - 1L)) {
    path <- as.integer(intToBits(mask)[seq_len(steps)])
    q <- 1
    previous <- 1L
    for (j in seq_len(steps)) {
      t <- first + j - 1L
      s <- plogis(phi_eta[[t]])^intervals[[t]]
      state <- path[[j]]
      if (previous == 1L) q <- q * if (state == 1L) s else (1 - s)
      else if (state == 1L) { q <- 0; break }
      occasion <- t + 1L
      if (observed[[occasion]]) {
        if (y[[occasion]] == 1L) q <- q * if (state == 1L) plogis(p_eta[[occasion]]) else 0
        else if (state == 1L) q <- q * (1 - plogis(p_eta[[occasion]]))
      }
      previous <- state
    }
    total <- total + q
  }
  if (!is.finite(total) || total <= 0) stop("enumerated history probability is not positive for id ", id)
  freq * log(total)
}

design_check <- function(actual, offset, literal, key_name, key_rows, factor_name) {
  literal$key <- paste(literal$id, literal[[key_name]], sep = "\r")
  literal <- literal[match(key_rows, literal$key), , drop = FALSE]
  if (anyNA(literal$key)) stop("literal design fixture is missing active keys", call. = FALSE)
  expected <- cbind(literal$intercept, literal$x, literal[[factor_name]])
  if (!isTRUE(all.equal(unname(actual), unname(expected), tolerance = 1e-13)))
    stop("native model-matrix columns differ from the literal design fixture", call. = FALSE)
  if (!isTRUE(all.equal(as.numeric(offset), literal$offset, tolerance = 1e-13)))
    stop("native offsets differ from the literal design fixture", call. = FALSE)
}

results <- list()
for (case in unique(orders$case)) {
  o <- orders[orders$case == case, , drop = FALSE]
  o <- o[order(o$rank), , drop = FALSE]
  h <- histories[match(o$id, histories$id), , drop = FALSE]
  n <- nrow(h); nt <- length(occasions)
  chars <- lapply(h$history, function(z) strsplit(z, "", fixed = TRUE)[[1L]])
  y <- matrix(0L, n, nt); observed <- matrix(TRUE, n, nt)
  for (i in seq_len(n)) for (t in seq_len(nt)) {
    c <- chars[[i]][[t]]
    if (c == "?") observed[i, t] <- FALSE else y[i, t] <- as.integer(c)
  }
  ends <- h$end
  data <- cmr_data(y, id = h$id, observed = observed, occasions = occasions,
                   intervals = intervals, units = "years", end = ends,
                   frequency = h$frequency)
  phi_data <- phi_raw[phi_raw$id %in% h$id, , drop = FALSE]
  p_data <- p_raw[p_raw$id %in% h$id, , drop = FALSE]
  if (case == "permuted") {
    phi_data <- phi_data[nrow(phi_data):1L, , drop = FALSE]
    p_data <- p_data[nrow(p_data):1L, , drop = FALSE]
  }
  phi_data$habitat <- factor(phi_data$habitat, levels = c("A", "B"))
  p_data$method <- factor(p_data$method, levels = c("A", "B"))
  p_rows <- data.frame(i = rep(seq_len(n), each = nt), t = rep(seq_len(nt), n))
  phi_rows <- data.frame(i = rep(seq_len(n), each = nt - 1L), t = rep(seq_len(nt - 1L), n))
  p_post <- p_rows$t > data$first[p_rows$i] & p_rows$t <= data$end[p_rows$i]
  p_active <- p_post & data$observed[cbind(p_rows$i, p_rows$t)]
  phi_active <- phi_rows$t >= data$first[phi_rows$i] & phi_rows$t < data$end[phi_rows$i]
  p_frame <- join_predictors(data, p_data, p_rows, "p")
  phi_frame <- join_predictors(data, phi_data, phi_rows, "phi")
  p_design <- cmr_design(~ x + method + offset(off), p_frame, "p", p_active)
  phi_design <- cmr_design(~ x + habitat + offset(off), phi_frame, "phi", phi_active)

  phi_key_rows <- unlist(lapply(seq_len(n), function(i) {
    f <- data$first[[i]]; if (f >= ends[[i]]) integer() else seq.int(f, ends[[i]] - 1L)
  }), use.names = FALSE)
  phi_key <- paste(rep(h$id, times = pmax(0L, ends - data$first)), phi_key_rows, sep = "\r")
  p_key <- paste(h$id[p_rows$i[p_active]], p_rows$t[p_active], sep = "\r")
  design_check(phi_design$X[phi_active, , drop = FALSE], phi_design$offset[phi_active],
               phi_literal, "interval_index", phi_key, "habitat_B")
  design_check(p_design$X[p_active, , drop = FALSE], p_design$offset[p_active],
               p_literal, "occasion_index", p_key, "method_B")
  neutral_p_rows <- !p_active
  if (any(p_design$X[neutral_p_rows, , drop = FALSE] != 0) || any(p_design$offset[neutral_p_rows] != 0))
    stop("unobserved or noncontributing detection rows must be neutral in native expanded design arrays", call. = FALSE)
  if (!any(p_post & !data$observed[cbind(p_rows$i, p_rows$t)]))
    stop("fixture must exercise a masked post-capture occasion", call. = FALSE)

  coef_row <- coefficients[coefficients$case == case, , drop = FALSE]
  beta_phi <- c(coef_row$phi_intercept[[1L]], coef_row$phi_x[[1L]], coef_row$phi_habitat_B[[1L]])
  beta_p <- c(coef_row$p_intercept[[1L]], coef_row$p_x[[1L]], coef_row$p_method_B[[1L]])
  par <- c(beta_phi, beta_p)
  objective_data <- list(
    model_type = 1000L, cmr_N = n, cmr_T = nt,
    cmr_y = as.integer(t(data$y)), cmr_observed = as.integer(t(data$observed)),
    cmr_first = data$first - 1L, cmr_end = data$end - 1L,
    cmr_delta = as.numeric(t(data$delta)), cmr_frequency = data$frequency,
    cmr_X_phi = phi_design$X, cmr_X_p = p_design$X,
    cmr_offset_phi = phi_design$offset, cmr_offset_p = p_design$offset)
  objective <- TMB::MakeADFun(data = objective_data,
    parameters = list(beta_phi = numeric(ncol(phi_design$X)), beta_p = numeric(ncol(p_design$X))),
    DLL = "drmTMB", silent = TRUE)
  ll <- -objective$fn(par)

  # The independent oracle uses the stored literal design, not the native
  # objective or its forward recursion.
  pd_lookup <- split(p_literal, p_literal$id)
  sd_lookup <- split(phi_literal, phi_literal$id)
  oracle <- sum(vapply(seq_len(n), function(i) {
    row_s <- sd_lookup[[h$id[[i]]]]
    row_s <- row_s[order(row_s$interval_index), , drop = FALSE]
    row_p <- pd_lookup[[h$id[[i]]]]
    row_p <- row_p[order(row_p$occasion_index), , drop = FALSE]
    eta_s <- row_s$intercept * beta_phi[[1L]] + row_s$x * beta_phi[[2L]] +
      row_s$habitat_B * beta_phi[[3L]] + row_s$offset
    eta_p <- row_p$intercept * beta_p[[1L]] + row_p$x * beta_p[[2L]] +
      row_p$method_B * beta_p[[3L]] + row_p$offset
    enumerate_history(h$history[[i]], ends[[i]], data$first[[i]],
                      h$frequency[[i]], h$id[[i]], eta_s, eta_p)
  }, numeric(1)))
  frozen <- frozen_truth$loglik[match(case, frozen_truth$case)]
  assert_close(oracle, frozen, 1e-10, paste("R enumeration vs frozen truth", case))
  assert_close(ll, oracle, 1e-10, paste("R native vs independent truth", case))
  results[[case]] <- ll
  cat(sprintf("CMR_PARITY_ROW,language=R,case=%s,loglik=%.17g,oracle=%.17g\n", case, ll, oracle))
}
assert_close(results[["base"]], results[["permuted"]], 1e-8, "R keyed row permutation")

# Matched external comparator on a separate, fully observed constant-parameter
# fixture. marked is loaded from the isolated library; any TMB build artifacts
# are confined to the owned temporary directory and the working directory is
# restored on exit. Do not adjust constants to manufacture agreement.
run_marked_comparator <- function() {
marked_library <- Sys.getenv("CMR_MARKED_LIBRARY", "/private/tmp/cmr-marked-library")
if (dir.exists(marked_library)) .libPaths(c(marked_library, .libPaths()))
if (!requireNamespace("marked", quietly = TRUE))
  stop("marked 1.2.8 comparator is unavailable from CMR_MARKED_LIBRARY", call. = FALSE)
marked_rows <- read_fixture("parity-marked.csv", c("character", "character", "integer"))
marked_reference <- read_fixture("parity-marked-reference.csv")
marked_build_dir <- Sys.getenv("CMR_MARKED_BUILD_DIR", "/private/tmp/cmr-programme/marked-backend")
if (!dir.exists(marked_build_dir)) stop("owned marked backend directory is missing: ", marked_build_dir, call. = FALSE)
old_wd <- getwd()
on.exit(setwd(old_wd), add = TRUE)
setwd(marked_build_dir)
expanded <- rep(seq_len(nrow(marked_rows)), marked_rows$frequency)
marked_raw <- data.frame(ch = marked_rows$history[expanded], stringsAsFactors = FALSE)
marked_proc <- marked::process.data(marked_raw, model = "CJS", begin.time = 1,
                                    time.intervals = rep(1, 3), accumulate = FALSE)
marked_ddl <- marked::make.design.data(marked_proc)
marked_fit <- marked::crm(marked_proc, marked_ddl, model = "CJS",
  model.parameters = list(Phi = list(formula = ~1), p = list(formula = ~1)),
  use.tmb = TRUE, compile = FALSE, hessian = FALSE,
  initial = list(Phi = 0, p = 0), accumulate = FALSE, itnmax = 50)
marked_beta_phi <- unname(marked_fit$results$beta$Phi[[1L]])
marked_beta_p <- unname(marked_fit$results$beta$p[[1L]])
marked_ll <- -marked_fit$results$neg2lnl / 2
if (as.character(utils::packageVersion("marked")) != marked_reference$marked_version[[1L]])
  stop("marked version differs from the retained comparator receipt", call. = FALSE)
assert_close(marked_beta_phi, as.numeric(marked_reference$beta_phi[[1L]]), 1e-6, "marked Phi MLE")
assert_close(marked_beta_p, as.numeric(marked_reference$beta_p[[1L]]), 1e-6, "marked p MLE")
assert_close(marked_ll, as.numeric(marked_reference$loglik[[1L]]), 1e-8, "marked conditional log likelihood")

marked_y <- do.call(rbind, lapply(marked_rows$history, function(z) as.integer(strsplit(z, "", fixed = TRUE)[[1L]])))
marked_data <- cmr_data(marked_y, id = marked_rows$id, observed = matrix(TRUE, nrow(marked_y), ncol(marked_y)),
                        occasions = 1:4, intervals = rep(1, 3), units = "years",
                        frequency = marked_rows$frequency)
marked_p_rows <- data.frame(i = rep(seq_len(nrow(marked_y)), each = 4L), t = rep(seq_len(4L), nrow(marked_y)))
marked_s_rows <- data.frame(i = rep(seq_len(nrow(marked_y)), each = 3L), t = rep(seq_len(3L), nrow(marked_y)))
marked_p_active <- marked_p_rows$t > marked_data$first[marked_p_rows$i]
marked_s_active <- marked_s_rows$t >= marked_data$first[marked_s_rows$i]
marked_p_frame <- join_predictors(marked_data, NULL, marked_p_rows, "p")
marked_s_frame <- join_predictors(marked_data, NULL, marked_s_rows, "phi")
marked_p_design <- cmr_design(~1, marked_p_frame, "p", marked_p_active)
marked_s_design <- cmr_design(~1, marked_s_frame, "phi", marked_s_active)
marked_obj <- TMB::MakeADFun(data = list(
  model_type = 1000L, cmr_N = nrow(marked_y), cmr_T = ncol(marked_y),
  cmr_y = as.integer(t(marked_data$y)), cmr_observed = as.integer(t(marked_data$observed)),
  cmr_first = marked_data$first - 1L, cmr_end = marked_data$end - 1L,
  cmr_delta = as.numeric(t(marked_data$delta)), cmr_frequency = marked_data$frequency,
  cmr_X_phi = marked_s_design$X, cmr_X_p = marked_p_design$X,
  cmr_offset_phi = marked_s_design$offset, cmr_offset_p = marked_p_design$offset),
  parameters = list(beta_phi = numeric(1), beta_p = numeric(1)), DLL = "drmTMB", silent = TRUE)
native_marked_ll <- -marked_obj$fn(c(marked_beta_phi, marked_beta_p))
assert_close(native_marked_ll, marked_ll, 1e-8, "drmTMB native vs marked full conditional log likelihood at marked MLE")
cat(sprintf("CMR_MARKED_ROW,language=marked,version=%s,loglik=%.17g,beta_phi=%.17g,beta_p=%.17g\n",
            as.character(utils::packageVersion("marked")), marked_ll, marked_beta_phi, marked_beta_p))
cat(sprintf("CMR_MARKED_NATIVE_ROW,language=R,loglik=%.17g,marked_loglik=%.17g,difference=%.17g\n",
            native_marked_ll, marked_ll, native_marked_ll - marked_ll))
}
run_marked_comparator()

cat("CMR_PARITY_OK\n")
