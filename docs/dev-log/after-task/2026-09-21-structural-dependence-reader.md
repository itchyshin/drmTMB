# Structural-dependence reader repair (S1)

## 1. Goal

Rewrite `vignettes/structural-dependence.Rmd` so a first-time ecology or
evolution researcher can pick a structural random-effect route from their
scientific question, without needing to know internal labels such as
evidence-tier names or software-construction terms. The deliberately failing
reader-contract test written on this branch (`8401f134b`) names the exact
markers required and the exact internal phrases to remove.

## 2. Implemented

Opened the article with the required sentence "Choose the structure that
matches your scientific question." Rebuilt the "Pick the route" table from
three columns (`Question | Current route | Status`) to the required four
(`Your question | A sensible starting point | What to check before reporting |
Read next`), adding a `Read next` link to each structure's specialist guide.
Removed the three banned internal phrases (`Pedigree/Ainv bridge marshalling`,
`recovery-grade NB2`, `fixed-kappa mesh intercept`), replacing each with plain
wording that keeps the same limitation: pedigree/`Ainv` matrix assembly stays
"not available yet"; the two `recovery-grade NB2` mentions became "run
`check_drm()` and read the guide before reporting it"; the mesh route is now
described as "a mesh-based option with a fixed spatial range." Added the
required sentence "A successful fit does not show that every related model is
reliable." as the opening of the "Fitted versus planned" section, followed by
a plain-language explanation that a fit's success does not certify a
neighbouring model (different family, extra slope, or combined structure)
without its own check. Re-expressed the `q1`/`q2`/`q4` and
`inference-ready with caveats` / `point-fit/extractor only` evidence-tier
language in that section in plain words ("links those two traits through one
shared structured correlation," "you can fit and inspect the estimate, but do
not report an interval for it yet") while keeping the same fitted/not-fitted
boundary. All parameter names (`mu`, `sigma`, `rho12`, family names), all
family-specific gate names required by other tests (see Section 6), and every
"not available yet" limitation from the original table are preserved.

## 3a. Decisions and Rejected Alternatives

Kept the exact technical gate phrases (for example "Poisson/NB2 q1
phylogenetic `mu` intercept-plus-one-slope," "NB2 q1 relmat `sigma`,"
"Gamma q1 relmat `mu`," "truncated-NB2 q1 relmat `hu`") rather than
paraphrasing them away, because `test_provider_claims_name_exact_nongaussian_gates`
in the same test module requires those exact substrings to remain in this
file; verified this before editing (Section 6). This means the fix is
targeted at the three named internal phrases and the required new sentences,
not a full rewrite of every technical term in the table: `q1`/`q2`/`q4`
notation, family names, and `diagnostic-only` labelling are already used on
the already-shipped `model-map.Rmd` reader page and are not on this file's
banned-phrase list, so keeping them (with the reader-question framing and the
"what to check" column doing the explanatory work) was judged the safer,
more surgical repair than inventing a parallel plain-English vocabulary that
risked drifting from the exact evidence-tier facts. Rejected reviving or
merging from `origin/codex/reader-model-guides-cleanup-20260918`: its one
commit touching this path range did not actually change
`vignettes/structural-dependence.Rmd` (confirmed byte-identical to the
pre-edit file at that ref), so there was nothing to build on. Did not touch
`tools/tests/test_capability_ledger.py`: no adjustment was needed once the
prose matched every required marker. Did not rename the `## Pick the route`
or `## Fitted versus planned` headings: neither heading text is checked by
any test and renaming was not required by the handover.

## 4. Files Touched

- `vignettes/structural-dependence.Rmd`
- `docs/dev-log/after-task/2026-09-21-structural-dependence-reader.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- Worktree `/private/tmp/drmtmb-structural-reader-20260921`, branch
  `codex/structural-reader-decisions-20260921`, base commit `37cde2e01`
  (`github/codex/structural-reader-decisions-20260921`, PR #1418, draft).
  drmTMB 0.7.1 installed; no compilation performed.
- Lease: `~/shinichi-brain/tools/lane_lease.sh --claim drmTMB --paths
  vignettes/structural-dependence.Rmd,docs/dev-log/after-task/2026-09-21-structural-dependence-reader.md,docs/dev-log/check-log.md
  --note "S1 structural-dependence reader repair (#1418)"` →
  `GRANTED -- lane 'claude:drmtmb-structural-reader-20260921:23107' holds
  drmTMB [...] for 4h`.
- `python3 -m unittest tools.tests.test_capability_ledger.CapabilityLedgerTests.test_reader_navigation_redirect_and_public_language_contract`
  on the unmodified page: **FAIL** with `AssertionError:
  'Choose the structure that matches your scientific question.' not found in
  '...'` (the very first required marker; not an unrelated failure).
- `python3 -m unittest tools.tests.test_capability_ledger` on the unmodified
  page: `Ran 80 tests ... FAILED (failures=1)`, the one failure being the
  target test above.
- After the prose edit, `python3 -m unittest tools.tests.test_capability_ledger`:
  `Ran 80 tests in 1.987s` / `OK`, plus `C14 receipt equivalence: OK` and
  `capability-ledger: OK`.
- `Rscript --vanilla -e 'rmarkdown::render("vignettes/structural-dependence.Rmd", output_dir = tempdir(), quiet = TRUE)'`:
  exit 0.
- `Rscript --vanilla -e 'rmarkdown::render("vignettes/structural-dependence.Rmd", output_dir = "<scratchpad>/render/drmtmb", quiet = TRUE)'`:
  exit 0; produced `structural-dependence.html` (15,536 bytes).
- `Rscript tools/check-reader-contracts.R`: `Reader vignette contract: OK`.
- `git diff --check`: clean (no output).
- Parsed the rendered HTML's first table: 4 header cells
  (`Your question`, `A sensible starting point`, `What to check before
  reporting`, `Read next`) and exactly 5 data rows, each with exactly 4
  `<td>` cells; the literal `|` characters inside backtick code spans
  (for example `` `animal(1 | individual, ...)` ``) did not split any table
  cell.
- Manually read the rendered first screen (extracted body text): the opening
  sentence, the assumption paragraph, and the four-column table appear before
  any specialist link; the table's fourth column routes to the matching
  specialist guide for every row.
- Consistency scans (protocol `docs/design/10-after-task-protocol.md`):
  `rg "meta_gaussian|tau ~|rho ~|meta_known_V\([^V]|meta_known_V\(V = V\).*(current|preferred|stable|default)" vignettes/structural-dependence.Rmd`
  → no matches; `rg "simple.*mu random|sigma.*Later|currently.*only.*mu|optional simple.*location|log_sd_mu|Current TMB-side objects" vignettes/structural-dependence.Rmd`
  → no matches.
- Repo-wide re-check of the three banned phrases in the edited file:
  `grep -n "Pedigree/Ainv bridge marshalling\|recovery-grade NB2\|fixed-kappa mesh intercept" vignettes/structural-dependence.Rmd`
  → no matches (exit 1).
- `git diff -- vignettes/structural-dependence.Rmd | grep "^+"` piped through a
  search for the em-dash character (U+2014): no matches, so no em dash was
  introduced in new prose.
- `git diff -- vignettes/structural-dependence.Rmd | grep -niE "\bPR #|\blane\b|\bhandover\b|\bmilestone\b|\bworktree\b|\bagent\b|\bregister\b|\bcodex\b|\bclaude\b"`:
  no matches: no internal process language introduced.
- `gh issue list -R itchyshin/drmTMB --search "structural-dependence reader"`
  and `--search "reader-first structural"`: both returned only #1243 (a
  Julia-companion-link consistency issue, unrelated to this prose repair; see
  Section 7a).
- No `devtools::test()`, `load_all()`, or `R CMD check` run, per the assigned
  scope (drmTMB 0.7.1 is already installed; this change is prose-only inside
  one vignette).

## 6. Tests of the Tests

Confirmed the red test failed for exactly the intended reason (missing
opening sentence) before editing, not for an unrelated cause (Section 5).
Before writing the new table, checked the rest of the same test file for
other assertions that read `vignettes/structural-dependence.Rmd`, because a
plain-language rewrite risks deleting content another test still requires:
`test_provider_claims_name_exact_nongaussian_gates` (line 2278) requires the
exact substrings "Poisson/NB2 q1 phylogenetic `mu`
intercept-plus-one-slope," "NB2 q1 phylogenetic `sigma`," "Student-t q1
phylogenetic `nu`," "cumulative-logit q1 phylogenetic `mu`," "Poisson/NB2 q1
animal `mu` intercept-plus-one-slope," "NB2 q1 animal `sigma`," "beta animal
models," "Poisson/NB2 q1 relmat `mu` intercept-plus-one-slope," "NB2 q1
relmat `sigma`," "Gamma q1 relmat `mu`," and "truncated-NB2 q1 relmat `hu`"
to remain in this file (after whitespace normalization), and separately bans
five other stale phrases across a combined multi-file string that includes
this vignette; `test_reader_surfaces_do_not_erase_structured_sigma_slope_support`
(line 1658) bans 37 other stale phrasings across a larger multi-file
combination that also includes this vignette;
`test_spatial_inflation_tiers_propagate_across_current_surfaces` (line 2438)
requires four exact "diagnostic-only ... `zi ~ spatial(...)`" substrings to
remain. Re-ran the full 80-test module after editing specifically to catch a
regression in any of these other assertions, not only the one target test;
the full run reported `OK`, confirming the "recovery-grade" removal (deleting
only the seven-character prefix "recovery-grade ") left the required
"NB2 q1 ... `sigma`" substrings intact everywhere they were required.

## 7a. Issue Ledger

No open issue matched this reader-prose repair (Section 5's `gh issue list`
search). Issue #1243 (Julia-companion-link asymmetry) is unrelated: this
patch does not touch any DRM.jl cross-links. No issue was opened, closed, or
commented on.

## 8. Consistency Audit

Read the full test file's assertions about `structural-dependence.Rmd`
before and after editing (Section 6) rather than relying on the one target
test. Re-read the rendered HTML table structure to rule out a pipe-inside-
code-span table-parsing break. Checked the diff for em dashes and for
internal process language (PR numbers, lane, handover, milestone, worktree,
agent names, register, "Codex"/"Claude") and found none in the added lines.
Ran the protocol's stale-wording `rg` patterns from
`docs/design/10-after-task-protocol.md` against the edited file. Confirmed
via `git log`/`git merge-base` that `origin/codex/reader-model-guides-cleanup-20260918`,
the only plausibly overlapping branch touching this path, left this exact
file unchanged, so nothing needed reconciling. Did not touch `README.md`,
`_pkgdown.yml`, `NEWS.md`, `docs/design/01-formula-grammar.md`, or any other
vignette; the family/formula-grammar/likelihood scope named in `AGENTS.md`'s
Design Rules was not implicated by a prose-only change.

## 9. What Did Not Go Smoothly

The first design pass under-read the scope: a fully "plain-English" rewrite
of the evidence-tier language (translating every `q1`/`NB2`/`diagnostic-only`
term away) would have deleted several exact substrings that
`test_provider_claims_name_exact_nongaussian_gates` and
`test_reader_surfaces_do_not_erase_structured_sigma_slope_support` require
elsewhere in the same test module. Reading those two tests in full before
writing prose (Section 6) caught this before any edit was made, and the
final approach, remove only the three named phrases and add the two
required sentences, leaving the exact gate names in place, passed on the
first attempt with no failed edit-and-revert cycle. The pre-existing table
already used literal `|` characters inside backtick code spans (for example
`` `animal(1 | individual, pedigree = pedigree)` ``); this pattern was
carried into the new four-column table, so the render check in Section 5
specifically confirmed pandoc's pipe-table parser still respected the code
spans and did not mis-split any of the eleven such occurrences.

## 10. Known Residuals

The `## Fitted versus planned` section still uses `q1`/`q2`/`q4` shorthand in
two remaining sentences (the univariate-intercept-into-`sigma` sentence and
the four-provider one-slope `sigma` sentence); this shorthand is not on this
file's banned-phrase list and is not covered by an "explain q on first use"
requirement in the reader-contract test, but a later editorial pass could
still expand it further, matching `model-map.Rmd`'s own explicit "in developer
shorthand, q=4 ... means four distributional endpoints" aside. The three
`spatial-inflation` models (`zi ~ spatial()`, fixed-`zi` `mu ~ spatial()`
variants) remain described as "diagnostic-only ... checked on a single
example" is required verbatim by a sibling test and by the mission's
own "keep every caveat" instruction, but it is still one of the harder
sentences in the article for a first-time reader; the linked spatial guide is
where a fuller explanation belongs. This patch does not touch the other
three sites in the four-site continuation map (drmTMB's model map already
done separately; drmTMB reference/README surfaces; gllvmTMB's beginner
article, limits article, and phylogeny article) named in the handover remain
remain open work for a separate slice.

## 11. Team Learning

When a reader-contract test bans specific phrases in one vignette, grep the
rest of the same test file for other assertions on that path before drafting
new prose: a different test in the identical file can require the exact
substrings a well-meaning plain-language rewrite would delete. Removing an
internal-sounding qualifier word (here, the single word "recovery-grade")
while leaving the following exact gate name untouched is often enough to
satisfy both a ban-this-phrase test and a keep-this-substring test at once,
and is lower risk than rephrasing the whole sentence. When a table cell needs
a literal pipe character, keep it inside backtick code spans and verify the
rendered `<td>` count per row rather than trusting the source Markdown alone.

## 12. Cross-Product Coverage

Covers the "Pick the route" table and the "Fitted versus planned" section of
`vignettes/structural-dependence.Rmd` only. Does NOT cover: any other
vignette; `README.md`; `_pkgdown.yml`; the drmTMB model-map reader repair
(separate protected worktree/lane); PR #1417's convergence-reader work
(separate protected lane); the gllvmTMB, GLLVModels.jl, or DRModels.jl sites
named in the handover's four-site continuation map; figures; the formula
grammar or engine; CI configuration; or release/versioning. This patch keeps
PR #1418 in draft; it does not merge or mark the PR ready.
