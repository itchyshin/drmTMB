# Characterisation tests for the internal pedigree and known-precision helpers
# in R/phylo-utils.R. These are normally reached only through animal() and
# relmat() fits; here they are called directly so the abort branches and edge
# cases are checked without fitting a model.

edge_pedigree <- function() {
  # Founders are coded three ways: NA, "0" and "". Rows are in valid order.
  # c and d are full sibs; e is their offspring (full-sib mating, F(e) = 0.25).
  data.frame(
    id = c("a", "b", "x", "c", "d", "e", "f", "g"),
    dam = c(NA, "0", "", "b", "b", "d", "e", "e"),
    sire = c("", NA, "0", "a", "a", "c", "x", "d"),
    stringsAsFactors = FALSE
  )
}

test_that("drm_standardize_pedigree returns id, dam, sire with NA founders", {
  ped <- drmTMB:::drm_standardize_pedigree(edge_pedigree())

  expect_s3_class(ped, "data.frame")
  expect_identical(names(ped), c("id", "dam", "sire"))
  expect_identical(ped$id, c("a", "b", "x", "c", "d", "e", "f", "g"))
  expect_true(all(vapply(ped, is.character, logical(1))))
  expect_identical(ped$dam, c(NA, NA, NA, "b", "b", "d", "e", "e"))
  expect_identical(ped$sire, c(NA, NA, NA, "a", "a", "c", "x", "d"))

  # Extra columns are dropped and row order is preserved.
  extra <- edge_pedigree()
  extra$sex <- "u"
  extra <- extra[rev(seq_len(nrow(extra))), ]
  ped2 <- drmTMB:::drm_standardize_pedigree(extra)
  expect_identical(names(ped2), c("id", "dam", "sire"))
  expect_identical(ped2$id, rev(ped$id))
})

test_that("drm_normalize_pedigree_parent maps NA, '' and '0' to NA", {
  out <- drmTMB:::drm_normalize_pedigree_parent(c("a", NA, "", "0", "00"))
  expect_identical(out, c("a", NA, NA, NA, "00"))
})

test_that("drm_pedigree_topological_order puts parents before offspring", {
  ped <- drmTMB:::drm_standardize_pedigree(edge_pedigree())
  set.seed(1)
  shuffled <- ped[c(8, 6, 4, 7, 5, 3, 2, 1), , drop = FALSE]
  # Confirm the shuffle really puts some parent after its offspring.
  pos <- match(shuffled$dam, shuffled$id)
  expect_true(any(pos > seq_along(pos), na.rm = TRUE))

  order <- drmTMB:::drm_pedigree_topological_order(shuffled)
  expect_setequal(order, seq_len(nrow(shuffled)))
  sorted <- shuffled[order, , drop = FALSE]
  for (col in c("dam", "sire")) {
    parent_pos <- match(sorted[[col]], sorted$id)
    has_parent <- !is.na(parent_pos)
    expect_true(all(parent_pos[has_parent] < seq_len(nrow(sorted))[has_parent]))
  }

  # Already-ordered input is returned unchanged.
  expect_identical(drmTMB:::drm_pedigree_topological_order(ped), seq_len(8L))
})

test_that("pedigree validation aborts name the problem", {
  base <- edge_pedigree()

  expect_error(
    drmTMB:::drm_standardize_pedigree(list(id = "a")),
    "must be a data frame"
  )
  expect_error(
    drmTMB:::drm_standardize_pedigree(base[, c("id", "dam")]),
    "must contain.*columns"
  )
  expect_error(
    drmTMB:::drm_standardize_pedigree(base[1, ]),
    "at least two individuals"
  )

  blank_id <- base
  blank_id$id[[2L]] <- ""
  expect_error(
    drmTMB:::drm_standardize_pedigree(blank_id),
    "non-missing labels"
  )

  dup <- base
  dup$id[[2L]] <- "a"
  expect_error(
    drmTMB:::drm_standardize_pedigree(dup),
    "must be unique"
  )

  unknown <- base
  unknown$dam[[4L]] <- "zzz"
  expect_error(
    drmTMB:::drm_standardize_pedigree(unknown),
    "parents must appear in the"
  )

  # A self-parent is a one-element cycle: it standardises, then cannot resolve.
  self <- base
  self$dam[[4L]] <- "c"
  self_ped <- drmTMB:::drm_standardize_pedigree(self)
  expect_error(
    drmTMB:::drm_pedigree_topological_order(self_ped),
    "must not contain parent-offspring cycles"
  )

  # A two-step cycle: a has dam c, c has dam a.
  cycle <- base
  cycle$dam[[1L]] <- "c"
  cycle$dam[[4L]] <- "a"
  cycle_ped <- drmTMB:::drm_standardize_pedigree(cycle)
  expect_error(
    drmTMB:::drm_pedigree_topological_order(cycle_ped),
    "must not contain parent-offspring cycles"
  )
  expect_error(
    drmTMB:::drm_pedigree_additive_relationship(cycle),
    "must not contain parent-offspring cycles"
  )
})

