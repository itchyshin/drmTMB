# After task: correlated-slope and binomial-phylogeny NEWS prose

## Task goal

Explain five historical 0.7.0 additions to an applied ecology or evolution
reader: the four ordinary correlated-slope families and the first binomial
phylogenetic intercept. Base: `2370e36e`, after PR #1403.

## Files created or changed

`NEWS.md`: only the five named section bodies. The interleaved CRAN/Julia
paragraph is byte-identical. This report and a separate check-log entry record
the review. No code, API, tests, workflows, or other release entries changed.

## Checks run and exact outcomes

- `git diff --check`: PASS.
- `Rscript -e 'pkgdown::build_news(preview = FALSE)'`: PASS after granting
  normal network/cache access; generated `pkgdown-site/news/index.html`.
- `Rscript tools/check-reader-contracts.R`: PASS, reader vignette contract OK.
- `python3 tools/qseries_v1_claim_guard.py`: PASS (exit 0).
- Executed the existing `process_patterns` and `visible_text` definitions from
  `tools/check-pkgdown-public-surface.R` against the regenerated NEWS: PASS,
  zero matches. The full-site checker was not run against this NEWS-only build.
- Parsed the source before/after by level-two heading: exactly the intended
  five bodies changed, heading sequence unchanged, excluded CRAN/Julia
  paragraph unchanged. A focused pattern scan found 29 occurrences before and
  zero after: `(?i)\b(?:mc-\d+|wave|design-\d+|point_fit_recovery|ledger|slice|gate)\b|#\d+`.
- Read the generated HTML for all five sections, then used `xml2` to extract
  their visible text and scan for `mc-[0-9]+|Wave|design-[0-9]+|point_fit_recovery|ledger|#1048`:
  PASS. The excluded Julia paragraph was excluded from that focused scan.

## Consistency audit

Pat and Rose were review perspectives in this task, not separately launched
agents. Each slope entry retains its formula, complete-data restriction,
estimated intercept and slope SDs and correlation, and exclusions. The
lognormal, binomial and negative-binomial entries retain the within-group
variation requirement and pre-fit rejection. The negative-binomial entry
retains zero-inflated and truncated-family exclusions; lognormal retains the
Gamma exclusion. Intervals remain unavailable and coverage unestablished.

Compared against `docs/design/01-formula-grammar.md:175,189,194,256`, design
257 and the correlated-slope after-task reports. Read the constant-predictor
rejection assertion in `test-binomial-correlated-re-mspl-prereq.R:230`.

Read issue #1048 and its recovery comment. The source of the 160-tip and
approximately 9% attenuation numbers is the Julia twin, not a native drmTMB
simulation. NEWS now names that provenance and retains the Bernoulli-only
scope: 30 replicates per size, unit-height balanced tree, 12 observations per
tip. At 40/80 tips phylogenetic SD biases were -8.9%/-9.5%; at 160 tips the
SD bias was -0.1% and slope bias +0.3%. No two-column recovery or interval
coverage is inferred. The admitted two-column fitting syntax remains explicit.

## Tests of the tests

The focused scan detects 29 original terms, then zero in the revised text.
The section comparison detects any additional NEWS edit. No numerical tests
were added or run because model behavior is unchanged.

## What did not go smoothly

The sandbox initially blocked SSH and pkgdown's CRAN metadata lookup/Sass
cache. The approved access reruns succeeded. The first temporary section
comparison used a greedy heading expression; restricting it to non-newline
characters fixed the check. Generated heading IDs carry the inherited
`-0-7-1` suffix despite these source sections appearing under 0.7.0; source
release headings and chronology were not changed. Rendering checks therefore
matched the heading prefix, not an assumed ID.

## Team learning and process improvements

A reader-language repair must verify the provenance of numerical claims:
removing an issue number can otherwise hide which engine and design supplied
the evidence. Existing public prose patterns need no change for this slice;
the focused scan supplements their narrower vocabulary.

## Design-doc updates

None. No model or validation policy changed.

## Pkgdown/documentation updates

Built NEWS only. The generated page is local and untracked; no full-site,
deployment, or visual browser-layout pass is claimed.

## GitHub issue maintenance

Read open PRs and open issues returned by the NEWS search. No matching
standalone reader-cleanup issue was found, and none was created or changed.
This slice is submitted as a focused draft PR; no merge is authorized here.

## Known limitations and next actions

This repairs five historical entries only. Other NEWS process language and
the unrelated Julia/CRAN paragraph remain for their owning slices. Review the
draft PR and check CI before integration.
