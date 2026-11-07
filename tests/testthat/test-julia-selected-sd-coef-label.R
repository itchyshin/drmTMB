# Static (no Julia) pin of the selected-coefficient SD label mapping.
# `sd(id, coef = "x") ~ w` is labelled in the payload under its hashed
# `sdtarget_<hex>` block; DRM.jl returns its sole SD target under `sd`.

sd_key <- function(lhs) {
  drmTMB:::drm_julia_sd_target_block(drmTMB:::parse_sd_lhs(lhs))
}
labels_for <- function(sd_name, sd_terms = c("(Intercept)", "w")) {
  out <- list(mu = c("(Intercept)", "x"), sd_terms)
  names(out) <- c("mu", sd_name)
  out
}
engine_names <- c("mu_(Intercept)", "mu_x", "sd_(Intercept)", "sd_w")

test_that("the selected-coefficient SD target hashes the documented identity", {
  key <- sd_key(quote(sd(id, coef = "x")))
  hex <- paste(sprintf("%02x", as.integer(charToRaw("id|iid|mu|x|none"))),
               collapse = "")
  expect_identical(key, paste0("sdtarget_", hex))
  expect_identical(sd_key(quote(sd(id))), "sd")
  expect_false(identical(sd_key(quote(sd(id, coef = "(Intercept)"))), key))
})

test_that("a sole hashed SD label key is matched to the returned sd block", {
  key <- sd_key(quote(sd(id, coef = "x")))
  payload <- list(coef_labels = labels_for(key))
  expect_silent(
    drmTMB:::drm_julia_bridge_check_coef_labels(engine_names, payload)
  )
  split <- drmTMB:::drm_julia_split_coef_name(engine_names)
  expect_identical(
    names(drmTMB:::drm_julia_alias_single_sd_target_labels(
      payload$coef_labels, unique(split$dpar)
    )),
    c("mu", "sd")
  )
})

test_that("emulating the pre-fix check reproduces the live failure", {
  key <- sd_key(quote(sd(id, coef = "x")))
  testthat::local_mocked_bindings(
    drm_julia_alias_single_sd_target_labels = function(coef_labels, ...) {
      coef_labels
    },
    .package = "drmTMB"
  )
  expect_error(
    drmTMB:::drm_julia_bridge_check_coef_labels(
      engine_names, list(coef_labels = labels_for(key))
    ),
    "no payload label was built for fixed-effect dpar\\(s\\): sd"
  )
})

test_that("the alias never hides a label disagreement or an ambiguity", {
  key <- sd_key(quote(sd(id, coef = "x")))
  expect_error(
    drmTMB:::drm_julia_bridge_check_coef_labels(
      engine_names,
      list(coef_labels = labels_for(key, c("(Intercept)", "z")))
    ),
    "do not match"
  )
  expect_error(
    drmTMB:::drm_julia_bridge_check_coef_labels(
      engine_names, list(coef_labels = list(mu = c("(Intercept)", "x")))
    ),
    "no payload label was built for fixed-effect dpar\\(s\\): sd"
  )
  two <- c(labels_for(key), stats::setNames(list(c("(Intercept)", "w")),
                                            paste0(key, "0a")))
  expect_identical(
    drmTMB:::drm_julia_alias_single_sd_target_labels(two, c("mu", "sd")),
    two
  )
  hashed_engine <- c("mu_(Intercept)", "mu_x",
                     paste0(key, "_(Intercept)"), paste0(key, "_w"))
  expect_silent(
    drmTMB:::drm_julia_bridge_check_coef_labels(
      hashed_engine, list(coef_labels = labels_for(key))
    )
  )
})
