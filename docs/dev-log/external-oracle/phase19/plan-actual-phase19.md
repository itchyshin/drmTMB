# Phase 19 — plan vs. actual reconciliation

**Author:** Melissa (reconciler). **Date:** 2026-08-15.
**Worktree:** `.worktrees/phase19`, branch `claude/phase19-comparator-workflows`,
head `a9cc3143` (three commits ahead: `7c9e65d5e`, `2e5c78709`, `12416bdbe`,
`8659319cc`, `a9cc31431`, on top of the pre-Phase-19 tree).
**Scope.** Compare `docs/dev-log/external-oracle/phase19/PR2-build-plan.md` (what
the arc said it would do) against the built artifacts
(`vignettes/comparing-with-other-packages.Rmd`,
`tests/testthat/test-comparators-phase19.R`), `git log origin/main..HEAD`, and
the round-by-round audit trail in the same directory. Material deviations only;
I am not re-reviewing the tests (Gauss's `audit-c04-c09.md` already did that;
its unresolved findings are folded in below where they bear on plan-vs-actual).

---

## 1. Summary counts

- **Deviations found:** 7 (4 adaptive, 2 drift, 1 unclear).
- **Adjudicated questions (given to me directly):** 5 — 1 adaptive-and-accurately-recorded,
  1 adaptive-but-incompletely-propagated, 1 adaptive-and-recorded, 1 drift (real,
  found late, not yet closed), 1 unclear (unsubstantiated in this worktree).
- **Most important process fix to promote:** the after-task report's own §11
  finding — *"a verification step whose result is a predicted failure is not
  verification, and it silently expires; re-run the checks at the moment the
  record is written"* — should be generalised past this one phase and put
  where a session reads it *before* writing a report, not after. See §7 below.

---

## 2. The five adjudications

### 2.1 The two scope narrowings — ADAPTIVE, and the record is accurate

Round 4 dropped the two frontier fits (`c02`, `c10`) from the article
(`PR2-build-plan.md:284`, "TAKEN 2026-08-15 (maintainer decision)"). Round 5
dropped the frontier *narrative* as well — no Part 3, no classification prose,
nothing about absent comparators anywhere in the reader-facing document
(`PR2-build-plan.md:306-347`, §2.5, signed at §10.4 item 5a).

Both are recorded in three independent places that agree with each other and
with the artifact:

- The plan itself (§0 decision table, §2.4, §2.5, §10.4 items 5 and 5a) states
  what was dropped, why, what it cost, and that it was a maintainer decision
  taken on 2026-08-15.
