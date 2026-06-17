# Spell-check vignette prose and .Rd text against inst/WORDLIST.
#
# Report-only (error = FALSE): prints potential spelling errors to the check
# log without failing R CMD check, so an incomplete inst/WORDLIST never breaks
# CI. Skipped on CRAN (skip_on_cran = TRUE) because it depends on the system
# hunspell dictionary.
#
# To switch to enforcement (error = TRUE), first run spelling::update_wordlist()
# locally (needs hunspell) to populate inst/WORDLIST with every current term,
# then flip error = TRUE. DESCRIPTION uses `Language: en-GB` because the
# package prose uses British spellings (behaviour, colour, modelling, ...), and
# CI has already confirmed the en_GB hunspell dictionary is available.
if (requireNamespace("spelling", quietly = TRUE)) {
  spelling::spell_check_test(
    vignettes = TRUE,
    error = FALSE,
    skip_on_cran = TRUE
  )
}
