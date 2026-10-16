## F8a-r-poisson-mle-nonexistent: drmTMB poisson() reports a clean convergence
## on datasets where the Poisson MLE does not exist.
## Run from this directory:  Rscript repro_F8a.R > repro_F8a.out 2>&1
## Data: ../../data/pois_n8_lowmean_rNN.csv (t4 cell k = 15, n = 8,
##   x ~ N(0,1), y ~ Poisson(exp(-1.5 + 0.5 x)); R seed = (20261016400 + 1400 + rep - 1) %% 2^31).
suppressPackageStartupMessages({ library(drmTMB); library(lpSolve) })
options(width = 200)
cat("drmTMB", format(packageVersion("drmTMB")), " lpSolve", format(packageVersion("lpSolve")), "\n")
print(sessionInfo())

ddir <- file.path("..", "..", "data")
reps_zero    <- c(3, 4, 6, 11, 21, 22, 32, 39, 48)   # all y = 0
reps_extreme <- c(25, 27, 33, 38, 47)                 # y > 0 only at the extreme x
reps_ctrl    <- c(1, 2)                               # MLE exists (controls)

## Linear-programming existence check (Santos Silva & Tenreyro 2010, Econ. Lett.
## 107:310-312): for full-rank X the Poisson MLE fails to exist iff some delta != 0
## has X_i delta = 0 for every y_i > 0 and X_i delta <= 0 for every y_i = 0 with at
## least one strict inequality. Maximise sum_{y=0} -(X_i delta) with that sum capped
## at 1; optimum > 0  <=>  MLE does not exist.
pois_mle_nonexistent <- function(X, y) {
  p <- ncol(X); Z <- X[y == 0, , drop = FALSE]; P <- X[y > 0, , drop = FALSE]
  if (!nrow(Z)) return(FALSE)
  A <- function(M) cbind(M, -M)              # delta = d_plus - d_minus, both >= 0
  con <- rbind(A(Z), if (nrow(P)) A(P), -colSums(A(Z)))
  dir <- c(rep("<=", nrow(Z)), rep("=", nrow(P)), "<=")
  rhs <- c(rep(0, nrow(Z)), rep(0, nrow(P)), 1)
  sol <- lp("max", -colSums(A(Z)), con, dir, rhs)
  sol$status == 0 && sol$objval > 1e-8
}

capture <- function(expr) {
  w <- character()
  v <- withCallingHandlers(expr, warning = function(c) { w <<- c(w, conditionMessage(c)); invokeRestart("muffleWarning") })
  list(value = v, warnings = w)
}

one <- function(rep) {
  d <- read.csv(file.path(ddir, sprintf("pois_n8_lowmean_r%02d.csv", rep)))
  X <- cbind(1, d$x)
  cf <- capture(drmTMB(bf(y ~ x), family = poisson(), data = d))
  fit <- cf$value
  se <- sqrt(diag(vcov(fit)))
  chk <- check_drm(fit)
  row <- function(nm) { r <- chk[chk$check == nm, ]; if (nrow(r)) paste0(r$status, " [", r$value, "]") else "<absent>" }
  g <- capture(glm(y ~ x, family = poisson(), data = d))
  gs <- summary(g$value)$coefficients
  data.frame(
    rep = rep, n_pos = sum(d$y > 0), y_pos = paste(d$y[d$y > 0], collapse = ","),
    lp_nonexistent = pois_mle_nonexistent(X, d$y),
    start_b0 = unname(fit$obj$par[1]), start_b1 = unname(fit$obj$par[2]),
    drm_b0 = unname(fit$opt$par[1]), drm_b1 = unname(fit$opt$par[2]),
    drm_se_b0 = unname(se[1]), drm_se_b1 = unname(se[2]),
    drm_logLik = as.numeric(logLik(fit)),
    is_conv = is_converged(fit), is_conv_hess = is_converged(fit, include_hessian = TRUE),
    status = convergence_status(fit), opt_code = fit$opt$convergence,
    opt_iter = fit$opt$iterations, opt_msg = fit$opt$message, pdHess = fit$sdr$pdHess,
    fit_warnings = length(cf$warnings), check_ok = isTRUE(attr(chk, "ok")),
    check_warn = paste(chk$check[chk$status %in% c("warning", "error")], collapse = ";"),
    se_inflated = row("standard_errors_inflated"),
    weakly_id = row("weakly_identified_fixed_effects"),
    hess_cond = row("hessian_conditioning"),
    glm_b0 = unname(coef(g$value)[1]), glm_b1 = unname(coef(g$value)[2]),
    glm_se_b0 = gs[1, 2], glm_se_b1 = gs[2, 2],
    glm_converged = g$value$converged, glm_iter = g$value$iter,
    glm_warnings = paste(unique(g$warnings), collapse = " | "),
    stringsAsFactors = FALSE)
}

res <- do.call(rbind, lapply(c(reps_zero, reps_extreme, reps_ctrl), one))
res$group <- rep(c("all_zero", "extreme_x", "control"), c(length(reps_zero), length(reps_extreme), length(reps_ctrl)))

cat("\n== Existence (LP check) and drmTMB convergence flags ==\n")
print(res[, c("group", "rep", "n_pos", "y_pos", "lp_nonexistent", "is_conv", "is_conv_hess", "status", "opt_code",
              "opt_iter", "opt_msg", "pdHess", "fit_warnings", "check_ok", "check_warn")], row.names = FALSE)
cat("\n== drmTMB estimates vs. its start values (start = drmTMB:::poisson_start(), i.e. glm.fit) ==\n")
print(res[, c("group", "rep", "start_b0", "start_b1", "drm_b0", "drm_b1", "drm_se_b0", "drm_se_b1", "drm_logLik")],
      row.names = FALSE, digits = 10)
