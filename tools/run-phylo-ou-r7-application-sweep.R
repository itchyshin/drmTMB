#!/usr/bin/env Rscript

# Reproduce the full R7 batch receipt. This can take several minutes locally;
# use the cell runner for the short, independently retained usability cells.

if (!requireNamespace("ape", quietly = TRUE) ||
    !requireNamespace("MASS", quietly = TRUE) ||
    !requireNamespace("pkgload", quietly = TRUE)) stop("R7 needs ape, MASS, pkgload")
pkgload::load_all(".", compile = FALSE, quiet = TRUE)
out <- "docs/dev-log/evidence/ou-fixed-alpha-r7"
grid <- c(0.1, 0.3, 0.7, 1.3, 2.5)
source_data <- "/Users/z3437171/Dropbox/Github Local/eco-climatic-rules/data"

repair_tree <- function(tree) {
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
  tree
}

fit_one <- function(id, formula, data) {
  started <- proc.time()[["elapsed"]]
  fit <- ou_sensitivity(formula, data, alpha = grid)
  summary <- fit$summary
  summary$dataset <- id
  summary$elapsed_seconds <- (proc.time()[["elapsed"]] - started) / nrow(summary)
  coefficients <- fit$coefficients
  coefficients$dataset <- id
  list(summary = summary, coefficients = coefficients)
}

av <- utils::read.csv(file.path(source_data, "Avonet", "ELEData", "TraitData", "AVONET3_BirdTree.csv"))
climate <- utils::read.csv(file.path(source_data, "Delhey_etal_2019", "species.level.data.csv"))
av$Phylo <- gsub(" ", "_", av$Phylo)
ayumi <- merge(climate, av[av$Order3 == "Passeriformes", ], by.x = "TipLabel", by.y = "Phylo")
ayumi$c_body_mass_g <- as.numeric(scale(log(ayumi$Mass), scale = FALSE))
ayumi$temp_z <- as.numeric(scale(ayumi$annual_mean_temperature))
ayumi$precip_z <- as.numeric(scale(ayumi$annual_precipitation))
ayumi <- ayumi[complete.cases(ayumi[, c("TipLabel", "c_body_mass_g", "temp_z", "precip_z")]), ]
ayumi_tree <- ape::read.tree(file.path(source_data, "Stage2_Hackett_MCC_no_neg.tre"))
ayumi_tree <- repair_tree(ape::drop.tip(ayumi_tree, setdiff(ayumi_tree$tip.label, ayumi$TipLabel)))
ayumi <- ayumi[match(ayumi_tree$tip.label, ayumi$TipLabel), ]

e <- new.env(parent = emptyenv())
load("/Users/z3437171/Dropbox/Github Local/prepR4pcm/data/avonet_subset.rda", envir = e)
birds <- e$avonet_subset
birds$species <- gsub(" ", "_", birds$Species1)
birds <- birds[complete.cases(birds[, c("species", "Mass", "Beak.Depth", "Wing.Length")]), ]
bird_tree <- ape::read.tree(file.path(source_data, "Stage2_Hackett_MCC_no_neg.tre"))
bird_tree <- repair_tree(ape::drop.tip(bird_tree, setdiff(bird_tree$tip.label, birds$species)))
birds <- birds[match(bird_tree$tip.label, birds$species), ]
birds$log_mass <- log(birds$Mass)
birds$beak_depth_z <- as.numeric(scale(birds$Beak.Depth))
birds$wing_length_z <- as.numeric(scale(birds$Wing.Length))

set.seed(20260913)
sim_tree <- ape::rcoal(64)
depth <- mean(ape::node.depth.edgelength(sim_tree)[seq_along(sim_tree$tip.label)])
u <- as.numeric(MASS::mvrnorm(1, rep(0, 64), 0.8^2 * exp(-(0.7 / depth) * ape::cophenetic.phylo(sim_tree))))
sim <- data.frame(species = rep(sim_tree$tip.label, each = 6), x = rep(as.numeric(scale(rnorm(64))), each = 6))
sim$y <- 0.4 + 0.7 * sim$x + rep(u, each = 6) + rnorm(nrow(sim), sd = 0.35)

fits <- list(
  fit_one("ayumi_passerine_body_mass", bf(c_body_mass_g ~ precip_z + I(precip_z^2) + temp_z + I(temp_z^2) + phylo(1 | TipLabel, tree = ayumi_tree, model = "ou"), sigma ~ temp_z + precip_z), ayumi),
  fit_one("avonet_mass_morphology", bf(log_mass ~ beak_depth_z + wing_length_z + phylo(1 | species, tree = bird_tree, model = "ou"), sigma ~ wing_length_z), birds),
  fit_one("simulated_informative_ou_alpha_0.7", bf(y ~ x + phylo(1 | species, tree = sim_tree, model = "ou"), sigma ~ 1), sim)
)
utils::write.csv(do.call(rbind, lapply(fits, `[[`, "summary")), file.path(out, "summary.csv"), row.names = FALSE)
utils::write.csv(do.call(rbind, lapply(fits, `[[`, "coefficients")), file.path(out, "coefficients.csv"), row.names = FALSE)
cat("OU_FIXED_ALPHA_R7_BATCH_PASS\n")
