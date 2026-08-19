test_that("function-map inventory matches the public API", {
  root <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  inventory_path <- file.path(root, "tools", "function-map-inventory.R")
  namespace_path <- file.path(root, "NAMESPACE")
  skip_if(
    !file.exists(inventory_path) || !file.exists(namespace_path),
    "source-only function-map inventory is unavailable"
  )

  inventory_env <- new.env(parent = baseenv())
  sys.source(inventory_path, envir = inventory_env)
  namespace_lines <- readLines(namespace_path, warn = FALSE)
  exports <- sub(
    "^export\\(([^)]+)\\)$", "\\1",
    grep("^export\\(", namespace_lines, value = TRUE)
  )

  expect_length(
    setdiff(inventory_env$function_map_primary_exports, exports),
    0L
  )
  expect_length(intersect(
    inventory_env$function_map_primary_exports,
    inventory_env$function_map_compatibility
  ), 0L)

  classification <- inventory_env$function_map_classify_exports(exports)
  expect_setequal(names(classification), exports)
  expect_false(anyNA(classification))
  expect_true(all(classification %in% c(
    "featured", "compatibility", "reference_only"
  )))
  expect_true(all(
    classification[inventory_env$function_map_primary_exports] == "featured"
  ))
  expect_true(all(
    classification[inventory_env$function_map_compatibility] == "compatibility"
  ))

  for (method in inventory_env$function_map_primary_methods) {
    expect_true(any(grepl(
      paste0("^S3method\\(", method, ",drmTMB\\)$"),
      namespace_lines
    )))
  }

  reference_topics <- vapply(
    inventory_env$function_map_primary_exports,
    function(name) sub(
      "[.]html$", "",
      basename(inventory_env$function_map_reference_path(name))
    ),
    character(1)
  )
  method_topics <- vapply(
    inventory_env$function_map_primary_methods,
    function(name) sub(
      "[.]html$", "",
      basename(inventory_env$function_map_reference_path(name, method = TRUE))
    ),
    character(1)
  )
  expect_true(all(file.exists(file.path(root, "man", paste0(
    c(reference_topics, method_topics), ".Rd"
  )))))
})

test_that("function-map article exposes the visual and both downloads", {
  root <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  article_path <- file.path(
    root, "vignettes", "articles", "function-map-cheatsheet.Rmd"
  )
  assets <- file.path(
    root,
    "pkgdown",
    "assets",
    "cheatsheets",
    c("drmTMB-function-map.pdf", "drmTMB-function-cheatsheet.pdf")
  )
  skip_if(
    !file.exists(article_path) || !dir.exists(file.path(root, "pkgdown")),
    "source-only function-map article and assets are unavailable"
  )

  article <- paste(readLines(article_path, warn = FALSE), collapse = "\n")
  expect_match(article, "drmTMB function map", fixed = TRUE)
  expect_match(article, "function_map_html()", fixed = TRUE)
  expect_match(article, "../cheatsheets/drmTMB-function-map.pdf", fixed = TRUE)
  expect_match(
    article,
    "../cheatsheets/drmTMB-function-cheatsheet.pdf",
    fixed = TRUE
  )
  expect_true(all(file.exists(assets)))
  expect_true(all(file.info(assets)$size > 1000))
  expect_false(file.exists(file.path(
    root, "vignettes", "function-map-cheatsheet.png"
  )))
  expect_false(file.exists(file.path(
    root, "vignettes", "articles", "function-map-cheatsheet.png"
  )))
})
