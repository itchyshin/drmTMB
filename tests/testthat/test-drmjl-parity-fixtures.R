# drmTMB vs DRModels.jl parity on committed reference values.
#
# The reference values in fixtures/drmjl-parity/reference.csv were produced by
# DRModels.jl itself (DRModels.drm_bridge, called directly from Julia by
# tools/drmjl-parity/make-reference.jl), on the CSVs written by
# tools/drmjl-parity/make-data.R. The DRModels.jl commit is recorded in
# fixtures/drmjl-parity/PROVENANCE. Seven families, each fixed-effect only and
# with a mu random intercept (1 | g): Gaussian, Poisson, NB2, Beta, Binomial,
# Student, Gamma.
#
# Two layers:
#   1. Pure R (always runs, no Julia): fit engine = "tmb" on each data file and
#      compare logLik, coefficients and Wald SEs against the stored values.
#   2. Live (skips unless a DRModels.jl checkout and JuliaCall are available):
#      refit the bridge-admitted cases through engine = "julia" and confirm the
#      engine at hand still reproduces the stored values.
#
# Coefficients and SEs are compared on the working scale both engines optimise:
# mu/sigma/nu linear predictors, and the log-SD of the random intercept
# (DRModels.jl `resd_g`, TMB `log_sd_mu`).
#
# Non-Gaussian (1 | g) cases use DRModels.jl marginal = "Laplace", the same
# integrator as TMB. The DRModels.jl DEFAULT integrator on those routes is
# 32-node adaptive Gauss-Hermite (DRModels.jl#1071); those values are stored as
# `<family>_re_default` and are skipped here as a known, by-design mismatch.

drmjl_parity_dir <- function() {
  testthat::test_path("fixtures", "drmjl-parity")
}

drmjl_parity_reference <- function() {
  utils::read.csv(
    file.path(drmjl_parity_dir(), "reference.csv"),
    stringsAsFactors = FALSE,
    colClasses = c(value = "character")
  )
}

drmjl_parity_provenance <- function() {
  lines <- readLines(file.path(drmjl_parity_dir(), "PROVENANCE"), warn = FALSE)
  keys <- sub(":.*$", "", lines)
  vals <- trimws(sub("^[^:]*:", "", lines))
  stats::setNames(as.list(vals), keys)
}

drmjl_parity_data <- function(family) {
  dat <- utils::read.csv(file.path(drmjl_parity_dir(), paste0("data-", family, ".csv")))
  dat$g <- factor(dat$g)
  dat
}

# The drmTMB call for each case. Formulas mirror the DRModels.jl strings in
# tools/drmjl-parity/make-reference.jl term for term.
drmjl_parity_cases <- function() {
  list(
    gaussian_fe = list(form = bf(y ~ x, sigma ~ x), family = gaussian()),
    gaussian_re = list(form = bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian()),
    poisson_fe = list(form = bf(y ~ x), family = poisson()),
    poisson_re = list(form = bf(y ~ x + (1 | g)), family = poisson()),
    nbinom2_fe = list(form = bf(y ~ x, sigma ~ 1), family = nbinom2()),
    nbinom2_re = list(form = bf(y ~ x + (1 | g), sigma ~ 1), family = nbinom2()),
    beta_fe = list(form = bf(y ~ x, sigma ~ 1), family = beta_family()),
    beta_re = list(form = bf(y ~ x + (1 | g), sigma ~ 1), family = beta_family()),
    binomial_fe = list(form = bf(cbind(successes, failures) ~ x), family = binomial()),
    binomial_re = list(form = bf(cbind(successes, failures) ~ x + (1 | g)), family = binomial()),
    student_fe = list(form = bf(y ~ x, sigma ~ 1, nu ~ 1), family = student()),
    student_re = list(form = bf(y ~ x + (1 | g), sigma ~ 1, nu ~ 1), family = student()),
    gamma_fe = list(form = bf(y ~ x, sigma ~ 1), family = Gamma(link = "log")),
    gamma_re = list(form = bf(y ~ x + (1 | g), sigma ~ 1), family = Gamma(link = "log"))
  )
}

