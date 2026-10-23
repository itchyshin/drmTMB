# Gate 1 component ledger and rights review — drmTMB 0.7.0

**Auditor:** Rose (systems auditor) · **Date:** 2026-08-15 · **Worktree:**
`.worktrees/cran-07` (branch `claude/07-cran-ladder`) · **Scope:** close the
`RUNG-REPORT-0.7.0.md:123` bookkeeping gap only. This document does not change
`status_claim`, advance any rung, or edit any file under
`docs/dev-log/release/0.7.0-cran-gate/`.

**Verdict up front:** the "SHIP 4 · EXCLUDE 0 · UNRESOLVED 2" count in
`RUNG-REPORT-0.7.0.md:123` **cannot be mechanically recovered** — no document
anywhere in the repository ever wrote down which four components were "SHIP"
or names the two "UNRESOLVED" items as components. What follows is (a) an
independently rebuilt component ledger with fresh SHIP/EXCLUDE verdicts, (b)
the actual rights review of the one component that was flagged, never done,
and (c) a documentation-quality finding: the "2" being counted are not the
same kind of thing, which is exactly why nobody could resolve the count.

---

## 0. Does the prior recon's mapping hold?

`2026-08-15-gate1-recon-inventory.md` (this worktree) concluded the two unresolved items are
the ledger's `rights_and_consent_is_stale` and `source_clean_evidence_predates_candidate`
gaps. **Independently re-derived — it holds, but with a qualification the
recon did not surface.**

- `docs/dev-log/release-audits/2026-08-11-070-cran-release-ledger.json:97-101`
  contains **five** `known_evidence_gaps` keys, not two:
  `rights_and_consent_is_stale`, `gate1_unresolved_items` (a meta-pointer back
  to the RUNG-REPORT sentence, not itself a gap), `source_clean_evidence_predates_candidate`,
  `platform_evidence_provenance`, `candidate_no_longer_matches_main`.
- `platform_evidence_provenance` is about the **platform-clean** rung (3-OS /
  R-hub same-source-not-same-bytes), not Gate 1. It is correctly excluded from
  the recon's mapping.
- `RUNG-REPORT-0.7.0.md:121-129` ("Gate 1 — rights and product contract")
  **only discusses rights/licensing** in its body text. It never once mentions
  product contract, rendered-site, or NEWS.md staleness. The "product
  contract" half of the Gate-1 heading is undischarged by the section's own
  prose — the only place that half is actually described is the ledger's
  `source_clean_evidence_predates_candidate` gap, which lives outside the
  RUNG-REPORT entirely.
- **Finding:** the "UNRESOLVED 2" bundles a **substantive rights gap**
  (component 6, below — undocumented review, not undocumented borrowing) with
  a **process/evidence-currency gap** (product-contract and rendered-site
  evidence describing an earlier commit than the candidate). These are not
  commensurable — one is "has this code's licence been checked", the other is
  "is this prose still accurate" — yet Gate 1 reports them as a single tally
  of 2. That incommensurability, not just the missing names, is why the count
  could never be resolved by inspection alone.
- `candidate_no_longer_matches_main` (NEWS.md correction, "First CRAN
  release" wording) is a related but temporally later staleness note (dated
  the same day as the ledger, 2026-08-11) and is **not** one of the original
  "UNRESOLVED 2" — it postdates the RUNG-REPORT (written 2026-08-10) and
  describes a *new* divergence. `docs/dev-log/release-audits/2026-08-15-070-refreeze-timing-decision.md:47-50`
  confirms the drift has since grown to 60 shipped files. This is a live,
  worsening third gap that Gate 1's "2" never captured and does not currently
  count.

**Conclusion:** the recon's mapping is a **reasonable and well-supported
reconstruction** for the two items the RUNG-REPORT actually meant, but it is
a reconstruction, not a recovery of a decision anyone recorded. Treat "SHIP 4"
below the same way: rebuilt, not recovered.

---

## 1. Component ledger (built from the tarball + `inst/COPYRIGHTS`, not `.Rbuildignore`)

Ground truth: `docs/dev-log/release/0.7.0-cran-gate/tarball-0.7.0-inventory.txt`
(937 paths, candidate `a75c3c901`, SHA-256 `2176e4b8…cda9`).

