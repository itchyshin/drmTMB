# Probe: which REML refusal a structured-marker formula gets through
# engine = "julia" -- univariate Gaussian, bivariate Gaussian, and phylo --
# measured on origin/main.
#
# WHY: docs/design/261-reml-by-route.md's `general_covariance_structured
# (gaussian)` row said drm_julia_has_structured_term() "is checked BEFORE any
# family dispatch and refuses unconditionally". Both halves are over-broad:
#   (a) the family IS dispatched first -- biv_gaussian + a structured marker
#       takes its own branch one step earlier and gets a DIFFERENT message;
#   (b) "structured" means relmat/animal/spatial only
#       (drm_julia_structured_marker_types()); a phylo() term never reaches
#       this gate and is governed by drm_julia_reml_supported() instead.
#
# Pure R: every refusal here is raised before Julia starts, so no DRM.jl is
# booted and the probe runs with DRM_JL_PATH unset.
suppressMessages(devtools::load_all(
  "/Users/z3437171/local-scratch/parity-joint/wt-docs-staleness",
  quiet = TRUE
))

set.seed(1)
K <- diag(3)
tree <- ape::rcoal(3)
tree$tip.label <- c("a", "b", "c")
dat <- data.frame(
  id = rep(c("a", "b", "c"), each = 4),
  species = rep(c("a", "b", "c"), each = 4),
  x = stats::rnorm(12),
  y = stats::rnorm(12),
  y1 = stats::rnorm(12),
  y2 = stats::rnorm(12)
)

grab <- function(label, expr) {
  msg <- tryCatch({ force(expr); "NO ERROR (fit attempted)" },
                  error = function(e) conditionMessage(e))
  cat("---- ", label, "\n", sep = "")
  cat(msg, "\n\n", sep = "")
  invisible(msg)
}

uni <- grab(
  "UNIVARIATE gaussian + relmat(1 | id, K = K), REML = TRUE",
  drmTMB(bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1),
         family = gaussian(), data = dat, engine = "julia", REML = TRUE)
)

biv <- grab(
  "BIVARIATE biv_gaussian + relmat(1 | p | id, K = K), REML = TRUE",
  drmTMB(bf(mu1 = y1 ~ x + relmat(1 | p | id, K = K),
            mu2 = y2 ~ x + relmat(1 | p | id, K = K),
            sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
         family = biv_gaussian(), data = dat, engine = "julia", REML = TRUE)
)

# cli hard-wraps the message, so compare on whitespace-normalised text.
flat <- function(x) gsub("[[:space:]]+", " ", x)
uni_f <- flat(uni)
biv_f <- flat(biv)

marker_types <- drmTMB:::drm_julia_structured_marker_types()
# Same call shape tests/testthat/test-julia-structured.R:50-68 uses: bf() is
# passed straight in, no separate parse step.
phylo_is_structured <- drmTMB:::drm_julia_has_structured_term(
  bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)
)
relmat_is_structured <- drmTMB:::drm_julia_has_structured_term(
  bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1)
)

cat("==== MEASURED ====\n")
cat("drm_julia_structured_marker_types(): ",
    paste(marker_types, collapse = ", "), "\n", sep = "")
cat("univariate cell label is 'structured-effect'            : ",
    grepl("cannot fit structured-effect models", uni_f, fixed = TRUE), "\n", sep = "")
cat("bivariate cell label is 'bivariate q2 known-covariance' : ",
    grepl("cannot fit bivariate q2 known-covariance structured-effect models",
          biv_f, fixed = TRUE), "\n", sep = "")
cat("the two refusals are DISTINCT messages                  : ",
    !identical(uni_f, biv_f), "\n", sep = "")
cat("a relmat() term counts as a structured term            : ",
    relmat_is_structured, "\n", sep = "")
cat("a phylo() term counts as a structured term             : ",
    phylo_is_structured, "\n", sep = "")

ok <-
  grepl("cannot fit structured-effect models", uni_f, fixed = TRUE) &&
  grepl("cannot fit bivariate q2 known-covariance structured-effect models",
        biv_f, fixed = TRUE) &&
  !identical(uni_f, biv_f) &&
  identical(sort(marker_types), c("animal", "relmat", "spatial")) &&
  isTRUE(relmat_is_structured) &&
  isFALSE(phylo_is_structured)

cat("\n==== VERDICT ====\n")
cat("The family IS dispatched before the generic structured branch\n")
cat("(biv_gaussian takes its own branch one step earlier), and the gate\n")
cat("covers relmat/animal/spatial only -- phylo is governed elsewhere.\n")
if (ok) cat("DISPATCH_ORDER_CONFIRMED\n") else stop("probe expectations not met")
