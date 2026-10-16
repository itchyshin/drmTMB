# t6 (sweep-oct16): diagnostics behind the P11 bridge candidates (30_bridge.R).
#
# D1  Gaussian (1 | g) refusal: is it the factor predictor? Root cause in the
#     conditional-Gaussian Julia helper (R/julia-bridge.R:4174-4247), which calls
#     `_bridge_formula(...)` without `labels = true` and `_bridge_flatten(...)`
#     without `labels`/`coef_labels`, so the `bridge_formula_labels_v1` map is
#     never returned and drmTMB's fail-closed base-R spelling check refuses.
#     (a) numeric-only mean formula y ~ x + (1 | g): admitted? if so, P11 parity
#         on it (bridge vs native DRModels.jl, same module, same data).
#     (b) f as factor: same refusal?
#     (c) same payload sent through the MAIN bridge entry (drmTMB_drm_bridge)
#         versus the conditional entry: which returns the label contract?
#
# Run: Rscript R/31_bridge_diag.R > logs/bridge_diag.log 2>&1

Sys.setenv(JULIA_DEPOT_PATH = "/opt/julia-depot", DRMODELS_JL_PATH = "/home/user/DRModels.jl",
  NOT_CRAN = "true", JULIA_HOME = "/opt/julia-env/bin", JULIA_NUM_THREADS = "1",
  OPENBLAS_NUM_THREADS = "1", OMP_NUM_THREADS = "1")
options(warn = 1, width = 200)
suppressPackageStartupMessages({ library(drmTMB); library(jsonlite) })
if (!exists("%||%", baseenv())) assign("%||%", function(x, y) if (is.null(x)) y else x, envir = globalenv())
source("/home/user/drmTMB/sweep-oct16/t6/R/lib_t6.R")
logf <- function(fmt, ...) { cat(format(Sys.time(), "%H:%M:%S"), sprintf(fmt, ...), "\n"); flush(stdout()) }
safe <- function(expr) tryCatch(expr, error = function(e) e)
et <- function(e) if (inherits(e, "error")) t6_err(e) else "ok"
jl <- function(code) JuliaCall::julia_eval(code)
jl_vec <- function(expr) as.numeric(unlist(jl(sprintf("collect(Float64, %s)", expr))))
OUT <- list()

nd_main <- utils::read.csv(file.path(T6_DATA, "nd_main.csv"), stringsAsFactors = FALSE)
d <- t6_read_cell("gaussian_ri.csv", "gaussian", "character")
logf("drmTMB %s, R %s", as.character(utils::packageVersion("drmTMB")), R.version.string)

# ---- D1(b) SPEC formula, character f and factor f ---------------------------------
spec <- t6_formula("gaussian", "ri")
r_chr <- safe(drmTMB(spec$bf, family = gaussian(), data = d, engine = "julia"))
logf("D1 SPEC formula %s, f character: %s", spec$text, et(r_chr))
d_fac <- t6_read_cell("gaussian_ri.csv", "gaussian", "factor")
r_fac <- safe(drmTMB(spec$bf, family = gaussian(), data = d_fac, engine = "julia"))
logf("D1 SPEC formula, f factor: %s", et(r_fac))
OUT$D1b <- list(formula = spec$text, character_f = et(r_chr), factor_f = et(r_fac))

