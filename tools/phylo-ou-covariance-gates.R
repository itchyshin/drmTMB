#!/usr/bin/env Rscript

# Fail-closed gate runner for the phylogenetic OU covariance arc.
# Only PO1 is runnable during orientation. Later gates deliberately refuse to
# assert success until their implementation fixtures exist.
args <- commandArgs(trailingOnly = TRUE)
allowed <- c(paste0("PO", 1:12))
if (length(args) < 1L || length(args) > 2L || !args[[1L]] %in% allowed ||
    (length(args) == 2L && !identical(args[[2L]], "--reverify"))) {
  stop("Usage: Rscript --vanilla tools/phylo-ou-covariance-gates.R PO1|...|PO12 [--reverify]", call. = FALSE)
}

gate <- args[[1L]]
reverify <- length(args) == 2L
if (identical(gate, "PO1")) {
  if (reverify) stop("PO1 does not accept --reverify.", call. = FALSE)
  plan <- "docs/dev-log/plans/2026-09-11-phylo-ou-covariance/PLAN.md"
  ledger <- "docs/dev-log/plans/2026-09-11-phylo-ou-covariance/unlazy/GATES.md"
  required_plan <- c(
    "phylo(1 | species, tree = tree, model = \"bm\")",
    "phylo(1 | species, tree = tree, model = \"ou\")",
    "ape::corMartins",
    "not** a BM limit"
  )
  text <- if (file.exists(plan)) paste(readLines(plan, warn = FALSE), collapse = "\n") else ""
  ledger_text <- if (file.exists(ledger)) paste(readLines(ledger, warn = FALSE), collapse = "\n") else ""
  if (!all(vapply(required_plan, grepl, logical(1), x = text, fixed = TRUE)) ||
      !grepl("PHYLO_OU_COVARIANCE_PO2_PASS", ledger_text, fixed = TRUE)) {
    stop("PO1 plan or ledger contract is incomplete.", call. = FALSE)
  }
  cat("PHYLO_OU_COVARIANCE_PO1_PASS\n")
} else {
  stop(
    sprintf("%s is pending: its gate has no accepted implementation evidence yet.", gate),
    call. = FALSE
  )
}
