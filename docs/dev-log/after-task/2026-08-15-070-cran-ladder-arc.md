# After-task — the 0.7.0 CRAN ladder arc

**2026-08-15 · Claude · lane `claude/07-cran-ladder` · PRs #1039, #1041**

## 1. Goal

Make the two owner holds on drmTMB 0.7.0 — D-93 and D-117 — **decidable**, and close every
pre-freeze item that does not depend on the freeze, so that when the holds lift we cut one
candidate and run the platform matrix once.

## 2. Implemented

**The D-93 decision packet** (`docs/dev-log/release-audits/2026-08-15-d93-decision-packet.md`).
D-93 has held 0.7.0 since 2026-07-27 and had never been put back in front of Shinichi with the
numbers that now exist. The packet assembles the ladder — 0.5092 conditional bootstrap → 0.8714
marginal → 0.9400 profile (3 cells) → **0.924800, SE 0.000417, 400,000 attempts** at the 10-group
corner — against nominal 0.95 and the pre-registered floor `ss_floor(10) = 0.918`. It prices both
readings of D-93's own wording, labels its recommendation as a recommendation, states the argument
against that recommendation, and **ends in an unanswered question**.

**Gate 1 closed** (`…2026-08-15-gate1-component-ledger-and-rights-review.md`). A 9-row component
ledger rebuilt from the tarball inventory, plus the rights review the release ledger flags as never
performed. **Verdict: CLEAR** — does not block `submission-ready`.

**The version-string hazard removed.** `DESCRIPTION` on `main` read the bare `Version: 0.7.0` —
byte-identical to the frozen candidate's — while 60 shipped files differed from it. Now
`0.7.0.9000`; the freeze will set it back.