# ---- D1(a) numeric-only mean formula ----------------------------------------------
f_num <- bf(y ~ x + (1 | g), sigma ~ x)
fitj <- safe(drmTMB(f_num, family = gaussian(), data = d, engine = "julia"))
logf("D1 numeric-only formula bf(y ~ x + (1 | g), sigma ~ x): %s", et(fitj))
OUT$D1a <- list(formula = "bf(y ~ x + (1 | g), sigma ~ x)", bridge = et(fitj))
JuliaCall::julia_command("using DRModels;")
stopifnot(isTRUE(jl("DRModels === drmTMB_backend")))
JuliaCall::julia_assign("t6tmp_y", d$y); JuliaCall::julia_assign("t6tmp_x", d$x)
JuliaCall::julia_assign("t6tmp_g", d$g)
jl("begin global t6_nt = (; y = t6tmp_y, x = t6tmp_x, g = String.(t6tmp_g)); nothing end")
JuliaCall::julia_assign("t6tmp_ndx", nd_main$x); JuliaCall::julia_assign("t6tmp_ndf", nd_main$f)
JuliaCall::julia_assign("t6tmp_ndg", nd_main$g)
jl("begin global t6_nd = (; x = t6tmp_ndx, f = String.(t6tmp_ndf), g = String.(t6tmp_ndg)); nothing end")
jl("begin global t6_fit = drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ x)), Gaussian(); data = t6_nt); nothing end")
if (!inherits(fitj, "error")) {
  th <- jl_vec("t6_fit.theta")
  raw <- as.numeric(unlist(fitj$bridge$coefficients))
  a <- list(coef_names = as.character(unlist(fitj$bridge$coef_names)),
    coef_max_abs = if (length(th) == length(raw)) max(abs(th - raw)) else Inf,
    loglik_bridge = fitj$logLik, loglik_native = as.numeric(jl("t6_fit.loglik")))
  bhat <- jl_vec("ranef(t6_fit)[:g]")
  gidx <- match(d$g, unique(d$g))
  Xb_in <- jl_vec("predict_parameters(t6_fit, t6_nt; type = :link)[:mu]")
  a$insample_mu_link_vs_native_Xb_plus_ranef <- max(abs(predict(fitj, dpar = "mu", type = "link") - (Xb_in + bhat[gidx])))
  a$insample_mu_link_vs_native_Xb_only <- max(abs(predict(fitj, dpar = "mu", type = "link") - Xb_in))
  a$insample_sigma_link <- max(abs(predict(fitj, dpar = "sigma", type = "link") -
    jl_vec("predict_parameters(t6_fit, t6_nt; type = :link)[:sigma]")))
  for (dp in c("mu", "sigma")) for (ty in c("link", "response")) {
    a[[paste0("nd_main_", dp, "_", ty)]] <- max(abs(predict(fitj, newdata = nd_main, dpar = dp, type = ty) -
      jl_vec(sprintf("predict_parameters(t6_fit, t6_nd; type = :%s)[:%s]", ty, dp))))
  }
  a$fitted_bridge_vs_native_fitted <- max(abs(fitted(fitj) - jl_vec("fitted(t6_fit)")))
  a$fitted_bridge_vs_conditional_mu <- max(abs(fitted(fitj) - predict(fitj, dpar = "mu", type = "response")))
  fitt <- drmTMB(f_num, family = gaussian(), data = d)
  a$tmb_fitted_vs_conditional_mu <- max(abs(fitted(fitt) - predict(fitt, dpar = "mu", type = "response")))
  a$tmb_vs_bridge_coef_mu <- max(abs(fitt$coefficients$mu - fitj$coefficients$mu))
  a$tmb_vs_bridge_coef_sigma <- max(abs(fitt$coefficients$sigma - fitj$coefficients$sigma))
  a$tmb_vs_bridge_loglik <- as.numeric(logLik(fitt)) - fitj$logLik
  a$tmb_vs_bridge_insample_mu <- max(abs(predict(fitt, dpar = "mu") - predict(fitj, dpar = "mu")))
  a$tmb_vs_bridge_fitted <- max(abs(fitted(fitt) - fitted(fitj)))
  OUT$D1a <- c(OUT$D1a, a)
  logf("D1(a) parity: %s", paste(names(a), vapply(a, function(z) paste(format(z), collapse = ","), ""), sep = "=", collapse = "; "))
}

# ---- D1(c) same SPEC payload: main bridge entry vs conditional entry ---------------
pl <- safe(drmTMB:::drm_julia_bridge_payload(formula = spec$bf, family_type = "gaussian", data = d,
  env = globalenv(), method = "ML", control_overrides = list()))
