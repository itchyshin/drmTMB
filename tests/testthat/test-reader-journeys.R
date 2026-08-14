test_that("the ten native reader journeys complete their generic post-fit smoke", {
  skip_if_not_installed("ape")

  audit_env <- new.env(parent = globalenv())
  audit_out <- tempfile(fileext = ".tsv")
  withr::local_envvar(DRMTMB_READER_AUDIT_OUT = audit_out)
  source(testthat::test_path("..", "..", "tools", "run-reader-workflow-audit.R"), local = audit_env)

  results <- utils::read.delim(audit_out, check.names = FALSE)
  expect_equal(nrow(results), 10L)
  expect_setequal(
    results$workflow,
    c(
      "continuous_location_scale", "count_with_effort", "denominator_proportion",
      "ordinal_condition", "boundary_proportion", "phylogenetic_trait",
      "spatial_site_effect", "bivariate_traits", "meta_analysis", "missing_response"
    )
  )
  expect_true(all(results$fit == "pass"), info = paste(results$first_blocker, collapse = "\n"))
  expect_true(all(results$diagnostics == "pass"), info = paste(results$first_blocker, collapse = "\n"))
  expect_true(all(results$report_output == "pass"), info = paste(results$first_blocker, collapse = "\n"))
  expect_true(all(grepl("generic post-fit smoke", results$report_artifact, fixed = TRUE)))
})

test_that("the reader audit does not call warning diagnostics a pass", {
  audit_path <- testthat::test_path("..", "..", "tools", "run-reader-workflow-audit.R")
  audit_lines <- readLines(audit_path)
  first_workflow <- grep("^results <- list", audit_lines)[1L]
  audit_env <- new.env(parent = globalenv())
  eval(parse(text = audit_lines[seq_len(first_workflow - 1L)]), envir = audit_env)
  warning_diagnostic <- structure(data.frame(status = "warning"), ok = FALSE)
  expect_false(audit_env$reader_diagnostic_pass(list(ok = TRUE, value = warning_diagnostic)))
  expect_false(audit_env$reader_diagnostic_pass(list(ok = FALSE, value = warning_diagnostic)))
  expect_true(audit_env$reader_diagnostic_pass(list(ok = TRUE, value = structure(data.frame(status = "ok"), ok = TRUE))))
})

test_that("ordinal probabilities are response-scale probabilities, not raw thresholds", {
  set.seed(20260813)
  dat <- data.frame(
    x = seq(-1, 1, length.out = 60),
    score = ordered(sample(c("low", "medium", "high"), 60, replace = TRUE),
      levels = c("low", "medium", "high"))
  )
  fit <- drmTMB(bf(score ~ x), cumulative_logit(), data = dat)
  grid <- prediction_grid(fit, focal = "x", at = list(x = c(-.5, 0, .5)))
  distribution <- fitted_distribution(fit, newdata = grid)
  probability <- vapply(seq_along(levels(dat$score)), function(k) {
    distribution$d(rep(k, nrow(grid)))
  }, numeric(nrow(grid)))

  expect_equal(nrow(probability), nrow(grid))
  expect_true(all(is.finite(probability) & probability >= 0 & probability <= 1))
  expect_equal(rowSums(probability), rep(1, nrow(grid)), tolerance = 1e-8)
  targets <- profile_targets(fit)
  expect_true(all(!targets$profile_ready[grepl("^ordinal:theta_ord:", targets$parm)]))
  expect_true(all(targets$profile_ready[grepl("^ordinal:cutpoint:", targets$parm)]))
})

test_that("missing-response rows retain fitted values but not residuals", {
  set.seed(20260813)
  dat <- data.frame(x = seq(-1, 1, length.out = 40))
  dat$y <- .5 + .7 * dat$x + stats::rnorm(nrow(dat), sd = .2)
  missing <- c(5L, 16L, 29L)
  dat$y[missing] <- NA_real_
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1), gaussian(), data = dat,
    missing = miss_control(response = "include"), control = drm_control(se = FALSE)
  )

  expect_equal(nobs(fit), nrow(dat) - length(missing))
  expect_length(fitted(fit), nrow(dat))
  expect_true(all(is.na(residuals(fit)[missing])))
  expect_true(all(is.finite(fitted(fit)[missing])))
})

test_that("bivariate reader output separates response-scale rho12 from its link", {
  set.seed(20260813)
  n <- 80L
  dat <- data.frame(x = seq(-1, 1, length.out = n))
  latent_rho <- 0.2 + 0.4 * dat$x
  rho <- 0.999999 * tanh(latent_rho)
  e1 <- stats::rnorm(n)
  dat$y1 <- 0.4 * dat$x + e1
  dat$y2 <- -0.3 * dat$x + rho * e1 + sqrt(1 - rho^2) * stats::rnorm(n)
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~x),
    family = c(gaussian(), gaussian()), data = dat
  )

  grid <- prediction_grid(fit, focal = "x", at = list(x = c(-.5, 0, .5)))
  response_rho <- rho12(fit, newdata = grid)
  link_rho <- rho12(fit, newdata = grid, type = "link")
  pair <- corpairs(fit, conf.int = TRUE)
  expect_length(response_rho, nrow(grid))
  expect_true(all(is.finite(response_rho) & abs(response_rho) < 1))
  expect_equal(response_rho, 0.999999 * tanh(link_rho), tolerance = 1e-12)
  expect_identical(pair$conf.status, "derived_interval_unavailable")
  expect_identical(pair$level, "residual")
})

test_that("structured and meta-analysis reader extractors retain their meaning", {
  skip_if_not_installed("ape")
  set.seed(20260813)
  tree <- ape::chronos(ape::rtree(8), lambda = 1)
  species <- factor(rep(tree$tip.label, each = 3), levels = tree$tip.label)
  phylo_dat <- data.frame(
    species = species,
    x = rep(c(-1, 0, 1), 8)
  )
  phylo_dat$y <- 0.5 * phylo_dat$x + rep(stats::rnorm(8, sd = .25), each = 3) +
    stats::rnorm(nrow(phylo_dat), sd = .2)
  phylo_fit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1), gaussian(), data = phylo_dat
  )
  deviations <- ranef(phylo_fit)
  targets <- profile_targets(phylo_fit)
  expect_true(length(deviations$phylo_mu$values) > 0L)
  expect_true(any(grepl("phylo", targets$parm, fixed = TRUE)))

  vi <- rep(.08, 24)
  meta_fit <- drmTMB(
    bf(yi ~ 1 + meta_V(V = vi), sigma ~ 1), gaussian(),
    data = data.frame(yi = stats::rnorm(24, .2, sqrt(vi + .06)), vi = vi)
  )
  expect_true(all(is.finite(sigma(meta_fit)) & sigma(meta_fit) > 0))
})

test_that("fitted means are not silently substituted with lognormal mu predictions", {
  set.seed(20260813)
  dat <- data.frame(x = seq(-1, 1, length.out = 50))
  dat$y <- exp(.2 + .5 * dat$x + stats::rnorm(nrow(dat), sd = .35))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), lognormal(), data = dat)
  mu <- predict(fit, dpar = "mu")
  response_mean <- fitted(fit)
  expect_false(isTRUE(all.equal(mu, response_mean)))
  expect_equal(response_mean, exp(predict(fit, dpar = "mu", type = "link") + .5 * sigma(fit)^2))
})
