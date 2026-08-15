files <- jsonlite::fromJSON("scratchpad/recovery-result.json")$recovered
paths <- names(files)
rs <- paths[endsWith(paths, ".R")]
bad <- character()
for (p in rs) {
  ok <- tryCatch({ parse(p); TRUE },
                 error = function(e) { cat("PARSE FAIL:", p, "--", conditionMessage(e), "\n"); FALSE })
  if (!ok) bad <- c(bad, p)
}
cat(sprintf("\nrecovered R files: %d   parse OK: %d   parse FAIL: %d\n",
            length(rs), length(rs) - length(bad), length(bad)))
