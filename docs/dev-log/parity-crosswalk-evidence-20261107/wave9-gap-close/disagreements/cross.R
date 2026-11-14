.libPaths(c(path.expand("~/drm_campaign_20261108/Rlib"), .libPaths()))
suppressPackageStartupMessages(library(drmTMB))
DD <- "data"
src <- readLines("agree.R"); a <- grep("^fam_of", src)[1]
# reuse helper definitions from agree.R (everything between the data setup and the main loop)
tree <- ape::read.tree(file.path(DD, "tree.nwk"))
cc <- read.csv(file.path(DD, "coords.csv")); coords <- as.matrix(cc[, c("easting", "northing")]); rownames(coords) <- cc$id
ids <- read.csv(file.path(DD, "A_ids.csv"))$id
A <- as.matrix(read.csv(file.path(DD, "A.csv"), header = FALSE)); dimnames(A) <- list(ids, ids); K <- A
level_of <- c(animal = "animal", relmat = "relmat", phylo = "phylogenetic", spatial = "spatial")
cname_r <- c("(Intercept)", "x1", "x2", "x3")
build <- function(kind, lab, q, pat, fam) {
  terms <- c("1", "x1", "x2", "x3")[seq_len(q)]
  inner <- paste0(paste(terms, collapse = " + "), if (lab == 1) " | p | " else " | ", "g")
  re <- switch(kind, phylo = paste0("phylo(", inner, ", tree = tree)"), spatial = paste0("spatial(", inner, ", coords = coords)"))
  mu <- as.formula(paste("y ~ x1 + x2 + x3 +", re)); environment(mu) <- environment()
  rhs <- if (pat == "one") "1" else "z"
  sds <- lapply(seq_len(q), function(j) as.formula(sprintf('sd(g, level = "%s", coef = "%s") ~ %s', level_of[[kind]], cname_r[j], rhs)))
  do.call(bf, c(list(mu, sigma = as.formula("~ 1")), sds))
}
getth <- function(file, sid, seed) { for (l in readLines(file)) { f <- strsplit(l, "\t")[[1]]; if (f[1] == sid && f[2] == as.character(seed)) return(as.numeric(strsplit(f[6], ",")[[1]])) } }
cat("shape\tseed\tR_nll(thR)\tR_nll(thJ)\tR_ll(thR)\tR_ll(thJ)\tR_gradmax_at_thR\n")
for (job in list(c("B2", 2, "phylo", "z"), c("B5", 9, "spatial", "z"), c("B5", 10, "spatial", "z"))) {
  sid <- job[1]; seed <- as.integer(job[2]); kind <- job[3]
  d <- read.csv(file.path(DD, sprintf("data_gamma_%s_s%d.csv", kind, seed))); d$g <- factor(d$g, levels = unique(d$g))
  fit <- drmTMB(build(kind, 0, 2, job[4], "gamma"), family = Gamma(link = "log"), data = d)
  thJ <- getth("julia_all.tsv", sid, seed); thR <- fit$opt$par
  fR <- fit$obj$fn(thR); fJ <- fit$obj$fn(thJ); gR <- max(abs(fit$obj$gr(thR)))
  cat(sprintf("%s\t%d\t%.6f\t%.6f\t%.6f\t%.6f\t%.2e\n", sid, seed, fR, fJ, -fR, -fJ, gR))
}
