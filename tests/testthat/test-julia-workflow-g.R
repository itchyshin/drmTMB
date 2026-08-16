# Live R Workflow G gate (#499): round-trip DRM.jl's eleven admitted parity
# fixtures through drmTMB(..., engine = "julia") and compare against the
# committed expected.toml numbers (drmTMB 0.6.0 pin). Skip-safe when JuliaCall /
# DRM.jl / the fixture tree is unavailable. xfam-external-gllvm stays OUT.

drm_wfg_cohort <- function() {
  c(
    "gaussian-locscale",
    "gaussian-bivariate-rho12",
    "robust-student",
    "count-nbinom2",
    "proportion-beta",
    "meta-analysis-V",
    "count-poisson",
    "positive-gamma",
    "binomial-trials",
    "positive-lognormal",
    "nbinom2-dispersion"
  )
}

drm_wfg_drmjl_path <- function() {
  path <- drm_test_drmjl_path("DRM_JL_PATH")
  if (nzchar(path)) {
    return(path)
  }
  pkg_root <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  github_local <- if (identical(basename(dirname(pkg_root)), ".worktrees")) {
    dirname(dirname(dirname(pkg_root)))
  } else {
    dirname(pkg_root)
  }
  cand <- file.path(github_local, "DRM.jl")
  if (dir.exists(cand)) {
    return(cand)
  }
  ""
}

drm_wfg_fixtures_root <- function(jl_path = drm_wfg_drmjl_path()) {
  if (!nzchar(jl_path)) {
    return("")
  }
  file.path(jl_path, "test", "parity", "fixtures")
}

# Minimal TOML reader for Workflow G expected.toml ([fit]/ [coef], [tol]).
drm_wfg_parse_expected <- function(path) {
  lines <- readLines(path, warn = FALSE)
  section <- ""
  fit <- list()
  coef <- list()
  tol <- list()
  for (line in lines) {
    trimmed <- sub("#.*$", "", line)
    trimmed <- trimws(trimmed)
    if (!nzchar(trimmed)) {
      next
    }
    if (grepl("^\\[[^]]+\\]$", trimmed)) {
      section <- sub("^\\[(.+)\\]$", "\\1", trimmed)
      next
    }
    if (!grepl("=", trimmed, fixed = TRUE)) {
      next
    }
    key <- trimws(sub("\\s*=\\s*.*$", "", trimmed))
    raw <- trimws(sub("^[^=]*=\\s*", "", trimmed))
    key <- gsub('^"|"$', "", key)
    if (identical(section, "fit")) {
      if (grepl('^".*"$', raw)) {
        fit[[key]] <- gsub('^"|"$', "", raw)
      } else {
        fit[[key]] <- as.numeric(raw)
      }
    } else if (identical(section, "coef")) {
      coef[[key]] <- as.numeric(raw)
    } else if (identical(section, "tol")) {
      tol[[key]] <- as.numeric(raw)
    }
  }
  list(
    fit = fit,
    coef = unlist(coef, use.names = TRUE),
    tol = tol
  )
}

drm_wfg_flat_coef <- function(fit) {
  cf <- stats::coef(fit)
  if (is.null(names(cf)) && is.list(cf)) {
    return(numeric())
  }
  out <- numeric()
  for (nm in names(cf)) {
    block <- cf[[nm]]
    nms <- names(block)
    if (is.null(nms)) {
      nms <- as.character(seq_along(block))
    }
    out <- c(out, stats::setNames(as.numeric(block), paste0(nm, "_", nms)))
  }
  out
}

drm_wfg_within <- function(a, b, rtol, atol) {
  abs(a - b) <= max(atol, rtol * max(abs(a), abs(b)))
}