- The after-task report's Team Learning section (§11) restates the same two
  decisions in a different register ("drop the two frontier fits… then… cut
  the absence narrative out of the article entirely") without contradicting
  the plan.
- The built artifact matches: `grep -c 'frontier' vignettes/comparing-with-other-packages.Rmd`
  returns 0, and neither `c02`'s `sigma = ~ (1|Subject)` model nor `c10`'s
  `rho12 ~ species` model appears anywhere in the vignette or the test file —
  confirmed independently by `audit-c04-c09.md` §0's grep-and-map exercise.

**Verdict: adaptive.** The narrowing is justified in writing at the point it
happened, by the person with authority to make it (the maintainer, per §10.4's
sign-off convention), and the deliverable matches the decision exactly. This
is not drift dressed as adaptation — there is no daylight between what the
record says was cut and what the artifact actually omits.

**One qualification.** The cost of the second narrowing is itself an absence
claim under construction: §15.10 states "the fact that most of drmTMB's
implemented surface was not compared… is now reachable only by a reader who
follows a pointer." That is honest, but it means the reader-facing article now
carries *zero* signal that a boundary was drawn deliberately — a reader who
never opens `docs/dev-log/external-oracle/phase19/` cannot distinguish "eight
models chosen because they were comparable" from "these are representative."
§1.3's composition disclosure and §6.3's closing paragraph are the two
partial mitigations the plan itself names, and both are present, verified, in
the shipped article (`comparing-with-other-packages.Rmd`, opening and closing
sections). Not a defect in the reconciliation sense — the plan predicted this
exact residue and it is not more or less true than predicted.

### 2.2 Five rounds on one defect class — proportionate escalation, recorded where a session working *inside this arc* will find it; not propagated to the team-wide lesson ledger

The recurring defect — an unqualified "no comparator exists" claim — survived
four repair attempts (`gate3-claims.md`, `gate4-claims.md`, and the earlier
`regate-claims.md`/`adversarial-claims.md` rounds), each of which fixed the
exact wording the prior audit had named and let the class resurface elsewhere
(`PR2-build-plan.md:1179-1181`, quoting `gate3-claims.md` Part D: "a blacklist
cannot close an open class"). Round 5's structural fix — remove the sentence's
*habitat* from the article rather than police its wording — is a genuine
escalation in kind, not degree, and it worked: the after-task report states
the final claims audit over the built article "enumerated all 59 paragraphs,
13 headings and 8 table cells one at a time and found zero A1 violations" and
`grep -i frontier` on the shipped file returns 0, which I re-verified myself.

**Proportionate?** Yes. The alternative — a sixth wording pass — had already
failed four times against the same mechanism (phrase-search substituting for
enumeration). Escalating to a structural change once the pattern was clear
(two consecutive rounds, `gate3-claims.md` and `gate4-claims.md`, naming the
same mechanism) is the correct point to stop negotiating wording.

**Is it recorded where a future contributor will find it?** Partially.
- **Inside this arc, yes, thoroughly.** `PR2-build-plan.md` §2.3–§2.5, §8.5,
  and the round-by-round correction tables in §11 all state the mechanism, the
  failed attempts, and the reasoning for round 5's structural fix.
- **In the after-task report, yes.** §11 "Team Learning" states the general
  lesson plainly: "replace the surface the claim needs, rather than chasing
  its wording — and verify by enumeration, not by grep."
- **In `docs/dev-log/check-log.md`, yes** (append-only, dated, searchable by
  date or by "phase19" but not indexed).
- **In `docs/dev-log/team-improvements.md` — no.** I checked; that file
  (chartered by `AGENTS.md` under "Team Improvement Loop" as the place "when a
  task exposes a better way for the team to work") has no entry from this
  phase. The five-round recurrence and its structural resolution is a
  generalisable methodology lesson — "phrase-search verification of an
  open-ended claim class does not converge; enumerate the closed set of units
  instead" — and it is not in the one document `AGENTS.md` designates for
  exactly this kind of finding.

**Verdict: adaptive escalation, correctly recorded for this arc, but not
propagated to the team-wide ledger `AGENTS.md` names for it.** This is a small
gap, not a drift — nothing was silently dropped, the lesson simply was not
copied to its second home. Worth a one-line follow-up, not a re-open.

### 2.3 `--as-cran` run three times, caught what unit tests and `knitr::knit()` missed — the lesson is recorded, but only after the fact and in a place that requires knowing to look

`docs/dev-log/check-log.md` (2026-08-15 entry, "`--as-cran` caught a
search-path leak the unit tests could not") documents all three runs
faithfully:

1. First run: 8 downstream vignettes failed re-building (`ranef` dispatch
   broke once `glmmTMB` was attached via `library()`).
2. Second run: cleared the 8 downstream vignettes, then failed on the new
   article itself in a cascade from the same root cause (unqualified
   `fixef()`/`Owls` lookups after removing the `library()` call).
3. Third run: 0 errors, 0 warnings, 2 notes — one expected (`New submission`),
   one self-inflicted (`figure/` PNG debris swept in by `git add -A` while
   diagnosing the leak).

The entry states explicitly that the earlier `knitr::knit()` check "reported
OK on a file that `rmarkdown::render()` then failed," and names the general
mechanism: "`R CMD check` re-builds vignettes with `rmarkdown`, so `render()`
is the authoritative local check and `knit()` is not a substitute for it. Both
cascading defects were invisible to `knit()`." It also names the second
occurrence of a related class in this same arc ("This is the second time this
exact class has bitten this arc. The first was `library(lme4)` in the oracle
test file… repaired in PR #1031"), and flags the underlying package fragility
(`ranef.drmTMB` not registered on the `nlme` generic) as a real defect
deliberately not fixed here.

**Verdict: recorded, faithfully and specifically, in `check-log.md`.** This
matches `AGENTS.md` rule 7 ("Every meaningful change should update
`docs/dev-log/check-log.md`"), so it is in the designated place. The
qualification is the same one as §2.2: `check-log.md` is ~94,000 lines and
append-only, so "recorded" here means "recorded and retrievable by date or
grep," not "surfaced to the next session automatically." The generalisable
half of the lesson — unit tests + `knit()` do not catch search-path pollution
from `library()` calls in vignettes, only a real `R CMD check`/`render()` pass
does — is exactly the kind of thing `team-improvements.md` exists for, and it
is not there either.

**One item the git-add-A debris surfaces that the reconciliation should flag
on its own:** the check-log entry names the repo's own standing rule directly
("stage scoped paths and never `git add -A`... not following it cost a NOTE")
— i.e. an existing, already-documented team discipline was violated in this
same arc, in the act of fixing an unrelated defect, and caught by CI rather
than by habit. That is worth noting because it is the second time in this
report (see §2.2) that an `AGENTS.md`-designated mechanism existed and was not
used.

### 2.4 §9/§12/c04–c09 went unaudited for 3–4 rounds; when finally checked this round, real defects surfaced that are still unfixed in the shipped artifact — this is DRIFT, live and unresolved

This is the one place I found something ship on the strength of unaudited
material, with the evidence still visible in the current `HEAD`.

**The unaudited window.** `gate3-claims.md:499`, `gate4-claims.md:366-367`, and
`gate5-claims.md:375-378` each independently confirm, across three consecutive
audit rounds, that §9 (registration), §12 (reproducibility), and the c04–c09
build specifications were out of scope for that round's auditor and remained
unaudited. `gate5-claims.md` states it plainly: "three sections remain
unaudited from the audit side, and that is now three to four rounds deep… I
did not audit them this round either." This is honestly tracked the whole way
— nobody claimed these sections were checked when they weren't — so the
*tracking* is not the drift.

**What happened when they finally were checked, this round:**

1. `audit-registration-repro.md` found §9 (registration) correct on all five
   coupled edits, but §12 (reproducibility) **NOT BUILT**: "no versions,
   platform, seed statement or threading information appeared anywhere a
   re-runner could find it," despite the article quoting comparator-version-
   dependent precisions (`1e-3`, `1.63e-11`). This was fixed in commit
   `a9cc31431` ("record reproducibility metadata and fix a stale count"),
   which added the "Reproducing these numbers" section and corrected a stale
   `37` → `38` count in `docs/design/226-reader-learning-path.md` that the
   automated ledger test does not check. Both repairs are visible in the
   current tree. **This part of the drift is closed.**

2. `audit-c04-c09.md` (Gauss, dated 2026-08-15, **untracked — `git status`
   shows it as `??`, not committed**) numerically re-audited the three build
   specifications that had never been independently re-fitted since round 2
   (c04, c05, c09 — article Comparisons 2, 3, 7) plus c01, c06, c07, c08. It
   returned **NOT-DONE** on three findings, all prose-level, none numerical:

   - **F1** (MEDIUM): the article's Comparison 3 prose says `rma.mv(struct =
     "DIAG")` uses `alternate` "as the reference **on both sides**." Verified
     false — `rma.mv` has no reference level at all; it estimates one free
     variance per level. I confirmed this is still in the shipped vignette:
     `vignettes/comparing-with-other-packages.Rmd:212`, "`alternate` as the
     reference on both sides."
   - **F2** (MEDIUM): the article's Comparison 5 prose says the random-slope
     cell `mc-0227` is recorded "a tier lower" than `mc-0225`. By the repo's
     own `TIER_ORDER` in `tools/capability_ledger.py`, the gap is **two**
     tiers (`interval_feasible` → `diagnostic_only` → `point_fit_recovery`).
     Still in the shipped vignette: `vignettes/comparing-with-other-packages.Rmd:357-358`,
     "a tier lower at `point_fit_recovery`."
   - **F3** (MEDIUM): the Comparison 7 test does not pin the model the section
     is about — swapping both sides to `sigma = ~1`/`dispformula = ~1` (which
     drops the `sex` effect the whole comparison exists to demonstrate) still
     passes 4 of 5 assertions, and the fifth only fails by a factor of 2
     against its threshold. Not yet repaired in `tests/testthat/test-comparators-phase19.R`
     as of `HEAD`.

**Why this is drift, not adaptive.** Nothing was decided or recorded that
these three findings should ship unfixed — they simply had not been found yet,
because the section that would have found them (`audit-c04-c09.md`) is dated
the same day as `HEAD` but is not committed to the branch. The plan's own
build order (§14, step 12) requires the after-task report to record deliberate
exclusions "so neither is later read as an oversight," and the after-task
report does that correctly for the two frontier-narrative narrowings (§2.1
above) — but F1/F2/F3 are not deliberate exclusions, they are unaudited-then-
found defects that landed in a shipped, tested, after-task-reported article
before the audit that would have caught them ran. The after-task report's own
"Known Residuals" (§10) is honest that "`PR2-build-plan.md` §12… and the
c04–c09 build specifications remain unaudited from the audit side" — so the
gap was disclosed, but disclosure of "not yet checked" is not the same as the
defects it predicted not being present. They were present, and F1/F2 are still
in the tree at the time of this reconciliation.

**Severity, stated honestly.** All three are prose/test-quality defects, not
numerical or scientific errors — `audit-c04-c09.md`'s headline finding is that
"all six comparisons reproduce exactly, every scale conversion… is correct."
F1 mischaracterises a comparator's estimation method in the one comparison
whose rhetorical point is "these are the same model," which is a real
credibility risk given how much of this arc's five rounds were spent
protecting exactly that kind of claim from overreach in the *other*
direction. F2 is a one-word factual error against the repo's own enum. F3 is a
test gap, not an article defect.

**Owner:** domain reviewer (Noether for F1's mathematical mischaracterisation
of `rma.mv`; Gauss, who found it, for F2/F3 as test/numeric items). Not Ada
(not a scope question) and not Rose (not a closeout-claims question — the
after-task report did not overclaim here, it disclosed the gap accurately).

**Recommended immediate action, stated for the record, not performed by me:**
commit `audit-c04-c09.md`, apply its three one-line/two-line repairs to the
vignette and test file, and re-run the 41-assertion test file plus a knit
before treating Phase 19 as closeable. This is the one item in this
reconciliation with a concrete, small, unshipped fix still outstanding.

### 2.5 Two PRs touching DESCRIPTION `Suggests` conflicting, one rebased — UNCLEAR, unsubstantiated in this worktree

I searched for this specifically: `git log --all -- DESCRIPTION` shows exactly
one commit in this branch's history adding `metadat` to `Suggests`
(`7c9e65d5e`, the same commit that adds the test file), and no merge or rebase
commit touching `DESCRIPTION` appears in `git log origin/main..HEAD`. `git diff
origin/main..HEAD -- DESCRIPTION` shows a single clean one-line addition. I
also checked `docs/dev-log/check-log.md` and every Phase 19 audit document in
`docs/dev-log/external-oracle/phase19/` for any mention of a `DESCRIPTION`
conflict or a rebase touching `Suggests`; none exists. The after-task report's
§3a explicitly states "a scan of every local and remote ref confirmed no other
branch already adds it, so this is not a duplicate of another lane's fix" —
which is evidence *against* a same-package conflict, checked at the time.

**Verdict: unclear.** I cannot confirm this happened inside the artifacts,
commits, or audit trail available to me in this worktree. It may describe
something in a sibling worktree, a different branch, or a different session
not reachable from here, or it may be a premise I should not assume is true.
I am flagging it rather than either confirming or denying it — if the
orchestrator has visibility into a second branch/PR that this worktree cannot
see, that is the place to check next.

---

## 3. Other material deviations noticed while reading, not on the assigned list

### 3.1 ADAPTIVE — `docs/design/226-reader-learning-path.md` was edited outside this PR's stated scope, but the edit is recorded and the reason is sound

`git diff --stat` shows `docs/design/226-reader-learning-path.md` changed (+18/-?)
even though `PR2-build-plan.md` §9.1 lists only four coupled edits (later
corrected to five, adding this file, in `audit-registration-repro.md` A5). The
after-task report's §4 "Files Touched" explicitly separates it out: "Not
touched: … `docs/design/226-reader-learning-path.md` (repaired separately by
the maintainer)." The `check-log.md` entry for `a9cc31431` independently
confirms a stale `37`→`38` count was found and fixed in this file by the final
audit pass, distinct from the maintainer's earlier repair. Two different
repairs to the same file, by two different actors, both recorded, neither
silently absorbed. **Adaptive** — the plan's own §9.1 was wrong about the edit
count (four, not five) and both the audit trail (`audit-registration-repro.md`
A5) and the after-task report correct this explicitly rather than silently
matching the plan's stale count.

### 3.2 DRIFT (minor, self-corrected within the branch) — the after-task report shipped stale for ~12 minutes and said so itself

Not something I need to adjudicate — the after-task report's own §9 ("What
Did Not Go Smoothly") discloses this without prompting: the report and the
check-log entry were written against a tree where the article did not yet
exist, then the article landed 12 minutes later, leaving three false
statements in a document that was "ready to ship that way." The report was
subsequently rewritten (its own header note says so) to describe the tree as
it actually stands. I list this only because it is a textbook instance of the
exact mechanism the arc's five-round claims-audit history is about —
verification whose result is a *prediction* rather than a *measurement*
silently expiring — surfacing a second time, at a different layer (process
records, not article prose), inside the same phase. It is fully closed and
fully self-disclosed; **no action needed**, but see §7.

---

## 4. What did NOT drift (checked, found consistent)

- The eight-cell surviving set (§1.1 of the plan) matches the article's eight
  comparisons exactly, in the plan's stated order (`c08, c04, c05, c06, c07,
  c01, c09, c03`) — confirmed against both the vignette's chunk order and
  `audit-c04-c09.md`'s independent mapping.
- The `rho12` link correction (`0.999999 * tanh(eta)`, never plain `tanh`) is
  absent from the article (correctly — the article states no `rho12` link at
  all per §2.5) and the plan's own tracking of where that correction still
  matters (doc 158, §10.2 item 5) is consistent with what I can see was or
  was not done to doc 158 in this diff (doc 158 is not in the changed-files
  list, so item 6/7 of §10.2 and the doc-242 proposal of §10.3 remain
  undone — but the plan never claimed otherwise; §15 items 2 and 6 disclose
  this as still open).
- The zero-ledger-row decision (§10.1) is honoured: no `cells.tsv` or
  `evidence.tsv` row was added; the after-task report states this explicitly
  and cites the same rationale as the plan.
- `metadat`'s `Suggests` declaration matches §9.3 exactly, and the after-task
  report's own dependency reasoning (transitive via `metafor`'s `Depends`, but
  worth declaring directly since `metafor` itself carries no version floor in
  `DESCRIPTION`) matches the plan's mitigating-fact framing almost verbatim.

---

## 5. Deviation ledger (compact)

| # | Deviation | Tag | Owner | Status |
| --- | --- | --- | --- | --- |
| 1 | Two frontier fits dropped (round 4) | adaptive | — | closed, recorded accurately |
| 2 | Frontier narrative cut entirely (round 5) | adaptive | — | closed, recorded accurately |
| 3 | Five-round defect-class recurrence, structural fix in round 5 | adaptive | — | closed for this arc; lesson not copied to `team-improvements.md` |
| 4 | `--as-cran` found search-path leak + debris, 3 runs | adaptive-in-hindsight (real bugs, real fixes) | — | closed; lesson recorded in check-log, not in `team-improvements.md` |
| 5 | §9/§12/c04–c09 unaudited 3–4 rounds; §12 gap found and fixed; c04–c09 gaps (F1, F2, F3) found and **not yet fixed** | **drift** | Noether (F1), Gauss (F2, F3) | **open** — `audit-c04-c09.md` uncommitted, fixes not applied |
| 6 | Two-PR DESCRIPTION `Suggests` conflict | unclear | — | unsubstantiated in this worktree |
| 7 | `docs/design/226` edited outside the plan's stated 4-edit scope | adaptive | — | closed, both repairs recorded, plan's own count corrected |
| 8 | After-task report shipped stale for ~12 min, self-corrected | drift (minor, self-healed) | — | closed, fully disclosed by its own author |

---

## 6. Answering the two overarching questions directly

**"Was the eventual structural fix proportionate?"** Yes — four rounds of
symptom-level repair against a recurring class is the right amount of evidence
to require before escalating to removing the class's habitat entirely,
and the escalation demonstrably worked (zero A1 violations on final
enumeration, independently re-checked by Gauss's fresh six-comparison audit
this round).

**"Is the recurrence recorded somewhere a future contributor will actually
find it?"** Inside this arc's own paper trail, yes, redundantly. At the
team level — the `docs/dev-log/team-improvements.md` ledger `AGENTS.md`
designates for exactly this kind of generalisable lesson — no. That is the
one process gap threading through three of the five adjudicated questions
(§2.2, §2.3, and implicitly §2.4's disclosure-vs-outcome gap): the arc is
disciplined about recording decisions *for itself*, and less disciplined
about promoting the generalisable half of what it learned to the place
other phases would look.

---

## 7. The single most important process fix to promote

**Treat "unaudited" as a claim with an expiry, not a permanent hedge.**

Three separate mechanisms in this phase all reduce to the same shape: a
record says "this has not been checked yet" (§9/§12/c04–c09 across three
audit rounds; the after-task report's own predicted-failure statements;
`gate5-claims.md`'s own honest "I did not audit them either"), and that
disclosure is correctly worded and correctly timestamped every time — but
nothing in the workflow forces the *next* thing that touches the same
material to re-ask "is this still true?" before proceeding as if the risk is
merely disclosed rather than closed. The after-task report names half of this
generalisation itself: "a verification step whose result is a *predicted*
failure… is not verification, and it silently expires… re-run the checks at
the moment the record is written." The other half, visible in §2.4 above, is
that an honestly-disclosed *gap* in coverage carries the same expiry — "not
yet audited" quietly becomes "shipped" the moment enough commits pile on top
of it, unless something forces the audit to actually happen before the
material is treated as final. The fix is not another audit round; it is
making "unaudited" a blocking, greppable status on the specific sections it
applies to (the way `gate5-claims.md`'s own item numbering already tracks it)
rather than a prose sentence that a build order can walk past.
