# High-information production fixture for the two exact bivariate-Gaussian
# animal q2 slope targets.  This is intentionally a new DGP version: the
# historical eight-animal source fixture is insufficient for random-slope
# interval work and is retained separately as negative evidence.

lane_b_animal_q2_slope_stop <- function(...) stop(..., call. = FALSE)

lane_b_animal_q2_slope_contracts <- function() {
  data.frame(
    cell_id = c("mc-0131", "mc-0132"),
    target_id = c(
      "mc-0131::sd:mu:mu1:animal(0 + x | p | id)",
      "mc-0132::sd:mu:mu2:animal(0 + x | p | id)"
    ),
    profile_parameter = c(
      "sd:mu:mu1:animal(0 + x | p | id)",
      "sd:mu:mu2:animal(0 + x | p | id)"
    ),
    truth = c(1.05, 0.90),
    stringsAsFactors = FALSE
  )
}

lane_b_animal_q2_slope_row <- function(cell, target_id, seed, rung) {
  rows <- lane_b_animal_q2_slope_contracts()
  row <- rows[rows$cell_id == cell & rows$target_id == target_id, , drop = FALSE]
  if (nrow(row) != 1L) lane_b_animal_q2_slope_stop("No exact animal q2 slope contract for this cell and target.")
  if (!identical(as.integer(seed), 2026072901L) || !identical(as.character(rung), "high")) {
    lane_b_animal_q2_slope_stop("Animal q2 slope evidence is frozen at seed 2026072901 and high rung.")
  }
  row
}

lane_b_animal_q2_slope_A <- function(n = 32L) {
  labels <- paste0("id", seq_len(n))
  A <- outer(seq_len(n), seq_len(n), function(i, j) 0.32 ^ abs(i - j))
  diag(A) <- diag(A) + 0.18
  dimnames(A) <- list(labels, labels)
  if (!isTRUE(all.equal(A, t(A))) || any(!is.finite(A)) || any(eigen(A, symmetric = TRUE, only.values = TRUE)$values <= 0) || !identical(rownames(A), colnames(A)) || anyDuplicated(rownames(A))) {
    lane_b_animal_q2_slope_stop("The supplied animal A matrix must be symmetric positive definite with unique matched IDs.")
  }
  A
}

lane_b_animal_q2_slope_fixture <- function(cell, target_id, seed, rung) {
  row <- lane_b_animal_q2_slope_row(cell, target_id, seed, rung)
  set.seed(seed)
  A <- lane_b_animal_q2_slope_A(32L)
  ids <- rownames(A)
  endpoint_cov <- matrix(c(1.05^2, 0.35 * 1.05 * 0.90, 0.35 * 1.05 * 0.90, 0.90^2), 2L)
  effects <- t(chol(A)) %*% matrix(stats::rnorm(64L), nrow = 32L) %*% chol(endpoint_cov)
  colnames(effects) <- c("mu1", "mu2")
  id <- factor(rep(ids, each = 20L), levels = ids)
  x <- rep(seq(-1.25, 1.25, length.out = 20L), times = 32L)
  residual <- matrix(stats::rnorm(length(id) * 2L), ncol = 2L) %*% chol(matrix(c(0.22^2, -0.10 * 0.22 * 0.24, -0.10 * 0.22 * 0.24, 0.24^2), 2L))
  data <- data.frame(
    y1 = 0.25 + 0.35 * x + effects[as.character(id), "mu1"] * x + residual[, 1L],
    y2 = -0.15 - 0.25 * x + effects[as.character(id), "mu2"] * x + residual[, 2L],
    x = x, id = id
  )
  if (any(vapply(split(data$x, data$id), function(z) length(unique(z)) != 20L, logical(1L)))) {
    lane_b_animal_q2_slope_stop("Every animal level must retain 20 distinct within-level x values.")
  }
  truth <- list(
    cell_id = cell, target_id = target_id, profile_parameter = row$profile_parameter[[1L]],
    dgp_id = "lane_b_animal_q2_slope_highinfo_v1", target_truth = row$truth[[1L]],
    execution_rung = rung, seed = seed, A = A, group_count = 32L,
    within_group_replicates = 20L
  )
  list(data = data, truth = truth, fit = function(dat) {
    drmTMB::drmTMB(
      drmTMB::bf(
        mu1 = y1 ~ x + animal(0 + x | p | id, A = A),
        mu2 = y2 ~ x + animal(0 + x | p | id, A = A),
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ), family = drmTMB::biv_gaussian(), data = dat,
      control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 2400, iter.max = 2400))
    )
  })
}
