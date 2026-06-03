# Spell-check vignette prose and .Rd text against inst/WORDLIST.
#
# This test is report-only (error = FALSE): it prints potential spelling
# errors to the check log without failing R CMD check, so an incomplete
# inst/WORDLIST never breaks CI. To enforce the wordlist instead, run
# spelling::update_wordlist() locally to refresh inst/WORDLIST, then flip
# error = TRUE here. See docs/dev-log/after-task/ for the rollout note.
if (requireNamespace("spelling", quietly = TRUE)) {
  spelling::spell_check_test(
    vignettes = TRUE,
    error = FALSE,
    skip_on_cran = TRUE
  )
}
