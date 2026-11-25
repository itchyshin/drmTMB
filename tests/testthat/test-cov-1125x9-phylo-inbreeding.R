# Pedigree inbreeding helpers in R/phylo-utils.R (not phylo tree guards in 1124d).

mini_pedigree <- function() {
  data.frame(
    id = c("base1", "base2", "offspring"),
    sire = c(NA_character_, NA_character_, "base1"),
    dam = c(NA_character_, NA_character_, "base2")
  )
}

test_that("drm_pedigree_inbreeding_parent_index() orders ancestors before descendants", {
  ped <- mini_pedigree()
  idx <- drmTMB:::drm_pedigree_inbreeding_parent_index(ped)
  expect_named(idx, c("ids", "sire", "dam"))
  expect_identical(idx$ids, ped$id)
  expect_equal(idx$sire[3], 1L)
  expect_equal(idx$dam[3], 2L)
  bad <- data.frame(id = "child", sire = "child", dam = NA_character_)
  expect_error(
    drmTMB:::drm_pedigree_inbreeding_parent_index(bad),
    "ancestors to descendants"
  )
})

test_that("Meuwissen-Luo inbreeding agrees between R and compiled walks", {
  ped <- mini_pedigree()
  F_r <- drmTMB:::drm_pedigree_inbreeding_meuwissen_luo_r(ped)
  F_c <- drmTMB:::drm_pedigree_inbreeding_meuwissen_luo(ped)
  expect_named(F_r, ped$id)
  expect_named(F_c, ped$id)
  expect_equal(F_r, F_c, tolerance = 1e-10)
  expect_equal(as.numeric(F_r["offspring"]), 0)
  expect_true(all(F_r >= 0 & F_r <= 1))
})

test_that("drm_pedigree_additive_relationship() matches inbreeding diagonal adjustment", {
  ped <- mini_pedigree()
  A <- drmTMB:::drm_pedigree_additive_relationship(ped)
  expect_equal(rownames(A), ped$id)
  expect_equal(A, t(A), tolerance = 1e-12)
  expect_true(all(diag(A) >= 1))
  expect_equal(A["offspring", "offspring"], 1)
})