#!/usr/bin/env Rscript
# Independent, fail-closed verifier for run-julia-phylo-labels-public.R receipts.

args <- commandArgs(trailingOnly = TRUE)
usage <- paste(
  "usage: check-julia-phylo-labels-receipt.R RECEIPT.json [--current] [--self-test]",
  "\n  --current    verify the recorded source and runner hashes against this checkout",
  "\n  --self-test  mutate the supplied receipt in memory and require every mutation to fail",
  sep = ""
)
if (length(args) < 1L || any(args %in% c("-h", "--help"))) {
  cat(usage, "\n")
  quit(status = if (length(args) == 0L) 1L else 0L)
}

receipt_path <- args[[1L]]
flags <- args[-1L]
if (!file.exists(receipt_path) || any(!flags %in% c("--current", "--self-test"))) {
  stop(usage, call. = FALSE)
}
if (!requireNamespace("jsonlite", quietly = TRUE) ||
    !requireNamespace("digest", quietly = TRUE)) {
  stop("jsonlite and digest are required for receipt verification", call. = FALSE)
}

fail <- function(...) stop(paste0(...), call. = FALSE)
expect <- function(ok, ...) if (!isTRUE(ok)) fail(...)
field <- function(x, name, where) {
  expect(is.list(x) && !is.null(names(x)) && name %in% names(x),
         where, " is missing required field `", name, "`")
  x[[name]]
}
scalar_character <- function(x, where) {
  expect(is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x),
         where, " must be one nonempty character string")
  x
}
scalar_number <- function(x, where) {
  expect(is.numeric(x) && length(x) == 1L && is.finite(x),
         where, " must be one finite numeric scalar")
  as.numeric(x)
}
scalar_flag <- function(x, where) {
  expect(is.logical(x) && length(x) == 1L && !is.na(x),
         where, " must be one non-missing logical scalar")
  isTRUE(x)
}
numeric_vector <- function(x, where, length = NULL) {
  flat <- unlist(x, recursive = TRUE, use.names = FALSE)
  expect(is.numeric(flat) && all(is.finite(flat)),
         where, " must contain only finite numeric values")
  if (!is.null(length)) {
    expect(length(flat) == length, where, " has length ", length(flat),
           ", expected ", length)
  }
  as.numeric(flat)
}
character_vector <- function(x, where, length = NULL, unique = FALSE) {
  flat <- unlist(x, recursive = TRUE, use.names = FALSE)
  expect(is.character(flat) && all(!is.na(flat)) && all(nzchar(flat)),
         where, " must contain only nonempty character values")
  if (!is.null(length)) {
    expect(length(flat) == length, where, " has length ", length(flat),
           ", expected ", length)
  }
  if (unique) expect(!anyDuplicated(flat), where, " must be unique")
  as.character(flat)
}
numeric_matrix <- function(x, where, nrow, ncol) {
  expect(is.list(x) && length(x) == nrow, where, " must have ", nrow, " rows")
  rows <- lapply(seq_len(nrow), function(i) numeric_vector(x[[i]],
    paste0(where, " row ", i), ncol))
  matrix(unlist(rows, use.names = FALSE), nrow = nrow, ncol = ncol, byrow = TRUE)
}
max_abs <- function(x) {
  expect(length(x) > 0L && all(is.finite(x)), "non-finite difference")
  max(abs(x))
}

parse_data <- function(data, labels) {
  expect(is.list(data) && length(data) > 0L, "result$data must be a nonempty row list")
  n <- length(data)
  out <- lapply(c("y", "x", "z"), function(name) vapply(seq_len(n), function(i) {
    scalar_number(field(data[[i]], name, paste0("result$data row ", i)),
                  paste0("result$data row ", i, "$", name))
  }, numeric(1)))
  names(out) <- c("y", "x", "z")
  out$species <- vapply(seq_len(n), function(i) {
    scalar_character(field(data[[i]], "species", paste0("result$data row ", i)),
                     paste0("result$data row ", i, "$species"))
  }, character(1))
  expect(all(out$species %in% labels), "result$data$species contains a label absent from result$labels")
  out
}

