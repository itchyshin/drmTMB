# Dense oracle for the one flagged seed (gauss_lspatial seed 2): exact Gaussian marginal log-likelihood
# y ~ N(X b, sigma^2 I + Z Sigma Z'), (u0,u1) ~ N(0, R kron C), b_k = s_k[g] u_k, rho = 0.999999 tanh(eta),
# evaluated at the Julia estimate and at the R estimate. Kernel C = exp(-d / median d) + 1e-6 I on the 8 x 8 grid.
d <- read.csv("data/gauss_lspatial_s02.csv"); ids <- unique(d$id); n <- nrow(d); G <- length(ids)
cc <- read.csv("coords.csv"); co <- as.matrix(cc[, 2:3]); rownames(co) <- cc$id; co <- co[ids, ]
dd <- as.matrix(dist(co)); C <- exp(-dd / median(dd[upper.tri(dd)])); diag(C) <- diag(C) + 1e-6
gi <- match(d$id, ids); zg0 <- d$z0[match(ids, d$id)]; zg1 <- d$z1[match(ids, d$id)]
Zi <- matrix(0, n, G); Zi[cbind(1:n, gi)] <- 1
oracle <- function(p) {
  b <- p[1:2]; sigma <- exp(p[3]); s0 <- exp(p[4] + p[5] * zg0); s1 <- exp(p[6] + p[7] * zg1); rho <- 0.999999 * tanh(p[8])
  Z0 <- Zi * s0[gi]; Z1 <- (Zi * s1[gi]) * d$x   # loadings for u0 and u1
  V <- sigma^2 * diag(n) + Z0 %*% C %*% t(Z0) + Z1 %*% C %*% t(Z1) + rho * (Z0 %*% C %*% t(Z1) + Z1 %*% C %*% t(Z0))
  r <- d$y - b[1] - b[2] * d$x; ch <- chol(V)
  -0.5 * n * log(2 * pi) - sum(log(diag(ch))) - 0.5 * sum(backsolve(ch, r, transpose = TRUE)^2)
}
j <- read.csv("julia/gauss_lspatial_s02.csv"); r <- read.csv("r/gauss_lspatial_s02.csv")
jl <- read.csv("julia/gauss_lspatial_s02_ll.csv"); rl <- read.csv("r/gauss_lspatial_s02_ll.csv", colClasses = c(ll = "character"))
out <- data.frame(point = c("Julia estimate", "R estimate"), oracle_ll = c(oracle(j$est), oracle(r$est)), reported_ll = c(jl$ll, as.numeric(rl$ll)),
                  eta_cor = c(j$est[8], r$est[8]), rho = 0.999999 * tanh(c(j$est[8], r$est[8])))
out$oracle_minus_reported <- out$oracle_ll - out$reported_ll
# profile in rho: oracle ll at the Julia estimate with eta_cor replaced by a few values
pr <- data.frame(eta = c(0, 1, 2, 3, 5, 8, 11.5896, 19.15), ll = sapply(c(0, 1, 2, 3, 5, 8, 11.5896, 19.15), function(e) { p <- j$est; p[8] <- e; oracle(p) }))
pr$rho <- 0.999999 * tanh(pr$eta)
print(out, digits = 12); print(pr, digits = 12)
write.csv(out, "oracle_lspatial_s02.csv", row.names = FALSE); write.csv(pr, "oracle_lspatial_s02_rho_profile.csv", row.names = FALSE)
