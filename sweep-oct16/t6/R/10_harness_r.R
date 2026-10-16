# t6 (sweep-oct16): R harness for SPEC tests P1-P8 on the drmTMB native TMB
# engine (engine = "tmb", the default), all 28 cells.
#
# Run (from anywhere):
#   Rscript /home/user/drmTMB/sweep-oct16/t6/R/10_harness_r.R \
#     > /home/user/drmTMB/sweep-oct16/t6/logs/harness_r.log 2>&1
# Optional args: cell keys to restrict the run, e.g. gaussian_ri poisson_fixed.
#
# Outputs (results/): r_<family>_<re>.json, r_<family>_<re>_pred.csv,
# r_summary.csv. Expected values are computed independently in lib_t6.R.

options(warn = 1, width = 200)
suppressPackageStartupMessages({
  library(drmTMB)
  library(jsonlite)
})
source("/home/user/drmTMB/sweep-oct16/t6/R/lib_t6.R")

TOL1 <- 1e-10   # P1-P5 exact-algebra tolerance (mixed abs/rel, see maxmix)
TOLQ <- 1e-8    # P6/P7 tolerance
TOLREL <- 1e-6  # P5 releveled-fit tolerance (relative)
NSIM <- 1000L
PROBS <- c(0.025, 0.5, 0.975)

logf <- function(fmt, ...) {
  cat(format(Sys.time(), "%H:%M:%S"), sprintf(fmt, ...), "\n")
  flush(stdout())
}

cells <- utils::read.csv(file.path(T6_DATA, "cells.csv"), stringsAsFactors = FALSE,
  colClasses = c(seed = "character", seed_r = "character"))
args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0L) cells <- cells[paste(cells$family, cells$re, sep = "_") %in% args, ]

nd_main <- utils::read.csv(file.path(T6_DATA, "nd_main.csv"), stringsAsFactors = FALSE)
nd_subset <- utils::read.csv(file.path(T6_DATA, "nd_subset.csv"), stringsAsFactors = FALSE)
nd_unseen <- utils::read.csv(file.path(T6_DATA, "nd_unseen_f.csv"), stringsAsFactors = FALSE)
idx_b <- which(nd_main$f == "b")   # nd_subset rows, in the same order

logf("drmTMB %s; R %s; pin %s", as.character(utils::packageVersion("drmTMB")),
  R.version.string, "ca3ddefa5ea11bbfd3b765615dfbb89305d2485a")
logf("cells: %d", nrow(cells))

# capture re.form one-time message text for the record
REFORM_MSG <- NULL

safe <- function(expr) tryCatch(expr, error = function(e) e)

