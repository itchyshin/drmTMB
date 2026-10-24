# FX6b t10-grid parametric bootstrap type-I (16 Oct 2026).
# Usage: T10_CELL=nb2|re T10_NREP=500 T10_NSIM=99 Rscript tools/fx6b-t10-bootstrap.R
# Optional sharding: T10_FIRST (first i, default 0) and T10_CSV (output path)
# let several processes run disjoint seed blocks into separate CSVs.
#
# Same DGPs and official seeds as sweep-oct16/t10. Each outer draw fits the
# reduced/full pair, then anova(..., test = "bootstrap"). Pass bar: type-I at
# alpha = 0.05 in [4%, 6%].

pkg_root <- Sys.getenv("FX6B_PKG", "/workspace")
if (requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(pkg_root, helpers = FALSE, quiet = TRUE)
} else {
  suppressPackageStartupMessages(library(drmTMB))
}

cell <- Sys.getenv("T10_CELL", "nb2")
nrep <- as.integer(Sys.getenv("T10_NREP", "500"))
nsim <- as.integer(Sys.getenv("T10_NSIM", "99"))
first <- as.integer(Sys.getenv("T10_FIRST", "0"))
seed0 <- 20261017000
log_dir <- Sys.getenv("FX6B_LOG", "/workspace/docs/dev-log/after-task/fx6b-t10-logs")
dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)
csv_path <- Sys.getenv("T10_CSV", file.path(log_dir, sprintf("r_%s_bootstrap.csv", cell)))
ctrl <- drm_control(se = FALSE, keep_tmb_object = FALSE, keep_model_frame = FALSE)

header <- paste(
  "engine", "cell", "seed", "status",
  "statistic", "pvalue", "p_method", "nsim", "failed",
  "chibar_p", "naive_p",
  "elapsed", "error",
  sep = ","
)
if (!file.exists(csv_path)) {
  writeLines(header, csv_path)
}
done <- if (file.exists(csv_path) && file.size(csv_path) > nchar(header)) {
  unique(utils::read.csv(csv_path, stringsAsFactors = FALSE)$seed)
} else {
  numeric()
}

append_row <- function(...) {
  dots <- list(...)
  vals <- vapply(dots, function(v) {
    if (is.null(v) || (length(v) == 1L && is.na(v))) ""
    else if (is.character(v)) gsub("[\n,]", " ", v)
    else format(v, digits = 16, scientific = TRUE)
  }, character(1L))
  cat(paste(vals, collapse = ","), "\n", file = csv_path, append = TRUE, sep = "")
}

make_data <- function(official) {
  set.seed(as.integer(official - 1.9e10))
  if (identical(cell, "nb2")) {
    n <- 250L
    dat <- data.frame(x = stats::rnorm(n))
    dat$y <- stats::rpois(n, lambda = exp(0.4 + 0.3 * dat$x))
    return(dat)
  }
  if (identical(cell, "re")) {
    G <- 25L
    m <- 12L
    g <- factor(rep(seq_len(G), each = m))
    x <- stats::rnorm(G * m)
    return(data.frame(g = g, x = x, y = 0.4 - 0.5 * x + 0.7 * stats::rnorm(G * m)))
  }
  stop("T10_CELL must be nb2 or re, got: ", cell)
}

fit_pair <- function(dat) {
  if (identical(cell, "nb2")) {
    list(
      reduced = drmTMB(bf(y ~ x), family = stats::poisson(), data = dat, control = ctrl),
      full = drmTMB(bf(y ~ x, sigma ~ 1), family = nbinom2(), data = dat, control = ctrl)
    )
  } else {
    list(
      reduced = drmTMB(bf(y ~ x, sigma ~ 1), family = stats::gaussian(), data = dat, control = ctrl),
      full = drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = stats::gaussian(), data = dat, control = ctrl)
    )
  }
}

for (i in first + seq_len(nrep) - 1L) {
  official <- seed0 + i
  if (official %in% done) {
    next
  }
  t0 <- proc.time()[["elapsed"]]
  out <- tryCatch(
    {
      dat <- make_data(official)
      fits <- fit_pair(dat)
      a <- suppressWarnings(anova(
        fits$reduced,
        fits$full,
        test = "bootstrap",
        nsim = nsim,
        seed = as.integer(official - 1.9e10)
      ))
      lb <- tryCatch(
        lrt_boundary(fits$full, fits$reduced, q = 1),
        error = function(e) NULL
      )
      list(
        status = "OK",
        statistic = a$Chisq[[2L]],
        pvalue = a$`Pr(>Chisq)`[[2L]],
        p_method = attr(a, "p.method")[[2L]],
        nsim = attr(a, "bootstrap.nsim")[[2L]],
        failed = attr(a, "bootstrap.failed")[[2L]],
        chibar_p = if (is.null(lb)) NA_real_ else lb$pvalue,
        naive_p = if (is.null(lb)) NA_real_ else lb$pvalue_naive,
        error = NA_character_
      )
    },
    error = function(e) {
      list(
        status = "ERROR",
        statistic = NA_real_,
        pvalue = NA_real_,
        p_method = NA_character_,
        nsim = nsim,
        failed = NA_integer_,
        chibar_p = NA_real_,
        naive_p = NA_real_,
        error = conditionMessage(e)
      )
    }
  )
  append_row(
    "r", cell, official, out$status,
    out$statistic, out$pvalue, out$p_method, out$nsim, out$failed,
    out$chibar_p, out$naive_p,
    proc.time()[["elapsed"]] - t0,
    out$error
  )
}

tab <- utils::read.csv(csv_path, stringsAsFactors = FALSE)
ok <- tab[tab$status == "OK", , drop = FALSE]
type1 <- if (nrow(ok) == 0L) NA_real_ else mean(ok$pvalue < 0.05)
cat(
  sprintf(
    "FX6b %s: %d/%d OK; type-I = %.1f%% (%d/%d); nsim = %d\n",
    cell, nrow(ok), nrep, 100 * type1, sum(ok$pvalue < 0.05), nrow(ok), nsim
  )
)