parse_fit <- function(x, where, n = NULL, require_runtime = FALSE) {
  mu <- numeric_vector(field(x, "mu", where), paste0(where, "$mu"), 2L)
  sigma <- numeric_vector(field(x, "sigma", where), paste0(where, "$sigma"), 2L)
  sd_phylo <- numeric_vector(field(x, "sd_phylo", where), paste0(where, "$sd_phylo"), 2L)
  loglik <- scalar_number(field(x, "loglik", where), paste0(where, "$loglik"))
  converged <- scalar_flag(field(x, "converged", where), paste0(where, "$converged"))
  result <- list(mu = mu, sigma = sigma, sd_phylo = sd_phylo,
                 loglik = loglik, converged = converged)
  if (!is.null(n)) result$fitted <- numeric_vector(field(x, "fitted", where),
    paste0(where, "$fitted"), n)
  if (isTRUE(require_runtime)) {
    result$labels <- character_vector(field(x, "labels", where),
      paste0(where, "$labels"), unique = TRUE)
    result$threads <- scalar_number(field(x, "threads", where), paste0(where, "$threads"))
    result$blas <- scalar_number(field(x, "blas", where), paste0(where, "$blas"))
    result$source <- scalar_character(field(x, "source", where), paste0(where, "$source"))
  }
  result
}

gaussian_components <- function(fit, data, correlation, group_covariate, labels) {
  index <- match(data$species, labels)
  expect(!anyNA(index), "species-to-label map is incomplete")
  log_sigma <- fit$sigma[[1L]] + fit$sigma[[2L]] * data$x
  log_sd <- fit$sd_phylo[[1L]] + fit$sd_phylo[[2L]] * group_covariate
  expect(all(is.finite(log_sigma)) && all(is.finite(log_sd)),
         "linear predictors must be finite")
  residual_sd <- exp(log_sigma)
  group_sd <- exp(log_sd)
  expect(all(is.finite(residual_sd) & residual_sd > 0) &&
           all(is.finite(group_sd) & group_sd > 0),
         "variance scales must be positive and finite")
  covariance <- diag(residual_sd^2) +
    (group_sd[index] %o% group_sd[index]) * correlation[index, index, drop = FALSE]
  factor <- tryCatch(chol(covariance), error = function(e) NULL)
  expect(!is.null(factor), "reconstructed Gaussian covariance is not positive definite")
  residual <- data$y - fit$mu[[1L]] - fit$mu[[2L]] * data$x
  list(index = index, covariance = covariance, factor = factor, residual = residual,
       group_covariance = (group_sd %o% group_sd) * correlation)
}

gaussian_likelihood <- function(fit, data, correlation, group_covariate, labels) {
  parts <- gaussian_components(fit, data, correlation, group_covariate, labels)
  -.5 * (length(parts$residual) * log(2 * pi) +
    2 * sum(log(diag(parts$factor))) +
    sum(backsolve(parts$factor, parts$residual, transpose = TRUE)^2))
}

newick_label <- function(label) {
  expect(is.character(label) && length(label) == 1L && !is.na(label) && nzchar(label),
         "tree label must be one nonempty string")
  if (grepl("^[A-Za-z0-9_.-]+$", label, perl = TRUE)) return(label)
  paste0("'", gsub("'", "''", label, fixed = TRUE), "'")
}

