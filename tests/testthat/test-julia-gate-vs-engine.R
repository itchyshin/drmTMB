# Gate-vs-engine guard for drmTMB#544.
#
# These tests do not assert that the gated cells are impossible in DRM.jl
# forever. They assert that every currently intentional R-side Julia bridge
# rejection is named in one registry and remains consciously tested. When
# DRM.jl gains a capability, update the registry and relax the corresponding
# R gate in the same PR.

expect_julia_gate <- function(gate_id, expr, regexp) {
  gates <- drmTMB:::drm_julia_intentional_gates()
  expect_true(gate_id %in% gates$gate_id)
  gate <- gates[match(gate_id, gates$gate_id), ]
  expect_equal(gate$action, "error")
  expect_equal(gate$r_bridge_status, "intentional_error")
  if (!missing(regexp)) {
    expect_equal(regexp, gate$message_pattern)
  }
  err <- tryCatch(force(expr), error = function(cnd) cnd)
  expect_s3_class(err, "error")
  if (!inherits(err, "error")) {
    return(invisible(err))
  }
  message <- conditionMessage(err)
  expect_match(message, gate$message_pattern)
  expect_match(
    message,
    paste(
      c(
        "engine\\s*=\\s*\"tmb\"",
        "Supported:",
        "drop",
        "complete responses and predictors",
        "large-p phylogenetic speed edge",
        "coefficient-scale parity tests",
        "latent engine",
        "not wired"
      ),
      collapse = "|"
    ),
    ignore.case = TRUE
  )
  invisible(err)
}

new_gate_tree <- function(n = 6) {
  tree <- ape::rcoal(n)
  tree$edge.length <- rep(1, nrow(tree$edge))
  tree
}

test_that("Julia bridge intentional-gate registry is complete and unique", {
  gates <- drmTMB:::drm_julia_intentional_gates()
  expected_gate_ids <- c(
    "base_weights",
    "base_impute",
    "base_control",
    "base_missing_predictor_model",
    "base_missing_response_nongaussian",
    "base_unsupported_family",
    "biv_invalid_partial_phylo",
    "biv_rho12_phylo",
    "structured_unsupported_family",
    "structured_sigma_predictor",
    "structured_precision_slot",
    "xfam_missing_route",
    "xfam_rho12_formula",
    "xfam_dispersionless_sigma",
    # drmTMB#1146 (DRM.jl#620/#621): non-intercept lhs on a structured marker
    # (phylo/relmat/animal/spatial) refused pre-Julia, defense-in-depth.
    "structured_marker_slope"
  )

  expect_s3_class(gates, "data.frame")
  expect_named(
    gates,
    c(
      "gate_id",
      "route",
      "guard",
      "family_type",
      "syntax",
      "r_bridge_status",
      "drmjl_status",
      "message_pattern",
      "review_due",
      "evidence_url",
      "action",
      "evidence",
      "issue"
    )
  )
  expect_setequal(gates$gate_id, expected_gate_ids)
  expect_equal(anyDuplicated(gates$gate_id), 0L)
  expect_true(all(nzchar(gates$gate_id)))
  expect_true(all(nzchar(gates$route)))
  expect_true(all(nzchar(gates$guard)))
  expect_true(all(nzchar(gates$family_type)))
  expect_true(all(nzchar(gates$syntax)))
  expect_true(all(nzchar(gates$drmjl_status)))
  expect_true(all(nzchar(gates$message_pattern)))
  expect_true(all(nzchar(gates$review_due)))
  expect_true(all(grepl("^https://github.com/", gates$evidence_url)))
  expect_true(all(nzchar(gates$evidence)))
  expect_setequal(gates$r_bridge_status, "intentional_error")
  expect_setequal(gates$action, "error")
  expect_setequal(gates$issue, "drmTMB#544")
})

test_that("dashboard Julia gate artifact matches the registry", {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  gate_paths <- c(
    file.path(pkg, "docs", "dev-log", "dashboard", "julia-gates.tsv"),
    system.file("extdata", "julia-gates.tsv", package = "drmTMB")
  )
  gate_paths <- gate_paths[nzchar(gate_paths) & file.exists(gate_paths)]
  expect_true(length(gate_paths) >= 1L)
  registry <- drmTMB:::drm_julia_intentional_gates()
  registry[] <- lapply(registry, as.character)

  for (gate_path in gate_paths) {
    artifact <- utils::read.delim(
      gate_path,
      stringsAsFactors = FALSE,
      check.names = FALSE,
      quote = ""
    )
    artifact[] <- lapply(artifact, as.character)
    expect_equal(artifact, registry, info = gate_path)
  }
})

