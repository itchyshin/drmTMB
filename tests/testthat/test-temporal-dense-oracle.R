temporal_oracle_data <- function(with_intercept, seed = 20260908L) {
  set.seed(seed)
  occasion <- c(0L, 1L, 3L, 4L, 7L, 9L)
  ids <- paste0("site_", seq_len(24L))
  dat <- do.call(rbind, lapply(ids, function(id) {
    data.frame(id = id, occasion = occasion, x = stats::rnorm(length(occasion)))
  }))
  beta <- c(`(Intercept)` = 0.2, x = 0.5)
  sd_between <- if (with_intercept) 0.6 else 0
  sd_temporal <- 0.8
  sigma <- 0.4
  phi <- if (with_intercept) -0.35 else 0.45
  dat$y <- NA_real_
  for (id in ids) {
    index <- which(dat$id == id)
    time <- dat$occasion[index]
    R <- phi^abs(outer(time, time, "-"))
    temporal <- as.vector(t(chol(R)) %*% stats::rnorm(length(index))) * sd_temporal
    intercept <- if (with_intercept) stats::rnorm(1L, sd = sd_between) else 0
    dat$y[index] <- beta[[1L]] + beta[[2L]] * dat$x[index] + intercept + temporal +
      stats::rnorm(length(index), sd = sigma)
  }
  dat[sample.int(nrow(dat)), , drop = FALSE]
}

temporal_dense_loglik <- function(fit) {
  temporal <- fit$model$structured$temporal_mu
  beta <- unname(fit$coefficients$mu)
  X <- as.matrix(fit$model$X$mu)
  sigma <- exp(unname(fit$coefficients$sigma[[1L]]))
  sd_temporal <- unname(fit$sdpars$mu[[temporal_mu_sd_label(temporal)]])
  phi <- unname(fit$corpars$temporal[[temporal$label]])
  sd_between <- if ("(1 | id)" %in% names(fit$sdpars$mu)) {
    unname(fit$sdpars$mu[["(1 | id)"]])
  } else {
    0
  }
  data <- fit$data
  out <- 0
  for (id in temporal$series_levels) {
    rows <- which(as.character(data[[temporal$group]]) == id)
    rows <- rows[order(data[[temporal$time]][rows])]
    time <- data[[temporal$time]][rows]
    V <- sd_between^2 + sd_temporal^2 * phi^abs(outer(time, time, "-"))
    diag(V) <- diag(V) + sigma^2
    residual <- fit$model$y[rows] - as.vector(X[rows, , drop = FALSE] %*% beta)
    root <- chol(V)
    out <- out - 0.5 * (
      length(rows) * log(2 * pi) +
        2 * sum(log(diag(root))) +
        sum(forwardsolve(t(root), residual)^2)
    )
  }
  out
}

test_that("Gaussian temporal likelihood matches a dense marginal covariance oracle", {
  for (with_intercept in c(FALSE, TRUE)) {
    dat <- temporal_oracle_data(with_intercept)
    fit <- if (with_intercept) {
      suppressWarnings(drmTMB(
        bf(y ~ x + (1 | id) + temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
        data = dat, family = gaussian(), REML = FALSE
      ))
    } else {
      suppressWarnings(drmTMB(
        bf(y ~ x + temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
        data = dat, family = gaussian(), REML = FALSE
      ))
    }
    expect_equal(
      as.numeric(stats::logLik(fit)),
      temporal_dense_loglik(fit),
      tolerance = 1e-7
    )
  }
})
