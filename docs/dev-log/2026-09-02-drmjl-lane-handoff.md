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

> Quoted verbatim from design 258 §7.1–7.3 (branch `claude/rev-parity-c2-label-producer` @ `af1790492`,
> on origin; this supersedes the earlier quote at 5b77eb691 — the producer was repaired after an
> adversarial pass: fixed-effect-only label construction, unconditional map-path cross-check,
> no-vacuity rule, legacy predict path scoped):

### 7.1 Payload: `coef_labels`

`drm_julia_bridge_payload()` (`R/julia-bridge.R`) now sends an additional
top-level field, alongside the existing `formula`/`data`/`tree`/`options`:

```
coef_labels: list, keyed by dpar (e.g. "mu", "sigma", "mu1", "rho12", ...)
  each element: character vector, base-R model.matrix() column order
```

Built by `drm_julia_bridge_payload_coef_labels(formula, data, env)`: for each
`formula$entries` entry whose `dpar` is one of `julia_bridge_supported_dpars()`,
the RHS is first reduced to its FIXED-EFFECT-ONLY part with
`drm_strip_structured_terms(entry$rhs)` (`R/julia-bridge.R`) -- the SAME
reduction `drm_julia_predict_design()` already applies at predict time, so the
producer and `predict()` build the design from ONE definition, not two.
`drm_strip_structured_terms()` drops structured markers (`phylo()`,
`spatial()`, `relmat()`, `animal()`), lme4-style random bars (`(1 | g)`,
`(1 + x | g)`), and known-covariance `meta_V()`/`meta_known_V()` markers,
leaving only population-level fixed-effect terms. It then forms `~ <reduced
rhs>` with the SAME `data` (the already row-ordered, column-subset `data_out`
the rest of the payload marshals) and `env`, runs `stats::model.frame()` then
`colnames(stats::model.matrix(stats::terms(mf), mf))`, and stores the result
under that dpar's key.

**Every supported dpar is labelled, even one carrying a structured or
random-effect term** -- earlier drafts of this section (pre-Rose-S9) skipped
a dpar entirely whenever `entry$structured` was non-empty, which (a) silently
left a phylogenetic mean block permanently unlabelled (a bare `(1 | g)`
random-intercept term is not even recorded in `entry$structured` at all, so
it was NOT skipped by that rule either, and reached `stats::model.matrix()`
directly, which misparses `|` as the logical-OR operator and fabricates a
column such as `"1 | gTRUE"` -- Rose S9 attack A2b, the most serious of the
seven refutations). Neither failure mode is possible once every dpar's RHS is
reduced through `drm_strip_structured_terms()` before it ever reaches
`model.matrix()`. A dpar is omitted from `coef_labels` only when the (already
fixed-effect-reduced) model matrix errors to build -- an `sd(group)` /
`sd_phylo(group)` location-scale-scale grouping formula is still excluded up
front, since its dpar NAME itself does not match `julia_bridge_supported_dpars()`.
These are precisely drmTMB's own `coefficient_labels()` column names
(`R/methods.R`), minus the `"<dpar>:"` prefix that function adds afterwards --
i.e. `coef_labels$mu` for `y ~ x + I(x^2)` is `c("(Intercept)", "x", "I(x^2)")`,
matching row 1 of §2 exactly.

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

### 7.3 R-side rule after the call (S3, repaired after Rose S9)

