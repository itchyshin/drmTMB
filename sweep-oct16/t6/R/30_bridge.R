# t6 (sweep-oct16): SPEC test P11 -- the drmTMB engine = "julia" bridge.
#
# One R session, all 28 cells (Julia boots once). For each cell:
#   * admission: does drmTMB(..., engine = "julia") admit the cell? Refusal
#     message verbatim; compared with the julia-engine vignette family table,
#     the drmTMB() @param engine roxygen, and R/julia-family-registry.R.
#     A refused cell is retried once with sigma ~ 1 (SPEC fallback).
#   * (a) P11 same-fit parity: bridge predict() (nd_main and in-sample, every
#     dpar, link + response) versus DRModels.jl predict_parameters()/predict()
#     on the SAME data and formula fitted natively in Julia, inside this R
#     session through JuliaCall on the SAME DRModels module the bridge loaded
#     (so the optimizer path is identical). Coefficients and logLik compared
#     too. Pass: 1e-8 (link scale; response scale where both engines define the
#     same quantity -- semantic differences are reported separately).
#   * (b) bridge predict() vs native drmTMB engine = "tmb" predict() on
#     nd_main (fit-vs-fit, informative) + coefficient / logLik differences.
#   * (c) P2-P5 on the drmTMB_julia class.
#   * (d) simulate() on bridge fits.
#   * (e) fitted() on bridge fits vs native drmTMB fitted() semantics.
#
# Run:
#   Rscript /home/user/drmTMB/sweep-oct16/t6/R/30_bridge.R \
#     > /home/user/drmTMB/sweep-oct16/t6/logs/bridge.log 2>&1
# Optional args: cell keys (e.g. gaussian_fixed gaussian_ri) to restrict.
#
# Outputs: results/bridge_<family>_<re>.json, results/bridge_<family>_<re>_pred.csv,
#          results/bridge_summary.csv.

Sys.setenv(
  JULIA_DEPOT_PATH = "/opt/julia-depot",
  DRMODELS_JL_PATH = "/home/user/DRModels.jl",
  NOT_CRAN = "true",
  JULIA_HOME = "/opt/julia-env/bin",
  JULIA_NUM_THREADS = "1",
  OPENBLAS_NUM_THREADS = "1",
  OMP_NUM_THREADS = "1"
)
options(warn = 1, width = 200)
suppressPackageStartupMessages({
  library(drmTMB)
  library(jsonlite)
})
# drmTMB #1550 (known): R 4.3.3 has no base %||%; the bridge needs it.
SHIM_1550 <- FALSE
if (!exists("%||%", baseenv())) {
  assign("%||%", function(x, y) if (is.null(x)) y else x, envir = globalenv())
  SHIM_1550 <- TRUE
}
source("/home/user/drmTMB/sweep-oct16/t6/R/lib_t6.R")

TOL1 <- 1e-10   # P2-P5 exact-algebra tolerance (mixed abs/rel)
TOL11 <- 1e-8   # P11 bridge-vs-native-Julia tolerance
TOLREL <- 1e-6  # P5 releveled-fit tolerance
NSIM <- 1000L

