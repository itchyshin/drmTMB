#!/usr/bin/env Rscript
# leaf-a4g17 scout probe (G0/G1). Ad hoc measurement script, NOT wired into
# testthat's automatic collection (filename starts with "helper-" but this is
# meant to be run directly via `Rscript`, not sourced by testthat itself,
# since it calls devtools::load_all() and quit()). Left uncommitted for the
# builder.
#
# Usage:
#   Rscript tests/testthat/helper-fe-only-fence-probe.R --baseline
#   Rscript tests/testthat/helper-fe-only-fence-probe.R --controls

args <- commandArgs(trailingOnly = TRUE)
mode <- if ("--controls" %in% args) "controls" else "baseline"
run_requested <- any(c("--baseline", "--controls") %in% args)

# Two guards, both required, because this file's name matches testthat's
# `^helper.*\.[rR]$` test-helper glob:
#
# (1) run_requested / --baseline|--controls: this file is auto-sourced by
#     pkgload::load_all()/testthat::test_dir() EVERY time anyone loads this
#     package for something completely unrelated (running the real test
#     suite, `Rscript tools/write-julia-gate-registry.R`, R CMD check, ...).
#     Without this flag check, the probe's model fits would fire as a silent
#     side effect of every such load. The probe body below runs ONLY when
#     invoked directly as `Rscript .../helper-fe-only-fence-probe.R
#     --baseline|--controls`.
# (2) the option() sentinel: our own explicit `Rscript ... --baseline`
#     invocation calls devtools::load_all() below, and pkgload's own helper
#     loading SOURCES THIS SAME FILE AGAIN, nested, before load_all()
#     returns. At that nested invocation commandArgs() still reports
#     "--baseline" (it reads the one OS process's argv), so run_requested is
#     also TRUE there -- guard (1) alone would let it double-run/recurse.
#     The option flag, set before calling load_all() and cleared after,
#     distinguishes "am I the nested, in-progress load" from "am I the
#     top-level call", because both invocations share the same R session.
if (isTRUE(getOption("drmtmb.fe_only_fence_probe.loading"))) {
  # The nested, pkgload-triggered invocation of this exact file: do nothing.
  invisible(NULL)
} else if (!run_requested) {
  # Sourced as an ordinary test helper (no --baseline/--controls flag):
  # define nothing, run nothing, return silently.
  invisible(NULL)
} else {
  options(drmtmb.fe_only_fence_probe.loading = TRUE)
  if (!isNamespaceLoaded("drmTMB")) {
    suppressMessages(devtools::load_all(".", quiet = TRUE))
  }
  options(drmtmb.fe_only_fence_probe.loading = FALSE)
  if (!isNamespaceLoaded("drmTMB")) {
    stop("drmTMB namespace still not loaded after devtools::load_all(); aborting probe.")
  }

classify <- function(cnd) {
  if (is.null(cnd)) {
    return("NO_ERROR")
  }
  msg <- conditionMessage(cnd)
  julia_setup_pattern <- paste(
    c(
      "needs a local DRM.jl checkout",
      "does not exist",
      "does not look like a DRM.jl checkout",
      "DRM_JL_PATH",
      "JuliaCall"
    ),
    collapse = "|"
  )
  if (grepl(julia_setup_pattern, msg)) {
    "REACHES_JULIA_SETUP"
  } else {
    "PRE_JULIA_REFUSAL"
  }
}

run_probe <- function(label, expr) {
  cnd <- tryCatch({
    force(expr)
    NULL
  }, error = function(e) e)
  cls <- classify(cnd)
  msg <- if (is.null(cnd)) "<no error raised>" else conditionMessage(cnd)
  cat(sprintf("---- %s ----\n", label))
  cat(sprintf("CLASS: %s\n", cls))
  cat(sprintf("MESSAGE: %s\n", msg))
  cat("\n")
  cls
}

set.seed(1)
n <- 60L
g <- factor(rep(seq_len(10), each = 6))
x <- stats::rnorm(n)
z <- stats::rnorm(n)

# ---- ape tree fixture (matches the pattern used by phylo tests) -----------
have_ape <- requireNamespace("ape", quietly = TRUE)
if (have_ape) {
  # ape::rcoal() is already ultrametric by construction (a coalescent tree);
  # do not overwrite edge.length with a constant, since that only stays
  # ultrametric for a topologically balanced tree.
  tr <- ape::rcoal(10)
  tr$tip.label <- paste0("s", seq_len(10))
  sp <- factor(paste0("s", rep(seq_len(10), each = 6)))
} else {
  tr <- NULL
  sp <- NULL
}

results <- character()

if (identical(mode, "baseline")) {
  # ---- student(): y ~ x + (1 | g) ----
  dat1 <- data.frame(y = stats::rt(n, df = 5) + 0.3 * x, x = x, g = g)
  results["student_re_mu"] <- run_probe(
    "student() y ~ x + (1 | g)",
    drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = student(), data = dat1,
           engine = "julia")
  )

  # ---- tweedie(): y ~ x + phylo(1 | sp, tree = tr) ----
  if (have_ape) {
    beta_mu <- c(`(Intercept)` = 0.2, x = 0.45)
    beta_sigma <- c(`(Intercept)` = -0.55)
    mu <- exp(beta_mu[[1L]] + beta_mu[[2L]] * x)
    sigma <- exp(beta_sigma[[1L]])
    y2 <- drmTMB:::rtweedie_compound(n, mu = mu, phi = sigma^2, power = 1.35)
    dat2 <- data.frame(y = y2, x = x, sp = sp)
    results["tweedie_phylo_mu"] <- run_probe(
      "tweedie() y ~ x + phylo(1 | sp, tree = tr)",
      drmTMB(bf(y ~ x + phylo(1 | sp, tree = tr), sigma ~ 1, nu ~ 1),
             family = tweedie(), data = dat2, engine = "julia")
    )
  } else {
    cat("SKIP tweedie phylo probe: ape not installed\n")
  }

  # ---- beta_binomial(): cbind(s, f) ~ x + (1 | g) ----
  trials <- sample(8:24, n, replace = TRUE)
  p <- stats::plogis(-0.2 + 0.7 * x)
  s <- stats::rbinom(n, size = trials, prob = p)
  dat3 <- data.frame(s = s, f = trials - s, x = x, g = g)
  results["beta_binomial_re_mu"] <- run_probe(
    "beta_binomial() cbind(s, f) ~ x + (1 | g)",
    drmTMB(bf(cbind(s, f) ~ x + (1 | g), sigma ~ 1),
           family = beta_binomial(), data = dat3, engine = "julia")
  )

  # ---- lognormal(): sigma ~ z + (1 | g) ----
  dat4 <- data.frame(y = stats::rlnorm(n, meanlog = 0.2 + 0.4 * x, sdlog = 0.5),
                      x = x, z = z, g = g)
  results["lognormal_re_sigma"] <- run_probe(
    "lognormal() sigma ~ z + (1 | g)",
    drmTMB(bf(y ~ x, sigma ~ z + (1 | g)), family = lognormal(), data = dat4,
           engine = "julia")
  )

  # ---- zero_one_beta(): y ~ x + (1 | g) ----
  mu5 <- stats::plogis(-0.2 + 0.65 * x)
  y5 <- stats::rbeta(n, shape1 = mu5 * 4, shape2 = (1 - mu5) * 4)
  dat5 <- data.frame(y = y5, x = x, g = g)
  results["zero_one_beta_re_mu"] <- run_probe(
    "zero_one_beta() y ~ x + (1 | g)",
    drmTMB(bf(y ~ x + (1 | g), sigma ~ 1, zoi ~ 1, coi ~ 1),
           family = zero_one_beta(), data = dat5, engine = "julia")
  )

  # ---- truncated_nbinom2(): y ~ x + (1 + x | g) ----
  mu6 <- exp(0.5 + 0.25 * x)
  sigma6_true <- 0.6
  p0 <- stats::dnbinom(0, size = 1 / sigma6_true^2, mu = mu6)
  u <- p0 + pmax(stats::runif(n), 1e-10) * (1 - p0)
  y6 <- stats::qnbinom(u, size = 1 / sigma6_true^2, mu = mu6)
  dat6 <- data.frame(y = y6, x = x, g = g)
  results["truncated_nbinom2_slope_mu"] <- run_probe(
    "truncated_nbinom2() y ~ x + (1 + x | g)",
    drmTMB(bf(y ~ x + (1 + x | g), sigma ~ 1),
           family = truncated_nbinom2(), data = dat6, engine = "julia")
  )

  n_reach <- sum(results == "REACHES_JULIA_SETUP")
  cat(sprintf("FE_ONLY_RE_REACHES_JULIA_SETUP: %d\n", n_reach))
}

