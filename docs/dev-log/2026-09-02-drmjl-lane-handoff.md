# Handoff to the DRM.jl lane — from drmTMB's reverse-parity lane, 2026-09-02

**Reader:** the Claude DRM.jl lane (session DRM.jl3 today, or its successor task). Ownership settled
the same morning (Shinichi via that session, vault D-203, with one supersession: no Codex or Cursor
lane is running; the remaining DRM.jl-side #563 slices, including the Julia half of the label
contract, are carried by the Claude DRM.jl lane in a fresh task, resuming the codex ledger rather
than rebuilding it). The DRM.jl-side durable record is vault D-203 plus the DRM.jl decision map
`docs/dev-log/plans/2026-09-02-true-parity-decision-map-drmjl.md` (branch `docs/true-parity-decision-map`),
which cites drmTMB's design 258 §7 by SHA; there is no separate Codex handover document. This memo is
the R-side record either lane can cite. Shinichi has approved src/ edits PR-gated
(RED test first, Noether + Rose review, he merges) for the `src/bridge.jl` label-map echo. **Purpose:** four items drmTMB cannot do from its side. Nothing here was
applied to DRM.jl; this lane only reads that repository. Owner decisions cited: vault D-202
(2026-09-02) and D-179/D-181. Coordination messages exchanged the same morning are summarised at
the end so nothing lives only in chat.

## 1. Echo the coefficient-label map: `bridge_formula_labels_v1`

**Decision (Shinichi, 2026-09-02):** canonical coefficient names are **base-R spelling**; drmTMB is
authoritative and DRM.jl's fixtures translate. drmTMB now sends the public names in the bridge
payload and validates what comes back with the existing validator in
`R/julia-coefficient-labels.R`; when the engine returns **no map** and its raw names differ from
the payload's names, the R side **aborts** naming DRM.jl (fail-closed; plain numeric terms whose
names already coincide keep working). The exact contract, quoted from drmTMB
`docs/design/258-coefficient-naming-contract.md` §7 (branch `claude/rev-parity-c2-label-producer`):

> Quoted verbatim from design 258 §7.1–7.2 (branch `claude/rev-parity-c2-label-producer` @ `5b77eb691`,
> on origin):

### 7.1 Payload: `coef_labels`

`drm_julia_bridge_payload()` (`R/julia-bridge.R`) now sends an additional
top-level field, alongside the existing `formula`/`data`/`tree`/`options`:

```
coef_labels: list, keyed by dpar (e.g. "mu", "sigma", "mu1", "rho12", ...)
  each element: character vector, base-R model.matrix() column order
```

Built by `drm_julia_bridge_payload_coef_labels(formula, data, env)`: for each
`formula$entries` entry whose `dpar` is one of `julia_bridge_supported_dpars()`
and whose `entry$structured` is empty (no phylo / random-effect / `sd(...)`
term anywhere in that entry's RHS), it forms `~ <rhs>` with the SAME `data`
(the already row-ordered, column-subset `data_out` the rest of the payload
marshals) and `env`, runs `stats::model.frame()` then
`colnames(stats::model.matrix(stats::terms(mf), mf))`, and stores the result
under that dpar's key. A dpar is silently absent from `coef_labels` when it
carries a structured term, or when building the model matrix errors --
neither case is a plain fixed-effect coefficient block this contract covers
in its first cut (design doctrine: keep first implementations simple before
adding random effects). These are precisely drmTMB's own `coefficient_labels()`
column names (`R/methods.R`), minus the `"<dpar>:"` prefix that function adds
afterwards -- i.e. `coef_labels$mu` for `y ~ x + I(x^2)` is
`c("(Intercept)", "x", "I(x^2)")`, matching row 1 of §2 exactly.

### 7.2 Echo: `bridge_formula_labels_v1`

This is DRM.jl's half to implement -- not built by this slice, but specified
here precisely enough to build against, transcribed directly from the
EXISTING validator `drm_julia_bridge_coef_labels()` (`R/julia-coefficient-labels.R`,
unchanged by S3) rather than invented fresh. To supply a map, a fitted
`result` must set ALL of:

| Field | Type | Meaning |
|---|---|---|
| `coef_label_contract` | scalar string, exactly `"bridge_formula_labels_v1"` | version tag |
| `coef_names` | character vector, length *n*, no NA/empty/duplicates | the **public** names, base-R spelling, `"<dpar>_<term>"` (underscore-joined -- e.g. `"mu_I(x^2)"`, matching `coef_labels$mu` term-for-term with the dpar re-prefixed with `_`), in the SAME order as `coefficients`/`vcov` |
| `raw_coef_names` | character vector, length *n*, no NA/empty/duplicates | the **raw** synthetic names DRM.jl actually computed internally (e.g. `"mu___bridge_I_1"`), same length as `coef_names` |
| `coef_name_map` | named list or named character vector, length *n* | keys = every `coef_names` entry (as a set, order-free); values = the paired `raw_coef_names` entry for that key, so that `map[coef_names]` reproduces `raw_coef_names` in `coef_names`' order |
| `vcov_names` | character vector | must be `identical()` to `coef_names` (covariance axis order matches the public name order) |
| `coefficients`, `vcov` | as already returned | lengths/dimensions must match *n* |

The validator additionally requires `drm_julia_split_coef_name(coef_names)$dpar`
to equal `drm_julia_split_coef_name(raw_coef_names)$dpar`
element-for-element -- i.e. the public/raw pairing must agree on which dpar
block each coefficient belongs to, even though the term spelling differs.
`drm_julia_split_coef_name()` (`R/julia-bridge.R`) matches the LONGEST known
block prefix from `drm_julia_bridge_blocks()`, so `"mu_I(x^2)"` splits to
dpar `"mu"`, term `"I(x^2)"`.

**Failure text** (`drm_julia_bridge_coef_labels()`, unchanged): on any
inconsistency it calls `stop("Invalid Julia coefficient label metadata: ",
what, call. = FALSE)`, where `what` is one of, in check order: `"unknown
contract"`, `"missing or duplicate labels"`, `"incomplete label map"`,
`"invalid map values"`, `"map order or coefficient identity mismatch"`,
`"coefficient block mismatch"`, `"covariance label order mismatch"`,
`"coefficient coverage mismatch"`, `"covariance dimensions mismatch"`,
`"covariance axes mismatch"`. This is the exact, already-shipping validator;
S3 adds no new echo-side checks.

The R-side rule after the call (§7.3, implemented): a returned map is validated by the existing
validator and its `public` names are used; NO map + raw names byte-identical to `coef_labels` → the
fit proceeds unchanged (plain numeric terms keep working); NO map + differing names → abort naming
DRM.jl and listing the dpar/columns that differ. No `gsub()`/regex on engine names anywhere in R/
(the legacy predict-time rewrite was removed on the same branch).

What DRM.jl's half needs (`src/bridge.jl`: `_bridge_coef_vector` ~lines 937-953 produces the raw
names, and `coef_label_contract = "bridge_formula_labels_v1"` is already emitted at ~line 1276 on
origin/main, so the structure exists and only its CONTENT changes): read the payload's per-dpar public names; return
`bridge_formula_labels_v1 = {public, raw, vcov_names}` in the engine's own column order, pairing
each raw synthetic name (`__bridge_I_1`, `__bridge_factor_1: lo`, `mu_x & z`, …) with the public
name it was given for that column. No string translation on either side — design 258 §3 forbids
punctuation guessing, and its row 7 (reversed two-factor interaction) shows why: the two sides can
disagree on interaction-term ORDER even after names match, and only an explicit map catches that.

