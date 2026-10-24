test_that("@param engine names every family the Julia registry admits (#1569)", {
  rd <- test_path("..", "..", "man", "drmTMB.Rd")
  skip_if_not(file.exists(rd), "man/ is unavailable in an installed-package check.")
  text <- paste(readLines(rd, warn = FALSE), collapse = " ")
  start <- regexpr("\\item{engine}{", text, fixed = TRUE)
  skip_if(start < 0L, "engine item not found in drmTMB.Rd")
  engine_doc <- gsub("\\s+", " ", substr(text, start, start + 2500L))
  for (fam in c("skew_normal", "cumulative_logit", "biv_student", "biv_lognormal")) {
    expect_true(
      fam %in% vapply(drmTMB:::drm_julia_family_registry(), `[[`, "", "family"),
      info = fam
    )
    expect_true(grepl(fam, engine_doc, fixed = TRUE), info = fam)
  }
})

test_that("vignettes do not call admitted Julia families unsupported (#1569)", {
  read <- function(p) {
    path <- test_path("..", "..", p)
    skip_if_not(file.exists(path), "vignettes/ is unavailable in an installed-package check.")
    paste(readLines(path, warn = FALSE), collapse = " ")
  }
  expect_false(grepl("`skew_normal\\(\\)` or another family", read("vignettes/julia-engine.Rmd")))
  expect_false(grepl("and `engine = \"julia\"` remain unsupported",
                     gsub("\\s+", " ", read("vignettes/distribution-families.Rmd"))))
  expect_false(grepl("rejects non-logit links.*and `engine = \"julia\"`",
                     gsub("\\s+", " ", read("vignettes/proportion-beta-binomial.Rmd"))))
  expect_false(grepl("binomial structured effects or Julia bridge",
                     read("vignettes/model-map.Rmd")))
})
