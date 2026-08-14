contract_linter <- new.env(parent = globalenv())
sys.source(
  testthat::test_path("..", "..", "tools", "check-reader-contracts.R"),
  envir = contract_linter
)

contract_fixture <- function(files = list(), manifest = NULL, exceptions = NULL) {
  root <- tempfile("reader-contract-")
  dir.create(file.path(root, "vignettes"), recursive = TRUE)
  dir.create(file.path(root, "inst", "reader-contracts"), recursive = TRUE)

  base_files <- list(
    "adding-families.Rmd" = "fit$opt$convergence",
    "testing-likelihoods.Rmd" = "fit$model$X",
    "source-map.Rmd" = "fit$model$weights",
    "large-data.Rmd" = "`fit$obj` was intentionally dropped",
    "figure-gallery.Rmd" = paste(
      'pred_tail$model <- "Tail weight"',
      'pred_zi$model <- "Structural-zero probability"',
      'pred_rho$model <- "Residual correlation"',
      sep = "\n"
    ),
    "reader.Rmd" = "summary(fit)$parameters\nranef(fit)$terms"
  )
  files <- utils::modifyList(base_files, files)
  for (name in names(files)) writeLines(files[[name]], file.path(root, "vignettes", name))

  if (is.null(manifest)) {
    manifest <- data.frame(
      vignette = names(files),
      audience = c("contributor", "contributor", "contributor", rep("reader", length(files) - 3L)),
      permitted_private_fields = c("opt", "model", "model", rep("", length(files) - 3L)),
      rationale = c("convergence assertion", "likelihood reconstruction", "source documentation", rep("", length(files) - 3L)),
      stringsAsFactors = FALSE
    )
  }
  if (is.null(exceptions)) {
    exceptions <- contract_linter$reader_contract_expected_exceptions
  }
  utils::write.csv(manifest, file.path(root, "inst", "reader-contracts", "vignette-manifest.csv"), row.names = FALSE)
  utils::write.csv(exceptions, file.path(root, "inst", "reader-contracts", "private-access-exceptions.csv"), row.names = FALSE)
  root
}

test_that("the scanner catches private slots regardless of object name", {
  root <- contract_fixture(files = list("reader.Rmd" = "arbitrary_name$sdpars$mu"))
  expect_match(
    paste(contract_linter$reader_contract_lint(root), collapse = "\n"),
    "Undeclared private access in reader.Rmd.*sdpars"
  )
})

test_that("the scanner catches bracket private slots regardless of object name", {
  root <- contract_fixture(files = list("reader.Rmd" = 'x[["sdpars"]][["mu"]]'))
  expect_match(
    paste(contract_linter$reader_contract_lint(root), collapse = "\n"),
    "Undeclared private access in reader.Rmd.*sdpars"
  )
})

test_that("public summary and ranef fields are accepted", {
  root <- contract_fixture()
  expect_length(contract_linter$reader_contract_lint(root), 0L)
})

test_that("contributor permissions are field-specific", {
  root <- contract_fixture(files = list("adding-families.Rmd" = "fit$opt$convergence\nfit$sdr$pdHess"))
  expect_match(
    paste(contract_linter$reader_contract_lint(root), collapse = "\n"),
    "Undeclared private access in adding-families.Rmd.*sdr"
  )
})

test_that("contributor permissions cannot be broadened even when used", {
  root <- contract_fixture(files = list("adding-families.Rmd" = "fit$opt$convergence\nfit$sdr$pdHess"))
  manifest_path <- file.path(root, "inst", "reader-contracts", "vignette-manifest.csv")
  manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
  manifest$permitted_private_fields[manifest$vignette == "adding-families.Rmd"] <- "opt;sdr"
  utils::write.csv(manifest, manifest_path, row.names = FALSE)
  expect_match(
    paste(contract_linter$reader_contract_lint(root), collapse = "\n"),
    "Contributor permission must be exactly adding-families.Rmd -> opt"
  )
})

