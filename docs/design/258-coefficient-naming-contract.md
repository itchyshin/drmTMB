# 258 — Coefficient-naming contract between drmTMB and DRM.jl

Status: **specification only**. No R code changed. Implementation is deliberately
deferred until the authority question below is settled (see "NOT decided here").

## 1. The problem, as measured

The gated `engine = "julia"` bridge parity suite in DRM.jl
(`test/parity/runparity_bridge_formula.jl`, cohort `_BRIDGE_FORMULA_COHORT`)
currently reads **1 pass / 6 fail** when run with `DRM_PARITY_TESTS=1`:

- `bridge-minus-term` — **passes**.
- `bridge-I`, `bridge-factor`, `bridge-poly`, `bridge-poly-cross`, `bridge-power`,
  `bridge-scale` — **fail**.

Source: DRM.jl issue #467, comment 5501007899.

The failures are **coefficient-NAME mismatches only** — `compare_bridge` compares
`out` (what `drm_bridge` actually names its columns) against `expected`
(`expected.toml`, generated from drmTMB's own `coef()`/`vcov()` names via an
explicit `name_map`, see `test/parity/gen_bridge_formula_fixtures.R`). The
numeric coefficient values and vcov entries are not in dispute; only the string
keys used to look them up differ, so every construct except plain term removal
(`- term`, which introduces no synthetic column) fails to match by name. `vcov`
axis-ordering failures are downstream of the same name mismatch, not a separate
numerical problem.

Because the suite is gated behind `DRM_PARITY_TESTS=1`, it is not part of CI,
and this drift was invisible until someone ran it by hand.

A second, independent thread of prior work
(`docs/dev-log/evidence/julia-r-parity/coefficient-labels/CHECK-EXPECT.md` and
`RESULT.md`, branch `origin/codex/rebase-julia-optimizer-controls`) built a
bounded, non-shipping oracle that reproduces the same underlying gap for a
wider set of ten model-matrix constructs plus four base-R spelling-precedent
cases, and sketched (but did not land) a `bridge_formula_labels_v1` public/raw
name-map contract. **DRM.jl's `src/` does not currently implement or emit
`coef_label_contract` / `bridge_formula_labels_v1` for `drm_bridge` at all** —
grep across DRM.jl's tracked `.jl` sources for `coef_label_contract`,
`bridge_formula_labels_v1`, and `coef_name_map` returns nothing. On the R side,
`R/julia-coefficient-labels.R`'s `drm_julia_bridge_coef_labels()` and
`drm_julia_public_inference_term()` are validators for that map — they check it
is well-formed and self-consistent, but they do not construct it, and they are
presently unreachable because no fit ever populates
`object$bridge_public_coef_labels`. drmTMB's own
`coefficient_labels()` (`R/methods.R`, `coefficient_labels <- function(object)`,
at line 6061) is unconditional pass-through:

```r
coefficient_labels <- function(object) {
  unlist(
    lapply(names(object$coefficients), function(dpar) {
      paste0(dpar, ":", names(object$coefficients[[dpar]]))
    }),
    use.names = FALSE
  )
}
```

`names(object$coefficients[[dpar]])` comes straight from
`colnames(stats::model.matrix(...))`. There is no canonicalisation step
anywhere in R today.

## 2. Construct table

