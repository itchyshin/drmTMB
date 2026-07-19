## S1 — multilevel meta-analysis: THREE-WAY comparator parity
##   metafor::rma.mv  ==  glmmTMB (equalto)  ==  drmTMB (meta_V)
## on the three-level meta-analysis dataset metadat::dat.assink2016.
##
## This is the Wolfgang-facing HEADLINE. It reproduces the exact comparison design
## of Williams et al. (arXiv 2604.04084, Wolfgang co-author) — where glmmTMB's
## `equalto` structure is validated by matching metafor — and adds drmTMB as a
## third, numerically-matching column. The part a comparator-minded skeptic cannot argue.
##
## Estimand map (confirmed at S0): metafor `~ 1 | study/esid` gives
##   sigma2[1] = between-study (level 3) ; sigma2[2] = within-study (level 2).
## - glmmTMB: known V via `equalto(0 + obs | g, VCV)` (VCV = diag(vi) from
##   metafor::vcalc, rho = 0); (1|study) = L3; (1|sid) = L2; dispformula = ~0
##   removes the free residual so the three variance sources match rma.mv.
## - drmTMB: meta_V(V = vi) known sampling var; (1|study) = L3; sigma ~ 1 = L2.
## All fit by REML (metafor default; drmTMB/glmmTMB REML = TRUE).

s1_multilevel <- function() {
  d <- metadat::dat.assink2016
  d$g   <- factor(1)
  d$obs <- factor(seq_len(nrow(d)))
  d$sid <- factor(paste(d$study, d$esid, sep = "."))
  VCV <- metafor::vcalc(vi, cluster = study, obs = esid, data = d, rho = 0)

  ## --- metafor reference (REML) ---
  ref <- metafor::rma.mv(yi, vi, random = ~ 1 | study / esid, data = d)
  mu_ref <- unname(coef(ref)); se_ref <- unname(ref$se)
  tau2_ref <- ref$sigma2[[1L]]; sig2_ref <- ref$sigma2[[2L]]

  ## --- glmmTMB (equalto) ---
  g_fit <- glmmTMB::glmmTMB(
    yi ~ 1 + (1 | study) + (1 | sid) + equalto(0 + obs | g, VCV),
    dispformula = ~0, REML = TRUE, data = d
  )
  vc_g <- glmmTMB::VarCorr(g_fit)$cond
  mu_g   <- unname(glmmTMB::fixef(g_fit)$cond[[1L]])
  se_g   <- unname(sqrt(diag(vcov(g_fit)$cond))[[1L]])
  tau2_g <- unname(attr(vc_g$study, "stddev")^2)
  sig2_g <- unname(attr(vc_g$sid, "stddev")^2)

  ## --- drmTMB (meta_V) ---
  drm <- drmTMB::drmTMB(
    drmTMB::bf(yi ~ 1 + (1 | study) + drmTMB::meta_V(V = vi), sigma ~ 1),
    family = gaussian(), data = d, REML = TRUE
  )
  mu_d   <- unname(coef(drm, "mu"))
  se_d   <- unname(sqrt(diag(vcov(drm)))[grepl("^mu:", colnames(vcov(drm)))][[1L]])
  tau2_d <- unname(drm$sdpars$mu[[1L]])^2
  sig2_d <- unname(sigma(drm)[[1L]])^2

  out <- data.frame(
    quantity   = c("mu (intercept)", "tau2_L3 (between-study)", "sig2_L2 (within-study)", "SE(mu)"),
    metafor    = c(mu_ref, tau2_ref, sig2_ref, se_ref),
    glmmTMB    = c(mu_g,   tau2_g,   sig2_g,   se_g),
    drmTMB     = c(mu_d,   tau2_d,   sig2_d,   se_d),
    stringsAsFactors = FALSE
  )
  out$max_abs_diff_vs_metafor <- pmax(
    abs(out$glmmTMB - out$metafor),
    abs(out$drmTMB  - out$metafor)
  )
  attr(out, "converged") <- (drm$opt$convergence == 0) && isTRUE(drm$sdr$pdHess) &&
    (g_fit$fit$convergence == 0)
  attr(out, "dataset") <- "metadat::dat.assink2016 (100 effects, 17 studies)"
  attr(out, "model")   <- "3-level intercept-only, REML"
  out
}
