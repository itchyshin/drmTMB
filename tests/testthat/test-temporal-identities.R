temporal_reference_covariance <- function(
  series,
  occasion,
  sd_between,
  sd_temporal,
  sigma,
  phi
) {
  n <- length(series)
  out <- matrix(0, nrow = n, ncol = n)
  for (i in seq_len(n)) {
    for (j in seq_len(n)) {
      if (identical(series[[i]], series[[j]])) {
        out[i, j] <- sd_between^2 +
          sd_temporal^2 * phi^abs(occasion[[i]] - occasion[[j]])
      }
    }
  }
  diag(out) <- diag(out) + sigma^2
  out
}

test_that("temporal covariance reduces correctly at zero persistence", {
  series <- rep(c("a", "b"), each = 3L)
  occasion <- c(0L, 1L, 4L, 0L, 2L, 5L)
  sd_between <- 0.6
  sd_temporal <- 0.8
  sigma <- 0.4
  actual <- temporal_reference_covariance(
    series, occasion, sd_between, sd_temporal, sigma, phi = 0
  )
  expected <- matrix(0, nrow = length(series), ncol = length(series))
  for (id in unique(series)) {
    rows <- which(series == id)
    expected[rows, rows] <- sd_between^2
  }
  diag(expected) <- diag(expected) + sd_temporal^2 + sigma^2
  expect_equal(actual, expected)
})

test_that("temporal covariance preserves integer gaps and independent series", {
  series <- c("a", "a", "a", "b", "b")
  occasion <- c(0L, 1L, 4L, 0L, 4L)
  phi <- -0.5
  actual <- temporal_reference_covariance(
    series, occasion, sd_between = 0, sd_temporal = 1, sigma = 0, phi = phi
  )
  expect_equal(actual[1L, 3L], phi^4)
  expect_false(isTRUE(all.equal(actual[1L, 3L], phi^2)))
  expect_equal(actual[1L, 4L], 0)
  expect_equal(actual[3L, 5L], 0)
})

test_that("temporal layout maps shuffled observations to sorted latent states", {
  dat <- data.frame(
    id = c("b", "a", "b", "a", "a", "b"),
    occasion = c(3L, 4L, 0L, 0L, 1L, 1L)
  )
  term <- list(group = "id", time = "occasion", structure = "ar1")
  layout <- drmTMB:::build_temporal_mu_structure(term, dat)
  expect_identical(layout$node_labels, c("b:0", "b:1", "b:3", "a:0", "a:1", "a:4"))
  expect_identical(layout$gap, c(0L, 1L, 2L, 0L, 1L, 3L))
  expect_identical(layout$observation_node_index, c(3L, 6L, 1L, 4L, 5L, 2L))
})

test_that("reference checks reject deliberate temporal covariance and normalizer mutations", {
  series <- c("a", "a", "a", "b", "b", "b")
  occasion <- c(0L, 1L, 4L, 0L, 1L, 4L)
  phi <- -0.5
  correct <- temporal_reference_covariance(
    series, occasion, sd_between = 0.6, sd_temporal = 0.8, sigma = 0.4, phi = phi
  )
  compressed_gaps <- temporal_reference_covariance(
    series, ave(occasion, series, FUN = rank), sd_between = 0.6,
    sd_temporal = 0.8, sigma = 0.4, phi = phi
  )
  shared_series <- outer(
    occasion, occasion,
    function(left, right) 0.6^2 + 0.8^2 * phi^abs(left - right)
  )
  diag(shared_series) <- diag(shared_series) + 0.4^2
  innovation_sd <- 0.8 * sqrt(1 - phi^2)
  innovation_scale <- temporal_reference_covariance(
    series, occasion, sd_between = 0.6, sd_temporal = innovation_sd,
    sigma = 0.4, phi = phi
  )
  omitted_intercept <- temporal_reference_covariance(
    series, occasion, sd_between = 0, sd_temporal = 0.8, sigma = 0.4, phi = phi
  )
  expect_false(isTRUE(all.equal(correct, compressed_gaps)))
  expect_false(isTRUE(all.equal(correct, shared_series)))
  expect_false(isTRUE(all.equal(correct, innovation_scale)))
  expect_false(isTRUE(all.equal(correct, omitted_intercept)))

  latent <- c(0.4, -0.2, 0.7)
  gap <- c(0L, 1L, 3L)
  normalized <- -stats::dnorm(latent[[1L]], log = TRUE)
  unnormalized <- latent[[1L]]^2 / 2
  for (node in 2:3) {
    transition <- phi^gap[[node]]
    transition_sd <- sqrt(1 - transition^2)
    normalized <- normalized - stats::dnorm(
      latent[[node]], transition * latent[[node - 1L]], transition_sd, log = TRUE
    )
    unnormalized <- unnormalized +
      (latent[[node]] - transition * latent[[node - 1L]])^2 / (2 * transition_sd^2)
  }
  expect_false(isTRUE(all.equal(normalized, unnormalized)))
})
