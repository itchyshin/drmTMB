# Claude handover — reader-first documentation arc

**Date:** 2026-09-21 (America/Edmonton)  
**From:** Codex  
**To:** Claude Code  
**Repository:** `itchyshin/drmTMB`  
**Branch:** `codex/structural-reader-decisions-20260921`

## Mission

Make the public documentation understandable to a first-time researcher,
especially a biology PhD student.  Start with their scientific question, give a
plain explanation and a runnable route, then say what to check before reporting.
Keep limits honest, but do not expose internal validation, issue, CI, campaign,
or bookkeeping language to readers.

This handover covers **one narrow next slice only**: the public
`structural-dependence` article in drmTMB.  It is part of a wider four-site
reader-first documentation arc, but do not broaden the scope here.

## Critical context

- The intended audience is ecology, evolution, and environmental-science
  researchers, with other applied scientists welcome.  Readers should not need
  to know package-internal labels to choose a starting model.
- The writing rule is: **question -> plain explanation -> runnable example ->
  interpretation -> next decision**.  Prefer precise, clear, brief language.
- Preserve evidence boundaries.  Do not turn an honest limitation into a
  promise; make it a useful choice or a link to the detailed guide instead.
- This arc excludes figures, visual redesign, API or engine changes, releases,
  package registration, repository renames, and foreign-engine work.
- The GitHub remote is named `github`.  `origin` is a local Dropbox clone and
  must not be used to infer GitHub/main state.
- Other agents have live branches and pull requests.  Do not reset, rebase,
  overwrite, or edit their work.  The coordination board and a fresh lane
  preflight are the authority before editing.

## What has been accomplished

1. A Pat-style first-reader audit identified the opening capability table in
   `vignettes/structural-dependence.Rmd` as the immediate reader-friction point:
   it leads with labels such as `q2/q4`, recovery status, marshalling, and a
   fixed-kappa mesh rather than scientific choices.
2. A deliberately failing reader-contract test was written **before** changing
   prose and committed as `8401f134b` (`test: define structural reader contract`).
   It requires a question-led table and bans three internal phrases.
3. The checkpoint is pushed to
   `github/codex/structural-reader-decisions-20260921`.  No public prose has
   changed in this branch yet.

## Current state

| Item | State | Meaning |
|---|---|---|
| `tools/tests/test_capability_ledger.py` | intentionally red | It protects the desired reader surface and must become green only when the article is rewritten. |
| `vignettes/structural-dependence.Rmd` | unmodified on this branch | Claude owns the prose rewrite, subject to the scope below. |
| drmTMB PR #1417 | protected concurrent lane | Its convergence-reader work is active; inspect but do not modify it from this branch. |
| Wider cross-site arc | in progress | Other packages have separate branches/PRs; this branch is not their integration point. |

## Carried-over work and landing state

| Repository | Branch / main relation | CI | Shipped | Plan |
|---|---|---|---|---|
| drmTMB | `codex/structural-reader-decisions-20260921`, based from `github/main` at `54df129fe`; current checkpoint `8401f134b` | intentionally failing local contract test; no PR checks should be treated as release evidence | no public article change yet | rewrite one article, render, inspect, then update the draft PR |
| drmTMB | PR #1417, separate protected lane | active when last observed; do not alter from this branch | not part of this handover | allow its owner to finish and merge only when genuinely green |
| gllvmTMB / DRModels.jl / GLLVModels.jl | separate repositories and lanes | not a dependency for this patch | outside this branch | do not consolidate or rename here |

**CARRIED-OVER:** `codex/structural-reader-decisions-20260921` contains the
committed and pushed test checkpoint because it correctly fails until the prose
repair exists.  This is intentional TDD state, not an unknown CI regression.

**FINDINGS-OF-RECORD: none.**  The reader audit is already recorded above as
repository-grounded task context, not a new durable scientific finding.

## Exact scope for Claude

Edit only these owned files unless a fresh lane preflight gives a different,
non-overlapping instruction:

- `vignettes/structural-dependence.Rmd`
- `tools/tests/test_capability_ledger.py` (only if the contract needs a small,
  justified adjustment after the prose is drafted)

Replace the article's first reader-facing table and the `Fitted versus planned`
discussion with prose that:

1. Opens with: **“Choose the structure that matches your scientific question.”**
2. Uses the table headings: **Your question | A sensible starting point | What
   to check before reporting | Read next**.
3. Explains what each supported structure lets a researcher ask, in ordinary
   words, before giving specialised links.
4. States that a successful fit does not establish reliability of every related
   model, without discussing internal recovery bookkeeping.
5. Retains truthful scope and links readers to specialised pages for details.

