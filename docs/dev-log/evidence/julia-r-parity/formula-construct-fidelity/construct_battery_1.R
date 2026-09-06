# Construct-fidelity battery for DRM.jl #467 / #609.
# For each R formula construct: does it cross engine="julia" with R-contrast
# fidelity, or is it REFUSED with a message naming the construct?
WT <- "/Users/z3437171/local-scratch/parity-joint/wt-jl-467-factors"
suppressMessages(pkgload::load_all(WT, quiet = TRUE, recompile = FALSE))
OUT <- Sys.getenv("BATTERY_OUT", "/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-drmTMB/7db7461b-e1ee-4ad0-a526-010c1c2e26a6/scratchpad/j467/battery-001.tsv")

set.seed(46709L)
n <- 120L
x <- runif(n, -1, 1)
z <- runif(n, -1, 1)
gi <- rep(c(2L, 9L, 10L), length.out = n)              # integer -> factor()
g3 <- factor(rep(c("a", "b", "c"), length.out = n))
g2 <- factor(rep(c("p", "q"), length.out = n))
gchar <- rep(c("a", "b", "c"), length.out = n)          # bare character column
flag <- rep(c(TRUE, FALSE), length.out = n)
gmix <- factor(rep(c("a", "B", "c"), length.out = n))   # locale vs codepoint order
g3rev <- factor(as.character(g3), levels = c("c", "b", "a"))
gempty <- factor(as.character(g3), levels = c("a", "b", "c", "zz"))  # unused level
gord <- factor(as.character(g3), levels = c("a", "b", "c"), ordered = TRUE)
gsum <- g3; stats::contrasts(gsum) <- stats::contr.sum(3)
gnaf <- g3; gnaf[c(5L, 17L)] <- NA

mu_true <- 0.3 + 0.6 * x - 0.4 * z + 0.25 * (g3 == "b") - 0.15 * (g3 == "c")
y <- mu_true + rnorm(n, sd = exp(-0.6 + 0.2 * x))
dat <- data.frame(y, x, z, gi, g3, g2, gchar, flag, gmix, g3rev, gempty,
                  gord, gsum, gnaf, stringsAsFactors = FALSE)

cases <- list(
  numeric_baseline   = "x",
  factor_column      = "g3",
  factor_call_int    = "factor(gi)",
  character_column   = "gchar",
  logical_column     = "flag",
  factor_mixed_case  = "gmix",
  factor_rev_levels  = "g3rev",
  factor_unused_lvl  = "gempty",
  ordered_factor     = "gord",
  contr_sum_factor   = "gsum",
  factor_with_NA     = "gnaf",
  num_by_factor_star = "x * g3",
  num_by_factor_colon= "x + g3 + x:g3",
  factor_by_factor   = "g3 * g2",
  I_square           = "x + I(x^2)",
  I_product          = "x + z + I(x * z)",
  I_nested_in_log    = "log(I(x + 2))",
  poly_2             = "poly(x, 2)",
  poly_in_inter      = "poly(x, 2) * g2",
  scale_x            = "scale(x)",
  crossing_power2    = "(x + z)^2",
  minus_removal      = "x * z - z",
  log_call           = "log(x + 2)",
  factor_call_inter  = "x + factor(gi) + x:factor(gi)",
  sqrt_call          = "sqrt(x + 2)"
)
# a few sigma-side repeats: the design that poisons a scale parameter is
# just as damaging and travels a different label path.
sigma_cases <- list(
  sigma_factor       = list(mu = "x", sigma = "g3"),
  sigma_factor_call  = list(mu = "x", sigma = "factor(gi)"),
  sigma_poly         = list(mu = "x", sigma = "poly(x, 2)"),
  sigma_I            = list(mu = "x", sigma = "I(x^2)")
)

fmt <- function(v) paste(v, collapse = "|")
short <- function(s) {
  s <- gsub("[\r\n\t]+", " ", s)
  s <- gsub(" +", " ", s)
  if (nchar(s) > 400L) paste0(substr(s, 1L, 400L), "...") else s
}