if (identical(mode, "controls")) {
  # ---- G4 positive controls ----
  dat_g1 <- data.frame(y = stats::rnorm(n, mean = 0.3 * x), x = x, g = g)
  results["gaussian_re_mu"] <- run_probe(
    "gaussian() y ~ x + (1 | g)",
    drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(), data = dat_g1,
           engine = "julia")
  )

  if (have_ape) {
    lam <- exp(0.2 + 0.3 * x)
    y_pois <- stats::rpois(n, lam)
    dat_g2 <- data.frame(y = y_pois, x = x, sp = sp)
    results["poisson_phylo_mu"] <- run_probe(
      "poisson() y ~ x + phylo(1 | sp, tree = tr)",
      drmTMB(bf(y ~ x + phylo(1 | sp, tree = tr)), family = poisson(),
             data = dat_g2, engine = "julia")
    )

    y1b <- stats::rnorm(n, mean = 0.2 + 0.3 * x)
    y2b <- stats::rnorm(n, mean = -0.1 + 0.2 * x)
    dat_g3 <- data.frame(y1 = y1b, y2 = y2b, x = x, sp = sp)
    results["biv_gaussian_phylo_mu1_only"] <- run_probe(
      "biv_gaussian() with mu1-only phylo term (invalid partial phylo)",
      drmTMB(
        bf(
          mu1 = y1 ~ x + phylo(1 | sp, tree = tr),
          mu2 = y2 ~ x,
          sigma1 = ~1, sigma2 = ~1, rho12 = ~1
        ),
        family = biv_gaussian(), data = dat_g3, engine = "julia"
      )
    )
    results["biv_gaussian_phylo_q2"] <- run_probe(
      "biv_gaussian() with a valid q2 mu1+mu2 phylo term",
      drmTMB(
        bf(
          mu1 = y1 ~ x + phylo(1 | sp, tree = tr),
          mu2 = y2 ~ x + phylo(1 | sp, tree = tr),
          sigma1 = ~1, sigma2 = ~1, rho12 = ~1
        ),
        family = biv_gaussian(), data = dat_g3, engine = "julia"
      )
    )

    y_gs <- stats::rnorm(n, mean = 0.2 + 0.3 * x)
    dat_g4 <- data.frame(y = y_gs, x = x, sp = sp)
    results["gaussian_sigma_phylo"] <- run_probe(
      "gaussian() sigma ~ phylo(1 | sp, tree = tr)",
      drmTMB(bf(y ~ x, sigma ~ phylo(1 | sp, tree = tr)), family = gaussian(),
             data = dat_g4, engine = "julia")
    )
  } else {
    cat("SKIP phylo controls: ape not installed\n")
  }
}
}
