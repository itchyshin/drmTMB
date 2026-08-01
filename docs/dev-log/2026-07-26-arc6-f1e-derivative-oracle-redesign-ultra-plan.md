# Arc 6 F1E — private derivative-oracle redesign ultra-plan

```text
🎯 GOAL
PLATFORM: Codex
DELIVERABLE: a SHA-pinned, test-only design and prototype decision for an
independent derivative oracle for the fixed-effect, complete-pair Bernoulli ×
ordinary-NB2 staged-alpha rectangle, with a retained F1-eligibility receipt.
HEADLINE: determine whether analytic moving-endpoint derivatives can certify the
negative tail without reusing the production finite-difference ladder.
IN PARALLEL: a cheap private-surface recon; symbolic Leibniz/endpoint derivation;
and an inference/scope review of the stop contract.
DEFER: reopening F1, F3 smoke/refits, F4/F5, remote compute, public APIs or
documentation, the capability ledger, Arc D/F5, other pair classes, slopes,
random effects, missingness, and direct biv_lognormal() rho12 inference.
DISCIPLINE: every derivative coordinate needs its own independent precision and
node/error ladder. Any unresolved term is derivative_unqualified_test_only;
no tolerance relaxation, clipping, retries, conditional curvature, or runtime
status mutation can turn it into a pass. Close with a fresh F1 decision request,
never F3 authorization.
```

## ARC PROGRAM

**Mode:** fixed capacity. **Requested capacity:** 6 hours (360 minutes).
This is a value-ranked programme, not a promise that numerical uncertainty will
consume six hours. F1D was planned at about seven hours but stopped after 26
minutes when its elementwise check falsified the premise. If F1E reaches a
named derivative hard stop early, it **terminates the technical programme**:
only the retained review and closeout work continues; no later rung becomes an
implicit retry or a differently labelled oracle.

| Order | Budget | Outcome | Definition of done |
| --- | ---: | --- | --- |
| Arc 0 | 45 min | Exact failure-coordinate and mechanism map | Separates association/Bernoulli integrand terms from NB2 moving-endpoint terms. |
| Rung 1 | 105 min | Symbolic derivative contract | First/second Leibniz boundary and cross terms written and aligned to `q=(a,lambda_B,xi_N,tau_N)`. |
| Rung 2 | 100 min | Test-only independent prototype | One log-stable analytic-derivative quadrature route, or a precise infeasibility receipt. |
| Rung 3 | 70 min | Locked-fixture adjudication | Coordinate-wise comparison at interior, `-4`, `+4` mirror, and `-7` control. |
| Review/repair | 25 min | Fresh Noether/Fisher/Rose verdict | Correct only a documented scope/contract defect; never tune a numeric pass. |
| Close | 15 min | Receipt, after-task report, plan-vs-actual record | Explicit F1/F3 disposition and next approval fence. |
| **Total** | **360 min** |  |  |

## What the brain already knows

- D-87 assigns association—the staged eta/sandwich subject—to Codex and
  separates it from Claude's scale/interval lane. This is the same subject and
  worktree, not a new lane.
- F1D's retained result is negative: K1 repaired the private point kernel, but
  the independent elementwise derivative evidence is unstable at `a=-4` and
  the `a=+4, B=0` mirror. The finite production derivative ladder is not a
  certificate.

The basic-memory CLI was attempted with the query
`drmTMB Arc 6 association staged eta F1 F3 numerical derivative tail next decision`
but was blocked by its attempt to chmod `~/.basic-memory`. The raw-vault
fallback inspected `memory/DECISIONS.md` D-87 instead; this is a retrieval
transport failure, not a semantic-search null result.

## Prior-work sweep receipt — required before decomposition

