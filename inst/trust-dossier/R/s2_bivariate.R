## S2 — bivariate meta-analysis: drmTMB meta_vcov_bivariate vs metafor::rma.mv
## on the canonical two-outcome dataset metadat::dat.berkey1998 (Berkey et al. 1998:
## 5 periodontal trials, each reporting PD and AL with KNOWN within-study sampling
## covariance). This is the standard bivariate meta-analysis worked example.
##
## NOTE (plan correction): the plan named `dat.bcg`, but dat.bcg is the UNIVARIATE
## BCG-vaccine dataset (2x2 tables, one log-RR per trial) — it cannot support a
## bivariate known-V meta-analysis. dat.berkey1998 is the correct bivariate dataset.
##
## Estimand map:
## - metafor rma.mv(yi, V, mods = ~outcome-1, random = ~outcome|trial, struct="UN"):
##   two pooled outcome means + between-study UN 2x2 covariance (tau_AL, tau_PD, rho).
##   metafor orders the outcome factor ALPHABETICALLY (AL, PD) -> tau2[1]=AL, tau2[2]=PD.
## - drmTMB bivariate: mu1 = PD, mu2 = AL; meta_V(V) supplies the row-paired within-
##   study covariance (built by meta_vcov_bivariate); sigma1/sigma2 = between-study SDs;
##   rho12() = between-study correlation (response scale). REML matches metafor's default.

s2_bivariate <- function() {
  dat <- metadat::dat.berkey1998

  ## --- metafor bivariate reference (REML) ---
  ## per-study 2x2 within-study covariance block [[var_PD, cov],[cov, var_AL]]
  V <- metafor::bldiag(lapply(split(dat, dat$trial), function(x) {
    vPD <- x$vi[x$outcome == "PD"]; vAL <- x$vi[x$outcome == "AL"]
    cov <- x$v2i[x$outcome == "PD"]
    matrix(c(vPD, cov, cov, vAL), 2, 2)
  }))
  ref <- metafor::rma.mv(yi, V, mods = ~ outcome - 1,
                         random = ~ outcome | trial, struct = "UN", data = dat)
  mu_PD_ref <- unname(coef(ref)[["outcomePD"]])
  mu_AL_ref <- unname(coef(ref)[["outcomeAL"]])
  ## tau2 ordered (AL, PD) by alphabetical outcome level
  tau_AL_ref <- sqrt(ref$tau2[[1L]]); tau_PD_ref <- sqrt(ref$tau2[[2L]])
  rho_ref <- ref$rho

  ## --- drmTMB bivariate (REML) ---
  w <- reshape(dat[, c("trial", "outcome", "yi", "vi")],
               idvar = "trial", timevar = "outcome", direction = "wide")
  names(w) <- c("trial", "y_PD", "v_PD", "y_AL", "v_AL")
  w$cov12 <- dat$v2i[dat$outcome == "PD"]
  V_drm <- drmTMB::meta_vcov_bivariate(v1 = w$v_PD, v2 = w$v_AL, cov12 = w$cov12)

  fit <- drmTMB::drmTMB(
    drmTMB::bf(mu1 = y_PD ~ 1 + drmTMB::meta_V(V = V_drm), mu2 = y_AL ~ 1,
               sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
    family = c(gaussian(), gaussian()), data = w, REML = TRUE
  )
  mu_PD_d <- unname(coef(fit, "mu1")[[1L]])
  mu_AL_d <- unname(coef(fit, "mu2")[[1L]])
  tau_PD_d <- unname(sigma(fit)[["sigma1"]][[1L]])
  tau_AL_d <- unname(sigma(fit)[["sigma2"]][[1L]])
  rho_d <- unname(drmTMB::rho12(fit)[[1L]])

  out <- data.frame(
    quantity = c("mu PD", "mu AL", "tau PD (between-study SD)",
                 "tau AL (between-study SD)", "rho between-study"),
    metafor  = c(mu_PD_ref, mu_AL_ref, tau_PD_ref, tau_AL_ref, rho_ref),
    drmTMB   = c(mu_PD_d,   mu_AL_d,   tau_PD_d,   tau_AL_d,   rho_d),
    stringsAsFactors = FALSE
  )
  out$abs_diff <- abs(out$drmTMB - out$metafor)
  attr(out, "converged") <- (fit$opt$convergence == 0) && isTRUE(fit$sdr$pdHess)
  attr(out, "dataset") <- "metadat::dat.berkey1998 (5 trials, 2 outcomes PD/AL, known within-study cov)"
  attr(out, "model")   <- "bivariate known-V meta-analysis, UN between-study, REML"
  out
}
