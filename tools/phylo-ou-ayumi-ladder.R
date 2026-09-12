#!/usr/bin/env Rscript

# A reproducible feasibility/sensitivity ladder for the locally available
# Ayumi all-passerine body-mass data.  This is deliberately explicit about its
# source receipt: it is not the 10,440-row issue dataset unless those files are
# supplied separately.

args <- commandArgs(trailingOnly = TRUE)
output_dir <- if (length(args) == 1L) args[[1L]] else file.path(
  "docs", "dev-log", "empirical-results", "2026-09-12-ayumi-5809-phylo-ou"
)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

required <- c("ape", "digest", "pkgload")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Missing packages: ", paste(missing, collapse = ", "))
pkgload::load_all(".", compile = TRUE, quiet = TRUE)

data_root <- "/Users/z3437171/Dropbox/Github Local/eco-climatic-rules"
data_file <- file.path(data_root, "data", "Delhey_etal_2019", "plumage_avonet_combined.csv")
tree_file <- file.path(data_root, "data", "Stage2_Hackett_MCC_no_neg.tre")
if (!file.exists(data_file) || !file.exists(tree_file)) {
  stop("The locally audited Ayumi data receipt is unavailable.")
}

dat <- read.csv(data_file)
tree <- ape::read.tree(tree_file)
needed <- c("cbody_mass_g", "temp_c", "precip_c", "TipLabel")
dat <- dat[complete.cases(dat[, needed]), needed]
keep <- intersect(as.character(dat$TipLabel), tree$tip.label)
dat <- dat[match(keep, dat$TipLabel), , drop = FALSE]
tree <- ape::drop.tip(tree, setdiff(tree$tip.label, keep))
edge_length <- tree$edge.length
repair_n <- sum(!is.finite(edge_length) | edge_length <= 0)
positive_scale <- median(edge_length[is.finite(edge_length) & edge_length > 0], na.rm = TRUE)
if (!is.finite(positive_scale)) positive_scale <- 1
edge_length[!is.finite(edge_length) | edge_length <= 0] <- positive_scale * 1e-8
tree$edge.length <- edge_length
if (!ape::is.ultrametric(tree) || any(!is.finite(tree$edge.length)) || any(tree$edge.length <= 0)) {
  stop("The repaired local tree is not an admissible positive ultrametric tree.")
}

formula_for <- function(model, residual_scale) {
  phylo_term <- if (identical(model, "bm")) {
    phylo(1 | TipLabel, tree = tree, model = "bm")
  } else {
    phylo(1 | TipLabel, tree = tree, model = "ou")
  }
  # Construct via explicit calls so `model` stays a literal parser choice.
  if (identical(model, "bm") && identical(residual_scale, "constant")) {
    bf(cbody_mass_g ~ temp_c + I(temp_c^2) + precip_c + I(precip_c^2) +
      phylo(1 | TipLabel, tree = tree, model = "bm"), sigma ~ 1,
      sd(TipLabel, level = "phylogenetic") ~ temp_c + precip_c)
  } else if (identical(model, "ou") && identical(residual_scale, "constant")) {
    bf(cbody_mass_g ~ temp_c + I(temp_c^2) + precip_c + I(precip_c^2) +
      phylo(1 | TipLabel, tree = tree, model = "ou"), sigma ~ 1,
      sd(TipLabel, level = "phylogenetic") ~ temp_c + precip_c)
  } else if (identical(model, "bm")) {
    bf(cbody_mass_g ~ temp_c + I(temp_c^2) + precip_c + I(precip_c^2) +
      phylo(1 | TipLabel, tree = tree, model = "bm"),
      sigma ~ temp_c + precip_c,
      sd(TipLabel, level = "phylogenetic") ~ temp_c + precip_c)
  } else {
    bf(cbody_mass_g ~ temp_c + I(temp_c^2) + precip_c + I(precip_c^2) +
      phylo(1 | TipLabel, tree = tree, model = "ou"),
      sigma ~ temp_c + precip_c,
      sd(TipLabel, level = "phylogenetic") ~ temp_c + precip_c)
  }
}

fits <- expand.grid(
  model = c("bm", "ou"), residual_scale = c("constant", "climate"),
  stringsAsFactors = FALSE
)
fits$id <- sprintf("%s_%s", fits$model, fits$residual_scale)
results <- vector("list", nrow(fits))
for (i in seq_len(nrow(fits))) {
  warnings <- character()
  started <- Sys.time()
  fit <- withCallingHandlers(
    tryCatch(
      drmTMB(
        formula_for(fits$model[[i]], fits$residual_scale[[i]]),
        data = dat, family = gaussian(), REML = FALSE,
        control = drm_control(
          optimizer_preset = "default", fallback_optimizer = "BFGS"
        )
      ),
      error = identity
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  if (inherits(fit, "error")) {
    results[[i]] <- list(id = fits$id[[i]], model = fits$model[[i]],
      residual_scale = fits$residual_scale[[i]], elapsed_seconds = elapsed,
      error = conditionMessage(fit), warnings = warnings)
  } else {
    gradient <- fit$obj$gr(fit$opt$par)
    results[[i]] <- list(id = fits$id[[i]], model = fits$model[[i]],
      residual_scale = fits$residual_scale[[i]], elapsed_seconds = elapsed,
      convergence = fit$opt$convergence, max_gradient = max(abs(gradient)),
      pdHess = isTRUE(fit$sdr$pdHess), logLik = as.numeric(logLik(fit)),
      fixed_effects = coef(fit),
      decay_phylo = if (identical(fits$model[[i]], "ou")) {
        fit$decaypars$phylo[["decay_phylo"]]
      } else NA_real_,
      warnings = warnings, fit = fit)
  }
  saveRDS(results, file.path(output_dir, "ladder-results.rds"))
}

receipt <- list(
  source = "local eco-climatic-rules all-passerine feasibility proxy",
  data_file = normalizePath(data_file), tree_file = normalizePath(tree_file),
  data_sha256 = digest::digest(file = data_file, algo = "sha256"),
  tree_sha256 = digest::digest(file = tree_file, algo = "sha256"),
  rows = nrow(dat), tips = length(tree$tip.label), repaired_branches = repair_n,
  REML = FALSE,
  optimizer = "default-to-careful-to-robust nlminb escalation; BFGS fallback",
  formula = "mu climate quadratics + phylo intercept; direct phylo-SD climate; sigma constant or climate",
  results = lapply(results, function(x) x[setdiff(names(x), "fit")])
)
saveRDS(receipt, file.path(output_dir, "receipt.rds"))
writeLines(capture.output(str(receipt, max.level = 3)), file.path(output_dir, "receipt.txt"))
cat(sprintf("AYUMI_PROXY_LADDER_PASS rows=%d tips=%d output=%s\n",
  nrow(dat), length(tree$tip.label), normalizePath(output_dir)
))
