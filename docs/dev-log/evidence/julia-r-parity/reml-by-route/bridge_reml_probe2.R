suppressMessages(devtools::load_all("/Users/z3437171/local-scratch/parity-joint/wt-a9f-reml-table", quiet = TRUE))
`%||%` <- function(a, b) if (is.null(a) || (length(a) == 1 && is.na(a))) b else a
set.seed(1)
n <- 60
x <- rnorm(n)
g <- factor(rep(1:12, length.out = n))
K <- diag(12) * 0.7 + 0.3
rownames(K) <- colnames(K) <- levels(g)
ypo <- rpois(n, exp(0.2 + 0.1 * x))
d <- data.frame(y = ypo, x = x, g = g)

t0 <- Sys.time()
res <- tryCatch(
  drmTMB(bf(y ~ x + relmat(1 | g, K = K)), family = poisson(), data = d, REML = TRUE, engine = "julia"),
  error = function(e) e
)
cat(sprintf("elapsed %.1fs\n", as.numeric(difftime(Sys.time(), t0, units = "secs"))))
if (inherits(res, "error")) {
  cat("OUTCOME=REFUSES\nMESSAGE=", conditionMessage(res), "\n")
} else {
  cat("OUTCOME=FITS\nloglik=", as.numeric(stats::logLik(res)), "\n")
}
cat("DONE2\n")