Columns: what base-R `model.matrix()`/`coef()` names the term today (drmTMB's
own spelling, taken from `gen_bridge_formula_fixtures.R`'s `name_map` LHS and
the `public-004.json` `expected` oracle for the four later cases); what
`drm_bridge` emits today (the RHS of that same `name_map`, i.e. DRM.jl's actual
column names, taken from `runparity_bridge_formula.jl`'s failing fixtures and
`public-004.json`'s `labels.raw`); and a **proposed** canonical name. The
canonical column is a proposal for this document, not a decision — see §3–4.

| # | Construct | Formula fragment | Base-R name (drmTMB today) | DRM.jl `drm_bridge` name (today) | Proposed canonical name |
|---|---|---|---|---|---|
| 1 | `I()` | `y ~ x + I(x^2)` | `mu:I(x^2)` | `mu___bridge_I_1` | `mu:I(x^2)` |
| 2 | `factor()` | `y ~ factor(grp)` | `mu:factor(grp)lo`, `mu:factor(grp)mid` | `mu___bridge_factor_1: lo`, `mu___bridge_factor_1: mid` | `mu:factor(grp)lo`, `mu:factor(grp)mid` |
| 3 | `poly()` | `y ~ poly(x, 3)` | `mu:poly(x, 3)1`, `mu:poly(x, 3)2`, `mu:poly(x, 3)3` | `mu___bridge_poly3c1_1`, `mu___bridge_poly3c2_2`, `mu___bridge_poly3c3_3` | `mu:poly(x, 3)1`, `mu:poly(x, 3)2`, `mu:poly(x, 3)3` |
| 4 | crossed `poly()` | `y ~ z * poly(x, 2)` | `mu:z:poly(x, 2)1`, `mu:z:poly(x, 2)2` (plus main effects) | `mu_z & __bridge_poly2c1_1`, `mu_z & __bridge_poly2c2_2` | `mu:z:poly(x, 2)1`, `mu:z:poly(x, 2)2` |
| 5 | powers `(...)^k` | `y ~ (x + z)^2` | `mu:x:z` | `mu_x & z` | `mu:x:z` |
| 6 | `scale()` | `y ~ scale(x)` | `mu:scale(x)` | `mu___bridge_scale_1` | `mu:scale(x)` |
| 7 | reversed two-factor interaction | `~ g + factor(h) + factor(h):g` | `(Intercept)`, `gb`, `gc`, `factor(h)20`, `gb:factor(h)20`, `gc:factor(h)20` (6 columns, reduced coding — CORRECTED 2026-09-02: an earlier version of this row listed 9 names with full dummy coding of `factor(h)` inside the interaction; base R does not do that when both main effects are present, measured independently by the drmTMB and DRM.jl lanes) | DRM.jl (StatsModels) renders exactly these 6 names in this order (DRM.jl lane, 2026-09-02) | `mu:` + the base-R column |
| 8 | unary-plus arithmetic | `~ I(+x)` | `I(+x)` | `__bridge_I_1` | `mu:I(+x)` |
| 9 | explicitly parenthesised arithmetic | `~ I(x + (z + 2))` | `I(x + (z + 2))` | `__bridge_I_1` | `mu:I(x + (z + 2))` |
| 10 | decimal-spelled integer exponent | `~ I(x^2)` | `I(x^2)` | `__bridge_I_1` | `mu:I(x^2)` |

Notes on the table:

- Rows 1–6 are the six DRM.jl parity failures named in the problem statement;
  their base-R/bridge pair is read directly from the committed
  `name_map` in `gen_bridge_formula_fixtures.R` (lines 148–279), which is
  itself generated from a real `drmTMB()` fit's `coef()`/`vcov()` names, so
  these are not reconstructed from memory.
- Rows 7–10 are the four cases added later per `CHECK-EXPECT.md`'s "Review
  expansion before public004" section; their base-R (`expected`/`actual`) and
  bridge (`labels.raw`) spellings are read from
  `public-004.json` in the `codex/rebase-julia-optimizer-controls` evidence
  branch (an independent, non-shipping oracle, not `drm_bridge` itself —
  flagged explicitly in §5).
- Every `drm_bridge` name in the table uses the synthetic
  `__bridge_<kind>_<n>` materialised-column convention for `I()`, `scale()`,
  `poly()`, and `factor()`, and StatsModels' `x & z` (space-padded `&`) for
  interactions, in place of R's `:`. Row 7's factor levels are also rendered
  as `10.0`/`20.0` (float-coerced) rather than R's bare `10`/`20`, because
  `Vector{Any}` numeric-as-string columns get parsed as floats on the Julia
  side — a second, independent source of name drift beyond the `__bridge_*`
  materialisation itself, worth noting for whoever implements the fix.
- The "proposed canonical name" column reuses the base-R spelling with the
  `mu:`/`sigma:`/… prefix drmTMB already applies via `coefficient_labels()`.
  This follows candidate (a) in §3 below; it is a proposal for discussion, not
  an adopted answer — see §3–4.

## 3. The binding constraint already in force: no punctuation-based guessing

`R/julia-coefficient-labels.R`'s header states it plainly: "No term spelling is
inferred from synthetic ordinals or punctuation: the engine supplies an exact
map." `drm_julia_bridge_coef_labels()` and `drm_julia_public_inference_term()`
enforce this — they validate a versioned map (`bridge_formula_labels_v1`) for
completeness, uniqueness, order-consistency between `public`/`raw`/`vcov_names`,
and per-`dpar` block agreement, and they hard-`stop()` on any inconsistency
rather than falling back to a guess. `CHECK-EXPECT.md` restates the same rule:
"Corrupt versioned metadata must fail before Julia startup; no
punctuation-based guessing is permitted."

Why this constraint is load-bearing rather than pedantic: a regex or
string-substitution translator built against the six failing constructs in §2
(strip `__bridge_<kind>_<n>`, replace ` & ` with `:`, replace `: ` with no
space) would look complete after those six pass. (Row 7's name LIST in §2 was corrected on
2026-09-02 to base R's six reduced-coding columns; the order evidence quoted here is from the
earlier `public-004.json` oracle and stands as recorded.) Row 7 (reversed two-factor
interaction) already shows why that is not safe — the same `__bridge_factor_1`
materialisation appears on both sides of an interaction with the level
rendered as `10.0` rather than `10`, and `public-004.json`'s own `expected`
vs `actual` diff for that case shows the two sides *disagree on interaction
term ORDER* (`gb:factor(h)10` before `gc:factor(h)10` in `expected` vs
`gb:factor(h)10` before `gb:factor(h)20` in `actual`) even after name
translation — a class of error a spelling-only guesser would not catch, and
would not know it had gotten wrong, on a case outside its original six. A
punctuation guess that passes on the constructs it was tuned against is
exactly the failure mode the existing validator was built to refuse silently
propagating; the fix belongs in an exact map the engine supplies, not in a
heuristic string translator on either side.

## 4. The two candidate authorities

**(a) Base-R spelling wins.** drmTMB's `coefficient_labels()` output (what
`summary()`, `coef()`, `fixef()`, `confint()`, and `vcov()` dimnames already
show an R user) becomes the contract's `public` name. DRM.jl's fixtures in
`expected.toml` change their keys to match, and `drm_bridge` gains a
translation layer that maps its synthetic `__bridge_*`/`&`-joined internal
names back to R's own spelling before returning results across the bridge.

*For*: R users already see base-R spelling in every existing output surface —
adopting it changes nothing they currently read. Usability is the principle
this project does not bend on (project doctrine, `AGENTS.md`); a user who
writes `poly(x, 3)` in a `drm_formula()` and later reads `poly(x, 3)1` in
`summary()` should not need to learn a second, Julia-internal spelling
(`__bridge_poly3c1_1`) to interpret a `engine = "julia"` fit's output — the
engine choice is meant to be invisible in output shape, per the pkgdown
positioning of `engine = "julia"` as a backend switch, not a different
package.

*Against*: DRM.jl's fixtures encode real, already-verified work — every
`expected.toml` in `test/parity/fixtures/bridge-*` was generated from an
actual byte-identical drmTMB fit (see `gen_bridge_formula_fixtures.R`'s
`write_bridge_fixture()`), and changing what they assert re-opens numerical
review of files that already passed. It also does not remove the underlying
translation problem, only moves which side has to solve it: `drm_bridge` still
needs an internal map from its synthetic columns back to R spelling, which is
nontrivial for the same reasons row 7 shows (interaction order, factor-level
type coercion).

**(b) DRM.jl's translated map wins.** `drm_bridge`'s current
`__bridge_<kind>_<n>` / `x & z` spelling becomes the contract's `public` name,
and drmTMB's Julia-engine code path translates its own `coefficient_labels()`
output to match before returning to the user — i.e. an `engine = "julia"` fit's
`summary()` would show `I(x^2)` translated to something like
`mu___bridge_I_1` (or a cleaned variant of it), diverging from what the same
formula shows under the native TMB engine.

