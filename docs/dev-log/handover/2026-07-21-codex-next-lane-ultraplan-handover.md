# Active plan: next `drmTMB` lane — execution ultra-plan

## 🎯 GOAL — paste verbatim into the fresh lane

```text
PLATFORM: Codex, solo (the active session). No other drmTMB implementation lane
may run concurrently.
WORKSPACE: a clean isolated worktree or fresh standalone clone of current
origin/main outside Dropbox; never edit the stale, dirty Dropbox checkout or
use a worktree whose .git metadata lives there.
DELIVERABLE: execute and close Track A of the approved 0.6 development arc
(first-impression API and reader-path repairs), then complete only Track B's
B0–B3 specification and review steps in this lane.
HEADLINE: make `(1 + x || group)` a safe first-class spelling for the existing
independent intercept-plus-numeric-slope route, without widening the capability
claim.
IN PARALLEL: Track-A recon, missing-data claim surfacing, and `coef()` Rd
example only after a clean branch and file-ownership map exist. Track B is
specification only through B3; Track C stays bounded by vignette time and
installed-payload gates.
DEFER: CRAN submission, platform matrix, tarball re-freeze, Julia cross-family
work (#806), capability promotion without new evidence, and every simulation
campaign until its preregistration is reviewed and Shinichi approves compute.
DISCIPLINE: use the API in a toy fit rather than infer capability from grep;
claim ceiling is the release-scope manifest and live ledger; run mechanical
verification after each batch; write after-task and handover before closing.
```

## Source of truth and landing state

1. The technical plan of record is
   `docs/dev-log/2026-07-21-0.6-dev-arc-ultra-plan.md` at `origin/main`.
   Reuse its locked decisions and fences; do not replace its capability design.
2. Remote planning base: `origin/main` = `83d48549e8925a97aa2c156941a97a9bf9b785c4`
   (`docs: use Confidence Eyes for phylogenetic SDs (#815)`). Re-fetch before
   branching; the SHA is a planning receipt, not a promise that main will stay
   still.
3. Sweep evidence recorded the visible Dropbox checkout as
   `claude/handover-freshness-0718`, dirty and 80 commits behind at planning
   time. It is evidence only, never a start point. The A-1 preflight must
   re-read this state and re-land **only** the three stranded files named in
   the plan of record. `DRM.jl` is dirty/ahead and out of this lane.
4. The reader-surface audit branch is a completed documentation lane. Its
   repaired bivariate `rho12` wording must be checked against the current
   manifest before the first claim-bearing edit; a contradiction is a public
   claim trigger, not a casual prose cleanup.

## Phase 0.25 sweep receipt

| Surface | Evidence | Finding | Call |
| --- | --- | --- | --- |
| Git state | `git status -sb`, `git worktree list`, `branch_drift_check.sh` on the Dropbox root | root is dirty and 80 commits behind; dedicated clean audit worktree exists | fresh standalone clone from `origin/main` |
| Current remote | `git fetch origin --prune`; `git log -1 origin/main`; latest handovers listed under `origin/main:docs/dev-log/handover/` | remote tip is `83d48549`; the 0.6-dev plan and its Claude handover are current; the pre-CRAN Codex handover is superseded for this lane | rebase/re-cut before any authoring |
| Existing plan | `origin/main:docs/dev-log/2026-07-21-0.6-dev-arc-ultra-plan.md` | Track A is immediately executable; Track B has B3 compute approval gate | reuse, do not redesign |
| Sister repo | `git -C DRM.jl status -sb; git -C DRM.jl log -1` | separate dirty/ahead Julia work; current drmTMB plan fences Julia/#806 | no cross-repo edit |
| Brain | `search_notes "drmTMB next lane after pkgdown reader audit D2 plotting release truth freeze Phase 20 handover"`; `read_note drmTMB_final` | older CRAN-submission plan is superseded by the 2026-07-21 decision to park submission | follow 0.6 development arc, not CRAN path |
| Verdict | all five receipts above | genuine gap is implementation of approved Track A, then Track-B B0–B3 specification/review only | **resume Track A, then B0–B3 only** |

## Execution order and routing

