# Findings owed to the DRM.jl parity lane (session `DRM.jl2`) — 2026-09-01

From: the drmTMB reverse-parity lane (Claude), branches `claude/rev-parity-*`.
Status: **for that lane to act on or reject. Nothing here was acted on unilaterally**, and
nothing in DRM.jl was modified — that repository was read only, and our fence confirms its
working tree is byte-identical to the baseline we pinned at
`main` @ `f47789646f27221ba4fad29a8ba1b3b8a790b521`.

Four findings surfaced while building drmTMB's half of the diagnosis layer. Each is
evidenced, and each is cheap for us to state and expensive for that lane to rediscover.

---

## 1. The bridge design note's central premise does not hold

`docs/dev-log/evidence/julia-r-parity/ayumi-target/objective-at-bridge-note.md` (commit
`882b54dfc`) designs the R-side wrapper for `DRM.reml_objective_at` on the assumption that it
can reuse a fitted object's *"cached Julia-side `prob`/`Q_cond` handles rather than
re-marshalling data"*.

**There is no such cache.** Measured:

- `Q_cond` appears **nowhere** in the drmTMB repository (`git grep` returns nothing).
- `drm_julia_call_bridge()` (`R/julia-bridge.R:1024`) passes formula, data, tree and options
  into `DRM.drm_bridge` in a **single** `JuliaCall::julia_call`. Everything DRM.jl builds
  internally is discarded when that call returns.
- R retains only the flat result list, stored verbatim as `fit$bridge`
  (`R/julia-bridge.R:1963`). There is no handle, no precision object, no problem struct.

The note is otherwise sound; only this premise needs correcting, and the design it implies
(a thin wrapper over an existing cache) has to become something else — see finding 2.

## 2. The shim is reachable with zero DRM.jl edits — but only via two PRIVATE names

Answered by reading source, not by guessing. The q4 REML route builds its problem at
`src/gaussian_bivariate.jl:705`:

    Qdense        = _q4_structured_precision(kind, grp, G; K, A, coords, spatial_range)
    prob, Q_cond  = make_problem_from_Q(Qdense, y1, y2, X1, X2, Xs1, Xs2, Xr; group = gidx)
    rr            = fit_q4_reml(prob, Q_cond; beta0, Lambda0, g_tol, iterations, n_newton, lc_zero)

Against DRM.jl's own export list (`src/DRM.jl:146`):

| name | file | exported? |
|---|---|---|
| `make_problem_from_Q` | `src/sparse_em_fit.jl:57` | **no** |
| `_q4_structured_precision` | `src/gaussian_bivariate.jl:632` | **no** (leading underscore) |
| `reml_objective_at` | `src/reml_q4.jl:338` | yes (`src/DRM.jl:152`) |

Julia reaches non-exported names through the module prefix, so a second shim registered
**from R** — exactly the pattern `drm_julia_setup()` already uses for `drmTMB_drm_bridge` at
`R/julia-bridge.R:1774` — can rebuild the problem and call `reml_objective_at` with no edit to
DRM.jl at all.

**The ask.** We can build that, and we will if you prefer. But it couples drmTMB to two DRM.jl
private symbols that may be renamed without notice or deprecation, breaking us silently at
runtime rather than at build time. **A supported entry point taking `(payload, phi)` would
remove the coupling entirely.** DRM.jl#569 is already open on bridge-side diagnostics and looks
like the natural home. This is our request and your decision; we have not opened an issue.

## 3. The coefficient-label contract is half-built on BOTH sides, not just ours

DRM.jl#467's framing — 6 of 8 formula-construct parity cells failing on names alone — reads
like a translation defect on one side. Reviewing both sides says otherwise:

- drmTMB's `R/julia-coefficient-labels.R` is a **validator with nothing to validate**. It
  checks a `bridge_formula_labels_v1` map and explicitly declines to infer any term spelling
  itself ("the engine supplies an exact map").
- **No producer of that map exists** — not in drmTMB, and not in DRM.jl's `src/` either.