`new_drmTMB_julia()` (`R/julia-bridge.R`), immediately after computing
`public_coef_labels <- drm_julia_bridge_coef_labels(result)`, resolves
`coef_names` (from the validated map's `public` when present, otherwise the
engine's own raw `result$coef_names`), and THEN calls
`drm_julia_bridge_check_coef_labels(coef_names, bridge_payload)`
UNCONDITIONALLY on both paths -- Rose S9 attacks A3/A3c showed that a
validated, self-consistent `bridge_formula_labels_v1` map is necessary but
not sufficient: nothing in §7.2's validator ties the public name ORDER, or
the public names THEMSELVES, to drmTMB's own `model.matrix()` spelling, so a
permuted map (A3, the intercept's coefficient value gets the wrong name) or a
map whose public names drmTMB never produced (A3c, e.g. `"mu_beta_one"`) both
validated cleanly under the old map-path-skips-the-comparison logic. **D-202:
base-R spelling wins even over an engine that supplies a validated map** --
the map's INTERNAL consistency and its AGREEMENT with drmTMB's own labels are
two separate checks, and both must hold.

`drm_julia_bridge_check_coef_labels(coef_names, bridge_payload)`:

- If `bridge_payload` carries no `coef_labels` field at all (the field is
  entirely ABSENT, not merely empty -- true for every route whose payload
  builder is not `drm_julia_bridge_payload()`, see §7.4), the check is a
  no-op. This is the only remaining "not checked" case, and it is
  structural (a different payload builder), not per-dpar.
- If `coef_labels` IS present but empty (zero dpars labelled) on a payload
  that DOES carry the field -- i.e. the main bridge -- this is an internal
  invariant failure, not a DRM.jl problem, and aborts:
  `"No coefficient labels were built for this Julia-engine fit; report this
  (an internal invariant failure in the drmTMB Julia bridge, not a DRM.jl
  problem)."` (Rose S9 attack A1; previously this silently returned `NULL`.)
- Otherwise, every FIXED-EFFECT dpar block the ENGINE actually returned is
  identified from `coef_names` via `drm_julia_split_coef_name()`, EXCLUDING
  the variance-component prefixes `drm_julia_bridge_variance_component_prefixes()`
  returns -- `"resd_"` (random-effect SD), `"recov_"` (residual correlation),
  `"phylocov_"` (phylogenetic among-axis covariance Cholesky entries) -- the
  SAME three prefixes `new_drmTMB_julia()`'s `structured_coef` filter already
  uses to separate non-fixed-effect working parameters out of the coefficient
  table. For each such engine dpar:
  - If it has NO entry in the payload's `coef_labels`, that ABORTS (Rose S9
    attack A5; previously the loop iterated only `names(coef_labels)`, so an
    engine dpar the payload never labelled -- exactly the phylo-mu case
    §7.1 now fixes at the source -- passed by vacuity).
  - If it has an entry, `drm_julia_split_coef_name(coef_names)$term` for that
    dpar must be `identical()` (exact strings, exact order) to
    `coef_labels[[dpar]]`.

  If every checked dpar matches and none is missing, the fit proceeds
  unchanged (this is what keeps plain-term bridge fits, e.g. §2 row for
  `- term`, working exactly as before, and what lets a correctly-echoed
  `bridge_formula_labels_v1` map still pass through). Otherwise it
  `cli::cli_abort()`s, naming DRM.jl explicitly and listing, per problem
  dpar, either the missing-label notice or drmTMB's expected column names
  against what DRM.jl returned:

  > "DRM.jl returned coefficient names that do not match drmTMB's base-R
  > `model.matrix()` spelling." followed by one bullet per problem dpar --
  > either `"no payload label was built for fixed-effect dpar(s): <dpars>."`
  > or `"<dpar>: drmTMB expects (<names>); DRM.jl returned (<names>)."` -- and
  > a hint: "DRM.jl must supply `bridge_formula_labels_v1` (design 258 §7)
  > for this formula construct, or its raw names must equal drmTMB's own
  > base-R spelling exactly."

No punctuation is stripped, guessed, or translated anywhere in this path --
`drm_julia_bridge_check_coef_labels()` performs only an `identical()` string/
order comparison of two already-final name vectors, never a `gsub()` on
`__bridge_*` or `&`-joined names (§3's binding constraint). The ONLY
punctuation rewrite remaining anywhere in `R/` is the LEGACY predict-time path
described in §7.4.

What DRM.jl's half needs (`src/bridge.jl`: `_bridge_coef_vector` ~lines 937-953 produces the raw
names, and `coef_label_contract = "bridge_formula_labels_v1"` is already emitted at ~line 1276 on
origin/main, so the structure exists and only its CONTENT changes): read the payload's per-dpar
public names; return `bridge_formula_labels_v1` in the engine's own column order, pairing each raw
synthetic name with the public name it was given for that column. The R side now REJECTS a map whose
public names are not exactly drmTMB's own (a permutation or an invented name aborts), so the echo
must preserve drmTMB's spelling and per-dpar order. No string translation on either side.

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

## 5. q4 REML SE receipt: TMB SEs delivered; the Julia SE axis is the fixture's recorded fence

The same-draw SE receipt you asked for exists — drmTMB branch `claude/rev-parity-q4-se-receipt`
@ `996870366`, files `docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-02-q4-se-receipt.{md,R}`,
engine pinned to `cda42b8c`. Coefficients and log-likelihood agree (tmb −219.613986 vs julia
−219.614005, |Δ| 1.9e-05; both converged; 7/7 coefficient names matched after canonicalising the
`.`/`:`/`_` separators). TMB's Wald SEs are all finite (`sdr$pdHess = TRUE`) and are tabulated
per coefficient. The bridge's `vcov()` on this route is all-NaN, self-reported as
`uncertainty$status = "unavailable"` — **this is the fixture's RECORDED fence, not a new defect**
(`expected.toml:22`: `interval_status = "wald_unavailable"`; Wald calibration on q4
phylo-covariance is DRM.jl #495). Correction from the DRM.jl lane, 2026-09-02, adopted here: the
`rtol_coef`/`atol_coef` re-derivation (C10) was always sized from drmTMB's OWN Wald SEs refit on the
committed data, so this receipt **unblocks** C10 rather than blocking it. What stays true:
`biv_q4_phylo_reml` cannot be promoted on the SE axis while the Julia side is fenced; the receipt
promotes nothing and edits no TSV.

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
