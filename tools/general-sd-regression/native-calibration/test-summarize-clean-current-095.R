# Run with: Rscript test-summarize-clean-current-095.R
script_path <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[[1L]]))
summary_script <- file.path(dirname(script_path), "summarize-095.R")
expressions <- parse(summary_script)
binding_expr <- Filter(function(expr) {
  is.call(expr) && identical(expr[[1L]], as.name("<-")) &&
    identical(expr[[2L]], as.name("native_sd_095_manifest_binding"))
}, as.list(expressions))
stopifnot(length(binding_expr) == 1L)
env <- new.env(parent = baseenv())
eval(binding_expr[[1L]], envir = env)
binding <- env$native_sd_095_manifest_binding

stopifnot(
  identical(binding("clean_current", TRUE), "direct_registry_pin"),
  identical(binding("clean_current", FALSE), "clean_current_frozen_source"),
  identical(binding("production", FALSE), "subset_receipt"),
  identical(binding("qualification", FALSE), "subset_receipt")
)

source_route <- paste(deparse(expressions), collapse = "\n")
binding_use <- Filter(function(expr) {
  is.call(expr) && identical(expr[[1L]], as.name("<-")) &&
    identical(expr[[2L]], as.name("manifest_binding")) &&
    is.call(expr[[3L]]) &&
    identical(expr[[3L]][[1L]], as.name("native_sd_095_manifest_binding"))
}, as.list(expressions))
stopifnot(
  length(binding_use) == 1L,
  identical(binding_use[[1L]][[3L]][[2L]], as.name("design_mode")),
  identical(binding_use[[1L]][[3L]][[3L]], as.name("direct_manifest_pin")),
  grepl("validate_clean_look1_manifest", source_route, fixed = TRUE)
)
cat("PASS: clean-current summaries bind to the frozen look-one source; other unpinned manifests require subset receipts\n")