| Surface | Evidence run | Finding | Forced call |
| --- | --- | --- | --- |
| Repository state | `git status --short --branch`; `git log --oneline -12`; `git worktree list`; `git stash list`; `branch_drift_check.sh` | `codex/arc6-association-public-prep-f0f2` is clean at `b91ff44f`, six ahead and ten behind `origin/main`; it contains the K1/F1D association history. | Continue in this worktree, but use a **fresh Codex task** for execution under D-80. |
| Lane ownership | `session_ownership.sh`; `lane_preflight.sh . --hours 36` | Platform is Codex; Claude has recent foreign Arc A/D/Cox--Reid activity. | Association-only; do not touch Arc D/F5 or foreign worktrees. |
| Existing implementation | `rg` over `R/associate-pairs{,-sandwich}.R` and staged-sandwich tests | Production uses a CDF-scale rectangle plus a five-point finite-difference ladder; F1D's independent route still finite-differenced moving endpoints. | Build only the analytic-endpoint derivative gap, test-only first. |
| Sister/twin work | `docs/dev-log/2026-07-25-general-latent-normal-association-sandwich-ultra-plan.md` prior targeted DRM.jl/GLLVM.jl/gllvmTMB sweep | No reusable frozen-margin Bernoulli × NB2 derivative oracle. | No port or transplant. |
| Brain | CLI query above, then raw `memory/DECISIONS.md` D-87 | Association remains Codex's subject; scale/interval work remains Claude's. | Same association lane; fresh task, not a new worktree. |
| Verdict | Evidence above | **Build the gap:** an independent analytic moving-endpoint derivative oracle. | Do not resume F3 or a campaign. |

## Mathematical contract to freeze

Let `q=(a,lambda_B,xi_N,tau_N)`, `eta=0.999999*tanh(a)`, and let

\[
I(q)=\int_{L(q)}^{U(q)} f(z;q)\,dz,\qquad \ell(q)=\log I(q),
\]

where `f` is the standard-normal density times the appropriate conditional
Bernoulli probability and `L,U` are the ordinary-NB2 latent-normal endpoints.
F1E must derive endpoint derivatives from the NB2 CDF/quantile relation rather
than call the production endpoint helper. For every `q_j`,

\[
I_j=f(U;q)U_j-f(L;q)L_j+\int_L^U f_j(z;q)\,dz,
\]

with the following complete second-order contract for every `j,k`:

\[
\begin{aligned}
I_{jk}={}&f(U)U_{jk}-f(L)L_{jk}\\
&+\{f_z(U)U_k+f_k(U)\}U_j
-\{f_z(L)L_k+f_k(L)\}L_j\\
&+f_j(U)U_k-f_j(L)L_k+\int_L^U f_{jk}(z;q)\,dz.
\end{aligned}
\]

For an endpoint defined by `Phi(E)=F(q)`, independently derive
`E_j=F_j/phi(E)` and
`E_jk={F_jk-phi'(E)E_jE_k}/phi(E)`, for both `U` and finite `L`. The
`y_N=0` lower endpoint is `-Inf`: its boundary terms are represented as their
mathematical limits, not silently evaluated as finite values. Finally,
`ell_jk=I_jk/I-I_j I_k/I^2`.

### Pre-registered F1E prototype acceptance contract

The analytic route is the independent reference. At each qualified fixture it
must report the point, all four gradient entries, all sixteen Hessian entries,
and their 512/1024/2048-node values. For every individual coordinate, both
adjacent node comparisons must satisfy the existing F1D elementwise rule
`abs(left-right) <= max(1e-8, 2e-10*max(1,abs(left),abs(right)))`; any failure
is `derivative_unqualified_test_only`. The `a=-4` point must also match the
pinned Genz value at `1e-10`. Only after those independent conditions pass may
the analytic values be compared with the production five-point ladder at the
already frozen `2e-3` gradient and `3e-3` Hessian tolerances, coordinate by
coordinate. The interior, `a=-4`, and `a=+4,B=0` mirror must all pass; `a=-7`
must retain an existing unavailable result, never a finite derivative pass.

## Slice table and routing

| Slice | Member | Model / effort / dispatch | Time | Input → output | Dependency |
| --- | --- | --- | ---: | --- | --- |
| Recon | Ada | Luna / low / tiered-cli enforced | 45 min | F1D receipt + source → coordinate/mechanism map | First; Luna-suitable bounded read-only sweep. |
| Derivation | Noether | Terra / high / native explicit | 105 min | frozen `q`, integrand, endpoints → symbolic Leibniz/endpoint contract | Recon. |
| Prototype | TMB engineer | Terra / high / native explicit | 100 min | contract → test-only independent log-stable derivative prototype or infeasibility receipt | Derivation. |
| Fixture adjudication | Fisher | Terra / high / native explicit | 70 min | prototype + locked cases → coordinate-wise matrix and test-only status disposition | Prototype. |
| Plan review | Noether + Fisher + Rose | Terra / medium / native explicit | 25 min | matrix/receipt → READY or STOPPED F1 eligibility verdict | Adjudication. |
| Mechanical verify | Rose | Luna / low / tiered-cli enforced | 10 min | artifacts/SHA/tests → non-empty consistency receipt | After review; Luna-suitable. |
| Close/reconcile | Ada + Melissa | Terra / medium / native explicit | 5 min | plan versus actual → `docs/dev-log/plan-actual/` record | Always. |