# =============================================================================
run_cell <- function(cr) {
  fam <- cr$family; re <- cr$re
  key <- paste(fam, re, sep = "_")
  seed_r <- as.numeric(cr$seed_r)
  is_ri <- re == "ri"
  links <- T6_LINKS[[fam]]
  out <- list(family = fam, re = re, engine = "r_tmb", cell_k = cr$k,
    seed = cr$seed, seed_r = cr$seed_r, sim_seed_r = seed_r + 100,
    formula = NA, family_call = t6_family_text(fam), fallback = "",
    fit_ok = FALSE, fit_error = "", converged = NA, loglik = NA, coef = list(),
    tests = list())
  pred_rows <- list()
  t_start <- Sys.time()

  # ---- fit -------------------------------------------------------------------
  d <- t6_read_cell(cr$file, fam, "character")
  spec <- t6_formula(fam, re)
  out$formula <- spec$text
  fit <- safe(drmTMB(spec$bf, family = t6_family_object(fam), data = d))
  if (inherits(fit, "error")) {
    out$fit_error <- t6_err(fit)
    logf("[%s] FIT ERROR: %s", key, out$fit_error)
    spec2 <- t6_formula(fam, re, sigma_const = TRUE)
    fit <- safe(drmTMB(spec2$bf, family = t6_family_object(fam), data = d))
    out$fallback <- "sigma ~ 1"
    out$formula <- spec2$text
    if (inherits(fit, "error")) {
      out$fit_error <- paste(out$fit_error, "|| fallback:", t6_err(fit))
      logf("[%s] FALLBACK FIT ERROR: %s", key, t6_err(fit))
      for (p in paste0("P", 1:11)) out$tests[[p]] <- t6_test("ERROR", notes = "fit failed")
      return(list(json = out, pred = NULL))
    }
  }
  out$fit_ok <- TRUE
  dpars <- names(fit$coefficients)
  out$converged <- isTRUE(fit$opt$convergence == 0)
  out$loglik <- as.numeric(logLik(fit))
  out$convergence <- list(
    opt_convergence = fit$opt$convergence, opt_message = fit$opt$message,
    gradient_max_component = fit$gradient_max_component,
    pdHess = fit$sdreport$pdHess, optimizer_used = fit$optimizer_used,
    df = attr(logLik(fit), "df"), nobs = fit$nobs)
  out$coef <- lapply(fit$coefficients, function(b) list(names = names(b), values = unname(b)))
  V_all <- safe(vcov(fit))
  out$vcov <- if (inherits(V_all, "error")) t6_err(V_all) else lapply(dpars, function(dp) {
    lab <- paste0(dp, ":", names(fit$coefficients[[dp]]))
    list(names = lab, matrix = unname(V_all[lab, lab, drop = FALSE]))
  })
  if (!inherits(V_all, "error")) names(out$vcov) <- dpars
  if (fam == "cumulative_logit") {
    out$cutpoints <- list(names = names(fit$ordinal$cutpoints),
      values = unname(fit$ordinal$cutpoints), levels = fit$ordinal$levels)
  }
  sd_g <- NA_real_
  if (is_ri) {
    sd_g <- unname(fit$sdpars$mu[["(1 | g)"]])
    bv <- fit$random_effects$mu$values
    out$ranef <- list(sd_g = sd_g, groups = sub("^\\(1 \\| g\\):", "", names(bv)),
      bhat = unname(bv))
  }
  logf("[%s] fit ok: conv=%s ll=%.6f dpars=%s sd_g=%s (%.1fs)", key, out$converged,
    out$loglik, paste(dpars, collapse = ","), format(sd_g),
    as.numeric(Sys.time() - t_start, units = "secs"))

  # ---- reference (independent) in-sample quantities -------------------------
  eta_pop <- list(); eta_cond <- list(); resp_cond <- list(); resp_pop <- list()
  bh <- if (is_ri) t6_bhat_rows(fit, d) else rep(0, nrow(d))
  for (dp in dpars) {
    eta_pop[[dp]] <- t6_eta(fit, fam, dp, d)
    eta_cond[[dp]] <- eta_pop[[dp]] + if (dp == "mu") bh else 0
    resp_cond[[dp]] <- t6_invlink(links[[dp]], eta_cond[[dp]])
    resp_pop[[dp]] <- t6_invlink(links[[dp]], eta_pop[[dp]])
  }
  trials_in <- if (fam %in% c("binomial", "beta_binomial")) d$successes + d$failures else NULL
  cutpoints <- if (fam == "cumulative_logit") unname(fit$ordinal$cutpoints) else NULL
  par_other <- c(resp_cond[setdiff(dpars, "mu")], list(trials = trials_in, cutpoints = cutpoints))

  # ===========================================================================
  # P1 in-sample predict
  out$tests$P1 <- tryCatch({
    det <- list(); worst <- 0
    for (dp in dpars) {
      pl <- predict(fit, dpar = dp, type = "link")
      pr <- predict(fit, dpar = dp, type = "response")
      pdflt <- predict(fit, dpar = dp)
      a <- maxmix(pl, eta_cond[[dp]])
      b <- maxmix(pr, t6_invlink(links[[dp]], pl))
      cc <- maxmix(pr, resp_cond[[dp]])
      e <- maxmix(pdflt, pr)
      cl <- if (dp == "sigma") t6_softclamp(eta_pop[[dp]], fit)$n_bent else NA
      det[[dp]] <- list(link_vs_Xb_plus_Zb = a, response_vs_invlink_of_engine_link = b,
        response_vs_hand = cc, default_type_vs_response = e, n_sigma_rows_clamped = cl,
        includes_bhat = (dp == "mu" && is_ri), link = links[[dp]])
      worst <- max(worst, a, b, cc, e)
    }
    fv <- fitted(fit)
    if (fam %in% c("binomial", "beta_binomial")) {
      doc_mean <- resp_cond$mu
      doc_txt <- "mu (success probability; ?fitted.drmTMB documents this for beta_binomial, binomial undocumented)"
    } else {
      doc_mean <- t6_cond_moments(fam, eta_cond$mu, par_other)$E
      doc_txt <- "documented response mean at conditional (b-hat) parameters"
    }
    df_ <- maxmix(fv, doc_mean)
    det$fitted <- list(max_mixdiff = df_, documented = doc_txt, length = length(fv),
      class = class(fv))
    worst <- max(worst, df_)
    if (is_ri) {
      det$mu_link_vs_population_Xb_only <- maxabs(predict(fit, dpar = "mu", type = "link"), eta_pop$mu)
    }
    t6_test(t6_status(worst <= TOL1), "max mixed abs/rel diff", worst,
      sprintf("link vs hand X beta%s; response vs documented invlink; fitted vs documented mean",
        if (is_ri) " + b-hat[g] (mu)" else ""), det)
  }, error = function(e) t6_test("ERROR", notes = t6_err(e)))
  logf("[%s] P1 %s value=%s", key, out$tests$P1$status, format(out$tests$P1$value))

  # ===========================================================================
  # P2 newdata with unseen group levels (nd_main) + g column removed
  pp_link <- safe(predict_parameters(fit, newdata = nd_main, type = "link", conf.int = TRUE,
    include_newdata = FALSE))
  pp_resp <- safe(predict_parameters(fit, newdata = nd_main, type = "response", conf.int = TRUE,
    include_newdata = FALSE))
  nd_pred <- list()
  out$tests$P2 <- tryCatch({
    det <- list(); worst <- 0; errs <- character()
    nd_nog <- nd_main[, setdiff(names(nd_main), "g")]
    for (dp in dpars) {
      pl <- safe(predict(fit, newdata = nd_main, dpar = dp, type = "link"))
      pr <- safe(predict(fit, newdata = nd_main, dpar = dp, type = "response"))
      if (inherits(pl, "error") || inherits(pr, "error")) {
        errs <- c(errs, sprintf("%s: %s", dp, t6_err(if (inherits(pl, "error")) pl else pr)))
        next
      }
      nd_pred[[dp]] <- list(link = pl, response = pr)
      eta_nd <- t6_eta(fit, fam, dp, nd_main)
      a <- maxmix(pl, eta_nd)
      b <- maxmix(pr, t6_invlink(links[[dp]], eta_nd))
      s1 <- maxabs(pl[1:9], pl[10:18]); s2 <- maxabs(pr[1:9], pr[10:18])
      plg <- safe(predict(fit, newdata = nd_nog, dpar = dp, type = "link"))
      prg <- safe(predict(fit, newdata = nd_nog, dpar = dp, type = "response"))
      g_rm <- if (inherits(plg, "error")) paste("ERROR:", t6_err(plg)) else max(maxabs(plg, pl), maxabs(prg, pr))
      det[[dp]] <- list(link_vs_pop_Xb = a, response_vs_invlink_pop = b,
        seen_vs_unseen_g_link = s1, seen_vs_unseen_g_response = s2,
        g_removed_vs_with_g = g_rm)
      worst <- max(worst, a, b, s1, s2, if (is.numeric(g_rm)) g_rm else Inf)
    }
    if (length(errs)) {
      t6_test("FAIL", "error", NA, paste("predict(newdata = nd_main) errored:", paste(errs, collapse = "; ")), det)
    } else {
      t6_test(t6_status(worst <= TOL1), "max mixed abs/rel diff", worst,
        "nd_main (g01 seen, gNEW unseen) vs population X_new beta; seen==unseen rows; g column removed", det)
    }
  }, error = function(e) t6_test("ERROR", notes = t6_err(e)))
  logf("[%s] P2 %s value=%s", key, out$tests$P2$status, format(out$tests$P2$value))

  # pred CSV rows: nd_main link/response with predict_parameters SE
  for (dp in names(nd_pred)) {
    for (ty in c("link", "response")) {
      ppx <- if (ty == "link") pp_link else pp_resp
      se <- if (inherits(ppx, "error")) rep(NA_real_, 18) else ppx$std.error[ppx$dpar == dp]
      pred_rows[[length(pred_rows) + 1L]] <- data.frame(row = 1:18, dpar = dp, type = ty,
        value = nd_pred[[dp]][[ty]], se = se, stringsAsFactors = FALSE)
    }
  }

  # ===========================================================================
  # P3 level subset (nd_subset, f = b only) in three encodings
  out$tests$P3 <- tryCatch({
    det <- list(); worst <- 0; refused <- character(); silent_bad <- FALSE
    for (enc in c("character", "factor_b", "factor_abc")) {
      nds <- nd_subset; nds$f <- t6_f_convert(nds$f, enc)
      for (dp in dpars) {
        for (ty in c("link", "response")) {
          v <- safe(predict(fit, newdata = nds, dpar = dp, type = ty))
          lab <- paste(enc, dp, ty, sep = ":")
          if (inherits(v, "error")) {
            refused <- c(refused, paste(lab, t6_err(v)))
            det[[lab]] <- paste("REFUSED:", t6_err(v))
            next
          }
          ref <- nd_pred[[dp]][[ty]][idx_b]
          dd <- maxmix(v, ref)
          det[[lab]] <- dd
          worst <- max(worst, dd)
          if (dd > TOL1) silent_bad <- TRUE
        }
      }
    }
    st <- if (silent_bad) "FAIL" else "PASS"
    t6_test(st, "max mixed diff vs nd_main f=b rows", worst,
      paste0("encodings: character, factor(levels='b'), factor(levels=a,b,c)",
        if (length(refused)) paste0("; refusals: ", length(refused)) else "; no refusals"), det)
  }, error = function(e) t6_test("ERROR", notes = t6_err(e)))
  logf("[%s] P3 %s value=%s", key, out$tests$P3$status, format(out$tests$P3$value))

  # ===========================================================================
  # P4 unseen fixed-effect level (f = "d")
  out$tests$P4 <- tryCatch({
    det <- list()
    for (dp in dpars) {
      v <- safe(predict(fit, newdata = nd_unseen, dpar = dp, type = "response"))
      det[[dp]] <- if (inherits(v, "error")) paste("REFUSED:", t6_err(v)) else
        list(values = as.numeric(v), note = "returned values (f not in this dpar's formula?)")
    }
    vq <- safe(predict(fit, newdata = nd_unseen, type = "quantile", prob = 0.5))
    det$quantile <- if (inherits(vq, "error")) paste("REFUSED:", t6_err(vq)) else list(values = as.numeric(vq))
    vpp <- safe(predict_parameters(fit, newdata = nd_unseen))
    det$predict_parameters <- if (inherits(vpp, "error")) paste("REFUSED:", t6_err(vpp)) else list(values = vpp$estimate)
    mu_msg <- det$mu
    mu_refused <- is.character(mu_msg) && startsWith(mu_msg, "REFUSED")
    names_it <- mu_refused && grepl("\\bf\\b|`f`", mu_msg) && grepl("\"d\"|'d'|\\bd\\b", mu_msg)
    others_ok <- is.character(det$quantile) && is.character(det$predict_parameters)
    st <- if (!mu_refused) "FAIL" else if (names_it && others_ok) "PASS" else "FAIL"
    t6_test(st, "mu refusal names factor/level", as.numeric(names_it),
      if (mu_refused) paste("mu message:", sub("^REFUSED: ", "", mu_msg)) else "mu returned a silent numeric answer", det)
  }, error = function(e) t6_test("ERROR", notes = t6_err(e)))
  logf("[%s] P4 %s", key, out$tests$P4$status)

  # ===========================================================================
  # P5 character vs factor predictors
  out$tests$P5 <- tryCatch({
    det <- list(); fails <- character()
    d_fac <- t6_read_cell(cr$file, fam, "factor")
    d_rel <- t6_read_cell(cr$file, fam, "relevel")
    fit_fac <- drmTMB(spec$bf, family = t6_family_object(fam), data = d_fac)
    fit_rel <- drmTMB(spec$bf, family = t6_family_object(fam), data = d_rel)
    if (out$fallback != "") {
      fit_fac <- drmTMB(t6_formula(fam, re, TRUE)$bf, family = t6_family_object(fam), data = d_fac)
      fit_rel <- drmTMB(t6_formula(fam, re, TRUE)$bf, family = t6_family_object(fam), data = d_rel)
    }
    # coefficients char vs factor
    nm_same <- identical(lapply(fit$coefficients, names), lapply(fit_fac$coefficients, names))
    cdiff <- max(unlist(Map(function(a, b) maxabs(a, b), fit$coefficients, fit_fac$coefficients)))
    det$coef_char_vs_factor <- list(names_identical = nm_same, max_abs = cdiff)
    if (!nm_same || cdiff > TOL1) fails <- c(fails, "coef char vs factor")
    if (fam == "cumulative_logit") {
      det$cutpoints_char_vs_factor <- maxabs(fit$ordinal$cutpoints, fit_fac$ordinal$cutpoints)
    }
    det$rel_coef_names <- lapply(fit_rel$coefficients, names)
    det$loglik <- list(char = as.numeric(logLik(fit)), factor = as.numeric(logLik(fit_fac)),
      relevel = as.numeric(logLik(fit_rel)))
    det$loglik_relevel_minus_char <- as.numeric(logLik(fit_rel)) - as.numeric(logLik(fit))
    if (is_ri) det$sd_g <- list(char = sd_g, factor = unname(fit_fac$sdpars$mu[[1]]),
      relevel = unname(fit_rel$sdpars$mu[[1]]))
    # hand design with releveled reference reproduces fit_rel predictions
    nd_fac <- nd_main; nd_fac$f <- factor(nd_fac$f)
    nd_rel <- nd_main; nd_rel$f <- factor(nd_rel$f, levels = c("c", "a", "b"))
    # rel = TRUE: releveled (reparameterised) fit, judged on the mixed
    # abs/rel scale (pure relative error is unstable for link values near 0);
    # the pure relative difference is reported alongside.
    cmp <- function(a, b, tol, rel = FALSE) {
      v <- maxmix(a, b)
      if (rel) list(diff = v, rel = maxrel(a, b), ok = v <= tol) else list(diff = v, ok = v <= tol)
    }
    score_from <- function(f_, pl) t6_cond_moments("cumulative_logit", pl,
      list(cutpoints = unname(f_$ordinal$cutpoints)))$E
    for (dp in dpars) {
      for (ty in c("link", "response")) {
        base <- nd_pred[[dp]][[ty]]
        p_fac_chr <- predict(fit_fac, newdata = nd_main, dpar = dp, type = ty)
        p_chr_fac <- predict(fit, newdata = nd_fac, dpar = dp, type = ty)
        p_chr_rel <- predict(fit, newdata = nd_rel, dpar = dp, type = ty)
        p_fac_rel <- predict(fit_fac, newdata = nd_rel, dpar = dp, type = ty)
        p_rel_chr <- predict(fit_rel, newdata = nd_main, dpar = dp, type = ty)
        p_rel_fac <- predict(fit_rel, newdata = nd_fac, dpar = dp, type = ty)
        r <- list(
          factorfit_chrnd = cmp(p_fac_chr, base, TOL1),
          charfit_factornd = cmp(p_chr_fac, base, TOL1),
          charfit_relevelnd = cmp(p_chr_rel, base, TOL1),
          factorfit_relevelnd = cmp(p_fac_rel, base, TOL1),
          relevelfit_factornd_vs_relevelfit_chrnd = cmp(p_rel_fac, p_rel_chr, TOL1))
        if (fam == "cumulative_logit" && dp == "mu") {
          # location is identified only relative to the cutpoints: compare
          # expected scores (category probabilities), and report the shift.
          r$relevelfit_vs_char_expected_score <- cmp(score_from(fit_rel, p_rel_chr),
            score_from(fit, base), TOLREL, rel = TRUE)
          r$relevelfit_link_shift_range <- diff(range(p_rel_chr - base))
        } else {
          r$relevelfit_vs_char <- cmp(p_rel_chr, base, TOLREL, rel = TRUE)
        }
        if (ty == "link") {
          hand <- t6_eta(fit_rel, fam, dp, nd_main, levs = c("c", "a", "b"))
          r$relevelfit_vs_hand_design <- cmp(p_rel_chr, hand, TOL1)
        }
        for (nm in names(r)) if (is.list(r[[nm]]) && !isTRUE(r[[nm]]$ok)) fails <- c(fails, paste(dp, ty, nm))
        det[[paste(dp, ty, sep = ":")]] <- r
      }
    }
    t6_test(if (length(fails)) "FAIL" else "PASS", "n failing comparisons", length(fails),
      if (length(fails)) paste("failing:", paste(fails, collapse = "; ")) else
        "char==factor coefs (1e-10); cross-type newdata exact; releveled fit 1e-6 rel", det)
  }, error = function(e) t6_test("ERROR", notes = t6_err(e)))
  logf("[%s] P5 %s value=%s %s", key, out$tests$P5$status, format(out$tests$P5$value),
    substr(out$tests$P5$notes, 1, 200))

  # ===========================================================================
  # P6 quantile predictions
  out$tests$P6 <- tryCatch({
    det <- list()
    qin <- safe(predict(fit, type = "quantile", prob = PROBS))
    qnd <- safe(predict(fit, newdata = nd_main, type = "quantile", prob = PROBS))
    if (inherits(qin, "error") || inherits(qnd, "error")) {
      msg <- t6_err(if (inherits(qin, "error")) qin else qnd)
      if (fam == "tweedie" && !requireNamespace("tweedie", quietly = TRUE)) {
        t6_test("NA", notes = paste("harness environment: Suggests package 'tweedie' not installed",
          "(CRAN unreachable); drmTMB refuses with:", msg))
      } else {
        t6_test("FAIL", "error", NA, paste("predict(type = 'quantile') errored:", msg))
      }
    } else {
      det$shape <- list(class = class(qin), dim = dim(qin), colnames = colnames(qin),
        calibrated = attr(qin, "calibrated"))
      par_c <- c(list(mu = resp_cond$mu, eta_mu = eta_cond$mu), par_other)
      par_p <- c(list(mu = resp_pop$mu, eta_mu = eta_pop$mu), par_other)
      nd_par <- list(mu = nd_pred$mu$response, eta_mu = nd_pred$mu$link,
        trials = if (fam %in% c("binomial", "beta_binomial")) nd_main$trials else NULL,
        cutpoints = cutpoints)
      for (dp in setdiff(dpars, "mu")) nd_par[[dp]] <- nd_pred[[dp]]$response
      worst <- 0; worst_pop <- 0
      for (j in seq_along(PROBS)) {
        p <- PROBS[j]
        ec <- t6_quantile(fam, p, par_c)
        en <- t6_quantile(fam, p, nd_par)
        a <- maxabs(qin[, j], ec); b <- maxabs(qnd[, j], en)
        det[[sprintf("p%.3f", p)]] <- list(insample_vs_predicted_params = a, newdata_vs_predicted_params = b)
        worst <- max(worst, a, b)
        if (is_ri) {
          ep <- t6_quantile(fam, p, par_p)
          det[[sprintf("p%.3f", p)]]$insample_vs_population_params = maxabs(qin[, j], ep)
          worst_pop <- max(worst_pop, maxabs(qin[, j], ep))
        }
        if (fam == "skew_normal") {
          nat <- t6_sn_native(resp_cond$mu, resp_cond$sigma, resp_cond$nu)
          Fq <- vapply(seq_along(nat$xi), function(i) t6_psn(qin[i, j], nat$xi[i], nat$omega[i], nat$alpha[i]), 0)
          det[[sprintf("p%.3f", p)]]$insample_cdf_error_at_engine_quantile <- max(abs(Fq - p))
        }
      }
      # tryCatch evaluates this block in run_cell's frame, so this appends there
      for (j in seq_along(PROBS)) {
        pred_rows[[length(pred_rows) + 1L]] <- data.frame(row = 1:18, dpar = "y",
          type = sprintf("quantile_%s", format(PROBS[j])),
          value = as.numeric(qnd[, j]), se = NA_real_, stringsAsFactors = FALSE)
      }
      note <- "in-sample vs family q-function at predict() in-sample parameters; nd_main vs q at population parameters"
      if (is_ri) {
        note <- paste0(note, sprintf("; ri in-sample max diff vs POPULATION-level params = %.3g (docs say fixed-effect population-level)", worst_pop))
      }
      t6_test(t6_status(worst <= TOLQ), "max abs diff", worst, note, det)
    }
  }, error = function(e) t6_test("ERROR", notes = t6_err(e)))
  logf("[%s] P6 %s value=%s", key, out$tests$P6$status, format(out$tests$P6$value))

  # ===========================================================================
  # P7 standard errors
  out$tests$P7 <- tryCatch({
    det <- list()
    fm <- names(formals(getS3method("predict", "drmTMB")))
    det$predict_formals <- fm
    det$se_fit_formal <- "se.fit" %in% fm
    r_se <- safe(predict(fit, se.fit = TRUE))
    det$predict_se_fit_TRUE <- if (inherits(r_se, "error")) paste("ERROR:", t6_err(r_se)) else
      list(class = class(r_se), is_list = is.list(r_se), length = length(r_se),
        identical_to_plain_predict = identical(r_se, predict(fit)))
    r_int <- safe(predict(fit, newdata = nd_main, interval = "confidence", level = 0.9))
    det$predict_interval_confidence <- if (inherits(r_int, "error")) paste("ERROR:", t6_err(r_int)) else
      list(class = class(r_int), identical_to_plain = identical(r_int, predict(fit, newdata = nd_main)))
    det$predict_parameters_formals <- names(formals(getS3method("predict_parameters", "drmTMB")))
    r_pp_se <- safe(predict_parameters(fit, se.fit = TRUE))
    det$predict_parameters_se_fit <- if (inherits(r_pp_se, "error")) paste("REFUSED:", t6_err(r_pp_se)) else "accepted"
    pp_in <- safe(predict_parameters(fit, conf.int = TRUE))
    det$predict_parameters_insample_conf_status <- if (inherits(pp_in, "error")) t6_err(pp_in) else
      as.list(table(pp_in$conf.status))
    # delta-method validation of predict_parameters(conf.int = TRUE) on nd_main
    z <- stats::qnorm(0.975)
    worst_se <- 0; worst_ci <- 0; worst_est <- 0
    if (inherits(pp_link, "error") || inherits(pp_resp, "error")) {
      det$pp_error <- t6_err(if (inherits(pp_link, "error")) pp_link else pp_resp)
      worst_se <- Inf
    } else {
      for (dp in dpars) {
        X <- t6_X(fit, fam, dp, nd_main)
        lab <- paste0(dp, ":", colnames(X))
        Vd <- V_all[lab, lab, drop = FALSE]
        eta <- as.vector(X %*% fit$coefficients[[dp]])
        se_l <- sqrt(rowSums((X %*% Vd) * X))
        se_r <- abs(t6_dinvlink(links[[dp]], eta)) * se_l
        el <- pp_link[pp_link$dpar == dp, ]; er <- pp_resp[pp_resp$dpar == dp, ]
        a <- maxrel(el$std.error, se_l); b <- maxrel(er$std.error, se_r)
        c1 <- max(maxmix(el$conf.low, eta - z * se_l), maxmix(el$conf.high, eta + z * se_l))
        c2 <- max(maxmix(er$conf.low, t6_invlink(links[[dp]], eta - z * se_l)),
          maxmix(er$conf.high, t6_invlink(links[[dp]], eta + z * se_l)))
        e1 <- max(maxmix(el$estimate, nd_pred[[dp]]$link), maxmix(er$estimate, nd_pred[[dp]]$response))
        det[[paste0("pp_", dp)]] <- list(se_link_rel = a, se_response_rel = b, ci_link = c1,
          ci_response = c2, estimate_vs_predict = e1, status = unique(c(el$conf.status, er$conf.status)))
        worst_se <- max(worst_se, a, b); worst_ci <- max(worst_ci, c1, c2); worst_est <- max(worst_est, e1)
      }
    }
    # emmeans (mu only)
    em_note <- ""
    if (requireNamespace("emmeans", quietly = TRUE)) {
      em <- safe(summary(emmeans::emmeans(fit, ~ f | x, at = list(x = c(-1, 0, 1.5)))))
      if (inherits(em, "error")) {
        det$emmeans <- paste("REFUSED:", t6_err(em)); em_note <- "emmeans refused"
      } else {
        emd <- data.frame(x = as.numeric(as.character(em$x)), f = as.character(em$f), g = "g01",
          trials = 10L, stringsAsFactors = FALSE)
        X <- t6_X(fit, fam, "mu", emd)
        lab <- paste0("mu:", colnames(X))
        se_l <- sqrt(rowSums((X %*% V_all[lab, lab, drop = FALSE]) * X))
        est <- as.vector(X %*% fit$coefficients$mu)
        a <- maxrel(em$SE, se_l); b <- maxmix(em$emmean, est)
        emr <- safe(summary(emmeans::emmeans(fit, ~ f | x, at = list(x = c(-1, 0, 1.5)), type = "response")))
        rr <- if (inherits(emr, "error")) paste("ERROR:", t6_err(emr)) else {
          rc <- intersect(c("response", "rate", "prob", "emmean"), names(emr))[1]
          se_r <- abs(t6_dinvlink(links[["mu"]], est)) * se_l
          list(se_response_rel = maxrel(emr$SE, se_r),
            est_response = maxmix(emr[[rc]], t6_invlink(links[["mu"]], est)), column = rc)
        }
        det$emmeans <- list(se_link_rel = a, est_link = b, response = rr)
        worst_se <- max(worst_se, a, if (is.list(rr)) rr$se_response_rel else 0)
        em_note <- "emmeans SE validated"
      }
    }
    det$worst_ci <- worst_ci; det$worst_estimate <- worst_est
    ok <- worst_se <= TOLQ && worst_ci <= TOLQ && worst_est <= TOL1
    t6_test(t6_status(ok), "max rel SE diff vs delta method", worst_se,
      paste0("predict() has no se.fit formal; se.fit=TRUE ",
        if (is.list(det$predict_se_fit_TRUE) && isTRUE(det$predict_se_fit_TRUE$identical_to_plain_predict))
          "silently ignored (known drmTMB #1536)" else "behaviour recorded",
        "; predict_parameters(conf.int=TRUE) Wald SE vs delta method; ", em_note), det)
  }, error = function(e) t6_test("ERROR", notes = t6_err(e)))
  logf("[%s] P7 %s value=%s %s", key, out$tests$P7$status, format(out$tests$P7$value), out$tests$P7$notes)

  # ===========================================================================
  # P8 simulate moments
  to_matrix <- function(sims) {
    if (fam == "cumulative_logit") {
      lv <- fit$ordinal$levels
      sapply(sims, function(col) match(as.character(col), lv))
    } else {
      as.matrix(sims)
    }
  }
  out$tests$P8 <- tryCatch({
    det <- list(); fails <- character()
    msgs <- character()
    sim_call <- function(...) withCallingHandlers(simulate(fit, ...),
      message = function(m) { msgs <<- c(msgs, t6_err(m)); invokeRestart("muffleMessage") })
    t0 <- Sys.time()
    s1 <- sim_call(nsim = NSIM, seed = seed_r + 100)
    det$elapsed_default_s <- as.numeric(Sys.time() - t0, units = "secs")
    det$shape <- list(class = class(s1), dim = dim(s1), names_head = head(names(s1), 3),
      names_tail = tail(names(s1), 1), col_class = class(s1[[1]]),
      col_levels = if (is.factor(s1[[1]])) levels(s1[[1]]) else NULL)
    Y1 <- to_matrix(s1)
    if (fam %in% c("binomial", "beta_binomial")) {
      det$binomial_scale <- list(max = max(Y1), all_integer = all(Y1 == round(Y1)),
        within_trials = all(Y1 <= trials_in), returns = if (max(Y1) > 1) "counts" else "proportions?")
    }
    s1b <- sim_call(nsim = NSIM, seed = seed_r + 100)
    det$seed_reproduces <- identical(s1, s1b)
    if (!det$seed_reproduces) fails <- c(fails, "seed not reproducible")
    rm(s1b)
    mom_marg <- if (is_ri) t6_marg_moments(fam, eta_pop$mu, par_other, sd_g) else
      t6_cond_moments(fam, eta_cond$mu, par_other)
    mom_cond <- t6_cond_moments(fam, eta_cond$mu, par_other)
    skip_var <- fam == "student" && any(par_other$nu <= 2)
    st1 <- t6_sim_stats(Y1, mom_marg$E, mom_marg$V, d)
    det$default_reNA <- st1
    if (!st1$pass_mean) fails <- c(fails, sprintf("default mean z=%.2f", st1$z_mean))
    if (!st1$pass_var && !skip_var) fails <- c(fails, sprintf("default var z=%.2f", st1$z_var))
    if (is_ri) {
      det$default_reNA$against_conditional_moments <- t6_sim_stats(Y1, mom_cond$E, mom_cond$V, d)[c("z_mean", "z_var", "max_abs_zi")]
      s2 <- sim_call(nsim = NSIM, seed = seed_r + 100, re.form = NULL)
      Y2 <- to_matrix(s2)
      st2 <- t6_sim_stats(Y2, mom_cond$E, mom_cond$V, d)
      st2$against_marginal_moments <- t6_sim_stats(Y2, mom_marg$E, mom_marg$V, d)[c("z_mean", "z_var", "max_abs_zi")]
      det$reNULL_conditional <- st2
      if (!st2$pass_mean) fails <- c(fails, sprintf("re.form=NULL mean z=%.2f", st2$z_mean))
      if (!st2$pass_var && !skip_var) fails <- c(fails, sprintf("re.form=NULL var z=%.2f", st2$z_var))
      s3 <- sim_call(nsim = 3, seed = seed_r + 100, re.form = ~0)
      det$reform_tilde0_equals_NA <- identical(s3, as.data.frame(s1[, 1:3]))
      rm(s2)
    } else {
      s3 <- sim_call(nsim = 5, seed = seed_r + 100, re.form = NULL)
      det$fixed_reNULL_equals_default <- identical(s3, as.data.frame(s1[, 1:5]))
    }
    # RNG state contract
    set.seed(424242); before <- .Random.seed
    invisible(sim_call(nsim = 2, seed = 1))
    det$rng_restored_after_seeded_call <- identical(before, .Random.seed)
    if (exists(".Random.seed", envir = .GlobalEnv)) rm(".Random.seed", envir = .GlobalEnv)
    invisible(sim_call(nsim = 2, seed = 1))
    det$rng_absent_stays_absent <- !exists(".Random.seed", envir = .GlobalEnv)
    set.seed(5); before <- .Random.seed
    invisible(sim_call(nsim = 2))
    det$rng_advances_without_seed <- !identical(before, .Random.seed)
    if (!det$rng_restored_after_seeded_call) fails <- c(fails, "RNG not restored")
    if (!det$rng_absent_stays_absent) fails <- c(fails, "RNG created when absent")
    # known #1536 (one cell only)
    if (key == "gaussian_fixed") {
      sk <- safe(sim_call(nsim = 1, seed = 1, newdata = nd_main))
      det$known_1536_newdata <- if (inherits(sk, "error")) paste("ERROR:", t6_err(sk)) else
        list(nrow_returned = nrow(sk), nrow_newdata = nrow(nd_main),
          identical_to_no_newdata = identical(sk, sim_call(nsim = 1, seed = 1)),
          label = "known: drmTMB #1536 simulate() has no newdata formal; silently returns training rows")
    }
    det$messages <- unique(msgs)
    det$skip_var <- skip_var
    zz <- c(st1$z_mean, st1$z_var, if (is_ri) c(det$reNULL_conditional$z_mean, det$reNULL_conditional$z_var))
    t6_test(if (length(fails)) "FAIL" else "PASS", "max |z| (mean/var, all modes)", max(abs(zz)),
      sprintf("default: zmean=%.2f zvar=%.2f%s", st1$z_mean, st1$z_var,
        if (is_ri) sprintf("; re.form=NULL: zmean=%.2f zvar=%.2f", det$reNULL_conditional$z_mean,
          det$reNULL_conditional$z_var) else ""), det)
  }, error = function(e) t6_test("ERROR", notes = t6_err(e)))
  logf("[%s] P8 %s %s", key, out$tests$P8$status, out$tests$P8$notes)

  for (p in c("P9", "P10", "P11")) {
    out$tests[[p]] <- t6_test("NA", notes = "not in scope of the R-engine harness (cross-engine / bridge tests run separately)")
  }
  out$elapsed_s <- as.numeric(Sys.time() - t_start, units = "secs")
  pred <- if (length(pred_rows)) do.call(rbind, pred_rows) else NULL
  list(json = out, pred = pred)
}

