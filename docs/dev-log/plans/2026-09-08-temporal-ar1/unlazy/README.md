🎯 GOAL

```text
Solo platform: Codex. PLAN ONLY until explicit approval; fresh Terra executes.
Deliverable: verified Gaussian mean-side temporal AR1 with separate residual sigma.
HEADLINE: complete the model, public workflow and original G0-G15 evidence contract.
IN PARALLEL: recovery and docs only after the shared implementation is stable.
DEFER: every OU/non-Gaussian/phi-regression/inference/bridge extension in plan.md.
DISCIPLINE: Unlazy re-verification, bounded compute, independent review and local closure.
```

# Temporal arc execution contract

Read the parent `plan.md` for the equations, data contract and exact tolerances.
This supplement supplies executable gate commands and their schedule. It supersedes
the JSON file as the **execution-status authority**, not as a source of permission.
`acceptance.json` remains the original numbered requirements map. No check has run
against an implemented temporal provider and no approval has been recorded.

## Route and ownership

The route is known: the destination is a verified Gaussian AR1 provider. No
scientific choice is newly opened here. Exact outputs are below; shared-path owner
approval is the S0 dependency. The proposed gate/test layout below replaces the
earlier three broad test filenames with one file per gate, so execution selection
is explicit. It does not drop any test requirement.

| Leaf | Member, model/effort, dispatch | Inputs → outputs | Dependencies | Time |
| --- | --- | --- | --- | --- |
| RECON / S0 | Shannon/Ada, Terra medium, fresh root | Existing source map + fresh leases → G0 evidence and guard-owner table | User approval | 15–30 min |
| 01: parser/layout | Boole, Terra medium, native/explicit | Formula contract → `R/temporal.R`, parser branch, `test-temporal-g1.R`, `test-temporal-g2.R`, independent helper | G0 | 1–2 h |
| 02: likelihood | Gauss, Terra high, native/explicit | Layout → native prior/data/maps; `test-temporal-g3.R` through `g7.R` | G1–G2; release leaf 01's lease | 2–3 h |
| 03: methods/guards | Emmy, Terra high, native/explicit | Verified fit → metadata, public methods, coordinated guards; `test-temporal-g8.R` through `g10.R` | G3–G7; release leaf 02 | 1–2 h |
| 04: recovery | Curie, Terra medium, native/explicit | Verified model → recovery runner, `g11.R`/`g12.R`, raw attempt tables | G8–G10; timed estimate before bounded run | 0.5–1 h |
| 05: reader workflow | Pat, Terra medium, native/explicit | Stable outputs → named source/generated docs, local render, `g13.R` | G8–G10; disjoint from leaf 04 | 1–2 h |
| 06: integration/review | Ada + fresh Noether/Pat/Rose review lenses; Terra medium/high, one Sol high load-bearing reviewer; native/explicit | G1–G13 evidence → package check, G15, after-task and reconciliation | Both leaves 04 and 05; lease check-log only now | 0.5–1 h |
| MECHANICAL-VERIFY | Luna medium, native/explicit if available, else tiered-cli/enforced | Gate status/receipts/source hashes → bounded verification receipt | Final candidate | 5–10 min within closeout |
| RECONCILE | Melissa lens, Terra medium, reused root | Planned vs actual scope/evidence/routing/authority → `docs/dev-log/plan-actual/2026-09-08-temporal-ar1.md` | Reviews and re-verification | Within closeout |

One Terra implementer may serve leaves 01–03 sequentially; role names are lenses,
not three automatic agents. At most two production children at once. Use fresh,
self-contained briefs and retain explicit dispatch evidence. Production child
budget <=4; final milestone panel once, separately, with two fresh Terra and one
fresh Sol reviewers. No new Astra execution parent. LANE: START A FRESH TASK after
approval, following D-251. No extra literature search is needed for this gate-format
upgrade; the parent plan retains its verified primary precedents and brain recall.

Estimate remains about 6–11 agent-hours (5–10 elapsed with disjoint docs), excluding
ownership waits. The estimates in the parent plan apply to each actual model run:
compile 3–10 min, a fit 1–3 min, six datasets/twelve starts 5–15 min, package check
10–30 min. **One final complete re-verification pass adds roughly 20–45 minutes**;
budget about 7–12 agent-hours including that closure. Stop and re-estimate an overrun.
Recovery >30 min requires separate approval with pre-run results and target. No
remote campaign or compute is launched by staging or status inspection.

## Frozen case IDs and command oracles

`check-tests.R` contains the exact required case IDs for G1–G13, for example
`G4:dense_marginal_identity`. Future test authors implement those cases in
`tests/testthat/test-temporal-g4.R`; the runner requires the complete ID set, no
duplicates, at least one successful assertion per case, and zero failures, errors,
skips or unexpected warnings. Each ID refers to all cases/tolerances in parent
plan section 8, not merely the label. Independent review checks the assertions
actually exercise that contract. Expected diagnostic warnings use explicit
`expect_warning` assertions; no blanket warning suppression or weakened tolerances.