test_that("Julia capability comparison artifact matches the registry", {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  capability_paths <- c(
    file.path(pkg, "docs", "dev-log", "dashboard", "julia-capabilities.tsv"),
    system.file("extdata", "julia-capabilities.tsv", package = "drmTMB")
  )
  capability_paths <- capability_paths[
    nzchar(capability_paths) & file.exists(capability_paths)
  ]
  expect_true(length(capability_paths) >= 1L)
  registry <- drmTMB:::drm_julia_capability_comparison()
  registry[] <- lapply(registry, as.character)

  expected_fields <- c(
    "capability_id",
    "route",
    "syntax",
    "r_bridge_status",
    "drmjl_status",
    "claim_status",
    "evidence_url",
    "claim_boundary",
    "next_action",
    "issue"
  )
  expect_named(registry, expected_fields)
  expect_equal(anyDuplicated(registry$capability_id), 0L)
  expect_true(all(nzchar(registry$capability_id)))
  expect_true(all(nzchar(registry$claim_boundary)))
  expect_true(all(grepl("^https://github.com/", registry$evidence_url)))
  expect_true(all(
    registry$r_bridge_status %in%
      c(
        "supported",
        "experimental",
        # "partial" added 2026-09-02 (wave 1 bridge promotion, docs/design/192):
        # same-target point+SE parity receipt on the committed fixture AND the
        # route runs unopted non-interactively; bridge-side inference (G3) stays
        # unqualified. Sits between "experimental" and "supported".
        "partial",
        "intentional_error",
        "planned",
        "unsupported"
      )
  ))
  expect_true(all(
    registry$claim_status %in%
      c(
        "covered",
        "partial",
        "experimental",
        "planned",
        "unsupported",
        "blocked"
      )
  ))
  expect_true("plain_binomial_nonphylo" %in% registry$capability_id)
  binomial_row <- registry[
    registry$capability_id == "plain_binomial_nonphylo",
  ]
  # Wave 1 bridge promotion (owner instruction 2026-09-02, D-203/D-204;
  # docs/dev-log/plan/2026-09-01-bridge-promotion-wave1.md): SE parity
  # 1.26789215931788e-09 abs / 2.482e-08 rel, comparator hash f3e754a4, and
  # the route runs unopted non-interactively post-#1112. This was
  # `expect_equal(binomial_row$r_bridge_status, "experimental")`; it is now
  # inverted rather than deleted, same pattern as the Phase 1.5 / Phase 1
  # inversions above, so an accidental reversion fails loudly.
  expect_equal(binomial_row$r_bridge_status, "partial")
  expect_match(binomial_row$claim_boundary, "Workflow G|expected\\.toml|#499")

  # The single-phylogeny LSS router has selected the sparse O(p) engine above
  # 500 species since DRM.jl #551.  This R-side registry must not tell users it
  # is future work or imply that the forced-dense 5,000-row guard applies to
  # every Julia LSS fit.
  lss_row <- registry[
    registry$capability_id == "location_scale_scale",
  ]
  expect_equal(nrow(lss_row), 1L)
  expect_match(lss_row$claim_boundary, "sparse O\\(p\\).*automatically")
  expect_match(lss_row$next_action, "forced dense")
  expect_false(grepl("underway|cap lifts", lss_row$claim_boundary, ignore.case = TRUE))
  expect_false(grepl("underway|cap lifts", lss_row$next_action, ignore.case = TRUE))

  # Hopper Phase 1.5 admitted trio (DRM.jl #5) — named, not a family expansion.
  expect_true(all(
    c(
      "base_gaussian_location_scale",
      "biv_gaussian_residual",
      "gaussian_phylo_mean"
    ) %in%
      registry$capability_id
  ))
  phase15 <- drmTMB:::drm_julia_phase15_admitted_cells()
  expect_setequal(
    phase15$capability_id,
    c(
      "base_gaussian_location_scale",
      "biv_gaussian_residual",
      "gaussian_phylo_mean"
    )
  )
  # Phase 1.5 cap LIFTED 2026-08-25 (owner decision, Shinichi). This assertion used
  # to read `%in% c("partial", "experimental")`, holding three rows below the status
  # their evidence supported. That was a CRAN-facing governance choice, not an
  # evidence one -- D-164 holds the RELEASE, and it never held the ledger.
  #
  # It is now inverted rather than deleted, so the decision is locked in and an
  # accidental reversion fails loudly. What the promotion claims is a CAPABILITY
  # claim only; the interval_status fences on these rows are UNCHANGED, and the
  # separate coverage_claimed assertions elsewhere in this file still enforce that.
  expect_true(all(phase15$claim_status == "covered"))
  expect_false(any(phase15$r_bridge_status == "intentional_error"))

  # Phase 1 promotions locked (2026-08-27, owner instruction -- the promotion arc,
  # DRM.jl docs/dev-log/plans/2026-08-26-promotion-arc.md). Same pattern as the
  # Phase 1.5 cap inversion above: asserted rather than merely edited, so an
  # accidental reversion fails loudly. Capability claims only -- the
  # interval_status / coverage_claimed fences elsewhere in this file are untouched.
  phase1_promoted <- registry[
    registry$capability_id %in%
      c(
        "phylo_gamma_beta_binomial",
        "general_covariance_structured",
        # Phase 2 (2026-08-27, "do the last two promotions"): each blocker was
        # fixed and re-measured first (DRM.jl PR #517; SE re-bank on build
        # 19ecb005). Same lock rationale as above.
        "phylo_count_large_p",
        "gaussian_response_mask"
      ),
  ]
  expect_equal(nrow(phase1_promoted), 4L)
  expect_true(all(phase1_promoted$claim_status == "covered"))

  # Wave 1 bridge promotion locked (owner instruction 2026-09-02, D-203/D-204;
  # docs/dev-log/plan/2026-09-01-bridge-promotion-wave1.md). experimental ->
  # partial on r_bridge_status for exactly these four rows -- a receipt-verified
  # same-target point+SE parity + unopted non-interactive route bar, NOT a
  # claim_status/covered promotion and NOT an interval_status move. Asserted
  # rather than merely edited, same pattern as the inversions above, so an
  # accidental reversion fails loudly.
  wave1_promoted <- registry[
    registry$capability_id %in%
      c(
        "base_gaussian_location_scale",
        "biv_gaussian_residual",
        "plain_binomial_nonphylo",
        "gaussian_response_mask"
      ),
  ]
  expect_equal(nrow(wave1_promoted), 4L)
  expect_true(all(wave1_promoted$r_bridge_status == "partial"))

  # q4 stays OUT of wave 1 (its Julia SE axis is the fixture's recorded fence;
  # see the plan's CONDITIONS section). Locked so it cannot drift silently.
  q4_row <- registry[registry$capability_id == "biv_q4_phylo_reml", ]
  expect_equal(nrow(q4_row), 1L)
  expect_equal(q4_row$r_bridge_status, "experimental")

  for (capability_path in capability_paths) {
    artifact <- utils::read.delim(
      capability_path,
      stringsAsFactors = FALSE,
      check.names = FALSE,
      quote = ""
    )
    artifact[] <- lapply(artifact, as.character)
    expect_equal(artifact, registry, info = capability_path)
  }
})

