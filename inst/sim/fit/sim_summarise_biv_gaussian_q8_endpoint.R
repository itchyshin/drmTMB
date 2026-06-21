phase18_summarise_biv_gaussian_q8_endpoint_fit <- function(
  fit,
  truth,
  cell_id = NA_character_,
  replicate = NA_integer_,
  elapsed = NA_real_,
  warnings = character()
) {
  if (is.data.frame(truth)) {
    truth <- attr(truth, "truth", exact = TRUE)
  }
  if (
    !is.list(truth) || !identical(truth$surface, "biv_gaussian_q8_endpoint")
  ) {
    stop(
      "`truth` must be a bivariate Gaussian q8 endpoint truth object.",
      call. = FALSE
    )
  }

  mu1_truth <- truth$beta_mu1
  mu2_truth <- truth$beta_mu2
  sigma1_truth <- truth$beta_sigma1
  sigma2_truth <- truth$beta_sigma2
  sd_mu_truth <- truth$sd_mu
  sd_sigma_truth <- truth$sd_sigma
  cor_truth <- truth$cor_re_cov
  residual_rho_truth <- truth$residual_rho
  metadata <- phase18_biv_gaussian_q8_endpoint_truth_metadata(truth)

  mu1_est <- stats::coef(fit, dpar = "mu1")[names(mu1_truth)]
  mu2_est <- stats::coef(fit, dpar = "mu2")[names(mu2_truth)]
  sigma1_est <- stats::coef(fit, dpar = "sigma1")[names(sigma1_truth)]
  sigma2_est <- stats::coef(fit, dpar = "sigma2")[names(sigma2_truth)]
  sd_mu_est <- fit$sdpars$mu[names(sd_mu_truth)]
  sd_sigma_est <- fit$sdpars$sigma[names(sd_sigma_truth)]
  cor_est <- fit$corpars$re_cov[names(cor_truth)]
  residual_rho_est <- c(rho12 = rho12(fit)[[1L]])
  diagnostics <- phase18_biv_gaussian_q8_endpoint_fit_diagnostics(fit)

  estimate <- c(
    mu1_est,
    mu2_est,
    sigma1_est,
    sigma2_est,
    sd_mu_est,
    sd_sigma_est,
    cor_est,
    residual_rho_est
  )
  truth_value <- c(
    mu1_truth,
    mu2_truth,
    sigma1_truth,
    sigma2_truth,
    sd_mu_truth,
    sd_sigma_truth,
    cor_truth,
    residual_rho_truth
  )
  parameter <- c(
    paste0("mu1:", names(mu1_est)),
    paste0("mu2:", names(mu2_est)),
    paste0("sigma1:", names(sigma1_est)),
    paste0("sigma2:", names(sigma2_est)),
    paste0("sd:mu:", names(sd_mu_est)),
    paste0("sd:sigma:", names(sd_sigma_est)),
    paste0("cor:re_cov:", names(cor_est)),
    "rho12"
  )
  names(estimate) <- parameter
  names(truth_value) <- parameter

  data.frame(
    surface = "biv_gaussian_q8_endpoint",
    diagnostic_id = metadata$diagnostic_id,
    diagnostic_preset = metadata$diagnostic_preset,
    diagnostic_level = metadata$diagnostic_level,
    diagnostic_note = metadata$diagnostic_note,
    cell_id = cell_id,
    replicate = replicate,
    parameter = parameter,
    parameter_class = c(
      rep("fixed_mu1", length(mu1_est)),
      rep("fixed_mu2", length(mu2_est)),
      rep("fixed_sigma1", length(sigma1_est)),
      rep("fixed_sigma2", length(sigma2_est)),
      rep("random_sd", length(sd_mu_est)),
      rep("random_sd", length(sd_sigma_est)),
      rep("derived_random_correlation", length(cor_est)),
      "residual_rho12"
    ),
    truth = unname(truth_value),
    estimate = unname(estimate),
    std.error = unname(
      phase18_biv_gaussian_q8_endpoint_std_error(fit, parameter)
    ),
    error = unname(estimate - truth_value),
    converged = isTRUE(fit$opt$convergence == 0),
    pdHess = isTRUE(fit$sdr$pdHess),
    nobs = stats::nobs(fit),
    elapsed = elapsed,
    optimizer_code = diagnostics$optimizer_code,
    optimizer_message = diagnostics$optimizer_message,
    objective = diagnostics$objective,
    max_gradient = diagnostics$max_gradient,
    qgt2_blocks = diagnostics$qgt2_blocks,
    max_q = diagnostics$max_q,
    max_pairs = diagnostics$max_pairs,
    min_group_n = diagnostics$min_group_n,
    min_sd_mu = diagnostics$min_sd_mu,
    min_sd_sigma = diagnostics$min_sd_sigma,
    max_abs_cor = diagnostics$max_abs_cor,
    min_cor_eigen = diagnostics$min_cor_eigen,
    max_cor_condition = diagnostics$max_cor_condition,
    warning_count = length(warnings),
    warnings = paste(warnings, collapse = " | "),
    stringsAsFactors = FALSE
  )
}

