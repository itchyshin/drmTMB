# #1512: the Julia bridge strips dimnames from K/A, and DRModels.jl pairs row i
# with the i-th group in first-appearance order. The bridge must therefore
# reorder labelled matrices itself. These tests need no Julia.

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
    "missing rows or columns"
  )
  Ku <- unname(K)
  dat2 <- data.frame(g = c("b", "a"))
  out <- drmTMB:::drm_julia_structured_matrix(term, "gaussian", list2env(list(K = Ku)), dat2)
  expect_equal(out$matrix, Ku)
})
