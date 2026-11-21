# usage: Rscript r_worker.R cells.tsv start out.tsv   (runs cells start.. , appends one line per cell)
args <- commandArgs(TRUE); RT <- dirname(normalizePath(args[1])); start <- as.integer(args[2]); out <- args[3]
.libPaths(c("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/lib", .libPaths()))
suppressPackageStartupMessages({library(drmTMB); library(ape)})
cells <- read.delim(args[1], stringsAsFactors = FALSE)
clean <- function(s) gsub("[\t\r\n]+", " ", paste(s, collapse = " | "))
famR <- function(f) switch(f, gaussian = gaussian(), poisson = poisson(), nb2 = nbinom2(), gamma = Gamma(link = "log"), binomial = binomial())
build <- function(ds, route, fam) {
  dir <- file.path(RT, "cells", ds)
  d <- read.csv(file.path(dir, sprintf("data_%s_%s.csv", route, fam)), stringsAsFactors = FALSE)
  meta <- readLines(file.path(dir, "meta.json")); ex <- as.integer(sub('.*"extra_levels":([0-9]+).*', "\\1", meta))
  lv <- sprintf("g%02d", 1:(24 + ex)); d$g <- factor(d$g, levels = if (ex > 0) lv else sort(unique(d$g)))
  tree <- read.tree(file.path(dir, "tree.nwk"))
  cc <- read.csv(file.path(dir, "coords.csv")); coords <- as.matrix(cc[, 2:3]); rownames(coords) <- cc$id
  A <- as.matrix(read.csv(file.path(dir, "A.csv"), check.names = FALSE)); ai <- read.csv(file.path(dir, "A_ids.csv"))$id
  dimnames(A) <- list(ai, ai)
  nuis <- if (fam %in% c("gaussian", "nb2", "gamma")) "sigma ~ 1," else ""
  mu <- switch(route, ord = "y ~ x + (1 | g)", ordq2 = "y ~ x + (1 + x | g)", animal = "y ~ x + animal(1 | g, A = A)",
               phylo = "y ~ x + phylo(1 | g, tree = tree)", spatial = "y ~ x + spatial(1 | g, coords = coords)")
  sds <- switch(route, ord = 'sd(g) ~ z',
                ordq2 = 'sd(g, coef = "(Intercept)") ~ z0, sd(g, coef = "x") ~ z1',
                animal = 'sd(g, level = "animal") ~ z', phylo = 'sd(g, level = "phylogenetic") ~ z',
                spatial = 'sd(g, level = "spatial") ~ z')
  env <- environment()
  fm <- eval(parse(text = sprintf("bf(%s, %s %s)", mu, nuis, sds)), env)
  list(fm = fm, d = d, fam = famR(fam))
}
file.create(paste0(out, '.ready'))
for (i in seq(start, min(as.integer(args[4]), nrow(cells)))) {
  ce <- cells[i, ]; t0 <- Sys.time(); warns <- character(); status <- "fit"; cls <- ""; msg <- ""; ll <- NA; conv <- NA; nobs <- NA; seok <- NA; cf <- ""
  res <- tryCatch(withCallingHandlers({
    b <- build(ce$ds, ce$route, ce$fam)
    drmTMB(b$fm, family = b$fam, data = b$d)
  }, warning = function(w) { warns <<- c(warns, conditionMessage(w)); invokeRestart("muffleWarning") }),
  error = function(e) e)
  if (inherits(res, "error")) { status <- "error"; cls <- paste(class(res), collapse = "/"); msg <- conditionMessage(res)
  } else {
    ll <- as.numeric(logLik(res)); conv <- res$opt$convergence; nobs <- tryCatch(nobs(res), error = function(e) NA)
    sm <- tryCatch(summary(res)$coefficients, error = function(e) NULL)
    seok <- if (is.null(sm)) NA else all(is.finite(sm[, 2]))
    fe <- tryCatch(unlist(fixef(res)), error = function(e) NULL)
    if (!is.null(fe)) cf <- paste(sprintf("%s=%.8g", names(fe), fe), collapse = ";")
  }
  el <- as.numeric(Sys.time() - t0, units = "secs")
  line <- paste(ce$id, "R", status, cls, conv, ll, nobs, round(el, 2), seok, clean(cf), clean(unique(warns)), clean(msg), sep = "\t")
  cat(gsub("\n", " ", line), "\n", file = out, append = TRUE, sep = "")
}