**The bootstrap boundary flag re-landed** (PR #1041). `8245449f2` was on no path to `main` and
would have been lost with the PR that carried it.

**D-117 condition 1 found already satisfied** — see §3a. No change was needed, and one was reverted.

## 3a. Decisions and Rejected Alternatives

**Reverted the D-117 condition-1 edit rather than shipping it.** The recovery-bias magnitude was
already user-facing on `main` in four places as `8.3%-15.8%`. The slice's output would have added a
second, differently-rounded statement of one measurement to the same help page. Rejected: keeping
it as a "more precise" refinement — two numbers for one quantity is worse than either alone, and
the repo prose standard requires stable terms.

**Ran the CRAN gate rather than reading the rung.** The handover asserted `platform-clean` was
blocked; a probe copy with `status_claim` raised proved it, naming both missing evidence keys. A
gate that only ever returns READY is indistinguishable from a broken one.

**Sent the D-93 packet to Rose, not back to Fisher, for the claim review.** The plan had Fisher
reused to save a child. Fisher wrote it; own-the-verifier forbids that.

**Did not run the REML arm the packet recommends.** ~20 minutes of Totoro compute, under the D-139
line — but outside this arc's fence (`compute=local only`), and it is the substance of the open
question, not a prerequisite to asking it. Shinichi's call.

**Did not advance `status_claim`, re-freeze, or touch platform evidence.** Fenced by the plan and
by the 2026-08-15 no-re-freeze decision.

## 4. Files Touched

Created:
- `docs/dev-log/release-audits/2026-08-15-d93-decision-packet.md`
- `docs/dev-log/release-audits/2026-08-15-gate1-component-ledger-and-rights-review.md`
- `docs/dev-log/release-audits/2026-08-15-gate1-recon-inventory.md`
- `docs/dev-log/release-audits/2026-08-15-mechanical-verify.md`
- `docs/dev-log/plan-actual/2026-08-15-070-cran-ladder-arc.md`
- `docs/dev-log/after-task/2026-08-15-070-cran-ladder-arc.md` (this report)

Modified: `DESCRIPTION` (Version line only).

Modified then **reverted to `origin/main`**: `R/profile.R`, `man/confint.drmTMB.Rd`, `NEWS.md`.

On PR #1041's separate branch (`claude/bootstrap-boundary-reland`): `R/profile.R`, `R/check.R`,
`man/confint.drmTMB.Rd`, `NEWS.md`, `tests/testthat/test-boundary-surfacing.R` (new).

GitHub: PR #1039 and #1041 opened; #959 and #955 closed earlier in the session.

## 5. Checks Run

| Check | Result |
| --- | --- |
| `cran_release_gate.py` on the 0.7.0 ledger, after **every** commit | **READY FOR CLAIMED RUNG**, unchanged throughout |
| Same ledger, `status_claim` probed to `platform-clean` | **NOT READY** — `platform_matrix`, `external_logs` |
| `shasum -a 256` on the frozen tarball | `2176e4b8…cda9`, 9,925,713 bytes — unchanged |
| `git diff origin/main..HEAD -- R/ src/ tests/ man/ vignettes/ NEWS.md` on this lane | **empty** |
| Version-pin sweep before the bump | 1 PIN (`DESCRIPTION` itself); all `packageVersion()` uses are provenance metadata |
| PR #1041 — boundary smoke | warning class raised, `conf.status = bootstrap_at_boundary`, point estimate 0.1936 |
| PR #1041 — `test-boundary-surfacing.R` | 16/16 pass |
| PR #1041 — `test-profile-targets.R` | 983 pass, 0 fail (2 pre-existing unrelated deprecation warnings) |
| PR #1041 — `devtools::document()` | regenerated `.Rd` matched the manual resolution, zero diff |
| Mechanical verification sweep (8 checks, independent agent) | see `2026-08-15-mechanical-verify.md` |
| Adversarial claim review of the D-93 packet (independent lens) | see §8 |

## 6. Tests of the Tests

The gate was exercised in both directions: READY on the unmodified ledger, NOT READY on the same
ledger with only `status_claim` raised, naming both missing keys. Ancestry checks likewise
discriminated — YES for `9c6a63223` and `e9f7118e1`, NO for `8245449f2` — rather than answering
uniformly.

For PR #1041 the detector was verified to **fire**, not merely to be present: the demonstrated case
has a point estimate of 0.1936, and the whole reason the original commit rejected a
`wald_boundary_targets()` implementation is that a Wald-style test reads that estimate and stays
silent. A test that passed without the warning firing would have proved nothing.

## 7a. Issue Ledger

- **D-93 — open, and now decidable.** The packet ends in one question. Two live findings inside it:
  `ss_floor` is **descriptive**, tapered to fit the measured g-sweep, so clearing it is not
  independent evidence of adequacy; and **REML is implemented on this exact target (`mc-0265`) and
  its coverage has never been measured** — the one named lever nobody has pulled.
- **D-117 — open, and now unconditionally so.** All four conditions are met; nothing engineering
  remains. Discharge is a judgement.
- **Two Gate 1 assets carry undocumented generation provenance** (logo SVGs,
  `function-map-cheatsheet.png`) — SHIP, recorded as follow-ups, not blockers.
- **The `RUNG-REPORT` "SHIP 4" cannot be reconstructed** — no document ever named them. The
  rebuilt ledger is the best-supported reconstruction and is labelled as such.
- **⚠ Stale `.git/index.lock`** (0 bytes, 2026-08-14 18:43) — still present. Reported, not removed.
- **`handoff_gate.sh` still fails** on foreign unpushed branches — global coordination state.

## 8. Consistency Audit

The D-93 packet was reviewed by an independent lens (not its author) against five questions: does
it overstate dr20's literature position; does any wording read as a discharge; is the closing
question genuinely open; are the numbers traceable; and are its two load-bearing claims
(`ss_floor` descriptive, `mc-0265` unmeasured) actually true. Verdict and any required fixes are
recorded with the arc.

Repo ↔ brain remained consistent throughout: `AGENTS.md` and `memory/DECISIONS.md` agree that D-93
holds and D-117 is not discharged. The earlier session-level claim that they conflicted was
retracted in `2026-08-15-070-cran-ladder-rehydration.md`.

## 9. What Did Not Go Smoothly

**I briefed a slice on a premise I had not checked hard enough.** My grep for the recovery-bias
disclosure searched `8–16 / 8-16`; the repo says `8.3%-15.8%`. An agent then spent a full slice
closing a gap that did not exist, and the output had to be reverted. The lesson is not "grep more"
— it is that a *negative* result ("this is not documented") deserves at least two different search
patterns before it becomes the basis of work, because absence is the one finding that cannot be
falsified by the thing you found.

**A slice was routed to an agent that could not finish it.** `documentation_writer` has no Bash, so
it could not run `devtools::document()` and hand-mirrored generated `.Rd` output instead. Tier
right, tool grant wrong.

**Two agents observed each other's edits** in the shared worktree and correctly flagged them as
unexplained. One inferred that the version bump "sits oddly" against the no-re-freeze decision —
reasonable from where it sat, and wrong; it took a correction round to resolve.

## 10. Known Residuals

- **D-93 and D-117 both await Shinichi.** Nothing else blocks on engineering.
- **The re-freeze remains deferred** with its five preconditions recorded.
- **PR #1041 is unmerged**; PR #1039 is unmerged.
- **The REML arm on `mc-0265` is unrun** — the packet's recommendation, not a commitment.
- Ledger gap `rights_and_consent_is_stale` is now **answered** by the Gate 1 review, but the ledger
  JSON itself was deliberately not edited; whoever owns it should fold the verdict in.
- The platform matrix, win-builder, R-hub and submission remain untouched by design.

## 11. Team Learning

**A negative finding needs a second search pattern before it becomes work.** This arc spent a
slice, a revert, and a correction round on "the 8–16% bias is not documented" — a claim produced by
one grep with one phrasing. Every *positive* finding carries its own evidence; a negative one is
only as good as the search that failed to find it.

**Check the tool grant, not just the model tier.** An implementation slice needing R went to a
review-shaped agent with no Bash. The dispatch looked correct because the tier was correct.

**The producer must not be its own verifier, even when the budget says reuse.** The plan named
Fisher for both S1 and S7 to save a child. That row was wrong and execution overrode it.

**Memory receipt:** loaded the repo LOAD-FIRST manifest and the hub CRAN rules. The guards that
shaped the work were **D-49** (ran the executable gate rather than reading the rung, in both
directions), **D-43** (did not accept any producer's self-report — the handover's D-117 claim, the
packet's own verdict, and S2's premise were each independently checked, and two were wrong),
**D-87/D-88** (12 live lanes; `AGENTS.md` edits confined to the CRAN block; the `DESCRIPTION`
lane-hook warning was investigated rather than dismissed), **D-139** (the ~20-minute REML arm was
estimated and *not* run, because it sits outside the arc fence), and **D-37** (the D-117 and
`ss_floor` findings are recorded in the repo, not written to the vault).

Golden Set: the `cran-readiness-partial-green` regression is directly in scope and **held** — no
partial-green evidence became a whole-release claim, and the rung stayed at `tarball-clean`
through every commit.

Prior-work recall fired and paid: the deterministic grep over `projects/deep-research/README.md`
surfaced `dr20`, Shinichi's own ~90-source harvest built for this exact gate. The D-93 packet's
literature section is a *reuse* of it, not a re-derivation, and semantic recall alone had not
produced it.

## 12. Cross-Product Coverage

Confined to drmTMB. One cross-repo read: a sibling gllvmTMB checkout was inspected to verify the
GPL-3 licence and the three borrowed commits for the Gate 1 rights review — read-only, nothing
written there, and no cross-team note is owed because the finding is drmTMB-internal.

**What this arc covers:** the release-ladder decision surface — the rung, the frozen-artifact
identity, Gate 1 rights and components, the version string, and the two owner holds' decidability.

**What this arc does NOT cover**, per flag:

- **Platform / engine** — no platform evidence produced. `platform_matrix` and `external_logs`
  remain absent for every provider: 3-OS, R-hub sanitizers, valgrind, win-builder.
- **Compiled code** — the `src/drmTMB.cpp` drift is measured, not adjudicated; no sanitizer or
  valgrind run against it.
- **Intervals / coverage** — PR #1041 makes the bootstrap route *disclose* a boundary; it does not
  improve coverage anywhere, and no interval claim is advanced. The REML arm is unrun.
- **REML** — implemented on `mc-0265`, **coverage unmeasured**; that is the finding, not a result.
- **Missing data, aggregation, penalty** — untouched entirely; PR #1033's lane owns the first.
- **Recovery / point estimation** — the 8–16% bias is restated from existing evidence, not
  re-measured.
