test_that("pedigree A-inverse matches the dense inverse it replaces", {
  ped <- data.frame(
    id = c("a", "b", "c", "d", "e", "f"),
    dam = c(NA, NA, "b", "b", "d", "d"),
    sire = c(NA, "a", "a", "a", "c", "e"),
    stringsAsFactors = FALSE
  )

  A <- drm_pedigree_additive_relationship(ped)
  expected <- solve(A)

  precision <- drm_pedigree_relatedness_precision(
    ped,
    group = ped$id,
    object = "pedigree"
  )
  got <- as.matrix(precision$precision)

  expect_equal(dimnames(got), dimnames(expected))
  expect_equal(got, expected, tolerance = 1e-8)
})

test_that("pedigree A-inverse reports the log determinant of the precision", {
  ped <- data.frame(
    id = c("a", "b", "c", "d", "e"),
    dam = c(NA, NA, "b", "b", "d"),
    sire = c(NA, "a", "a", "a", "c"),
    stringsAsFactors = FALSE
  )

  A <- drm_pedigree_additive_relationship(ped)
  precision <- drm_pedigree_relatedness_precision(
    ped,
    group = ped$id,
    object = "pedigree"
  )

  expect_equal(
    precision$log_det_precision,
    -determinant(A, logarithm = TRUE)$modulus[[1]],
    tolerance = 1e-8
  )
})

test_that("pedigree A-inverse keeps the covariance-input diagnostic label", {
  ped <- data.frame(
    id = c("a", "b", "c"),
    dam = c(NA, NA, "b"),
    sire = c(NA, NA, "a"),
    stringsAsFactors = FALSE
  )

  precision <- drm_pedigree_relatedness_precision(
    ped,
    group = ped$id,
    object = "pedigree"
  )

  expect_identical(precision$matrix_type, "covariance")
})

test_that("pedigree A-inverse stores O(n) nonzeros, not O(n^2)", {
  set.seed(11)
  n_founder <- 20L
  n <- 300L
  ids <- sprintf("i%03d", seq_len(n))
  dam <- rep(NA_character_, n)
  sire <- rep(NA_character_, n)
  # Unrelated founders, then each animal takes two distinct earlier parents:
  # a connected pedigree whose dense A fills in but whose A^-1 stays O(n).
  for (i in (n_founder + 1L):n) {
    parents <- sample.int(i - 1L, 2L)
    dam[[i]] <- ids[[parents[[1L]]]]
    sire[[i]] <- ids[[parents[[2L]]]]
  }
  ped <- data.frame(id = ids, dam = dam, sire = sire, stringsAsFactors = FALSE)

  precision <- drm_pedigree_relatedness_precision(
    ped,
    group = ped$id,
    object = "pedigree"
  )

  nnz <- Matrix::nnzero(precision$precision)
  # Quaas assembly touches at most 9 entries per animal; the dense chol2inv
  # path this replaces leaves ~n^2 numerically-nonzero entries.
  expect_lt(nnz, 9L * n)
  expect_lt(nnz, n^2 / 10)
})
