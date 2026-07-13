# Estimator x downstream-surface conformance
# ---------------------------------------------------------------------------
# WHY THIS FILE EXISTS
#
# `REML = TRUE` is not a feature, it is a cross-cutting transformation: it moves
# the mean and scale coefficients out of TMB's `fixed` set and into the Laplace
# `random` block. Everything downstream that reads `opt$par`, `sdr$cov.fixed`, or
# profiles a free parameter is therefore silently affected.
#
# The REML arc validated the estimator on its OWN axis (does it debias? does it
# converge?) and never on the product axis. Every defect found on 2026-07-08 was a
# cell of a grid nobody had enumerated:
#   * `vcov()` reads the JOINT `sdr$cov` under REML, not `cov.fixed`
#   * profile intervals cannot touch fixed effects under REML
#   * the endpoint profile solver errored on an empty free-parameter vector
#   * the missing-data gate tested the SETTING, not whether the engine engaged
#   * spatial / animal / relmat structured effects originally lacked REML rows
#
# So: the grid is declared in
#   docs/dev-log/dashboard/estimator-surface-conformance.tsv
# and this test enforces it. AUTHORITY RULE (as for the q-series board): the TSV
# is truth, prose is derived. An UNDECLARED cell FAILS -- adding a surface to the
# registry below, or a new admission gate, forces you to say what happens.

conformance_table <- function() {
  path <- testthat::test_path("..", "..", "docs", "dev-log", "dashboard",
                              "estimator-surface-conformance.tsv")
  skip_if_not(file.exists(path), "conformance TSV not found")
  # colClasses = "character": otherwise `flag_value` is coerced to logical and
  # `fits[["TRUE"]]` silently becomes `fits[[TRUE]]`.
  utils::read.delim(
    path,
    stringsAsFactors = FALSE,
    na.strings = character(),
    colClasses = "character"
  )
}

# The REGISTRY of downstream surfaces. Adding an S3 method or extractor that a
# user reaches for after a fit means adding it here -- which then forces a row in
# the TSV for BOTH estimators, or this test fails.
conformance_surfaces <- function(sd_parm) {
  list(
    fit = function(f) if (identical(f$opt$convergence, 0L)) "ok" else "nonconvergence",
    sdreport = function(f) f$uncertainty$status,
    vcov = function(f) { stats::vcov(f); "ok" },
    summary_coef_se = function(f) {
      if (all(is.finite(summary(f)$coefficients$std_error))) "ok" else "na"
    },
    confint_wald = function(f) {
      stats::confint(f, parm = "fixef:mu:x", method = "wald"); "ok"
    },
    confint_profile_fixef = function(f) {
      suppressWarnings(stats::confint(f, parm = "fixef:mu:x", method = "profile")); "ok"
    },
    confint_profile_sd = function(f) {
      suppressWarnings(stats::confint(f, parm = sd_parm, method = "profile")); "ok"
    },
    profile_targets = function(f) if (any(profile_targets(f)$profile_ready)) "ok" else "none_ready",
    check_drm = function(f) if (isTRUE(attr(check_drm(f), "ok"))) "ok" else "not_ok",
    ranef = function(f) { ranef(f); "ok" },
    predict = function(f) { stats::predict(f, dpar = "mu"); "ok" },
    simulate = function(f) { stats::simulate(f, nsim = 1L, seed = 1L); "ok" },
    pdHess = function(f) if (isTRUE(f$sdr$pdHess)) "ok" else "false"
  )
}

# The REGISTRY of REML admission gates. Each returns a fit or throws.
conformance_gates <- function(env) {
  ctrl <- env$ctrl
  dat <- env$dat
  tree <- env$tree
  coords <- env$coords
  Kmat <- env$Kmat
  Amat <- env$Amat
  list(
    gate_phylo_mu = function() drmTMB(
      bf(y ~ x + phylo(1 | species, tree = tree)),
      family = gaussian(), data = dat, REML = TRUE, control = ctrl),
    gate_spatial_mu = function() drmTMB(
      bf(y ~ x + spatial(1 | species, coords = coords)),
      family = gaussian(), data = dat, REML = TRUE, control = ctrl),
    gate_animal_mu = function() drmTMB(
      bf(y ~ x + animal(1 | species, A = Amat)),
      family = gaussian(), data = dat, REML = TRUE, control = ctrl),
    gate_relmat_mu = function() drmTMB(
      bf(y ~ x + relmat(1 | species, K = Kmat)),
      family = gaussian(), data = dat, REML = TRUE, control = ctrl),
    gate_poisson = function() drmTMB(
      bf(count ~ x + (1 | id)),
      family = stats::poisson(), data = dat, REML = TRUE, control = ctrl),
    gate_aggregate_gaussian = function() drmTMB(
      bf(y ~ x), family = gaussian(), data = dat, REML = TRUE,
      control = drm_control(aggregate_gaussian = TRUE)),
    gate_sparse_fixed = function() drmTMB(
      bf(y ~ x), family = gaussian(), data = dat, REML = TRUE,
      control = drm_control(sparse_fixed = TRUE)),
    gate_ordinary_direct_sd = function() drmTMB(
      bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ 1),
      family = gaussian(), data = dat, REML = TRUE, control = ctrl),
    gate_missing_engine_complete = function() drmTMB(
      bf(y ~ x), family = gaussian(), data = dat,
      missing = miss_control(response = "include"), REML = TRUE, control = ctrl),
    gate_missing_engine_na = function() {
      d <- dat
      d$y[[2L]] <- NA_real_
      drmTMB(bf(y ~ x), family = gaussian(), data = d,
             missing = miss_control(response = "include"), REML = TRUE, control = ctrl)
    },
    # Ayumi, issue #3: the location-scale-scale model. Declared PLANNED, not silent.
    gate_sd_phylo_plus_sigma_phylo = function() drmTMB(
      bf(y ~ x + phylo(1 | species, tree = tree),
         sigma ~ 1 + phylo(1 | species, tree = tree),
         sd_phylo(species) ~ z_species),
      family = gaussian(), data = dat, REML = TRUE, control = ctrl)
  )
}

