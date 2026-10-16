# t6 (sweep-oct16): what predict(se.fit = TRUE) and predict_parameters() do on a
# drmTMB engine = "julia" bridge fit (SPEC P7 on the bridge class; known #1536
# says predict() silently drops unused ... on the native class).
# Run: Rscript R/32_bridge_se.R > logs/bridge_se.log 2>&1
Sys.setenv(JULIA_DEPOT_PATH = "/opt/julia-depot", DRMODELS_JL_PATH = "/home/user/DRModels.jl",
  NOT_CRAN = "true", JULIA_HOME = "/opt/julia-env/bin", JULIA_NUM_THREADS = "1",
  OPENBLAS_NUM_THREADS = "1", OMP_NUM_THREADS = "1")
options(warn = 1, width = 200)
suppressPackageStartupMessages({ library(drmTMB); library(jsonlite) })
if (!exists("%||%", baseenv())) assign("%||%", function(x, y) if (is.null(x)) y else x, envir = globalenv())
source("/home/user/drmTMB/sweep-oct16/t6/R/lib_t6.R")
safe <- function(expr) tryCatch(expr, error = function(e) e)
nd_main <- utils::read.csv(file.path(T6_DATA, "nd_main.csv"), stringsAsFactors = FALSE)
d <- t6_read_cell("gaussian_fixed.csv", "gaussian", "character")
sp <- t6_formula("gaussian", "fixed")
fj <- drmTMB(sp$bf, family = gaussian(), data = d, engine = "julia")
ft <- drmTMB(sp$bf, family = gaussian(), data = d)
out <- list()
p0 <- predict(fj, newdata = nd_main, dpar = "mu")
p1 <- safe(predict(fj, newdata = nd_main, dpar = "mu", se.fit = TRUE))
out$predict_formals <- names(formals(drmTMB:::predict.drmTMB_julia))
out$se_fit_TRUE <- if (inherits(p1, "error")) t6_err(p1) else list(class = class(p1),
  identical_to_plain = identical(p0, p1), is_list = is.list(p1))
p2 <- safe(predict(fj, newdata = nd_main, dpar = "mu", type = "respnse_typo_check_not_used", interval = "confidence"))
out$typo_type <- if (inherits(p2, "error")) t6_err(p2) else "returned values"
p3 <- safe(predict(fj, newdata = nd_main, dpar = "mu", interval = "confidence", level = 0.9))
out$unknown_args_interval_level <- if (inherits(p3, "error")) t6_err(p3) else list(identical_to_plain = identical(p0, p3))
pp <- safe(predict_parameters(fj, newdata = nd_main))
out$predict_parameters <- if (inherits(pp, "error")) t6_err(pp) else list(class = class(pp), names = names(pp))
ppt <- safe(predict_parameters(ft, newdata = nd_main, type = "link", conf.int = TRUE))
out$native_predict_parameters_has_se <- if (inherits(ppt, "error")) t6_err(ppt) else "std.error" %in% names(ppt)
# hand delta-method SE from the bridge vcov for reference
V <- vcov(fj)
out$bridge_vcov_names <- rownames(V)
cat(jsonlite::toJSON(out, auto_unbox = TRUE, pretty = TRUE), "\n")
writeLines(jsonlite::toJSON(out, auto_unbox = TRUE, pretty = TRUE), file.path(T6_RES, "bridge_se.json"))
