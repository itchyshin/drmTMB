#!/usr/bin/env Rscript

rd_files <- list.files("man", pattern = "[.]Rd$", full.names = TRUE)
topic <- sub("[.]Rd$", "", basename(rd_files))
rd_text <- lapply(rd_files, readLines, warn = FALSE)
has_examples <- vapply(
  rd_text,
  function(x) any(grepl("\\\\examples\\{", x, fixed = FALSE)),
  logical(1)
)

aliases <- lapply(rd_text, function(x) {
  alias_lines <- grep("^\\\\alias\\{", x, value = TRUE)
  sub("^\\\\alias\\{([^}]*)\\}.*", "\\1", alias_lines)
})

out <- data.frame(
  topic = topic,
  has_examples = has_examples,
  aliases = vapply(aliases, paste, character(1), collapse = ", "),
  stringsAsFactors = FALSE
)
out <- out[order(out$topic), ]

print(out, row.names = FALSE)

missing <- out$topic[!out$has_examples]
if (length(missing)) {
  message(
    "Topics without runnable examples: ",
    paste(missing, collapse = ", ")
  )
}