tree_covariance <- function(edge, edge_length, labels) {
  p <- length(labels)
  expect(ncol(edge) == 2L && nrow(edge) == length(edge_length),
         "tree edge and branch-length dimensions disagree")
  expect(all(is.finite(edge)) && all(edge == as.integer(edge)) && all(edge >= 1),
         "tree edge identifiers must be positive finite integers")
  expect(all(is.finite(edge_length)) && all(edge_length > 0),
         "tree branch lengths must be positive finite values")
  edge <- matrix(as.integer(edge), ncol = 2L)
  node_ids <- unique(as.integer(c(edge)))
  n_total <- max(node_ids)
  expect(identical(sort(node_ids), seq_len(n_total)), "tree node identifiers are not contiguous")
  parent <- edge[, 1L]
  child <- edge[, 2L]
  expect(!anyDuplicated(child), "tree assigns more than one parent to a node")
  expect(!any(parent <= p), "tree assigns children to a leaf node")
  expect(all(seq_len(p) %in% child), "tree is missing one or more labeled leaves")
  expect(!any(seq_len(p) %in% parent), "tree labels are not leaves")
  roots <- setdiff(unique(parent), child)
  expect(length(roots) == 1L, "tree must have exactly one root")
  root <- roots[[1L]]
  children <- lapply(seq_len(n_total), function(node) which(parent == node))
  names(children) <- as.character(seq_len(n_total))
  internal <- setdiff(seq_len(n_total), seq_len(p))
  expect(all(vapply(internal, function(node) length(children[[node]]) >= 2L, logical(1))),
         "tree has an unsupported unary or disconnected internal node")

  depth <- rep(NA_real_, n_total)
  depth[[root]] <- 0
  queue <- root
  cursor <- 1L
  while (cursor <= length(queue)) {
    node <- queue[[cursor]]
    for (edge_row in children[[node]]) {
      descendant <- child[[edge_row]]
      depth[[descendant]] <- depth[[node]] + edge_length[[edge_row]]
      queue <- c(queue, descendant)
    }
    cursor <- cursor + 1L
  }
  expect(!anyNA(depth), "tree is disconnected or cyclic")

  ancestors <- function(node) {
    out <- integer()
    current <- node
    repeat {
      out <- c(out, current)
      if (identical(current, root)) break
      row <- match(current, child)
      expect(!is.na(row), "tree ancestor path is incomplete")
      current <- parent[[row]]
    }
    out
  }
  covariance <- matrix(0, p, p)
  for (i in seq_len(p)) for (j in seq_len(p)) {
    common <- intersect(ancestors(i), ancestors(j))
    expect(length(common) > 0L, "tree leaves have no common ancestor")
    covariance[i, j] <- max(depth[common])
  }
  height <- diag(covariance)
  expect(max_abs(height - height[[1L]]) <= 1e-12,
         "recorded tree is not ultrametric and cannot yield a correlation matrix")

  build_newick <- function(node) {
    if (node <= p) {
      label <- newick_label(labels[[node]])
    } else {
      child_rows <- children[[node]]
      label <- paste0("(", paste(vapply(child_rows, function(edge_row) {
        build_newick(child[[edge_row]])
      }, character(1)), collapse = ","), ")")
    }
    if (identical(node, root)) return(label)
    edge_row <- match(node, child)
    paste0(label, ":", format(edge_length[[edge_row]], scientific = FALSE,
                                digits = 17L, trim = TRUE))
  }
  list(covariance = covariance, correlation = covariance / height[[1L]],
       newick = paste0(build_newick(root), ";"), root = root)
}

validate_manifest <- function(before, after, current = FALSE, rroot = NULL) {
  expect(is.list(before) && is.list(after) && !is.null(names(before)) && !is.null(names(after)),
         "source manifests must be named lists")
  expect(identical(sort(names(before)), sort(names(after))) && length(before) > 0L,
         "source_before/source_after keys differ")
  for (path in names(before)) {
    a <- scalar_character(before[[path]], paste0("source_before$", path))
    b <- scalar_character(after[[path]], paste0("source_after$", path))
    expect(grepl("^[0-9a-f]{64}$", a) && grepl("^[0-9a-f]{64}$", b),
           "source hash is not SHA-256 for ", path)
    expect(identical(a, b), "source changed during runner: ", path)
    if (isTRUE(current)) {
      target <- if (grepl("^R/", path)) file.path(rroot, path) else path
      expect(file.exists(target), "recorded source path is absent now: ", target)
      expect(identical(digest::digest(file = target, algo = "sha256"), a),
             "current source hash differs from receipt: ", path)
    }
  }
  expect(any(names(before) == "R/julia-bridge.R"), "manifest lacks R/julia-bridge.R")
  expect(any(grepl("/src/sparse_phy[.]jl$", names(before))), "manifest lacks src/sparse_phy.jl")
}