# Local copy: testthat does not share top-level objects across test files.
conformance_balanced_tree <- function(n_tip = 8L) {
  stopifnot(n_tip >= 2L, log2(n_tip) == floor(log2(n_tip)))
  edges <- matrix(integer(), ncol = 2L)
  edge_lengths <- numeric()
  next_node <- n_tip + 1L
  build <- function(tips) {
    if (length(tips) == 1L) {
      return(tips)
    }
    node <- next_node
    next_node <<- next_node + 1L
    mid <- length(tips) / 2L
    left <- build(tips[seq_len(mid)])
    right <- build(tips[seq.int(mid + 1L, length(tips))])
    edges <<- rbind(edges, c(node, left), c(node, right))
    edge_lengths <<- c(edge_lengths, 1, 1)
    node
  }
  build(seq_len(n_tip))
  structure(
    list(
      edge = edges,
      edge.length = edge_lengths,
      tip.label = paste0("sp_", seq_len(n_tip)),
      Nnode = n_tip - 1L
    ),
    class = "phylo"
  )
}

conformance_env <- function() {
  n_tip <- 8L
  n_each <- 4L
  tree <- conformance_balanced_tree(n_tip)
  sp <- rep(tree$tip.label, each = n_each)
  set.seed(20260708)
  dat <- data.frame(
    species = sp,
    id = sp,
    x = rep(seq(-0.6, 0.6, length.out = n_each), times = n_tip),
    z_species = rep(seq(-1, 1, length.out = n_tip), each = n_each)
  )
  dat$y <- 0.2 + 0.3 * dat$x +
    rep(seq(-0.4, 0.4, length.out = n_tip), each = n_each) +
    rep(c(-0.08, 0.05, -0.03, 0.04), times = n_tip)
  dat$count <- stats::rpois(nrow(dat), exp(0.4 + 0.2 * dat$x))
  coords <- data.frame(
    x = cos(seq(0, 1.5 * pi, length.out = n_tip)),
    y = sin(seq(0, 1.5 * pi, length.out = n_tip))
  )
  rownames(coords) <- tree$tip.label
  Kmat <- outer(seq_len(n_tip), seq_len(n_tip), function(i, j) 0.35^abs(i - j))
  diag(Kmat) <- diag(Kmat) + 0.15
  dimnames(Kmat) <- list(tree$tip.label, tree$tip.label)
  list(dat = dat, tree = tree, coords = coords, Kmat = Kmat, Amat = Kmat,
       ctrl = drm_control(optimizer = list(eval.max = 400, iter.max = 400)))
}


test_that("the conformance TSV's evidence citations are real and current", {
  # Melissa's audit, 2026-07-08: four `evidence` pointers were already stale hours
  # after being written, because an unrelated comment block shifted the line
  # numbers. The test passed anyway -- it never checked its own citations. A
  # conformance table whose evidence rots is a table nobody can trust.
  #
  # So: every `file:line` must exist, and for a declared REJECTION the cited lines
  # must actually contain the `detail` string the test matches on. That makes a
  # line-number shift a TEST FAILURE, not silent decay.
  tab <- conformance_table()
  root <- testthat::test_path("..", "..")

  for (i in seq_len(nrow(tab))) {
    row <- tab[i, ]
    ev <- row$evidence
    parts <- strsplit(ev, ":", fixed = TRUE)[[1L]]
    file <- parts[[1L]]
    path <- file.path(root, file)
    expect_true(
      file.exists(path),
      info = paste0(row$cell_id, ": evidence file does not exist: ", file)
    )
    if (length(parts) < 2L) next

    lines <- readLines(path, warn = FALSE)
    span <- as.integer(strsplit(parts[[2L]], "-", fixed = TRUE)[[1L]])
    expect_true(
      all(span >= 1L) && all(span <= length(lines)),
      info = paste0(row$cell_id, ": evidence line out of range for ", ev)
    )
    if (!identical(row$expected, "error") || !nzchar(row$detail)) next

    # A cited rejection must be findable at the cited place. Widen slightly: a
    # cli_abort() header sits within a few lines of its `cli::cli_abort(c(` call.
    lo <- max(1L, min(span) - 3L)
    hi <- min(length(lines), max(span) + 6L)
    region <- paste(lines[lo:hi], collapse = "\n")
    expect_true(
      grepl(row$detail, region, fixed = TRUE),
      info = paste0(
        row$cell_id, ": evidence ", ev, " does not contain the detail string \"",
        row$detail, "\". The line numbers have drifted -- update the TSV."
      )
    )
  }
})


