# Coverage for R/penalty.R argument guards and penalty wiring.

test_that("drm_phylo_penalty() validates sd_u and sd_alpha", {
  p <- drm_phylo_penalty(sd_u = 2, sd_alpha = 0.1)
  expect_s3_class(p, "drm_phylo_penalty")
  expect_equal(p$sd_u, 2)
  expect_equal(p$rate, -log(0.1) / 2, tolerance = 1e-12)
  expect_error(drm_phylo_penalty(sd_u = 0), "sd_u")
  expect_error(drm_phylo_penalty(sd_u = 1, sd_alpha = 0), "sd_alpha")
  expect_error(drm_phylo_penalty(sd_u = 1, sd_alpha = 1), "sd_alpha")
  expect_error(drm_phylo_penalty(sd_u = 1, cor_sd = -1), "cor_sd")
})

test_that("drm_phylo_penalty() accepts optional cor_sd", {
  p <- drm_phylo_penalty(sd_u = 1, sd_alpha = 0.05, cor_sd = 0.5)
  expect_equal(p$cor_sd, 0.5)
  p2 <- drm_phylo_penalty(sd_u = 1, sd_alpha = 0.05, cor_sd = NULL)
  expect_null(p2$cor_sd)
})

test_that("drm_parse_phylo_penalty() accepts NULL or validated objects", {
  expect_null(drmTMB:::drm_parse_phylo_penalty(NULL))
  pen <- drm_phylo_penalty()
  expect_identical(drmTMB:::drm_parse_phylo_penalty(pen), pen)
  expect_error(drmTMB:::drm_parse_phylo_penalty(list(a = 1)), "drm_phylo_penalty")
})

test_that("drm_apply_phylo_penalty_spec() wires zero penalty without phylo", {
  spec <- list(
    structured = list(phylo_mu = list(has = FALSE)),
    start = list(log_sd_phylo = numeric()),
    tmb_data = list(has_sd_phylo_model = 0L)
  )
  out <- drmTMB:::drm_apply_phylo_penalty_spec(spec, NULL)
  expect_identical(out$tmb_data$penalize_phylo, 0L)
  expect_length(out$tmb_data$phylo_sd_penalty_rate, 0L)
})

test_that("drm_apply_phylo_penalty_spec() errors without phylo or with cor_sd alone", {
  spec <- list(
    structured = list(phylo_mu = list(has = FALSE)),
    start = list(log_sd_phylo = 0.1),
    tmb_data = list(has_sd_phylo_model = 0L)
  )
  expect_error(
    drmTMB:::drm_apply_phylo_penalty_spec(spec, drm_phylo_penalty()),
  "phylogenetic term"
  )
  spec$structured$phylo_mu$has <- TRUE
  spec$start$log_sd_phylo <- 0.1
  expect_error(
    drmTMB:::drm_apply_phylo_penalty_spec(
      spec,
      drm_phylo_penalty(cor_sd = 0.5)
    ),
    class = "drm_phylo_cor_penalty_needs_two_sd"
  )
})