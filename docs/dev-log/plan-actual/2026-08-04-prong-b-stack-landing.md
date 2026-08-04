# Plan vs actual — landing the Prong B stack (#915-#918) and setting the CI ceiling

Reconciler: Melissa · Sonnet 5 · 2026-08-04.

**Plan:** given to me as text by the orchestrating session, in the standard ultra-plan header
form (GOAL/PLATFORM/DELIVERABLE/IN PARALLEL/DEFER/DISCIPLINE) with a 10-slice table (S1-S10),
a FAN-OUT BUDGET (`<=6` children, ceiling `0`), and a D-43 note (not fired). I searched
`~/.claude/plans/` for a saved file matching this arc by every distinctive term I could pull
from the task (`prong-b-tier1`, `mc0653`/`mc-0653`, `citation-durability`, `collateral-unlock`)
and found only two hits, neither of which is this arc's own plan: `snug-sleeping-river.md`
("Ultra-Plan — Prong B Tier 1," the *prior* arc that authored the branches, already reconciled
in `docs/dev-log/plan-actual/2026-08-03-prong-b-tier1.md`) and `proud-noodling-dragonfly.md`
(2026-08-04, local mtime 08:24 — this **is** the mid-arc D-117 side-plan Deviation C describes;
see Axis 1, S-2). So this arc's own plan text is taken as given by the orchestrator, not
cross-checked against a saved file, **except** where a landed repo artifact independently pins
a plan detail (found for the "three completed runs" bar; not found for "75-90").
**Actual:** worktree `~/local-scratch/worktrees/drmTMB-verify-tip`, detached HEAD at
`origin/main = 5a9662110` exactly (`git rev-parse HEAD` = `5a9662110b36e6b9f15eec9c3cdf77a5b68c3156`),
clean working tree (`git status`).

## Verdict

