# #531 — corpair() marker docs and refusal should steer users to rho12 ~ x.

test_that("corpair() help distinguishes latent RE correlation from rho12 (#531)", {
  help <- readLines(drm_pkg_path("man/corpair.Rd"), warn = FALSE)
  text <- paste(help, collapse = " ")
  expect_match(text, "rho12", fixed = TRUE)
  expect_match(text, "latent", fixed = TRUE)
})

test_that("reserved corpair() formula entries name rho12 as the residual route", {
  entry <- list(
    dpar = "corpair(id, block = \"p\", from = \"mu1\", to = \"mu2\")",
    corpair = list(group = "id")
  )
  expect_error(
    drmTMB:::reject_corpair_formula_entries(list(entry)),
    "rho12"
  )
  expect_error(
    drmTMB:::reject_corpair_formula_entries(list(entry)),
    "residual"
  )
})