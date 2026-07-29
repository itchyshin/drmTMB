devtools::load_all(quiet = TRUE)
set.seed(20260729)

specifications <- list(
  additive = list(~x1 + x2, c("(Intercept)" = -0.15, x1 = 0.40, x2 = -0.25)),
  mixed = list(~x1 + habitat, c("(Intercept)" = -0.10, x1 = 0.35, habitatforest = 0.20)),
  factor_interaction = list(~x1 + habitat + x1:habitat, c("(Intercept)" = -0.10, x1 = 0.30, habitatforest = 0.15, "x1:habitatforest" = 0.20)),
  numeric_interaction = list(~x1 + x2 + x1:x2, c("(Intercept)" = -0.10, x1 = 0.30, x2 = -0.20, "x1:x2" = 0.20)),
  transformation = list(~x1 + I(x2^2), c("(Intercept)" = -0.10, x1 = 0.30, "I(x2^2)" = 0.20))
)

simulate_pair <- function(alpha, n = 360L) {
  x1 <- seq(-1.2, 1.2, length.out = n)
  x2 <- rep(c(-0.8, -0.1, 0.6), length.out = n)
  habitat <- factor(rep(c("forest", "field"), each = n / 2L))
  data <- data.frame(x1 = x1, x2 = x2, habitat = habitat)
  x_a <- stats::model.matrix(~x1 + x2 + habitat + x1:habitat + x1:x2 + I(x2^2), data)
  coefficient_vector <- setNames(rep(0, ncol(x_a)), colnames(x_a))
  coefficient_vector[names(alpha)] <- alpha
  eta <- 0.999999 * tanh(as.vector(x_a %*% coefficient_vector))
  z_binary <- stats::rnorm(n)
  z_count <- eta * z_binary + sqrt(1 - eta^2) * stats::rnorm(n)
  data$binary <- as.integer(z_binary > stats::qnorm(stats::plogis(-0.2 + 0.25 * x1), lower.tail = FALSE))
  data$count <- drmTMB:::drm_pair_nbinom2_quantile_from_normal(z_count, exp(0.5 + 0.15 * x2), rep(0.6, n))
  data
}

results <- lapply(names(specifications), function(name) {
  specification <- specifications[[name]]
  data <- simulate_pair(specification[[2L]])
  binary_fit <- drmTMB(bf(mu = binary ~x1 + x2), binomial(), data)
  count_fit <- drmTMB(bf(mu = count ~x1 + x2, sigma = ~1), nbinom2(), data)
  fit <- associate_pairs(binary_fit, count_fit, kernel = latent_normal(), association = specification[[1L]])
  if (identical(fit$status, "boundary_unresolved")) stop(sprintf("%s unresolved", name), call. = FALSE)
  if (!identical(names(fit$association_coefficients), names(specification[[2L]]))) stop(sprintf("%s changed coefficient order", name), call. = FALSE)
  prediction <- predict(fit, newdata = data[seq_len(5L), , drop = FALSE])
  if (length(prediction) != 5L || any(!is.finite(prediction))) stop(sprintf("%s prediction failed", name), call. = FALSE)
  data.frame(formula_id = name, status = fit$status, n = nrow(data), max_abs_alpha_error = max(abs(fit$association_coefficients - specification[[2L]])))
})

print(do.call(rbind, results), row.names = FALSE)