drm_wfg_case_spec <- function(slug) {
  switch(
    slug,
    "gaussian-locscale" = list(
      formula = quote(bf(y ~ x, sigma ~ x)),
      family = quote(stats::gaussian())
    ),
    "gaussian-bivariate-rho12" = list(
      formula = quote(bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~1,
        sigma2 = ~1,
        rho12 = ~1
      )),
      family = quote(biv_gaussian())
    ),
    "robust-student" = list(
      formula = quote(bf(y ~ x, sigma ~ 1, nu ~ 1)),
      family = quote(student())
    ),
    "count-nbinom2" = list(
      formula = quote(bf(y ~ x, sigma ~ 1)),
      family = quote(nbinom2())
    ),
    "proportion-beta" = list(
      formula = quote(bf(y ~ x, sigma ~ 1)),
      family = quote(beta())
    ),
    "meta-analysis-V" = list(
      formula = quote(bf(y ~ x + meta_V(V = v), sigma ~ 1)),
      family = quote(stats::gaussian())
    ),
    "count-poisson" = list(
      formula = quote(bf(y ~ x)),
      family = quote(stats::poisson())
    ),
    "positive-gamma" = list(
      formula = quote(bf(y ~ x, sigma ~ 1)),
      family = quote(stats::Gamma(link = "log"))
    ),
    "binomial-trials" = list(
      formula = quote(bf(cbind(successes, failures) ~ x)),
      family = quote(stats::binomial())
    ),
    "positive-lognormal" = list(
      formula = quote(bf(y ~ x, sigma ~ 1)),
      family = quote(lognormal())
    ),
    "nbinom2-dispersion" = list(
      formula = quote(bf(y ~ x, sigma ~ x)),
      family = quote(nbinom2())
    ),
    NULL
  )
}

drm_wfg_fit_slug <- function(slug, fixtures_root, jl_path) {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  julia_home <- drm_test_julia_home()
  if (!nzchar(julia_home) && nzchar(Sys.which("julia"))) {
    julia_home <- tryCatch(
      system2(
        "julia",
        c("-e", "print(Sys.BINDIR)"),
        stdout = TRUE,
        stderr = FALSE
      ),
      error = function(e) ""
    )
    julia_home <- paste(julia_home, collapse = "")
  }
  callr::r(
    function(pkg, jl_path, fixtures_root, slug, julia_home) {
      if (nzchar(julia_home)) {
        Sys.setenv(JULIA_HOME = julia_home)
      }
      options(drmTMB.DRM.jl.path = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))

      dir <- file.path(fixtures_root, slug)
      expected <- local({
        lines <- readLines(file.path(dir, "expected.toml"), warn = FALSE)
        section <- ""
        fit <- list()
        coef <- list()
        tol <- list()
        for (line in lines) {
          trimmed <- sub("#.*$", "", line)
          trimmed <- trimws(trimmed)
          if (!nzchar(trimmed)) next
          if (grepl("^\\[[^]]+\\]$", trimmed)) {
            section <- sub("^\\[(.+)\\]$", "\\1", trimmed)
            next
          }
          if (!grepl("=", trimmed, fixed = TRUE)) next
          key <- gsub('^"|"$', "", trimws(sub("\\s*=\\s*.*$", "", trimmed)))
          raw <- trimws(sub("^[^=]*=\\s*", "", trimmed))
          if (identical(section, "fit")) {
            fit[[key]] <- if (grepl('^".*"$', raw)) {
              gsub('^"|"$', "", raw)
            } else {
              as.numeric(raw)
            }
          } else if (identical(section, "coef")) {
            coef[[key]] <- as.numeric(raw)
          } else if (identical(section, "tol")) {
            tol[[key]] <- as.numeric(raw)
          }
        }
        list(fit = fit, coef = unlist(coef, use.names = TRUE), tol = tol)
      })
      dat <- utils::read.csv(file.path(dir, "data.csv"), stringsAsFactors = FALSE)
      spec <- switch(
        slug,
        "gaussian-locscale" = list(
          formula = drmTMB::bf(y ~ x, sigma ~ x),
          family = stats::gaussian()
        ),
        "gaussian-bivariate-rho12" = list(
          formula = drmTMB::bf(
            mu1 = y1 ~ x,
            mu2 = y2 ~ x,
            sigma1 = ~1,
            sigma2 = ~1,
            rho12 = ~1
          ),
          family = drmTMB::biv_gaussian()
        ),
        "robust-student" = list(
          formula = drmTMB::bf(y ~ x, sigma ~ 1, nu ~ 1),
          family = drmTMB::student()
        ),
        "count-nbinom2" = list(
          formula = drmTMB::bf(y ~ x, sigma ~ 1),
          family = drmTMB::nbinom2()
        ),
        "proportion-beta" = list(
          formula = drmTMB::bf(y ~ x, sigma ~ 1),
          family = drmTMB::beta()
        ),
        "meta-analysis-V" = list(
          formula = drmTMB::bf(y ~ x + meta_V(V = v), sigma ~ 1),
          family = stats::gaussian()
        ),
        "count-poisson" = list(
          formula = drmTMB::bf(y ~ x),
          family = stats::poisson()
        ),
        "positive-gamma" = list(
          formula = drmTMB::bf(y ~ x, sigma ~ 1),
          family = stats::Gamma(link = "log")
        ),
        "binomial-trials" = list(
          formula = drmTMB::bf(cbind(successes, failures) ~ x),
          family = stats::binomial()
        ),
        "positive-lognormal" = list(
          formula = drmTMB::bf(y ~ x, sigma ~ 1),
          family = drmTMB::lognormal()
        ),
        "nbinom2-dispersion" = list(
          formula = drmTMB::bf(y ~ x, sigma ~ x),
          family = drmTMB::nbinom2()
        ),
        stop("unknown Workflow G slug: ", slug)
      )
      fit <- drmTMB::drmTMB(
        spec$formula,
        family = spec$family,
        data = dat,
        engine = "julia"
      )
      cf <- stats::coef(fit)
      flat <- numeric()
      for (nm in names(cf)) {
        block <- cf[[nm]]
        flat <- c(
          flat,
          stats::setNames(as.numeric(block), paste0(nm, "_", names(block)))
        )
      }
      list(
        slug = slug,
        loglik = as.numeric(stats::logLik(fit)),
        coef = flat,
        expected_loglik = as.numeric(expected$fit$loglik),
        expected_coef = expected$coef,
        tol = expected$tol,
        converged = isTRUE(drmTMB::is_converged(fit))
      )
    },
    args = list(
      pkg = pkg,
      jl_path = jl_path,
      fixtures_root = fixtures_root,
      slug = slug,
      julia_home = julia_home
    )
  )
}

