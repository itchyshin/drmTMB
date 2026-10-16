# Tiny smoke: native Gaussian (1|g) on y00_x00, plus #1550 %||% probe.
cat("R", R.version.string, "\n")
cat("drmTMB HEAD pin expected ca3ddefa; packageVersion ",
    as.character(utils::packageVersion("drmTMB")), "\n")
d <- read.csv("sweep-oct16/t5/data/gaussian_y00_x00.csv")
library(drmTMB)
t0 <- proc.time()[["elapsed"]]
fit <- drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(), data = d)
cat("native logLik", as.numeric(logLik(fit)), "nobs", nobs(fit),
    "secs", proc.time()[["elapsed"]] - t0, "\n")
cat("base %||% exists:", exists("%||%", envir = baseenv()), "\n")
cat("drmTMB %||% exists:", exists("%||%", envir = asNamespace("drmTMB"), inherits = FALSE), "\n")
# #1550 probe: engine=julia without a %||% shim. Path is set so we reach the
# payload builder rather than the missing-checkout refusal.
Sys.setenv(DRMODELS_JL_PATH = "/tmp/DRModels.jl")
err <- tryCatch({
  drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = d, engine = "julia")
  "NO ERROR"
}, error = function(e) conditionMessage(e))
cat("engine=julia without shim:\n", err, "\n")