test_that("the manifest is complete and has no duplicate or stale article rows", {
  root <- contract_fixture()
  writeLines("summary(fit)$parameters", file.path(root, "vignettes", "unmanifested.Rmd"))
  expect_match(
    paste(contract_linter$reader_contract_lint(root), collapse = "\n"),
    "Missing manifest row.*unmanifested.Rmd"
  )

  manifest <- utils::read.csv(file.path(root, "inst", "reader-contracts", "vignette-manifest.csv"), stringsAsFactors = FALSE)
  manifest <- rbind(manifest, manifest[manifest$vignette == "reader.Rmd", , drop = FALSE])
  utils::write.csv(manifest, file.path(root, "inst", "reader-contracts", "vignette-manifest.csv"), row.names = FALSE)
  expect_match(
    paste(contract_linter$reader_contract_lint(root), collapse = "\n"),
    "Duplicate manifest row.*reader.Rmd"
  )

  root <- contract_fixture()
  manifest_path <- file.path(root, "inst", "reader-contracts", "vignette-manifest.csv")
  manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
  manifest <- rbind(
    manifest,
    data.frame(
      vignette = "removed-article.Rmd",
      audience = "reader",
      permitted_private_fields = "",
      rationale = "",
      stringsAsFactors = FALSE
    )
  )
  utils::write.csv(manifest, manifest_path, row.names = FALSE)
  expect_match(
    paste(contract_linter$reader_contract_lint(root), collapse = "\n"),
    "Manifest references absent vignette.*removed-article.Rmd"
  )
})

test_that("reader exceptions are clause-bound and stale exceptions fail", {
  exceptions <- data.frame(
    vignette = "reader.Rmd",
    field = "obj",
    clause = "fit$obj was intentionally dropped",
    rationale = "negative explanatory clause",
    stringsAsFactors = FALSE
  )
  root <- contract_fixture(exceptions = exceptions)
  expect_match(
    paste(contract_linter$reader_contract_lint(root), collapse = "\n"),
    "Stale or ambiguous private-access exception"
  )

  root <- contract_fixture(
    files = list("reader.Rmd" = "fit$obj was intentionally dropped"),
    exceptions = exceptions
  )
  expect_match(
    paste(contract_linter$reader_contract_lint(root), collapse = "\n"),
    "Approved private-access exception record.*missing"
  )
})

test_that("invalid declared private vocabulary fails closed", {
  root <- contract_fixture()
  manifest_path <- file.path(root, "inst", "reader-contracts", "vignette-manifest.csv")
  manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
  manifest$permitted_private_fields[manifest$vignette == "adding-families.Rmd"] <- "opt;not_a_private_slot"
  utils::write.csv(manifest, manifest_path, row.names = FALSE)
  expect_match(
    paste(contract_linter$reader_contract_lint(root), collapse = "\n"),
    "Invalid declared private field.*not_a_private_slot"
  )
})

test_that("exception records are immutable, unique, and cannot be widened", {
  root <- contract_fixture()
  exception_path <- file.path(root, "inst", "reader-contracts", "private-access-exceptions.csv")
  exceptions <- utils::read.csv(exception_path, stringsAsFactors = FALSE, check.names = FALSE)
  exceptions <- rbind(exceptions, exceptions[1L, , drop = FALSE])
  utils::write.csv(exceptions, exception_path, row.names = FALSE)
  expect_match(
    paste(contract_linter$reader_contract_lint(root), collapse = "\n"),
    "Duplicate private-access exception record"
  )

  extra_exception <- data.frame(
    vignette = "reader.Rmd",
    field = "obj",
    clause = "fit$obj reader-only explanation",
    rationale = "structurally valid but unauthorized",
    stringsAsFactors = FALSE
  )
  root <- contract_fixture(
    files = list("reader.Rmd" = "fit$obj reader-only explanation"),
    exceptions = rbind(contract_linter$reader_contract_expected_exceptions, extra_exception)
  )
  expect_match(
    paste(contract_linter$reader_contract_lint(root), collapse = "\n"),
    "Unauthorized private-access exception record.*reader.Rmd"
  )
})

test_that("the live corpus has the complete immutable manifest", {
  project_root <- normalizePath(testthat::test_path("..", ".."))
  manifest <- contract_linter$reader_contract_read_csv(
    file.path(project_root, "inst", "reader-contracts", "vignette-manifest.csv"),
    c("vignette", "audience", "permitted_private_fields", "rationale")
  )
  source_vignettes <- basename(list.files(file.path(project_root, "vignettes"), pattern = "[.]Rmd$"))
  expect_equal(nrow(manifest), 37L)
  expect_identical(anyDuplicated(manifest$vignette), 0L)
  expect_setequal(manifest$vignette, source_vignettes)
  expect_length(contract_linter$reader_contract_lint(project_root), 0L)
})
