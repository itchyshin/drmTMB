# #1653 — explicit S3 usage on associate_pairs() so roxygen2 stays stable when
# Matrix (or other packages) alter the inferred update() signature.

test_that("associate_pairs pins update() usage in roxygen (#1653)", {
  text <- readLines(drm_pkg_path("R/associate-pairs.R"), warn = FALSE)
  expect_true(any(grepl("^#' @usage$", text)))
  expect_true(any(grepl("associate_pairs\\(fit_1, fit_2, kernel, association\\)", text)))
  expect_true(any(grepl("\\\\method\\{update\\}\\{drm_pair_association\\}", text)))
})

test_that("association update usage is stable with Matrix attached", {
  skip_on_cran()
  skip_if_not_installed("roxygen2")
  skip_if_not_installed("withr")

  root <- dirname(drm_pkg_path("DESCRIPTION"))
  skip_if_not(
    all(file.exists(file.path(root, c("DESCRIPTION", "NAMESPACE")))) &&
      dir.exists(file.path(root, "R")) && dir.exists(file.path(root, "man")),
    "The package source tree is unavailable in an installed-package check."
  )
  recorded <- read.dcf(file.path(root, "DESCRIPTION"),
                       fields = "Config/roxygen2/version")[1L, 1L]
  skip_if(
    is.na(recorded) || as.character(utils::packageVersion("roxygen2")) != recorded,
    "Installed roxygen2 differs from the version recorded in DESCRIPTION."
  )

  ns <- asNamespace("drmTMB")
  method <- get("update.drm_pair_association", envir = ns, inherits = FALSE)
  expect_identical(formals(method), as.pairlist(alist(object = , ... = )))

  if (!"package:Matrix" %in% search()) withr::local_package("Matrix")
  expect_true("package:Matrix" %in% search())
  tmp <- tempfile("roxy-associate-")
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  expect_true(all(file.copy(file.path(root, c("DESCRIPTION", "NAMESPACE", "R", "man")),
                            tmp, recursive = TRUE)))
  generated <- file.path(tmp, "man", "associate_pairs.Rd")
  expect_identical(unlink(generated), 0L)
  expect_false(file.exists(generated))
  suppressMessages(suppressWarnings(utils::capture.output(
    roxygen2::roxygenise(tmp, roclets = "rd", load_code = function(path) ns)
  )))
  expect_true(file.exists(generated))
  if (file.exists(generated)) {
    expect_identical(
      readLines(generated, warn = FALSE),
      readLines(file.path(root, "man", "associate_pairs.Rd"), warn = FALSE)
    )
  }
})
