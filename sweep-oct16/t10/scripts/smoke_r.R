# t10 R smoke: one draw per nested pair + API / mixing checks.
# Hard timeout per fit via setTimeLimit. Writes sweep-oct16/t10/logs/smoke_r.jsonl

.libPaths(c("/tmp/t10-lib", .libPaths()))
suppressPackageStartupMessages(library(drmTMB))

log_path <- "/workspace/sweep-oct16/t10/logs/smoke_r.jsonl"
dir.create(dirname(log_path), recursive = TRUE, showWarnings = FALSE)
if (file.exists(log_path)) file.remove(log_path)

ctrl <- drm_control(se = FALSE, keep_tmb_object = FALSE, keep_model_frame = FALSE)

json_escape <- function(x) {
  x <- gsub("\\", "\\\\", x, fixed = TRUE)
  x <- gsub("\"", "\\\"", x, fixed = TRUE)
  x <- gsub("\n", "\\n", x, fixed = TRUE)
  x
}

emit <- function(...) {
  dots <- list(...)
  parts <- vapply(names(dots), function(nm) {
    v <- dots[[nm]]
    if (is.null(v) || (length(v) == 1L && is.na(v))) {
      sprintf("\"%s\":null", nm)
    } else if (is.logical(v) && length(v) == 1L) {
      sprintf("\"%s\":%s", nm, if (isTRUE(v)) "true" else "false")
    } else if (is.numeric(v) && length(v) == 1L) {
      sprintf("\"%s\":%s", nm, format(v, digits = 16, scientific = TRUE))
    } else {
      sprintf("\"%s\":\"%s\"", nm, json_escape(paste(v, collapse = " | ")))
    }
  }, character(1))
  cat(paste0("{", paste(parts, collapse = ","), "}\n"), file = log_path, append = TRUE)
  cat(paste(parts, collapse = "  "), "\n")
}

fit_timed <- function(expr, seconds, label) {
  t0 <- proc.time()[["elapsed"]]
  setTimeLimit(elapsed = seconds, transient = TRUE)
  on.exit(setTimeLimit(elapsed = Inf, transient = TRUE), add = TRUE)
  out <- tryCatch(
    list(ok = TRUE, value = expr, error = NA_character_),
    error = function(e) list(ok = FALSE, value = NULL, error = conditionMessage(e))
  )
  out$elapsed <- proc.time()[["elapsed"]] - t0
  out$timeout <- !out$ok && grepl("time.?limit|reached elapsed", out$error, ignore.case = TRUE)
  if (out$timeout) {
    emit(case = label, status = "TIMEOUT", elapsed = out$elapsed, error = out$error)
  } else if (!out$ok) {
    emit(case = label, status = "ERROR", elapsed = out$elapsed, error = out$error)
  }
  out
}

# Warmup so TMB's first-compile cost is not blamed on a later cell.
set.seed(1)
warm <- data.frame(y = rnorm(40), x = rnorm(40))
invisible(fit_timed(
  drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = warm, control = ctrl),
  60, "warmup_gaussian"
))

# --- Cell A: Gaussian sigma ~ 1 vs sigma ~ z (interior) ---
# Official seed 20261017000; RNG seed = official - 1.9e10 (R 32-bit set.seed).
set.seed(as.integer(20261017000 - 1.9e10))
n <- 200L
dat_a <- data.frame(x = rnorm(n), z = rnorm(n))
dat_a$y <- 0.3 + 0.5 * dat_a$x + rnorm(n)
m0 <- fit_timed(
  drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat_a, control = ctrl),
  30, "A_reduced"
)
m1 <- fit_timed(
  drmTMB(bf(y ~ x, sigma ~ z), family = gaussian(), data = dat_a, control = ctrl),
  30, "A_full"
)
if (isTRUE(m0$ok) && isTRUE(m1$ok)) {
  a <- anova(m0$value, m1$value)
  emit(
    case = "A_anova", status = "OK",
    statistic = a$Chisq[[2]], df = a$Df[[2]], pvalue = a$`Pr(>Chisq)`[[2]],
    p_method = attr(a, "p.method")[[2]],
    aic_reduced = AIC(m0$value), aic_full = AIC(m1$value),
    aicc_reduced = aicc(m0$value), aicc_full = aicc(m1$value),
    loglik_reduced = as.numeric(logLik(m0$value)),
    loglik_full = as.numeric(logLik(m1$value))
  )
}