## 2. Re-key the bridge fixtures to base-R names

`test/parity/gen_bridge_formula_fixtures.R` carries a hand-written `name_map` (lines ~149-270)
mapping R names → bridge names per fixture, and `compare_bridge` fails 6/7 constructs on those keys
(DRM.jl#467). Under the decision above, `expected.toml` keys stay the base-R names drmTMB emits
(they already come from a real drmTMB fit) and the map's job moves into the echoed
`bridge_formula_labels_v1`. Acceptance: `runparity_bridge_formula.jl` cohort 7/7 with
`DRM_PARITY_TESTS=1`. Note the second drift source design 258 records: factor levels rendered
`10.0`/`20.0` on the Julia side versus R's `10`/`20` (Vector{Any} numeric-as-string parsed as float).

## 3. `docs/src/capabilities.md:278-281` is stale

It still says there is no missing-response code path; `test/test_lss_missing_response.jl` and #559
(merged) contradict it. Found while comparing the twins on 2026-09-02; recorded here, not edited.

## 4. Fate of `feat/575-objective-at` (`reml_objective_at`, dc3ce190)

drmTMB's slice A4 (the R wrapper `drm_julia_reml_objective_at()`, design in
`objective-at-bridge-note.md` on PR #1112) needs that primitive **reachable from a merged ref**.
Either fold it into #579 or open its own PR; drmTMB's A4/A5 are HELD until it is on a ref we can pin.

## 5. q4 REML: Julia `vcov()` is all-NaN on the committed fixture (found by the SE receipt)

The same-draw SE receipt you asked for exists — drmTMB branch `claude/rev-parity-q4-se-receipt`
@ `996870366`, files `docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-02-q4-se-receipt.{md,R}`,
engine pinned to `cda42b8c`. Coefficients and log-likelihood agree (tmb −219.613986 vs julia
−219.614005, |Δ| 1.9e-05; both converged; 7/7 coefficient names matched after canonicalising the
`.`/`:`/`_` separators). **But the SE axis cannot be compared:** the bridge's `vcov()` for this
`biv_gaussian` q4-phylo REML route returns an all-NaN fixed-effect covariance, self-reported as
`uncertainty$status = "unavailable"`, while TMB's Wald SEs are all finite (`sdr$pdHess = TRUE`).
Consequences for you: the `rtol_coef` re-derivation cannot be taken from a Julia SE on this fixture
until DRM.jl's q4 REML route supplies a covariance; and `biv_q4_phylo_reml` stays out of any
promotion wave on the SE axis. The receipt promotes nothing and edits no TSV.

## What drmTMB is doing that touches you (no action needed)

- **q4 Wald-SE receipt** (your `rtol_coef = 10%` re-justification): drmTMB branch
  `claude/rev-parity-q4-se-receipt`, files
  `docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-02-q4-se-receipt.{md,R}`, engine
  pinned to `feat/575-exact-reml-gradient@cda42b8c` as you asked (not `main@f4778964`). Landed: see item 5.
- **#575 receipts** stay on `codex/rebase-julia-optimizer-controls` (PR #1112); #1112 lands first
  by owner decision, so your citation is stable.
- **Ordering:** `drm_control(start=, multi_start=)` under `engine = "julia"` will be **rejected**
  (not ignored) once #1112 and `claude/rev-parity-integration-post1112` land; nothing for you to
  translate.

## Messages exchanged 2026-09-02 (summary, for the record)

DRM.jl3 → drmTMB: closing #575 docs on PR #579; holds a lease on DRM.jl docs paths only; asked who
owns what and what is decided. drmTMB → DRM.jl3: lane list, decided/protected list, decision-map
pointer. DRM.jl3 → drmTMB: pin `cda42b8c` for the SE receipt; folded the naming decision and this
handoff surface into its replanning; holds no drmTMB lease.
