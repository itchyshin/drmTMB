test_that("cumulative-logit selected SD targets use Julia's single sd label", {
  data <- data.frame(
    score = ordered(c("low", "middle", "high", "middle")),
    x = c(-1, 1, -1, 1),
    w = c(-1, -1, 1, 1),
    id = factor(c("a", "a", "b", "b"))
  )
  formulas <- list(
    bf(score ~ x + (1 | id), sd(id, coef = "(Intercept)") ~ w),
    bf(score ~ x + (0 + x | id), sd(id, coef = "x") ~ w)
  )

  labels <- lapply(formulas, function(formula) {
    drmTMB:::drm_julia_bridge_payload_coef_labels(
      formula, data = data, env = environment(), family_type = "cumulative_logit"
    )
  })
  for (target_labels in labels) {
    expect_true("sd" %in% names(target_labels))
    expect_false(any(grepl("^sdtarget_", names(target_labels))))
    expect_identical(target_labels[["sd"]], c("(Intercept)", "w"))
  }
})