# --- Cell B: NB2 vs Poisson (boundary) ---
set.seed(as.integer(20261017000 - 1.9e10))
n <- 250L
x <- rnorm(n)
dat_b <- data.frame(x = x, y = rpois(n, lambda = exp(0.4 + 0.3 * x)))
p0 <- fit_timed(
  drmTMB(bf(y ~ x), family = poisson(), data = dat_b, control = ctrl),
  45, "B_poisson"
)
p1 <- fit_timed(
  drmTMB(bf(y ~ x, sigma ~ 1), family = nbinom2(), data = dat_b, control = ctrl),
  45, "B_nbinom2"
)
if (isTRUE(p0$ok) && isTRUE(p1$ok)) {
  warn_b <- character()
  a <- withCallingHandlers(
    anova(p0$value, p1$value),
    warning = function(w) {
      warn_b <<- c(warn_b, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  lb <- tryCatch(lrt_boundary(p1$value, p0$value, q = 1), error = function(e) e)
  emit(
    case = "B_anova", status = "OK",
    statistic = a$Chisq[[2]], df = a$Df[[2]], pvalue = a$`Pr(>Chisq)`[[2]],
    p_method = attr(a, "p.method")[[2]],
    anova_warning = if (length(warn_b)) paste(warn_b, collapse = " || ") else NA,
    aic_reduced = AIC(p0$value), aic_full = AIC(p1$value),
    loglik_reduced = as.numeric(logLik(p0$value)),
    loglik_full = as.numeric(logLik(p1$value)),
    npar_reduced = p0$value$df, npar_full = p1$value$df,
    lrt_boundary_ok = !inherits(lb, "error"),
    lrt_boundary_p = if (!inherits(lb, "error")) lb$pvalue else NA,
    lrt_boundary_stat = if (!inherits(lb, "error")) lb$statistic else NA,
    lrt_boundary_err = if (inherits(lb, "error")) conditionMessage(lb) else NA
  )
}

# --- Cell C: (1|g) vs none (boundary) ---
set.seed(as.integer(20261017000 - 1.9e10))
G <- 25L
m <- 12L
g <- factor(rep(seq_len(G), each = m))
x <- rnorm(G * m)
dat_c <- data.frame(g = g, x = x, y = 0.4 - 0.5 * x + 0.7 * rnorm(G * m))
r0 <- fit_timed(
  drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat_c, control = ctrl),
  30, "C_reduced"
)
r1 <- fit_timed(
  drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(), data = dat_c, control = ctrl),
  90, "C_full"
)
if (isTRUE(r0$ok) && isTRUE(r1$ok)) {
  warn_c <- character()
  a <- withCallingHandlers(
    anova(r0$value, r1$value),
    warning = function(w) {
      warn_c <<- c(warn_c, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  lb <- lrt_boundary(r1$value, r0$value, q = 1)
  emit(
    case = "C_anova", status = "OK",
    statistic = a$Chisq[[2]], df = a$Df[[2]], pvalue = a$`Pr(>Chisq)`[[2]],
    p_method = attr(a, "p.method")[[2]],
    anova_warning = if (length(warn_c)) paste(warn_c, collapse = " || ") else NA,
    chibar_p = lb$pvalue, naive_p = lb$pvalue_naive,
    aic_reduced = AIC(r0$value), aic_full = AIC(r1$value),
    loglik_reduced = as.numeric(logLik(r0$value)),
    loglik_full = as.numeric(logLik(r1$value))
  )
}

# Mixing: engine = "julia" is R's only other approximation route. It must refuse
# anova against a TMB fit (already coded). Record the refusal.
emit(
  case = "mix_anova_julia_stub",
  status = tryCatch({
    stub <- structure(list(nobs = 7L, df = 3L), class = "drmTMB_julia")
    anova(m0$value, stub)
    "NO_ERROR"
  }, error = function(e) paste("ERROR:", conditionMessage(e)))
)

si <- paste(capture.output(sessionInfo()), collapse = "\n")
writeLines(si, "/workspace/sweep-oct16/t10/logs/sessionInfo_r.txt")
cat("SMOKE_R_OK\n")
