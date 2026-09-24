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

test_that("Meuwissen-Luo F matches dense diag(A) - 1", {
  ped <- data.frame(
    id = c("a", "b", "c", "d", "e", "f"),
    dam = c(NA, NA, "b", "b", "d", "d"),
    sire = c(NA, "a", "a", "a", "c", "e"),
    stringsAsFactors = FALSE
  )
  A <- drm_pedigree_additive_relationship(ped)
  ordered <- rownames(A)
  ped_ord <- ped[match(ordered, ped$id), , drop = FALSE]
  F_ml <- drm_pedigree_inbreeding_meuwissen_luo(ped_ord)
  expect_equal(unname(F_ml), unname(diag(A) - 1), tolerance = 1e-8)
})

test_that("Meuwissen-Luo F matches dense F on a random connected pedigree", {
  set.seed(17)
  n_founder <- 12L
  n <- 80L
  ids <- sprintf("i%03d", seq_len(n))
  dam <- rep(NA_character_, n)
  sire <- rep(NA_character_, n)
  for (i in (n_founder + 1L):n) {
    parents <- sample.int(i - 1L, 2L)
    dam[[i]] <- ids[[parents[[1L]]]]
    sire[[i]] <- ids[[parents[[2L]]]]
  }
  ped <- data.frame(id = ids, dam = dam, sire = sire, stringsAsFactors = FALSE)
  A <- drm_pedigree_additive_relationship(ped)
  ped_ord <- ped[match(rownames(A), ped$id), , drop = FALSE]
  F_ml <- drm_pedigree_inbreeding_meuwissen_luo(ped_ord)
  expect_equal(unname(F_ml), unname(diag(A) - 1), tolerance = 1e-8)
  expect_equal(
    as.matrix(drm_pedigree_sparse_precision(ped)),
    as.matrix(drm_pedigree_sparse_precision_dense_F(ped)),
    tolerance = 1e-8
  )
})

test_that("Meuwissen-Luo F is zero with an unknown parent and follows selfing", {
  one_parent <- data.frame(
    id = c("a", "b"),
    dam = c(NA, "a"),
    sire = c(NA, NA),
    stringsAsFactors = FALSE
  )
  A_one <- drm_pedigree_additive_relationship(one_parent)
  ped_one <- one_parent[match(rownames(A_one), one_parent$id), , drop = FALSE]
  expect_equal(
    unname(drm_pedigree_inbreeding_meuwissen_luo(ped_one)),
    unname(diag(A_one) - 1),
    tolerance = 1e-8
  )
  expect_equal(unname(drm_pedigree_inbreeding_meuwissen_luo(ped_one)), c(0, 0))

  selfing <- data.frame(
    id = c("f", "s1", "s2", "s3"),
    dam = c(NA, "f", "s1", "s2"),
    sire = c(NA, "f", "s1", "s2"),
    stringsAsFactors = FALSE
  )
  A_self <- drm_pedigree_additive_relationship(selfing)
  ped_self <- selfing[match(rownames(A_self), selfing$id), , drop = FALSE]
  F_ml <- drm_pedigree_inbreeding_meuwissen_luo(ped_self)
  expect_equal(unname(F_ml), c(0, 0.5, 0.75, 0.875), tolerance = 1e-8)
  expect_equal(unname(F_ml), unname(diag(A_self) - 1), tolerance = 1e-8)
})

test_that("Meuwissen-Luo F is unchanged if sire and dam labels swap", {
  ped <- data.frame(
    id = c("a", "b", "c"),
    dam = c(NA, NA, "b"),
    sire = c(NA, NA, "a"),
    stringsAsFactors = FALSE
  )
  swapped <- data.frame(
    id = ped$id,
    dam = ped$sire,
    sire = ped$dam,
    stringsAsFactors = FALSE
  )
  A <- drm_pedigree_additive_relationship(ped)
  ped_ord <- ped[match(rownames(A), ped$id), , drop = FALSE]
  sw_ord <- swapped[match(rownames(A), swapped$id), , drop = FALSE]
  expect_equal(
    unname(drm_pedigree_inbreeding_meuwissen_luo(ped_ord)),
    unname(drm_pedigree_inbreeding_meuwissen_luo(sw_ord)),
    tolerance = 1e-8
  )
  expect_equal(
    as.matrix(drm_pedigree_sparse_precision(ped)),
    as.matrix(drm_pedigree_sparse_precision(swapped)),
    tolerance = 1e-8
  )
})

test_that("animal fit matches the dense-F Quaas route on coef and logLik", {
  ped <- data.frame(
    id = c("a", "b", "c", "d", "e", "f"),
    dam = c(NA, NA, "b", "b", "d", "d"),
    sire = c(NA, "a", "a", "a", "c", "e"),
    stringsAsFactors = FALSE
  )
  set.seed(1424)
  dat <- data.frame(
    id = ped$id,
    x = c(0.2, -0.4, 0.1, 0.3, -0.2, 0.0),
    y = c(0.8, 1.1, 0.4, 1.6, 0.9, 1.3)
  )
  ns <- asNamespace("drmTMB")
  ml_fun <- get("drm_pedigree_relatedness_precision", envir = ns)
  dense_fun <- function(
    pedigree,
    group,
    object = "pedigree",
    group_name = "id"
  ) {
    Ainv <- drm_pedigree_sparse_precision_dense_F(pedigree, object = object)
    drm_known_relatedness_precision(
      Ainv,
      group = group,
      matrix_type = "precision",
      marker = "animal",
      object = object,
      group_name = group_name,
      reported_matrix_type = "covariance"
    )
  }
  on.exit(
    utils::assignInNamespace(
      "drm_pedigree_relatedness_precision",
      ml_fun,
      ns = "drmTMB"
    ),
    add = TRUE
  )
  utils::assignInNamespace(
    "drm_pedigree_relatedness_precision",
    dense_fun,
    ns = "drmTMB"
  )
  fit_dense <- drmTMB(
    bf(y ~ x + animal(1 | id, pedigree = ped), sigma ~ 1),
    data = dat
  )
  utils::assignInNamespace(
    "drm_pedigree_relatedness_precision",
    ml_fun,
    ns = "drmTMB"
  )
  fit_ml <- drmTMB(
    bf(y ~ x + animal(1 | id, pedigree = ped), sigma ~ 1),
    data = dat
  )
  expect_equal(coef(fit_ml, "mu"), coef(fit_dense, "mu"), tolerance = 1e-8)
  expect_equal(coef(fit_ml, "sigma"), coef(fit_dense, "sigma"), tolerance = 1e-8)
  expect_equal(
    as.numeric(stats::logLik(fit_ml)),
    as.numeric(stats::logLik(fit_dense)),
    tolerance = 1e-8
  )
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