*For*: DRM.jl's fixtures stay untouched; no re-verification of already-checked
numeric evidence is needed on the Julia side; the synthetic-column names are
also arguably more information-preserving in one respect — `__bridge_poly3c1_1`
records the term-and-column *provenance* (which named term, which sub-column)
in a way `poly(x, 3)1` alone does not carry as unambiguously across two
different formula parsers.

*Against*: this directly breaks the invisible-engine-swap premise — the same
formula fit under `engine = "TMB"` vs `engine = "julia"` would show two
different coefficient vocabularies in `summary()`/`coef()`/`confint()`, which
is a much larger and more visible break to users than any single row in §5,
and it pushes the translation work onto every drmTMB output function that
currently trusts `coefficient_labels()`'s pass-through spelling.

**Recommendation**: (a), base-R spelling wins, on usability grounds — but this
is a cross-repo governance call between drmTMB and DRM.jl fixture ownership,
**not decided unilaterally by this document, nor by its author**. See §6.

## 5. Breaking-change assessment

Per construct in §2, would adopting the proposed canonical name (§2's last
column, i.e. candidate (a)) change a name a drmTMB user currently sees in
`summary()`, `coef()`, `fixef()`, `confint()`, or `vcov()` dimnames?

| # | Construct | Changes a name already shown under `engine = "TMB"` (native)? | Changes a name currently shown under `engine = "julia"`? |
|---|---|---|---|
| 1 | `I()` | No | **Cannot determine** — flagged below |
| 2 | `factor()` | No | **Cannot determine** — flagged below |
| 3 | `poly()` | No | **Cannot determine** — flagged below |
| 4 | crossed `poly()` | No | **Cannot determine** — flagged below |
| 5 | powers `(...)^k` | No | **Cannot determine** — flagged below |
| 6 | `scale()` | No | **Cannot determine** — flagged below |
| 7 | reversed two-factor interaction | No | **Cannot determine** — flagged below |
| 8 | unary-plus arithmetic | No | **Cannot determine** — flagged below |
| 9 | explicitly parenthesised arithmetic | No | **Cannot determine** — flagged below |
| 10 | decimal-spelled integer exponent | No | **Cannot determine** — flagged below |

Reasoning for the "No" column: `coefficient_labels()` and every caller of
`names(object$coefficients[[dpar]])` read directly off
`colnames(stats::model.matrix(...))` (`R/methods.R`, `coefficient_labels()`
and its callers at lines 2336, 4410, 5234). None of that code path consults
`object$bridge_public_coef_labels` or any Julia-supplied map; adopting
candidate (a) as the *bridge's* contract changes nothing about what a
native-TMB fit's `model.matrix()`-derived names already are, because (a) by
construction sets the canonical name equal to that same base-R spelling. This
is read directly from the code, not inferred.

Reasoning for the "**Cannot determine**" column: this document could not
locate a shipping, non-gated `engine = "julia"` fit path in `drmTMB` whose
`summary()`/`coef()`/`confint()`/`vcov()` output currently exposes any of
these ten constructs' coefficient names end-to-end, because (as established in
§1) `object$bridge_public_coef_labels` is never populated by any code this
document found — `drm_julia_bridge_coef_labels()` and
`drm_julia_public_inference_term()` are validators with no current producer.
Whether an `engine = "julia"` fit today shows `__bridge_I_1`-style raw names,
base-R names via some other translation this review did not find, or refuses
these constructs outright, was not established by reading `R/julia-coefficient-labels.R`
and `R/methods.R` alone; it would require exercising an actual
`engine = "julia"` fit of each construct (out of scope — this document commits
to writing no R code and running no tests) or a further read of the
`engine = "julia"` dispatch path in `R/` beyond the two files this review was
scoped to. **This is flagged rather than guessed**, per this document's own
brief.

## 6. NOT decided here

- **Which authority wins** (§4) — this is a cross-repo governance call between
  drmTMB and DRM.jl maintainers/reviewers, not a decision this specification
  document makes.
- **Whether `drm_bridge` gains a translation layer, or drmTMB's Julia-engine
  code path does** — a consequence of the authority decision above.
- **The exact `bridge_formula_labels_v1` map format** — the sketch in
  `public-004.json`/`CHECK-EXPECT.md` (a `public`/`raw`/`map` triple) is
  existing prior art to build from, not a ratified schema; `R/julia-coefficient-labels.R`'s
  validator already assumes a specific list-or-character-vector shape for
  `coef_name_map` that any implementation must satisfy, but this document does
  not specify how DRM.jl should construct or serialise it.
  This document does not adjudicate whether that or a different shape ships.
- **Row 7's term-order disagreement** (`gb:factor(h)10` vs `gc:factor(h)10`
  ordering, noted in §3) — whether this is a naming-contract issue or a
  separate column-order bug in `drm_bridge`'s interaction expansion is not
  determined here.
- **Timeline or issue ownership** for implementing whichever authority is
  chosen — no PR, branch, or milestone is proposed by this document.
- **Whether the gated parity suite (`DRM_PARITY_TESTS=1`) should be un-gated
  once fixed** — a CI-cost and cross-repo governance question outside this
  document's scope (`.github/workflows/` is explicitly out of scope per this
  slice's constraints).
- **Any change to `inst/extdata/julia-capabilities.tsv` or
  `docs/dev-log/coordination-board.md`** — both explicitly out of scope for
  this slice.

## 7. The producer contract (S3, drmTMB half; decided by D-202)

Owner decision (Shinichi, 2026-09-02, D-202): candidate (a) from §4 is
canonical -- base-R spelling wins. This section specifies the exact wire
contract drmTMB now implements on its side, so the DRM.jl lane can build the
matching echo without re-deriving the shape from `R/julia-coefficient-labels.R`.
This is a specification for the WHOLE round trip; only the drmTMB (R) half is
implemented by this slice (S3) -- see "What S3 does NOT cover" below.

### 7.1 Payload: `coef_labels`

