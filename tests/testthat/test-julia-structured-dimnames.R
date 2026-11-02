# #1512: Julia pairs row i of K/A with the i-th group in first-appearance order.
# These tests check that labelled matrices are aligned before marshalling.

make_labelled_K <- function(ids) {
  K <- matrix(0.1, length(ids), length(ids), dimnames = list(ids, ids))
  diag(K) <- seq_along(ids)
  K
}

test_that("labelled K is reordered to first-appearance order of the group", {
  ids <- c("a", "b", "c", "d")
  K <- make_labelled_K(ids)
  dat <- data.frame(g = c("c", "a", "d", "b", "c"))
  env <- list2env(list(K = K[ids, ids]))
  term <- list(type = "relmat", structure = "K", object = "K", group = "g")
  out <- drmTMB:::drm_julia_structured_matrix(term, "gaussian", env, dat)
  expect_equal(unname(diag(out$matrix)), c(3, 1, 4, 2))
  expect_equal(out$kwarg, "K")
})

test_that("shuffling a labelled matrix does not change the bridge matrix", {
  ids <- c("a", "b", "c", "d")
  K <- make_labelled_K(ids)
  dat <- data.frame(g = c("b", "d", "a", "c"))
  term <- list(type = "animal", structure = "A", object = "A", group = "g")
  res <- function(M) {
    drmTMB:::drm_julia_structured_matrix(
      term, "gaussian", list2env(list(A = M)), dat
    )$matrix
  }
  expect_equal(res(K), res(K[c(3, 1, 4, 2), c(3, 1, 4, 2)]))
})

test_that("labelled matrix missing a group level errors; unlabelled passes", {
  K <- make_labelled_K(c("a", "b"))
  dat <- data.frame(g = c("a", "b", "z"))
  term <- list(type = "relmat", structure = "K", object = "K", group = "g")
  expect_error(
    drmTMB:::drm_julia_structured_matrix(term, "gaussian", list2env(list(K = K)), dat),
    "has no row for 1 grouping level",
    class = "drmTMB_julia_structured_labels"
  )
  Ku <- unname(K)
  dat2 <- data.frame(g = c("b", "a"))
  expect_warning(
    out <- drmTMB:::drm_julia_structured_matrix(
      term, "gaussian", list2env(list(K = Ku)), dat2
    ),
    class = "drmTMB_julia_unlabelled_structured_matrix"
  )
  expect_equal(out$matrix, Ku)
})