The stack landed exactly as the plan specified — `25768833b` -> `12e94657f` (#915) ->
`c976e7316` (#916) -> `71ce9e544` (#917) -> `5a9662110` (#918), in order, nothing promoted,
census 182/60 unchanged throughout (recomputed directly from `_master.tsv` column 10, not
trusted from prose) — and every number I could independently regenerate did: the six CI job
durations reproduce to the *second* against the GitHub Actions API's own `started_at`/
`completed_at` fields (not just against the after-task report's retelling of them), the ceiling
value is `75` exactly in the live workflow file, `capability_ledger.py --check` plus all six
`tools/tests/*.py` pass at the tip when I re-ran them myself, and the `_master.tsv` diff across
the whole arc touches citation text only, never `status`/`evidence_tier`. The DEFER fence held
at the code level, not just in prose: `R/methods.R` (where `predict.drmTMB` lives) is untouched,
`mc-0282` and `SOURCE_COMMIT` have zero code touches, and the CI job-split "did" only a
135-line recommendation note plus the single `timeout-minutes: 45 -> 75` line. Two real findings
came out of independent digging rather than confirmation of the given narrative: first, the
merge-commit trailers show all of this arc's *own* new work (`d1314dfef`, PR #918) was done
under one model identity ("Claude Fable 5") in one commit that bundles what the plan called
three separate slices (S7 tighten-timeout, S8 mechanical-verify, S9 consolidate) — the
self-reported Deviation D names only S8/S9 as inline, but the evidence says S7 rode along too,
undisclosed. Second, S2 (stack-tip re-verify) and S3 (R1 gate) have no dispatched-child artifact
or byline anywhere in the landed diff, exactly the same evidentiary gap the *prior* arc's own
reconciliation hit for a different slice (S6) — this is now a second instance of the same
detection limit. Neither finding touches a number, a claim, or the code; both are about whether
the routing record can be trusted at face value.

## Axis 1 — Scope

**Matches, verified against `git log`/`gh pr list`, not the prose:** `origin/main` progressed
`25768833b` -> `12e94657f` (#915, `claude/prong-b-tier1`) -> `c976e7316` (#916,
`claude/citation-durability`) -> `71ce9e544` (#917, `claude/mc0653-fixture`) -> `5a9662110`
(#918, `claude/ci-ceiling-closeout`), confirmed via `gh pr list --state merged --limit 6`
(`mergedAt` timestamps strictly increasing, 14:46, 15:38, 16:24, 17:17 UTC on 2026-08-04).
Census: computed directly from `docs/dev-log/dashboard/capability-census/_master.tsv` column
10 (`evidence_tier`) at the tip — **182 `interval_feasible` / 60 `point_fit_recovery`** exactly,
and `python3 tools/capability_ledger.py --check` returns `OK (30 generated outputs)`. The only
`_master.tsv` diff across the *entire* `25768833b..5a9662110` range is `R/profile.R:LINE`
citation-anchor renumbering (e.g. `1710-1727` -> `1721-1738`) in the `student`/`skew_normal`
rows; `status` and `evidence_tier` are byte-identical in every changed row. Foreign lane:
PR #858 (`codex/lane-b-e0-readiness`) is untouched by this arc's diff (`git diff --stat` shows
no file it owns).

**S-1 [ADAPTIVE].** `gh pr merge` on #916 was refused: *"refusing to allow an OAuth App to
create or update workflow `.github/workflows/R-CMD-check.yaml` without `workflow` scope."*
Independently corroborated two ways: (1) `gh auth status` in this session shows
`Token scopes: 'admin:public_key', 'gist', 'read:org', 'repo'` — no `workflow` scope, matching
the after-task report's own parenthetical exactly; (2) the mechanism the report gives (#916's
head still carried `timeout-minutes: 45` while base carried `120`, so the merge result differed
from both parents and the API had to synthesize a new workflow blob, which needs the missing
scope) is internally consistent with `c1da21b7a` (the 45->120 raise) landing on
`claude/prong-b-tier1` *before* `claude/citation-durability` was rebased onto it. The fix —
merge `main` into the feature branch, push over SSH (unrestricted), then merge — added two
commits the plan's slice table does not name: `a1be123f1` ("Merge branch 'main' into
claude/citation-durability") and `246f4515c` ("Merge branch 'main' into claude/mc0653-fixture"),
both present in `git log --oneline origin/main`. This also resolves the plan's own "no rebase
needed" framing (Deviation B): `git merge-tree --write-tree` verification was TRUE for CI
purposes (zero conflicts, both merges yield `timeout-minutes: 120`) but insufficient for the
*merge API specifically*, which needs the workflow content on the head commit itself, not just
on the three-way-merge result. I did not re-derive the "byte-identical tree hash vs.
`refs/pull/916/merge`" claim myself — that PR ref no longer exists post-merge — so that specific
sub-claim is taken on trust from the after-task report (Sec. 7) and check-log. The second half
of the task's Deviation A — "a direct push to main was DENIED by the permission classifier" —
appears nowhere in any landed doc; that is expected (a tool-permission event is not the kind of
thing that gets written to repo prose) rather than suspicious, but it means I can neither
confirm nor refute it from repo artifacts. Net: justified, resolved, verified where checkable,
and recorded in both the after-task report (Sec. 7) and check-log (`docs/dev-log/check-log.md`,
"2026-08-04" entry). Not a scope violation — a mechanical necessity discovered mid-arc.

**S-2 [ADAPTIVE].** Deviation C (a second ultra-plan for the D-117 10-group coverage gate,
authored mid-arc at the user's request) is real and now precisely located:
`~/.claude/plans/proud-noodling-dragonfly.md`, local mtime 2026-08-04 08:24, titled
"Ultra-Plan — the next arc: D-117, the 10-group profile coverage gate." Its timing sits squarely
inside this arc's own CI-wait window: PR #915's check (`c1da21b7a`, run `30916793237`) started
at UTC 14:01:39 (local 08:01) and did not complete until 14:45:30 (local 08:45) — so the D-117
plan (08:24 local) was authored *while PR #915's CI was still running*, i.e. genuinely
concurrent with this arc, not a separate session mistaken for one. Its own header confirms the
model-routing convention I independently inferred from commit trailers below: row N0 reads
`Ada (this thread) | Fable, high | inline`. The **finding** it produced — the D-117 number
already exists, unpushed, at **0.937 (0.920, 0.951)**, n=1000, on `codex/sd-bootstrap-r999-diagnosis`
(`4cc837a85`) — is recorded in the after-task report Sec. 10 and independently reproduces:
`git cat-file -t 4cc837a85` returns `commit` (the object exists locally in this worktree's
object store), the branch `codex/sd-bootstrap-r999-diagnosis` exists locally, and
`git ls-remote origin` returns **zero** matches for it — confirmed unpushed, exactly as claimed.
The report's companion claim that `claude/profile-coverage-remeasure-20260718` (cited at
`~/shinichi-brain/memory/DECISIONS.md:1628`) **does not exist** also reproduces: the citation is
there verbatim, and `git branch -a` has no matching branch. D-117 itself exists in
`DECISIONS.md` at line 3427 (title: *"The 10-group corner IS a gate on drmTMB 0.7.0"*), content
matching what both handover docs and the after-task report attribute to it. The "2 Explore
agents beyond this arc's budget" process claim is not independently checkable from repo
artifacts (that accounting lives in the D-117 plan/session, not in a committed file), but it did
not touch the current arc's own FAN-OUT BUDGET — that budget is scoped to slices S1-S10 of
`kind-sprouting-cascade.md`-style header text given to me, none of which name a D-117 sub-plan.
Adaptive: user-directed, output landed and cited correctly.

No other scope drift. `docs/dev-log/plan-actual/2026-08-03-prong-b-tier1.md` (the prior
reconciliation) is carried into this diff range because it was committed on one of the
already-authored branches before this arc began — routine carry-through, not new scope.

## Axis 2 — Evidence / verification

**E-1 [ADAPTIVE].** The six CI job durations in the ceiling commit (`d1314dfef`), the after-task
report, and check-log — `43m35s / 43m51s / 44m34s / 44m36s / 45m49s / 46m34s` — reproduce
**exactly, to the second**, from `gh api repos/itchyshin/drmTMB/actions/runs/<id>/jobs`
(`started_at`/`completed_at` on the `ubuntu-latest (release)` job, not the outer workflow-run
`createdAt`/`updatedAt`, which include queue time and would not match): `30916793237`
14:01:55->14:45:30 = 43:35; `30920642104` 14:46:33->15:33:07 = 46:34; `30920681853`
14:47:01->15:32:50 = 45:49; `30925126850` 15:38:10->16:22:46 = 44:36; `30925161768`
15:38:37->16:22:28 = 43:51; `30925237692` 15:39:29->16:24:03 = 44:34. I went one step further
than the report and checked for a seventh candidate: run `30929010622` (push to `main` after
#917, `71ce9e544`) also completed that day at 46:25 but is **not** among the six. Its job
`started_at` was 16:25:19 and it did not complete until 17:11:44 — after `d1314dfef`'s own PR
job had already started (16:30:03) — so it was still in flight when the ceiling commit was
authored and simply was not yet measurable. This does not change the decision: 46:25 does not
exceed the max already used (46:34), so the ~28-minute margin claim is unaffected. The plan's
own bar, per `docs/dev-log/2026-08-04-ci-ceiling-and-job-split.md` Sec. 3 ("do not tighten the
ceiling — that waits for three completed runs"; Sec. 5, "did not tighten the ceiling — that
waits for three completed runs"), was a **minimum of three**; the actual close used six,
exceeding its own stated floor. This is a genuine escalation from what an intermediate,
already-landed note specified, but it strengthens the evidence base rather than weakening it —
tagged adaptive, not drift.

**Not independently verifiable: "not the 75-90 range the plan floated."** No landed repo
artifact or found plan file states a 75-90 range; the final value (`timeout-minutes: 75`,
confirmed live in `.github/workflows/R-CMD-check.yaml`) is solid, but the *comparison* to what
was floated pre-execution is outside what I could check. Taken on trust.

**Independently re-run at the tip, not just trusted from the report:**
`python3 tools/capability_ledger.py --check` -> `OK (30 generated outputs)`; all six
`tools/tests/test_capability_ledger.py`, `test_arc1_profile_reconcilers.py`,
`test_b3_q6_target_promotion.py`, `test_b4_ci_guard.py`, `test_b4_ci_c1.py`,
`test_profile_truth_gate.py` -> `OK` (3/3/12/5/24 tests respectively, plus the ledger's own
suite). I did not re-run the four R-based CI steps (`emit-profile-truth-manifest.R --check`,
`check-capability-runtime.R`, `check-profile-fence-integrity.R`, `check-evidence-citations.R`)
myself — each needs a TMB compile — but every relevant GitHub Actions run at every PR head and
every post-merge push shows `conclusion: success` (`gh run list --workflow=R-CMD-check.yaml`),
which is an independently generated receipt, not the report's own prose.

**R1 collateral-unlock gate — spot-checked, not fully re-enumerated.** I confirmed at the tip
that the three predicates the gate claims stayed retained are in fact still present and wired in
`R/profile.R` (`zi_nbinom2_sigma_q1_profile_restricted`, `zero_one_beta_zoi_q1_profile_restricted`,
`zero_one_beta_coi_q1_profile_restricted`, all still defined and still referenced in the
disjunction chain). I did not re-derive the full "0 unbacked routes across all 14 opened cells"
enumeration myself; that is taken on trust from the after-task report Sec. 6 and check-log.

## Axis 3 — Model routing

**R-1 [DRIFT].** All of this arc's *own* new work is a single commit, `d1314dfef` (PR #918),
co-authored `Claude Fable 5` per `git show -s --format=%b d1314dfef`. Every other commit in the
range (`cce6df666` through `c1da21b7a`) is co-authored `Claude Opus 5` — but those all predate
this arc's own plan (they are the Prong B Tier 1 authoring work, already reconciled
2026-08-03), so they are not part of this arc's own FAN-OUT BUDGET and their model tier is out
of scope here. What matters is that `d1314dfef` bundles the ceiling-value change
(`timeout-minutes: 45 -> 75`, i.e. the plan's S7, "tighten timeout," planned as `Gauss, Sonnet`)
together with the after-task report, the check-log entry, the AGENTS.md pointer refresh, and the
job-split note (together closest to S9, "consolidate," planned as `Rose, Sonnet`) into **one**
commit under **one** model identity. The task's own Deviation D names only S8/S9 as folded
inline; the commit evidence says S7 rode along in the same single commit too, and that is not
disclosed anywhere I could find (`grep`-checked the after-task report and check-log for "Gauss",
"Sonnet", "S7" — no hits distinguishing it as a separate act). This reading is corroborated by
an independent source: `proud-noodling-dragonfly.md` (Axis 1, S-2) uses the identical
"`Fable, high | inline`" notation for its own N0 row, confirming "Fable" is this session's own
convention for *orchestrator-inline* execution, not a literal Sonnet/Haiku dispatch — so the
trailer is legible evidence, not a coincidence of naming. Net: the *fact* of inline execution
(what Deviation D discloses) is independently confirmed and consistent with the prior arc's own
"fable, inline" labeling for slices S1/S5; the *scope* of what got folded in (three slices, not
two) is under-stated. **Owner: Rose** (closeout-completeness — the self-report is honest in kind
but incomplete in extent).

**R-2 [UNCLEAR].** S2 ("re-verify stack tip," planned `Rose, Haiku`) and S3 ("R1
collateral-unlock gate," planned `Fisher, Haiku`) have no separately titled artifact or byline
anywhere in `git diff 25768833b..5a9662110` — I grepped the whole range for `haiku`,
`systems_auditor`, `inference_reviewer`, and `byline` and got zero hits. Their results (10/10
checks at `ad39bacbc`; R1 gate 0 unbacked routes) are narrated directly in the after-task
report Sec. 6 without attribution to either persona. This is not evidence of a violation — a
bounded, read-only re-verification slice would not necessarily leave a distinct artifact, and
the actual *content* of both checks reproduces independently (Axis 2) — but it is also not
positive evidence that either ran as a dispatched child rather than inline. This is the same
evidentiary gap the *prior* Prong B Tier 1 reconciliation hit for a different slice (S6,
`docs/dev-log/plan-actual/2026-08-03-prong-b-tier1.md`, finding R-1) — a second occurrence of
"model-routing self-report cannot be independently confirmed from repo artifacts alone" (see
Recurring drift classes, below). **Owner: Ada**, to confirm routing intent.

**FAN-OUT BUDGET (`<=6` children, ceiling `0`) — holds once correctly scoped.** No Opus-tier
trailer appears on any commit that is this arc's own new work; the only new commit (`d1314dfef`)
is Fable. All Opus-trailer commits in the diff range belong to the separately-reconciled Prong B
Tier 1 authoring arc, not this one's slice table.

## Axis 4 — Safety gates

All matched; the DEFER fence is verified at the code level, not only in prose (see also "Did the
DEFER fence hold?" below). **DISCIPLINE ("verify = the full six-unittest CI step, never
`capability_ledger.py --check` alone")** is upheld: the after-task report Sec. 8 states this
explicitly, and it is structurally hard to violate on GitHub Actions specifically because the CI
job runs the whole sequence as one step (`.github/workflows/R-CMD-check.yaml`, "Validate
generated capability ledger" step) — the risk that bit the *predecessor* session (documented in
`docs/dev-log/handover/2026-08-04-claude-handover.md`, "Gotchas") was local/manual verification
before pushing, not this arc's own CI-backed re-verify. I independently re-ran the same full
Python-side sequence at the tip (Axis 2) rather than trusting the claim.

## Axis 5 — Public claims

`NEWS.md` is untouched after the #915 merge point (`git diff --stat 12e94657f..5a9662110 --
NEWS.md` is empty) — no new public claim was added during citation-durability, mc0653-fixture,
or ceiling work; its content (the "reachability, not inference" framing, the structured-sigma
caveat) was already Prong-B-Tier-1 content, audited by the prior reconciliation. "This stack
promotes nothing" and "census unchanged" both verified directly against the raw TSV (Axis 1),
not trusted from prose. The CI-ceiling comment now shipped inside
`.github/workflows/R-CMD-check.yaml` itself — a durable, visible artifact anyone reading the
workflow file will see — states the same six job durations verified in Axis 2 to the second; it
is accurate. The `drmSEM` sibling-instance flag ("same `timeout-minutes: 45` fault, not yet
fired... flagged, not fixed") is outside this repo and I did not check the `drmSEM` checkout to
confirm it was not touched; taken on trust, low risk given the claim explicitly says nothing was
done there.

## Axis 6 — Handoff state

**Matches exactly.** PR #918's sole commit (`d1314dfef`) is a 5-file diff:
`.github/workflows/R-CMD-check.yaml`, `AGENTS.md` (+41/-1, a "Latest pointer" refresh —
confirmed changed), `docs/dev-log/2026-08-04-ci-ceiling-and-job-split.md` (new, 135 lines, the
job-split *recommendation*), `docs/dev-log/after-task/2026-08-04-prong-b-stack-landing-and-ci-ceiling.md`
(new, 166 lines), and `docs/dev-log/check-log.md` (+37 lines). This is precisely the
"after-task report + check-log entry + AGENTS.md pointer refresh + a CI job-split recommendation
note" the task describes — file-for-file, confirmed via `git show --stat d1314dfef`. D-117 is
flagged as an open owner-decision in both the after-task report (Sec. 10) and the predecessor
handover (`docs/dev-log/handover/2026-08-04-claude-handover.md`, "Blockers / Open Questions"),
not silently dropped. The handover-doc trail is intact: `2026-08-03-prong-b-tier1-to-campaign-handover.md`,
`2026-08-04-claude-handover.md`, and a new `2026-08-04-prong-b-stack-handover.md` are all present
in the diff and cross-reference each other consistently on the DEFER list (135-trace campaign,
`predict()`, B4-CI `SOURCE_COMMIT`, mc-0282).

## What was verified independently vs. taken on trust

**Independently reproduced from raw sources (not the report's prose):**
- Census 182/60, computed directly from `_master.tsv` column 10 and cross-checked with
  `capability_ledger.py --check`.
- All six CI job durations, to the second, from the GitHub Actions API's own job timestamps —
  plus a seventh run the six-run set excluded, with a chronological (not selective) explanation.
- `timeout-minutes: 75` live in the workflow file.
- `_master.tsv`'s only diff across the whole range is citation-anchor text, never
  `status`/`evidence_tier`.
- `capability_ledger.py --check` and all six `tools/tests/*.py`, re-run at the tip.
- The missing `workflow` OAuth scope (`gh auth status`, matching the report's own parenthetical).
- `codex/sd-bootstrap-r999-diagnosis` @ `4cc837a85` exists locally, absent from origin; D-117 and
  the `claude/profile-coverage-remeasure-20260718` non-existence both confirmed in
  `~/shinichi-brain/memory/DECISIONS.md`.
- The mid-arc D-117 plan file itself (`proud-noodling-dragonfly.md`), located, dated, and shown
  to sit inside this arc's own CI-wait window.
- `R/methods.R` (home of `predict.drmTMB`), `mc-0282`, and `SOURCE_COMMIT` are absent from the
  entire arc diff; the workflow's job structure is unchanged (only the timeout value line moved).
- PR #918's exact file list, matching the claimed closeout bundle.

**Taken on trust (checked for internal consistency, not re-derived from a primary source):**
- The byte-identical tree-hash claim for the "update branch" workaround (the PR ref it would
  diff against no longer exists post-merge).
- The full 14-route "0 unbacked routes" enumeration for the R1 gate (spot-checked 3 of the
  retained-fence predicates, not all 14 opened routes against ledger cells).
- The "2 Explore agents beyond this arc's budget" process detail for Deviation C (the finding it
  produced is verified; the agent-count accounting is not in any committed file).
- The "direct push to main denied by the permission classifier" half of Deviation A (a
  tool-permission event, not expected to appear in repo prose either way).
- The "75-90 range the plan floated" comparison (no source document found).
- The `drmSEM` sibling-repo claim (out of this repo's scope).

## Did the DEFER fence hold?

**Yes, verified at the code level for every item, not only via the deferred-items list itself
being present in prose:**
1. **135-trace interval campaign** — not run. No Totoro/DRAC reference anywhere in the arc diff;
   explicitly listed as "NOT STARTED"/deferred in both the after-task report and the handover.
2. **`predict()` scale-axis defect** — not fixed. `R/methods.R` (where `predict.drmTMB` is
   defined, `R/methods.R:2707`) does not appear anywhere in `git diff --stat 25768833b..5a9662110`.
   The only related change is a new pinning comment/test inside the mc0653-fixture branch's own
   test file ("When `predict()` is fixed this will fail, which is the intended alarm") — pinning
   current (buggy) behaviour is explicitly not the same as fixing it, and no `src/*.cpp` or other
   `R/*.R` implementation file changed.
3. **mc-0282's runner contract (PROTECTED)** — untouched. Zero hits for `mc-0282` outside prose
   mentions in the handover/after-task docs recording it as still deferred.
4. **B4-CI `SOURCE_COMMIT` port** — untouched. Zero hits for `SOURCE_COMMIT` outside the same
   prose mentions; the workflow's excluded-test list (`test_b4_ci_c2/c3/c4`, excluded because
   `SOURCE_COMMIT 574c1108e` is unreachable from CI) is unchanged.
5. **CI guard/check job split** — not implemented. `docs/dev-log/2026-08-04-ci-ceiling-and-job-split.md`
   says so explicitly twice ("The split itself is NOT done here — it is a workflow change and
   deserves its own arc"; "Did not split the workflow — recommended above, own arc"), and the
   workflow diff confirms it: the only change to `.github/workflows/R-CMD-check.yaml` between
   `25768833b` and `5a9662110` is the `timeout-minutes` value line. A recommendation note is not
   the same as doing the split, and it was not conflated with doing it anywhere I found.

The fence held.

## Recurring drift classes

`~/shinichi-brain/memory/PLAN-DRIFT-LEDGER.md` currently records one standing class
("Multi-lane handover single-pointer trap," owner Ada, not applicable here) and does **not** yet
contain "citation/line-number anchor rot," which the prior Prong B Tier 1 reconciliation
recommended adding on 2026-08-03 — worth Rose's attention at the next monthly aggregation, since
per that ledger's own process this reconciliation only records, it does not escalate.

**Candidate class, now at 2 occurrences across 2 arcs 1 day apart:** *model-routing self-reports
are not independently verifiable from repo artifacts when a slice is bounded, read-only, or
folded inline* — the prior arc's R-1 (S6, mechanical-verify: no artifact either way) and this
arc's R-2 (S2/S3: same gap) are the same shape. Both times the *content* of the disputed slice
turned out to reproduce correctly under independent re-verification, so this is not (yet)
evidence of a routing failure — but it means Melissa's own Axis 3 check is structurally limited
to "consistent with / not contradicted by" rather than "confirmed," unless the executing session
adopts a convention of leaving a minimal artifact (even a one-line scratchpad note with a
persona byline) for every dispatched-vs-inline slice, the way S7's adversarial review did in the
prior arc. Recommend Rose consider this alongside the citation-anchor-rot class at the next
monthly ledger pass — two different classes, same "≥2×" bar.

## Tagged-deviation summary

| ID | Axis | Tag | Owner |
|---|---|---|---|
| S-1 | Scope | ADAPTIVE | — |
| S-2 | Scope | ADAPTIVE | — |
| E-1 | Evidence | ADAPTIVE | — |
| R-1 | Model routing | DRIFT | Rose |
| R-2 | Model routing | UNCLEAR | Ada |

**Counts: 3 adaptive, 1 drift, 1 unclear.**
