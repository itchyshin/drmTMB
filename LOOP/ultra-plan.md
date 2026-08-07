# ARC CARD — Really useful 0.7 (user-facing onboarding + honesty)

Created 2026-08-07 by Cursor via `arc-creation` (size mode), after Shinichi
approved a “really useful 0.7” user-facing programme distinct from the CRAN
packaging ladder. Written in worktree
`~/local-scratch/worktrees/drmTMB-07-tarball` (`cursor/07-tarball-clean` @
`f065fc905`). Scratchpad is `.Rbuildignore`d; `scratchpad/*.md` is not
gitignored (only `*.log` / `*.rds`).

**Mode:** size  
**Requested outcome:** not quantified — land the four first-week user-facing
deliverables Shinichi listed (onboarding vignette path; frozen default
uncertainty story; parseable capability surface; Ayumi-scale ergonomics
advice), with optional non-Gaussian REML/AGHQ corner deferred post-submit.  
**Mechanism authority:** reversible docs / pkgdown / README / NEWS / roxygen
edits that **restate existing evidence**; CRAN-safe vignette smoke only if a
new article needs it.  
**Excluded:** platform-clean; CRAN upload; DESCRIPTION `0.7` bump; Totoro /
DRAC campaigns; ledger promotions; AGHQ/Cox-Reid as Arc 0 or a CRAN blocker;
duplicating the packaging lane already at **tarball-clean** (#939 / check-log
2026-08-07).  
**Recommended arc:** **5.5 h** capacity programme (range **4.5–7 h**; Arc 0 =
40 min)  
**Time contract:** ceiling ~6 h for the four landed deliverables; later AGHQ
rung is optional and separately stoppable  
**Estimate confidence:** **inferred** — prior pkgdown/vignette honesty arcs
and the existing `model-workflow` / `capability-and-limits` / `?confint`
Boundary section are direct reuse surfaces; no measured end-to-end timing for
this exact programme.  
**Arc 0 outcome:** written gap map that cites what already exists and decides
**thin new vignette vs tighten + link** for the onboarding path (no blank-page
rebuild).  
**State transition:** packaging at **tarball-clean**; first-week
onboarding / default-uncertainty / parseable capability matrix incomplete →
those four doc/API-honesty deliverables landed and linked from README +
pkgdown Getting Started; AGHQ deferred unless a trivial doc-only pointer.  
**Executable rung and evidence:** prose + vignette + pkgdown/_pkgdown.yml +
README links; optional `R CMD check` vignette smoke / focused test only if a
new vignette is added. No campaign receipts. No public tier promotion without
citing an existing ledger cell.

---

## Why this arc (and why not packaging / AGHQ)