| # | Component | Source | Holder | Licence / permission | Transformation | Consumer in drmTMB | Verdict |
|---|---|---|---|---|---|---|---|
| 1 | Mesh/SPDE helper baseline — `R/mesh.R` (+ `R/crs.R` in the *upstream* baseline only; drmTMB does not ship `R/crs.R` — confirmed absent from the tarball inventory) | gllvmTMB PR #886, merged `01a3b1103e1b3fe5fdf5d27826349d5bc6f4f040` | Shinichi Nakagawa (same author, both packages) | GPL-3 — **verified from primary source**, see §2 | Adapted: coordinate validation, lon/lat transform, sparse mesh projection. Explicitly does not adopt multivariate/anisotropy/barrier machinery | `R/mesh.R`, spatial-model formula path | **SHIP** |
| 2 | Normalized mesh GMRF density — TMB `density::SCALE(density::GMRF(Q,true), scale)` construction | gllvmTMB merge `01a3b1103e1b`, `src/gllvmTMB.cpp:1562-1591` (content verified against that exact commit, §2); originating commit `12a93bae77bc7feb74ea8f46d892d795fda5d2e1` | Shinichi Nakagawa | GPL-3 — verified | Reparameterised from precision multiplier `tau` (`1/tau` to `SCALE`) to covariance-scale `s = exp(log_sd)` (`s` to `SCALE`); `s = 1/tau` identity confirmed algebraically in `inst/COPYRIGHTS:46-51` | `src/drmTMB.cpp` mesh/GMRF density term | **SHIP** |
| 3 | Binomial link generalisation — link-dispatch pattern + `drm_log_pnorm()` | gllvmTMB `431e173f7198f74c356ec3099ffa211f1ee85fd0` (2026-08-03), `R/fit-multi.R:441-450`, `src/gllvmTMB.cpp:112-146,2185-2199` | Shinichi Nakagawa | GPL-3 — verified | Dispatch pattern only (not gllvmTMB's numerics) for `link_code`; `drm_log_pnorm()` closely adapted Mills-ratio tail (content verified byte-for-byte against the cited commit, §2); **deliberately excludes** gllvmTMB's `gll_clamp()` probability-scale floor | `src/drm_numeric.h:76-89`, `drm_binom_log_mu()` | **UNRESOLVED — see §3** (documented, never rights-reviewed) |
| 4 | `inst/extdata/julia-capabilities.tsv`, `inst/extdata/julia-gates.tsv` | Self-generated by `tools/write-julia-capability-comparison.R` / `tools/write-julia-gate-registry.R` from `drmTMB:::drm_julia_capability_comparison()` | Shinichi Nakagawa | N/A — no third-party content; internal capability/gate metadata about drmTMB's own Julia bridge | None (direct write) | `vignettes/julia-engine.Rmd`, capability dashboard | **SHIP** |
| 5 | TMB compiled linkage (`LinkingTo: TMB`, `Imports: TMB (>= 1.9.6)`) | CRAN package `TMB` | Kasper Kristensen et al. | GPL-2 — **verified via installed `packageDescription("TMB")$License`** | None (link, not copy) | Every compiled family; the whole estimation engine | **SHIP** — compatibility reasoning in §4 |
| 6 | Logo assets — `man/figures/drmTMB-logo.{png,svg}`, `man/figures/logo.{png,svg}` | Hand-authored SVG (paths named `curveTeal`/`curveOrange`/etc.; system font stack `Arial, Helvetica, sans-serif` only, no embedded/external font file); first committed `69f11f82d` "Scaffold drmTMB package and Gaussian MVPs" | Shinichi Nakagawa (assumed — same author as the rest of the initial scaffold commit; **no explicit authorship statement for the artwork itself**) | Not third-party asset; no external licence implicated | N/A | README badge, pkgdown | **SHIP** — but provenance is asserted from commit context, not documented; see §5 recommendation |
| 7 | `vignettes/function-map-cheatsheet.png` (also shipped at `inst/doc/function-map-cheatsheet.png` post-build) | Committed binary, 1536×1024 RGB; added `86b08b345` "docs: add function map and cheat sheet" (2026-07-21). **Generation method not documented in-repo** — no `data-raw`/script produces it (`data-raw/` contains only `.gitkeep`), and the 1536×1024 dimensions are consistent with (not proof of) an AI image-generation tool rather than an R plot or hand-drawn diagram | Unclear — commit message does not say | Assumed original/no external asset, but **UNVERIFIED** | N/A | `vignettes/function-map-cheatsheet.Rmd:75` via `knitr::include_graphics()` | **SHIP, provenance UNVERIFIED** — see §5 |
| 8 | Vignette inputs (35 `.Rmd` files under `vignettes/`) | Authored in-repo | Shinichi Nakagawa | Package licence (GPL (>= 3)) | Rendered to `inst/doc/*.html` at build | pkgdown site, CRAN vignette build | **SHIP** |
| 9 | Author / copyright-holder consent | `DESCRIPTION:4-7` — single `Authors@R`, `role = c("aut","cre","cph")` | Shinichi Nakagawa | Self | N/A | Package-wide | **SHIP** (trivial — sole author is sole copyright holder; no third-party contributor consent is owed) |
| — | `LICENSE` (674-line verbatim GPL-3 text) | FSF | FSF | GPL-3 (public domain to redistribute verbatim) | None | **Deliberately excluded from tarball** — `.Rbuildignore:^LICENSE$`; correct, because `License: GPL (>= 3)` is a standard string, not `"GPL (>= 3) + file LICENSE"` | **EXCLUDE (correctly)** |

Repo-wide `grep` for `adapted from|ported from|closely adapted|borrowed from` across
`R/`, `src/`, `inst/` outside `inst/COPYRIGHTS` returned **no hits** — no
undocumented borrowing was found beyond what `inst/COPYRIGHTS` already
records. `pkgdown/favicon/*` are real files in the working tree but are
`.Rbuildignore`d (`^pkgdown$`) and confirmed absent from the tarball
inventory — not a shipped component, not scored above.

### Best-supported "SHIP 4 / UNRESOLVED 2" reconstruction

If forced to compress the ledger above to match `RUNG-REPORT-0.7.0.md:123`'s
tally, the most textually supported reading is:

- **SHIP 4** = components **1, 2, 4, 5** (the two 2026-08-02 gllvmTMB
  borrowings, the self-generated `inst/extdata`, and TMB linking) — these are
  exactly what the RUNG-REPORT's own sentence lists: "no undocumented
  borrowing, no consent gap, no undocumented data provenance" plus the
  TMB-linking sentence.
- **UNRESOLVED 2** = component **3** (binomial-link borrowing, rights review
  never done) + the **non-component** product-contract/rendered-site
  freshness gap (§0).

This reconstruction is offered as the best available inference, **not** as
recovery of a decision anyone actually made — no document states it this way,
and components 6-9 were never scored by anyone before this audit.

---

## 2. Independent verification of the citations (primary source: sibling checkout)

A sibling gllvmTMB checkout exists at
`/Users/z3437171/Dropbox/Github Local/gllvmTMB` (current HEAD `114a227e1`,
2026-08-14). Verified directly against it, not asserted:

- `DESCRIPTION:` `License: GPL-3` (exact string, not `GPL (>= 3)`). Confirmed
  again by installed-package metadata is not applicable here since gllvmTMB
  is a local dev checkout, but the `DESCRIPTION` field and the 674-line `LICENSE`
  file (standard FSF GPL-3 text) agree.
- All three cited commits exist in gllvmTMB's history:
  `431e173f7198f74c356ec3099ffa211f1ee85fd0` ("fix(likelihood): AD-safe
  ceiling in gll_log1mexp…", 2026-08-03), `12a93bae77bc7feb74ea8f46d892d795fda5d2e1`
  ("engine: gllvmTMB-native multi-trait TMB template…", 2026-05-10), and
  `01a3b1103e1b3fe5fdf5d27826349d5bc6f4f040`.
- Content at the cited lines matches the `inst/COPYRIGHTS` description:
  - `git show 431e173f…:src/gllvmTMB.cpp` at lines 2185-2199 shows exactly the
    `lid == 0/1/2` logit/probit/cloglog dispatch plus `gll_clamp()` before
    `dbinom()` (the clamp drmTMB explicitly declines to adopt).
  - `git show 431e173f…:src/gllvmTMB.cpp` at lines 108-146 shows `gll_log_pnorm()`
    with the identical Mills-ratio expansion, `cut = -20`, and `CondExp`
    structure that `drm_log_pnorm()` (`src/drm_numeric.h:76-89`) reproduces.
  - `git show 01a3b1103e…:src/gllvmTMB.cpp` at lines 1562-1591 shows the
    `SCALE(GMRF(Q_base), Type(1.0)/tau)` construction cited for component 2.
- **Withdrawn `R/crs.R` finding, confirmed correctly withdrawn (not
  re-raised as a live issue):** `inst/COPYRIGHTS:26` names `R/crs.R` as part
  of the *upstream reviewed baseline* ("the reviewed source baseline is
  `R/mesh.R`, `R/crs.R`, and their focused mesh/UTM tests at that exact
  commit"), i.e. gllvmTMB's own files at commit `01a3b1103e1b`. drmTMB itself
  does **not** ship `R/crs.R` (absent from both the working tree and the
  tarball inventory — only `R/mesh.R` exists in drmTMB). The citation is
  accurate as written; RUNG-REPORT:127-129's rebuttal of the earlier
  "phantom" finding is correct.

---

## 3. Rights review — the 2026-08-09 binomial-link borrowing (Task 2)

**This is a review that had never been done, not an undocumented-borrowing
problem.** `inst/COPYRIGHTS:53-80` names the exact upstream commit, files,
and line ranges, and states what drmTMB does *not* adopt. The gap the ledger
flags (`known_evidence_gaps.rights_and_consent_is_stale`,
`2026-08-11-070-cran-release-ledger.json:97`) is that the cited rights
document — `docs/dev-log/release-audits/2026-08-07-07-rights-skim.md`, dated
2026-08-07 at commit `8df6f2402` — **predates** the 2026-08-09 borrowing by
two days, so no rights document has ever discussed it.

**A second, sharper finding from reading the 2026-08-07 skim itself:** it
does not perform a licence-compatibility *analysis* for any of the three
`inst/COPYRIGHTS` borrowings, including the two from 2026-08-02 that predate
it. It states only that components "are listed in `inst/COPYRIGHTS` with
provenance" and that "ship/exclude decisions... remain as recorded... this
skim does not reopen them" (`2026-08-07-07-rights-skim.md:11-15`). That is a
**documentation-existence check**, not a GPL-3-compatibility review. So the
actual compatibility reasoning below is the first time this question has been
answered for *any* of the three borrowings, not only the newest one — the
ledger's framing ("no rights review has covered it", implying the earlier two
were covered) slightly overstates what happened to components 1 and 2.

### License-compatibility reasoning

1. **drmTMB's own licence:** `DESCRIPTION:25` reads `License: GPL (>= 3)`.
   This licenses drmTMB (and any code incorporated into it) under GPL version
   3 **or any later version**, at the choice of the recipient.
2. **gllvmTMB's licence:** verified `GPL-3` exactly (§2) — not `GPL (>= 3)`,
   so gllvmTMB code may only be used/redistributed under GPL-3 terms
   specifically (not GPL-2, and not silently "any later version").
3. **Compatibility:** combining GPL-3-only code into a GPL(>=3) work is
   standard and compatible — a GPL(>=3) licensee may always choose to
   distribute the combined work under GPL-3 exactly, which satisfies both
   sides simultaneously. There is no version mismatch to reconcile (unlike,
   say, incorporating GPL-2-only code into a GPL-3-only work, which is the
   classic incompatible case). **This is a standard, low-risk combination**,
   not a novel judgement call.
4. **Attribution sufficiency under GPL-3 (informal, not counsel):**
   `inst/COPYRIGHTS:53-80` identifies the source (exact upstream commit
   hash), states the licence (`GPL-3`, explicit), and describes the
   modifications (what was and was not adapted, in enough detail to
   reproduce the distinction). This is line-level, verifiable provenance —
   stronger than most CRAN packages' third-party-code disclosures. **One
   gap:** neither `src/drm_numeric.h` nor `R/mesh.R` carries an in-file
   pointer comment to `inst/COPYRIGHTS` at the adapted function/block itself
   (checked directly — `drm_log_pnorm()` at `src/drm_numeric.h:76-89` and the
   top of `R/mesh.R` have no such note). Centralising provenance in one
   ledger file is an accepted, common R-package pattern (this is how
   `inst/COPYRIGHTS` itself is designed to work, and matches practice
   elsewhere in the TMB-adjacent ecosystem), so this is a **quality
   recommendation, not a compliance blocker.**
5. **TMB-linking precedent (`LinkingTo: TMB`, GPL-2), independently
   verified, not merely re-cited:**
   - `packageDescription("TMB")$License` on this machine returns `GPL-2`
     (confirmed).
   - `packageDescription("glmmTMB")` returns `License: AGPL-3`,
     `LinkingTo: TMB, RcppEigen`, `Repository: CRAN` (confirmed) — glmmTMB
     ships this exact GPL-2-linked-under-a-GPL-3-family-licence combination
     and is live on CRAN today on this machine's installed copy.
   - This is **precedent by inspection**, exactly as RUNG-REPORT:124-125
     frames it — not a formal FOSS-legal compatibility proof (GPL-2-only
     code combined with GPL-3-family code is a genuinely debated area under
     strict FSF compatibility doctrine when it is source-level combination;
     R's compiled `LinkingTo` model and CRAN's own practice do not appear to
     apply that doctrine as strictly, and glmmTMB's acceptance is the
     concrete evidence for that). The correct-confidence framing is
     "practically de-risked by an accepted CRAN precedent doing the identical
     thing", not "provably compliant" — and that is the framing already used
     in RUNG-REPORT. I concur with it and would not strengthen the wording
     further without an actual legal opinion.

### Verdict: rights review — CLEAR, does not block `submission-ready`

The borrowing is documented at the standard `inst/COPYRIGHTS` already
achieves for the other two components; the licence combination is a standard
compatible case (GPL-3-only into GPL(>=3)); and the adjacent TMB-linking
question has independent, machine-verified precedent. **This document
constitutes the rights review that was missing** for
`known_evidence_gaps.rights_and_consent_is_stale`. Recording it as closed in
the frozen ledger or RUNG-REPORT is the orchestrator's/owner's decision, not
this audit's — this document does not edit those files.

---

## 4. What remains before `submission-ready`

Independent of this component ledger and rights review, the following are
**not** touched or resolved by this document (frozen-evidence gaps, restated
for completeness — see the cited files for authority):

1. **Re-freeze required.** `docs/dev-log/release-audits/2026-08-15-070-refreeze-timing-decision.md`
   is Shinichi's explicit 2026-08-15 decision **not** to re-freeze yet — the
   tree is held by two undischarged owner decisions (D-93, D-117), and 60
   shipped files now differ between `main` and the frozen candidate
   `a75c3c901`. A new candidate, once cut, needs a **complete new
   platform-matrix campaign** (3-OS, sanitizers, valgrind, and win-builder —
   win-builder has never run against any exact candidate's bytes).
2. **`8245449f2` (`bootstrap_at_boundary`)** — a user-facing honesty gap on
   an interval route, currently absent from `main`, needs a deliberate
   ship/defer decision before the next freeze
   (`2026-08-15-070-refreeze-timing-decision.md` item 4).
3. **The product-contract / rendered-site freshness gap** (§0) is unrelated
   to code rights and remains open — no rendered-site check has ever covered
   the candidate's exact bytes.
4. **This document itself is new evidence**, not yet incorporated into the
   ledger's `known_evidence_gaps` or the D-43 completion panel
   (`panel.grace/rose/pat` are all `NOT_RUN` in the 2026-08-11 ledger).
5. **Component 6/7 provenance (logo, cheatsheet PNG)** were never previously
   scored anywhere. Neither blocks rights-review closure (no third-party
   asset was found), but their generation method is undocumented — a cheap
   fix (one line in `inst/COPYRIGHTS` or a commit-message note: "self-drawn
   SVG" / "generated via <tool>") would remove the `UNVERIFIED` tag on
   component 7 at negligible cost.

