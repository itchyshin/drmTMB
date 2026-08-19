#!/usr/bin/env Rscript

# Generate the printable companions to the public function-map article.
# Run from the package root: Rscript --vanilla tools/build-function-cheatsheets.R

source("tools/function-map-inventory.R")

namespace_lines <- readLines("NAMESPACE", warn = FALSE)
exports <- sub(
  '^export\\(([^)]+)\\)$', '\\1',
  grep('^export\\(', namespace_lines, value = TRUE)
)
missing_exports <- setdiff(function_map_primary_exports, exports)
if (length(missing_exports)) {
  stop(
    "Primary function-map entries are not exported: ",
    paste(missing_exports, collapse = ", "),
    call. = FALSE
  )
}
if (length(intersect(function_map_primary_exports, function_map_compatibility))) {
  stop("Compatibility functions entered the primary map.", call. = FALSE)
}

missing_methods <- function_map_primary_methods[!vapply(
  function_map_primary_methods,
  function(fun) any(grepl(paste0("^S3method\\(", fun, ",drmTMB\\)$"), namespace_lines)),
  logical(1)
)]
if (length(missing_methods)) {
  stop(
    "Primary function-map methods are not registered for drmTMB: ",
    paste(missing_methods, collapse = ", "),
    call. = FALSE
  )
}

export_classification <- function_map_classify_exports(exports)
if (!identical(sort(names(export_classification)), sort(exports)) ||
    anyNA(export_classification) ||
    !all(export_classification %in% c("featured", "compatibility", "reference_only"))) {
  stop("Every exported function must have a function-map classification.", call. = FALSE)
}

output_dir <- "pkgdown/assets/cheatsheets"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

ink <- "#173042"
muted <- "#526875"
paper <- "#F7FAFB"
wrap <- function(x, width) paste(strwrap(x, width = width), collapse = "\n")

draw_header <- function(title, subtitle) {
  par(mar = c(0, 0, 0, 0), xpd = NA)
  plot.new()
  plot.window(xlim = c(0, 1), ylim = c(0, 1))
  rect(0, 0, 1, 1, col = paper, border = NA)
  rect(0, .89, 1, 1, col = "#052B3F", border = NA)
  text(.045, .955, "drmTMB", col = "white", font = 2, adj = c(0, .5), cex = 1.35)
  text(.045, .912, title, col = "white", adj = c(0, .5), cex = .9)
  text(
    .955, .912, "https://itchyshin.github.io/drmTMB/",
    col = "#D8E8ED", adj = c(1, .5), cex = .56
  )
  text(.045, .862, subtitle, col = muted, adj = c(0, .5), cex = .7)
}

draw_panel <- function(x0, y0, width, height, item) {
  rect(x0, y0 - height, x0 + width, y0, col = "white", border = item$colour, lwd = 1.3)
  rect(x0, y0 - .062, x0 + width, y0, col = item$dark, border = NA)
  text(
    x0 + .018, y0 - .031, item$label,
    col = "white", adj = c(0, .5), font = 2,
    cex = if (nchar(item$label) > 25) .72 else .84
  )
  text(
    x0 + .02, y0 - .082,
    wrap(item$purpose, 37),
    col = ink, adj = c(0, 1), cex = .68
  )
  function_label <- paste0("Functions: ", function_map_function_label(item))
  y_fun <- y0 - .158
  text(
    x0 + .02, y_fun,
    wrap(function_label, 41),
    col = ink, adj = c(0, 1), font = 2,
    cex = .61
  )
  text(
    x0 + .02, y_fun - .082,
    wrap(item$route, 41),
    col = muted, adj = c(0, 1), cex = .61
  )
}

draw_branch_cue <- function(y) {
  segments(.045, y, .955, y, col = "#9EAFB8", lwd = 1.2)
  rect(.37, y - .021, .63, y + .021, col = paper, border = NA)
  text(.5, y, "AFTER CHECKING: CHOOSE ONE NEXT TASK", col = ink, font = 2, cex = .7)
}

draw_flow_arrows <- function() {
  arrows(.315, .64, .355, .64, length = .08, col = ink, lwd = 1.4)
  arrows(.635, .64, .675, .64, length = .08, col = ink, lwd = 1.4)
  arrows(.82, .49, .82, .468, length = .07, col = ink, lwd = 1.4)
}

draw_sheet_row <- function(x0, y0, width, height, item) {
  rect(x0, y0 - height, x0 + width, y0, col = "white", border = item$colour, lwd = 1.3)
  rect(x0, y0 - height, x0 + .012, y0, col = item$dark, border = NA)
  text(x0 + .027, y0 - .035, item$label, col = item$dark, adj = c(0, .5), font = 2, cex = .82)
  text(
    x0 + .027, y0 - .073, wrap(item$purpose, 48),
    col = ink, adj = c(0, 1), cex = .68
  )
  text(
    x0 + .027, y0 - .135,
    wrap(paste0("Functions: ", function_map_function_label(item)), 59),
    col = ink, adj = c(0, 1), font = 2, cex = .62
  )
}

map_path <- file.path(output_dir, "drmTMB-function-map.pdf")
grDevices::pdf(map_path, width = 16, height = 9, useDingbats = FALSE)
draw_header(
  "Function map",
  "A task-based route through the current public workflow. Read the HTML article for links and full boundaries."
)
coords <- list(c(.045, .79), c(.365, .79), c(.685, .79), c(.045, .405), c(.365, .405), c(.685, .405))
for (i in seq_along(function_map_inventory)) {
  xy <- coords[[i]]
  draw_panel(xy[1], xy[2], .27, .30, function_map_inventory[[i]])
}
draw_branch_cue(.46)
draw_flow_arrows()
text(
  .5, .055,
  "Typical route: Specify to Fit to Check fit health. Interpretation, prediction, uncertainty, and simulation are conditional next tasks.",
  col = ink, cex = .72
)
text(
  .5, .026,
  "Navigation aid only: a documented function can still be unsuitable for a particular family, structure, target, or data set.",
  col = muted, cex = .64
)
grDevices::dev.off()

sheet_path <- file.path(output_dir, "drmTMB-function-cheatsheet.pdf")
grDevices::pdf(sheet_path, width = 11.69, height = 8.27, useDingbats = FALSE)
draw_header(
  "Function cheat sheet",
  "Six first-use routes. The HTML article carries links, examples, and complete scope boundaries."
)
sheet_coords <- list(
  c(.045, .81), c(.515, .81), c(.045, .57),
  c(.515, .57), c(.045, .33), c(.515, .33)
)
for (i in seq_along(function_map_inventory)) {
  xy <- sheet_coords[[i]]
  draw_sheet_row(xy[1], xy[2], .44, .20, function_map_inventory[[i]])
}
text(
  .5, .025,
  "Choose the task first, then check the linked article for family, structure, and interval boundaries.",
  col = muted, adj = c(.5, .5), cex = .64
)
grDevices::dev.off()

message("Wrote ", map_path, " and ", sheet_path)