# Known mismatches: case -> skip reason naming the issue. Every case not listed
# here must agree within tolerance.
parity_known_mismatch <- c(
  poisson_re_default = "DRModels.jl default integrator (GHQ-32) differs from drmTMB Laplace by design (DRModels.jl#1071)",
  nbinom2_re_default = "DRModels.jl default integrator (GHQ-32) differs from drmTMB Laplace by design (DRModels.jl#1071)",
  beta_re_default = "DRModels.jl default integrator (GHQ-32) differs from drmTMB Laplace by design (DRModels.jl#1071)",
  binomial_re_default = "DRModels.jl default integrator (GHQ-32) differs from drmTMB Laplace by design (DRModels.jl#1071)",
  student_re_default = "DRModels.jl default integrator (GHQ-32) differs from drmTMB Laplace by design (DRModels.jl#1071)",
  gamma_re_default = "DRModels.jl default integrator (GHQ-32) differs from drmTMB Laplace by design (DRModels.jl#1071)"
)

# Measured at the fixture commit (macOS arm64, 2026-10-31), worst case over the
# 14 parity cases: logLik 6.8e-12, coefficient 2.5e-08 (beta_re), SE 1.2e-06
# relative (gaussian_fe). The bars leave two or more orders of headroom.
drmjl_parity_tol <- list(loglik = 1e-6, coef = 1e-5, se_rel = 1e-4)

# Stored values for one case, as named numeric vectors in DRModels.jl labels.
drmjl_parity_expected <- function(ref, case) {
  r <- ref[ref$case == case, , drop = FALSE]
  pick <- function(q) {
    rr <- r[r$quantity == q, , drop = FALSE]
    stats::setNames(as.numeric(rr$value), rr$term)
  }
  list(
    family = r$family[[1L]],
    loglik = as.numeric(r$value[r$quantity == "loglik"]),
    converged = r$value[r$quantity == "converged"],
    marginal = r$value[r$quantity == "marginal"],
    coef = pick("coef"),
    se = pick("se")
  )
}

# drmTMB working-scale estimates and SEs relabelled to DRModels.jl names. The
# TMB fixed parameters come in blocks (beta_mu, beta_sigma, beta_nu,
# log_sd_mu); within a block the order is the model-matrix column order,
# which is also DRModels.jl's order for these (Intercept) + x designs.
drmjl_parity_tmb_values <- function(fit, jl_names) {
  s <- summary(fit$sdr, "fixed")
  block_of_jl <- ifelse(
    startsWith(jl_names, "resd_"),
    "log_sd_mu",
    paste0("beta_", sub("_.*$", "", jl_names))
  )
  est <- se <- stats::setNames(rep(NA_real_, length(jl_names)), jl_names)
  for (blk in unique(block_of_jl)) {
    rows <- which(rownames(s) == blk)
    cols <- which(block_of_jl == blk)
    if (length(rows) != length(cols)) {
      stop("block ", blk, ": TMB has ", length(rows), " rows, DRModels.jl ", length(cols))
    }
    est[cols] <- s[rows, "Estimate"]
    se[cols] <- s[rows, "Std. Error"]
  }
  extra <- setdiff(unique(rownames(s)), unique(block_of_jl))
  if (length(extra)) stop("TMB parameters with no DRModels.jl counterpart: ", toString(extra))
  list(coef = est, se = se)
}

test_that("drmjl-parity fixtures carry a clean DRModels.jl commit and every case", {
  prov <- drmjl_parity_provenance()
  expect_match(prov$drmjl_commit, "^[0-9a-f]{40}$")
  expect_identical(prov$drmjl_dirty, "false")

  ref <- drmjl_parity_reference()
  expect_false(any(ref$quantity == "error"))
  cases <- c(names(drmjl_parity_cases()), names(parity_known_mismatch))
  expect_setequal(unique(ref$case), cases)
  for (case in cases) {
    e <- drmjl_parity_expected(ref, case)
    expect_true(is.finite(e$loglik), info = case)
    expect_identical(e$converged, "true", info = case)
    expect_identical(names(e$coef), names(e$se), info = case)
    expect_true(all(is.finite(e$se) & e$se > 0), info = case)
    # Like-for-like integrator: Laplace on every non-Gaussian (1 | g) case.
    if (grepl("_re$", case) && e$family != "gaussian") {
      expect_identical(e$marginal, "Laplace", info = case)
    }
  }
})