logf("D1(c) payload: %s; coef_labels: %s", et(pl),
  if (!inherits(pl, "error")) paste(names(pl$coef_labels), vapply(pl$coef_labels, paste, "", collapse = ","), sep = "=", collapse = " ; ") else "")
if (!inherits(pl, "error")) {
  r_main <- safe(JuliaCall::julia_call("drmTMB_drm_bridge", pl$formula, "gaussian", as.list(pl$data), NULL, pl$options))
  r_cond <- safe(JuliaCall::julia_call("drmTMB_drm_bridge_conditional_gaussian_components", pl$formula, "gaussian",
    as.list(pl$data), NULL, pl$options))
  summ <- function(r) if (inherits(r, "error")) list(error = t6_err(r)) else list(
    coef_names = as.character(unlist(r$coef_names)),
    coef_label_contract = r$coef_label_contract %||% "(absent)",
    raw_coef_names = as.character(unlist(r$raw_coef_names %||% NA)),
    has_conditional_re = !is.null(r$conditional_re), loglik = r$loglik)
  OUT$D1c <- list(main_entry = summ(r_main), conditional_entry = summ(r_cond))
  logf("D1(c) main entry coef_names: %s | contract: %s", paste(OUT$D1c$main_entry$coef_names, collapse = ","),
    OUT$D1c$main_entry$coef_label_contract)
  logf("D1(c) conditional entry coef_names: %s | contract: %s", paste(OUT$D1c$conditional_entry$coef_names, collapse = ","),
    OUT$D1c$conditional_entry$coef_label_contract)
}

# ---- D2 non-Gaussian (1 | g): R lets it through, Julia fits, then the label echo aborts ----
put_nt <- function(name, df, cols) {
  parts <- character()
  for (cc in cols) {
    v <- df[[cc]]; tmp <- paste0("t6tmp_", cc)
    JuliaCall::julia_assign(tmp, v)
    parts <- c(parts, if (is.character(v)) sprintf("%s = String.(%s)", cc, tmp) else sprintf("%s = %s", cc, tmp))
  }
  jl(sprintf("begin global %s = (; %s); nothing end", name, paste(parts, collapse = ", ")))
}
OUT$D2 <- list()
for (fam in c("poisson", "nbinom2")) {
  dd <- t6_read_cell(sprintf("%s_ri.csv", fam), fam, "character")
  sp <- t6_formula(fam, "ri")
  t0 <- Sys.time()
  r <- safe(drmTMB(sp$bf, family = t6_family_object(fam), data = dd, engine = "julia"))
  secs <- as.numeric(Sys.time() - t0, units = "secs")
  pl2 <- safe(drmTMB:::drm_julia_bridge_payload(formula = sp$bf, family_type = fam, data = dd,
    env = globalenv(), method = "ML", control_overrides = list()))
  fence <- fam %in% drmTMB:::drm_julia_fe_only_fence_families()
  # the same payload WITHOUT coef_labels: does DRM.jl's bridge fit it?
  nolab <- if (!inherits(pl2, "error")) {
    o <- pl2$options; o$coef_labels <- NULL
    rr <- safe(JuliaCall::julia_call("drmTMB_drm_bridge", pl2$formula, fam, as.list(pl2$data), NULL,
      if (length(o)) o else NULL))
    if (inherits(rr, "error")) list(error = substr(t6_err(rr), 1, 400)) else
      list(coef_names = as.character(unlist(rr$coef_names)), loglik = rr$loglik, marginal = rr$marginal,
        converged = rr$converged)
  } else list(error = t6_err(pl2))
  # native DRModels on the same data
  cols <- c("y", "x", "f", "g")
  put_nt("t6_nt2", dd, cols)
  jerr <- as.character(jl(sprintf(
    "begin global t6_e2 = \"\"; try; global t6_f2 = drm(%s, %s; data = t6_nt2); catch e; global t6_e2 = sprint(showerror, e); end; t6_e2 end",
    sub("^bf\\(", "bf(", paste0("bf(@formula(y ~ x + f + (1 | g))", if (fam == "nbinom2") ", @formula(sigma ~ x)" else "", ")")),
    c(poisson = "Poisson()", nbinom2 = "NegBinomial2()")[[fam]])))
  nat <- if (identical(jerr, "")) list(loglik = as.numeric(jl("t6_f2.loglik")), marginal = as.character(jl("String(t6_f2.marginal)")),
    coefnames = as.character(unlist(jl("vcat([String[string(p) * \"::\" * string(n) for n in ns] for (p, ns) in t6_f2.coefnames]...)")))) else list(error = jerr)
  tmb <- safe(drmTMB(sp$bf, family = t6_family_object(fam), data = dd))
  OUT$D2[[fam]] <- list(formula = sp$text, bridge = et(r), seconds_to_refusal = secs,
    in_fe_only_fence = fence,
    payload_coef_label_dpars = if (inherits(pl2, "error")) t6_err(pl2) else names(pl2$coef_labels),
    main_entry_without_coef_labels = nolab, native_drmodels = nat,
    native_tmb = if (inherits(tmb, "error")) t6_err(tmb) else list(loglik = as.numeric(logLik(tmb)), converged = isTRUE(tmb$opt$convergence == 0)))
  logf("D2 %s: refused after %.1fs; fence=%s; payload label dpars=%s; no-label bridge: %s; native DRModels: %s; TMB: %s",
    fam, secs, fence, paste(OUT$D2[[fam]]$payload_coef_label_dpars, collapse = ","),
    if (!is.null(nolab$error)) nolab$error else paste("fits, names", paste(nolab$coef_names, collapse = ","), "ll", format(nolab$loglik)),
    if (!is.null(nat$error)) nat$error else paste("fits ll", format(nat$loglik), "marginal", nat$marginal),
    if (inherits(tmb, "error")) t6_err(tmb) else paste("fits ll", format(as.numeric(logLik(tmb)))))
}

