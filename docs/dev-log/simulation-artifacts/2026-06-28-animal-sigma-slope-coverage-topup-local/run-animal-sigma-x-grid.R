args <- commandArgs(trailingOnly = TRUE)
runner <- file.path("tools", "run-structured-re-sigma-slope-coverage-grid.R")
if (!file.exists(runner)) {
  stop("Run from the drmTMB repository root; missing ", runner, call. = FALSE)
}

patched <- readLines(runner, warn = FALSE)
text <- paste(patched, collapse = "\n")
old_map <- paste(
  c(
    "SHARD_MAP <- data.frame(",
    "  shard = 1:7,",
    "  provider = c(",
    '    "phylo",',
    '    "phylo",',
    '    "spatial",',
    '    "spatial",',
    '    "animal",',
    '    "relmat",',
    '    "relmat"',
    "  ),",
    "  target = c(",
    '    "sigma:(Intercept)",',
    '    "sigma:x",',
    '    "sigma:(Intercept)",',
    '    "sigma:x",',
    '    "sigma:(Intercept)",',
    '    "sigma:(Intercept)",',
    '    "sigma:x"',
    "  ),",
    "  stringsAsFactors = FALSE",
    ")"
  ),
  collapse = "\n"
)
new_map <- paste(
  c(
    "SHARD_MAP <- data.frame(",
    "  shard = 1:8,",
    "  provider = c(",
    '    "phylo",',
    '    "phylo",',
    '    "spatial",',
    '    "spatial",',
    '    "animal",',
    '    "relmat",',
    '    "relmat",',
    '    "animal"',
    "  ),",
    "  target = c(",
    '    "sigma:(Intercept)",',
    '    "sigma:x",',
    '    "sigma:(Intercept)",',
    '    "sigma:x",',
    '    "sigma:(Intercept)",',
    '    "sigma:(Intercept)",',
    '    "sigma:x",',
    '    "sigma:x"',
    "  ),",
    "  stringsAsFactors = FALSE",
    ")"
  ),
  collapse = "\n"
)
if (!grepl(old_map, text, fixed = TRUE)) {
  stop("Could not find the expected sigma-slope SHARD_MAP block", call. = FALSE)
}
text <- sub(
  old_map,
  new_map,
  text,
  fixed = TRUE
)
text <- gsub(
  "args$shard > 7L",
  "args$shard > 8L",
  text,
  fixed = TRUE
)
text <- gsub(
  "Must be an integer 1..7.",
  "Must be an integer 1..8.",
  text,
  fixed = TRUE
)
text <- gsub(
  "[grid] animal sigma:x is an EXCLUDED holdout (profile failure) -- not in this map.",
  "[grid] animal sigma:x is included by the artifact-local reconciliation wrapper.",
  text,
  fixed = TRUE
)

tmp_runner <- tempfile("run-animal-sigma-x-grid-", fileext = ".R")
writeLines(text, tmp_runner)

status <- system2(
  file.path(R.home("bin"), "Rscript"),
  c("--no-init-file", tmp_runner, args)
)
quit(status = status)