test_that("public Julia bridge docs do not outrun the bridge registries", {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  public_paths <- c(
    file.path(pkg, "README.md"),
    file.path(pkg, "NEWS.md"),
    file.path(pkg, "vignettes", "julia-engine.Rmd"),
    file.path(pkg, "vignettes", "cross-family.Rmd")
  )
  public_paths <- public_paths[file.exists(public_paths)]
  skip_if(
    length(public_paths) == 0L,
    "public docs are not available in this installed-package context"
  )
  docs <- paste(
    vapply(
      public_paths,
      function(path) readChar(path, file.info(path)$size, useBytes = TRUE),
      character(1L)
    ),
    collapse = "\n"
  )

  forbidden <- c(
    "engine\\s*=\\s*\"julia\"[^\\n\\.]{0,160}(all|any|every)[^\\n\\.]{0,80}(famil|model)",
    "(binomial|Binomial)[^\\n\\.]{0,80}(bridge|engine\\s*=\\s*\"julia\")[^\\n\\.]{0,80}(ready|supported|covered|available)",
    "(Julia|DRM\\.jl)[^\\n\\.]{0,80}(speed|fast)[^\\n\\.]{0,80}(guarantee|headline|claim)"
  )
  for (pattern in forbidden) {
    expect_false(
      grepl(pattern, docs, ignore.case = TRUE, perl = TRUE),
      info = pattern
    )
  }
})

