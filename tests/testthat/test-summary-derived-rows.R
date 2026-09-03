# Tests for the summary() derived-row rename (D-213 #1, arc f2, 2026-09-03).
#
# summary()'s derived rows (built by drm_derived_summary_rows(), R/methods.R)
# and the icc()/repeatability() accessors (R/heritability.R) both compute a
# variance ratio for a structured mu random-effect component, but with a
# DIFFERENT denominator:
#   - summary()'s "total_variance_share" / "phylo_total_variance_share" rows
#     divide by the TOTAL variance (every mu random-effect variance in the
#     fit, summed, plus the residual variance) -- same denominator as
#     heritability().
#   - icc() / repeatability() divide by that one component's variance plus
#     the residual only (focal-vs-residual).
# On a fit with exactly one structured mu component the two denominators
# coincide; with two or more they disagree. Before arc f2, summary()'s rows
# were labelled "repeatability"/"phylogenetic_signal", so the same word named
# two different numbers. This file asserts the rename (first test) and makes
# the numeric disagreement visible on a two-component fit (second test),
# rather than a footnote in a design doc.
# See docs/design/259-heritability-icc-repeatability.md section 3 item 5.

test_that("renamed: summary() no longer emits a row called repeatability", {
  set.seed(20260903)
  n_id <- 20
  n_each <- 6
  id <- factor(rep(seq_len(n_id), each = n_each))
  u <- stats::rnorm(n_id, sd = 0.5)
  dat <- data.frame(id = id)
  dat$y <- 0.1 + u[id] + stats::rnorm(nrow(dat), sd = 0.4)

  fit <- drmTMB(bf(y ~ 1 + (1 | id), sigma ~ 1), family = gaussian(), data = dat)
  derived <- summary(fit)$derived

  parm <- "derived:total_variance_share(id)"
  expect_true(parm %in% rownames(derived))
  expect_equal(derived[parm, "quantity"], "total_variance_share")

  # The old label must not appear anywhere: not as a row name, not as a
  # quantity value.
  expect_false("repeatability" %in% rownames(derived))
  expect_false("repeatability" %in% derived$quantity)
  expect_false(any(grepl("^derived:repeatability\\(", rownames(derived))))
})

test_that("denominator: icc() (focal-vs-residual) and summary()'s row (total variance) differ on a two-component fit", {
  # Two structured mu components, so the two denominators genuinely differ:
  # icc()'s focal-vs-residual denominator excludes the second component's
  # variance; summary()'s total-variance denominator includes it.
  set.seed(20260904)
  n_groups <- 15
  n_per <- 8
  n_groups2 <- 6
  grp <- factor(rep(seq_len(n_groups), each = n_per))
  grp2 <- factor(sample(seq_len(n_groups2), n_groups * n_per, replace = TRUE))
  sd_g <- 1
  sd_g2 <- 0.5
  sd_e <- 0.6
  b_g <- rnorm(n_groups, sd = sd_g)
  b_g2 <- rnorm(n_groups2, sd = sd_g2)
  dat <- data.frame(
    y = 2 + b_g[grp] + b_g2[grp2] + rnorm(n_groups * n_per, sd = sd_e),
    grp = grp,
    grp2 = grp2
  )
  fit <- drmTMB(
    bf(y ~ 1 + (1 | grp) + (1 | grp2), sigma ~ 1),
    family = gaussian(),
    data = dat
  )

  sd_focal <- unname(fit$sdpars$mu[["(1 | grp)"]])
  sd_other <- unname(fit$sdpars$mu[["(1 | grp2)"]])
  sigma <- unique(stats::sigma(fit))

  focal_vs_residual <- sd_focal^2 / (sd_focal^2 + sigma^2)
  total_variance_share <- sd_focal^2 / (sd_focal^2 + sd_other^2 + sigma^2)

  # The two denominators genuinely differ for this fit (the point of this
  # test): the second component's variance is strictly positive.
  expect_gt(sd_other, 0)
  expect_false(isTRUE(all.equal(focal_vs_residual, total_variance_share)))

  r_icc <- icc(fit, component = "(1 | grp)")
  derived <- summary(fit)$derived
  parm <- "derived:total_variance_share(grp)"

  expect_equal(r_icc$estimate, focal_vs_residual, tolerance = 1e-10)
  expect_equal(derived[parm, "estimate"], total_variance_share, tolerance = 1e-10)

  # The point of this arc: the two quantities visibly disagree.
  expect_false(isTRUE(all.equal(r_icc$estimate, derived[parm, "estimate"])))
})