**Fan-out:** three producer/review agents in two batches after approval; no more
than one hard derivation specialist. **Luna suitability:** yes for bounded recon
and mechanical verification, both requiring retained tiered-dispatch receipts.
**Ultra effort:** no. **Compute:** local only; Totoro/DRAC are explicitly not
used because this is a deterministic kernel audit, not a recovery campaign.

## Decision rules and hard stops

1. Each point, four gradient entries, and sixteen Hessian entries must carry
   its own error/node diagnostic. A maximum norm may summarize but cannot
   decide acceptance.
2. A prototype that finite-differences the same moving endpoints, calls a
   production helper, or shares production quadrature control is inadmissible.
3. If NB2 endpoint first or second sensitivities cannot be stabilized more
   tightly than the production route, stop as `derivative_unqualified_test_only`.
4. A passing prototype requests only fresh Noether/Fisher/Rose review and a
   fresh owner decision on a revised F1 matrix. It does not reopen F1 itself
   and never authorizes F3.

## What Shinichi told us

- The next arc should be genuinely useful for roughly six hours, not padded
  after an early numerical stop.
- The desired strategic destination is Arc 6 completion, but the method must
  remain honest about the current F1 block.

## What the team raised

- **Noether:** include full Leibniz boundary and cross terms; the hard stop is
  unstable independent NB2 endpoint sensitivities.
- **Fisher:** preserve `derivative_unqualified_test_only` as evidence status,
  never runtime availability or SE evidence; even a pass only requests a fresh
  F1 decision.
- **Rose:** F1E must remain test-only in this association worktree, retain F1D
  as negative evidence, and explicitly exclude every F3/F4/public surface.

## Ada's recommendation

Run F1E in a **fresh Codex task but this same worktree/branch**. It is the
smallest six-hour programme that could retire the decisive block. A new lane
would duplicate the same association subject; executing here in the current
long task would violate the fresh-task boundary after a meaningful milestone.

## Questions still open and approval fence

**Approval requested:** authorize F1E only as written: test-only symbolic and
prototype work for the private B×NB2 derivative oracle, followed by a retained
receipt and fresh review. This does not authorize a production kernel change,
F1 reopening, F3 smoke, refits, simulation/bootstrap, remote compute,
`vcov()`, `confint()`, profiles, public docs, ledger movement, Arc D/F5,
slopes/other pairs, or direct `rho12`.

**External evidence:** no novelty or public claim is planned, so a new
NotebookLM literature sweep is not required. If Shinichi wants one, commission
it before prototype implementation to search specifically for stable discrete
copula rectangle-derivative methods.

## Completion and handoff

**Done when:** the plan's 360 minutes have been used on completed rungs, or a
named hard stop yields a non-empty receipt. F1E may end either `STOPPED` or
`READY FOR FRESH F1 REVIEW`; neither is F3 authorization.

**LANE: START A FRESH TASK.** Same worktree and same association branch; the
current F1D milestone is closed and D-80 requires a fresh task before the
distinct F1E arc.

**Copy-ready next-task prompt:**

```text
Continue Arc 6 F1E in /Users/z3437171/.codex/worktrees/663a/drmTMB on
codex/arc6-association-public-prep-f0f2. Read AGENTS.md, then
docs/dev-log/2026-07-26-arc6-f1e-derivative-oracle-redesign-ultra-plan.md and
the F1D receipt. Execute only after approval: private/test-only analytic
moving-endpoint derivative-oracle redesign for fixed-effect complete-pair
Bernoulli × ordinary-NB2. F1D remains negative; do not relax tolerances or
reopen F1/F3. Do not touch Arc D/F5, public APIs, ledger, refits/simulations,
remote compute, other pairs/slopes, or direct biv_lognormal rho12.
```