`drm_julia_bridge_payload()` (`R/julia-bridge.R`) now builds an additional
field. **Wire format (corrected 2026-09-02):** the Julia call `drmTMB_drm_bridge(formula, family,
data, tree, options)` carries only those five arguments, so `coef_labels` travels **inside
`options`** as `options$coef_labels` (a Dict keyed by dpar of `Vector{String}` on the Julia side);
the top-level payload element of the same name is the R-side copy used after the call. DRM.jl reads
`options["coef_labels"]`, checks per-dpar column counts, echoes verbatim in order under
`bridge_formula_labels_v1`, and aborts naming the construct on any mismatch:

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
    engine dpar the payload never labelled -- exactly the phylo-mu FIXED-
    EFFECT case (the `mu` block's OWN `(Intercept)`/`x`/... columns) §7.1
    now fixes at the source -- passed by vacuity). NOTE (a Rose adversarial
    pass on N1, §7.7): this fixed the `mu` block's own labels, but a
    SEPARATE block (`resd_<group>`, the phylo term's own random-effect SD,
    no `formula$entries` counterpart at all) was still unlabelled and
    aborted the echo before this check was ever reached, so a live
    univariate phylo fit stayed broken end-to-end until §7.7's repair --
    do not read this bullet as "the phylo route worked" before that.
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

### 7.4 Route coverage (widened by N1, 2026-09-03; corrected 2026-09-03 after a Rose adversarial pass -- see S7.7)

As of N1, every bridge payload builder that reaches a live Julia call sends or
constructs base-R coefficient names, and `new_drmTMB_julia()`'s fail-closed
check (§7.3) applies to every route that goes through it. This section used to
list four routes as "not yet under this contract" (structured,
bivariate-known-structured, joint, cross-family); that list is empty for those
FOUR routes. It is NOT empty overall -- §7.7 corrects an overclaim a Rose
adversarial pass caught: the univariate `phylo(1 | group)` route (a FIFTH,
pre-existing route, not one of the four N1 widened) was ALSO failing the echo
on already-merged main, is now fixed for the plain mean-side case, and TWO
more phylo shapes (a `sigma`-side phylo term, and a correlated random-slope
phylo term) remain measured-broken and are explicitly out of this repair's
scope -- see §7.7 for what is and is not covered, precisely. Two different
mechanisms close the four-route list, matched to how each route talks to
DRM.jl:

- **Structured (relmat/animal/spatial, `drm_julia_structured_payload()`) and
  bivariate known-structured (q2, `drm_julia_biv_known_structured_payload()`)**
  both call `drmTMB_drm_bridge_structured(...)`, an R-registered Julia wrapper
  that forwards straight to the SAME `DRM.drm_bridge(...)` the base bridge
  calls -- so DRM.jl's `_bridge_echo_coef_labels` (§7.2/§7.5) applies to them
  identically. Both payload builders now call the ONE producer,
  `drm_julia_bridge_payload_coef_labels()`, exactly as the base bridge does,
  and send the result inside `options$coef_labels` the same way. Two blocks
  these routes report have no `formula$entries` counterpart at all and are
  built by the producer directly from `drm_julia_collect_structured_terms()`
  (empirically confirmed against DRM.jl 77513aa0, the pinned clone):
  - **`resd`** (structured route only) -- DRM.jl's general-covariance sparse
    Laplace names its one random-effect SD coefficient `"resd_<group>"`; the
    label is simply the grouping column's own name (`term$group`), DRM.jl's
    own synthetic name echoed back unchanged, not a base-R spelling to
    translate.
  - **`phylocov`** (known-structured route only) -- the shared relmat/animal/
    spatial term's 2x2 among-axis covariance, SAME `Sigma_a:L<row><col>`
    lower-triangular convention as the q4 phylogenetic case in §7.5, just for
    q=2. `drm_julia_phylocov_block_labels(q)` now generates both sizes from
    one function.