So whichever side is chosen as the naming authority, somebody still has to write the producer,
and that work is invisible in the issue's current framing. Our spec page enumerating ten
constructs, both candidate authorities, and a per-row breaking-change assessment is at
`docs/design/258-coefficient-naming-contract.md`. It **recommends** base-R spelling as
canonical and explicitly refuses to settle the question, because it is cross-repo governance.
Zero rows are confirmed breaking under drmTMB's native TMB engine; all ten `engine = "julia"`
rows are marked *cannot determine* rather than guessed, precisely because the producer is absent.

## ⚠ CORRECTION to finding 3, issued 2026-09-01 before this note was acted on

**Finding 3 above overstates the case on the DRM.jl side, and the overstatement is ours.**

It says no producer of the `bridge_formula_labels_v1` map exists "in DRM.jl's `src/` either".
**That is false.** `src/bridge.jl:1272-1279` on DRM.jl's `origin/main` emits exactly that map:

    out["coef_label_contract"] = "bridge_formula_labels_v1"
    out["raw_coef_names"]      = raw_cnames
    out["coef_name_map"]       = public_to_raw

and it is reached on the ordinary bridge routes — `_bridge_formula(formula, family, dat;
labels = true)` is called at `src/bridge.jl:55` and `:186`. A producer exists and runs.

**How the error happened, since the mechanism matters more than the claim.** A sub-agent
reported it; the coordinator verified the *easy* half of that report — the spec table's base-R
column, 7 of 7 rows reproduced exactly against `model.matrix()` — and did **not** verify the
*negative* claim. A negative existence claim is precisely the kind that needs checking, and the
verifiable part was checked instead. It was then relayed twice as established before an
adversarial pass caught it.

**What survives, stated narrowly.** drmTMB's `R/julia-coefficient-labels.R` is a validator, and
6 of 8 formula-construct parity cells still fail on names alone — those measurements are
unaffected. The open question is **not** "does a producer exist" but the sharper one: **is the
map populated, and correct, for the specific constructs that fail?** That is a better question
than the one finding 3 asked, and it belongs to your lane to answer.

**Do not act on finding 3 as originally written.**

## 3b. A SECOND, independent name-drift mechanism — float-coerced factor levels

Surfaced while specifying the constructs, and distinct from the `__bridge_*` materialisation
in finding 3. On the reversed two-factor interaction case, R's factor levels `10` and `20`
come back from the bridge as **`10.0` and `20.0`**: a `Vector{Any}` column of numeric-looking
values is parsed as `Float64` on the Julia side, so the level label itself is re-rendered.

That matters because it is not fixed by agreeing a naming authority. Even if both sides adopt
base-R spelling tomorrow, `factor(h)10` and `factor(h)10.0` still differ, and the mismatch
originates in *column parsing*, not in label translation. Whoever implements the fix needs both
mechanisms in view, and the second one is invisible in DRM.jl#467's current framing.

Verified independently on the R side: `model.matrix()` names for `I(x^2)`, `poly(x, 3)`,
`z * poly(x, 2)`, `(x + z)^2`, `scale(x)`, `I(+x)` and `I(x + (z + 2))` all reproduce exactly
as our spec table records them (7 of 7 checkable rows), so the base-R column of that table is
measured, not reconstructed.

## 4. Ayumi's limitation #7 may already be answered on our side

Her open limitation #7 is that a whole-tree q4 profile CI is impractical: DRM.jl's q4 profile
runs only when *all* SD targets are requested together, her 343-tip run was terminated past
2 h, and unbounded upper endpoints came back.

drmTMB exports **`profile_targets(fit)`** — a per-coefficient readiness inventory
(`parm, param, index, estimate, scale, profile_ready, profile_note`) that **runs no
optimization**. It is close to what that limitation asks for, and it is already shipped.

We are not proposing code. This looks like a **reply to write**, and the Ayumi drafts belong to
your lane, so we are handing it over rather than drafting it.

---

## What we did NOT do

No edit, PR, issue or comment in DRM.jl. No bridge-route promotion, no `r_bridge_status`
change, no `inst/extdata/julia-capabilities.tsv` row touched, no work on #575's optimum fix,
the scoreboard, the Parity Standing artifact, or the Ayumi reply drafts — all of which are
yours. Nothing merged to drmTMB `main`. D-164's hold on the CRAN release is untouched.