phase18_biv_gaussian_q8_endpoint_truth_metadata <- function(truth) {
  fields <- c(
    "diagnostic_id",
    "diagnostic_preset",
    "diagnostic_level",
    "diagnostic_note"
  )
  out <- stats::setNames(
    rep(NA_character_, length(fields)),
    fields
  )
  for (field in fields) {
    value <- truth[[field]]
    if (is.character(value) && length(value) == 1L && nzchar(value)) {
      out[[field]] <- value
    }
  }
  as.list(out)
}

phase18_biv_gaussian_q8_endpoint_std_error <- function(fit, parameter) {
  out <- rep(NA_real_, length(parameter))
  names(out) <- parameter
  coefficients <- tryCatch(
    summary(fit)$coefficients,
    error = function(e) NULL
  )
  if (
    is.null(coefficients) ||
      !"std_error" %in% names(coefficients) ||
      is.null(row.names(coefficients))
  ) {
    return(out)
  }
  matched <- match(parameter, row.names(coefficients))
  ok <- !is.na(matched)
  out[ok] <- coefficients$std_error[matched[ok]]
  out
}

phase18_biv_gaussian_q8_endpoint_fit_diagnostics <- function(fit) {
  covariance <- phase18_biv_gaussian_q8_endpoint_covariance_diagnostics(fit)
  c(
    list(
      optimizer_code = phase18_biv_gaussian_q8_endpoint_scalar(
        fit$opt$convergence,
        NA_integer_
      ),
      optimizer_message = phase18_biv_gaussian_q8_endpoint_character(
        fit$opt$message
      ),
      objective = phase18_biv_gaussian_q8_endpoint_scalar(fit$opt$objective),
      max_gradient = phase18_biv_gaussian_q8_endpoint_max_gradient(fit),
      min_sd_mu = phase18_biv_gaussian_q8_endpoint_min_finite(fit$sdpars$mu),
      min_sd_sigma = phase18_biv_gaussian_q8_endpoint_min_finite(
        fit$sdpars$sigma
      ),
      max_abs_cor = phase18_biv_gaussian_q8_endpoint_max_abs_finite(
        fit$corpars$re_cov
      )
    ),
    covariance
  )
}

phase18_biv_gaussian_q8_endpoint_covariance_diagnostics <- function(fit) {
  empty <- list(
    qgt2_blocks = 0L,
    max_q = NA_integer_,
    max_pairs = NA_integer_,
    min_group_n = NA_real_,
    min_cor_eigen = NA_real_,
    max_cor_condition = NA_real_
  )
  registry <- fit$model$random$covariance_blocks
  if (
    !is.list(registry) ||
      is.null(registry$blocks) ||
      nrow(registry$blocks) == 0L
  ) {
    return(empty)
  }

  blocks <- registry$blocks[
    registry$blocks$implemented &
      registry$blocks$n_members > 4L &
      registry$blocks$level == "group",
    ,
    drop = FALSE
  ]
  if (nrow(blocks) == 0L) {
    return(empty)
  }

  summaries <- lapply(seq_len(nrow(blocks)), function(i) {
    block <- blocks[i, , drop = FALSE]
    members <- registry$members[
      registry$members$block_id0 == block$block_id0[[1L]],
      ,
      drop = FALSE
    ]
    pairs <- registry$pairs[
      registry$pairs$block_id0 == block$block_id0[[1L]],
      ,
      drop = FALSE
    ]
    group_counts <- phase18_biv_gaussian_q8_endpoint_group_counts(
      members,
      block$n_groups[[1L]]
    )
    cor <- unname(fit$corpars$re_cov[match(
      pairs$parameter,
      names(fit$corpars$re_cov)
    )])
    cor_diagnostics <- phase18_biv_gaussian_q8_endpoint_cor_diagnostics(
      members,
      pairs,
      cor
    )

    list(
      q = block$n_members[[1L]],
      pairs = nrow(pairs),
      min_group_n = if (length(group_counts) > 0L) {
        min(group_counts)
      } else {
        NA_real_
      },
      min_cor_eigen = cor_diagnostics$min_eigen,
      max_cor_condition = cor_diagnostics$condition
    )
  })

  list(
    qgt2_blocks = nrow(blocks),
    max_q = max(vapply(summaries, `[[`, numeric(1L), "q")),
    max_pairs = max(vapply(summaries, `[[`, numeric(1L), "pairs")),
    min_group_n = phase18_biv_gaussian_q8_endpoint_min_finite(vapply(
      summaries,
      `[[`,
      numeric(1L),
      "min_group_n"
    )),
    min_cor_eigen = phase18_biv_gaussian_q8_endpoint_min_finite(vapply(
      summaries,
      `[[`,
      numeric(1L),
      "min_cor_eigen"
    )),
    max_cor_condition = phase18_biv_gaussian_q8_endpoint_max_finite(vapply(
      summaries,
      `[[`,
      numeric(1L),
      "max_cor_condition"
    ))
  )
}

