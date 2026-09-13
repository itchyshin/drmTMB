#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L || !args[[1L]] %in% c("avonet", "simulation", "simulation_strong")) {
  stop("Usage: run-phylo-ou-r7-cell.R {avonet|simulation|simulation_strong} alpha")
}
dataset <- args[[1L]]
alpha <- as.numeric(args[[2L]])
if (!is.finite(alpha) || alpha <= 0) stop("alpha must be positive")

if (!requireNamespace("ape", quietly = TRUE) ||
    !requireNamespace("MASS", quietly = TRUE) ||
    !requireNamespace("pkgload", quietly = TRUE)) {
  stop("R7 needs ape, MASS, and pkgload.")
}
pkgload::load_all(".", compile = FALSE, quiet = TRUE)
out <- "docs/dev-log/evidence/ou-fixed-alpha-r7/cells"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
source_data <- "/Users/z3437171/Dropbox/Github Local/eco-climatic-rules/data"

if (identical(dataset, "avonet")) {
  e <- new.env(parent = emptyenv())
  load(
    "/Users/z3437171/Dropbox/Github Local/prepR4pcm/data/avonet_subset.rda",
    envir = e
  )
  data <- e$avonet_subset
  data$species <- gsub(" ", "_", data$Species1)
  data <- data[complete.cases(data[, c(
    "species", "Mass", "Beak.Depth", "Wing.Length"
  )]), ]
  # A deterministic 128-species subset keeps the bounded application sweep
  # local and fast; it is a usability demonstration, not an AVONET analysis.
  set.seed(20260913)
  keep_species <- sample(unique(data$species), 128)
  data <- data[data$species %in% keep_species, ]
  tree <- ape::read.tree(file.path(source_data, "Stage2_Hackett_MCC_no_neg.tre"))
  tree <- ape::drop.tip(tree, setdiff(tree$tip.label, data$species))
  edge <- tree$edge.length
  positive <- edge[is.finite(edge) & edge > 0]
  edge[!is.finite(edge) | edge <= 0] <- median(positive) * 1e-8
  tree$edge.length <- edge
  if (!ape::is.binary(tree)) {
    set.seed(42)
    tree <- ape::multi2di(tree, random = TRUE)
    edge <- tree$edge.length
    edge[!is.finite(edge) | edge <= 0] <- median(edge[edge > 0]) * 1e-8
    tree$edge.length <- edge
  }
  data <- data[match(tree$tip.label, data$species), ]
  data$log_mass <- log(data$Mass)
  data$beak_depth_z <- as.numeric(scale(data$Beak.Depth))
  data$wing_length_z <- as.numeric(scale(data$Wing.Length))
  formula <- bf(
    log_mass ~ beak_depth_z + wing_length_z +
      phylo(1 | species, tree = tree, model = "ou"),
    sigma ~ wing_length_z
  )
} else {
  set.seed(20260913)
  tree <- ape::rcoal(64)
  depth <- mean(ape::node.depth.edgelength(tree)[seq_along(tree$tip.label)])
  covariance <- exp(-(0.7 / depth) * ape::cophenetic.phylo(tree))
  amplitude <- if (identical(dataset, "simulation_strong")) 2 else 0.8
  residual_sd <- if (identical(dataset, "simulation_strong")) 0.15 else 0.35
  u <- as.numeric(MASS::mvrnorm(1, rep(0, 64), amplitude^2 * covariance))
  data <- data.frame(
    species = rep(tree$tip.label, each = 6),
    x = rep(as.numeric(scale(rnorm(64))), each = 6)
  )
  data$y <- 0.4 + 0.7 * data$x + rep(u, each = 6) + rnorm(nrow(data), sd = residual_sd)
  formula <- bf(y ~ x + phylo(1 | species, tree = tree, model = "ou"), sigma ~ 1)
}

started <- proc.time()[["elapsed"]]
fit <- ou_sensitivity(formula, data = data, alpha = alpha)
result <- fit$summary
result$dataset <- dataset
result$elapsed_total_seconds <- proc.time()[["elapsed"]] - started
utils::write.csv(
  result,
  file.path(out, paste0(dataset, "-alpha-", format(alpha, trim = TRUE), ".csv")),
  row.names = FALSE
)
cat("OU_FIXED_ALPHA_R7_CELL_PASS\n")
