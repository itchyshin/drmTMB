# Native R drmTMB runner for the refusal-gap map. One process, many cells, one result line per cell.
# Usage: Rscript run_r.R <cells.tsv> <idlist.txt> <start_index> <outfile>
# Env: FUZZ_DATA (data dir), DRMTMB_LIB (library holding drmTMB 0.8.1).
args <- commandArgs(TRUE)
cells_file <- args[1]; idlist <- readLines(args[2]); start <- as.integer(args[3]); outfile <- args[4]
DD <- Sys.getenv("FUZZ_DATA", "data")
if (nzchar(Sys.getenv("DRMTMB_LIB"))) .libPaths(c(Sys.getenv("DRMTMB_LIB"), .libPaths()))
suppressPackageStartupMessages(library(drmTMB))
cells <- read.delim(cells_file, stringsAsFactors = FALSE)
rownames(cells) <- cells$cell_id

tree <- ape::read.tree(file.path(DD, "tree.nwk"))
cc <- read.csv(file.path(DD, "coords.csv")); coords <- as.matrix(cc[, c("easting", "northing")]); rownames(coords) <- cc$id
ids <- read.csv(file.path(DD, "A_ids.csv"))$id
A <- as.matrix(read.csv(file.path(DD, "A.csv"), header = FALSE)); dimnames(A) <- list(ids, ids); K <- A

fam_of <- function(f) switch(f,
  gaussian = gaussian(), poisson = poisson(), nb2 = nbinom2(), gamma = Gamma(link = "log"),
  binomial = binomial(link = "logit"), beta = beta_family(), lognormal = lognormal(),
  student = student(), tweedie = tweedie())
has_sigma <- function(f) !(f %in% c("poisson", "binomial"))
cname_r <- c("(Intercept)", "x1", "x2", "x3")
level_of <- c(animal = "animal", relmat = "relmat", phylo = "phylogenetic", spatial = "spatial")

build <- function(cl) {
  q <- cl$q; kind <- cl$kind
  terms <- c("1", "x1", "x2", "x3")[seq_len(q)]
  bar <- paste(terms, collapse = " + ")
  lab <- if (cl$lab == 1 || cl$cm == 1) " | p | " else " | "
  inner <- paste0(bar, lab, "g")
  re <- switch(kind,
    ordinary = paste0("(", inner, ")"),
    slope = "(0 + x1 | g)",
    indep = paste0("(1 | g)", paste0(" + (0 + ", c("x1", "x2", "x3")[seq_len(q - 1)], " | g)", collapse = "")),
    crossed = paste0("(", inner, ") + (1 | g2)"),
    animal = paste0("animal(", inner, ", A = A)"),
    relmat = paste0("relmat(", inner, ", K = K)"),
    phylo = paste0("phylo(", inner, ", tree = tree)"),
    spatial = paste0("spatial(", inner, ", coords = coords)"))
  mu <- as.formula(paste("y ~ x1 + x2 + x3 +", re)); environment(mu) <- environment()
  sel <- switch(cl$pat, none = integer(0), one = seq_len(q), z = seq_len(q), first = 1L, last = q)
  rhs <- if (cl$pat == "one") "1" else "z"
  lvl <- if (kind %in% names(level_of)) sprintf(', level = "%s"', level_of[[kind]]) else ""
  sds <- lapply(sel, function(j) {
    cf <- if (kind == "slope") ', coef = "x1"' else if (q == 1) "" else sprintf(', coef = "%s"', cname_r[j])
    as.formula(sprintf("sd(g%s%s) ~ %s", lvl, cf, rhs))
  })
  if (kind == "crossed" && cl$pat != "none" && cl$pat != "last") {
    sds <- c(sds, list(as.formula(sprintf("sd(g2) ~ %s", if (cl$pat == "one") "1" else "z2"))))
  }
  parts <- list(mu)
  if (has_sigma(cl$family)) {
    sg <- if (cl$cm == 1) as.formula("~ 1 + (1 | p | g)") else as.formula("~ 1")
    parts <- c(parts, list(sigma = sg))
  }
  do.call(bf, c(parts, sds))
}

full_msg <- function(x) substr(trimws(gsub("[[:space:]]+", " ", paste(x, collapse = " "))), 1, 600)
first_line <- function(x) { x <- gsub("[\t\r]", " ", strsplit(paste(x, collapse = "\n"), "\n")[[1]]); x <- x[nzchar(trimws(x))]; if (length(x)) substr(trimws(x[1]), 1, 400) else "" }
clean_ansi <- function(x) gsub("\033\\[[0-9;]*m", "", x)

run_one <- function(id) {
  cl <- cells[id, ]
  d <- read.csv(file.path(DD, sprintf("data_%s_%s.csv", cl$family, if (cl$kind %in% c("indep", "slope")) "ordinary" else cl$kind)))
  d$g <- factor(d$g, levels = unique(d$g)); d$g2 <- factor(d$g2)
  warn <- character(0)
  t0 <- Sys.time()
  res <- tryCatch(
    withCallingHandlers({
      fm <- build(cl)
      fit <- drmTMB(fm, family = fam_of(cl$family), data = d, REML = (cl$est == "REML"))
      list(ok = TRUE, fit = fit)
    }, warning = function(w) { warn <<- c(warn, conditionMessage(w)); invokeRestart("muffleWarning") }),
    error = function(e) list(ok = FALSE, e = e))
  secs <- as.numeric(Sys.time() - t0, units = "secs")
  w1 <- if (length(warn)) first_line(clean_ansi(warn[1])) else ""
  if (!res$ok) {
    e <- res$e
    cls <- class(e)[1]
    cond <- if (inherits(e, "rlang_error")) "abort" else "base"
    return(c(status = "ERROR", etype = paste0(cond, ":", cls), msg = first_line(clean_ansi(conditionMessage(e))), msgfull = full_msg(clean_ansi(conditionMessage(e))),
             ll = "", conv = "", extra = "", secs = sprintf("%.2f", secs), warn = w1))
  }
  fit <- res$fit
  ll <- tryCatch(as.numeric(logLik(fit)), error = function(e) NA_real_)
  conv <- tryCatch(fit$opt$convergence, error = function(e) NA)
  pd <- tryCatch(isTRUE(fit$sdr$pdHess), error = function(e) NA)
  isc <- tryCatch(isTRUE(drmTMB::is_converged(fit)), error = function(e) NA)
  ok <- is.finite(ll) && identical(as.integer(conv), 0L)
  c(status = if (ok) "FITS" else "NONCONVERGED", etype = "", msg = "", msgfull = "",
    ll = sprintf("%.10f", ll), conv = as.character(conv),
    extra = sprintf("pdHess=%s;is_converged=%s;npar=%d", pd, isc, length(fit$opt$par)),
    secs = sprintf("%.2f", secs), warn = w1)
}

con <- file(outfile, "a")
for (i in seq(start, length(idlist))) {
  id <- idlist[i]
  cat(sprintf("S\t%d\t%s\n", i, id), file = con); flush(con)
  r <- tryCatch(run_one(id), error = function(e) c(status = "RUNNER_ERROR", etype = "runner", msg = first_line(conditionMessage(e)), msgfull = full_msg(conditionMessage(e)), ll = "", conv = "", extra = "", secs = "", warn = ""))
  cat(sprintf("R\t%d\t%s\t%s\n", i, id, paste(gsub("\n", " ", r[c("status", "etype", "msg", "msgfull", "ll", "conv", "extra", "secs", "warn")]), collapse = "\t")), file = con); flush(con)
}
close(con)