validate_receipt <- function(receipt, current = FALSE, rroot = NULL) {
  expect(is.list(receipt), "receipt root must be an object")
  expect(identical(scalar_character(field(receipt, "status", "receipt"), "receipt$status"), "PASS"),
         "receipt$status must be PASS")
  expect(scalar_flag(field(receipt, "source_unchanged", "receipt"), "receipt$source_unchanged"),
         "receipt declares source changes")
  source_before <- field(receipt, "source_before", "receipt")
  source_after <- field(receipt, "source_after", "receipt")
  validate_manifest(source_before, source_after, current, rroot)
  expected_runner <- scalar_character(field(receipt, "runner_sha256", "receipt"), "receipt$runner_sha256")
  expect(grepl("^[0-9a-f]{64}$", expected_runner), "runner_sha256 is not SHA-256")
  if (isTRUE(current)) {
    runner <- file.path(rroot, "tools", "run-julia-phylo-labels-public.R")
    expect(file.exists(runner), "current runner is absent: ", runner)
    expect(identical(digest::digest(file = runner, algo = "sha256"), expected_runner),
           "current runner hash differs from receipt")
  }

  result <- field(receipt, "result", "receipt")
  expect(identical(scalar_character(field(result, "status", "result"), "result$status"), "PASS"),
         "result$status must be PASS")
  checks <- field(result, "checks", "result")
  required_checks <- c("names", "covariance", "likelihood", "native_parity",
                       "bridge_parity", "rows", "converged", "source")
  expect(is.list(checks) && all(required_checks %in% names(checks)),
         "result$checks is incomplete")
  for (name in required_checks) expect(scalar_flag(checks[[name]], paste0("result$checks$", name)),
                                       "runner recorded failed check: ", name)

  labels <- character_vector(field(result, "labels", "result"), "result$labels", unique = TRUE)
  p <- length(labels)
  expect(p >= 2L, "at least two labels are required")
  payload <- field(result, "payload", "result")
  tip_order <- character_vector(field(payload, "tip_order", "result$payload"),
    "result$payload$tip_order", p, unique = TRUE)
  expect(identical(tip_order, labels), "payload tip_order differs from result labels")
  recorded_newick <- scalar_character(field(payload, "newick", "result$payload"),
                                      "result$payload$newick")
  data <- parse_data(field(result, "data", "result"), labels)
  n <- length(data$y)
  permutation <- numeric_vector(field(result, "permutation", "result"), "result$permutation", n)
  expect(all(permutation == as.integer(permutation)) && identical(sort(as.integer(permutation)), seq_len(n)),
         "result$permutation must be a permutation of 1:n")
  permutation <- as.integer(permutation)
  # Older label receipts explicitly sorted direct input in their scope text.
  # New identity receipts declare whether direct Julia received original rows.
  direct_order <- if ("direct_order" %in% names(result))
    scalar_character(result$direct_order, "result$direct_order") else "tree"
  expect(direct_order %in% c("tree", "input"), "unknown direct-row order contract")
  if (direct_order == "input") {
    expect(identical(permutation, seq_len(n)), "input-order direct fit was reordered")
    expect(!identical(unique(data$species), tip_order),
           "input-order identity fixture does not challenge first-seen tip ordering")
  } else {
    expect(identical(permutation, order(match(data$species, tip_order))),
           "tree-order direct fit permutation differs from the declared order")
  }
  correlation <- numeric_matrix(field(result, "native_correlation", "result"),
    "result$native_correlation", p, p)
  expect(max_abs(correlation - t(correlation)) <= 1e-12,
         "native correlation is not symmetric")
  expect(max_abs(diag(correlation) - 1) <= 1e-12,
         "native correlation diagonal is not one")
  expect(!is.null(tryCatch(chol(correlation), error = function(e) NULL)),
         "native correlation is not positive definite")
  group_covariate <- numeric_vector(field(result, "group_covariate", "result"),
    "result$group_covariate", p)
  group_index <- match(data$species, labels)
  expect(max_abs(data$z - group_covariate[group_index]) <= 1e-12,
         "data z is not aligned to the recorded group covariate/labels")
  edge_length <- numeric_vector(field(result, "tree_edge_length", "result"),
                                "result$tree_edge_length")
  tree_edge <- numeric_matrix(field(result, "tree_edge", "result"),
                              "result$tree_edge", length(edge_length), 2L)
  tree <- tree_covariance(tree_edge, edge_length, labels)
  expect(identical(recorded_newick, tree$newick),
         "payload Newick does not exactly encode recorded tree edges, lengths, and labels")
  expect(max_abs(correlation - tree$correlation) <= 1e-12,
         "native correlation differs from the independently reconstructed tree correlation")

  outputs <- field(result, "outputs", "result")
  native <- parse_fit(field(outputs, "native", "result$outputs"), "result$outputs$native")
  bridge <- parse_fit(field(outputs, "bridge", "result$outputs"), "result$outputs$bridge")
  direct_raw <- field(outputs, "direct", "result$outputs")
  direct <- parse_fit(direct_raw, "result$outputs$direct", n, require_runtime = TRUE)
  expect(identical(direct$labels, tip_order), "direct labels differ from payload tip_order")
  expect(identical(direct$threads, 1) && identical(direct$blas, 1),
         "direct receipt must use one Julia and one BLAS thread")
  drm_sources <- names(source_before)[grepl("/src/DRM[.]jl$", names(source_before))]
  expect(length(drm_sources) == 1L, "source manifest must identify exactly one Julia DRM.jl")
  expect(identical(normalizePath(direct$source, mustWork = FALSE), normalizePath(drm_sources, mustWork = FALSE)),
         "direct source path is not the exact DRM.jl recorded in the manifest")
  direct_covariance <- numeric_matrix(field(direct_raw, "covariance", "result$outputs$direct"),
    "result$outputs$direct$covariance", p, p)
  expect(max_abs(direct_covariance - tree$covariance) <= 1e-12,
         "direct covariance differs from the independently reconstructed raw tree covariance")
  expect(all(c(native$converged, bridge$converged, direct$converged)),
         "one or more fits did not converge")

  tolerance <- 4e-6
  likelihood_tolerance <- 1e-7
  for (engine in c("native", "bridge", "direct")) {
    pair <- list(native = native, bridge = bridge, direct = direct)[[engine]]
    ll <- gaussian_likelihood(pair, data, correlation, group_covariate, labels)
    expect(abs(pair$loglik - ll) <= likelihood_tolerance,
           "independent Gaussian likelihood mismatch for ", engine, ": ",
           format(abs(pair$loglik - ll), digits = 17))
  }
  for (name in c("mu", "sigma", "sd_phylo", "loglik")) {
    expect(max_abs(native[[name]] - direct[[name]]) <= tolerance,
           "native/direct ", name, " exceeds 4e-6")
    expect(max_abs(bridge[[name]] - direct[[name]]) <= tolerance,
           "bridge/direct ", name, " exceeds 4e-6")
  }
  bridge_fitted <- numeric_vector(field(result, "bridge_fitted", "result"),
    "result$bridge_fitted", n)
  expect(max_abs(bridge_fitted - direct$fitted[order(permutation)]) <= 1e-8,
         "bridge fitted values do not invert the recorded direct-row permutation")
  direct_data <- lapply(data, function(column) column[permutation])
  expected_direct_fitted <- direct$mu[[1L]] + direct$mu[[2L]] * direct_data$x
  expect(max_abs(direct$fitted - expected_direct_fitted) <= 1e-8,
         "direct fitted values do not equal their fixed-mean mu design in direct-row order")

  list(labels = p, rows = n, tolerance = tolerance, checks = length(required_checks))
}

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_path <- if (length(script_arg) == 1L) normalizePath(sub("^--file=", "", script_arg)) else NA_character_
rroot <- if (is.na(script_path)) getwd() else dirname(dirname(script_path))
receipt <- jsonlite::fromJSON(receipt_path, simplifyVector = FALSE)
summary <- validate_receipt(receipt, current = "--current" %in% flags, rroot = rroot)

