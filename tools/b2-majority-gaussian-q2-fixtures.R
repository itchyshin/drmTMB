# Source-addressed local Gaussian q2 DGP fixtures for B2's selected majority cohort.
# A q2 fixture shares one labelled structured provider between mu and sigma.

b2_majority_q2_stop <- function(...) stop(..., call. = FALSE)
`%||%` <- function(x, y) if (is.null(x)) y else x

b2_majority_q2_contract <- function(root, cell, target_id, seed, rung) {
  if (identical(rung, "high")) {
    source(file.path(root, "tools", "validate-b2-majority-high-q2-slope-contract.R"))
    x <- b2_majority_high_q2_read_validate(root)
  } else {
    source(file.path(root, "tools", "validate-b2-majority-40-fixture-contract.R"))
    x <- b2_majority40_read_validate(root)
  }
  row <- x[x$cell_id == cell & x$fixture_module == "b2_gaussian_q2", , drop = FALSE]
  if (nrow(row) != 1L || !identical(row$target_id[[1L]], target_id) || !identical(as.integer(row$seed[[1L]]), as.integer(seed)) || !identical(row$information_rung[[1L]], rung)) b2_majority_q2_stop("No exact B2 majority Gaussian-q2 fixture matches this tuple.")
  row
}

b2_majority_q2_provider <- function(provider, n = 24L) {
  labels <- paste0(if (provider == "spatial") "site" else if (provider == "phylo") "sp" else "id", seq_len(n))
  if (provider == "phylo") {
    if (!requireNamespace("ape", quietly = TRUE)) b2_majority_q2_stop("ape is required for phylogenetic q2 fixtures.")
    tree <- ape::rcoal(n); tree$tip.label <- labels
    return(list(labels = labels, K = ape::vcv(tree, corr = TRUE), tree = tree, group = "species"))
  }
  if (provider == "spatial") {
    theta <- seq(0, 1.8 * pi, length.out = n); coords <- data.frame(x = cos(theta) + seq_len(n) / (4 * n), y = sin(theta)); rownames(coords) <- labels
    precision <- drmTMB:::drm_spatial_coords_precision(coords, site = labels, group = "site")
    return(list(labels = labels, K = solve(as.matrix(precision$precision)), coords = coords, group = "site"))
  }
  K <- outer(seq_len(n), seq_len(n), function(i, j) .35^abs(i - j)); diag(K) <- diag(K) + .15; dimnames(K) <- list(labels, labels)
  list(labels = labels, K = K, group = "id")
}

b2_majority_q2_fixture <- function(root = ".", cell, target_id, seed, rung = "low") {
  row <- b2_majority_q2_contract(root, cell, target_id, seed, rung); set.seed(as.integer(seed))
  profile_parameter <- sub("^[^:]+::", "", target_id)
  provider_name <- sub("^.*:(phylo|spatial|animal|relmat)\\(.*$", "\\1", profile_parameter)
  if (!provider_name %in% c("phylo", "spatial", "animal", "relmat")) b2_majority_q2_stop("Unsupported q2 provider.")
  n_groups <- if (identical(rung, "high")) 72L else 24L
  n_observations <- if (identical(rung, "high")) 20L else 12L
  p <- b2_majority_q2_provider(provider_name, n_groups); id <- factor(rep(p$labels, each = n_observations), levels = p$labels); x <- rep(seq(-1, 1, length.out = n_observations), length(p$labels))
  slope <- grepl("0 \\+ x", profile_parameter)
  endpoint_cov <- matrix(c(.45^2, .25 * .45 * .30, .25 * .45 * .30, .30^2), 2L)
  fields <- t(chol(p$K)) %*% matrix(stats::rnorm(length(p$labels) * 2L), ncol = 2L) %*% chol(endpoint_cov); rownames(fields) <- p$labels
  multiplier <- if (slope) x else 1
  eta <- .20 + .35 * x + fields[as.character(id), 1L] * multiplier
  log_sigma <- -.55 + fields[as.character(id), 2L] * multiplier
  data <- data.frame(y = eta + stats::rnorm(length(id), sd = exp(log_sigma)), x = x, id = id, species = id, site = id)
  target_truth <- if ("target_truth" %in% names(row)) as.numeric(row$target_truth[[1L]]) else if (grepl("^sd:mu", profile_parameter)) .45 else .30
  list(data = data, truth = list(cell_id = cell, target_id = target_id, profile_parameter = profile_parameter, dgp_id = row$dgp_id[[1L]], seed = as.integer(seed), execution_rung = rung, target_truth = target_truth, K = p$K, tree = p$tree %||% NULL, coords = p$coords %||% NULL), fit = function(dat) {
    tree <- p$tree; coords <- p$coords; A <- p$K; K <- p$K
    if (provider_name == "phylo") {
      form <- if (slope) drmTMB::bf(y ~ x + drmTMB::phylo(1 + x | p | species, tree = tree), sigma ~ drmTMB::phylo(1 + x | p | species, tree = tree)) else drmTMB::bf(y ~ x + drmTMB::phylo(1 | p | species, tree = tree), sigma ~ drmTMB::phylo(1 | p | species, tree = tree))
    } else if (provider_name == "spatial") {
      form <- if (slope) drmTMB::bf(y ~ x + drmTMB::spatial(1 + x | p | site, coords = coords), sigma ~ drmTMB::spatial(1 + x | p | site, coords = coords)) else drmTMB::bf(y ~ x + drmTMB::spatial(1 | p | site, coords = coords), sigma ~ drmTMB::spatial(1 | p | site, coords = coords))
    } else if (provider_name == "animal") {
      form <- if (slope) drmTMB::bf(y ~ x + drmTMB::animal(1 + x | p | id, A = A), sigma ~ drmTMB::animal(1 + x | p | id, A = A)) else drmTMB::bf(y ~ x + drmTMB::animal(1 | p | id, A = A), sigma ~ drmTMB::animal(1 | p | id, A = A))
    } else {
      form <- if (slope) drmTMB::bf(y ~ x + drmTMB::relmat(1 + x | p | id, K = K), sigma ~ drmTMB::relmat(1 + x | p | id, K = K)) else drmTMB::bf(y ~ x + drmTMB::relmat(1 | p | id, K = K), sigma ~ drmTMB::relmat(1 | p | id, K = K))
    }
    drmTMB::drmTMB(form, family = stats::gaussian(), data = dat)
  })
}