test_that("drm_pedigree_inbreeding_parent_index indexes parents and rejects bad order", {
  ped <- drmTMB:::drm_standardize_pedigree(edge_pedigree())
  idx <- drmTMB:::drm_pedigree_inbreeding_parent_index(ped)
  expect_identical(idx$ids, ped$id)
  expect_identical(idx$dam, c(0L, 0L, 0L, 2L, 2L, 5L, 6L, 6L))
  expect_identical(idx$sire, c(0L, 0L, 0L, 1L, 1L, 4L, 3L, 5L))
  expect_type(idx$sire, "integer")
  expect_type(idx$dam, "integer")

  reversed <- ped[rev(seq_len(nrow(ped))), , drop = FALSE]
  expect_error(
    drmTMB:::drm_pedigree_inbreeding_parent_index(reversed),
    "could not be ordered from ancestors to descendants"
  )
})

test_that("Quaas A-inverse equals the inverse of the additive relationship", {
  check <- function(pedigree, expect_inbred) {
    ped <- drmTMB:::drm_standardize_pedigree(pedigree)
    ped <- ped[drmTMB:::drm_pedigree_topological_order(ped), , drop = FALSE]
    A <- drmTMB:::drm_pedigree_additive_relationship(ped)
    F <- diag(A) - 1
    expect_identical(any(F > 0), expect_inbred)
    ainv <- drmTMB:::drm_pedigree_quaas_ainv(ped, inbreeding = F)
    expect_equal(
      as.matrix(ainv),
      solve(A),
      tolerance = 1e-10,
      ignore_attr = TRUE
    )
    expect_identical(rownames(ainv), ped$id)
    expect_identical(colnames(ainv), ped$id)
    expect_s4_class(ainv, "sparseMatrix")
    ainv
  }

  # With inbreeding: e is the offspring of full sibs c and d.
  inbred <- edge_pedigree()
  ped <- drmTMB:::drm_standardize_pedigree(inbred)
  A <- drmTMB:::drm_pedigree_additive_relationship(ped)
  expect_equal(unname(diag(A)[ped$id == "e"]), 1.25, tolerance = 1e-12)
  check(inbred, expect_inbred = TRUE)

  # Without inbreeding: drop the full-sib mating offspring and descendants.
  outbred <- edge_pedigree()[1:5, ]
  check(outbred, expect_inbred = FALSE)

  # Half-known parents (dam only, sire only) use the 0.75 Mendelian variance.
  half <- data.frame(
    id = c("a", "b", "c", "d"),
    dam = c(NA, NA, "a", NA),
    sire = c(NA, NA, NA, "b"),
    stringsAsFactors = FALSE
  )
  check(half, expect_inbred = FALSE)
})

test_that("drm_pedigree_quaas_ainv aborts on an impossible inbreeding value", {
  ped <- drmTMB:::drm_standardize_pedigree(edge_pedigree()[1:5, ])
  expect_error(
    drmTMB:::drm_pedigree_quaas_ainv(ped, inbreeding = rep(1, nrow(ped))),
    "non-positive Mendelian sampling variance"
  )
})

