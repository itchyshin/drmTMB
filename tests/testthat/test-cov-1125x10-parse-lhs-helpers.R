# Coverage shard cursor-cloud-1125x10: parse-formula LHS classification helpers.

test_that("is_nonlocation_dpar_lhs distinguishes location responses", {
  expect_false(drmTMB:::is_nonlocation_dpar_lhs(quote(y)))
  expect_false(drmTMB:::is_nonlocation_dpar_lhs(quote(mu)))
  expect_false(drmTMB:::is_nonlocation_dpar_lhs(quote(mu1)))
  expect_true(drmTMB:::is_nonlocation_dpar_lhs(quote(sigma)))
  expect_true(drmTMB:::is_nonlocation_dpar_lhs(quote(sd(id))))
})

test_that("is_sd_lhs and is_random_scale_lhs recognise sd markers", {
  expect_true(drmTMB:::is_sd_lhs(quote(sd(g))))
  expect_true(drmTMB:::is_sd_lhs(quote(sd1(g))))
  expect_false(drmTMB:::is_sd_lhs(quote(sigma)))
  expect_true(drmTMB:::is_random_scale_lhs(quote(sd(g))))
  expect_true(drmTMB:::is_random_scale_lhs(quote(sd_phylo(sp))))
  expect_false(drmTMB:::is_random_scale_lhs(quote(corpair(a))))
})

test_that("random_scale_lhs_function normalises deprecated phylo spellings", {
  expect_identical(
    drmTMB:::random_scale_lhs_function(quote(sd(id))),
    "sd"
  )
  expect_identical(
    drmTMB:::random_scale_lhs_function(quote(sd_phylo(id))),
    "sd_phylo"
  )
  funs <- drmTMB:::random_scale_lhs_functions()
  expect_true("sd" %in% funs)
  expect_true("sd1" %in% funs)
  expect_true("sd_phylo1" %in% funs)
})

test_that("is_corpair_lhs matches corpair() left-hand sides", {
  expect_true(drmTMB:::is_corpair_lhs(quote(corpair(id))))
  expect_false(drmTMB:::is_corpair_lhs(quote(sd(id))))
})

test_that("canonicalize_sd_lhs_fun records phylogenetic level metadata", {
  expect_warning(
    canon <- drmTMB:::canonicalize_sd_lhs_fun("sd_phylo", NA),
    "deprecated"
  )
  expect_identical(canon$fun, "sd_phylo")
  expect_identical(canon$level, "phylogenetic")
  canon2 <- drmTMB:::canonicalize_sd_lhs_fun("sd", "phylogenetic")
  expect_identical(canon2$fun, "sd_phylo")
  expect_identical(canon2$level, "phylogenetic")
})

test_that("is_random_scale_lhs_entry flags sd left-hand sides in entries", {
  entry <- list(
    lhs = quote(sd(id)),
    corpair = NULL,
    dpar = "mu"
  )
  expect_true(drmTMB:::is_random_scale_lhs_entry(entry))
  plain <- list(lhs = quote(y), corpair = NULL, dpar = "mu")
  expect_false(drmTMB:::is_random_scale_lhs_entry(plain))
})

test_that("structured_marker_names lists implemented markers", {
  markers <- drmTMB:::structured_marker_names()
  expect_type(markers, "character")
  expect_true("spatial" %in% markers)
  expect_true("phylo" %in% markers)
  expect_true("animal" %in% markers)
})

test_that("structured_marker_call_name extracts the top-level call", {
  expr <- quote(spatial(1 | site, mesh = mesh_obj))
  expect_identical(
    drmTMB:::structured_marker_call_name(expr),
    "spatial"
  )
  expect_true(
    drmTMB:::is_structured_marker_call(expr, "spatial")
  )
  expect_false(
    drmTMB:::is_structured_marker_call(expr, "phylo")
  )
})