source("tools/cmr_profile_target_extract.R")

partial <- matrix(c(NA_real_, -0.6018527403493983), nrow = 1L,
  dimnames = list("sd_phi:(Intercept)", c("lower", "upper")))
attr(partial, "target_status") <- c("sd_phi:(Intercept)" = "partial")
result <- cmr_profile_target_result(partial)
stopifnot(identical(result$status, "partial"), is.na(result$lower),
  isTRUE(all.equal(result$upper, -0.6018527403493983)))

complete <- matrix(c(-2, 1), nrow = 1L,
  dimnames = list("sd_phi:(Intercept)", c("lower", "upper")))
attr(complete, "target_status") <- c("sd_phi:(Intercept)" = "ok")
stopifnot(identical(cmr_profile_target_result(complete)$status, "ok"))

cat("CMR profile target extractor: 2 assertions passed\n")