# =============================================================================
summary_rows <- list()
for (i in seq_len(nrow(cells))) {
  cr <- cells[i, ]
  key <- paste(cr$family, cr$re, sep = "_")
  logf("==== cell %s (k=%d, seed_r=%s) ====", key, cr$k, cr$seed_r)
  res <- tryCatch(run_cell(cr), error = function(e) {
    logf("[%s] CELL ERROR: %s", key, t6_err(e))
    list(json = list(family = cr$family, re = cr$re, engine = "r_tmb", fit_ok = FALSE,
      fit_error = paste("harness error:", t6_err(e)), tests = list()), pred = NULL)
  })
  jpath <- file.path(T6_RES, sprintf("r_%s.json", key))
  writeLines(jsonlite::toJSON(res$json, auto_unbox = TRUE, digits = NA, null = "null",
    na = "null", pretty = TRUE, force = TRUE), jpath)
  if (!is.null(res$pred)) {
    utils::write.csv(res$pred, file.path(T6_RES, sprintf("r_%s_pred.csv", key)), row.names = FALSE)
  }
  for (p in names(res$json$tests)) {
    tt <- res$json$tests[[p]]
    summary_rows[[length(summary_rows) + 1L]] <- data.frame(cell = key, family = cr$family,
      re = cr$re, test = p, status = tt$status, metric = as.character(tt$metric),
      value = suppressWarnings(as.numeric(tt$value)), notes = substr(as.character(tt$notes), 1, 400),
      stringsAsFactors = FALSE)
    if (p == "P8" && is.list(tt$details)) {
      for (mode in intersect(c("default_reNA", "reNULL_conditional"), names(tt$details))) {
        s <- tt$details[[mode]]
        for (w in c("mean", "var")) {
          summary_rows[[length(summary_rows) + 1L]] <- data.frame(cell = key, family = cr$family,
            re = cr$re, test = sprintf("P8%s_%s", w, mode),
            status = if (isTRUE(s[[paste0("pass_", w)]])) "PASS" else "FAIL",
            metric = paste0("z_", w), value = s[[paste0("z_", w)]],
            notes = sprintf("max|z_i|=%.2f n|z_i|>3=%d (exp %.2f) reg max|t|=%.2f",
              s$max_abs_zi, s$n_abs_zi_gt3, s$expected_n_gt3, s$reg_max_abs_t_slopes),
            stringsAsFactors = FALSE)
        }
      }
    }
  }
  utils::write.csv(do.call(rbind, summary_rows), file.path(T6_RES, "r_summary.csv"), row.names = FALSE)
}
logf("done")