for (case in names(drmjl_parity_cases())) {
  local({
    case <- case
    test_that(paste0("drmTMB matches DRModels.jl reference: ", case), {
      spec <- drmjl_parity_cases()[[case]]
      e <- drmjl_parity_expected(drmjl_parity_reference(), case)
      dat <- drmjl_parity_data(e$family)
      fit <- drmTMB(spec$form, family = spec$family, data = dat)
      expect_true(is_converged(fit))

      tmb <- drmjl_parity_tmb_values(fit, names(e$coef))
      expect_lt(abs(as.numeric(logLik(fit)) - e$loglik), drmjl_parity_tol$loglik)
      expect_lt(max(abs(tmb$coef - e$coef)), drmjl_parity_tol$coef)
      expect_lt(max(abs(tmb$se / e$se[names(tmb$se)] - 1)), drmjl_parity_tol$se_rel)
    })
  })
}

for (case in names(parity_known_mismatch)) {
  local({
    case <- case
    test_that(paste0("drmTMB vs DRModels.jl default integrator: ", case), {
      skip(parity_known_mismatch[[case]])
    })
  })
}

# ---- live: the engine at hand still reproduces the stored values ----------

# Cases engine = "julia" admits today. Non-Gaussian ordinary (1 | g) is refused
# in R before Julia starts (#1551), so those are covered by layer 1 only.
drmjl_parity_bridge_cases <- c(
  "gaussian_fe", "gaussian_re", "poisson_fe", "nbinom2_fe", "beta_fe",
  "binomial_fe", "student_fe", "gamma_fe"
)

test_that("engine = 'julia' reproduces the stored DRModels.jl reference values", {
  drm_skip_live_julia()
  testthat::skip_if_not_installed("JuliaCall")
  testthat::skip_if_not_installed("callr")
  testthat::skip_if_not_installed("pkgload")

  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  fx_dir <- normalizePath(drmjl_parity_dir(), mustWork = TRUE)
  out <- callr::r(
    function(pkg, jl_path, fx_dir, cases, specs) {
      julia_home <- Sys.getenv("DRM_JL_JULIA_HOME", Sys.getenv("JULIA_HOME", ""))
      if (nzchar(julia_home)) Sys.setenv(JULIA_HOME = julia_home)
      options(drmTMB.DRModels.jl.path = jl_path, drmTMB.DRM.jl.path = jl_path)
      Sys.setenv(DRM_JL_PATH = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))
      res <- list()
      for (case in cases) {
        fam <- sub("_(fe|re)$", "", case)
        dat <- utils::read.csv(file.path(fx_dir, paste0("data-", fam, ".csv")))
        dat$g <- factor(dat$g)
        fj <- drmTMB::drmTMB(
          specs[[case]]$form, family = specs[[case]]$family,
          data = dat, engine = "julia"
        )
        b <- fj$bridge
        nm <- as.character(unlist(b$coef_names))
        res[[case]] <- list(
          loglik = as.numeric(b$loglik),
          coef = stats::setNames(as.numeric(unlist(b$coefficients)), nm),
          se = stats::setNames(sqrt(diag(as.matrix(b$vcov))), as.character(unlist(b$vcov_names)))
        )
      }
      res
    },
    args = list(
      pkg = pkg, jl_path = drm_test_drmjl_path(), fx_dir = fx_dir,
      cases = drmjl_parity_bridge_cases,
      specs = drmjl_parity_cases()[drmjl_parity_bridge_cases]
    )
  )

  ref <- drmjl_parity_reference()
  for (case in drmjl_parity_bridge_cases) {
    e <- drmjl_parity_expected(ref, case)
    got <- out[[case]]
    expect_setequal(names(got$coef), names(e$coef))
    expect_lt(abs(got$loglik - e$loglik), drmjl_parity_tol$loglik, label = case)
    expect_lt(max(abs(got$coef[names(e$coef)] - e$coef)), drmjl_parity_tol$coef, label = case)
    expect_lt(max(abs(got$se[names(e$se)] / e$se - 1)), drmjl_parity_tol$se_rel, label = case)
  }
})