- **Joint (`R/julia-joint-missing.R` / `drm_bridge_joint`, Julia side
  `joint_missing_bridge.jl`) and cross-family (`drm_julia_xfam_axes()` /
  `DRM.fit_mixed_family`)** never ask DRM.jl for a name at all, so there is no
  round trip to widen: both build the coefficient vocabulary R-side, straight
  from `colnames(stats::model.matrix(...))`, and DRM.jl's Julia function
  returns only bare numeric vectors that R names itself
  (`joint_missing_bridge.jl`'s `drm_bridge_joint()` builds `coef_names`
  literally as `blocks .* "_" .* terms` from the `mu_names`/`sigma_names`/
  `predictor_names` the R payload supplied; `drm_julia_xfam_axes()` sets
  `coef_names = colnames(X)` directly). These two routes were under the
  contract by CONSTRUCTION before N1 touched anything; N1 added the tests
  that measure it (`tests/testthat/test-coefficient-labels.R`, "joint
  payload"/"cross-family payload" and the two matching "live echo" tests),
  not new production code.

**A base-bridge gap N1 found and closed along the way** (not a new route, the
SAME producer the base bridge already used): `drm_julia_bridge_payload_coef_labels()`
only labelled dpars present in `formula$entries`. DRM.jl's echo (§7.5) demands
a label for EVERY block it fits, including a dispersion/shape parameter the R
formula never names (e.g. a bare `bf(mu = y ~ x)` Gaussian fit still has a
`sigma` block, defaulting to an intercept-only design -- the SAME `~1` default
`default_dpar_entry()` in `R/drmTMB.R` inserts for the native TMB engine's own
family spec builders, without ever touching `formula$entries` itself). Before
this fix, ANY Julia-engine fit whose formula omitted `sigma` (or, for
`biv_gaussian`, `sigma1`/`sigma2`/`rho12`) aborted with `"coef_labels is
missing an entry for dpar \"sigma\""` -- confirmed empirically on a plain
`drmTMB(bf(mu = y ~ x), gaussian(), engine = "julia")` fit against DRM.jl
77513aa0, i.e. this affected the ALREADY-MERGED base bridge, not only the two
new routes. `drm_julia_bridge_default_dpar_labels()` (R/julia-bridge.R) now
fills these in as `"(Intercept)"`, gated on `family_type` (threaded into the
producer's call from all three payload builders that use it): dispersionless
families (`poisson`, `binomial`, `drm_julia_dispersionless_families()`) get no
default; `biv_gaussian` defaults `sigma1`/`sigma2`/`rho12`; every other
admitted family (`gaussian`, `lognormal`, `beta`, `nbinom2`, `gamma`, and
`student`, which ALSO defaults `nu`) defaults `sigma`. Measured against
DRM.jl 77513aa0 directly (`DRM.drm_bridge(formula = "y ~ x", family = fam,
...)` for every family `drm_julia_family_tag()` admits).

**RETIRED 2026-09-03: the legacy predict-time rewrite.** `drm_julia_predict_fixed_eta()`
(`R/julia-bridge.R`) used to retain a `gsub()`-based rewrite of
`object$coefficients[[dpar]]` names (`" & "` -> `":"`, `": "` -> `""`), guarded
by `is.null(object$bridge_public_coef_labels) && !inherits(object,
"drmTMB_julia_joint")`, for the four routes listed above. Now that every route
carries base-R spelling by construction (either checked at fit time via §7.3,
or never translated at all per the joint/cross-family mechanism above), the
guard's condition is never true for any live-reachable object, and the
rewrite is deleted outright -- `grep -rEn 'gsub\([^)]*(__bridge_|& )'
R/` returns nothing. This closes gate S3-G4 (previously ABANDONED) to MET;
see `docs/dev-log/plan/2026-09-01-...` history and the N1 after-task note for
the removal attempt this repairs (commit `5b77eb691`, reverted by Rose S9
attack A10 for the mistaken premise "every other case aborts at fit time" --
that premise is now actually true, verified live against all four routes
before deletion, not merely assumed).

- **Row 7's term-order disagreement** (§3, §6) is unchanged -- if DRM.jl ever
  echoes a syntactically valid but reordered map for that construct, §7.2's
  existing validator (unchanged) still refuses it via `"map order or
  coefficient identity mismatch"`, and §7.3's cross-check refuses it a second
  way regardless (the reordered public names would not `identical()`-match
  `coef_labels[[dpar]]`).

## Sources

- DRM.jl issue #467, comment 5501007899 (1 pass / 6 fail measurement).
- `test/parity/runparity_bridge_formula.jl` (DRM.jl, cohort definition and
  comparison logic).
- `test/parity/gen_bridge_formula_fixtures.R` (DRM.jl, base-R vs `drm_bridge`
  name pairs for constructs 1–6, generated from real `drmTMB()` fits).
- `docs/dev-log/evidence/julia-r-parity/coefficient-labels/CHECK-EXPECT.md` and
  `RESULT.md` (drmTMB, branch `origin/codex/rebase-julia-optimizer-controls`;
  prior bounded, non-shipping oracle work; source of constructs 7–10 and the
  `bridge_formula_labels_v1` sketch).
- `docs/dev-log/evidence/julia-r-parity/coefficient-labels/public-004.json`
  (same branch; concrete `expected`/`actual`/`labels` data for constructs 7–10).
- `R/julia-coefficient-labels.R` (drmTMB, all 54 lines — validator only, no
  producer found).
- `R/methods.R` (drmTMB, `coefficient_labels()` at line 6061 and its callers
  at lines 2336, 4410, and 5234).
- `docs/src/capabilities.md` (DRM.jl) — reviewed; contains no coefficient-label
  contract documentation to cite.

### 7.5 Amendment, 2026-09-02 evening (DRM.jl #599 echo validator; measured at DRM.jl main 77513aa0)

DRM.jl's echo (`_bridge_echo_coef_labels`, `src/bridge.jl`) runs **only when `options["coef_labels"]`
is supplied** — a payload without it (drmTMB `main` before PR #1114) fits exactly as before. When it
IS supplied, the engine requires an entry for **every block it fits, not only formula-driven dpars**,
with exactly one name per column. Two consequences, both implemented in
`drm_julia_bridge_payload_coef_labels()`:

- **`phylocov`** — the bivariate q=4 phylogenetic route's fifth block (the 4x4 among-axis covariance's
  ten log-Cholesky entries) has no `formula$entries` counterpart; it is labelled by name
  `Sigma_a:L<row><col>` (lower-triangular, column-major), the convention `drm_julia_phylocov_matrix()`
  already reads back.
- **`sd(group)` / `sd_phylo(group)`** — location-scale-scale dpars, whose dpar NAME carries the group
  (so `julia_bridge_supported_dpars()` cannot enumerate them), are labelled under the block key that
  precedes the `(` (`sd`, `sd_phylo`), from their ordinary RHS.

**Wire form:** each dpar's character vector crosses as a Julia `Vector{String}` by sending an R *list*
of single strings (JuliaCall unboxes a length-1 atomic vector to a scalar `String`, which the echo
would iterate by character — "(Intercept)" read as 11 names). The R-side `coef_labels` copy stays a
plain character vector per dpar; only `options$coef_labels` is list-wrapped.

§7.4's "not covered" list at the time this amendment was first written listed the structured/known-
structured/joint/xfam payload builders; the two blocks above were, at that time, covered on the base
bridge only. Measured: the committed `biv-q4-phylo-reml` and `lss-tip-identity` fixtures fit through the
echo at 77513aa0 (leaves a4/a5/s7).

### 7.6 Amendment, 2026-09-03 (N1 -- block rules for the two remaining live-round-trip routes)

Widening §7.1's producer to the structured and known-structured payload builders (§7.4) needed two more
block rules, discovered the same way as §7.5's `phylocov`/`sd(group)` rules -- fitting `DRM.drm_bridge`
directly against the pinned 77513aa0 clone and reading the echo's own error text:

- **`resd`** (`drm_julia_structured_payload()`, relmat/animal/spatial on `mu`) -- `DRM.drm_bridge(formula
  = "y ~ x + relmat(1 | g)", family = "gaussian", K = K, options = Dict())` reports `coef_names` ending
  in `"resd_g"`; supplying `coef_labels` with only `mu`/`sigma` aborts `coef_labels is missing an entry
  for dpar "resd" (1 fixed-effect columns; Julia names: ["resd_g"])`. The label is simply the grouping
  column's own name (`term$group}` on the R side) -- confirmed stable across all four
  `drm_julia_structured_families()` (gaussian, poisson, nbinom2, gamma) and both `relmat`/`animal` marker
  types. Poisson has no `sigma` block (dispersionless) but still has `resd`.
- **`phylocov` at q=2** (`drm_julia_biv_known_structured_payload()`, relmat/animal/spatial shared by
  `mu1`/`mu2`) -- a `biv_gaussian` fit with matching `relmat(1 | g)` terms on both mean axes reports
  `coef_names` ending in `"phylocov_Sigma_a:L11"`, `"...L21"`, `"...L22"`; the echo demands exactly those
  three names under dpar `"phylocov"`. SAME lower-triangular, column-major `Sigma_a:L<row><col>`
  convention as the q4 case in §7.5, just for a 2x2 matrix -- `drm_julia_phylocov_block_labels(q)`
  (R/julia-bridge.R) now generates both sizes from one function, refactoring §7.5's inline q4 loop to
  call it too.

A THIRD finding was not a new route's block at all, but a gap in the producer's EXISTING per-`formula$entries`
loop that blocked both new routes AND the already-merged base bridge: DRM.jl's echo (§7.5) demands a label
for every block it fits, including a dispersion/shape dpar the R formula never named (a bare `bf(mu = y ~
x)` Gaussian fit still gets an intercept-only `sigma` block from DRM.jl, mirroring the SAME `~1` default
`default_dpar_entry()` in `R/drmTMB.R` silently inserts for the native TMB engine, without ever writing
that default into `formula$entries` for the Julia payload to see). Measured directly against 77513aa0 for
every family the bridge admits: `gaussian`/`lognormal`/`beta`/`nbinom2`/`gamma` each default `sigma`;
`student` ALSO defaults `nu`; `biv_gaussian` defaults `sigma1`/`sigma2`/`rho12`; `poisson`/`binomial`
default nothing (no free dispersion parameter). `drm_julia_bridge_default_dpar_labels()` (R/julia-bridge.R)
fills these as `"(Intercept)"`, gated on a new `family_type` parameter threaded into
`drm_julia_bridge_payload_coef_labels()` from all three call sites that carry one (base bridge, structured,
known-structured). §7.4 has the full writeup and the "RETIRED 2026-09-03" note on the legacy predict-time
rewrite this closes out.

### 7.7 Amendment, 2026-09-03 evening (N1 repair -- Rose adversarial pass refutation and neighbour hole)

A Rose (fresh, adversarial) pass against N1's branch (`docs/dev-log/after-task/2026-09-03-n1-label-contract-all-routes.md`'s
companion review) REFUTED the claim that "every bridge route" passes DRM.jl's echo. It found one WORST
gap and one neighbour hole, both pre-existing on already-merged main (not introduced by N1), plus a prose
overclaim this section corrects.

**The WORST gap, fixed.** The univariate phylogenetic route -- `bf(y ~ x + phylo(1 | species, tree = tr),
sigma ~ 1)`, gaussian, `engine = "julia"` -- aborted on BOTH `origin/main` and N1's branch:
`coef_labels is missing an entry for dpar "resd" (1 fixed-effect columns; Julia names: ["resd_species"])`.
Root cause: the producer's `resd` block (§7.6) was built only from `drm_julia_collect_structured_terms()`,
whose marker types are `relmat`/`animal`/`spatial` -- `phylo` is deliberately excluded there (it gates
ROUTING to a different code path), so the univariate phylo route's own `resd_<group>` block was never
labelled. Fixed by a SEPARATE detection in the producer, gated to a bare random-intercept `phylo(1 | g)`
term on `mu` specifically (`term$dpar == "mu"`, `term$coef_names == "(Intercept)"`), skipped when the
formula is bivariate (`drm_julia_biv_phylo_dimension()` non-NA -- those routes use `phylocov` instead) or
when the SAME group also carries a coupled `sd(group)`/`sd_phylo(group)` LSS dpar (that route reports the
covariance through the `sd`/`sd_phylo` block instead, verified empirically no separate `resd` appears --
the `lss-tip-identity` fixture already passed before this repair). Re-verified live after the fix: the
mean-only phylo route now matches the native TMB engine's `mu` coefficient names exactly; the q4 bivariate
phylo route (`phylocov`) and the LSS `sd()` route are unaffected (both still pass); a Poisson phylo
round-trip (`tests/testthat/test-julia-phylo-count.R`, previously silently skipped under this arc's
mandated live env because it gates on the DIFFERENT `DRM_JL_PHYLO_PATH` variable, §7.7's next paragraph)
now runs and passes too.

**NOT fixed, measured, explicitly out of scope (at the time this paragraph was written -- see §7.8, all
three are now fixed).** Two other phylo shapes were measured to need a DIFFERENT, dpar-qualified block key
this repair does not attempt, and remain broken against the pinned echo exactly as they were before N1
touched anything (confirmed unchanged on the branch tip before and after this repair, same error text): a
`sigma`-side phylo term (the "sigma-phylo REML" cluster, `drm_julia_locscale_phylo_families()`) reports
`resd_sigma` with a COMPOUND term name (`"species:sd_sigma"`, not the bare group --
`tests/testthat/test-julia-sigma-phylo-reml.R`'s live fit errors `coef_labels is missing an entry for
dpar "resd_sigma"`), and a correlated random-slope phylo term (`phylo(1 + x | g)`) is a separate, more
complex shape again (likely `resd_<group>` plus a `recov_<group>` correlation block), neither measured
here.

**The neighbour hole, fixed.** A user-WRITTEN `sigma ~ ...` formula on a `drm_julia_dispersionless_families()`
family (poisson, binomial -- no free dispersion parameter) aborted the echo in the OPPOSITE direction:
`coef_labels supplies names for unknown dpar "sigma"; the model has dpars: mu`. The native TMB engine
already refuses this formula outright for the same reason (`drmTMB(bf(y ~ x, sigma ~ 1), poisson())` ->
"Poisson models only support `mu` and optional `zi`. Unsupported parameter: \"sigma\".", verified live) --
the fix makes `engine = "julia"` refuse the same formula the same way (a clear, drmTMB-authored
`cli::cli_abort()`, not a silent drop of what the user wrote, and not the confusing DRM.jl-attributed
echo message), rather than building a payload doomed to fail downstream.

**Why the WORST gap went undetected.** Every live phylo test in the repo gates on `DRM_JL_PHYLO_PATH`, a
DIFFERENT env var from the `DRM_JL_PATH` this lane's mandated live command sets, so the whole phylo family
silently skipped under the standard live invocation; when the var IS set, several phylo test files wrap
the fit in `tryCatch(..., error = function(e) skip(...))`, converting a hard bridge abort into a green
skip (16 sites across 9 files, filed as a separate issue, explicitly OUT of this repair's scope -- not
touched here).

**Test-count correction.** The after-task's original §4 claimed "114 assertions" for the offline
`test-coefficient-labels.R` run; Rose measured 94 passing + 4 skipped = 98 at that point. After this
repair (new tests added), the SAME offline invocation
(`env -u DRM_JL_PATH -u DRMTMB_JULIA_TESTS`) measures 104 passed + 5 skipped = 109 expectations; the
filtered suite (`coefficient-labels|julia-bridge|julia-structured|julia-joint|xfam`) measures 646 passed +
10 skipped, 0 failed/errors. Both numbers are freshly re-measured for this section, not carried over from
either earlier claim.

### 7.8 Amendment, 2026-09-03 (N9 -- the three §7.7 "NOT fixed" gaps closed, plus one neighbour §7.7 did
not name)

N9 (`docs/dev-log/after-task/2026-09-03-n9-label-gaps.md`) closes the three constructs §7.7 explicitly
left broken -- a `sigma`-side phylo random-intercept term, a random-SLOPE phylo term on `mu`, and the
`phylocov` block on the q=2 (not only q=4) bivariate phylo route -- and, while unskipping the live test
that exercises the sigma-phylo shape end-to-end, found and closed a FOURTH gap §7.7 did not name: the
coupled mu+sigma phylo-locscale route (`phylo_locscale` mode, both mu and sigma carrying a bare-intercept
`phylo()` term on the SAME group) needs a block that depends on the ESTIMATOR (`method`), not only the
formula shape. All four are measured against DRM.jl 77513aa0, empirically, by fitting `DRM.drm_bridge`
directly and reading its own error text (never guessed from punctuation, per §3).

- **`resd_<dpar>` for a non-`mu` phylo random-intercept term** (e.g. `sigma ~ phylo(1 | group, tree =
  tree)`, family `gaussian`, sigma NOT also coupled to a mu-side phylo term on the same group) --
  `coef_names` ends in `"resd_sigma_species:sd_sigma"`: a dpar-QUALIFIED block key (`"resd_<dpar>"`, e.g.
  `"resd_sigma"`) whose ONE label is a COMPOUND term (`"<group>:sd_<dpar>"`, e.g. `"species:sd_sigma"`),
  not the bare group `mu`-side phylo uses. Any non-`mu` dpar carrying a bare-intercept `phylo()` term gets
  this rule, gated the same way the `mu` rule already is (skipped for a bivariate q2/q4 formula, and
  skipped for a group that also carries a coupled `sd(group)`/`sd_phylo(group)` LSS dpar).
- **`resd` for a random-SLOPE `phylo(1 + x | g)` term on `mu`** -- confirmed empirically that DRM.jl's
  sparse-Laplace GLMM route reports EXACTLY ONE `resd_<group>` coefficient regardless of how many
  random-effect columns the term has (`coef_names` ends in `"resd_species"`, "1 fixed-effect columns" per
  the echo's own count) -- there is no separate intercept/slope SD split to label. The producer's existing
  bare-group `resd` rule (previously restricted to `term$coef_names == "(Intercept)"`) now applies to any
  `mu`-side phylo random-effect term regardless of column count.
- **`phylocov` on the q=2 bivariate phylo route** (`mu1`/`mu2` sharing one `phylo()` term directly, no
  sigma-side phylo axis -- distinct from the q=2 KNOWN-STRUCTURED (`relmat`/`animal`/`spatial`) route §7.6
  already covers) -- `coef_names` ends in `"phylocov_Sigma_a:L11/L21/L22"`, the SAME lower-triangular
  column-major convention `drm_julia_phylocov_block_labels(2L)` already generates for the known-structured
  q2 route; only the ROUTE reaching it differs (`drm_julia_biv_phylo_dimension(formula) == "q2"`, not
  `drm_julia_collect_structured_terms()`).
- **`recov` vs `resd_mu`/`resd_sigma` for the coupled mu+sigma phylo-locscale route, gated on `method`**
  (the fourth, unnamed-in-§7.7 gap) -- when the SAME group carries a bare-intercept `phylo()` term on BOTH
  `mu` and another dpar (DRM.jl's `phylo_locscale` mode, `drm_julia_phylo_payload()`), which block DRM.jl
  expects depends on the ESTIMATOR, not the formula: fitting the identical
  `y ~ x + phylo(1 | species, tree = tree), sigma ~ phylo(1 | species, tree = tree)` formula through
  `DRM.drm_bridge` directly under both `method = "ML"` and `method = "REML"` gives two different shapes.
  - `method = "ML"` (DRM.jl's coupled route, `phylo_coupled = TRUE` in `drm_julia_bridge_options()`): ONE
    2x2 mu/sigma-axis residual-correlation block, `coef_names` ending in `"recov_species:L11"`,
    `"...L22"`, `"...L21"` -- a DIAG-then-OFFDIAG order, deliberately NOT `phylocov`'s lower-triangular
    column-major order -- under dpar key `"recov"`. New helper `drm_julia_recov_block_labels(group)`
    generates this (q=2 only; this route never reaches a larger axis count).
  - `method = "REML"` (coupled mean-sigma phylo REML is not implemented in DRM.jl, so REML falls back to
    the separate-block route): TWO dpar-qualified blocks, `"resd_mu"` (compound term `"<group>:sd_mu"`)
    and `"resd_<dpar>"` (compound term `"<group>:sd_<dpar>"`) -- note the `mu` block is ALSO
    dpar-qualified here, unlike the mu-only (no coupled sigma term) case, which keeps the bare `"resd"`
    key.
  `drm_julia_bridge_payload_coef_labels()` gained a `method = "ML"` parameter (threaded from the base
  bridge's own `method` argument; the structured/known-structured payload builders never reach a `phylo()`
  term at all, so they pass no `method` and keep the default) to make this determination -- the ONLY
  signature change in this repair.

**Why this was found, not assumed.** N9's brief named only the first three constructs (written against
the ORIGINAL "measured broken" skip text in `tests/testthat/test-julia-tmb-parity.R`, which happened to
describe the `resd_sigma` compound-name shape). Fixing that shape alone was not enough to make the live
test AT that skip site pass: the SAME test also fits the coupled `mu_sigma` construct, which turned out to
need the `recov`/`resd_mu` split above. This was discovered by running the live test after the first three
fixes and reading DRM.jl's own abort text for the NEW failure, not by speculating about what else might be
broken -- the same evidence discipline as every other row in this document.

Caveat on the random-slope row (coordinator, 2026-09-03 08:45 UTC, from the DRM.jl lane's own finding,
DRM.jl issue #620): at DRM.jl 77513aa0 the one-column `resd` label for `phylo(1 + x | g)` matches what the
engine echoes because `_split_ranef` (`src/gaussian_ranef.jl:19`) keeps only the grouping symbol of a
`phylo()` marker, so DRM.jl fits the INTERCEPT-ONLY model and silently discards `x`; the label is correct
for the model DRM.jl actually fits, not for a two-SD random slope. DRM.jl is adding a fail-closed refusal
of `phylo(<not 1> | group)` on its univariate routes; once drmTMB's pinned clone moves past it, the live
Gamma random-slope test in `test-julia-slope-nongaussian.R` must expect an engine refusal, and a two-SD
random-slope label becomes a new row here (DRM.jl's S8 follow-up implements the Gaussian case).

Test-count: `tests/testthat/test-coefficient-labels.R` gained four new offline unit tests (naming
"resd_sigma", "random-slope", "phylocov" per this repair's own gate); the four live "measured broken"
skips this section closes are removed from `test-julia-sigma-phylo-reml.R` (1),
`test-julia-slope-nongaussian.R` (1), and `test-julia-tmb-parity.R` (2).

**N10 addendum, 2026-09-03 (an ORDINARY, non-phylo `sigma ~ (1 | g)` random intercept -- a different
route than every rule above, all of which are phylo-only).** `bf(y ~ x, sigma ~ (1 | g))` --  a plain
lme4-style random intercept on `sigma`, no `phylo()`/`relmat()`/`animal()`/`spatial()` marker anywhere
-- aborted `engine = "julia"` with `coef_labels is missing an entry for dpar "resd" (1 fixed-effect
columns; Julia names: ["resd_g_logsigma"])`. This is a DIFFERENT code path from every `resd`/`resd_<dpar>`
rule above: `drm_julia_formula_entry()` only strips the phylo tree and rewrites `meta_V()` -- it does NOT
strip lme4-style bars -- so the term crosses the bridge as literal text (`"sigma ~ (1 | g)"`) and DRM.jl's
own ordinary sparse-Laplace GLMM route parses and fits it directly, with no `formula$entries$structured`
record on the R side at all (the SAME "not even recorded" gap §7.1 already notes for a mu-side bar).
Measured directly against DRM.jl 77513aa0 (`drmTMB_drm_bridge` called on `("y ~ x", "sigma ~ (1 | g)")`):
`coef_names` ends in `"resd_g_logsigma"` -- a BARE `"resd"` block key (unlike the phylo sigma-side rule
above, which is dpar-qualified `"resd_sigma"`), whose one label is a single compound term, UNDERSCORE-
joined (not `drm_julia_recov_block_labels()`'s colon convention): `"<group>_<DRM.jl's own internal dpar
name>"`, where DRM.jl's internal name for `sigma` is `"logsigma"` (its log-link working scale). Verified
supplying `resd = list("g_logsigma")` reproduces the exact raw name and the fit proceeds under the echo.
`drm_julia_bridge_payload_coef_labels()` gained a small, separate detection for this shape, restricted to
`sigma` (the only non-`mu` dpar measured) and to a random-INTERCEPT term (a random-SLOPE ordinary term on
`sigma`, or the same shape on another non-`mu` dpar such as `nu`, is not measured and left alone). Two
neighbour shapes were probed live and found to be DRM.jl-side REFUSALS, not labelling gaps: an ordinary
random term on BOTH `mu` and a non-`mu` dpar (same group, or two different groups) aborts DRM.jl's own
solver ("a random effect on `sigma` must be the only random structure (the mean must be fixed effects)")
before any `coef_labels` check is even reached -- confirmed fitting `("y ~ x + (1 | g)", "sigma ~ (1 | g)")`
and `("y ~ x + (1 | g)", "sigma ~ (1 | h)")` directly; neither is addressed here, since there is no label
this producer could supply that would change DRM.jl's own refusal.

**A found-and-since-fixed downstream gap (2026-09-03, same day, OWNS widened by the lane coordinator to
cover it).** Once the fit succeeds, `coef(fj, "mu")` and `coef(fj, "sigma")` are correct and match the
native TMB engine exactly (verified live) -- the fixed-effect coefficient table this section governs was
always right. But `drm_julia_structured_parameters()` (`R/julia-bridge.R`, a SIBLING function this
producer feeds, not one of its own helpers) initially mis-attributed the resulting `resd_g_logsigma`
random-effect SD to `sdpars$mu` instead of `sdpars$sigma`: it falls back to a hard-coded `dpar <- "mu"`
default whenever a bare `resd_` block has no matching `entry$structured` term record (true here, for the
same "not recorded" reason above), a default written before any non-`mu` bare-`resd` shape existed. This
was a real display bug for `sdpars()`/`ranef()`-style access on this construct, found while verifying this
addendum live -- shipping it unfixed would have turned an honest abort into a fit whose `sdpars` were
mislabelled, so the OWNS fence for this arc was widened to include `drm_julia_structured_parameters()`
and it was fixed the same day: a new shared helper, `drm_julia_ordinary_nonmu_resd_map()` (factored out of
the SAME detection `drm_julia_bridge_payload_coef_labels()` already used, so both call sites agree on
exactly one rule), reattributes this specific fallback shape to the dpar it actually belongs to, with
label `"(1 | <group>)"` -- `format_random_mu_label()`'s own spelling (`R/drmTMB.R`), the same name the
native TMB engine's `sdpars$sigma` uses for this construct. Verified live: `fj$sdpars$sigma` now has one
entry named `"(1 | g)"` (`fj$sdpars$mu` empty), matching a native TMB fit of the same formula exactly.
Every OTHER bare-`resd` shape (phylo, relmat/animal/spatial) keeps its existing `entry$structured`-matched
attribution unchanged -- only the previously-unhandled fallback default is touched.