G1/G2/G6 pure tests load their required R definitions/reference helper explicitly;
they must run without the package DLL. G6's unavailable-OU check is parser/admission
behaviour, not an OU fit. Native tests explicitly load needed helpers because the
runner disables automatic test helper loading. A reviewed forced build writes a
source/DLL fingerprint; native gates refuse stale or foreign DLLs. Build/test receipts
are local run state. At final review bind all relevant R/C++/test/reference/DGP
files to the tested implementation revision, including ignored generated inputs.

G11/G12 call the future `inst/validation/temporal-ar1-recovery.R`, then independent
tests validate its outputs. The runner must emit immutable run directories, a seed/DGP
manifest, elapsed-time/estimate receipt, six selected-fit rows and **twelve raw
attempt rows** for bounded mode (two starts per dataset, failures retained). Pre-run
mode has one dataset/two attempts. Keep values, signs, seed order and thresholds from
the parent plan. Tests recompute winner selection, ties, errors and recovery metrics
from raw rows. No output-only success string can pass this two-stage gate. If outputs
already exist on a new --reverify run, write a new unique run directory and update a
small latest-run pointer; never overwrite old runs. Tests bind that pointer to the
new run and its source/DGP hash so stale results cannot certify a changed model.

G13 requires a current local render and exported teaching workflow. Public tutorials
use `summary()`, `structured_effects()` and `ranef()` as appropriate; internal
`sdpars`/`corpars` recovery slots are not the reader-facing example. G15 independently
reviews the rendered result. G14 uses rcmdcheck with zero errors/warnings/notes; an
existing legitimate note is a visible contract-review item, not an automatic waiver.

The new tests are planned outputs, not present implementations. The two manual gates
are G0 (user authority/ownership) and G15 (independent scientific and usability
review plus reconciliation). All other gates have commands. The runner's own
self-test verifies orchestration failure controls only, not the temporal mathematics.

## Staging and execution after approval

Committed files here are immutable templates. Run `node
docs/dev-log/plans/2026-09-08-temporal-ar1/unlazy/stage.mjs` from the execution
worktree once. It checks that `.unlazy/` is ignored and refuses an existing scope.
Runtime `.unlazy/temporal-ar1/` can then change without dirtying tracked templates.
At this planning checkout ignore coverage comes from the common Git `info/exclude`;
recheck it in the new worktree. No persistent settings or Stop hook is installed.

Read-only whole-scope inspection:

```sh
node /Users/z3437171/shinichi-brain/skills/unlazy/scripts/gate-check.mjs --root . --scope temporal-ar1 --status
```

Read each CHECK and its called scripts, including the future tests and recovery
runner, before executing. Ada schedules eligible leaves. The R runner also requires
recorded G0 approval and prerequisite receipts matching the current source, tests,
reference helpers and verification scripts. A source change invalidates those
receipts: rerun prerequisites in order before continuing. G11/G12 check readiness
before invoking the recovery program, and bind its retained outputs into receipts.
Never use an indiscriminate whole-scope `--approve`. Claim and release only the
currently eligible leaf. The separate hub lease remains necessary for ownership.

After G0 and the announced estimate, build with:

```sh
Rscript --vanilla docs/dev-log/plans/2026-09-08-temporal-ar1/unlazy/check-tests.R --build
```

For an eligible leaf, review all bound inputs then approve its exact checks once:

```sh
node /Users/z3437171/shinichi-brain/skills/unlazy/scripts/gate-check.mjs --root . --cwd . --shell /bin/sh --timeout 900 --approve .unlazy/temporal-ar1/gates/leaf-01.md
```

Use 1800 seconds for the package-check leaf after stating its estimate; other
leaves use their shorter measured limits. Approvals bind CWD, shell, PATH, command
and timeout; changes require fresh review. Re-review called scripts whenever their
contents change even if the CHECK string does not. No check approval is recorded
by this planning task. Thread caps in the parent plan apply to all commands.

At closure, commit the tested source, rebuild if native source changed, and rerun
every eligible leaf using the same bound inputs with `--reverify` in place of
`--approve`. Save exact stdout/exit/hash receipts in ignored run state, distil the
decisive results into a tracked after-task report, then mark G15 with review evidence.
An evidence-only closure commit may follow; compare implementation-file hashes
instead of rerunning the model just because that report changed the commit ID.
Report met/unmet/abandoned counts. Any required unmet gate means the feature is
unfinished; do not silently delete or abandon it to reach a green summary.

## Approval envelope

The user is approving the original Gaussian AR1 scope and this concrete verification
schedule. After approval, a fresh Terra task may implement the named files, run the
bounded checks, render locally and commit locally, subject to the shared-path leases.
The >30-min recovery, foreign ownership, external-message, push/merge/release and
deployment boundaries remain unchanged. Once approved, complete the reversible
arc autonomously through G15; do not seek a fresh instruction at each leaf boundary.
