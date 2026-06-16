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
  expect_error(force(expr), regexp = gate$message_pattern)
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
    "base_nonphylo_count",
    "biv_partial_phylo_q4",
    "biv_rho12_phylo",
    "structured_unsupported_family",
    "structured_sigma_predictor",
    "structured_precision_slot",
    "xfam_missing_route",
    "xfam_rho12_formula",
    "xfam_dispersionless_sigma"
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
    "impute"
  )
  expect_julia_gate(
    "base_control",
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      data = dat,
      control = list(eval.max = 10),
      engine = "julia"
    ),
    "default .*control"
  )
  expect_julia_gate(
    "base_missing_predictor_model",
    drmTMB(
      bf(y ~ mi(x), sigma ~ 1),
      data = dat,
      missing = miss_control(predictor = "model"),
      engine = "julia"
    ),
    "missing.*route|impute"
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
      family = student(),
      data = dat,
      engine = "julia"
    ),
    "Gaussian one-/two-response"
  )
  expect_julia_gate(
    "base_nonphylo_count",
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = nbinom2(),
      data = dat,
      engine = "julia"
    ),
    "only with a .*phylo.* random intercept"
  )
})

test_that("bivariate q4 phylo gates are intentional and pre-JuliaCall", {
  tree <- new_gate_tree(6)
  dat <- data.frame(
    y1 = rnorm(6),
    y2 = rnorm(6),
    x = seq(-1, 1, length.out = 6),
    species = tree$tip.label
  )

  partial_q4 <- bf(
    mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
    mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
    sigma1 = ~1,
    sigma2 = ~1,
    rho12 = ~1
  )
  expect_julia_gate(
    "biv_partial_phylo_q4",
    drmTMB(
      partial_q4,
      family = biv_gaussian(),
      data = dat,
      engine = "julia"
    ),
    "Missing phylogenetic axis"
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
