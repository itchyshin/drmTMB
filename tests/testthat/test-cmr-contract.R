test_that("cmr_data rejects malformed CJS histories and interval declarations", {
  y <- rbind(c(1, 0, 0), c(1, 0, 1))
  expect_error(cmr_data(y, id = c("a", NA_character_)), "unique, non-missing")
  expect_error(cmr_data(y, id = c("a", "a")), "unique, non-missing")
  expect_error(cmr_data(rbind(c(0, 0, 0)), id = "z"), "all-zero")
  expect_error(cmr_data(rbind(c(1, 2, 0)), id = "z"), "0, 1")
  expect_error(cmr_data(y, intervals = c(1, 0)), "positive finite")
  expect_error(cmr_data(y, intervals = c(1, Inf)), "positive finite")
  labelled <- cmr_data(y, occasions = c(0, 2, 6), intervals = c(2, 4), units = "years")
  expect_identical(labelled$units, "years")
  expect_equal(labelled$delta, matrix(c(2, 4, 2, 4), nrow = 2, byrow = TRUE))
  expect_error(cmr_data(y, units = 2), "units")
  expect_error(cmr_data(rbind(c(1, 0, 1)), end = 2L), "after the administrative endpoint")
})

test_that("keyed predictor schemas retain shuffled keys, factor levels, and contrasts", {
  y <- rbind(c(1, 0, 0, 0), c(1, 0, 1, 0))
  observed <- rbind(c(TRUE, FALSE, TRUE, TRUE), rep(TRUE, 4))
  d <- cmr_data(y, id = c("a", "b"), observed = observed, occasions = 1:4)
  # Deliberately shuffle keys; detection needs only surveyed post-capture rows.
  p <- data.frame(id = c("b", "a", "b", "a", "b"),
                  occasion = c(4, 4, 2, 3, 3),
                  x = c(24, 14, 22, 13, 23),
                  group = factor(c("C", "B", "A", "A", "B"), levels = c("A", "B", "C")))
  rows <- data.frame(i = rep(1:2, each = 4), t = rep(1:4, 2))
  frame <- .cmr_join_predictors(d, p, rows, "p")
  active <- rows$t > d$first[rows$i] & rows$t <= d$end[rows$i] & d$observed[cbind(rows$i, rows$t)]
  expect_identical(frame$x[active], c(13, 14, 22, 23, 24))
  expect_true(all(is.na(frame$x[!active])))
  supplied_contrast <- contr.sum(3)
  rownames(supplied_contrast) <- c("A", "B", "C")
  contrasts(frame$group) <- supplied_contrast
  design <- .cmr_design(~ group + x, frame, "p", active)
  expect_identical(design$xlevels$group, c("A", "B", "C"))
  expect_identical(colnames(design$X), c("(Intercept)", "group1", "group2", "x"))
  expect_equal(design$X[active, "x"], c(13, 14, 22, 23, 24))
  expect_equal(unname(design$X[active, c("group1", "group2")]),
               rbind(c(1, 0), c(0, 1), c(1, 0), c(0, 1), c(-1, -1)))
  expect_equal(design$contrasts$group, supplied_contrast)
  unknown <- rbind(p, data.frame(id = "ghost", occasion = 3, x = 99,
                                 group = factor("A", levels = levels(p$group))))
  expect_error(.cmr_join_predictors(d, unknown, rows, "p"), "unknown|unexpected|outside")
  missing_key <- rbind(p, data.frame(id = NA_character_, occasion = 3, x = 99,
                                     group = factor("A", levels = levels(p$group))))
  expect_error(.cmr_join_predictors(d, missing_key, rows, "p"), "missing|non-missing|complete")
  missing_result <- tryCatch(.cmr_design(~ x, transform(frame, x = replace(x, which(active)[1], NA_real_)),
                                         "p", active), error = identity)
  expect_s3_class(missing_result, "error")
})

test_that("CJS requires predictors only for post-capture contributing rows", {
  y <- rbind(c(1, 0, 0, 0), c(1, 0, 1, 0))
  observed <- rbind(c(TRUE, FALSE, TRUE, TRUE), rep(TRUE, 4))
  d <- cmr_data(y, id = c("a", "b"), observed = observed, occasions = 1:4)
  # Missing keys for pre-capture and unsurveyed occasions are allowed; the
  # production design builder must omit those rows before model-frame checks.
  p <- data.frame(id = c("a", "a", "b", "b", "b"), occasion = c(3, 4, 2, 3, 4), x = 1:5)
  rows <- data.frame(i = rep(1:2, each = 4), t = rep(1:4, 2))
  frame <- .cmr_join_predictors(d, p, rows, "p")
  active <- rows$t > d$first[rows$i] & rows$t <= d$end[rows$i] & d$observed[cbind(rows$i, rows$t)]
  design <- .cmr_design(~ x, frame, "p", active)
  expect_equal(unname(design$X[!active, , drop = FALSE]), matrix(0, sum(!active), 2))
  expect_equal(design$X[active, "x"], 1:5)
})

