# temporal_lag_witnesses() replaces the O(m^2) pairwise lag matrix in the
# lag-variation rules. It must decide those rules exactly as the full pairwise
# set does: the number of distinct positive lags (capped at 3) and, for
# integer AR1 occasions, whether any lag is odd.
full_pairwise_lags <- function(x) {
  x <- sort(unique(x))
  if (length(x) < 2L) return(numeric())
  lags <- abs(outer(x, x, "-"))
  lags[upper.tri(lags, diag = FALSE)]
}

lag_rule_summary <- function(lags) {
  distinct <- unique(lags[lags > 0])
  c(n_capped = min(length(distinct), 3L), has_odd = any(distinct %% 2 == 1))
}

test_that("lag witnesses decide the count and odd-lag rules like the full set", {
  set.seed(20261002)
  for (i in seq_len(400)) {
    n_series <- sample.int(4L, 1L)
    integer_times <- i %% 2L == 0L
    series <- lapply(seq_len(n_series), function(s) {
      m <- sample.int(8L, 1L)
      if (integer_times) {
        sample(0:20, m) * sample(c(1L, 2L), 1L)
      } else {
        round(stats::runif(m, 0, 10), 1)
      }
    })
    full <- unlist(lapply(series, full_pairwise_lags))
    witness <- unlist(lapply(series, temporal_lag_witnesses))
    expect_true(all(witness %in% full))
    # The odd-lag rule applies only to integer AR1 occasions.
    keep <- if (integer_times) c("n_capped", "has_odd") else "n_capped"
    expect_identical(lag_rule_summary(witness)[keep], lag_rule_summary(full)[keep])
  }
})

test_that("lag witnesses stay linear for a long series", {
  x <- seq(0, 2e5, by = 2)
  witness <- temporal_lag_witnesses(x)
  expect_length(witness, 3L)
  expect_identical(witness, c(2, 4, 6))
  expect_true(any(temporal_lag_witnesses(c(x, 7)) %% 2 == 1))
})