known_spd <- function() {
  m <- matrix(
    c(
      2.0, 0.5, 0.2, 0.0,
      0.5, 1.5, 0.3, 0.1,
      0.2, 0.3, 1.0, 0.4,
      0.0, 0.1, 0.4, 1.2
    ),
    nrow = 4L,
    dimnames = list(letters[1:4], letters[1:4])
  )
  m
}

test_that("covariance and precision helpers are mutually consistent", {
  cov <- known_spd()

  from_cov <- drmTMB:::drm_covariance_to_known_precision(cov, "relmat", "K")
  expect_named(from_cov, c("precision", "log_det_precision"))
  expect_equal(
    as.matrix(from_cov$precision %*% cov),
    diag(4L),
    tolerance = 1e-10,
    ignore_attr = TRUE
  )
  expect_equal(
    from_cov$log_det_precision,
    -as.numeric(determinant(cov, logarithm = TRUE)$modulus),
    tolerance = 1e-10
  )
  expect_identical(rownames(from_cov$precision), letters[1:4])

  prec <- solve(cov)
  validated <- drmTMB:::drm_validate_known_precision_matrix(prec, "relmat", "K")
  expect_named(validated, c("precision", "log_det_precision"))
  expect_equal(
    as.matrix(validated$precision %*% cov),
    diag(4L),
    tolerance = 1e-10,
    ignore_attr = TRUE
  )
  expect_equal(
    validated$log_det_precision,
    from_cov$log_det_precision,
    tolerance = 1e-10
  )
  expect_equal(
    as.matrix(validated$precision),
    as.matrix(from_cov$precision),
    tolerance = 1e-10,
    ignore_attr = TRUE
  )
})

test_that("known-precision helpers abort on non-positive-definite input", {
  nonpd <- known_spd()
  nonpd[1L, 1L] <- -1
  expect_error(
    drmTMB:::drm_covariance_to_known_precision(nonpd, "relmat", "K"),
    "covariance matrix.*must be positive definite"
  )
  # CHOLMOD emits a warning before the helper turns the failure into an abort.
  expect_error(
    suppressWarnings(
      drmTMB:::drm_validate_known_precision_matrix(nonpd, "relmat", "K")
    ),
    "precision matrix.*must be positive definite"
  )

  singular <- known_spd()
  singular[, 4L] <- singular[, 3L]
  singular[4L, ] <- singular[3L, ]
  expect_error(
    drmTMB:::drm_covariance_to_known_precision(singular, "relmat", "K"),
    "must be positive definite"
  )
})

test_that("drm_standardize_relatedness_matrix aborts on malformed matrices", {
  std <- drmTMB:::drm_standardize_relatedness_matrix
  good <- known_spd()

  expect_identical(std(good, "relmat", "K"), good)

  # Columns are reordered to match rows.
  shuffled <- good[, c(3, 1, 4, 2)]
  expect_identical(colnames(std(shuffled, "relmat", "K")), rownames(good))

  expect_error(
    std(good[, 1:3], "relmat", "K"),
    "must be a square matrix"
  )
  expect_error(
    std("a", "relmat", "K"),
    "must be a numeric square matrix"
  )

  nonfinite <- good
  nonfinite[1L, 2L] <- NA_real_
  expect_error(std(nonfinite, "relmat", "K"), "finite numeric values")

  unnamed <- good
  dimnames(unnamed) <- NULL
  expect_error(std(unnamed, "relmat", "K"), "non-empty row and column names")

  dup <- good
  dimnames(dup) <- list(c("a", "a", "c", "d"), c("a", "a", "c", "d"))
  expect_error(std(dup, "relmat", "K"), "must be unique")

  mismatch <- good
  colnames(mismatch) <- c("a", "b", "c", "zz")
  expect_error(std(mismatch, "relmat", "K"), "row and column names must match")
})

test_that("an asymmetric matrix is symmetrised from its upper triangle", {
  # Characterisation: forceSymmetric(uplo = "U") does not abort on asymmetry.
  cov <- known_spd()
  asym <- cov
  asym[4L, 1L] <- 0.9
  out <- drmTMB:::drm_covariance_to_known_precision(asym, "relmat", "K")
  expect_equal(
    as.matrix(out$precision %*% cov),
    diag(4L),
    tolerance = 1e-10,
    ignore_attr = TRUE
  )
})
