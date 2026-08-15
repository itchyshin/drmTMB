# Source-faithful, targetwise production fixtures for the structured q2
# residual-scale intercept cells.  Loading is inert; fitting is only done by
# the explicit runner that supplies the frozen cell, seed, and rung.

lane_b_q2scale_stop <- function(...) stop(..., call. = FALSE)

lane_b_q2scale_contracts <- function() {
  data.frame(
    cell_id = c("mc-0113", "mc-0114", "mc-0135", "mc-0136", "mc-0157", "mc-0158"),
    provider = rep(c("spatial", "animal", "relmat"), each = 2L),
    axis = rep(c("sigma1", "sigma2"), 3L),
    group = c(rep("site", 2L), rep("id", 4L)),
    target_truth = rep(c(0.45, 0.40), 3L),
    seed = rep(823113L, 6L),
    n_level = rep(12L, 6L),
    n_each = rep(30L, 6L),
    rung = rep("high_information", 6L),
    dgp_id = paste0("qseries_", rep(c("spatial", "animal", "relmat"), each = 2L), "_q2_plus_q2_scale"),
    stringsAsFactors = FALSE
  )
}

lane_b_q2scale_row <- function(cell, seed, rung) {
  x <- lane_b_q2scale_contracts()
  if (!is.character(cell) || length(cell) != 1L || !cell %in% x$cell_id) {
    lane_b_q2scale_stop("No structured q2 scale fixture is registered for ", cell, ".")
  }
  row <- x[match(cell, x$cell_id), , drop = FALSE]
  if (!identical(as.integer(seed), row$seed[[1L]]) || !identical(as.character(rung), row$rung[[1L]])) {
    lane_b_q2scale_stop("The structured q2 scale fixture requires its exact seed and information rung.")
  }
  row
}

lane_b_q2scale_covariance <- function(n_level) {
  K <- outer(seq_len(n_level), seq_len(n_level), function(i, j) 0.25^abs(i - j))
  diag(K) <- diag(K) + 0.35
  K
}

lane_b_q2scale_fixture <- function(cell, seed, rung) {
  row <- lane_b_q2scale_row(cell, seed, rung)
  set.seed(row$seed[[1L]])
  n_level <- row$n_level[[1L]]; n_each <- row$n_each[[1L]]
  labels <- if (identical(row$provider[[1L]], "spatial")) paste0("site", seq_len(n_level)) else paste0("id", seq_len(n_level))
  K <- lane_b_q2scale_covariance(n_level); dimnames(K) <- list(labels, labels)
  endpoint_cov <- matrix(c(0.45^2, 0.15 * 0.45 * 0.40, 0.15 * 0.45 * 0.40, 0.40^2), 2L)
  effects <- t(chol(K)) %*% matrix(stats::rnorm(n_level * 2L), n_level, 2L) %*% chol(endpoint_cov)
  rownames(effects) <- labels
  group <- rep(labels, each = n_each)
  y1 <- 0.20 + stats::rnorm(length(group), sd = exp(-0.85 + effects[group, 1L]))
  y2 <- -0.10 + stats::rnorm(length(group), sd = exp(-0.75 + effects[group, 2L]))
  data <- data.frame(y1 = y1, y2 = y2, stringsAsFactors = FALSE)
  if (identical(row$provider[[1L]], "spatial")) {
    data$site <- group
    coords <- data.frame(x = seq_len(n_level), y = sqrt(seq_len(n_level))); rownames(coords) <- labels
    formula <- drmTMB::bf(mu1 = y1 ~ 1, mu2 = y2 ~ 1, sigma1 = ~drmTMB::spatial(1 | ps | site, coords = coords), sigma2 = ~drmTMB::spatial(1 | ps | site, coords = coords), rho12 = ~1)
  } else {
    data$id <- group; Q <- solve(K)
    formula <- if (identical(row$provider[[1L]], "animal")) drmTMB::bf(mu1 = y1 ~ 1, mu2 = y2 ~ 1, sigma1 = ~drmTMB::animal(1 | ps | id, Ainv = Q), sigma2 = ~drmTMB::animal(1 | ps | id, Ainv = Q), rho12 = ~1) else drmTMB::bf(mu1 = y1 ~ 1, mu2 = y2 ~ 1, sigma1 = ~drmTMB::relmat(1 | ps | id, Q = Q), sigma2 = ~drmTMB::relmat(1 | ps | id, Q = Q), rho12 = ~1)
  }
  target <- paste0("sd:mu:", row$axis[[1L]], ":", row$provider[[1L]], "(1 | ps | ", row$group[[1L]], ")")
  list(
    data = data, row = row, profile_parameter = target,
    fit = function() drmTMB::drmTMB(formula, family = drmTMB::biv_gaussian(), data = data, control = drmTMB::drm_control(optimizer = list(eval.max = 2500, iter.max = 2500)))
  )
}