cat("\nlog(0.1) - 22 =", format(log(0.1) - 22, digits = 12),
    " (glm.fit IRLS starts at mustart = y + 0.1 and takes unit Newton steps on all-zero data)\n")
cat("\n== check_drm rows that should catch this ==\n")
print(res[, c("group", "rep", "se_inflated", "weakly_id", "hess_cond")], row.names = FALSE)
cat("\n== base R glm() on the same data (default glm.control) ==\n")
print(res[, c("group", "rep", "glm_b0", "glm_b1", "glm_se_b0", "glm_se_b1", "glm_converged", "glm_iter", "glm_warnings")],
      row.names = FALSE, digits = 6)

## Scan the whole cell with the LP check to confirm the 14 nonexistent reps exactly.
all_lp <- sapply(1:50, function(r) { d <- read.csv(file.path(ddir, sprintf("pois_n8_lowmean_r%02d.csv", r)))
  pois_mle_nonexistent(cbind(1, d$x), d$y) })
cat("\nLP-nonexistent reps in the 50-rep cell:", which(all_lp), "\n")

## Why standard_errors_inflated / weakly_identified_fixed_effects stay silent:
## R/check.R:1340-1350 takes the 'reference' SE as median(SE < 50) and, when every
## SE is >= 50, falls back to min(SE); a parameter is flagged only when
## SE >= 50 AND SE >= 1000 * reference. With two parameters both inflated, the
## ratio max(SE)/min(SE) is O(1), never 1000.
cat("\nmax(SE)/min(SE) per nonexistent rep (must reach 1000 to be flagged):\n")
nx <- res[res$group != "control", ]
print(data.frame(rep = nx$rep, min_se = pmin(nx$drm_se_b0, nx$drm_se_b1), max_se = pmax(nx$drm_se_b0, nx$drm_se_b1),
                 ratio = pmax(nx$drm_se_b0, nx$drm_se_b1) / pmin(nx$drm_se_b0, nx$drm_se_b1)), row.names = FALSE)

## Cheap alternative signal: fitted means. On every nonexistent rep some fitted mean
## underflows toward 0 (eta far below log(.Machine$double.eps)) where y = 0.
cat("\nmin fitted eta (X %*% beta) per rep:\n")
print(data.frame(rep = res$rep, group = res$group, min_eta = sapply(seq_len(nrow(res)), function(i) {
  d <- read.csv(file.path(ddir, sprintf("pois_n8_lowmean_r%02d.csv", res$rep[i])))
  min(res$drm_b0[i] + res$drm_b1[i] * d$x) })), row.names = FALSE)

## The reported estimate is an artefact of the start, not of the data: refit the
## all-zero rep 3 and the extreme-x rep 25 from other user starts (drm_control(start =)).
cat("\n== Start dependence (same data, different user starts; compare estimates and flags) ==\n")
for (rep in c(3, 25)) {
  d <- read.csv(file.path(ddir, sprintf("pois_n8_lowmean_r%02d.csv", rep)))
  for (st in list(c(0, 0), c(-5, 0), c(-40, 0), c(-10, 10))) {
    f <- capture(drmTMB(bf(y ~ x), family = poisson(), data = d,
      control = drm_control(start = list("fixef:mu:(Intercept)" = st[1], "fixef:mu:x" = st[2]))))
    fit <- f$value
    se <- tryCatch(sqrt(diag(vcov(fit))), error = function(e) c(NA_real_, NA_real_))
    cat(sprintf("rep %2d start (%5.1f, %5.1f): est (%9.3f, %8.3f)  SE (%9.3g, %9.3g)  logLik %.6g  is_converged %s  status %s  check ok %s  iter %d  warnings: %s\n",
      rep, st[1], st[2], fit$opt$par[1], fit$opt$par[2], se[1], se[2],
      as.numeric(logLik(fit)), is_converged(fit), convergence_status(fit), isTRUE(attr(check_drm(fit), "ok")),
      fit$opt$iterations, if (length(f$warnings)) paste(substr(unique(f$warnings), 1, 60), collapse = " | ") else "none"))
  }
}

## Scope probes (same data): intercept-only Poisson on all-zero y, and nbinom2.
cat("\n== Scope probes ==\n")
show <- function(lab, expr) {
  f <- capture(tryCatch(expr, error = function(e) { cat(lab, "ERROR:", conditionMessage(e), "\n"); NULL }))
  fit <- f$value; if (is.null(fit)) return(invisible())
  se <- tryCatch(sqrt(diag(vcov(fit))), error = function(e) NA)
  cat(sprintf("%-28s est (%s)  SE (%s)  is_converged %s  status %s  check ok %s  warnings %d\n", lab,
    paste(signif(fit$opt$par, 5), collapse = ", "), paste(signif(se, 3), collapse = ", "),
    is_converged(fit), convergence_status(fit), isTRUE(attr(check_drm(fit), "ok")), length(f$warnings)))
}
d3  <- read.csv(file.path(ddir, "pois_n8_lowmean_r03.csv"))
d25 <- read.csv(file.path(ddir, "pois_n8_lowmean_r25.csv"))
show("poisson  y ~ 1, rep 3",        drmTMB(bf(y ~ 1), family = poisson(), data = d3))
show("nbinom2  y ~ x, rep 3",        drmTMB(bf(y ~ x, sigma ~ 1), family = nbinom2(), data = d3))
show("nbinom2  y ~ x, rep 25",       drmTMB(bf(y ~ x, sigma ~ 1), family = nbinom2(), data = d25))
