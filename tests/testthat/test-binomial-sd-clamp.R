test_that("latent SD clamp detection is separate from residual sigma", {
  tmb_data <- list(use_logsigma_clamp = 1L, logsigma_clamp = c(-2, 2, 1))
  report <- list(log_sd_mu_group = c(0.2, 2.6), log_sigma = 0.1)
  # The existing default is also used by residual-sigma accessors: a latent
  # clamp must not make them claim residual sigma was clamped.
  expect_null(drm_logsigma_clamp_active(report, tmb_data))

  spec <- list(model_type = "binomial", tmb_data = tmb_data,
               random_scale = list(mu = list(n_models = 1L),
                                   phylo = list(n_models = 0L)))
  fields <- drm_active_logsigma_clamp_fields(spec)
  expect_true("log_sd_mu_group" %in% fields)
  expect_false("log_sigma" %in% fields)
  info <- drm_logsigma_clamp_active(report, tmb_data, fields = fields)
  expect_equal(info$arm, "upper")
  expect_equal(info$field, "log_sd_mu_group")
  expect_equal(info$kind, "latent random-effect SD")

  obj <- list(report = function(...) report)
  expect_warning(drm_warn_if_clamp_active(obj, spec),
                 "latent random-effect", class = "drmTMB_clamp_active_warning")
  fit <- list(model = spec, obj = obj,
              tmb_state = list(last.par.best = 0))
  row <- check_logsigma_clamp_active(fit)
  expect_equal(row$status, "warning")
  expect_match(row$message, "latent random-effect SD", fixed = TRUE)
  expect_false(grepl("residual sigma", row$message, fixed = TRUE))
})

test_that("lower latent and phylogenetic SD clamp arms are diagnosed", {
  tmb_data <- list(use_logsigma_clamp = 1L, logsigma_clamp = c(-2, 2, 1))
  ordinary <- list(model_type = "binomial", tmb_data = tmb_data,
                   random_scale = list(mu = list(n_models = 1L),
                                       phylo = list(n_models = 0L)))
  lower <- list(report = function(...) list(log_sd_mu_group = -2.7))
  row <- check_logsigma_clamp_active(list(model = ordinary, obj = lower,
              tmb_state = list(last.par.best = 0)))
  expect_equal(row$status, "note")
  expect_match(row$message, "latent random-effect SD", fixed = TRUE)
  expect_false(grepl("tau = 0", row$message, fixed = TRUE))

  phylo <- list(model_type = "beta", tmb_data = tmb_data,
                random_scale = list(mu = list(n_models = 0L),
                                    phylo = list(n_models = 1L)))
  expect_true("log_sd_phylo_group" %in% drm_active_logsigma_clamp_fields(phylo))
  info <- drm_logsigma_clamp_active(
    list(log_sd_phylo_group = 2.4), tmb_data,
    fields = drm_active_logsigma_clamp_fields(phylo))
  expect_equal(info$kind, "latent random-effect SD")
  expect_equal(info$arm, "upper")
})

test_that("binomial models without latent SD keep clamp diagnostics inapplicable", {
  spec <- list(model_type = "binomial",
               tmb_data = list(use_logsigma_clamp = 1L,
                               logsigma_clamp = c(-2, 2, 1)),
               random_scale = list(mu = list(n_models = 0L),
                                   phylo = list(n_models = 0L)))
  expect_length(drm_active_logsigma_clamp_fields(spec), 0L)
  obj <- list(report = function(...) list(log_sd_mu_group = 4))
  expect_false(drm_warn_if_clamp_active(obj, spec))
  row <- check_logsigma_clamp_active(list(model = spec, obj = obj,
              tmb_state = list(last.par.best = 0)))
  expect_equal(row$status, "ok")
})

test_that("binomial SD starts warn only when raw group predictor leaves band", {
  dat <- binomial_sd_fixture(groups = 12L, repeats = 4L)$data
  spec <- drm_build_binomial_spec(bf(y ~ x + (1 | id), sd(id) ~ w), dat)
  spec$tmb_data$use_logsigma_clamp <- 1L
  spec$tmb_data$logsigma_clamp <- c(-2, 2, 1)

  expect_no_warning(drm_warn_if_start_saturates_logsigma_clamp(
    spec, list(beta_sd_mu = c(0, 0))))
  expect_warning(drm_warn_if_start_saturates_logsigma_clamp(
    spec, list(beta_sd_mu = c(4, 0))),
    "latent random-effect", class = "drmTMB_start_clamp_saturated_warning")
  expect_warning(drm_warn_if_start_saturates_logsigma_clamp(
    spec, list(beta_sd_mu = c(-4, 0))),
    "latent random-effect", class = "drmTMB_start_clamp_saturated_warning")

  spec$tmb_data$use_logsigma_clamp <- 0L
  expect_no_warning(drm_warn_if_start_saturates_logsigma_clamp(
    spec, list(beta_sd_mu = c(4, 0))))
})

test_that("residual sigma start diagnostics retain their existing gate", {
  spec <- list(model_type = "gaussian", X = list(sigma = matrix(1, 3, 1)),
               start = list(beta_sigma = 0),
               tmb_data = list(use_logsigma_clamp = 1L,
                               logsigma_clamp = c(-2, 2, 1)),
               random_scale = list(mu = list(n_models = 0L),
                                   phylo = list(n_models = 0L)))
  expect_no_warning(drm_warn_if_start_saturates_logsigma_clamp(
    spec, list(beta_sigma = 0)))
  expect_warning(drm_warn_if_start_saturates_logsigma_clamp(
    spec, list(beta_sigma = 4)),
    "log(sigma)", class = "drmTMB_start_clamp_saturated_warning")
})

test_that("stored binomial fit diagnoses frozen latent SD report without mutation", {
  skip_if(identical(Sys.getenv("DRMTMB_SOURCE_ASSEMBLY"), "1"),
          "source-only assembly uses the installed, older TMB binary")
  dat <- binomial_sd_fixture(groups = 12L, repeats = 4L, trials = 4L)$data
  fit <- suppressWarnings(drmTMB(
    bf(cbind(y, failure) ~ x + (1 | id), sd(id) ~ w),
    stats::binomial(), dat,
    control = drm_control(se = FALSE, logsigma_clamp = c(-2, 2))
  ))
  expect_true(is.list(fit$obj))
  frozen <- fit
  p <- frozen$tmb_state$last.par.best
  idx <- which(names(p) == "beta_sd_mu")
  expect_length(idx, 2L)
  p[idx[[1L]]] <- 4
  frozen$tmb_state$last.par.best <- p

  raw <- frozen$obj$report(p)$log_sd_mu_group
  expect_true(is.numeric(raw) && length(raw) > 0L)
  expect_true(any(raw > 2))
  before <- frozen$obj$env$last.par
  row <- check_logsigma_clamp_active(frozen)
  expect_equal(row$status, "warning")
  expect_match(row$message, "latent random-effect SD", fixed = TRUE)
  expect_equal(frozen$obj$env$last.par, before)
})