# ---- D3 fitted()/residuals() semantics, bridge vs native drmTMB ---------------------
OUT$D3 <- list()
for (fam in c("lognormal", "truncated_nbinom2")) {
  dd <- t6_read_cell(sprintf("%s_fixed.csv", fam), fam, "character")
  sp <- t6_formula(fam, "fixed")
  fj <- drmTMB(sp$bf, family = t6_family_object(fam), data = dd, engine = "julia")
  ft <- drmTMB(sp$bf, family = t6_family_object(fam), data = dd)
  eta <- predict(fj, dpar = "mu", type = "link"); s <- predict(fj, dpar = "sigma", type = "response")
  arith <- if (fam == "lognormal") exp(eta + s^2 / 2) else { mu <- exp(eta); k <- 1 / s^2; mu / (1 - (k / (k + mu))^k) }
  comp <- exp(eta)
  OUT$D3[[fam]] <- list(
    rows_1_3 = list(bridge_fitted = head(fitted(fj), 3), tmb_fitted = head(fitted(ft), 3),
      hand_documented_mean = head(arith, 3), hand_exp_eta = head(comp, 3), y = head(dd$y, 3)),
    bridge_fitted_vs_exp_eta = max(abs(fitted(fj) - comp)),
    tmb_fitted_vs_documented_mean = max(abs(fitted(ft) - arith)),
    bridge_vs_tmb_fitted_maxabs = max(abs(fitted(fj) - fitted(ft))),
    bridge_vs_tmb_residuals_maxabs = max(abs(residuals(fj) - residuals(ft))),
    mean_y = mean(dd$y), mean_bridge_fitted = mean(fitted(fj)), mean_tmb_fitted = mean(fitted(ft)),
    mean_bridge_resid = mean(residuals(fj)), mean_tmb_resid = mean(residuals(ft)),
    bridge_coef_vs_tmb = max(abs(unlist(fj$coefficients) - unlist(ft$coefficients))))
  logf("D3 %s: bridge fitted == exp(eta) to %.3g; TMB fitted == documented mean to %.3g; bridge vs TMB fitted max %.4g, residuals max %.4g; mean y %.4f, bridge fitted %.4f, TMB fitted %.4f",
    fam, OUT$D3[[fam]]$bridge_fitted_vs_exp_eta, OUT$D3[[fam]]$tmb_fitted_vs_documented_mean,
    OUT$D3[[fam]]$bridge_vs_tmb_fitted_maxabs, OUT$D3[[fam]]$bridge_vs_tmb_residuals_maxabs,
    OUT$D3[[fam]]$mean_y, OUT$D3[[fam]]$mean_bridge_fitted, OUT$D3[[fam]]$mean_tmb_fitted)
}