if ("--self-test" %in% flags) {
  copy_receipt <- function(x) unserialize(serialize(x, NULL))
  mutations <- list(
    order_contract = function(x) { x$result$direct_order <- "unknown"; x },
    labels = function(x) { x$result$outputs$direct$labels[[1L]] <- "tampered"; x },
    rows = function(x) { x$result$permutation[[1L]] <- x$result$permutation[[2L]]; x },
    coefficients = function(x) { x$result$outputs$direct$mu[[1L]] <- x$result$outputs$direct$mu[[1L]] + 0.05; x },
    likelihood = function(x) { x$result$outputs$native$loglik <- x$result$outputs$native$loglik + 0.05; x },
    source = function(x) { x$source_after[[1L]] <- strrep("0", 64L); x },
    resources = function(x) { x$result$outputs$direct$threads <- 2; x },
    newick = function(x) { x$result$payload$newick <- "(tampered:1);"; x },
    covariance = function(x) { x$result$outputs$direct$covariance[[1L]][[1L]] <- 99; x },
    fitted = function(x) {
      x$result$outputs$direct$fitted[[1L]] <- x$result$outputs$direct$fitted[[1L]] + 0.05
      bridge_row <- which(order(as.integer(unlist(x$result$permutation))) == 1L)
      x$result$bridge_fitted[[bridge_row]] <- x$result$bridge_fitted[[bridge_row]] + 0.05
      x
    },
    nonfinite = function(x) { x$result$outputs$bridge$sigma[[1L]] <- NaN; x },
    shape = function(x) { x$result$native_correlation[[1L]] <- list(1); x }
  )
  for (name in names(mutations)) {
    damaged <- mutations[[name]](copy_receipt(receipt))
    rejected <- inherits(try(validate_receipt(damaged, current = FALSE, rroot = rroot), silent = TRUE), "try-error")
    expect(rejected, "self-test mutation was accepted: ", name)
    cat("SELFTEST_REJECTED ", name, "\n", sep = "")
  }
}

cat("PHYLO_LABEL_RECEIPT_PASS labels=", summary$labels,
    " rows=", summary$rows,
    " checks=", summary$checks,
    " tolerance=", format(summary$tolerance, scientific = TRUE), "\n", sep = "")
