# Handover (2026-07-19): Reader documentation arc — D1 DONE (PR #799 draft), D2 not started

You are picking up the **drmTMB reader-documentation arc (Arc D)** from a Claude session. This
doc stands alone. Read `AGENTS.md`, then this, then
[docs/design/226-reader-learning-path.md](../../design/226-reader-learning-path.md).

**This lane is documentation only.** It never touches `R/`, `src/`, `tests/`, the capability
ledger, or generated capability surfaces.

---

## Lane safety — read before touching anything

Codex owns the **Arc 4c** three-family mu-slope coverage campaign. Its worktrees are
`drmTMB-wt-arc4c-infra` and `drmTMB-wt-arc4c-repair`, and the **dirty repo root belongs to Codex
and Shinichi** — 56 uncommitted files. This arc never ran a git write in the root and never
modified a fenced path.

**FENCED — do not modify:** `R/**`, `src/**`, `tests/**`, `docs/dev-log/dashboard/**`,
`tools/capability_ledger.py`, `vignettes/capability-and-limits.Rmd`, `vignettes/includes/**`,
`AGENTS.md`, `NEWS.md`, `DESCRIPTION`, package version/release state.

Worktrees created by this arc:

| Worktree | Branch | State |
|---|---|---|
| `../drmTMB-wt-d1` | `claude/docs-reader-path-31` | **PR #799, draft, pushed** |
| `../drmTMB-wt-d2` | `claude/docs-figure-gallery-58` | **untouched, at `origin/main`** |

---

## D1 — DONE, draft PR #799

Documentation only: no functionality change, **no new pkgdown pages** (33 vignettes before and
after), **zero changed lines inside any R chunk** (the example set is frozen because D2's figures
depend on those exact fits).

| | before | after |
|---|---|---|
| navbar vs articles-index disagreements | 26 / 33 | **0 / 33** |
| zero-inbound vignettes | 9 | **0** |
| fully-disconnected vignettes | 8 | **0** |
| internal cross-links | 50 | **94** |

Gates, all run locally and read (never asserted from an exit code):

- `devtools::test()` → **FAIL 0, ERROR 0, PASS 39466** (62 warn, 24 skip — pre-existing)
- `pkgdown::check_pkgdown()` → **No problems found**
- **33/33 articles render**
- broken internal link targets **0**; `git diff --check` clean; fence intact

Seven commits, rebased onto `origin/main` at `46affaee`.

### What D1 deliberately did NOT do — recorded in 226 §9

- **`model-workflow` split.** It is ~1,000 lines and turns partway through into random-effect
  material the reader has not met. It got an internal signpost; splitting articles is a non-goal.
- **Organism unification.** The spine uses plants in `drmTMB`/`location-scale` and fish in
  `which-scale`/`model-workflow`. Unifying means renaming variables inside fitted chunks, which
  changes the figures D2 depends on. §9.5 records Darwin's recommended target set if taken later.
- **Heritability in `animal-models`.** Never computed, though it is the point of an animal model
  for an evolutionary biologist. A statistical-output change needing its own evidence — §9.6.
- **`distribution-families` leads with implementation status**, not biology, at the moment the
  reader is choosing a family — §9.6.

---

## THE ENVIRONMENT TRAP — read this before rendering anything

A `relmat-known-matrices` render failure during this session looked like a pre-existing bug on
`main`. **It was not a bug.** The installed drmTMB binary was built **2026-07-12**; commit
`1f563a17` (2026-07-15, on `origin/main`) shipped the relmat q2 REML gate, the vignette prose, and
the backing evidence *together*. The abort string does not exist in the source tree at all.

Fix: `R CMD INSTALL .` — done this session; the library is now built 2026-07-19.

**Why it fooled a control experiment:** both worktrees resolve `library(drmTMB)` to the same
shared user library, so a clean same-commit control does **not** control for a stale installed
package. `pkgdown::build_site()` loads the installed package, not the worktree.

**Guard for next time:** before calling any vignette/gate contradiction "pre-existing on main",
assert the loaded namespace matches the worktree — probe for a HEAD-only internal, or render with
`pkgload::load_all()`. The tell here was traceback line numbers that did not match HEAD.

Had this been "just fixed" by setting `REML = FALSE`, it would have deleted a real capability
backed by a 605-line oracle test and a 2,400-fit Totoro campaign (ledger cells `mc-0201`,
`mc-0674`, tranche `arc1b-s2r`), and desynchronised the vignette from the ledger.

A background task chip was spawned describing this as a bug **before** the diagnosis. It is a
FALSE PREMISE and could not be withdrawn because it had already been started — **close it.**