Do not use the public phrases `Pedigree/Ainv bridge marshalling`,
`recovery-grade NB2`, or `fixed-kappa mesh intercept`.  Do not change figures,
examples' statistical meaning, APIs, CI configuration, any other vignette, or
`AGENTS.md`.

## Verification and acceptance gates

After the prose change, all must pass:

```sh
python3 -m unittest tools/tests/test_capability_ledger.py
Rscript -e 'rmarkdown::render("vignettes/structural-dependence.Rmd", output_dir=tempdir(), quiet=TRUE)'
Rscript tools/check-reader-contracts.R
git diff --check
```

Then inspect the rendered article as a reader, checking that the first screen
answers what the package can help them ask, offers a sensible route, and says
what a successful fit does *not* prove.  Do not claim completion from a source
grep alone.

## Gotchas

- The failing test is the start point.  Do not delete or weaken it merely to get
  green checks.
- `origin` is not GitHub.  Use `git fetch github` and compare to `github/main`.
- An earlier stale branch, `codex/model-map-reader-question-20260921`, conflicted
  with newer main changes and is not a recovery route.  Do not revive it.
- No raw `gh pr merge`.  This handover branch must remain a draft PR until all
  acceptance gates have passed and the current owner explicitly decides it is
  ready.
- Multi-lane documentation work means no `AGENTS.md` snapshot-pointer update
  belongs in this patch.  The coordination board remains the cross-lane pointer.

## Four-site continuation map (do not fold into this patch)

The overall reader-first arc is broader than this one prose repair.  These are
the next independently auditable targets, recorded here so they do not vanish
when the structural page is finished.

| Site | Next reader problem | Evidence-backed next slice | Boundary |
|---|---|---|---|
| drmTMB | The public model map still reads as an implementation register. | Rewrite only its less-common-model table around a scientific question, a reportability decision, and the next specialist guide. | Preserve precise scope in detailed guides; do not alter the engine or formula API. |
| drmTMB | Reference and installation surfaces sometimes teach contributor machinery to ordinary users. | Rename the public `_pkgdown.yml` reference descriptions to reader purposes; remove comparator/test/render dependencies from the ordinary README install route. | Keep contributor requirements elsewhere. |
| gllvmTMB | The beginner article shows a non-runnable formula sketch before loading its data; its limits and phylogeny articles still surface validation machinery before reader decisions. | First repair `vignettes/gllvmTMB.Rmd`: lead with a complete load -> fit -> check -> covariance sequence, then explain the mathematics.  Next translate `current-limits.Rmd` into safe-start/exploratory/do-not-use decisions, then move phylogeny simulation setup behind the analysis route. | Keep every family, link, rank, sample-size, interval, and uncertainty qualifier; inspect the rendered article and execute the first visible sequence in a clean R session. |
| GLLVModels.jl | Advisory R/Julia parity CI is red across NB2, truncated-NB2, and Student-t mechanisms. | Do not make a speculative repair.  First create build-independent, family-specific health invariants against an authoritative frozen build. | This is a diagnostic finding, not evidence that the documentation work regressed parity. |
| DRModels.jl | Current reader-route coverage is already split across live PRs #795--#800 (landing definition, getting started, model map, matrix tutorial, migration, reference prose, and a route gate). | Do not start another overlapping prose patch.  Review those live PRs as one reader journey after they have settled, then choose the first uncovered route from source plus rendered evidence. | Do not expand into formula grammar, the core engine, API changes, or repository renames. |

For all subsequent slices, retain the same completion evidence: source review,
reader-contract checks, successful render, a manual first-screen reading, and
an Unlazy acceptance ledger.  No source grep or green CI badge alone proves a
reader route is understandable.

## Rehydration and next immediate steps

```sh
cd /private/tmp/drmtmb-structural-reader-20260921
git fetch github
git status --short --branch
/Users/z3437171/Dropbox/Github\ Local/Shinichi/tools/lane_preflight.sh .
/Users/z3437171/Dropbox/Github\ Local/Shinichi/tools/lane_lease.sh --claim \
  codex-drmtmb-structural-reader-20260921 --paths \
  vignettes/structural-dependence.Rmd tools/tests/test_capability_ledger.py
python3 -m unittest tools/tests/test_capability_ledger.py
```

1. Confirm the test fails for the expected missing reader markers, not for an
   unrelated change.
2. Rewrite only the specified structural-dependence prose.
3. Run every acceptance command above and inspect the rendered output.
4. Commit and push the repair to this existing branch; update its draft PR.
5. Ask for a Rose/Pat reader review before proposing a merge.  Do not merge
   automatically while other lanes are active.

Read `AGENTS.md` and
`docs/dev-log/handover/2026-09-21-claude-handover.md`. Run the handover
rehydration steps, reconcile them with the current git state, then continue only
the OWED Next Immediate Steps.
