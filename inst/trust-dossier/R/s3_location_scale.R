## S3 — location-scale meta-analysis: modelling heterogeneity as a function of a
## moderator, and the genuinely-novel random-effect-in-dispersion case.
##
## S3a (comparator-validated): FE location-scale meta-analysis on
##   metadat::dat.bangertdrowns2004 (48 writing-to-learn SMD studies). Model the
##   log heterogeneity SD as a function of `grade`. THREE-WAY parity:
##     metafor  rma(scale = ~grade, link="log")   [models log(tau^2)]
##     glmmTMB  equalto(known V) + dispformula ~ grade   [models log(sigma)]
##     drmTMB   meta_V(V=vi) + sigma ~ grade             [models log(sigma)]
##   Parametrization: metafor alpha = 2 * (drmTMB/glmmTMB log-SD coef), since
##   log(tau^2) = 2*log(sigma). Estimates match to 5dp (compare estimates, not
##   logLik: the REML/location-scale normalization constant differs — see handover).
##
## S3b (novelty, simulation-validated): RANDOM EFFECT IN DISPERSION —
##   sigma ~ 1 + (1 | study) on a multilevel meta-analysis. Neither metafor's `rma`
##   (scale= is fixed-effect only) nor glmmTMB's dispformula (no random effects)
##   can fit this. Validated by simulation-from-truth recovery (one demonstration;
##   the calibrated coverage grid is commissioned to Totoro, like S4). rma's/glmmTMB's
##   inability is context, NOT the trust argument — the trust argument is recovery.

s3_location_scale_fe <- function() {
  d <- metadat::dat.bangertdrowns2004
  d <- d[!is.na(d$yi) & !is.na(d$vi), ]
  d$gradef <- factor(d$grade)
  d$g <- factor(1); d$obs <- factor(seq_len(nrow(d)))
  Vd <- diag(d$vi)

  ## metafor location-scale (models log tau^2)
  mref <- metafor::rma(yi, vi, scale = ~gradef, data = d, link = "log")
  alpha_names <- names(coef(mref)$alpha)
  mu_ref    <- unname(coef(mref)$beta[[1L]])
  alpha_ref <- unname(coef(mref)$alpha)          # log(tau^2) coefs

  ## glmmTMB equalto + dispformula (models log sigma)
  gt <- glmmTMB::glmmTMB(yi ~ 1 + equalto(0 + obs | g, Vd),
                         dispformula = ~gradef, REML = TRUE, data = d)
  mu_g   <- unname(glmmTMB::fixef(gt)$cond[[1L]])
  disp_g <- unname(glmmTMB::fixef(gt)$disp)        # log(sigma) coefs

  ## drmTMB meta_V + sigma ~ grade (models log sigma)
  drm <- drmTMB::drmTMB(drmTMB::bf(yi ~ 1 + drmTMB::meta_V(V = vi), sigma ~ gradef),
                        family = gaussian(), data = d, REML = TRUE)
  mu_d   <- unname(coef(drm, "mu")[[1L]])
  sig_d  <- unname(coef(drm, "sigma"))             # log(sigma) coefs

  ## put all on the log(tau^2) scale for one comparison (metafor scale)
  labs <- c("mu (location intercept)",
            paste0("log(tau^2) ", alpha_names))
  out <- data.frame(
    quantity = labs,
    metafor  = c(mu_ref, alpha_ref),
    glmmTMB  = c(mu_g, 2 * disp_g),
    drmTMB   = c(mu_d, 2 * sig_d),
    stringsAsFactors = FALSE
  )
  out$max_abs_diff_vs_metafor <- pmax(abs(out$glmmTMB - out$metafor),
                                      abs(out$drmTMB  - out$metafor))
  attr(out, "converged") <- (drm$opt$convergence == 0) && isTRUE(drm$sdr$pdHess) &&
    (gt$fit$convergence == 0)
  attr(out, "dataset") <- "metadat::dat.bangertdrowns2004 (48 SMD studies)"
  attr(out, "model")   <- "FE location-scale: log-heterogeneity ~ grade, REML"
  out
}

## S3b — RANDOM EFFECT IN DISPERSION, validated by simulation-from-truth.
## Model: bf(yi ~ 1 + meta_V(V = vi), sigma ~ 1 + (1 | study)) — the between-study
## heterogeneity MAGNITUDE is itself a study-level random effect:
##   log(sigma_j) = alpha0 + u_j, u_j ~ N(0, sd_disp^2); y_ij ~ N(mu, vi_ij + sigma_j^2).
## Neither metafor's rma (scale= is fixed-effect only) nor glmmTMB's dispformula
## (no random effects) can fit this — so the ground truth is simulation, not a
## comparator. This is ONE scenario (K studies x nj effects), reported as bias with
## Monte-Carlo SE. It is a recovery DEMONSTRATION; the calibrated coverage grid over
## a DGP range is commissioned to Totoro (see S4 / D-50), not claimed here.
s3_re_dispersion_recovery <- function(nrep = 30L, K = 40L, nj = 8L,
                                      mu_true = 0.3, alpha0_true = log(0.25),
                                      sd_disp_true = 0.5, base_seed = 20260714L) {
  sim_one <- function(seed) {
    set.seed(seed)
    N <- K * nj
    study <- factor(rep(seq_len(K), each = nj))
    u <- stats::rnorm(K, 0, sd_disp_true)
    sigma_j <- exp(alpha0_true + u)
    vi <- stats::runif(N, 0.01, 0.08)
    yi <- mu_true + stats::rnorm(N, 0, sqrt(vi + sigma_j[study]^2))
    d <- data.frame(study, yi, vi)
    fit <- tryCatch(
      drmTMB::drmTMB(drmTMB::bf(yi ~ 1 + drmTMB::meta_V(V = vi), sigma ~ 1 + (1 | study)),
                     family = gaussian(), data = d, REML = TRUE),
      error = function(e) NULL
    )
    if (is.null(fit) || fit$opt$convergence != 0) return(c(NA, NA, NA))
    c(mu = coef(fit, "mu")[[1L]],
      alpha0 = coef(fit, "sigma")[[1L]],
      sd_disp = unname(fit$sdpars$sigma[[1L]]))
  }
  res <- t(vapply(seq_len(nrep), function(i) sim_one(base_seed + i), numeric(3)))
  res <- res[stats::complete.cases(res), , drop = FALSE]
  truth <- c(mu = mu_true, alpha0 = alpha0_true, sd_disp = sd_disp_true)
  out <- data.frame(
    parameter = colnames(res),
    truth     = truth[colnames(res)],
    mean_est  = colMeans(res),
    bias      = colMeans(res) - truth[colnames(res)],
    mcse      = apply(res, 2, stats::sd) / sqrt(nrow(res)),
    stringsAsFactors = FALSE
  )
  rownames(out) <- NULL
  attr(out, "reps_converged") <- nrow(res)
  attr(out, "reps_requested") <- nrep
  attr(out, "design") <- sprintf("K=%d studies x nj=%d effects; one DGP scenario, REML", K, nj)
  attr(out, "note") <- "recovery demonstration (no comparator exists); calibrated coverage grid -> Totoro"
  out
}
