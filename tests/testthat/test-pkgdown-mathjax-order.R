test_that("MathJax configuration precedes the loader without changing page content", {
  script <- test_path("..", "..", "tools", "build-pkgdown.R")
  skip_if_not(file.exists(script), "site build script is unavailable in this package context")
  expr <- parse(script)
  env <- new.env(parent = baseenv())
  for (name in c("repair_mathjax_order_text", "repair_mathjax_order")) {
    hit <- which(vapply(expr, function(e) {
      is.call(e) && identical(as.character(e[[1L]]), "<-") &&
        identical(as.character(e[[2L]]), name)
    }, logical(1)))
    expect_length(hit, 1L)
    eval(expr[[hit]], envir = env)
  }
  loader <- '<script src="https://cdn.jsdelivr.net/npm/mathjax@3.2.2/es5/tex-mml-chtml.js" integrity="sha256-test"></script>'
  config <- '<script>window.MathJax = {chtml: {fontURL: "x"}};</script>'
  original <- paste0('<html><head>', loader, config, '</head><body>β</body></html>')
  corrected <- paste0('<html><head>', config, loader, '</head><body>β</body></html>')
  expect_identical(env$repair_mathjax_order_text(original), corrected)
  expect_identical(env$repair_mathjax_order_text(corrected), corrected)
  expect_identical(env$repair_mathjax_order_text('<html>plain β</html>'), '<html>plain β</html>')
  expect_error(env$repair_mathjax_order_text('<script src="tex-mml-chtml.js">'), "Malformed")
  expect_error(env$repair_mathjax_order_text(paste0(loader, '<script>window.MathJax = {}')), "Malformed")
  expect_error(env$repair_mathjax_order_text('window.MathJax = {}'), "Malformed")
  expect_error(env$repair_mathjax_order_text(loader), "Ambiguous")
  expect_error(env$repair_mathjax_order_text(config), "Ambiguous")
  expect_error(env$repair_mathjax_order_text(paste0(loader, loader, config)), "Ambiguous")
  expect_error(env$repair_mathjax_order_text(paste0(loader, config, config)), "Ambiguous")
  expect_error(env$repair_mathjax_order_text(paste0(loader, '<script>other()</script>', config)), "Unexpected content")
  expect_error(env$repair_mathjax_order_text(paste0(loader, '<script src="/NA">window.MathJax = {};</script>')), "not an inline")
  directory <- withr::local_tempdir()
  writeBin(charToRaw(original), file.path(directory, "math.html"))
  writeBin(charToRaw('<html>plain β</html>'), file.path(directory, "plain.html"))
  expect_identical(env$repair_mathjax_order(directory), 1L)
  expect_identical(env$repair_mathjax_order(directory), 0L)
  expect_identical(rawToChar(readBin(file.path(directory, "math.html"), "raw", n = file.info(file.path(directory, "math.html"))$size)), corrected)
})
