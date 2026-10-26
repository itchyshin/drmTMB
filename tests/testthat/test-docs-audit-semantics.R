test_that("404 MathJax configuration stays inline without changing other scripts", {
  skip_if_not_installed("xml2")
  script <- test_path("..", "..", "tools", "build-pkgdown.R")
  skip_if_not(file.exists(script), "documentation builder is not in this build")
  definitions <- Filter(function(expr) {
    is.call(expr) && identical(expr[[1]], as.name("<-")) &&
      identical(expr[[2]], as.name("repair_404_mathjax"))
  }, as.list(parse(script)))
  expect_length(definitions, 1L)
  env <- new.env(parent = baseenv())
  eval(definitions[[1L]], env)
  site <- tempfile("mathjax-404-")
  dir.create(site)
  on.exit(unlink(site, recursive = TRUE), add = TRUE)
  path <- file.path(site, "404.html")
  writeLines(paste0(
    '<html><head>',
    '<script src="https://example.test/NA">window.MathJax = {};</script>',
    '<script src="https://cdn.example/mathjax.js"></script>',
    '<script src="https://example.test/NA">otherConfig = {};</script>',
    '</head></html>'
  ), path)
  expect_identical(env$repair_404_mathjax(site), 1L)
  page <- xml2::read_html(path)
  expect_length(xml2::xml_find_all(page,
    ".//script[not(@src)][contains(.,'window.MathJax')]"), 1L)
  expect_identical(xml2::xml_attr(xml2::xml_find_all(page, ".//script[@src]"), "src"),
    c("https://cdn.example/mathjax.js", "https://example.test/NA"))
  expect_identical(env$repair_404_mathjax(site), 0L)
  expect_identical(env$repair_404_mathjax(file.path(site, "missing")), 0L)
})

test_that("refusal hints retain the existing structured route boundaries", {
  bad <- list(list(type = "intercept", covariance_label = "p", label = "1 | p | id"))
  message_for <- function(expr) {
    condition <- tryCatch(force(expr), error = identity)
    expect_s3_class(condition, "error")
    gsub("[[:space:]]+", " ", conditionMessage(condition))
  }
  binomial <- message_for(drmTMB:::validate_binomial_mu_random_terms(bad))
  expect_match(binomial, "phylo", fixed = TRUE)
  expect_match(binomial, "relmat", fixed = TRUE)
  expect_match(binomial, "remain unsupported", fixed = TRUE)
  beta <- message_for(drmTMB:::validate_beta_mu_random_terms(bad))
  expect_match(beta, "relmat", fixed = TRUE)
  expect_match(beta, "fixed-effect-only", fixed = TRUE)
  structured <- message_for(drmTMB:::drm_reject_phase1_terms(
    quote(phylo(1 | species, tree = tree)), "mu"))
  expect_match(structured, "one strict-Beta", fixed = TRUE)
  expect_match(structured, "binomial", fixed = TRUE)
  expect_match(structured, "relmat", fixed = TRUE)
})

test_that("diagnostic subsetting honors drop and retains overall status", {
  tab <- data.frame(check = c("first", "second"), status = c("ok", "warning"))
  class(tab) <- c("drm_check", "data.frame")
  attr(tab, "ok") <- FALSE
  attr(tab, "n_checks_total") <- 2L
  one <- tab[, "check"]
  expect_s3_class(one, "drm_check")
  expect_equal(ncol(one), 1L)
  expect_identical(attr(one, "ok"), FALSE)
  expect_identical(attr(one, "n_checks_total"), 2L)
  expect_identical(tab[, "check", drop = TRUE], c("first", "second"))
  expect_s3_class(tab[1, , drop = FALSE], "drm_check")
  attr(tab, "n_checks_total") <- NULL
  expect_identical(attr(tab[1, , drop = FALSE], "n_checks_total"), 2L)
})

test_that("convergence help retains the exported generic and Julia method aliases", {
  path <- drm_pkg_path("man/is_converged.Rd")
  help <- readLines(path, warn = FALSE)
  expect_true("is_converged(object, ...)" %in% help)
  expect_true("\\alias{is_converged.drmTMB_julia}" %in% help)
  expect_true("\\alias{is_converged.drmTMB_julia_xfam}" %in% help)
})


test_that("numbered argument anchors are unique and retain incoming targets", {
  skip_if_not_installed("xml2")
  script <- test_path("..", "..", "tools", "build-pkgdown.R")
  skip_if_not(file.exists(script), "documentation builder is not in this build")
  definitions <- Filter(function(expr) {
    is.call(expr) && identical(expr[[1]], as.name("<-")) &&
      identical(expr[[2]], as.name("repair_duplicate_argument_anchors"))
  }, as.list(parse(script)))
  expect_length(definitions, 1L)
  env <- new.env(parent = baseenv())
  eval(definitions[[1L]], env)
  site <- tempfile("argument-anchors-")
  dir.create(site)
  on.exit(unlink(site, recursive = TRUE), add = TRUE)
  path <- file.path(site, "reference.html")
  writeLines(paste0('<html><body><dl>',
    '<dt id="arg-tree-">tree1<a href="#arg-tree-"></a></dt>',
    '<dt id="arg-tree-">tree2<a href="#arg-tree-"></a></dt>',
    '<dt id="arg-tree-2">reserved<a href="#arg-tree-2"></a></dt>',
    '<dt id="arg-x">x<a href="#arg-x"></a></dt>',
    '</dl></body></html>'), path)
  expect_identical(env$repair_duplicate_argument_anchors(site), 1L)
  page <- xml2::read_html(path)
  terms <- xml2::xml_find_all(page, ".//dt")
  ids <- xml2::xml_attr(terms, "id")
  expect_identical(ids, c("arg-tree-", "arg-tree-3", "arg-tree-2", "arg-x"))
  expect_identical(anyDuplicated(ids), 0L)
  expect_identical(xml2::xml_attr(xml2::xml_find_first(terms, "./a"), "href"),
                   paste0("#", ids))
  expect_identical(env$repair_duplicate_argument_anchors(site), 0L)
})
