# Spell-check vignette prose and .Rd text against inst/WORDLIST.
#
# Enforced (error = TRUE): a new misspelling that is not in inst/WORDLIST
# fails R CMD check. The check is skipped on CRAN (skip_on_cran = TRUE),
# because it depends on the system hunspell dictionary, and runs on the
# package's own CI. When you intentionally introduce a new technical term,
# refresh the wordlist with spelling::update_wordlist() and commit it.
if (requireNamespace("spelling", quietly = TRUE)) {
  spelling::spell_check_test(
    vignettes = TRUE,
    error = TRUE,
    skip_on_cran = TRUE
  )
}