---

## D2 — NOT STARTED. Its scope changed materially at review.

Branch and worktree exist at `origin/main`, untouched. **Rebase onto D1 before starting** — D2
consumes D1's sequence and vocabulary.

**The gallery is NOT a stub and must not be rebuilt.** `vignettes/figure-gallery.Rmd` is 2,304
lines, 11 sections, 20 plotting chunks producing 21 PNGs, every chunk already setting both
`fig.cap` and `fig.alt`, with interpretation prose throughout.

**The real gap, found by Florence and verified directly:** the gallery demonstrates exactly
**one of six** public plotting functions.

| function | occurrences in gallery |
|---|---|
| `plot_parameter_surface` | 8 |
| `plot_corpairs` | **0** |
| `worm_plot` | **0** |
| `qq_plot` | **0** |
| `centile_chart` | **0** |
| `plot.profile.drmTMB` | **0** |

The three diagnostics plotters live only in `distributional-outputs-and-adequacy.Rmd`. So D2's
centre of gravity is **coverage, not reordering** — bring the five unused functions into the
reader path. This is lower-risk and more valuable than reordering a mature file.

Binding decisions already made for D2:

1. **Do NOT add a seventh plotting helper.** Compose the six that exist. No `autoplot` anywhere;
   ggplot2 is Suggests-only; patchwork is not a dependency — use facets or sequential ggplots.
2. **Do NOT restructure the gallery.** Cross-link plus minimal reorder only. Sections reuse
   objects computed earlier (`fit_growth`, `pair_table`, `sim_summary`) and dev-log notes cite
   chunks by name, so physical reordering risks breaking both.
3. **Rename the misleading section header.** `figure-gallery.Rmd:1666` reads "Fitted correlation
   summaries" while `pair_table` is hand-typed. Caption-level labelling is not enough — the header
   is the first claim a skimmer reads.
4. **Label the two fixture sections loudly** in caption, alt text, and adjacent prose:
   `correlation-display` and `simulation-operating-characteristics` use fabricated numbers.
   Approved decision is to label, **not** to replace with real fits.
5. **Alt-text scope**: gallery + the D1 spine articles only. 16 of 33 vignettes set neither
   `fig.cap` nor `fig.alt`; the rest is a named follow-up, not this arc.
6. **Render and inspect every PNG one by one** — `figure-visual-audit` hard gate; a contact sheet
   is navigation, not evidence. Budget ~90 min over two passes for ~31 images, not 45 min.
7. Tag "structured effects" coverage as **fixture-only**, not resolved, given the deferred split.
8. Re-check the documented `simulation-operating-characteristics` axis-label bug
   (`docs/dev-log/2026-06-12-drmtmb-full-audit-handoff.md:51`) rather than assuming it fixed.

Figure evidence goes to a **new** directory,
`docs/dev-log/figure-audits/2026-07-19-reader-arc-d2/` — cannot collide with any other lane.

---

## Merge order

1. **Arc 4c merges first.**
2. Rebase `claude/docs-reader-path-31` onto the resulting `origin/main`; re-run the gates; take
   PR #799 out of draft.
3. Rebase `claude/docs-figure-gallery-58` onto D1; build D2; open as draft.

Never overwrite Arc 4c's handover pointer. This arc wrote its own dated handover and left
`AGENTS.md` untouched.

---

## Routing lessons for the next session

- **Haiku was the wrong tier for the taxonomy reconciliation.** It reported **0** disagreements
  where there were **26**. Structured cross-comparison is not grepping. It was redone
  deterministically in Python — more accurate *and* cheaper than any model tier.
- **Several subagents had no shell access** and reported verification they could not have run
  (`git diff --stat`, `Rscript`). Every such claim was re-checked by the orchestrator. When
  dispatching a slice whose output contract includes running commands, confirm the agent type has
  Bash.
- **A wrapper exit code is not the gate.** The first full site build reported exit 0 while the log
  said `Execution halted`. Read the log, not the status.
- **The adversarial workflow paid for itself.** Nine agents refused the false dichotomy in the
  brief and found the environment defect instead of "fixing" a non-bug.

## Resume command

```
Rehydrate from docs/dev-log/handover/2026-07-19-claude-reader-docs-arc-handover.md plus
docs/design/226-reader-learning-path.md, then start D2 in ../drmTMB-wt-d2: rebase onto
claude/docs-reader-path-31 and bring the five unused public plotting functions into the reader
path. Do not add a seventh helper, do not restructure the gallery, and render + inspect every
PNG one by one.
```