# ---- D4 native DRModels predict_parameters(:response) on the response-semantic gaps --------
OUT$D4 <- list()
for (fam in c("student", "skew_normal", "zero_one_beta", "lognormal")) {
  dd <- t6_read_cell(sprintf("%s_fixed.csv", fam), fam, "character")
  put_nt("t6_nt4", dd, c("y", "x", "f"))
  others <- t6_other_dpars(fam)
  forms <- c("@formula(y ~ x + f)", vapply(names(others), function(nm) sprintf("@formula(%s ~ %s)", nm, deparse(others[[nm]][[2]])), ""))
  jl(sprintf("begin global t6_f4 = drm(bf(%s), %s; data = t6_nt4); nothing end", paste(forms, collapse = ", "),
    c(student = "Student()", skew_normal = "SkewNormal()", zero_one_beta = "ZeroOneBeta()", lognormal = "LogNormal()")[[fam]]))
  dp <- if (fam %in% c("student", "skew_normal")) "nu" else "mu"
  e <- jl_vec(sprintf("predict_parameters(t6_f4, t6_nd; type = :link)[:%s]", dp))
  r <- jl_vec(sprintf("predict_parameters(t6_f4, t6_nd; type = :response)[:%s]", dp))
  stored <- if (dp == "nu") jl_vec("t6_f4.scales[:nu]")[1] else NA
  OUT$D4[[fam]] <- list(dpar = dp, eta1 = e[1], response1 = r[1],
    response_minus_eta = max(abs(r - e)), response_minus_exp_eta = max(abs(r - exp(e))),
    response_minus_2_plus_exp_eta = max(abs(r - (2 + exp(e)))), response_minus_plogis_eta = max(abs(r - plogis(e))),
    stored_fit_scale_row1 = stored)
  logf("D4 %s %s: eta[1]=%.6f native response[1]=%.6f; |r-eta|=%.3g |r-exp|=%.3g |r-(2+exp)|=%.3g |r-plogis|=%.3g; fit.scales[:nu][1]=%s",
    fam, dp, e[1], r[1], OUT$D4[[fam]]$response_minus_eta, OUT$D4[[fam]]$response_minus_exp_eta,
    OUT$D4[[fam]]$response_minus_2_plus_exp_eta, OUT$D4[[fam]]$response_minus_plogis_eta, format(stored))
}

# ---- D5 simulate on a bridge fit: methods and what dispatch does ---------------------
fjg <- drmTMB(t6_formula("gaussian", "fixed")$bf, family = gaussian(),
  data = t6_read_cell("gaussian_fixed.csv", "gaussian", "character"), engine = "julia")
OUT$D5 <- list(methods = format(methods(class = "drmTMB_julia")),
  simulate = et(safe(simulate(fjg, nsim = 10, seed = 1))),
  simulate_with_drmTMB_class_appended = {
    o <- fjg; class(o) <- c(class(o), "drmTMB")
    et(safe(simulate(o, nsim = 10, seed = 1)))
  })
logf("D5 methods(class='drmTMB_julia'): %s", paste(OUT$D5$methods, collapse = " "))
logf("D5 simulate(bridge fit): %s", OUT$D5$simulate)
logf("D5 simulate after appending class 'drmTMB' (diagnostic only): %s", OUT$D5$simulate_with_drmTMB_class_appended)

writeLines(jsonlite::toJSON(OUT, auto_unbox = TRUE, pretty = TRUE, digits = NA, null = "null", na = "null"),
  file.path(T6_RES, "bridge_diag.json"))
logf("done")