Highest proven CRAN rung is already **tarball-clean** on main (#939). Another
agent may own **platform-clean**; this card must not duplicate that or upload.
Shinichi’s approved “really useful 0.7” list is **user-week usefulness**: can a
new ecology/evolution user fit → inventory targets → profile an RE-SD → read
`profile.boundary` → know when not to trust the interval, and find a
family × dpar × RE × interval-tier surface without reading the ledger TSV.
AGHQ / non-Gaussian REML is a **science corner**, not a first-week doc gap —
keep it post-submit or as a final optional rung after the four deliverables.

## State-transition gate

| Step | Content |
| --- | --- |
| 1. Current | Packaging **tarball-clean**; `?confint` has **Boundary intervals**; NEWS has profile-boundary + Prong B honesty; `model-workflow` already walks `profile_targets()` / `confint` / `conf.status`; `capability-and-limits` defines tiers; generated `docs/dev-log/dashboard/capability-surface.md` exists but is **not** a first-week pkgdown article; `se_group_sd` is documented in `?drm_control` / NEWS but **absent** from `large-data.Rmd` learning-path advice; DESCRIPTION still **0.6.0**. |
| 2. Intended | Four deliverables landed + linked from README/pkgdown Getting Started; default uncertainty story frozen in NEWS + `?confint` without claiming nominal coverage everywhere; Ayumi-scale default advice visible; AGHQ deferred. |
| 3. Intervention | Gap-aware vignette (or short article) + roxygen/NEWS freeze + README/pkgdown parseable capability surface + `large-data` / phylo ergonomics paragraphs. |
| 4. Approval | Shinichi already approved this list. **Do not** bump version, upload, or promote ledger cells. Capability-surface edits must **cite existing tiers** (reversible docs) and not invent new public claims. |

## Prior-work sweep (do not rebuild)

| Surface | What already exists | Gap for this arc |
| --- | --- | --- |
| `man/confint.drmTMB.Rd` §Boundary intervals | Full D-117 story: profile warns with `drmTMB_profile_boundary_warning`; coverage 0.0732 / 0.2540 / 0.8566; lme4 comparator; “not a repair for a boundary” | Needs a short **default uncertainty recipe** (profile RE-SD; Wald FE; boundary warn; no nominal-coverage-everywhere) near the top of Details / a dedicated subsection, not only deep in Boundary |
| `NEWS.md` (top) | Profile boundary warning + Prong B “computable ≠ coverage” | Freeze an explicit **default uncertainty story** bullet block for 0.7 readers (may live under unreleased / 0.7 draft notes without bumping DESCRIPTION) |
| `vignettes/model-workflow.Rmd` | Long “Checking and using fitted models”: `profile_targets()`, Wald/`profile`/`bootstrap`, `conf.status` table, mentions `profile.boundary` | Too long for first week; D-117 “when not to trust” is thin vs `?confint`; needs a **short onboarding spine** (new vignette *or* a front-loaded section + Getting Started link) |
| `vignettes/drmTMB.Rmd` | Learning-path table → model-workflow / capability-and-limits / large-data | No single row for “fit → profile RE-SD → read boundary” |
| `vignettes/capability-and-limits.Rmd` | Tier definitions + “at a glance” tables; points at `capability-census/` | Not a parseable **family × dpar × RE × interval tier** matrix for README/pkgdown skim |
| `docs/dev-log/dashboard/capability-surface.md` (+ `.html`) | Generated snapshot (699 model cells; 187 IF / 55 recovery / 29 IR as of 2026-08-05) | Dev-log only; not in `_pkgdown.yml` articles; first-week users never see it |
| `_pkgdown.yml` articles | Getting Started = `drmTMB`, `function-map-cheatsheet`; Capability = `capability-and-limits`, …; Workflow = `model-workflow`, `large-data`, … | Slot for onboarding uncertainty article missing; no compact matrix article |
| `vignettes/large-data.Rmd` | Memory-light `drm_control()`, `se = FALSE`, large-phylo Wald-first advice | **`se_group_sd` never named**; Ayumi 10,440-tip path not default advice |
| `man/drm_control.Rd` / NEWS ~L794 | `se_group_sd = FALSE` default; n_group×n_group ADREPORT / REML GB warning | Need vignette + learning-path pointer so users find it without reading Rd |
| Packaging | check-log: tarball-clean freeze; STOP before platform-clean/upload | Out of scope here |

## Capacity ladder

| Order | Budget | Outcome | Trigger / definition of done |
| --- | ---: | --- | --- |
| Arc 0 | 40 min | Gap map + decision: **new short vignette** vs **tighten model-workflow + drmTMB learning-path** (prefer reuse; new article only if a ≤~150-line spine is cleaner) | Start now. Cite the prior-work table above. |
| Rung 1 | 70 min | **Default uncertainty story frozen** in NEWS + `?confint` (profile for RE-SD / variance components; Wald for FE routine; read `profile.boundary`; no nominal-coverage-everywhere). Docs-only; no claim expansion. | After Arc 0. Reversible prose. |
| Rung 2 | 100 min | **Onboarding path landed**: fit → `profile_targets()` → `confint(method="profile")` → read `profile.boundary` → when not to trust; linked from `_pkgdown.yml` Getting Started + `drmTMB.Rmd` learning path. Prefer CRAN-safe tiny example (no long phylo). | After Rung 1 so vignette can cite the frozen story. |
| Rung 3 | 80 min | **Parseable capability surface** for users: compact family × dpar × RE × interval tier (fit / `interval_feasible` / `inference_ready`) on README and/or a pkgdown-facing page that **summarises** existing `capability-and-limits` + ledger snapshot — no new promotions. | After Arc 0 decision on where the matrix lives. |
| Rung 4 | 50 min | **Ayumi-scale ergonomics**: `large-data.Rmd` (+ learning-path row) default advice for big tip counts — keep `se_group_sd = FALSE`; when to set `TRUE`; point at `?drm_control`. | Independent of Rung 2 once Arc 0 confirms gap. |
| Integrate/close | 30 min | Links consistent; after-task or check-log note; Actuals; HAND TO next (platform-clean owner / AGHQ post-submit). | Always reserve. |
| *(optional later)* | — | One non-Gaussian REML/AGHQ supported corner (binomial or cumlogit) | **Post-submit / separate arc** — not Arc 0; not a CRAN blocker. |
| **Total** | **370 min (~6.2 h)** | Shortest credible programme that lands all four; trim to ~5.5 h if Arc 0 chooses reuse-only (no new vignette file). | |

**Reversible docs vs public claims:** Rungs 1–2 and 4 are reversible documentation if they only restate measured behaviour. Rung 3 is reversible **only while it cites existing ledger tiers**; inventing “supported” / expanding domains is a public-claim change and is **out of scope**.

## Budget — Arc 0

| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient | 15 | Re-read `?confint` Boundary, `model-workflow` confint section, `capability-and-limits` tiers, `large-data` memory section, `_pkgdown.yml` Getting Started |
| Core | 15 | Write gap map (files + 1-sentence gap each) + decide vignette strategy |
| Verify | 5 | Confirm platform-clean / upload still foreign; DESCRIPTION stays 0.6.0 |
| Repair reserve | 0 | External packaging wait is not this arc |
| Closeout | 5 | Record decision on this card; start Rung 1 or Rung 4 if Rung 1 blocked |
| **Total** | **40** | |

**In scope:** onboarding uncertainty path; NEWS/`?confint` default story; parseable capability surface linked for users; Ayumi `se_group_sd` advice.  
**Not in this arc:** platform-clean; CRAN upload; DESCRIPTION version bump; Totoro; ledger promotions; AGHQ/Cox-Reid implementation; rebuilding `capability-and-limits` from scratch; touching the dirty primary checkout.  
**Evidence used:** `man/confint.drmTMB.Rd` §Boundary intervals; NEWS profile-boundary + Prong B entries; `vignettes/model-workflow.Rmd` (`profile_targets` / `conf.status`); `vignettes/capability-and-limits.Rmd`; `docs/dev-log/dashboard/capability-surface.md` (2026-08-05 snapshot); `man/drm_control.Rd` `se_group_sd`; absence of `se_group_sd` in `vignettes/large-data.Rmd`; `_pkgdown.yml` articles; check-log tarball-clean freeze; prior Arc Card `scratchpad/2026-08-05-arc-07-cran-release-readiness.md` (packaging — complementary, not overlapping).  
**Risk branch:** If Arc 0 finds the onboarding path is already first-week complete in `model-workflow` after a short front-load, **do not** add a new vignette — spend the Rung 2 budget on linking + Boundary cross-refs + capability matrix instead. If Rung 3 tempts a ledger regeneration or tier rewrite, **stop** and ship a skim table that cites existing statuses only. If another agent’s platform-clean PR conflicts on README/`_pkgdown.yml`, rebase in a useful-07 worktree off `origin/main` — never dirty primary.

**Done when:** (size-mode programme) (1) onboarding path exists and is linked from Getting Started; (2) NEWS + `?confint` state the default uncertainty story without nominal-coverage-everywhere; (3) users can parse family × dpar × RE × interval tier from README/pkgdown without opening the ledger TSV; (4) Ayumi-scale `se_group_sd` advice is in `large-data` (or equivalent user surface); AGHQ remains deferred; no version bump / upload / campaign.  
**First action:**

```text
In ~/local-scratch/worktrees/drmTMB-07-tarball (or a fresh useful-07 worktree
off origin/main): open man/confint.drmTMB.Rd §Boundary intervals,
vignettes/model-workflow.Rmd (confint / profile_targets),
vignettes/capability-and-limits.Rmd (tier defs), vignettes/large-data.Rmd,
and _pkgdown.yml Getting Started — then record Arc 0 decision on this card:
new short vignette vs reuse+link only.
```

### Actuals (complete at close)
**Recommended / actual:** 370 / _ · **Requested / used:** N/A / _ · **Rungs completed:** _  
**Under-run event:** _  
**Calibration:** _  
**Metric movement:** first-week user surfaces incomplete → _ (four deliverables: _) · AGHQ: deferred  
**Result:** _ · **Next arc:** platform-clean (other owner) **or** post-submit AGHQ corner (binomial / cumlogit) as a separate science arc

---

HAND TO ULTRA PLAN: 5.5h drmTMB “really useful 0.7” user-facing programme —
Arc 0 = 40 min gap map (reuse vs thin new vignette); then freeze default
uncertainty story in NEWS+?confint; land fit→profile_targets→confint(profile)→
profile.boundary onboarding linked from Getting Started; ship parseable
family×dpar×RE×tier surface from existing ledger (no promotions); add
Ayumi-scale se_group_sd advice to large-data; no platform-clean, no upload,
no DESCRIPTION 0.7 bump, no Totoro, AGHQ deferred post-submit; work from
clean worktree off origin/main / tarball worktree, never dirty primary.