test_that("Workflow G fixture map covers the eleven admitted cells", {
  expect_length(drm_wfg_cohort(), 11L)
  for (slug in drm_wfg_cohort()) {
    expect_false(is.null(drm_wfg_case_spec(slug)), info = slug)
  }
})

test_that("live engine=julia matches DRM.jl Workflow G expected.toml", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")

  jl_path <- drm_wfg_drmjl_path()
  skip_if(!nzchar(jl_path), "DRM.jl engine path not available")
  fixtures_root <- drm_wfg_fixtures_root(jl_path)
  skip_if(
    !dir.exists(fixtures_root),
    "DRM.jl Workflow G fixtures not available"
  )
  for (slug in drm_wfg_cohort()) {
    skip_if(
      !file.exists(file.path(fixtures_root, slug, "expected.toml")),
      paste0("missing fixture: ", slug)
    )
  }

  drm_test_set_julia_home()
  failures <- character()
  for (slug in drm_wfg_cohort()) {
    res <- tryCatch(
      drm_wfg_fit_slug(slug, fixtures_root, jl_path),
      error = function(e) e
    )
    if (inherits(res, "error")) {
      failures <- c(failures, paste0(slug, ": ", conditionMessage(res)))
      next
    }
    if (!isTRUE(res$converged)) {
      failures <- c(failures, paste0(slug, ": not converged"))
      next
    }
    atol_ll <- res$tol$atol_loglik
    if (is.null(atol_ll) || !is.finite(atol_ll)) {
      atol_ll <- 1e-4
    }
    if (!drm_wfg_within(res$loglik, res$expected_loglik, rtol = 0, atol = atol_ll)) {
      failures <- c(
        failures,
        sprintf(
          "%s loglik: got=%.8g expected=%.8g atol=%g",
          slug,
          res$loglik,
          res$expected_loglik,
          atol_ll
        )
      )
    }
    rtol_coef <- res$tol$rtol_coef
    atol_coef <- res$tol$atol_coef
    if (is.null(rtol_coef) || !is.finite(rtol_coef)) {
      rtol_coef <- 1e-4
    }
    if (is.null(atol_coef) || !is.finite(atol_coef)) {
      atol_coef <- 1e-6
    }
    for (nm in names(res$expected_coef)) {
      if (!nm %in% names(res$coef)) {
        failures <- c(failures, paste0(slug, " missing coef: ", nm))
        next
      }
      if (!drm_wfg_within(
        res$coef[[nm]],
        res$expected_coef[[nm]],
        rtol = rtol_coef,
        atol = atol_coef
      )) {
        failures <- c(
          failures,
          sprintf(
            "%s coef %s: got=%.8g expected=%.8g",
            slug,
            nm,
            res$coef[[nm]],
            res$expected_coef[[nm]]
          )
        )
      }
    }
  }
  expect_true(
    length(failures) == 0L,
    info = paste(failures, collapse = "\n")
  )
})