rows <- list()
run_case <- function(nm, mu_rhs, sigma_rhs) {
  f <- eval(str2lang(sprintf("bf(y ~ %s, sigma ~ %s)", mu_rhs, sigma_rhs)),
            envir = globalenv())
  # R's own reference design for the mu part.
  mm_mu <- tryCatch(colnames(stats::model.matrix(
      stats::as.formula(paste("~", mu_rhs)), data = dat)),
    error = function(e) NA_character_)
  mm_sg <- tryCatch(colnames(stats::model.matrix(
      stats::as.formula(paste("~", sigma_rhs)), data = dat)),
    error = function(e) NA_character_)
  fr <- tryCatch(drmTMB(f, data = dat, engine = "tmb"),
                 error = function(e) structure(list(msg = conditionMessage(e)), class = "casefail"))
  fj <- tryCatch(drmTMB(f, data = dat, engine = "julia"),
                 error = function(e) structure(list(msg = conditionMessage(e)), class = "casefail"))
  tmb_err <- inherits(fr, "casefail"); jl_err <- inherits(fj, "casefail")
  status <- NA_character_; detail <- ""; maxdiff <- NA_real_
  jl_names_mu <- NA_character_; jl_names_sg <- NA_character_
  if (tmb_err && jl_err) {
    status <- "BOTH_REFUSE"; detail <- short(fj$msg)
  } else if (tmb_err) {
    status <- "TMB_ONLY_REFUSE"; detail <- short(fr$msg)
  } else if (jl_err) {
    status <- "JULIA_REFUSE"; detail <- short(fj$msg)
  } else {
    cr <- coef(fr); cj <- coef(fj)
    jl_names_mu <- fmt(names(cj$mu)); jl_names_sg <- fmt(names(cj$sigma))
    same_names <- identical(names(cr$mu), names(cj$mu)) &&
                  identical(names(cr$sigma), names(cj$sigma))
    mu_ok <- identical(as.character(mm_mu), names(cj$mu))
    sg_ok <- identical(as.character(mm_sg), names(cj$sigma))
    maxdiff <- max(abs(unlist(cr) - unlist(cj)))
    if (!same_names) {
      status <- "NAMES_DIFFER"
      detail <- paste0("tmb=", fmt(names(cr$mu)), "/", fmt(names(cr$sigma)))
    } else if (!(mu_ok && sg_ok)) {
      status <- "NAMES_NOT_MODELMATRIX"
      detail <- paste0("model.matrix=", fmt(mm_mu), "/", fmt(mm_sg))
    } else if (!is.finite(maxdiff) || maxdiff > 1e-6) {
      status <- "MISLABELLED_SILENT"
      detail <- paste0("identical names, coefficients differ by ", signif(maxdiff, 4))
    } else {
      status <- "FAITHFUL"
    }
  }
  rows[[length(rows) + 1L]] <<- data.frame(
    case = nm, mu = mu_rhs, sigma = sigma_rhs, status = status,
    max_abs_coef_diff = maxdiff,
    r_model_matrix_mu = fmt(mm_mu), julia_names_mu = jl_names_mu,
    r_model_matrix_sigma = fmt(mm_sg), julia_names_sigma = jl_names_sg,
    detail = detail, stringsAsFactors = FALSE)
  cat(sprintf("%-20s %-22s %s\n", nm, status, short(detail)))
  utils::write.table(do.call(rbind, rows), OUT, sep = "\t",
                     row.names = FALSE, quote = FALSE)
}

t0 <- proc.time()[["elapsed"]]
for (nm in names(cases)) run_case(nm, cases[[nm]], "1")
for (nm in names(sigma_cases)) run_case(nm, sigma_cases[[nm]]$mu, sigma_cases[[nm]]$sigma)
cat("elapsed", round(proc.time()[["elapsed"]] - t0, 1), "s\n")
cat("R", R.version.string, "\n")
cat("DRM_JL_PATH", Sys.getenv("DRM_JL_PATH"), "\n")
