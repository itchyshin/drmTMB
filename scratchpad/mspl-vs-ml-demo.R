#!/usr/bin/env Rscript
# MSPL versus ML on the same data -- two regimes, one script.
#
#   Run:  R_PROFILE_USER=/dev/null Rscript --no-init-file scratchpad/mspl-vs-ml-demo.R
#
# Regime 1 uses the motivating dataset of Sterzinger & Kosmidis (2023), the
# paper MSPL comes from: Culcita coral predation (McKeon et al. 2012, via
# Bolker 2015), shipped in lme4 as `culcitalogreg`. 80 observations, 10 blocks,
# 4 treatments, one random intercept per block.
#
# Regime 2 is a deliberately SEPARATED design: one treatment level with zero
# events, which is where the unpenalized MLE does not exist.
#
# The point of showing both: MSPL should leave an already-identified fit alone
# and only rescue the part that is broken. Regime 1 checks the first half of
# that claim, regime 2 the second.

suppressMessages({
  devtools::load_all(quiet = TRUE)
  library(lme4)
})

fit_three <- function(data, label) {
  ml <- tryCatch(
    drmTMB(bf(y ~ trt + (1 | block)), family = binomial(), data = data),
    error = function(e) e
  )
  mspl <- tryCatch(
    drmTMB(bf(y ~ trt + (1 | block)), family = binomial(), data = data,
           estimator = "mspl"),
    error = function(e) e
  )
  gl <- tryCatch(
    glmer(y ~ trt + (1 | block), family = binomial, data = data, nAGQ = 1L),
    error = function(e) e
  )
  sm <- function(f) if (inherits(f, "error")) NULL else summary(f)$coefficients
  cml <- sm(ml)
  cms <- sm(mspl)
  cgl <- if (inherits(gl, "error")) NULL else {
    coef(summary(gl))[, c("Estimate", "Std. Error"), drop = FALSE]
  }

  cat("\n########", label, "########\n")
  cat("\n-- drmTMB ML --\n");   if (!is.null(cml)) print(round(cml, 2))
  cat("\n-- lme4::glmer --\n"); if (!is.null(cgl)) print(round(cgl, 2))
  cat("\n-- drmTMB MSPL --\n"); if (!is.null(cms)) print(round(cms, 2))

  if (!is.null(cml) && !is.null(cms)) {
    cat("\n-- headline --\n")
    cat(sprintf("  %-6s max|beta| = %10.2f   max SE = %12.2f\n",
                "ML", max(abs(cml[, 1])), max(cml[, 2], na.rm = TRUE)))
    if (!is.null(cgl)) {
      cat(sprintf("  %-6s max|beta| = %10.2f   max SE = %12.2f\n",
                  "glmer", max(abs(cgl[, 1])), max(cgl[, 2], na.rm = TRUE)))
    }
    cat(sprintf("  %-6s max|beta| = %10.2f   max SE = %12.2f\n",
                "MSPL", max(abs(cms[, 1])), max(cms[, 2], na.rm = TRUE)))
    w <- mspl$mspl$wald
    cat(sprintf("\n  MSPL Wald: spd = %s | rcond = %.3g | unpenalized grad = %.4g\n",
                w$spd, w$rcond, w$unpenalized_gradient_max_abs))
  }
  invisible(list(ml = cml, mspl = cms, glmer = cgl))
}

## ---- Regime 1: the paper's own dataset, NOT fixed-design separated ---------
data(culcitalogreg, package = "lme4")
culcita <- culcitalogreg
culcita$block <- factor(culcita$block)
culcita$trt <- factor(
  culcita$ttt.1,
  levels = c("No Symbionts", "Pair of Crabs", "Pair of Shrimp",
             "Pair of Shrimp and Crabs")
)
culcita$y <- culcita$predation

cat("Regime 1 -- Culcita, events by treatment:\n")
print(table(culcita$trt, culcita$y))
cat("\nEvery cell has both outcomes, so this is NOT fixed-design separation.\n")
cat("`detect_separation()` on the fixed design agrees:\n  ")
X1 <- model.matrix(y ~ trt, culcita)
cat("separation =",
    isTRUE(detectseparation::detect_separation(
      x = X1, y = culcita$y, family = binomial(), intercept = FALSE)$outcome), "\n")
fit_three(culcita, "REGIME 1: Culcita (identified)")

## ---- Regime 2: engineered separation --------------------------------------
set.seed(20260809)
G <- 12
sep <- data.frame(
  block = factor(rep(seq_len(G), each = 8)),
  trt = factor(rep(c("a", "b", "c", "d"), times = 2 * G))
)
u <- rnorm(G, 0, 0.8)
eta <- c(a = 0.5, b = 1.2, c = -0.3, d = -50)[as.character(sep$trt)] +
  u[as.integer(sep$block)]
sep$y <- rbinom(nrow(sep), 1, plogis(eta))

cat("\n\nRegime 2 -- engineered separation, events by treatment:\n")
print(table(sep$trt, sep$y))
X2 <- model.matrix(y ~ trt, sep)
cat("\n  separation =",
    isTRUE(detectseparation::detect_separation(
      x = X2, y = sep$y, family = binomial(), intercept = FALSE)$outcome), "\n")
fit_three(sep, "REGIME 2: engineered separation")

cat("\n\n#### What to look for ####\n")
cat("Regime 1: all three engines should agree closely, and MSPL should shrink\n")
cat("  only mildly -- the penalty must not disturb an identified fit.\n")
cat("Regime 2: ML and glmer both diverge on the separated coefficient AND\n")
cat("  DISAGREE WITH EACH OTHER, because they stop at different points on an\n")
cat("  almost-flat likelihood. That disagreement is the tell. MSPL stays finite\n")
cat("  and its three identified coefficients still match ML to ~2 decimals.\n")