test_that("the conformance TSV declares every (estimator x surface) cell", {
  tab <- conformance_table()
  surfaces <- names(conformance_surfaces("dummy"))
  gates <- names(conformance_gates(conformance_env()))

  base <- tab[tab$scenario == "base_gaussian_phylo", ]
  for (flag_value in c("FALSE", "TRUE")) {
    declared <- base$surface[base$flag_value == flag_value]
    undeclared <- setdiff(surfaces, declared)
    stray <- setdiff(declared, surfaces)
    expect_identical(
      undeclared, character(0),
      info = paste0("UNDECLARED cells for REML=", flag_value, ": ",
                    paste(undeclared, collapse = ", "),
                    " -- add a row to estimator-surface-conformance.tsv")
    )
    expect_identical(
      stray, character(0),
      info = paste0("TSV rows with no surface in the registry: ",
                    paste(stray, collapse = ", "))
    )
  }

  declared_gates <- tab$scenario[tab$scenario != "base_gaussian_phylo"]
  expect_setequal(declared_gates, gates)
  expect_true(all(tab$expected %in% c("ok", "error")))
  expect_true(all(nzchar(tab$cell_id)))
  expect_false(any(duplicated(tab$cell_id)))
})


test_that("every declared (REML x surface) cell behaves as the TSV says", {
  skip_on_cran()
  env <- conformance_env()
  fit_base <- function(reml) {
    # `bf()` uses NSE: `tree` must be a bare symbol, not `env$tree`.
    tree <- env$tree
    suppressWarnings(drmTMB(
      bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
      family = gaussian(), data = env$dat, REML = reml, control = env$ctrl
    ))
  }
  fits <- list(`FALSE` = fit_base(FALSE), `TRUE` = fit_base(TRUE))

  targets <- profile_targets(fits[["FALSE"]])
  sd_parm <- targets$parm[targets$profile_ready & grepl("^sd:", targets$parm)][[1L]]
  surfaces <- conformance_surfaces(sd_parm)

  tab <- conformance_table()
  base <- tab[tab$scenario == "base_gaussian_phylo", ]
  for (i in seq_len(nrow(base))) {
    row <- base[i, ]
    f <- fits[[row$flag_value]]
    probe <- surfaces[[row$surface]]
    observed <- tryCatch(probe(f), error = function(e) conditionMessage(e))
    threw <- inherits(tryCatch(probe(f), error = function(e) e), "error")

    if (identical(row$expected, "ok")) {
      expect_false(
        threw,
        info = paste0(row$cell_id, ": expected ok, threw: ", observed)
      )
      expect_identical(
        observed, "ok",
        info = paste0(row$cell_id, ": expected \"ok\", observed \"", observed, "\"")
      )
    } else {
      expect_true(
        threw,
        info = paste0(row$cell_id, ": expected an error, got \"", observed, "\"")
      )
      expect_match(observed, row$detail, fixed = TRUE, info = row$cell_id)
    }
  }
})


test_that("every declared REML admission gate behaves as the TSV says", {
  skip_on_cran()
  env <- conformance_env()
  gates <- conformance_gates(env)
  tab <- conformance_table()
  gate_rows <- tab[tab$scenario %in% names(gates), ]

  for (i in seq_len(nrow(gate_rows))) {
    row <- gate_rows[i, ]
    run <- gates[[row$scenario]]
    result <- tryCatch(suppressWarnings(run()), error = function(e) e)
    if (identical(row$expected, "ok")) {
      expect_false(
        inherits(result, "error"),
        info = paste0(row$cell_id, ": expected admission, got: ",
                      if (inherits(result, "error")) conditionMessage(result) else "")
      )
    } else {
      expect_true(
        inherits(result, "error"),
        info = paste0(row$cell_id, ": expected rejection, but the model FIT. ",
                      "If this capability landed, update the TSV row.")
      )
      expect_match(conditionMessage(result), row$detail, fixed = TRUE, info = row$cell_id)
    }
  }
})