logf <- function(fmt, ...) {
  cat(format(Sys.time(), "%H:%M:%S"), sprintf(fmt, ...), "\n")
  flush(stdout())
}
safe <- function(expr) tryCatch(expr, error = function(e) e)
# capture warnings as well as the value / error
safe_w <- function(expr) {
  ws <- character()
  val <- withCallingHandlers(
    tryCatch(expr, error = function(e) e),
    warning = function(w) {
      ws <<- c(ws, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(value = val, warnings = ws)
}
errtxt <- function(e) if (inherits(e, "error")) t6_err(e) else NA_character_

cells <- utils::read.csv(file.path(T6_DATA, "cells.csv"), stringsAsFactors = FALSE,
  colClasses = c(seed = "character", seed_r = "character"))
args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0L) cells <- cells[paste(cells$family, cells$re, sep = "_") %in% args, ]

nd_main <- utils::read.csv(file.path(T6_DATA, "nd_main.csv"), stringsAsFactors = FALSE)
nd_subset <- utils::read.csv(file.path(T6_DATA, "nd_subset.csv"), stringsAsFactors = FALSE)
nd_unseen <- utils::read.csv(file.path(T6_DATA, "nd_unseen_f.csv"), stringsAsFactors = FALSE)
idx_b <- which(nd_main$f == "b")

logf("drmTMB %s; R %s; drmTMB pin %s; DRModels.jl pin %s; %%||%% shim applied: %s",
  as.character(utils::packageVersion("drmTMB")), R.version.string,
  "ca3ddefa5ea11bbfd3b765615dfbb89305d2485a", "f71b2923360e9e5d4591e0d6e15a9ef9db0356d7",
  SHIM_1550)
logf("cells: %d", nrow(cells))

# ---- documentation expectations ------------------------------------------------
# vig: vignettes/julia-engine.Rmd "Family and route reference" table.
# rox: drmTMB() @param engine (R/drmTMB.R:144-157 at the pin).
# reg: R/julia-family-registry.R fe column + the fe-only RE fence
#      (drm_julia_fe_only_fence_families(): fe rows with no phylo/structured column).
DOCS <- list(
  gaussian = list(vig_fixed = TRUE, vig_ri = TRUE, rox_fixed = TRUE,
    vig_text = "fixed effects; selected phylo(), ordinary random-effect, relmat(), spatial(), animal() routes"),
  student = list(vig_fixed = TRUE, vig_ri = FALSE, rox_fixed = TRUE, vig_text = "fixed effects only"),
  skew_normal = list(vig_fixed = FALSE, vig_ri = FALSE, rox_fixed = FALSE,
    vig_text = "skew_normal() or another family: not currently available through the Julia engine"),
  lognormal = list(vig_fixed = TRUE, vig_ri = FALSE, rox_fixed = TRUE, vig_text = "fixed effects only"),
  gamma = list(vig_fixed = TRUE, vig_ri = NA, rox_fixed = TRUE,
    vig_text = "fixed effects; selected large-phylogeny routes (ordinary RE not listed)"),
  beta = list(vig_fixed = TRUE, vig_ri = NA, rox_fixed = TRUE,
    vig_text = "fixed effects; selected large-phylogeny routes (ordinary RE not listed)"),
  zero_one_beta = list(vig_fixed = TRUE, vig_ri = FALSE, rox_fixed = TRUE, vig_text = "fixed effects only"),
  beta_binomial = list(vig_fixed = TRUE, vig_ri = FALSE, rox_fixed = TRUE,
    vig_text = "fixed effects only (proportion-beta-binomial.Rmd: random intercept 'not admitted through engine = \"julia\" yet')"),
  binomial = list(vig_fixed = TRUE, vig_ri = NA, rox_fixed = TRUE,
    vig_text = "binomial(link='logit'): fixed effects; selected large-phylogeny mean route (ordinary RE not listed). NB distribution-families.Rmd:806 and proportion-beta-binomial.Rmd:170 say plain binomial engine = \"julia\" 'remain(s) unsupported'"),
  poisson = list(vig_fixed = TRUE, vig_ri = NA, rox_fixed = TRUE,
    vig_text = "fixed effects; selected large-phylogeny routes; fixed-effect zi terms (ordinary RE not listed)"),
  nbinom2 = list(vig_fixed = TRUE, vig_ri = NA, rox_fixed = TRUE,
    vig_text = "fixed effects; selected large-phylogeny routes; fixed-effect zi terms (ordinary RE not listed)"),
  truncated_nbinom2 = list(vig_fixed = TRUE, vig_ri = FALSE, rox_fixed = TRUE, vig_text = "fixed effects only"),
  tweedie = list(vig_fixed = TRUE, vig_ri = FALSE, rox_fixed = TRUE, vig_text = "fixed effects only"),
  cumulative_logit = list(vig_fixed = TRUE, vig_ri = FALSE, rox_fixed = FALSE,
    vig_text = "fixed effects only (not named in the drmTMB() @param engine roxygen list)")
)
REG_FE <- tryCatch(drmTMB:::drm_julia_registry_families("fe"), error = function(e) character())
REG_FENCE <- tryCatch(drmTMB:::drm_julia_fe_only_fence_families(), error = function(e) character())
logf("registry fe: %s", paste(REG_FE, collapse = ","))
logf("registry fe-only RE fence: %s", paste(REG_FENCE, collapse = ","))

# ---- Julia-side helpers ----------------------------------------------------------
JL_FAM <- c(gaussian = "Gaussian()", student = "Student()", skew_normal = "SkewNormal()",
  lognormal = "LogNormal()", gamma = "Gamma()", beta = "Beta()",
  zero_one_beta = "ZeroOneBeta()", beta_binomial = "BetaBinomial()",
  binomial = "Binomial()", poisson = "Poisson()", nbinom2 = "NegBinomial2()",
  truncated_nbinom2 = "TruncatedNegBinomial2()", tweedie = "Tweedie()",
  cumulative_logit = "CumulativeLogit()")

jl_ready <- FALSE
jl <- function(code) JuliaCall::julia_eval(code)
# Evaluate `expr` into global `name`; return "" or the Julia error text.
jl_try <- function(name, expr) {
  code <- paste0("begin\n global ", name, "_err = \"\"\n global ", name, " = nothing\n",
    " try\n  global ", name, " = (", expr, ")\n catch e\n  global ", name,
    "_err = sprint(showerror, e)\n end\n ", name, "_err\nend")
  as.character(jl(code))
}
jl_init <- function() {
  if (jl_ready) return(invisible(TRUE))
  # the bridge has already booted Julia and loaded the module as drmTMB_backend
  r <- safe(JuliaCall::julia_command("using DRModels;"))
  same <- safe(jl("DRModels === drmTMB_backend"))
  logf("Julia: using DRModels -> %s; same module as drmTMB_backend: %s; pathof = %s; VERSION = %s; nthreads = %s",
    if (inherits(r, "error")) t6_err(r) else "ok", format(same),
    format(safe(jl("pathof(drmTMB_backend)"))), format(safe(jl("string(VERSION)"))),
    format(safe(jl("Threads.nthreads()"))))
  if (!isTRUE(same)) stop("native DRModels module is not the module the bridge loaded")
  jl_ready <<- TRUE
  invisible(TRUE)
}

# Julia formula text for the native fit (mirrors t6_formula()).
jl_formula_text <- function(fam, re, sigma_const = FALSE) {
  lhs <- if (fam %in% c("binomial", "beta_binomial")) "cbind(successes, failures)" else "y"
  rhs <- if (re == "ri") "x + f + (1 | g)" else "x + f"
  forms <- sprintf("@formula(%s ~ %s)", lhs, rhs)
  others <- t6_other_dpars(fam)
  for (nm in names(others)) {
    r <- if (nm == "sigma" && sigma_const) "1" else deparse(others[[nm]][[2]])
    forms <- c(forms, sprintf("@formula(%s ~ %s)", nm, r))
  }
  paste0("bf(", paste(forms, collapse = ", "), ")")
}

# Columns the bridge marshals (drm_julia_needed_columns): response(s) + RHS vars.
bridge_columns <- function(fam, re) {
  resp <- if (fam %in% c("binomial", "beta_binomial")) c("successes", "failures") else "y"
  c(resp, "x", "f", if (re == "ri") "g")
}

# Assign a data frame's columns into Julia and build a NamedTuple `name`.
# Character columns -> Vector{String}; numeric/integer columns are passed
# exactly as JuliaCall converts them (the conversion the bridge itself uses).
jl_put_nt <- function(name, df, cols) {
  parts <- character()
  for (cc in cols) {
    v <- df[[cc]]
    tmp <- paste0("t6tmp_", cc)
    if (is.factor(v) && !is.ordered(v)) v <- as.character(v)
    JuliaCall::julia_assign(tmp, v)
    parts <- c(parts, if (is.character(v)) sprintf("%s = String.(%s)", cc, tmp) else
      sprintf("%s = %s", cc, tmp))
  }
  jl(sprintf("begin global %s = (; %s); nothing end", name, paste(parts, collapse = ", ")))
  invisible(TRUE)
}

jl_vec <- function(expr) as.numeric(unlist(jl(sprintf("collect(Float64, %s)", expr))))

# ---- independent reference values -------------------------------------------------
# documented response mean (SPEC moment table) from hand parameters at given eta_mu
doc_mean <- function(fam, eta_mu, par) {
  if (fam %in% c("binomial", "beta_binomial")) return(t6_invlink(T6_LINKS[[fam]][["mu"]], eta_mu))
  t6_cond_moments(fam, eta_mu, par)$E
}

# ==================================================================================
run_cell <- function(cr) {
  fam <- cr$family; re <- cr$re
  key <- paste(fam, re, sep = "_")
  seed_r <- as.numeric(cr$seed_r)
  is_ri <- re == "ri"
  links <- T6_LINKS[[fam]]
  docs <- DOCS[[fam]]
  out <- list(family = fam, re = re, engine = "bridge", cell_k = cr$k, seed = cr$seed,
    seed_r = cr$seed_r, sim_seed_r = seed_r + 100, formula = NA,
    family_call = t6_family_text(fam), fallback = "", fit_ok = FALSE, fit_error = "",
    converged = NA, loglik = NA, coef = list(), tests = list())
  pred_rows <- list()
  t0 <- Sys.time()

  d <- t6_read_cell(cr$file, fam, "character")
  spec <- t6_formula(fam, re)
  out$formula <- spec$text
  sigma_const <- FALSE

  # ---- admission ------------------------------------------------------------------
  fj <- safe_w(drmTMB(spec$bf, family = t6_family_object(fam), data = d, engine = "julia"))
  adm <- list(first_try = list(formula = spec$text,
    admitted = !inherits(fj$value, "error"), message = errtxt(fj$value),
    warnings = fj$warnings))
  if (inherits(fj$value, "error")) {
    logf("[%s] bridge REFUSED: %s", key, errtxt(fj$value))
    if (!is.null(t6_other_dpars(fam)$sigma)) {
      spec2 <- t6_formula(fam, re, sigma_const = TRUE)
      fj2 <- safe_w(drmTMB(spec2$bf, family = t6_family_object(fam), data = d, engine = "julia"))
      adm$fallback_try <- list(formula = spec2$text, admitted = !inherits(fj2$value, "error"),
        message = errtxt(fj2$value), warnings = fj2$warnings)
      logf("[%s] bridge fallback sigma ~ 1: %s", key,
        if (inherits(fj2$value, "error")) paste("REFUSED:", errtxt(fj2$value)) else "admitted")
      if (!inherits(fj2$value, "error")) {
        fj <- fj2; spec <- spec2; sigma_const <- TRUE
        out$fallback <- "sigma ~ 1"; out$formula <- spec2$text
      }
    }
  }
  admitted <- !inherits(fj$value, "error")
  doc_expect <- if (is_ri) docs$vig_ri else docs$vig_fixed
  reg_expect <- if (is_ri) (fam %in% REG_FE && !(fam %in% REG_FENCE)) else fam %in% REG_FE
  adm$doc_vignette_expects_admitted <- doc_expect
  adm$doc_vignette_text <- docs$vig_text
  adm$doc_roxygen_lists_family_fixed <- docs$rox_fixed
  adm$registry_expects_admitted <- reg_expect
  adm$admitted <- admitted
  adm$verdict <- if (is.na(doc_expect)) {
    if (admitted) "admitted; vignette silent on this route (undocumented admission)" else
      "refused; vignette silent on this route"
  } else if (admitted == doc_expect) {
    "consistent with vignette"
  } else if (admitted) {
    "CANDIDATE: admitted although the vignette says it is not available"
  } else {
    "CANDIDATE: refused although the vignette says it is available"
  }
  if (admitted != reg_expect) adm$verdict <- paste(adm$verdict, "| differs from registry expectation")
  out$admission <- adm
  logf("[%s] admission: %s (%s)", key, admitted, adm$verdict)

  if (!admitted) {
    out$fit_error <- errtxt(fj$value)
    for (p in c("P2", "P3", "P4", "P5", "P8", "P11")) {
      out$tests[[p]] <- t6_test("NA", notes = paste("bridge refused the cell:", errtxt(fj$value)))
    }
    out$elapsed_s <- as.numeric(Sys.time() - t0, units = "secs")
    return(list(json = out, pred = NULL))
  }
  fitj <- fj$value
  jl_init()
  out$fit_ok <- TRUE
  out$fit_warnings <- fj$warnings
  dpars <- names(fitj$coefficients)
  out$class <- class(fitj)
  out$converged <- isTRUE(fitj$diagnostics$converged)
  out$loglik <- as.numeric(fitj$logLik)
  out$bridge_marginal <- fitj$bridge$marginal %||% NA
  out$bridge_iterations <- fitj$bridge$iterations %||% NA
  out$coef <- lapply(fitj$coefficients, function(b) list(names = names(b), values = unname(b)))
  raw_names <- as.character(unlist(fitj$bridge$coef_names))
  raw_vals <- as.numeric(unlist(fitj$bridge$coefficients))
  out$bridge_raw_coef <- list(names = raw_names, values = raw_vals)
  if (fam == "cumulative_logit") out$cutpoints <- list(values = unname(fitj$ordinal$cutpoints),
    names = names(fitj$ordinal$cutpoints))
  logf("[%s] bridge fit ok: conv=%s ll=%.8f marginal=%s dpars=%s (%.1fs)", key, out$converged,
    out$loglik, out$bridge_marginal, paste(dpars, collapse = ","),
    as.numeric(Sys.time() - t0, units = "secs"))

  # ---- native TMB fit (same formula as the bridge) ----------------------------------
  ft <- safe_w(drmTMB(spec$bf, family = t6_family_object(fam), data = d))
  fitt <- ft$value
  tmb_ok <- !inherits(fitt, "error")
  if (!tmb_ok) logf("[%s] native TMB fit ERROR: %s", key, errtxt(fitt))

  # ---- native Julia fit (same data/formula, same module, default options) --------
  cols <- bridge_columns(fam, re)
  dj <- d
  if (fam == "cumulative_logit") dj$y <- as.integer(d$y)   # what the bridge sends
  jl_put_nt("t6_nt", dj, cols)
  jform <- jl_formula_text(fam, re, sigma_const)
  t_j <- Sys.time()
  jerr <- jl_try("t6_fit", sprintf("drm(%s, %s; data = t6_nt)", jform, JL_FAM[[fam]]))
  out$native_julia <- list(call = sprintf("drm(%s, %s; data = t6_nt)", jform, JL_FAM[[fam]]),
    columns = cols, error = jerr,
    seconds = as.numeric(Sys.time() - t_j, units = "secs"))
  jl_ok <- identical(jerr, "")
  if (!jl_ok) logf("[%s] native Julia fit ERROR: %s", key, jerr)
  if (jl_ok) {
    out$native_julia$loglik <- as.numeric(jl("Float64(t6_fit.loglik)"))
    out$native_julia$converged <- as.logical(jl("t6_fit.converged"))
    out$native_julia$marginal <- as.character(jl("String(t6_fit.marginal)"))
    out$native_julia$theta <- jl_vec("t6_fit.theta")
    out$native_julia$coefnames <- as.character(unlist(jl(
      "vcat([String[string(p) * \"::\" * string(n) for n in ns] for (p, ns) in t6_fit.coefnames]...)")))
    out$native_julia$blocks <- as.character(unlist(jl("String[string(p) * \"=\" * string(r) for (p, r) in t6_fit.blocks]")))
  }
  jl_put_nt("t6_nd", nd_main, c("x", "f", "g", "trials"))

  # ===============================================================================
  # (a) P11 same-fit parity
  out$tests$P11 <- tryCatch({
    if (!jl_ok) stop("native Julia fit failed: ", jerr)
    det <- list()
    th <- out$native_julia$theta
    det$coef_len <- c(bridge = length(raw_vals), native = length(th))
    det$coef_max_abs_diff <- if (length(th) == length(raw_vals)) max(abs(th - raw_vals)) else Inf
    det$loglik_diff <- out$loglik - out$native_julia$loglik
    det$coef_names_bridge <- raw_names
    det$coef_names_native <- out$native_julia$coefnames
    # native predictions on nd_main (predict_parameters + predict for mu)
    e1 <- jl_try("t6_ppl", "predict_parameters(t6_fit, t6_nd; type = :link)")
    e2 <- jl_try("t6_ppr", "predict_parameters(t6_fit, t6_nd; type = :response)")
    e3 <- jl_try("t6_pml", "predict(t6_fit, t6_nd; type = :link)")
    e4 <- jl_try("t6_pmr", "predict(t6_fit, t6_nd; type = :response)")
    det$native_errors <- list(predict_parameters_link = e1, predict_parameters_response = e2,
      predict_link = e3, predict_response = e4)
    # native in-sample
    e5 <- jl_try("t6_ipl", "predict_parameters(t6_fit, t6_nt; type = :link)")
    e6 <- jl_try("t6_ipr", "predict_parameters(t6_fit, t6_nt; type = :response)")
    det$native_errors$insample_link <- e5; det$native_errors$insample_response <- e6
    bl <- if (is_ri && fam == "gaussian") {
      ee <- jl_try("t6_ranef", "collect(Float64, ranef(t6_fit)[:g])")
      if (identical(ee, "")) jl_vec("t6_ranef") else { det$native_errors$ranef <- ee; NULL }
    } else NULL
    gidx <- match(as.character(d$g), unique(as.character(d$g)))
    worst_link <- 0; worst_resp_same <- 0; semantic <- list(); errs <- character()
    for (dp in dpars) {
      jdp <- dp
      # bridge predictions
      bl_nd <- safe(predict(fitj, newdata = nd_main, dpar = dp, type = "link"))
      br_nd <- safe(predict(fitj, newdata = nd_main, dpar = dp, type = "response"))
      bl_in <- safe(predict(fitj, dpar = dp, type = "link"))
      br_in <- safe(predict(fitj, dpar = dp, type = "response"))
      for (ty in c("link", "response")) {
        v <- if (ty == "link") bl_nd else br_nd
        if (!inherits(v, "error")) pred_rows[[length(pred_rows) + 1L]] <- data.frame(
          row = seq_along(v), dpar = dp, type = ty, value = as.numeric(v), se = NA_real_)
      }
      # native values
      has <- function(obj) isTRUE(jl(sprintf("%s !== nothing && haskey(%s, :%s)", obj, obj, jdp)))
      jl_nd_l <- if (identical(e1, "") && has("t6_ppl")) jl_vec(sprintf("t6_ppl[:%s]", jdp)) else NULL
      jl_nd_r <- if (identical(e2, "") && has("t6_ppr")) jl_vec(sprintf("t6_ppr[:%s]", jdp)) else NULL
      jl_in_l <- if (identical(e5, "") && has("t6_ipl")) jl_vec(sprintf("t6_ipl[:%s]", jdp)) else NULL
      jl_in_r <- if (identical(e6, "") && has("t6_ipr")) jl_vec(sprintf("t6_ipr[:%s]", jdp)) else NULL
      r <- list()
      cmpv <- function(a, b) if (inherits(a, "error")) paste("bridge ERROR:", t6_err(a)) else
        if (is.null(b)) "native unavailable" else maxabs(a, b)
      r$nd_link <- cmpv(bl_nd, jl_nd_l)
      r$nd_response_vs_predict_parameters <- cmpv(br_nd, jl_nd_r)
      if (dp == "mu") {
        jm_l <- if (identical(e3, "")) jl_vec("t6_pml") else NULL
        jm_r <- if (identical(e4, "")) jl_vec("t6_pmr") else NULL
        r$nd_link_vs_predict <- cmpv(bl_nd, jm_l)
        r$nd_response_vs_predict <- cmpv(br_nd, jm_r)
        if (!is.null(jm_r) && !inherits(bl_nd, "error")) {
          # what does native predict(:response) hold? compare to known transforms
          r$native_predict_response_minus_exp_link <- maxabs(jm_r, exp(as.numeric(bl_nd)))
          r$native_predict_response_minus_plogis_link <- maxabs(jm_r, plogis(as.numeric(bl_nd)))
        }
      }
      # in-sample: compare like with like. Bridge Gaussian ri mu is conditional
      # (X b + BLUP); native predict_parameters is population-level.
      r$insample_link <- cmpv(bl_in, jl_in_l)
      r$insample_response <- cmpv(br_in, jl_in_r)
      if (!is.null(bl) && dp == "mu" && !is.null(jl_in_l)) {
        r$insample_link_vs_native_Xb_plus_ranef <- cmpv(bl_in, jl_in_l + bl[gidx])
      }
      # hand X theta(native) as a fallback reference when native predict refuses
      if (jl_ok) {
        jnames <- out$native_julia$coefnames
        thj <- out$native_julia$theta
        sel <- startsWith(jnames, paste0(dp, "::"))
        if (any(sel)) {
          Xh <- t6_design(fam, dp, nd_main)
          if (dp == "sigma" && sigma_const) Xh <- Xh[, 1, drop = FALSE]
          if (ncol(Xh) == sum(sel)) {
            r$nd_link_vs_hand_X_theta_native <- cmpv(bl_nd, as.vector(Xh %*% thj[sel]))
          }
        }
      }
      det[[dp]] <- r
      if (inherits(bl_nd, "error")) errs <- c(errs, paste(dp, t6_err(bl_nd)))
      if (is.numeric(r$nd_link)) worst_link <- max(worst_link, r$nd_link)
      if (is.numeric(r$insample_link) && !(is_ri && fam == "gaussian" && dp == "mu"))
        worst_link <- max(worst_link, r$insample_link)
      if (is.numeric(r$insample_link_vs_native_Xb_plus_ranef))
        worst_link <- max(worst_link, r$insample_link_vs_native_Xb_plus_ranef)
      if (is.numeric(r$nd_response_vs_predict_parameters)) {
        if (r$nd_response_vs_predict_parameters <= TOL11) {
          worst_resp_same <- max(worst_resp_same, r$nd_response_vs_predict_parameters)
        } else {
          semantic[[dp]] <- r$nd_response_vs_predict_parameters
        }
      }
    }
    det$worst_link <- worst_link
    det$worst_response_same_semantics <- worst_resp_same
    det$response_semantic_differences <- semantic
    native_unavail <- !identical(e1, "")
    st <- if (length(errs)) "FAIL" else if (native_unavail) "NA" else
      t6_status(worst_link <= TOL11 && det$coef_max_abs_diff <= TOL11)
    notes <- sprintf(
      "coef max|d| = %.3g, logLik d = %.3g; link max|d| (nd_main + in-sample) = %.3g; response same-semantics max|d| = %.3g; response semantic differences on: %s%s%s",
      det$coef_max_abs_diff, det$loglik_diff, worst_link, worst_resp_same,
      if (length(semantic)) paste(sprintf("%s (%.3g)", names(semantic), unlist(semantic)), collapse = ", ") else "none",
      if (native_unavail) paste0("; native predict_parameters refused: ", e1) else "",
      if (length(errs)) paste0("; bridge predict errors: ", paste(errs, collapse = "; ")) else "")
    t6_test(st, "max abs diff bridge vs native Julia (link)", worst_link, notes, det)
  }, error = function(e) t6_test("ERROR", notes = t6_err(e)))
  logf("[%s] P11 %s %s", key, out$tests$P11$status, out$tests$P11$notes)

  # ===============================================================================
  # (b) bridge vs native TMB on nd_main
  out$bridge_vs_tmb <- tryCatch({
    if (!tmb_ok) stop("native TMB fit failed: ", errtxt(fitt))
    det <- list()
    det$tmb_loglik <- as.numeric(logLik(fitt))
    det$loglik_diff <- out$loglik - det$tmb_loglik
    det$tmb_converged <- isTRUE(fitt$opt$convergence == 0)
    cd <- list()
    for (dp in intersect(dpars, names(fitt$coefficients))) {
      a <- fitj$coefficients[[dp]]; b <- fitt$coefficients[[dp]]
      cd[[dp]] <- if (identical(names(a), names(b))) max(abs(a - b)) else
        paste("names differ:", paste(names(a), collapse = ","), "vs", paste(names(b), collapse = ","))
    }
    if (fam == "cumulative_logit") cd$cutpoints <- maxabs(fitj$ordinal$cutpoints, fitt$ordinal$cutpoints)
    if (is_ri) {
      det$sd_g <- list(bridge_raw = raw_vals[grepl("resd", raw_names)],
        bridge_raw_names = raw_names[grepl("resd", raw_names)],
        tmb = unname(fitt$sdpars$mu[["(1 | g)"]]))
    }
    det$coef_max_abs_diff <- cd
    cnum <- unlist(Filter(is.numeric, cd))
    det$coef_max_overall <- if (length(cnum)) max(cnum) else NA
    pdiff <- list()
    for (dp in intersect(dpars, names(fitt$coefficients))) {
      for (ty in c("link", "response")) {
        a <- safe(predict(fitj, newdata = nd_main, dpar = dp, type = ty))
        b <- safe(predict(fitt, newdata = nd_main, dpar = dp, type = ty))
        pdiff[[paste(dp, ty, sep = ":")]] <- if (inherits(a, "error") || inherits(b, "error"))
          paste("ERROR:", errtxt(a), "|", errtxt(b)) else
          list(max_abs = maxabs(a, b), max_rel = maxrel(a, b))
      }
    }
    det$predict_nd_main <- pdiff
    pm <- unlist(lapply(pdiff, function(x) if (is.list(x)) x$max_abs else NA))
    det$predict_max_abs <- suppressWarnings(max(pm, na.rm = TRUE))
    det$receipt_bar_1e4 <- list(coef_ok = isTRUE(det$coef_max_overall <= 1e-4),
      loglik_ok = isTRUE(abs(det$loglik_diff) <= 1e-4))
    det
  }, error = function(e) list(error = t6_err(e)))
  logf("[%s] bridge vs TMB: coef max %s, logLik d %s, predict max %s", key,
    format(out$bridge_vs_tmb$coef_max_overall), format(out$bridge_vs_tmb$loglik_diff),
    format(out$bridge_vs_tmb$predict_max_abs))

  # ===============================================================================
  # (c) P2 unseen g / g removed
  nd_pred <- list()
  out$tests$P2 <- tryCatch({
    det <- list(); worst <- 0; errs <- character()
    nd_nog <- nd_main[, setdiff(names(nd_main), "g")]
    for (dp in dpars) {
      pl <- safe(predict(fitj, newdata = nd_main, dpar = dp, type = "link"))
      pr <- safe(predict(fitj, newdata = nd_main, dpar = dp, type = "response"))
      if (inherits(pl, "error") || inherits(pr, "error")) {
        errs <- c(errs, sprintf("%s: %s", dp, t6_err(if (inherits(pl, "error")) pl else pr)))
        next
      }
      nd_pred[[dp]] <- list(link = pl, response = pr)
      eta_nd <- t6_eta(fitj, fam, dp, nd_main)
      if (dp == "sigma" && sigma_const) eta_nd <- rep(unname(fitj$coefficients$sigma[1]), nrow(nd_main))
      a <- maxmix(pl, eta_nd)
      b <- maxmix(pr, t6_invlink(links[[dp]], eta_nd))
      s1 <- maxabs(pl[1:9], pl[10:18]); s2 <- maxabs(pr[1:9], pr[10:18])
      plg <- safe(predict(fitj, newdata = nd_nog, dpar = dp, type = "link"))
      prg <- safe(predict(fitj, newdata = nd_nog, dpar = dp, type = "response"))
      g_rm <- if (inherits(plg, "error")) paste("ERROR:", t6_err(plg)) else max(maxabs(plg, pl), maxabs(prg, pr))
      det[[dp]] <- list(link_vs_pop_Xb = a, response_vs_invlink_pop = b,
        seen_vs_unseen_g_link = s1, seen_vs_unseen_g_response = s2, g_removed_vs_with_g = g_rm)
      worst <- max(worst, a, b, s1, s2, if (is.numeric(g_rm)) g_rm else Inf)
    }
    if (length(errs)) t6_test("FAIL", "error", NA,
      paste("predict(newdata = nd_main) errored:", paste(errs, collapse = "; ")), det) else
      t6_test(t6_status(worst <= TOL1), "max mixed abs/rel diff", worst,
        "nd_main (g01 seen, gNEW unseen) vs population X_new beta (bridge coefficients, documented links); seen==unseen; g removed", det)
  }, error = function(e) t6_test("ERROR", notes = t6_err(e)))
  logf("[%s] P2 %s value=%s", key, out$tests$P2$status, format(out$tests$P2$value))

  # P3 level subset
  out$tests$P3 <- tryCatch({
    det <- list(); worst <- 0; refused <- character(); silent_bad <- FALSE
    for (enc in c("character", "factor_b", "factor_abc")) {
      nds <- nd_subset; nds$f <- t6_f_convert(nds$f, enc)
      for (dp in names(nd_pred)) for (ty in c("link", "response")) {
        v <- safe(predict(fitj, newdata = nds, dpar = dp, type = ty))
        lab <- paste(enc, dp, ty, sep = ":")
        if (inherits(v, "error")) {
          refused <- c(refused, lab); det[[lab]] <- paste("REFUSED:", t6_err(v)); next
        }
        dd <- maxmix(v, nd_pred[[dp]][[ty]][idx_b])
        det[[lab]] <- dd; worst <- max(worst, dd)
        if (dd > TOL1) silent_bad <- TRUE
      }
    }
    t6_test(if (silent_bad) "FAIL" else "PASS", "max mixed diff vs nd_main f=b rows", worst,
      paste0("encodings: character, factor(levels='b'), factor(levels=a,b,c)",
        if (length(refused)) paste0("; refusals: ", length(refused)) else "; no refusals"), det)
  }, error = function(e) t6_test("ERROR", notes = t6_err(e)))
  logf("[%s] P3 %s value=%s", key, out$tests$P3$status, format(out$tests$P3$value))

  # P4 unseen fixed-effect level
  out$tests$P4 <- tryCatch({
    det <- list()
    for (dp in dpars) {
      v <- safe(predict(fitj, newdata = nd_unseen, dpar = dp, type = "response"))
      det[[dp]] <- if (inherits(v, "error")) paste("REFUSED:", t6_err(v)) else
        list(values = as.numeric(v), note = "returned values")
    }
    mu_msg <- det$mu
    mu_refused <- is.character(mu_msg) && startsWith(mu_msg, "REFUSED")
    names_it <- mu_refused && grepl("\\bf\\b|`f`", mu_msg) && grepl("\"d\"|'d'|\\bd\\b", mu_msg)
    t6_test(if (mu_refused && names_it) "PASS" else "FAIL", "mu refusal names factor/level",
      as.numeric(names_it),
      if (mu_refused) paste("mu message:", sub("^REFUSED: ", "", mu_msg)) else "mu returned a silent numeric answer", det)
  }, error = function(e) t6_test("ERROR", notes = t6_err(e)))
  logf("[%s] P4 %s %s", key, out$tests$P4$status, out$tests$P4$notes)

  # P5 character vs factor
  out$tests$P5 <- tryCatch({
    det <- list(); fails <- character()
    d_fac <- t6_read_cell(cr$file, fam, "factor")
    d_rel <- t6_read_cell(cr$file, fam, "relevel")
    fit_fac <- drmTMB(spec$bf, family = t6_family_object(fam), data = d_fac, engine = "julia")
    fit_rel <- drmTMB(spec$bf, family = t6_family_object(fam), data = d_rel, engine = "julia")
    nm_same <- identical(lapply(fitj$coefficients, names), lapply(fit_fac$coefficients, names))
    cdiff <- max(unlist(Map(function(a, b) maxabs(a, b), fitj$coefficients, fit_fac$coefficients)))
    det$coef_char_vs_factor <- list(names_identical = nm_same, max_abs = cdiff)
    if (!nm_same || cdiff > TOL1) fails <- c(fails, "coef char vs factor")
    det$rel_coef_names <- lapply(fit_rel$coefficients, names)
    det$loglik <- list(char = fitj$logLik, factor = fit_fac$logLik, relevel = fit_rel$logLik)
    nd_fac <- nd_main; nd_fac$f <- factor(nd_fac$f)
    nd_rel <- nd_main; nd_rel$f <- factor(nd_rel$f, levels = c("c", "a", "b"))
    cmp <- function(a, b, tol, rel = FALSE) {
      if (inherits(a, "error")) return(list(error = t6_err(a), ok = FALSE))
      v <- maxmix(a, b)
      if (rel) list(diff = v, rel = maxrel(a, b), ok = v <= tol) else list(diff = v, ok = v <= tol)
    }
    score_from <- function(f_, pl) t6_cond_moments("cumulative_logit", pl,
      list(cutpoints = unname(f_$ordinal$cutpoints)))$E
    for (dp in names(nd_pred)) for (ty in c("link", "response")) {
      base <- nd_pred[[dp]][[ty]]
      p_fac_chr <- safe(predict(fit_fac, newdata = nd_main, dpar = dp, type = ty))
      p_chr_fac <- safe(predict(fitj, newdata = nd_fac, dpar = dp, type = ty))
      p_chr_rel <- safe(predict(fitj, newdata = nd_rel, dpar = dp, type = ty))
      p_rel_chr <- safe(predict(fit_rel, newdata = nd_main, dpar = dp, type = ty))
      p_rel_fac <- safe(predict(fit_rel, newdata = nd_fac, dpar = dp, type = ty))
      r <- list(factorfit_chrnd = cmp(p_fac_chr, base, TOL1),
        charfit_factornd = cmp(p_chr_fac, base, TOL1),
        charfit_relevelnd = cmp(p_chr_rel, base, TOL1),
        relevelfit_factornd_vs_relevelfit_chrnd = if (inherits(p_rel_chr, "error")) list(error = t6_err(p_rel_chr), ok = FALSE) else cmp(p_rel_fac, p_rel_chr, TOL1))
      if (fam == "cumulative_logit" && dp == "mu") {
        r$relevelfit_vs_char_expected_score <- if (inherits(p_rel_chr, "error")) list(error = t6_err(p_rel_chr), ok = FALSE) else
          cmp(score_from(fit_rel, p_rel_chr), score_from(fitj, base), TOLREL, rel = TRUE)
      } else {
        r$relevelfit_vs_char <- cmp(p_rel_chr, base, TOLREL, rel = TRUE)
      }
      for (nm in names(r)) if (!isTRUE(r[[nm]]$ok)) fails <- c(fails, paste(dp, ty, nm))
      det[[paste(dp, ty, sep = ":")]] <- r
    }
    # in-sample refit with relevel: compare logLik (reparameterisation)
    det$loglik_relevel_minus_char <- fit_rel$logLik - fitj$logLik
    t6_test(if (length(fails)) "FAIL" else "PASS", "char/factor/relevel agreement", length(fails),
      if (length(fails)) paste("failing:", paste(unique(fails), collapse = "; ")) else
        "coef char==factor; predictions agree across fit/newdata encodings", det)
  }, error = function(e) t6_test("ERROR", notes = t6_err(e)))
  logf("[%s] P5 %s %s", key, out$tests$P5$status, out$tests$P5$notes)

  # ===============================================================================
  # (d) simulate()
  out$tests$P8 <- tryCatch({
    meth <- format(methods(class = "drmTMB_julia"))
    has_sim <- any(grepl("^simulate", meth))
    s1 <- safe_w(simulate(fitj, nsim = NSIM, seed = seed_r + 100))
    det <- list(methods_drmTMB_julia = meth, has_simulate_method = has_sim,
      simulate_result_class = if (inherits(s1$value, "error")) NA else class(s1$value),
      simulate_error = errtxt(s1$value), simulate_warnings = s1$warnings,
      getS3method = !is.null(utils::getS3method("simulate", "drmTMB_julia", optional = TRUE)))
    if (!has_sim && inherits(s1$value, "error")) {
      t6_test("NA", "simulate method exists", 0,
        paste("no simulate method for class drmTMB_julia; simulate(fit, nsim = 1000, seed =) ->", errtxt(s1$value)), det)
    } else {
      t6_test("NA", "simulate method exists", as.numeric(has_sim),
        "simulate returned something on a bridge fit; moment check not implemented in this script (see details)", det)
    }
  }, error = function(e) t6_test("ERROR", notes = t6_err(e)))
  logf("[%s] P8(simulate) %s %s", key, out$tests$P8$status, out$tests$P8$notes)

  # ===============================================================================
  # (e) fitted() semantics
  out$fitted <- tryCatch({
    det <- list()
    fvj <- fitted(fitj)
    det$bridge_fitted_class <- class(fvj); det$bridge_fitted_length <- length(fvj)
    # independent reference from the bridge's own coefficients (population X b; Gaussian ri
    # in-sample conditional mu uses the bridge's own stored-row link prediction)
    eta_pop <- list(); par_resp <- list()
    for (dp in dpars) {
      e <- t6_eta(fitj, fam, dp, d)
      if (dp == "sigma" && sigma_const) e <- rep(unname(fitj$coefficients$sigma[1]), nrow(d))
      eta_pop[[dp]] <- e
      par_resp[[dp]] <- t6_invlink(links[[dp]], e)
    }
    trials_in <- if (fam %in% c("binomial", "beta_binomial")) d$successes + d$failures else NULL
    cutp <- if (fam == "cumulative_logit") unname(fitj$ordinal$cutpoints) else NULL
    par_o <- c(par_resp[setdiff(dpars, "mu")], list(trials = trials_in, cutpoints = cutp))
    E_pop <- doc_mean(fam, eta_pop$mu, par_o)
    mu_pop <- par_resp$mu
    det$bridge_fitted_vs_documented_mean_popXb <- maxmix(fvj, E_pop)
    det$bridge_fitted_vs_invlink_mu_popXb <- maxmix(fvj, mu_pop)
    if (fam == "lognormal") det$bridge_fitted_vs_exp_mu_median <- maxmix(fvj, exp(eta_pop$mu))
    if (fam == "cumulative_logit") det$bridge_fitted_vs_eta <- maxmix(fvj, eta_pop$mu)
    if (is_ri) {
      bl_in <- safe(predict(fitj, dpar = "mu", type = "link"))
      if (!inherits(bl_in, "error")) {
        E_cond <- doc_mean(fam, as.numeric(bl_in), par_o)
        det$bridge_fitted_vs_documented_mean_conditional <- maxmix(fvj, E_cond)
      }
    }
    if (jl_ok) {
      fjn <- jl_vec("fitted(t6_fit)")
      det$bridge_fitted_vs_native_julia_fitted <- maxabs(fvj, fjn)
    }
    if (tmb_ok) {
      fvt <- fitted(fitt)
      det$tmb_fitted_vs_bridge_fitted <- list(max_abs = maxabs(fvj, fvt), max_rel = maxrel(fvj, fvt),
        mean_bridge = mean(fvj), mean_tmb = mean(fvt))
      det$tmb_fitted_vs_documented_mean_popXb_bridgecoef <- maxmix(fvt, E_pop)
    }
    det$mean_observed_y <- if (fam %in% c("binomial", "beta_binomial")) mean(d$successes / (d$successes + d$failures)) else
      if (fam == "cumulative_logit") mean(as.integer(d$y)) else mean(d$y)
    det$semantics <- if (isTRUE(det$bridge_fitted_vs_documented_mean_popXb <= 1e-8) &&
      (!is_ri || fam != "gaussian")) "documented mean at population X b" else
      if (isTRUE(det$bridge_fitted_vs_invlink_mu_popXb <= 1e-8)) "inverse-link mu at population X b (not the documented mean)" else
      if (isTRUE(det$bridge_fitted_vs_documented_mean_conditional <= 1e-8)) "documented mean, conditional on BLUPs" else "other"
    det
  }, error = function(e) list(error = t6_err(e)))
  logf("[%s] fitted(): %s; vs TMB fitted max abs %s", key, format(out$fitted$semantics),
    format(out$fitted$tmb_fitted_vs_bridge_fitted$max_abs))

  out$elapsed_s <- as.numeric(Sys.time() - t0, units = "secs")
  pred <- if (length(pred_rows)) do.call(rbind, pred_rows) else NULL
  list(json = out, pred = pred)
}

# ==================================================================================
summ <- list()
for (i in seq_len(nrow(cells))) {
  cr <- cells[i, ]
  key <- paste(cr$family, cr$re, sep = "_")
  logf("==== [%s] ====", key)
  res <- tryCatch(run_cell(cr), error = function(e) {
    logf("[%s] HARNESS ERROR: %s", key, t6_err(e))
    list(json = list(family = cr$family, re = cr$re, engine = "bridge", harness_error = t6_err(e)), pred = NULL)
  })
  j <- res$json
  writeLines(jsonlite::toJSON(j, auto_unbox = TRUE, pretty = TRUE, digits = NA, null = "null", na = "null"),
    file.path(T6_RES, sprintf("bridge_%s.json", key)))
  if (!is.null(res$pred)) utils::write.csv(res$pred, file.path(T6_RES, sprintf("bridge_%s_pred.csv", key)), row.names = FALSE)
  st <- function(p) if (!is.null(j$tests[[p]])) j$tests[[p]]$status else NA
  summ[[length(summ) + 1L]] <- data.frame(
    cell = key, family = cr$family, re = cr$re,
    admitted = isTRUE(j$admission$admitted), fallback = j$fallback %||% "",
    admission_verdict = j$admission$verdict %||% NA,
    refusal = if (isTRUE(j$admission$admitted)) "" else (j$admission$first_try$message %||% ""),
    converged = j$converged %||% NA, loglik = j$loglik %||% NA,
    bridge_marginal = j$bridge_marginal %||% NA,
    P11 = st("P11"), P11_link_maxabs = if (!is.null(j$tests$P11$value)) j$tests$P11$value else NA,
    P11_coef_maxabs = j$tests$P11$details$coef_max_abs_diff %||% NA,
    P11_loglik_diff = j$tests$P11$details$loglik_diff %||% NA,
    P11_resp_semantic = if (length(j$tests$P11$details$response_semantic_differences))
      paste(names(j$tests$P11$details$response_semantic_differences), collapse = ";") else "",
    tmb_coef_maxabs = j$bridge_vs_tmb$coef_max_overall %||% NA,
    tmb_loglik_diff = j$bridge_vs_tmb$loglik_diff %||% NA,
    tmb_predict_maxabs = j$bridge_vs_tmb$predict_max_abs %||% NA,
    P2 = st("P2"), P3 = st("P3"), P4 = st("P4"), P5 = st("P5"), P8 = st("P8"),
    fitted_semantics = j$fitted$semantics %||% NA,
    fitted_vs_tmb_maxabs = j$fitted$tmb_fitted_vs_bridge_fitted$max_abs %||% NA,
    seconds = j$elapsed_s %||% NA, stringsAsFactors = FALSE)
  utils::write.csv(do.call(rbind, summ), file.path(T6_RES, "bridge_summary.csv"), row.names = FALSE)
}
logf("done")