phase18_biv_gaussian_q8_endpoint_group_counts <- function(members, n_groups) {
  if (nrow(members) == 0L || !is.finite(n_groups) || n_groups < 1L) {
    return(integer())
  }
  first_member <- members[order(members$member_id0), , drop = FALSE][1L, ]
  index <- first_member$latent_index0[[1L]]
  index <- index[!is.na(index) & index >= 0L]
  tabulate((index %% n_groups) + 1L, nbins = n_groups)
}

phase18_biv_gaussian_q8_endpoint_cor_diagnostics <- function(
  members,
  pairs,
  correlations
) {
  q <- nrow(members)
  if (q < 2L || nrow(pairs) == 0L || length(correlations) != nrow(pairs)) {
    return(list(min_eigen = NA_real_, condition = NA_real_))
  }

  member_ids <- members$member_id0[order(members$member_id0)]
  correlation_matrix <- diag(q)
  from <- match(pairs$from_member_id0, member_ids)
  to <- match(pairs$to_member_id0, member_ids)
  ok <- !is.na(from) & !is.na(to) & is.finite(correlations)
  if (!all(ok)) {
    return(list(min_eigen = NA_real_, condition = NA_real_))
  }

  correlation_matrix[cbind(from, to)] <- correlations
  correlation_matrix[cbind(to, from)] <- correlations
  eigenvalues <- tryCatch(
    eigen(correlation_matrix, symmetric = TRUE, only.values = TRUE)$values,
    error = function(e) NA_real_
  )
  if (!all(is.finite(eigenvalues))) {
    return(list(min_eigen = NA_real_, condition = NA_real_))
  }

  min_eigen <- min(eigenvalues)
  condition <- if (min_eigen > 0) {
    max(eigenvalues) / min_eigen
  } else {
    Inf
  }
  list(min_eigen = min_eigen, condition = condition)
}

phase18_biv_gaussian_q8_endpoint_max_gradient <- function(fit) {
  tryCatch(
    {
      if (is.null(fit$obj$gr) || is.null(fit$opt$par)) {
        return(NA_real_)
      }
      gradient <- fit$obj$gr(fit$opt$par)
      phase18_biv_gaussian_q8_endpoint_max_abs_finite(gradient)
    },
    error = function(e) NA_real_
  )
}

phase18_biv_gaussian_q8_endpoint_scalar <- function(x, default = NA_real_) {
  if (length(x) != 1L) {
    return(default)
  }
  x
}

phase18_biv_gaussian_q8_endpoint_character <- function(x) {
  if (length(x) != 1L || is.null(x) || is.na(x)) {
    return(NA_character_)
  }
  as.character(x)
}

phase18_biv_gaussian_q8_endpoint_min_finite <- function(x) {
  x <- as.numeric(x)
  x <- x[is.finite(x)]
  if (length(x) == 0L) {
    return(NA_real_)
  }
  min(x)
}

phase18_biv_gaussian_q8_endpoint_max_finite <- function(x) {
  x <- as.numeric(x)
  x <- x[is.finite(x)]
  if (length(x) == 0L) {
    return(NA_real_)
  }
  max(x)
}

phase18_biv_gaussian_q8_endpoint_max_abs_finite <- function(x) {
  x <- as.numeric(x)
  x <- x[is.finite(x)]
  if (length(x) == 0L) {
    return(NA_real_)
  }
  max(abs(x))
}