test_that("base Julia bridge gates are intentional and pre-JuliaCall", {
  dat <- data.frame(y = 1:6, x = seq(-1, 1, length.out = 6))

  expect_julia_gate(
    "base_weights",
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      data = dat,
      weights = rep(1, nrow(dat)),
      engine = "julia"
    ),
    "weights"
  )
  expect_julia_gate(
    "base_impute",
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      data = dat,
      impute = list(x = x ~ 1),
      engine = "julia"
    ),
    "predictor.*model"
  )
  expect_julia_gate(
    "base_control",
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      data = dat,
      control = list(eval.max = 10),
      engine = "julia"
    ),
    "does not support .*control"
  )
  expect_julia_gate(
    "base_missing_predictor_model",
    drmTMB(
      bf(y ~ mi(x), sigma ~ 1),
      data = dat,
      missing = miss_control(predictor = "model"),
      engine = "julia"
    ),
    "impute"
  )
  expect_julia_gate(
    "base_missing_response_nongaussian",
    drmTMB(
      bf(y ~ x),
      family = poisson(),
      data = dat,
      missing = miss_control(response = "include"),
      engine = "julia"
    ),
    "missing.*route"
  )
  expect_julia_gate(
    "base_unsupported_family",
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = beta_binomial(),
      data = dat,
      engine = "julia"
    ),
    "Gaussian one-/two-response|Workflow G fixed-effect"
  )
})

test_that("bivariate invalid phylo gates are intentional and pre-JuliaCall", {
  tree <- new_gate_tree(6)
  dat <- data.frame(
    y1 = rnorm(6),
    y2 = rnorm(6),
    x = seq(-1, 1, length.out = 6),
    species = tree$tip.label
  )

  partial_phylo <- bf(
    mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
    mu2 = y2 ~ x,
    sigma1 = ~1,
    sigma2 = ~1,
    rho12 = ~1
  )
  expect_julia_gate(
    "biv_invalid_partial_phylo",
    drmTMB(
      partial_phylo,
      family = biv_gaussian(),
      data = dat,
      engine = "julia"
    ),
    "requires either q2.*mu1/mu2|q4 all-four-axis|Missing phylogenetic axis"
  )

  rho12_phylo <- bf(
    mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
    mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
    sigma1 = ~ 1 + phylo(1 | p | species, tree = tree),
    sigma2 = ~ 1 + phylo(1 | p | species, tree = tree),
    rho12 = ~ 1 + phylo(1 | p | species, tree = tree)
  )
  expect_julia_gate(
    "biv_rho12_phylo",
    drmTMB(
      rho12_phylo,
      family = biv_gaussian(),
      data = dat,
      engine = "julia"
    ),
    "Unsupported phylogenetic axis"
  )
})

test_that("structured Julia bridge gates are intentional and pre-JuliaCall", {
  dat <- data.frame(
    y = rnorm(6),
    x = seq(-1, 1, length.out = 6),
    id = factor(rep(1:3, each = 2))
  )
  K <- diag(3)
  rownames(K) <- colnames(K) <- levels(dat$id)

  expect_julia_gate(
    "structured_unsupported_family",
    drmTMB(
      bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1),
      family = beta(),
      data = transform(dat, y = pmin(pmax(stats::plogis(y), 0.01), 0.99)),
      engine = "julia"
    ),
    "only for univariate Gaussian, Poisson, NB2, or Gamma"
  )
  expect_julia_gate(
    "structured_sigma_predictor",
    drmTMB(
      bf(y ~ x + relmat(1 | id, K = K), sigma ~ x),
      data = dat,
      engine = "julia"
    ),
    "requires .*sigma ~ 1"
  )
  expect_julia_gate(
    "structured_precision_slot",
    drmTMB(
      bf(y ~ x + relmat(1 | id, Q = K), sigma ~ 1),
      data = dat,
      engine = "julia"
    ),
    "only with a covariance matrix supplied as .*K"
  )
})

test_that("cross-family Julia bridge gates are intentional and pre-JuliaCall", {
  dat <- data.frame(
    y1 = rnorm(8),
    y2 = rpois(8, 3),
    x = seq(-1, 1, length.out = 8)
  )
  fam <- c(gaussian(), poisson())

  expect_julia_gate(
    "xfam_missing_route",
    drmTMB(
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x),
      family = fam,
      data = dat,
      missing = miss_control(response = "include"),
      engine = "julia"
    ),
    "missing.*routes"
  )
  expect_julia_gate(
    "xfam_rho12_formula",
    drmTMB(
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~1),
      family = fam,
      data = dat,
      engine = "julia"
    ),
    "rho12.*not wired"
  )
  expect_julia_gate(
    "xfam_dispersionless_sigma",
    drmTMB(
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma2 = ~x),
      family = fam,
      data = dat,
      engine = "julia"
    ),
    "cannot fit .*sigma2.*dispersion"
  )
})
