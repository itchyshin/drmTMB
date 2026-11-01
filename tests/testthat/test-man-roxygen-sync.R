# man/*.Rd are generated from roxygen blocks in R/. Editing them by hand (as
# #1400 did) is silently undone by the next devtools::document() run, so the
# committed help files must equal a fresh roxygen run over the committed sources
# (issue #1571).
test_that("committed man/*.Rd files match a fresh roxygen run", {
  skip_on_cran()
  skip_if_not_installed("roxygen2")
  skip_if_not_installed("pkgload")
  root <- normalizePath(test_path("..", ".."), mustWork = FALSE)
  skip_if_not(
    all(file.exists(file.path(root, c("DESCRIPTION", "NAMESPACE")))) &&
      dir.exists(file.path(root, "R")) && dir.exists(file.path(root, "man")),
    "The package source tree is unavailable in an installed-package check."
  )
  desc <- read.dcf(file.path(root, "DESCRIPTION"), fields = "Config/roxygen2/version")
  recorded <- desc[1L, 1L]
  skip_if(
    is.na(recorded) ||
      as.character(utils::packageVersion("roxygen2")) != recorded,
    "Installed roxygen2 differs from the version recorded in DESCRIPTION."
  )

  tmp <- tempfile("roxy-sync-")
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  file.copy(file.path(root, c("DESCRIPTION", "NAMESPACE", "R", "man")), tmp,
            recursive = TRUE)

  # Reuse the loaded namespace so the check does not need to compile src/.
  ns <- asNamespace("drmTMB")
  suppressMessages(suppressWarnings(utils::capture.output(
    roxygen2::roxygenise(tmp, roclets = "rd", load_code = function(path) ns)
  )))

  committed <- list.files(file.path(root, "man"), pattern = "\\.Rd$")
  fresh <- list.files(file.path(tmp, "man"), pattern = "\\.Rd$")
  expect_identical(fresh, committed)
  stale <- committed[!vapply(committed, function(f) {
    identical(
      readLines(file.path(root, "man", f), warn = FALSE),
      readLines(file.path(tmp, "man", f), warn = FALSE)
    )
  }, logical(1L))]
  expect_identical(
    stale, character(0),
    info = paste(
      "These man/*.Rd files differ from roxygen output; edit the roxygen",
      "block in R/ and run devtools::document(), do not edit man/ directly."
    )
  )
})