test_that("invalid design numerics, aliases, and random terms are explicit errors", {
  frame <- data.frame(x = c(0, 1, 2, 3), z = c(0, 1, 2, 3), off = c(0, 0, Inf, 0))
  active <- rep(TRUE, 4)
  offset_result <- tryCatch(.cmr_design(~ 0 + offset(off), frame, "phi", active), error = identity)
  expect_true(inherits(offset_result, "error"),
              info = if (inherits(offset_result, "error")) conditionMessage(offset_result) else "no error")
  if (inherits(offset_result, "error")) expect_match(conditionMessage(offset_result), "finite")
  aliased <- .cmr_design(~ x + z, frame, "phi", active)
  expect_lt(qr(aliased$X)$rank, ncol(aliased$X))

  d <- cmr_data(rbind(c(1, 0, 1, 0), c(1, 1, 0, 0), c(1, 0, 0, 1), c(1, 1, 1, 0)),
                id = letters[1:4])
  # Persistent individual intercepts are an admitted native route. This
  # contract test guards the unsupported random-slope syntax instead.
  random_result <- tryCatch(drm_cjs(d, phi = ~(1 + x | id), p = ~1,
                                    phi_data = data.frame(
                                      id = rep(letters[1:4], each = 3),
                                      interval_start = rep(1:3, 4),
                                      interval_end = rep(2:4, 4),
                                      x = rep(0:2, 4))), error = identity)
  expect_s3_class(random_result, "error")
  expect_match(if (inherits(random_result, "error")) conditionMessage(random_result) else "",
               "random|unsupported|not supported")
  phi_data <- data.frame(id = rep(letters[1:4], each = 3),
                         interval_start = rep(1:3, 4), interval_end = rep(2:4, 4),
                         x = rep(0:2, 4), z = rep(0:2, 4))
  rank_result <- tryCatch(drm_cjs(d, phi = ~ x + z, p = ~1, phi_data = phi_data), error = identity)
  expect_s3_class(rank_result, "error")
  expect_match(if (inherits(rank_result, "error")) conditionMessage(rank_result) else "",
               "rank deficient|linearly dependent|singular")
})

test_that("terminal time effects are guarded globally, with exactly one constraint", {
  y <- rbind(c(1, 0, 0, 0), c(1, 0, 1, 0), c(1, 1, 0, 0), c(1, 1, 1, 0),
             c(1, 0, 0, 1), c(1, 0, 1, 1), c(1, 1, 0, 1), c(1, 1, 1, 1))
  d <- cmr_data(y, end = c(3L, 3L, 3L, 3L, 4L, 4L, 4L, 4L))
  phi_data <- data.frame(id = rep(seq_len(8), each = 3),
                         interval_start = rep(1:3, 8), interval_end = rep(2:4, 8),
                         year = factor(rep(c("a", "b", "c"), 8)))
  p_data <- data.frame(id = rep(seq_len(8), each = 4), occasion = rep(1:4, 8),
                       year = factor(rep(c("a", "b", "c", "d"), 8)))
  expect_error(drm_cjs(d, phi = ~ year, p = ~ year,
                       phi_data = phi_data, p_data = p_data), "terminal phi and p")
  # A terminal time effect in only one process is allowed.
  fit <- suppressWarnings(drm_cjs(d, phi = ~1, p = ~year,
                                  phi_data = phi_data, p_data = p_data,
                                  control = list(iter.max = 30L)))
  expect_s3_class(fit, "drm_cjs")
  # The constraint applies at declared global occasion 4. ID 1 ends at 3, so
  # its occasion-3 predictor remains free while the global occasion-4 row is fixed.
  fixed <- suppressWarnings(drm_cjs(d, phi = ~1, p = ~1,
                                    terminal_constraint = list(p = 0.4),
                                    control = list(iter.max = 30L)))
  expect_equal(unname(fixed$p$X[3, 1]), 1)
  expect_equal(fixed$p$offset[4], qlogis(0.4))
  expect_equal(unname(fixed$p$X[4, 1]), 0)
  expect_error(drm_cjs(d, phi = ~1, p = ~1,
                       terminal_constraint = list(phi = 0.8, p = 0.4)), "exactly one")
})
