# Whole-package coverage lane w3 (ranks 4–6, unclaimed p-r / parse / phylo helpers).
# Fit-free characterisation tests only.

test_that("profile_controls_label() summarises profile arguments", {
  f <- drmTMB:::profile_controls_label
  expect_identical(f(list()), "TMB defaults")
  label <- f(list(ystep = 0.5, ytol = 2))
  expect_match(label, "ystep=0.5")
  expect_match(label, "ytol=2")
  long <- f(list(vals = seq_len(6)))
  expect_match(label_long <- f(list(vals = seq_len(6))), "vals=1/2/3/4/...")
  expect_false(grepl("6", label_long))
})

test_that("profile_transform_values() applies each documented transformation", {
  f <- drmTMB:::profile_transform_values
  tgt <- function(trans, tmb_parameter = "eta") {
    list(transformation = trans, tmb_parameter = tmb_parameter)
  }
  expect_identical(f(1:3, tgt("linear_predictor")), 1:3)
  expect_identical(f(1:3, tgt("ordered_cutpoint")), 1:3)
  expect_equal(f(c(0, log(2)), tgt("exp")), c(1, 2))
  expect_equal(f(0, tgt("plogis")), 0.5)
  re <- f(0, tgt("tanh", "eta_cor_re"))
  expect_equal(re, drmTMB:::DRM_RE_CORR_GUARD * tanh(0))
  phylo <- f(0, tgt("tanh", "eta_cor_phylo"))
  expect_equal(phylo, drmTMB:::DRM_CORR_GUARD * tanh(0))
  expect_equal(f(0, tgt("rho12_tanh")), drmTMB:::rho_response(0))
  expect_identical(f(pi, tgt("unknown_mode")), pi)
})

test_that("profile_plot_caption() formats source and elapsed passes", {
  f <- drmTMB:::profile_plot_caption
  data <- data.frame(
    profile_source = "endpoint",
    profile_pass = c("coarse", "profile", "dense"),
    elapsed = c(0.1, 0.2, 0.05),
    profile_controls = c("a", "b", "c"),
    stringsAsFactors = FALSE
  )
  cap <- f(data)
  expect_match(cap, "^Source: endpoint\\.")
  expect_match(cap, "coarse 0.10s \\(a\\)")
  expect_match(cap, "profile 0.20s \\(b\\)")
  expect_match(cap, "dense 0.05s \\(c\\)")

  multi <- rbind(data, data[1L, , drop = FALSE])
  multi$profile_source[2L] <- "other"
  expect_match(f(multi), "Source: TMB::tmbprofile")
})

test_that("wald_sd_target_is_location_axis() classifies mu versus sigma families", {
  f <- drmTMB:::wald_sd_target_is_location_axis
  row <- function(dpar) data.frame(dpar = I(list(dpar)), stringsAsFactors = FALSE)
  expect_true(f(row("mu")))
  expect_true(f(row("mu1")))
  expect_false(f(row("sigma")))
  expect_false(f(row("sigma2")))
  expect_false(f(row(NA_character_)))
})

test_that("structured_sd_group_count() reads phylo_mu group levels", {
  f <- drmTMB:::structured_sd_group_count
  bare <- list(model = list(structured = list(phylo_mu = list(has = FALSE))))
  expect_identical(f(bare), NA_real_)
  interaction <- list(
    model = list(
      structured = list(
        phylo_mu = list(
          has = TRUE,
          type = "phylo_interaction",
          group_levels = c("a", "b")
        )
      )
    )
  )
  expect_identical(f(interaction), NA_real_)
  spatial <- list(
    model = list(
      structured = list(
        phylo_mu = list(
          has = TRUE,
          type = "spatial",
          group_levels = c("s1", "s2", "s3")
        )
      )
    )
  )
  expect_identical(f(spatial), 3)
  empty_groups <- list(
    model = list(
      structured = list(
        phylo_mu = list(has = TRUE, type = "phylo", group_levels = character())
      )
    )
  )
  expect_identical(f(empty_groups), NA_real_)
})

test_that("structured_sd_term_matches_label() matches exact, suffix, and signatures", {
  f <- drmTMB:::structured_sd_term_matches_label
  expect_false(f(NA_character_, "phylo(id)"))
  expect_false(f("phylo(id)", NA_character_))
  expect_false(f("", "phylo(id)"))
  expect_true(f("phylo(species)", "phylo(species)"))
  expect_true(f("animal(id)", "animal(id)"))
  expect_false(f("sd_phylo(species)", "species"))
  expect_false(f("animal(id)", "phylo(species)"))
})

test_that("drm_subset_model_columns() keeps present variables only", {
  f <- drmTMB:::drm_subset_model_columns
  d <- data.frame(y = 1:2, x = 3:4)
  out <- f(d, c("y", "x", "y"))
  expect_identical(out, d)
  expect_error(f(d, "z"), "Missing")
  expect_error(f(d, "z"), "z")
})

test_that("drm_unsupported_dpar_hint() points to bf() syntax", {
  hint <- drmTMB:::drm_unsupported_dpar_hint()
  expect_type(hint, "character")
  expect_match(hint, "bf")
  expect_match(hint, "sigma")
})

test_that("is_random_scale_lhs_entry() detects sd() formulas", {
  f <- drmTMB:::is_random_scale_lhs_entry
  scale_entry <- list(lhs = quote(sd(id)), corpair = NULL, dpar = "sigma")
  plain <- list(lhs = NULL, corpair = NULL, dpar = "sigma")
  expect_true(f(scale_entry))
  expect_false(f(plain))
})

test_that("parse_corpair_string_arg() validates corpair string arguments", {
  f <- drmTMB:::parse_corpair_string_arg
  args <- list("p", "mu1")
  names <- c("level", "from")
  expect_identical(f(args, names, "missing"), NA_character_)
  expect_identical(f(args, names, "level"), "p")
  expect_error(f(list(1L), names, "level"), "single string")
  expect_error(f(list(NA_character_), names, "level"), "single string")
  expect_error(f(list(c("a", "b")), names, "level"), "single string")
})

test_that("drm_reject_smooth_terms() refuses mgcv-style smooth markers", {
  f <- drmTMB:::drm_reject_smooth_terms
  ok <- bf(y ~ x)
  expect_invisible(f(ok))
  bad <- bf(y ~ s(x))
  expect_error(f(bad), "Smooth terms are not supported")
  expect_error(f(bad), "s")
})

test_that("validate_phylo_species() accepts NULL and rejects malformed labels", {
  f <- drmTMB:::validate_phylo_species
  expect_null(f(NULL, c("a", "b")))
  expect_identical(f(c("a", "a", "b"), c("a", "b")), c("a", "b"))
  expect_error(f(character(), c("a")), "at least one")
  expect_error(f(c("a", NA), c("a", "b")), "missing or empty")
  expect_error(f(c("a", ""), c("a", "b")), "missing or empty")
  expect_error(f("c", c("a", "b")), "Missing tip label")
})

test_that("phylo_node_depths() assigns root-to-tip distances", {
  f <- drmTMB:::phylo_node_depths
  edge <- cbind(c(3L, 3L), c(1L, 2L))
  len <- c(2, 3)
  depths <- f(edge, len, n_total = 3L, root = 3L)
  expect_identical(depths[[3L]], 0)
  expect_identical(depths[[1L]], 2)
  expect_identical(depths[[2L]], 3)
})