| Slice | Owner | Model / effort | Dispatch | Output / verification | Dependency |
| --- | --- | --- | --- | --- | --- |
| A-1 clean-room preflight | Grace | Luna low | tiered CLI enforced | clone receipt, SHA, clean status; re-add exactly the three stranded files from the plan of record and prove no duplicate diff | none |
| A0 parser/claim recon | Ebbinghaus + Boole | Luna low | tiered CLI enforced | concise map of `||` parse path, Phase-jargon strings, and missing-data ledger rows | A-1 |
| A1 `||` desugaring | Gauss + Boole | Terra high | native explicit | ordinary unlabelled numeric-slope sugar only; update `docs/design/01-formula-grammar.md`; test equality with explicit two-term form, two independent blocks/no correlation, and stable `ranef()`/`coef()`/`confint()`/profile keys | A0 |
| A2 error polish / grouping guard | Boole + Pat | Terra medium | native explicit | factor-slope `||` errors say factor slopes are unsupported; labelled/structured/multi-slope errors name the supported explicit equivalent where one exists; clean `s(x)`; regression test fails without simple-grouping guard | A1 |
| A3 missing-data surfacing | Rose + documentation writer | Terra medium | native explicit | generated include path, claim source, and focused rendered article check | A0 |
| A4 `coef()` Rd example | documentation writer | Terra low | native explicit | roxygen/Rd example; return type unchanged | A0 |
| A5 mechanical verification | Grace | Luna low | tiered CLI enforced | ledger test, `capability_ledger.py --check`, runtime check, fresh syntax sweep | A1–A4 |

Luna suitability is **yes**: A-1/A0/A5 are bounded, read-only or mechanical.
Use the ultra-plan tiered dispatcher with `--require-scout`; all Terra rows
are implementation or coupled-claim work. No Sol slice is scheduled in Track
A. A D-43 panel is not needed unless a public capability milestone is proposed.

## Gates and handover orders

1. **Start:** use a clean isolated worktree or create a fresh clone outside
   Dropbox, fetch, verify `origin/main`,
   read `AGENTS.md`, this handover, the 0.6-dev plan, the release-scope manifest,
   and `docs/dev-log/handover/2026-07-21-0.6-dev-arc-claude-handover.md`. Do not
   use the superseded pre-CRAN Codex handover or carry changes from the stale root.
2. **Track A:** execute A-1 through A5 in the table. A1/A2 serialize because
   they share parser regions; A3/A4 may run after A0 in parallel.
3. **Claim gate:** `meta_V()` and `rho12` wording must match the manifest,
   ledger, code, and rendered page. Any disagreement is a Rose/Fisher review
   trigger; do not decide a public boundary by local wording alone.
4. **Track B:** after Track A closes, perform B0–B3 plan/spec work only in this
   lane. At B3 stop and request Shinichi's explicit compute approval. No
   Track-B smoke, Totoro, DRAC, Actions campaign, ledger promotion, or claim
   expansion occurs before it. A1's CRAN-safe toy `||` fit is required and is
   not Track-B compute.
5. **Track C:** only adopt a reader-depth change in a later lane if its
   per-vignette render time and installed-payload impact are recorded and it
   does not collide with A3/B7 claim surfaces.
6. **Closure:** run focused tests plus the plan's pre-push validators; retitle
   the no-longer-pre-CRAN worklist, mark rungs 2–5 PARKED with reason/date,
   refresh Mission Control to say 0.6 is not being submitted, and write
   after-task and plan-vs-actual reconciliation. Commit/push
   only with the fresh lane's normal review authority; do not merge or submit
   to CRAN without a separate maintainer decision.

## Stop conditions

- A correctness defect or false shipped claim: stop only the dependent slice,
  preserve evidence, and ask Shinichi for the public/design choice.
- Any capability promotion, new API beyond the locked `||` desugaring, or
  compute campaign: new approval gate.
- CRAN/platform/re-freeze work: parked by the 2026-07-21 decision.

## Resume command

```text
Rehydrate from docs/dev-log/handover/2026-07-21-codex-next-lane-ultraplan-handover.md,
docs/dev-log/2026-07-21-0.6-dev-arc-ultra-plan.md, the release-scope manifest,
and AGENTS.md. Work only in the clean active Codex lane. Execute Track A, then
B0–B3 specification/review only; do not start Track-B compute or any CRAN gate.
Preserve the exact claim ceiling and use the tiered dispatcher for Luna
recon/verification.
```
